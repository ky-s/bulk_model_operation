require 'spec_helper'
require_relative '../lib/bulk_model_operation'
require_relative 'mocks/user'
require_relative 'mocks/user_with_error'

RSpec.describe BulkModelOperation do
  let(:bulk_model_operation) { BulkModelOperation.new(model_class, attributes_list, **keyword_args) }
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

    subject { bulk_model_operation }

    it 'has no error and not saved, not destroyed' do
      expect(subject.errors).to be_empty

      expect(subject.records[0].saved).to be_falsey
      expect(subject.records[1].saved).to be_falsey
      expect(subject.records[2].saved).to be_falsey
      expect(subject.records[3].saved).to be_falsey

      expect(subject.records[0].destroyed).to be_falsey
      expect(subject.records[1].destroyed).to be_falsey
      expect(subject.records[2].destroyed).to be_falsey
      expect(subject.records[3].destroyed).to be_falsey
    end
  end

  describe 'save_and_destroy' do
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

      it { is_expected.to be_truthy }

      it 'saved and destroyed' do
        subject

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

      it { is_expected.to be_truthy }

      it 'destroy only record that has destroy_key' do
        subject

        expect(bulk_model_operation.records[0].destroyed).to be_truthy
        expect(bulk_model_operation.records[1].destroyed).to be_falsey

        expect(bulk_model_operation.records[0].saved).to be_falsey
        expect(bulk_model_operation.records[1].saved).to be_truthy
      end
    end

    context 'with errors' do
      context 'save error' do
        let(:model_class) { UserWithError }
        let(:attributes_list) { [{ id: 1, name: 'save error', error_trigger: :save }] }

        it { is_expected.to be_falsey }

        it 'has error' do
          subject

          expect(bulk_model_operation.errors.first).to be_kind_of UserWithError::SaveError
        end
      end

      context 'destroy error' do
        let(:model_class) { UserWithError }
        let(:attributes_list) { [{ id: 1, name: 'destroy error', _destroy: true, error_trigger: :destroy }] }

        it { is_expected.to be_falsey }

        it 'has error' do
          subject

          expect(bulk_model_operation.errors.first).to be_kind_of UserWithError::DestroyError
        end
      end
    end
  end
end
