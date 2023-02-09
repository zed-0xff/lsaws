# frozen_string_literal: true

module Lsaws
  class Error < StandardError; end

  def self.root
    File.dirname(File.dirname(File.expand_path(__FILE__)))
  end
end

require_relative "lsaws/version"
require_relative "lsaws/sdk_parser"
require_relative "lsaws/cli"
require_relative "lsaws/lister"
