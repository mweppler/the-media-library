class Actor
  include DataMapper::Resource

  belongs_to :video

  property :id,         Serial
  property :name,       String
  property :created_at, DateTime
  property :updated_at, DateTime
end
