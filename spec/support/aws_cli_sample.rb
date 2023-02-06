# frozen_string_literal: true

require "json"

module AwsCliSample
  def self.get(sdk, cmd)
    fname = "tmp/aws-cli/awscli/examples/#{sdk}/#{cmd}.rst"
    File.open(fname) do |f|
      line = f.gets
      line = f.gets while line.strip != "Output::"
      line = f.gets until line.start_with?("    ")
      resp = String.new
      while line.start_with?("    ")
        resp << line
        line = f.gets
      end
      JSON.parse(resp)
    end
  end
end
