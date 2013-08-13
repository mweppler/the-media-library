class MediaLibrary < Sinatra::Application
  # Movie Routes.................................................................

  # /movies......................................................................
  get '/movies' do
    @title = 'Movies'
    @movies = Movie.all(:order => [:title.asc])
    haml :'movie/list'
  end

  # /movie/create................................................................
  post '/movie/create' do
    @movie = Movie.new(params[:movie])

    if params['image-file']
      image_attachment = @movie.attachments.new
      image_attachment.handle_upload(params['image-file'])
    end

    if params['video-file']
      video_attachment = @movie.attachments.new
      video_attachment.handle_upload(params['video-file'])
    end

    if @movie.save
      @message = 'Movie was saved.'
    else
      @message = 'Movie was not saved.'
    end

    haml :'movie/create'
  end

  # /movie/edit/:id..............................................................
  get '/movie/edit/:id' do
    @movie = Movie.get(params[:id])
    @title = 'Edit Movie Details'
    haml :'movie/edit'
  end

  # /movie/new...................................................................
  get '/movie/new' do
    @title = 'Upload Movie'
    haml :'movie/new'
  end

  # /movie/show/:id..............................................................
  get '/movie/show/:id' do
    @movie = Movie.get(params[:id])
    if @movie
      @title = @movie.title
      haml :'movie/show'
    else
      redirect '/movies'
    end
  end

  # /movie/update/:id............................................................
  post '/movie/update/:id' do
    @movie = Movie.get(params[:id])

    if params['image-file']
      image_attachment = @movie.attachments.new
      image_attachment.handle_upload(params['image-file'])
    end

    if params['video-file']
      video_attachment = @movie.attachments.new
      video_attachment.handle_upload(params['video-file'])
    end

    if @movie.save && @movie.update(params[:movie])
      @message = 'Movie was saved.'
    else
      @message = 'Movie was not saved.'
    end

    haml :'movie/update'
  end

  # /movie/watch/:id.............................................................
  get '/movie/watch/:id' do
    movie = Movie.get(params[:id])
    if movie
      @movies = {}
      movie.attachments.each do |attachment|
        supported_mime_type = $config.supported_mime_types.select { |type| type['extension'] == attachment.extension }.first
        if supported_mime_type['type'] === 'video'
          @movies[attachment.id] = { :path => File.join($config.file_properties.video.link_path['public'.length..-1], attachment.filename) }
        end
      end
      if @movies.empty?
        redirect "/movie/show/#{movie.id}"
      else
        @title = "Now Watching: #{movie.title}"
        haml :'movie/watch'
      end
    else
      redirect '/movies'
    end
  end
end
