require 'api_record/base'
require 'api_record/index_collection'

module ApiRecord
  module Indexable
    extend ActiveSupport::Concern
    include ApiRecord::Base

    class_methods do
      def api_path
        "#{name.pluralize.underscore}"
      end

      def index(page: 1, limit: 30)
        params = {
          page: page,
          limit: limit
        }
        response = request(:get, "#{api_path}", params)
        if response.success?
          ApiRecord::IndexCollection.new(response.body.map do |attributes| 
            new(attributes.deep_transform_keys!(&:underscore)) 
          end, response)
        else
          raise_api_exception(response)
        end
      end
    end
  end
end
