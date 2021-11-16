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

  def save!
    if @error_trigger == :save
      error = SaveError.new('save error')
      @errors.push(error)
      raise error
    end

    @saved = true
  end

  def destroy
    if @error_trigger == :destroy
      error = DestroyError.new('destroy error')
      @errors.push(error)
      raise error
    end

    @destroyed = true
  end
end
