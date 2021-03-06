require 'sinatra'
require 'sinatra/async'
require 'eventmachine'
require 'em-hiredis'
require 'thin'
require 'sinatra/base'
require 'pry'
require './lib/em-synchrony' # https://github.com/igrigorik/em-synchrony
require './services/shorter'
require './services/redisrepo'
require 'digest'

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
    content_type :json
    response = if aparams[:longUrl] && aparams[:longUrl].valid_url?
                 return_short_url(aparams[:longUrl])
               else
                 { message: 'url is missing'}
               end
    body response.to_json
  end

  # When we have to get url form redis,
  # async flow pauses for current fiber for redis request,
  # other fibers remain async.
  aget '/:url' do
    redis_initialize
    EM.synchrony do
      if aparams[:url]
        shorty = Shorter.assemble_short_url(aparams[:url])
        response = EM::Synchrony.sync @redis_server.get(shorty)
        headers 'Location' => response
        status 301
        body
      else
        response = { message: 'url is missing'}
        body response.to_json
        status 404
      end
    end
  end

  private

  # Initializes redis first time by any request,
  # keeps one connection per fiber
  def redis_initialize
    @redis_server ||= RedisRepo.new.redis_server
  end

  def return_short_url(long_url)
    shorty = Shorter.make_short_url(long_url)
    @redis_server.set(long_url, shorty)
    @redis_server.set(shorty, long_url)
    { url: shorty }
  end

  def valid_url?(url)
    url =~ URI::regexp
  end
end

run app: ShortenApp.new
