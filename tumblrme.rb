require "rubygems"
require "bundler/setup"
Bundler.require(:default)
require "active_support/cache"

class Tumblrme < Sinatra::Base
  def tumblrs
    connection = Faraday.new(:url => 'http://api.tumblr.com/v2/blog/kimjongillookingatthings.tumblr.com/posts/photo') do |conn|
      conn.response :rashify
      conn.response :json, :content_type => /\bjson$/
      conn.response :caching do
        ActiveSupport::Cache::FileStore.new 'tmp/cache', :namespace => 'faraday', :expires_in => 3600
      end
      conn.adapter Faraday.default_adapter
    end
    response = connection.get do |req|
      req.params["api_key"] = 'qpvITi2QuD3We7q6iz9ofLGVYLAVZ64g2XK5p7aZwcJ0KSg5nf'
      req.params["limit"]   = '200'
    end
    response.body.response.posts.map do |post|
      urls = post.photos.map do |photo|
        photo.alt_sizes.select{|size| size.width == 500}.map{|size| size.url}
      end.flatten

      urls.map{|url| { tumblr: url }}
    end.flatten
  end

  before do
    content_type :json
  end

  get '/' do
    tumblrs.to_json
  end

  get '/random' do
    tumblrs.sample.to_json
  end
end