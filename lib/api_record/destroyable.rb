require "api_record/base"
require "api_record/findable"
module ApiRecord
  module Destroyable
    extend ActiveSupport::Concern
    include ApiRecord::Base
    include ApiRecord::Findable

    def destroy
      request(:delete, "#{self.class.api_path}/#{id}")
      if response.success?
        true
      else
        handle_api_errors()
        false
      end
    end

    def destroy!
      request(:delete, "#{self.class.api_path}/#{id}")
      if response.success?
        self
      else
        raise_api_exception()
      end
    end
  end
end
