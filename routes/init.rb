class MediaLibrary < Sinatra::Application
  get '/' do
    @title = 'The Media Library'
    haml :index
  end
end

%w{api_v1 movie stylesheets tv_show}.each { |lib| require_relative lib }
