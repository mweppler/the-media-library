##############################################################################
#
#                             The Media Library
#
#-----------------------------------------------------------------------------
#
# Development:
#   start server with: bundle exec shotgun
#
#-----------------------------------------------------------------------------
#
# Routes:
#   get  /
#   get  /movies
#   post /movie/create
#   get  /movie/edit/:id
#   get  /movie/new
#   get  /movie/show/:id
#   post /movie/update/:id
#   get  /movie/watch/:id
#   get  /tv-shows
#   post /tv-show/create
#   get  /tv-show/edit/:id
#   get  /tv-show/new
#   get  /tv-show/show/:id
#   post /tv-show/update/:id
#   get  /tv-show/watch/:id
#
##############################################################################


%w{rubygems bundler/setup compass data_mapper dm-sqlite-adapter sinatra ./media_library}.each { |lib| require lib }
%w{digest/md5 dm-core dm-migrations dm-timestamps haml json ostruct}.each { |lib| require lib }

class Hash
  def self.to_ostructs(obj, memo={})
    return obj unless obj.is_a? Hash
    os = memo[obj] = OpenStruct.new
    obj.each { |k,v| os.send("#{k}=", memo[v] || to_ostructs(v, memo)) }
    os
  end
end

$config = Hash.to_ostructs(YAML.load_file(File.join(Dir.pwd, 'config.yml')))

class UploadFile
  attr_accessor :filename, :tempfile, :type

  def initialize(file)
    raise "Not a file" unless File.file? file

    self.tempfile = File.open(file, 'r')
    self.filename = File.basename file
    self.type = $config.supported_mime_types.select { |type| type['extension'] == File.extname(self.filename).sub(/^\./, '').downcase }.first['mime_type']
  end

  def [](key)
    if key.class == Symbol
      key = key.to_s
    elsif key.class != String
      raise "Expects a String or a Symbol. Saw #{key.class}."
    end
    self.send(key)
  end

  def to_hash
    return { :filename => self.filename, :tempfile => File.absolute_path(self.tempfile), :type => self.type }
  end
end


# Models.......................................................................

class Video
  include DataMapper::Resource

  has n, :actors
  has n, :attachments

  property :id,          Serial
  property :created_at,  DateTime
  property :description, Text
  property :genre,       String
  property :length,      Integer
  property :title,       String
  property :type,        Discriminator#, :default => 'movie'
  property :updated_at,  DateTime

  def to_hash
    hash = {}
    self.instance_variables.each  {|var| hash[var.to_s.delete('@')] = self.instance_variable_get(var) }
    hash
  end
end

class Actor
  include DataMapper::Resource

  belongs_to :video

  property :id,         Serial
  property :name,       String
  property :created_at, DateTime
  property :updated_at, DateTime
end

class Attachment
  include DataMapper::Resource

  belongs_to :video

  property :id,         Serial
  property :created_at, DateTime
  property :extension,  String
  property :filehash,   String
  property :filename,   String
  property :mime_type,  String
  property :path,       Text
  property :size,       Integer
  property :updated_at, DateTime

  def handle_upload(file, handle_options = {})
    self.filehash  = Digest::MD5.hexdigest(file[:tempfile].read)
    file[:tempfile].rewind

    self.extension = File.extname(file[:filename]).sub(/^\./, '').downcase

    supported_mime_type = $config.supported_mime_types.select { |type| type['extension'] == self.extension }.first
    return false unless supported_mime_type

    self.filename  = self.filehash + '.' + self.extension
    self.mime_type = file[:type]
    self.size      = File.size(file[:tempfile])

    if handle_options.empty? || handle_options[:move_file]
      self.path = File.join(Dir.pwd, $config.file_properties.send(supported_mime_type['type']).absolute_path, self.filename)
      unless File.exists? path
        File.open(path, 'wb') do |f|
          f.write(file[:tempfile].read)
        end
      end
    else
      self.path = file[:tempfile].to_path
    end

    symlink = File.join($config.file_properties.send(supported_mime_type['type']).link_path, self.filename)
    unless File.exists? symlink
      FileUtils.symlink(self.path, symlink)
    end
  end
end

#class Book   < Video; end
class Movie  < Video; end
#class Photo  < Video; end
#class Song   < Video; end
class TvShow < Video
  property :episode, Integer
  property :season,  Integer
  property :show,  String
end


