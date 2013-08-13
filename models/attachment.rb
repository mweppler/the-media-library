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
