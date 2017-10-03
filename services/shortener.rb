require 'uri'
require 'yab62'

class Shortener
  def self.call(normal_url, connection, id)
    if normal_url =~ URI::regexp
      { url: return_short_url(normal_url, connection, id) }
    else
      { message: 'invalid url'}
    end
  end

  private

  def self.return_short_url(normal_url, connection, id)
    # Check if long url already exists in redis, form and return
    # corresponding short link
    connection.exists(normal_url).callback do |key|
      binding.pry
      if key == 1
        connection.get(normal_url).callback do |existid|
          binding.pry
          short_url(existid)
          yield if block_given?
        end
      else
        binding.pry
          connection.set(normal_url, id)
          short_url(id)
      end
    end
  end


  def self.return_short_url(normal_url, connection, id)
    current_id = connection.get(normal_url).callback do |exist_id|
      #binding.pry
      exist_id.nil? ? false : exist_id
    end
    #binding.pry
    if current_id
      short_url(current_id.to_i)
    else
      connection.set(normal_url, id)
      short_url(id.to_i)
    end
  end

    #end
      # connection.get(normal_url).callback do |id|
      #   binding.pry
      #   short_url(id)
      #   yield if block_given?
    #else # Save new long url and id to redis, form and return short link
      #binding.pry
      #connection.set(normal_url, id)
      #binding.pry
      #short_url(id)
  #end

  # TODO (A1ex Lopatin) change hardcoded prefix to yml settings file or constant
  def self.short_url(id)
    binding.pry
    "http://127.0.0.1:8181/#{id.encode62}"
  end
end