configure :development do
  DataMapper.finalize
  DataMapper.auto_upgrade!
end

# set utf-8 for outgoing
before do
  headers 'Content-Type' => 'text/html; charset=utf-8'
end

before %r{.+\.json$} do
  headers 'Content_Type' => 'application/json; charset=utf-8'
end


# Stylesheet Route..................................................................
get '/stylesheets/:name.css' do
  content_type 'text/css', :charset => 'utf-8'
  scss(:"stylesheets/#{params[:name]}" )
end


# Root Route..................................................................
get '/' do
  @title = 'The Media Library'
  haml :index
end


# Movie Routes.................................................................

# /movies......................................................................
get '/movies' do
  @title = 'Movies'
  @movies = Movie.all(:order => [:title.asc])
  haml 'movie/list'.to_sym
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

  haml 'movie/create'.to_sym
end

# /movie/edit/:id..............................................................
get '/movie/edit/:id' do
  @movie = Movie.get(params[:id])
  @title = 'Edit Movie Details'
  haml 'movie/edit'.to_sym
end

# /movie/new...................................................................
get '/movie/new' do
  @title = 'Upload Movie'
  haml 'movie/new'.to_sym
end

# /movie/show/:id..............................................................
get '/movie/show/:id' do
  @movie = Movie.get(params[:id])
  if @movie
    @title = @movie.title
    haml 'movie/show'.to_sym
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

  if @movie.update(params[:movie])
    @message = 'Movie was saved.'
  else
    @message = 'Movie was not saved.'
  end

  haml 'movie/update'.to_sym
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
      haml 'movie/watch'.to_sym
    end
  else
    redirect '/movies'
  end
end


# TV Show Routes...............................................................

# get  /tv-shows...............................................................
get '/tv-shows' do
  @title = 'TV Shows'
  @tv_shows = TvShow.all(:order => [:show.asc, :episode.asc])
  haml 'tv-show/list'.to_sym
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

  haml 'tv-show/create'.to_sym
end

# get  /tv-show/edit/:id.......................................................
get '/tv-show/edit/:id' do
  @tv_show = TvShow.get(params[:id])
  @title = 'Edit TV Show Details'
  haml 'tv-show/edit'.to_sym
end

# get  /tv-show/new............................................................
get '/tv-show/new' do
  @title = 'Upload TV Show'
  haml 'tv-show/new'.to_sym
end

# get  /tv-show/show/:id.......................................................
get '/tv-show/show/:id' do
  @tv_show = TvShow.get(params[:id])
  if @tv_show
    @title = @tv_show.title
    haml 'tv-show/show'.to_sym
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

  if @tv_show.update(params[:tv_show])
    @message = 'TV Show was saved.'
  else
    @message = 'TV Show was not saved.'
  end

  haml 'tv-show/update'.to_sym
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
      haml 'tv-show/watch'.to_sym
    end
  else
    redirect '/tv-shows'
  end
end


# API V1.......................................................................

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
    all_media << { :media => {
        :id          => medium.id,
        :description => medium.description,
        :genre       => medium.genre,
        :length      => medium.length,
        :title       => medium.title,
        :type        => medium.type,
        :audio       => audio,
        :thumb       => thumb,
        :video       => video
      }
    }
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
      audio << File.join($config.file_properties.video.link_path['public'.length..-1], attachment.filename)
    end
    if supported_mime_type['type'] === 'video'
      video << File.join($config.file_properties.video.link_path['public'.length..-1], attachment.filename)
    end
    if supported_mime_type['type'] === 'image'
      thumb << File.join($config.file_properties.video.link_path['public'.length..-1], attachment.filename)
    end
  end

  return audio, thumb, video
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

  { :media => {
      :id          => media.id,
      :description => media.description,
      :genre       => media.genre,
      :length      => media.length,
      :title       => media.title,
      :type        => media.type,
      :audio       => audio,
      :thumb       => thumb,
      :video       => video
    }
  }.to_json
end

get '/api/v1/movies.json' do
  api_v1_get_all_media 'movie'
end

get '/api/v1/movie/:id.json' do
  api_v1_get_media 'movie', params[:id]
end

get '/api/v1/tv-shows.json' do
  api_v1_get_all_media 'tv-show'
end

get '/api/v1/tv-show/:id.json' do
  api_v1_get_media 'tv-show', params[:id]
end

