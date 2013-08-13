class MediaLibrary < Sinatra::Application
  # TV Show Routes...............................................................

  # get  /tv-shows...............................................................
  get '/tv-shows' do
    @title = 'TV Shows'
    @tv_shows = TvShow.all(:order => [:show.asc, :episode.asc])
    haml :'tv-show/list'
  end

  # post /tv-show/create.........................................................
  post '/tv-show/create' do
    @tv_show = TvShow.new(params[:tv_show])

    if params['image-file']
      image_attachment = @tv_show.attachments.new
      image_attachment.handle_upload(params['image-file'])
    end

    if params['video-file']
      video_attachment = @tv_show.attachments.new
      video_attachment.handle_upload(params['video-file'])
    end

    if @tv_show.save
      @message = 'TV Show was saved.'
    else
      @message = 'TV Show was not saved.'
    end

    haml :'tv-show/create'
  end

  # get  /tv-show/edit/:id.......................................................
  get '/tv-show/edit/:id' do
    @tv_show = TvShow.get(params[:id])
    @title = 'Edit TV Show Details'
    haml :'tv-show/edit'
  end

  # get  /tv-show/new............................................................
  get '/tv-show/new' do
    @title = 'Upload TV Show'
    haml :'tv-show/new'
  end

  # get  /tv-show/show/:id.......................................................
  get '/tv-show/show/:id' do
    @tv_show = TvShow.get(params[:id])
    if @tv_show
      @title = @tv_show.title
      haml :'tv-show/show'
    else
      redirect '/tv-shows'
    end
  end

  # post /tv-show/update/:id.....................................................
  post '/tv-show/update/:id' do
    @tv_show = TvShow.get(params[:id])

    if params['image-file']
      image_attachment = @tv_show.attachments.new
      image_attachment.handle_upload(params['image-file'])
    end

    if params['video-file']
      video_attachment = @tv_show.attachments.new
      video_attachment.handle_upload(params['video-file'])
    end

    if @tv_show.save && @tv_show.update(params[:tv_show])
      @message = 'TV Show was saved.'
    else
      @message = 'TV Show was not saved.'
    end

    haml :'tv-show/update'
  end

  # get  /tv-show/watch/:id......................................................
  get '/tv-show/watch/:id' do
    tv_show = TvShow.get(params[:id])
    if tv_show
      @tv_shows = {}
      tv_show.attachments.each do |attachment|
        supported_mime_type = $config.supported_mime_types.select { |type| type['extension'] == attachment.extension }.first
        if supported_mime_type['type'] === 'video'
          @tv_shows[attachment.id] = { :path => File.join($config.file_properties.video.link_path['public'.length..-1], attachment.filename) }
        end
      end
      if @tv_shows.empty?
        redirect "/tv-show/show/#{tv_show.id}"
      else
        @title = "Now Watching: #{tv_show.show}: #{tv_show.title}"
        haml :'tv-show/watch'
      end
    else
      redirect '/tv-shows'
    end
  end
end
