# frozen_string_literal: true

module Lsaws
  class SDKParser
    IGNORED_SDKS = [
      "core", "resources", # do not contain any resource listing methods
      "s3control" # requires account_id param for all requests
    ].freeze

    def self.get_sdks
      r = []
      Gem.path.each do |p|
        next unless Dir.exist?(p)

        r.append(*Dir[File.join(p, "gems/aws-sdk-*")].map do |gem_dir|
          a = File.basename(gem_dir).split("-")
          a.size == 4 ? a[2] : nil
        end)
      end
      r.compact.uniq.sort - IGNORED_SDKS
    end

    def initialize(sdk)
      @sdk = sdk
      require "aws-sdk-#{sdk}"
    end

    def client_class_name
      @client_class_name ||=
        begin
          # TODO: use constants from gems/aws-sdk-resources-x.xxx
          c = Aws.constants.find { |x| x.to_s.downcase == @sdk }
          "Aws::#{c}::Client"
        end
    end

    def client_class
      @client_class ||= Kernel.const_get(client_class_name)
    end

    def etype2method(etype)
      ["list_#{etype}", "describe_#{etype}", "get_#{etype}"]
        .find { |m| client_class.public_method_defined?(m) }
    end

    def method2etype(method)
      method.to_s.sub(/^(describe|list|get)_/, "")
    end

    def entity_types
      methods = client_class
                .instance_methods
                .find_all { |m| m =~ /^(describe|list)_.+s$/ && m !~ /(status|access)$/ }

      return [] if methods.empty?

      methods.delete_if do |m|
        rdoc = get_method_rdoc(m)
        next(true) unless rdoc

        required_params = rdoc.scan(/^\s+# @option params \[required, (.+?)\] :(\w+)/)
        required_params.any? || Lsaws.config.dig(@sdk, method2etype(m), "required_params")
      end

      methods.map { |m| m.to_s.sub(/^(describe|list)_/, "") }.sort
    end

    def get_method_rdoc(method)
      @source ||= File.read(client_class.instance_method(method).source_location[0])

      pos = @source =~ /^\s+def\s+#{method}\s*\(/
      return nil unless pos

      chunk = ""
      bs = 4096
      until chunk["\n\n"]
        chunk = @source[pos - bs..pos]
        bs *= 2
      end
      chunk[chunk.rindex("\n\n") + 2..]
    end

    def get_method_api(method)
      # calling private API!
      client_class.api.operation(method)
    end
  end
end
