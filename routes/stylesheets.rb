class MediaLibrary < Sinatra::Application
  # Stylesheet Route..................................................................
  get '/stylesheets/:name.css' do
    content_type 'text/css', :charset => 'utf-8'
    scss :"stylesheets/#{params[:name]}"
  end
end
