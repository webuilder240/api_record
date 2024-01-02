require "active_model"
require 'active_support/all'
require "faraday"
require_relative 'errors'

module ApiRecord
  module Base
    extend ActiveSupport::Concern
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Serializers::JSON

    included do
      private 

      attr_accessor :response
    end

    class_methods do
      def api_url
        'http://localhost:3000'
      end

      def client
        ::Faraday.new(url: api_url) do |faraday|
          configure_faraday(faraday)
        end
      end

      def configure_faraday(faraday)
        default_config.call(faraday)
        @config_f.call(faraday) if @config_f
      end

      def default_config
        lambda do |faraday|
          faraday.adapter ::Faraday.default_adapter
          faraday.request :json
          # faraday.response :logger unless Rails.env.test?
          faraday.response :json
        end
      end

      def faraday_configure(&block)
        @config_f = block
      end

      def raise_api_exception(response)
        case response.status
        when 404
          raise ApiNotFound.new(response), "Record not found"
        when 422
          raise ApiInvalidError.new(response), "Invalid data"
        when 400..499
          raise HttpClientError.new(response), "Client error"
        when 500..599
          raise HttpServerError.new(response), "Server error"
        else
          raise ApiError.new(response), "Api Error"
        end
      end

      def request(method, *args, &block)
        response = client.public_send(method, *args) do |req|
          yield req if block_given?
        end
        if response.success?
          response
        else
          raise_api_exception(response)
        end
      end
    end

    def inspect
      attributes_to_display = self.class.attribute_names.map(&:to_s) + ['response']
      attributes_string = attributes_to_display.map { |attr| "#{attr}: #{send(attr).inspect}" }.join(', ')
      "#<#{self.class.name} #{attributes_string}>"
    end

    def has_error?
      errors.any?
    end

    def validate!
      raise RecordInvalidError.new(self) unless valid?
    end

    private

    def request(method, *args, &block)
      @response = self.class.client.public_send(method, *args) do |req|
        yield req if block_given?
      end
      if response.success?
        true
      else
        handle_api_errors
      end
    end

    def request!(method, *args, &block)
      @response = self.class.client.public_send(method, *args) do |req|
        yield req if block_given?
      end
      if response.success?
        self
      else
        raise_api_exception
      end
    end

    def raise_api_exception
      case response.status
      when 404
        raise ApiNotFound.new(response), "Record not found"
      when 422
        add_api_errors
        raise RecordInvalidError.new(self, response)
      when 400..499
        raise HttpClientError.new(response), "Client error"
      when 500..599
        raise HttpServerError.new(response), "Server error"
      else
        raise ApiError.new(response), "Api Error"
      end
    end

    def handle_api_errors
      raise_api_exception
    rescue RecordInvalidError
      false
    end

    def add_api_errors
      error_message = :unknown_error

      # Get the custom error message if available, otherwise use the default message
      custom_error_key = "activemodel.errors.models.#{self.class.name.underscore}.response.#{error_message}"
      common_error_key = "activemodel.errors.api_record.response.#{error_message}"
      error_message_text = I18n.t(custom_error_key, default: I18n.t(common_error_key))

      errors.add(:response, error_message_text)

      error_response = response.body
      if error_response.is_a?(Hash)
        error_response.each do |key, error_details|
          error_details.each do |message|
            errors.add(key, message)
          end
        end
      end
    end
  end
end
