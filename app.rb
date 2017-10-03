require 'sinatra'
require 'sinatra/async'
require 'eventmachine'
require 'em-hiredis'
require 'thin'
require 'sinatra/base'
require './services/shortener'
require 'pry'
require 'yab62' # https://github.com/siong1987/yab62
require './services/redisrepo'

def run(opts)
  EM.run do
    # define some defaults for our app
    server  = opts[:server] || 'thin'
    host    = opts[:host]   || '127.0.0.1'
    port    = opts[:port]   || '8181'
    web_app = opts[:app]

    unless ['thin', 'hatetepe', 'goliath'].include? server
      raise "Need an EM webserver, but #{server} isn't"
    end

    # Starts em-hiredis in context of eventmachine.
    # @redis_server should be available inside webserver, inside
    # ShortenApp instance.
    @redis_server = EM::Hiredis.connect("redis://127.0.0.1:6379")

    dispatch = Rack::Builder.app do
      map '/' do
        run web_app
      end
    end

    # Starts webserver (ShortenApp instance will be inside webserver)
    Rack::Server.start({
                         app:    dispatch,
                         server: server,
                         Host:   host,
                         Port:   port,
                         signals: false,
                       })
  end
end

class ShortenApp < Sinatra::Base
  register Sinatra::Async
  configure do
    # threaded - False: Will take requests on the reactor thread
    set :threaded, false
  end

  # Uses sinatra/async
  apost '/' do
    redis_initialize
    generate_key
    #binding.pry
    content_type :json
    response = if aparams[:longUrl]
                 Shortener.call(aparams[:longUrl], @connection, @id)
               else
                 { message: 'url is missing'}
               end
    body response.to_json
  end

  aget '/:url' do
    redis_initialize
    aparams[:url] ? key = aparams[:url].decode62 : { message: 'url is missing'}
    @connection.get(key).callback { |long_url| long_url }
    status 301
  end

  private

  def redis_initialize
    @connection ||= RedisRepo.new.redis_server
  end

  def generate_key
    @id ||= 1_000_000_000_000
    @id += 1
  end
end

run app: ShortenApp.new
