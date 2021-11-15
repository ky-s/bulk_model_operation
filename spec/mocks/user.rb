class User
  attr_reader :id, :name, :saved, :destroyed

  def initialize(**args)
    @id = args[:id]
    @name = args[:name]
    @saved = false
    @destroyed = false
  end

  def self.find(id)
    new(id: id)
  end

  def self.find_by(id:)
    id.map { new(id: _1) }
  end

  def attributes=(attributes)
    @name = attributes[:name]
  end

  def save
    @saved = true
  end

  def destroy
    @destroyed = true
  end
end
