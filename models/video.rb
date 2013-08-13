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

  def audio
    attachment_of_type 'audio'
  end

  def thumbnail
    attachment_of_type 'image'
  end

  def to_hash
    hash = {}
    self.instance_variables.each  {|var| hash[var.to_s.delete('@')] = self.instance_variable_get(var) }
    hash
  end

  def video
    attachment_of_type 'video'
  end

  private

  def attachment_of_type type
    return nil if self.attachments.nil? || self.attachments.empty?
    self.attachments.each do |attachment|
      if $config.supported_mime_types.select { |type| type['extension'] == attachment.extension }.first['type'] == type
        return File.join($config.file_properties.send(type).link_path['public'.length..-1], attachment.filename)
      end
    end
    return nil
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
