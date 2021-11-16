require 'spec_helper'

require_relative '../lib/bulk_model_operation'

require_relative 'mocks/user_with_error'

RSpec.describe BulkModelOperation do
  let(:bulk_model_operation) {
    BulkModelOperation.new(model_class, attributes_list, **keyword_args)
  }
  let(:model_class) { UserWithError }

  subject { bulk_model_operation.save_and_destroy }

  let(:keyword_args) {
    {
      destroy_key: :delete,
      save_validator: -> (record) {
        if record.name == 'invalid'
          error = ArgumentError.new('invalid data')
          record.errors.push(error)
          raise error
        end
      },
      destroy_validator: -> (record) {
        if record.name == 'invalid'
          error = ArgumentError.new('cannot destroy')
          record.errors.push(error)
          raise error
        end
      }
    }
  }

  context 'valid' do
    let(:attributes_list) {
      [
        { id: 1, name: 'John' },
        {        name: 'Bill' },
        { id: 3, name: 'Will', delete: true },
        { id: 4, name: 'Bob' , delete: true }
      ]
    }

    it 'success' do
      subject

      expect(bulk_model_operation.errors.size).to eq 0

      expect(bulk_model_operation.records[0].saved).to be_truthy
      expect(bulk_model_operation.records[1].saved).to be_truthy

      expect(bulk_model_operation.records[2].destroyed).to be_truthy
      expect(bulk_model_operation.records[3].destroyed).to be_truthy
    end
  end

  context 'invalid' do
    let(:attributes_list) {
      [
        { id: 1, name: 'John'    },
        {        name: 'invalid' },
        { id: 2, name: 'Bill',    error_trigger: :save },
        { id: 3, name: 'will',    delete: true },
        { id: 4, name: 'invalid', delete: true },
        { id: 5, name: 'Bob' ,    delete: true, error_trigger: :destroy }
      ]
    }

    it 'has errors' do
      subject

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
