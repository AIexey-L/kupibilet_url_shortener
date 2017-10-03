class RedisRepo
  attr_accessor :redis_server

  def initialize
    @redis_server = EM::Hiredis.connect("redis://127.0.0.1:6379")
  end
end
