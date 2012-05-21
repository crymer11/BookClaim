require 'sinatra'
require 'sinatra/config_file'
require 'net/http'
require 'json'
require 'curb'
require 'haml'

config_file 'config.yml'
enable :logging

helpers do
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic Realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    # TODO: Use database for authentication here
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'admin']
  end

  def partial(page, options={})
    haml page.to_sym, options.merge!(:layout => false)
  end

  def logger
    request.logger
  end
end

get '/' do
  haml :index, locals: { content: "Testing" }
end

get '/admin/?' do
  protected!
  haml :admin, locals: { apikey: settings.apikey }
end

get '/books/?' do
  haml :books, locals: { content: "Testing books" }
end

post'/book_search/?' do
  apikey = settings.apikey
  query = request.params["q"]

  resp = Curl::Easy.perform("https://www.googleapis.com/books/v1/volumes?q=" + URI.encode(query) + "&key=" + apikey)
  resp = JSON.parse(resp.body_str)

  haml :admin, locals: { apikey: apikey, books: resp["items"], query: query }
end

get '/book_search/?' do
  request.params.inspect
end
