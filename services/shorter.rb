require 'yab62' # https://github.com/siong1987/yab62
require 'digest'

class Shorter
  #TODO (A1ex Lopatin) Implement yml config
  # instead hardcoded string, or may be constant
  def self.assemble_short_url(code)
    "http://127.0.0.1:8181/#{code}"
  end

  def self.make_short_url(long_url)
    code = Digest::MD5.hexdigest(long_url)
             .to_i(16).to_s.split('')[0..12].join.to_i
             .encode62
    assemble_short_url(code)
  end
end
