require 'uri'
require 'http_request.rb'
require 'json'
require 'pathname'


BT_API_URL = 'http://btapi.115.com'
UPLOAD_URL = 'http://upload.115.com'
BASE_URL = 'http://115.com'
PASSPORT_URL = 'http://passport.115.com'
WEB_API_URL = 'http://web.api.115.com'

class Lixian
  attr_accessor :http, :time, :sign, :tasks

  def initialize
    @http = Http_request.new
  end

  def get_sign
    get_url = BASE_URL + '/?ct=offline&ac=space&_=' + "%10.2f" % Time.now.to_f
    ret = @http.get(get_url)
    unless ret.code == 200
      puts "get_sign失败:请求失败"
      return
    end
    ret = JSON.parse(ret.to_str)
    if ret['err_msg']
      puts "get_sign失败： #{ret['err_msg']}"
      return
    else
      @sign = ret['sign']
      @time = ret['time']
    end
  end

  def get_lixian_tasks_list
    self.get_sign
    tasks = []
    post_url = BASE_URL + '/web/lixian/?ct=lixian&ac=task_lists'
    current_page = 1
    page_count = 1
    while current_page <= page_count
      data = {'page' => current_page, 'uid' => @http.cookies['UID'].split('_').first, 'sign' => self.sign, 'time' => self.time}
      ret = @http.post(post_url, data)
      unless ret.code == 200
        self.tasks = nil
        puts "获取列表失败:请求失败"
        return
      end
      ret = JSON.parse(ret.to_str)
      if ret['page_count']
        page_count = ret['page_count']
      end
      ret['tasks'].each{|x| tasks << x} if ret['tasks']
      current_page += 1
    end
    @tasks = tasks
  end

  def upload_torrent(torrent_file_path)
    self.get_sign
    ret = @http.get(BASE_URL + "/?ct=lixian&ac=get_id&torrent=1&_=" + @time.to_s)
    ret = JSON.parse(ret.to_str)
    cid = ret['cid']
    #puts cid
    ret = @http.get(BASE_URL + "/?tab=offline&mode=wangpan")
    reg = /upload\?(\S+?)"/
    ids = reg.match(ret.to_str)
    unless ids
      puts "没有找到上传入口"
      return false
    end
    url = 'http://upload.115.com/upload?' + ids[0].chomp("\"")
    torrent_file_name = Pathname.new(torrent_file_path).basename
    post_url = url
    params = {'Filename' => torrent_file_name, 'target' =>'U_1_' + cid,
              'Filedata' => open(torrent_file_path,'rb'),
              'Upload' =>'Submit Query'}
    ret = @http.upload(post_url, params)
    ret = JSON.parse(ret.to_str)
    unless ret['state']
      puts "上传种子step.3出错: #{ret}"
      return false
    end
    url = WEB_API_URL + '/files/file'
    data = {'file_id' => ret['data']['file_id']}
    ret = @http.post(url, data)
    ret = JSON.parse(ret.to_str)
    unless ret['state']
      puts "上传种子step.4出错: #{ret}"
      return false
    end
    post_url = BASE_URL + '/web/lixian/?ct=lixian&ac=torrent'
    data = {'pickcode' => ret['data'][0]['pick_code'],
            'sha1' => ret['data'][0]['sha1'],
            'uid' => @http.cookies['UID'].split('_').first,
            'sign' => self.sign,
            'time' => self.time}
    ret = @http.post(post_url,data)
    ret = JSON.parse(ret.to_str)
    unless ret['state']
      puts "上传种子step.5出错: #{ret}"
      return false
    end
    wanted = nil
    idx = 0
    ret['torrent_filelist_web'].each do |item|
      if item['wanted'] != -1
        if !wanted
          wanted = idx.to_s
        else
          wanted += ',' + idx.to_s
        end
      end
      idx += 1
    end

    post_url = BASE_URL + '/web/lixian/?ct=lixian&ac=add_task_bt'
    data = {'info_hash' => ret['info_hash'],
            'wanted' => wanted,
            #115有个小bug,文件名包含'会出问题
            'savepath' => ret['torrent_name'].gsub('\'', ''),
            'uid' => @http.cookies['UID'].split("_").first,
            'sign' => self.sign,
            'time' => self.time}
    ret = @http.post(post_url, data)
    ret = JSON.parse(ret.to_str)
    if ret['error_msg']
      puts ret['error_msg']
      return true
    end

    puts "任务 torrent=#{torrent_file_name} 提交成功"
    return true
  end

  def upload_link(link)
    self.get_sign
    url = BASE_URL + "/web/lixian/?ct=lixian&ac=add_task_url"
    data = {'url' => URI.escape(link),
            'uid' => @http.cookies['UID'].split('_').first,
            'sign' => @sign,
            'time' => @time}
    ret = @http.post(url,data)
    puts ret
    ret = JSON.parse(ret.to_str)
    unless ret['state']
      puts "下载链接提交失败"
      return false
    end
    puts "链接提交成功，开始下载"
    return true
  end

  def current_tasks_count(refresh=true)
    count = 0
    if refresh
      self.get_lixian_tasks_list
    end
    return 999 unless @tasks
    @tasks.each do |task|
      next if task['status'] == 2
      count += 1
    end
    count
  end

  def list_tasks_info
    self.get_lixian_tasks_list
    @tasks.each do |task|
      if task['status'] == 2
        if task['file_id']
          puts "#{task['file_id']} #{task['name'].encode('UTF-8')}"
        end
      end
    end
  end

  def show_task(task_id)
    url = "http://web.api.115.com/files?aid=1&cid=#{task_id}&o=user_ptime&asc=0&offset=0&show_dir=1&limit=40&code=&scid=&snap=0&natsort=1&source=&format=json&type=&star=&is_share="
    ret = @http.get(url)
    ret = JSON.parse(ret.to_str)
    ret["data"].each do |term|
      puts "#{term["pc"]}  #{term["n"]}"
    end
  end

  def get_file_download_url(pick_code)
    self.get_sign
    url = "http://web.api.115.com/files/download?pickcode=#{pick_code}&_=" + @time.to_s
    ret = @http.get(url)
    ret = JSON.parse(ret.to_s)
    puts URI.unescape(ret['file_url'])
  end

  def get_video_m3u8(pick_code)
    url = "http://115.com/api/video/m3u8/#{pick_code}.m3u8"
    ret = @http.get(url)
    File.open("#{pick_code}.m3u8",'wb'){|f| f.write(ret.to_str)}
    puts "m3u8文件下载成功"
  end
end

