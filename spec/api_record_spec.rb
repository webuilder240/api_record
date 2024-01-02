# frozen_string_literal: true

RSpec.describe ApiRecord do
  it "has a version number" do
    expect(ApiRecord::VERSION).not_to be nil
  end
end
