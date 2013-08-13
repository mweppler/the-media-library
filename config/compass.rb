if defined?(Sinatra)
  environment  = :development
  output_style = :expanded # possible options include: :expanded, :nested, :compact & :compressed
  project_path = Sinatra::Application.root
else
  css_dir         = File.join 'static', 'stylesheets'
  environment     = :production
  line_comments   = false # Uncomment to disable debugging comments that display the original location of your selectors.
  output_style    = :compressed
  relative_assets = true # Uncomment to enable relative paths to assets via compass helper functions.
end

# This is common configuration
http_path             = '/public/'
http_images_path      = File.join 'public', 'images'
http_javascripts_dir  = File.join 'public', 'javascripts'
http_stylesheets_path = File.join 'public', 'stylesheets'
images_dir            = File.join 'public', 'images'
javascripts_dir       = File.join 'public', 'javascripts'
sass_dir              = File.join 'views',  'stylesheets'
