# frozen_string_literal: true

require "yaml"

module Lsaws
  class Error < StandardError; end

  def self.root
    File.dirname(File.dirname(File.expand_path(__FILE__)))
  end

  def self.config
    @config ||= YAML.load_file(File.join(Lsaws.root, "lsaws.yml"))
  end
end

require_relative "lsaws/version"
require_relative "lsaws/sdk_parser"
require_relative "lsaws/cli"
require_relative "lsaws/utils"
require_relative "lsaws/lister"
