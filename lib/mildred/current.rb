# frozen_string_literal: true

require "active_support"
require "active_support/current_attributes"

module Mildred
  class Current < ActiveSupport::CurrentAttributes
    attribute :container_id, :noop
  end
end
