class MediaLibrary < Sinatra::Application

  # API V1.....................................................................

  get '/api/v1/movie/:id.json' do
    api_v1_get_media 'movie', params[:id]
  end

  get '/api/v1/movies.json' do
    api_v1_get_all_media 'movie'
  end

  get '/api/v1/movies/genres.json' do
    api_v1_get_genres 'Movie'
  end

  get '/api/v1/tv-show/:id.json' do
    api_v1_get_media 'tv-show', params[:id]
  end

  get '/api/v1/tv-shows.json' do
    api_v1_get_all_media 'tv-show'
  end

  get '/api/v1/tv-shows/genres.json' do
    api_v1_get_genres 'TvShow'
  end

  get '/api/v1/tv-shows/shows.json' do
    api_v1_get_tv_shows
  end

  private

  def api_v1_get_all_media(media_type)
    if media_type == 'audio'
      media = Music.all(:order => [:title.asc])
    elsif media_type == 'movie'
      media = Movie.all(:order => [:title.asc])
    elsif media_type == 'tv-show'
      media = TvShow.all(:order => [:show.asc, :episode.asc])
    end

    all_media = []
    media.each do |medium|
      audio, thumb, video = api_v1_get_attachments(medium)
      media_hash = {
        :audio       => audio,
        :created_at  => medium.created_at,
        :description => medium.description,
        :genres      => medium.genre.gsub(' ', '').split(','),
        :id          => medium.id,
        :length      => medium.length,
        :thumb       => thumb,
        :title       => medium.title,
        :type        => medium.type,
        :video       => video
      }
      if media_type == 'tv-show'
        media_hash.merge!({
          :episode     => medium.episode,
          :season      => medium.season,
          :show        => medium.show
        })
      end
      all_media << media_hash
    end
    all_media.to_json
  end

  def api_v1_get_attachments(media)
    audio = []
    thumb = []
    video = []

    media.attachments.each do |attachment|
      supported_mime_type = $config.supported_mime_types.select { |type| type['extension'] == attachment.extension }.first
      if supported_mime_type['type'] === 'audio'
        audio << File.join($config.file_properties.audio.link_path['public'.length..-1], attachment.filename)
      end
      if supported_mime_type['type'] === 'video'
        video << File.join($config.file_properties.video.link_path['public'.length..-1], attachment.filename)
      end
      if supported_mime_type['type'] === 'image'
        thumb << File.join($config.file_properties.image.link_path['public'.length..-1], attachment.filename)
      end
    end

    return audio, thumb, video
  end

  def api_v1_get_genres media_type
    data = repository(:default).adapter.select("SELECT DISTINCT(genre) FROM videos WHERE type='#{media_type}'")
    genres = []
    data.each do |genre_set|
      genres << genre_set.gsub(' ', '').split(',')
    end
    { :genres => genres.flatten.uniq.sort }.to_json
  end

  def api_v1_get_media(media_type, id)
    if media_type == 'audio'
      media = Music.get(params[:id])
    elsif media_type == 'movie'
      media = Movie.get(params[:id])
    elsif media_type == 'tv-show'
      media = TvShow.get(params[:id])
    end

    audio, thumb, video = api_v1_get_attachments(media)

    #media.to_hash.merge({ :audio => audio, :thumb => thumb, :video => video}).to_json

    media_hash = {
      :audio       => audio,
      :created_at  => medium.created_at,
      :description => medium.description,
      :genres      => medium.genre.gsub(' ', '').split(','),
      :id          => medium.id,
      :length      => medium.length,
      :thumb       => thumb,
      :title       => medium.title,
      :type        => medium.type,
      :video       => video
    }
    if media_type == 'tv-show'
      media_hash.merge!({
        :episode     => medium.episode,
        :season      => medium.season,
        :show        => medium.show
      })
    end
    media_hash.to_json
  end

  def api_v1_get_tv_shows
    data = repository(:default).adapter.select("SELECT DISTINCT(show) FROM videos WHERE type='TvShow'")
    { :shows => data.sort }.to_json
  end

end
