require 'sinatra/async/test'
require 'test/unit'
require './app'
require 'faker'

module My
  describe App do
    include Sinatra::Async::Test::Methods
    include Test::Unit::Assertions

    before :all do
      ShortenApp.new
    end

    describe 'post with correct long url' do
      before do
        @aparams = {
          :longUrl => Faker::Internet.url
        }
      end

      it 'returns correct status' do
        post '/', JSON.generate(@params)
        em_async_continue
        expect(last_response.status).to eq 200
      end

      it 'returns correct type' do
        post '/', JSON.generate(@params)
        em_async_continue
        expect(last_response.status).to eq 200
      end
    end
  end
end
