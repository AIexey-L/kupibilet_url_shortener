require 'yab62'

class RedisHandler
  attr_reader :long_url, :redis_server, :id
  def initialize(redis_server, id)
    @redis_server = redis_server
    @id = id
  end

  def self.save_to_redis(long_url)
    @redis_server.set(long_url, @id)
  end

  def self.increment_id
    @id =+ 1
  end

  def self.fetch_from_redis(id)
    @redis_server.get(id)
  end

  def make_short_url(id)
    "http://127.0.0.1:8181/#{id.to_i.encode62}"
  end

  def self.check_if_url_present(long_url)
    @redis_server.get(long_url).callback { |exist_id|
      exist_id.nil? ? false : exist_id
    }
  end

  def self.return_short_url(long_url)
    @redis_server.get(long_url).callback { |exist_id|
      if exist_id
        make_short_url(exist_id)
      else
        save_to_redis(long_url, increment_id)
        make_short_url(@id)
      end
    }
  end
end
