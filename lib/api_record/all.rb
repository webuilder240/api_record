require 'active_support/all'
require "api_record/base"
require "api_record/destroyable"
require "api_record/errors"
require "api_record/findable"
require "api_record/indexable"
require "api_record/saveable"

module ApiRecord
  module All
    extend ActiveSupport::Concern

    include ApiRecord::Base
    include ApiRecord::Findable
    include ApiRecord::Indexable
    include ApiRecord::Saveable
    include ApiRecord::Destroyable
  end
end
