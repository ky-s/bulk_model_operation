# frozen_string_literal: true

# Bulk operations for Model
#   bulk create, update and destroy
#
class BulkModelOperation
  attr_reader :errors

  def initialize(model_class, attributes_list, destroy_key: :_destroy, save_validator: nil, destroy_validator: nil)
    @model_class = model_class
    @attributes_list = attributes_list
    @destroy_key = destroy_key
    @save_validator = save_validator
    @destroy_validator = destroy_validator

    @errors = []
  end

  def save_and_destroy
    # Batch saving and destroying
    records_and_operations.each do |record, operation|
      if operation == :save
        @save_validator and @save_validator.call(record)
        record.save!
      else
        @destroy_validator and @destroy_validator.call(record)
        record.destroy
      end
    rescue => e
      @errors.push(e)
    end

    @errors.empty?
  end

  def records
    records_and_operations.map(&:first)
  end

  private

  def records_and_operations
    @records_and_operations ||=
      @attributes_list.map do |attributes|
        attributes = attributes.dup

        operation =
          attributes.delete(@destroy_key) ? :destroy : :save

        [build(attributes), operation]
      end
  end

  def build(attributes)
    attributes = attributes.dup

    id = attributes.delete(:id)

    (cache[id] || @model_class.new).tap do |record|
      record.attributes = attributes
    end
  end

  # Cache target records such structure
  # { id => record,... }
  def cache
    @cache ||= begin
      ids = @attributes_list.map { _1[:id] }

      @model_class.where(id: ids).reduce({}) do |acc, record| 
        acc.merge(record.id => record)
      end
    end
  end
end
