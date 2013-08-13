require 'digest/md5'

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
