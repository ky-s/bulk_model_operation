require 'spec_helper'

require_relative '../lib/bulk_model_operation'

require_relative 'mocks/user_with_error'

RSpec.describe BulkModelOperation do
  context 'valid' do
    it 'success' do
      #
      # Setup BulkModelOperation
      #
      bulk_model_operation = -> {
        #
        # Attributes list for bulk operation
        #
        attributes_list = [
          { id: 1, name: 'John' },
          {        name: 'Bill' },
          { id: 3, name: 'Will', delete: true },
          { id: 4, name: 'Bob' , delete: true }
        ]

        #
        # Custom validator
        #
        validator = -> (record) {
          if record.name == 'invalid'
            error = ArgumentError.new('invalid data')
            record.errors.push(error)
            raise error
          end
        }

        BulkModelOperation.new(
          UserWithError,
          attributes_list,
          destroy_key: :delete,
          save_validator: validator,
          destroy_validator: validator
        )
      }.call

      #
      # Bulk saving and destroying
      #
      bulk_model_operation.save_and_destroy

      #
      # Assertions
      #
      expect(bulk_model_operation.errors.size).to eq 0

      expect(bulk_model_operation.records[0].saved).to be_truthy
      expect(bulk_model_operation.records[1].saved).to be_truthy

      expect(bulk_model_operation.records[2].destroyed).to be_truthy
      expect(bulk_model_operation.records[3].destroyed).to be_truthy
    end
  end

  context 'invalid' do
    it 'has errors' do
      #
      # Setup BulkModelOperation
      #
      bulk_model_operation = -> {
        #
        # Attributes list for bulk operation
        #
        attributes_list = [
          { id: 1, name: 'John'    },
          {        name: 'invalid' },
          { id: 2, name: 'Bill',    error_trigger: :save },
          { id: 3, name: 'will',    delete: true },
          { id: 4, name: 'invalid', delete: true },
          { id: 5, name: 'Bob' ,    delete: true, error_trigger: :destroy }
        ]

        #
        # Custom validator
        #
        validator = -> (record) {
          if record.name == 'invalid'
            error = ArgumentError.new('invalid data')
            record.errors.push(error)
            raise error
          end
        }

        BulkModelOperation.new(
          UserWithError,
          attributes_list,
          destroy_key: :delete,
          save_validator: validator,
          destroy_validator: validator
        )
      }.call

      #
      # Bulk saving and destroying
      #
      bulk_model_operation.save_and_destroy

      #
      # Assertions
      #
      expect(bulk_model_operation.errors.size).to eq 4

      expect(bulk_model_operation.errors[0]).
        to be_kind_of ArgumentError
      expect(bulk_model_operation.errors[1]).
        to be_kind_of UserWithError::SaveError
      expect(bulk_model_operation.errors[2]).
        to be_kind_of ArgumentError
      expect(bulk_model_operation.errors[3]).
        to be_kind_of UserWithError::DestroyError

      expect(bulk_model_operation.records[0].saved).to be_truthy
      expect(bulk_model_operation.records[1].saved).to be_falsey
      expect(bulk_model_operation.records[2].saved).to be_falsey

      expect(bulk_model_operation.records[3].destroyed).to be_truthy
      expect(bulk_model_operation.records[4].destroyed).to be_falsey
      expect(bulk_model_operation.records[5].destroyed).to be_falsey

      expect(bulk_model_operation.records[1].errors.first).
        to be_kind_of ArgumentError
      expect(bulk_model_operation.records[2].errors.first).
        to be_kind_of UserWithError::SaveError
      expect(bulk_model_operation.records[4].errors.first).
        to be_kind_of ArgumentError
      expect(bulk_model_operation.records[5].errors.first).
        to be_kind_of UserWithError::DestroyError
    end
  end
end
