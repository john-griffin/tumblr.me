require "rubygems"
require "bundler/setup"
Bundler.require(:default)
require "active_support/cache"

class Tumblrme < Sinatra::Base
  def tumblrs(name)
    connection = Faraday.new(:url => "http://api.tumblr.com/v2/blog/#{name}.tumblr.com/posts/photo") do |conn|
      conn.response :rashify
      conn.response :json, :content_type => /\bjson$/
      conn.response :caching do
        ActiveSupport::Cache::FileStore.new 'tmp/cache', :namespace => 'faraday', :expires_in => 3600
      end
      conn.adapter Faraday.default_adapter
    end
    response = connection.get do |req|
      req.params["api_key"] = ENV["API_KEY"]
      req.params["limit"]   = '200'
    end
    unless response.body.response.is_a? Array
      response.body.response.posts.map do |post|
        post.photos.map do |photo|
          photo.alt_sizes.select{|size| size.width == 500}.map{|size| size.url}
        end.flatten.map{|url| { tumblr: url }}
      end.flatten
    end
  end

  before do
    content_type :json
  end

  get '/:name' do
    tumblrs(params[:name]).to_json
  end

  get '/:name/random' do
    tumblrs = tumblrs(params[:name])
    (tumblrs ? tumblrs.sample : nil).to_json
  end

  get '/:name/bomb' do
    tumblrs = tumblrs(params[:name])
    (tumblrs ? tumblrs.sample((params[:count] || 5).to_i) : nil).to_json
  end
end