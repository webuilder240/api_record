# require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ApiRecord::Base do
  class TestApiRecord
    include ApiRecord::All

    attribute :name, :string
    attribute :email, :string

    validates :name, presence: true
    validates :email, presence: true, format: { with: /\A[^@\s]+@[^@\s]+\z/, message: "is not a valid email address" }

    def self.request_params(param)
      {
        test_api_record: param.compact
      }
    end

    def self.api_path
      'test_api_records'
    end
  end

  before do
    stub_const('Api::TestApiRecord', TestApiRecord)
  end

  let(:valid_attributes) do
    {
      name: 'John Doe',
      email: 'john.doe@example.com'
    }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      record = Api::TestApiRecord.new(valid_attributes)
      expect(record).to be_valid
    end

    it 'is invalid with empty name' do
      record = Api::TestApiRecord.new(valid_attributes.merge(name: ''))
      expect(record).to be_invalid
    end

    it 'is invalid with empty email' do
      record = Api::TestApiRecord.new(valid_attributes.merge(email: ''))
      expect(record).to be_invalid
    end

    it 'is invalid with incorrect email format' do
      record = Api::TestApiRecord.new(valid_attributes.merge(email: 'invalid_email'))
      expect(record).to be_invalid
    end
  end

  describe 'Api::TestApiRecord api_path' do
    it 'returns the correct api_path' do
      expect(Api::TestApiRecord.api_path).to eq('test_api_records')
    end
  end

  let(:base_api_url) { 'http://localhost:3000' }

  describe 'Api::TestApiRecord index' do
    it 'returns an array of records' do
      stub_request(:get, "#{base_api_url}/test_api_records?page=1&limit=30")
        .to_return(status: 200, body: [{ id: 1, name: 'John Doe', email: 'john.doe@example.com' }].to_json, headers: {'Accept': 'appliation/json', 'content-type': 'application/json'})

      records = Api::TestApiRecord.index
      expect(records).to be_an(ApiRecord::IndexCollection)
      expect(records.items.first).to be_an_instance_of(Api::TestApiRecord)
      expect(records.items.first.name).to eq('John Doe')
    end
  end

  describe 'Api::TestApiRecord find' do
    it 'returns the record with the specified id' do
      stub_request(:get, "#{base_api_url}/test_api_records/1")
        .to_return(status: 200, body: { id: 1, name: 'John Doe', email: 'john.doe@example.com' }.to_json, headers: {'content-type': 'application/json'})

      record = Api::TestApiRecord.find(1)
      expect(record).to be_an_instance_of(Api::TestApiRecord)
      expect(record.id).to eq(1)
      expect(record.name).to eq('John Doe')
    end
  end

  describe 'Api::TestApiRecord create' do
    it 'creates a new record and returns it' do
      stub_request(:post, "#{base_api_url}/test_api_records")
        .with(body: { test_api_record: valid_attributes })
        .to_return(status: 201, body: valid_attributes.merge(id: 1).to_json, headers: {'content-type': 'application/json'})

      record = Api::TestApiRecord.create(valid_attributes)
      expect(record).to be_an_instance_of(Api::TestApiRecord)
      expect(record.id).to eq(1)
      expect(record.name).to eq('John Doe')
    end
  end

  describe 'Api::TestApiRecord create!' do
    it 'creates a new record and returns it' do
      stub_request(:post, "#{base_api_url}/test_api_records")
        .with(body: { test_api_record: valid_attributes })
        .to_return(status: 201, body: valid_attributes.merge(id: 1).to_json, headers: {'content-type': 'application/json'})

      record = Api::TestApiRecord.create!(valid_attributes)
      expect(record).to be_an_instance_of(Api::TestApiRecord)
      expect(record.id).to eq(1)
      expect(record.name).to eq('John Doe')
    end
  end

  describe 'Api::TestApiRecord destroy' do
    it 'deletes the record with the specified id' do
      stub_request(:get, "#{base_api_url}/test_api_records/1")
        .to_return(status: 200, body: valid_attributes.merge(id: 1).to_json, headers: {'content-type': 'application/json'})

      stub_request(:delete, "#{base_api_url}/test_api_records/1")
        .to_return(status: 204, body: '', headers: {})

      record = Api::TestApiRecord.find(1)
      expect(record.destroy).to be_truthy
    end
  end

  describe 'Api::TestApiRecord destroy!' do
    it 'deletes the record with the specified id' do
      stub_request(:get, "#{base_api_url}/test_api_records/1")
        .to_return(status: 200, body: valid_attributes.merge(id: 1).to_json, headers: {'content-type': 'application/json'})

      stub_request(:delete, "#{base_api_url}/test_api_records/1")
        .to_return(status: 204, body: '', headers: {})

      record = Api::TestApiRecord.find(1)
      expect(record.destroy!).to be_an_instance_of(Api::TestApiRecord)
    end
  end

  describe 'Api::TestApiRecord save' do
    it 'saves a new record when the record is valid' do
      stub_request(:post, "#{base_api_url}/test_api_records")
        .with(body: { test_api_record: valid_attributes })
        .to_return(status: 201, body: valid_attributes.merge(id: 1).to_json, headers: {'content-type': 'application/json'})

      record = Api::TestApiRecord.new(valid_attributes)
      expect(record.save).to be_truthy
      expect(record.id).to eq(1)
    end

    it 'returns false when the record is invalid' do
      record = Api::TestApiRecord.new(valid_attributes.merge(name: ''))
      expect(record.save).to be_falsey
    end

    context 'when updating an existing record' do
      before do
        stub_request(:get, "http://localhost:3000/test_api_records/1").
          to_return(status: 200, body: {
            id: 1,
            name: "John Doe",
            email: "john.doe@example.com"
          }.to_json, headers: { 'content-type': 'application/json' })
  
        stub_request(:put, "http://localhost:3000/test_api_records/1").
          with(
            body: {"test_api_record"=>{"id"=>1, "name"=>"Jane Doe", "email"=>"jane.doe@example.com"}}).
          to_return(status: 200, body: {
            id: 1,
            name: "Jane Doe",
            email: "jane.doe@example.com"
          }.to_json, headers: { 'content-type': 'application/json' }
          )
      end
  
      it 'updates the existing record and returns true' do
        record = Api::TestApiRecord.find(1)
        record.name = "Jane Doe"
        record.email = "jane.doe@example.com"
  
        expect(record.save).to be true
        expect(record.name).to eq("Jane Doe")
        expect(record.email).to eq("jane.doe@example.com")
      end
    end
  end

  describe 'Api::TestApiRecord save!' do
    it 'saves a new record when the record is valid' do
      stub_request(:post, "#{base_api_url}/test_api_records")
        .with(body: { test_api_record: valid_attributes })
        .to_return(status: 201, body: valid_attributes.merge(id: 1).to_json, headers: {'content-type': 'application/json'})

      record = Api::TestApiRecord.new(valid_attributes)
      expect { record.save! }.not_to raise_error
      expect(record.id).to eq(1)
    end

    it 'raises an error when the record is invalid' do
      record = Api::TestApiRecord.new(valid_attributes.merge(name: ''))
      expect { record.save! }.to raise_error(ApiRecord::RecordInvalidError)
    end

    context 'when updating an existing record' do
      before do
        stub_request(:get, "http://localhost:3000/test_api_records/1").
          to_return(status: 200, body: {
            id: 1,
            name: "John Doe",
            email: "john.doe@example.com"
          }.to_json, headers: { 'content-type': 'application/json' })
  
        stub_request(:put, "http://localhost:3000/test_api_records/1").
          with(
            body: {"test_api_record"=>{"id"=>1, "name"=>"Jane Doe", "email"=>"jane.doe@example.com"}}).
          to_return(status: 200, body: {
            id: 1,
            name: "Jane Doe",
            email: "jane.doe@example.com"
          }.to_json, headers: { 'content-type': 'application/json' })
      end
  
      it 'updates the existing record and returns the updated record' do
        record = Api::TestApiRecord.find(1)
        record.name = "Jane Doe"
        record.email = "jane.doe@example.com"
  
        expect { record.save! }.not_to raise_error
        expect(record.name).to eq("Jane Doe")
        expect(record.email).to eq("jane.doe@example.com")
      end
    end
  end
  describe 'Error handling' do
    let(:api_record) { Api::TestApiRecord.new(id: 1, name: 'John Doe', email: 'john.doe@example.com') }

    
    before do
      stub_request(:get, "#{base_api_url}/test_api_records/1").
        to_return(status: 200, body: {
          id: 1,
          name: "John Doe",
          email: "john.doe@example.com"
        }.to_json, headers: { 'content-type': 'application/json' })

      stub_request(:put, "#{base_api_url}/test_api_records/1").
        with(body: { test_api_record: { id: 1, name: 'John Doe', email: 'john.doe@example.com' } }).
        to_return(status: 200, body: {
          id: 1,
          name: "John Doe",
          email: "john.doe@example.com"
        }.to_json, headers: { 'content-type': 'application/json' })
    end

    context 'when status is 404' do
      it 'raises ApiNotFound' do
        stub_request(:put, "#{base_api_url}/test_api_records/1").
          with(body: { test_api_record: { id: 1, name: 'John Doe', email: 'john.doe@example.com' } }).
          to_return(status: 404)
    
        expect {
          api_record.save!
        }.to raise_error(ApiRecord::ApiNotFound)
      end
    end
    
    context 'when status is 422' do
      it 'raises ApiInvalidError' do
        stub_request(:put, "#{base_api_url}/test_api_records/1").
          with(body: { test_api_record: { id: 1, name: 'John Doe', email: 'john.doe@example.com' } }, headers: { 'content-type': 'application/json' })
          .to_return(status: 422)
    
        expect {
          api_record.save!
        }.to raise_error(ApiRecord::RecordInvalidError)
      end
    end
    
    context 'when status is 400..499 (except 404 and 422)' do
      it 'raises HttpClientError' do
        stub_request(:put, "#{base_api_url}/test_api_records/1").
          with(body: { test_api_record: { id: 1, name: 'John Doe', email: 'john.doe@example.com' } }, headers: { 'content-type': 'application/json' })
          .to_return(status: 400)
    
        expect {
          api_record.save!
        }.to raise_error(ApiRecord::HttpClientError)
      end
    end

    context 'when status is 500..599' do
      it 'raises HttpServerError' do
        stub_request(:put, "#{base_api_url}/test_api_records/1").to_return(status: 500)

        expect {
          api_record.save!
        }.to raise_error(ApiRecord::HttpServerError)
      end
    end
  end
end
