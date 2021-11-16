class User
  attr_reader :id, :name, :saved, :destroyed, :errors

  def initialize(**args)
    @id = args[:id]
    @name = args[:name]
    @saved = false
    @destroyed = false
    @errors = []
  end

  def self.find(id)
    new(id: id)
  end

  def self.where(id:)
    id.map { new(id: _1) }
  end

  def attributes=(attributes)
    @name = attributes[:name]
  end

  def save!
    @saved = true
  end

  def destroy
    @destroyed = true
  end

  def set_error(error)
    @errors.push(error)
  end
end
