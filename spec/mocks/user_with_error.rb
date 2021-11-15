require_relative 'user'

class UserWithError < User
  class SaveError < StandardError; end
  class DestroyError < StandardError; end

  def initialize(**args)
    @error_trigger = args[:error_trigger]
    super(**args)
  end

  def attributes=(attributes)
    @error_trigger = attributes[:error_trigger]
    super(attributes)
  end

  def save
    @error_trigger == :save and
      raise SaveError, 'save error'

    @saved = true
  end

  def destroy
    @error_trigger == :destroy and
      raise DestroyError, 'destroy error'

    @destroyed = true
  end
end
