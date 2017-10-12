require 'sinatra'
require 'sinatra/async'
require 'eventmachine'
require 'em-hiredis'
require 'thin'
require 'sinatra/base'
require 'pry'
require 'em-synchrony'
require './services/shorter'
require 'digest'
require 'config'

set :root, File.dirname(__FILE__)

def run(opts)
  EM.run do
    # define some defaults for our app in config.yml
    config = Settings.webserver_config
    server  = opts[:server] || config.server
    host    = opts[:host]   || config.host
    port    = opts[:port]   || config.port
    web_app = opts[:app]    || config.web_app

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
  register Config
  Config.load_and_set_settings("./config/config.yml")
  configure do
    # threaded - False: Will take requests on the reactor thread
    set :threaded, false
  end

  # Uses sinatra/async
  apost '/' do
    aparams = eval(request.body.read)
    redis_initialize
    content_type :json
    response = if aparams[:longUrl] && valid_url?(aparams[:longUrl])
                 fetch_short_url(aparams[:longUrl])
               else
                 { message: 'url is missing or invalid'}
               end
    body response.to_json
  end

  # When we have to get url form redis,
  # async flow pauses for current fiber for redis request,
  # other fibers remain async.
  aget '/:url' do
    aparams = eval(request.body.read)
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
    redis_config = 'redis://' + Settings.redis.host + ':' + Settings.redis.port
    @redis_server ||= EM::Hiredis.connect(redis_config)

  end

  def fetch_short_url(long_url)
    shorty = Shorter.make_short_url(long_url)
    @redis_server.set(shorty, long_url)
    { url: shorty }
  end

  def valid_url?(url)
    url =~ URI::regexp
  end
end

run app: ShortenApp.new
