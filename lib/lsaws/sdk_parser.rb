# frozen_string_literal: true

module Lsaws
  class SDKParser
    def self.get_sdks
      r = []
      Gem.path.each do |p|
        next unless Dir.exist?(p)

        r.append(*Dir[File.join(p, "gems/aws-sdk-*")].map do |gem_dir|
          a = File.basename(gem_dir).split("-")
          a.size == 4 ? a[2] : nil
        end)
      end
      r.compact.uniq.sort - ["core"]
    end

    def initialize(sdk)
      @sdk = sdk
      require "aws-sdk-#{sdk}"
    end

    def client_class_name
      @client_class_name ||=
        begin
          c = Aws.constants.find { |x| x.to_s.downcase == @sdk }
          "Aws::#{c}::Client"
        end
    end

    def client_class
      @client_class ||= Kernel.const_get(client_class_name)
    end

    def entity_types
      methods = client_class
                .instance_methods
                .find_all { |m| m =~ /^(describe|list)_.+s$/ && m !~ /(status|access)$/ }

      return [] if methods.empty?

      data = File.read(client_class.instance_method(methods[0]).source_location[0])
      methods.delete_if do |m|
        rdoc = _get_method_rdoc(data, m)
        next(true) unless rdoc

        required_params = rdoc.scan(/^\s+# @option params \[required, (.+?)\] :(\w+)/)
        required_params.any?
      end

      methods.map { |m| m.to_s.sub(/^(describe|list)_/, "") }.sort
    end

    def _get_method_rdoc(data, method)
      pos = data =~ /^\s+def\s+#{method}\s*\(/
      return nil unless pos

      chunk = ""
      bs = 4096
      until chunk["\n\n"]
        chunk = data[pos - bs..pos]
        bs *= 2
      end
      chunk[chunk.rindex("\n\n") + 2..]
    end
  end
end
