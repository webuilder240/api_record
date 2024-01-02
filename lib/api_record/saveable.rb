module ApiRecord
  module Saveable
    extend ActiveSupport::Concern
    include Base
    include Findable

    class_methods do
      def request_params(param)
        param
      end

      def create(params)
        record = new(params)
        record.save
        record
      end

      def create!(params)
        record = new(params)
        record.save!
        record
      end
    end

    def update!(params)
      self.attributes = params
      save!
    end

    def update(params)
      self.attributes = params
      save
    end

    def save
      return false unless valid?

      result = perform_save_request
      if result
        if response.body.present?
          body = response.body.deep_transform_keys!(&:underscore)
          self.attributes = body
        end
      end
      result
    end

    def save!
      validate!

      perform_save_request!

      if response.body.present?
        body = response.body.deep_transform_keys!(&:underscore)
        self.attributes = body
      end
      self
    end

    def perform_save_request!
      params = self.class.request_params(attributes)
      params.delete("id")
      if new_record?
        request!(:post, "#{self.class.api_path}", params)
      else
        request!(:put, "#{self.class.api_path}/#{id}", params)
      end
    end

    def perform_save_request
      params = self.class.request_params(attributes)
      params.delete("id")
      if new_record?
        request(:post, "#{self.class.api_path}", params)
      else
        request(:put, "#{self.class.api_path}/#{id}", params)
      end
    end
  end
end
