require 'spec_helper'

require_relative '../lib/bulk_model_operation'

require_relative 'mocks/user'
require_relative 'mocks/user_with_error'

RSpec.describe BulkModelOperation do
  let(:bulk_model_operation) {
    BulkModelOperation.new(model_class, attributes_list, **keyword_args)
  }

  let(:keyword_args) { {} }

  describe 'just initialized' do
    let(:model_class) { User }
    let(:attributes_list) {
      [
        { id: 1, name: 'John', _destroy: false },
        { id: 2, name: 'Bill', _destroy: false },
        {        name: 'Will', _destroy: false },
        { id: 3, name: 'Bob' , _destroy: true  }
      ]
    }

    it 'has no error and not saved, not destroyed' do
      expect(bulk_model_operation.errors).to be_empty

      expect(bulk_model_operation.records[0].saved).to be_falsey
      expect(bulk_model_operation.records[1].saved).to be_falsey
      expect(bulk_model_operation.records[2].saved).to be_falsey
      expect(bulk_model_operation.records[3].saved).to be_falsey

      expect(bulk_model_operation.records[0].destroyed).to be_falsey
      expect(bulk_model_operation.records[1].destroyed).to be_falsey
      expect(bulk_model_operation.records[2].destroyed).to be_falsey
      expect(bulk_model_operation.records[3].destroyed).to be_falsey
    end
  end

  describe '.save_and_destroy' do
    subject { bulk_model_operation.save_and_destroy }

    context 'mixed save and destroy with successfully' do
      let(:model_class) { User }
      let(:attributes_list) {
        [
          { id: 1, name: 'John', _destroy: false },
          { id: 2, name: 'Bill', _destroy: false },
          {        name: 'Will', _destroy: false },
          { id: 3, name: 'Bob' , _destroy: true  }
        ]
      }

      it 'saved and destroyed' do
        is_expected.to be_truthy

        expect(bulk_model_operation.records[0].saved).to be_truthy
        expect(bulk_model_operation.records[1].saved).to be_truthy
        expect(bulk_model_operation.records[2].saved).to be_truthy
        expect(bulk_model_operation.records[3].saved).to be_falsey

        expect(bulk_model_operation.records[0].destroyed).to be_falsey
        expect(bulk_model_operation.records[1].destroyed).to be_falsey
        expect(bulk_model_operation.records[2].destroyed).to be_falsey
        expect(bulk_model_operation.records[3].destroyed).to be_truthy

        expect(bulk_model_operation.errors).to be_empty
      end
    end

    context 'custom destroy key' do
      let(:keyword_args) { { destroy_key: :delete } }
      let(:model_class) { User }
      let(:attributes_list) { [
        { id: 1, name: 'John', delete: true },
        { id: 2, name: 'Bob', _destroy: true },
      ] }


      it 'destroy only record that has destroy_key' do
        is_expected.to be_truthy

        expect(bulk_model_operation.records[0].destroyed).to be_truthy
        expect(bulk_model_operation.records[1].destroyed).to be_falsey

        expect(bulk_model_operation.records[0].saved).to be_falsey
        expect(bulk_model_operation.records[1].saved).to be_truthy
      end
    end

    context 'with errors' do
      context 'save error' do
        let(:model_class) { UserWithError }
        let(:attributes_list) {
          [
            { id: 1, name: 'save error', error_trigger: :save }
          ]
        }

        it 'has error' do
          is_expected.to be_falsey

          expect(bulk_model_operation.errors.first).
            to be_kind_of UserWithError::SaveError
        end
      end

      context 'destroy error' do
        let(:model_class) { UserWithError }
        let(:attributes_list) {
          [
            { id: 1, name: 'destroy error', _destroy: true, error_trigger: :destroy }
          ]
        }

        it 'has error' do
          is_expected.to be_falsey

          expect(bulk_model_operation.errors.first).
            to be_kind_of UserWithError::DestroyError
        end
      end

      context 'multiple errors' do
        let(:model_class) { UserWithError }
        let(:attributes_list) {
          [
            { id: 1, name: 'save error',                     error_trigger: :save    },
            { id: 2, name: 'destroy error', _destroy: true,  error_trigger: :destroy }
          ]
        }

        it 'has errors' do
          is_expected.to be_falsey

          expect(bulk_model_operation.errors[0]).
            to be_kind_of UserWithError::SaveError

          expect(bulk_model_operation.errors[1]).
            to be_kind_of UserWithError::DestroyError
        end
      end
    end

    describe 'custom validations' do
      context 'save_validator given' do
        let(:keyword_args) {
          {
            save_validator: -> (record) { record.name == 'invalid' and raise ArgumentError, 'invlaid data' }
          }
        }

        let(:model_class) { User }
        let(:attributes_list) {
          [
            { id: 1, name: 'invalid' },
            { id: 2, name: 'valid'   }
          ]
        }

        it 'has errors' do
          is_expected.to be_falsey

          expect(bulk_model_operation.errors.size).to eq 1

          expect(bulk_model_operation.errors[0]).
            to be_kind_of ArgumentError

          expect(bulk_model_operation.records[1].saved).to be_truthy
        end
      end

      context 'destroy_validator given' do
        let(:keyword_args) {
          {
            destroy_validator: -> (record) { record.name == 'invalid' and raise ArgumentError, 'cannot detstroy' }
          }
        }

        let(:model_class) { User }
        let(:attributes_list) {
          [
            { id: 1, name: 'invalid', _destroy: true },
            { id: 2, name: 'valid'  , _destroy: true }
          ]
        }

        it 'has errors' do
          is_expected.to be_falsey

          expect(bulk_model_operation.errors.size).to eq 1

          expect(bulk_model_operation.errors[0]).
            to be_kind_of ArgumentError

          expect(bulk_model_operation.records[1].destroyed).to be_truthy
        end
      end

      describe 'practical usecase' do
        let(:keyword_args) {
          {
            destroy_key: :delete,
            save_validator:    -> (record) { record.name == 'invalid' and raise ArgumentError, 'invalid data' },
            destroy_validator: -> (record) { record.name == 'invalid' and raise ArgumentError, 'cannot destroy' }
          }
        }
        let(:model_class) { UserWithError }

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
          end
        end
      end
    end
  end
end
