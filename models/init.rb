# encoding: utf-8

%w{actor attachment upload_file video}.each { |lib| require_relative lib }

configure :development do
  DataMapper.finalize
  DataMapper.auto_upgrade!
end

#configure :production do
  #DataMapper.finalize
  #DataMapper.auto_upgrade!
#end
