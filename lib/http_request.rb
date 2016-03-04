require 'restclient'

class Http_request
  attr_accessor :cookies

  def initialize()
    @cookies = {}
  end

  def post(url,data=nil)
    res = RestClient.post(url,data,cookies: @cookies,user_agent: "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.94 Safari/537.36")
      @cookies = @cookies.merge(res.cookies)
    return res
  end

  def get(url)
    res = RestClient.get(url,cookies: @cookies,user_agent: "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.94 Safari/537.36")
    @cookies = @cookies.merge(res.cookies)
    return res
  end

  def upload(url,files)
    res = RestClient.post(url,files,:user_agent => "Shockwave Flash")
    @cookies = @cookies.merge(res.cookies)
    return res
  end
end

