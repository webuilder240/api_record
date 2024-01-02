module ApiRecord
  class TimeoutError < StandardError; end

  class RecordInvalidError < StandardError
    attr_reader :record, :response

    def initialize(record, response = nil)
      @record = record
      @response = response
      message = "Validation failed: #{record.errors.full_messages.join(', ')}"
      super(message)
    end
  end

  class ApiInvalidError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
    end
  end

  class ApiError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
    end
  end

  class HttpClientError < ApiError; end
  class HttpServerError < ApiError; end
  class ApiNotFound < HttpClientError; end
end
