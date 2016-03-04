require "lixian115/version"
require "thor"
require "./lixian.rb"

module Lixian115
  LixianUtil = Lixian.new
  res = JSON.parse(IO.read('~/.115cookie'))
  cookies = {}

  res.each do |cookie|
    cookies[cookie["name"]] = cookie["value"]
  end
  cookies['loginType'] = '0'
  LixianUtil.http.cookies = cookies


  class App < Thor

    desc "list", "list completed tasks"
    def list
      LixianUtil.list_tasks_info
    end

    desc "upload file_path", "upload a torrent lixian task to 115"
    def upload file_path
      LixianUtil.upload_torrent(file_path)
    end

    desc "add link", "add a link lixian task to 115"
    def add url_path
      LixianUtil.upload_link(url_path)
    end

    desc "show task_id", "show files in a task"
    def show(task_id)
      LixianUtil.show_task(task_id)
    end

    desc "get_download_url file_id", "get the download url for a file in a task"
    def download_url file_id
      LixianUtil.get_file_download_url(file_id)
    end

    desc "play file_id(not works now)", "get the m3u8 file to play the video"
    def play(file_id)
      LixianUtil.get_video_m3u8(file_id)
    end
  end
end
