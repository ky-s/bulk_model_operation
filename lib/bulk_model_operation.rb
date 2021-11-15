# frozen_string_literal: true

# Bulk operations for Model
#   bulk create, update and destroy
#
class BulkModelOperation
  attr_reader :errors

  def initialize(model_class, attributes_list, destroy_key: :_destroy)
    @model_class = model_class
    @attributes_list = attributes_list
    @destroy_key = destroy_key

    @errors = []
  end

  def save_and_destroy
    # Batch saving and destroying
    records_and_operations.each do |record, operation|
      operation == :save ? record.save : record.destroy
    end

  rescue => e
    @errors.push(e)

  ensure
    return @errors.empty?
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

    # OPTIMIZE: It has N+1 problem.
    (id ? @model_class.find(id) : @model_class.new).tap do |record|
      record.attributes = attributes
    end
  end
end
