require_relative 'errors'

module ApiRecord
  module Findable
    extend ActiveSupport::Concern

    include Base

    included do
      attribute :id, :integer
    end

    class_methods do
      def api_path
        "#{name.pluralize.underscore}"
      end

      def find(id)
        response = request(:get, "#{api_path}/#{id}")
        if response.success?
          body = response.body.deep_transform_keys!(&:underscore)
          new(body)
        else
          raise_api_exception(response)
        end
      end
    end

    def new_record?
      id.nil?
    end
  end
end
