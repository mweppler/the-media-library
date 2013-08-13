Dir.chdir(File.dirname(__FILE__))

%w{rubygems bundler/setup compass data_mapper dm-core dm-migrations dm-sqlite-adapter dm-timestamps haml json logger sinatra}.each { |lib| require lib }

%w{lib/hash}.each { |lib| require_relative lib }

class MediaLibrary < Sinatra::Application

  #disable :sessions
  use Rack::Session::Pool, :expire_after => 2592000

	#set :clean_trace, true
  set :environment,    :development
  #set :environment,    :production
  set :haml,           { :format => :html5 }#, :escape_html => true }
  set :protection,     :session => true
  set :raise_errors,   true
  set :run,            false
  #set :scss,           { :style => :compact, :debug_info => false }
  set :session_secret, 'the-media-library-20130714'

  $config = Hash.to_ostructs(YAML.load_file(File.join(Sinatra::Application.root, 'config', 'config.yml')))
  Compass.add_project_configuration(File.join(Sinatra::Application.root, 'config', 'compass.rb'))
  DataMapper::setup(:default, File.join('sqlite3://', Sinatra::Application.root, 'development.db'))
  #DB = DataMapper::setup(:default, File.join('sqlite3://', Dir.pwd, 'development.db'))

	configure :production do
		#set :haml, { :ugly => true }
		set :dump_errors, false
	end

  configure :development do
		$logger = Logger.new(STDOUT)
  end

  #after do
    #response['X-'] = ''
	#end

  before do
    headers 'Content-Type' => 'text/html; charset=utf-8'
  end

  before %r{.+\.json$} do
    headers 'Content_Type' => 'application/json; charset=utf-8'
    #headers 'Access-Control-Allow-Origin']  => '*'
    #headers 'Access-Control-Allow-Methods'] => ''
  end

  helpers do
		include Rack::Utils
		alias_method :h, :escape_html
	end
end

%w{helpers/init models/init routes/init}.each { |lib| require_relative lib }
