require 'yab62'
require 'digest'

class Shorter
  def self.assemble_short_url(code)
    #"http://127.0.0.1:8181/#{code}"
    'http://' +
      Settings.webserver_config.host +
      Settins.webserver_config.port +
      '/' +
      code
  end

  def self.make_short_url(long_url)
    # code = Digest::MD5.hexdigest(long_url)
    #          .to_i(16).to_s.split('')[0..12].join.to_i
    #          .encode62
    # assemble_short_url(code)
    Digest::MD5.hexdigest(long_url)
      .to_i(16).to_s.split('')[0..12].join.to_i
      .encode62
  end
end
