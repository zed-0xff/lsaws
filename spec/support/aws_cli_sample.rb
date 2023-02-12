# frozen_string_literal: true

require "json"
require "active_support/core_ext/hash"
require "active_support/core_ext/string/inflections"

module AwsCliSample
  class FullAwsStub < Aws::Stubbing::EmptyStub

    # added keeping `visited` list between different nested classes, see emrcontainers:job_templates
    def stub visited = []
      if @rules
        stub_ref(@rules, visited)
      else
        EmptyStructure.new
      end
    end

    # original implementation returns empty lists for ListShape members, but we want nonempty
    def stub_ref(ref, visited = [])
      super.tap do |r|
        if r == [] && ref.shape.respond_to?(:member)
          return [FullAwsStub.new(ref.shape.member).stub(visited)]
        elsif ref.shape.is_a?(MapShape) && r == {}
          k = FullAwsStub.new(ref.shape.key).stub(visited)
          v = FullAwsStub.new(ref.shape.value).stub(visited)
          r[k] = v
        end
      end
    end
  end

  class << self

    def get(sdk, method, source: nil)
      source ||= ENV['AWS_RESPONSE_GENERATOR']
      if source
        return send("get_#{source}", sdk, method)
      end
      get_api_structure(sdk, method)
      #get_rubydoc_example(sdk, method) || 
    end

    def get_live(sdk, method)
      raise "should be handled earlier"
    end

    Example = Struct.new(:title, :call, :result)

    def get_rubydoc_example(sdk, method)
      rdoc = Lsaws::SDKParser.new(sdk).get_method_rdoc(method)
      examples = []
      rdoc.scan(/^\s*# @example Example:/) do
        pos = Regexp.last_match.offset(0).first
        io = StringIO.new(rdoc[pos..-1])
        title = io.gets.split("@example ",2).last

        raise if io.gets !~ /^\s*\#$/
        data = String.new
        loop do
          line = io.gets
          break unless line == "    #\n" || line.start_with?("    #   ")
          data << line
        end

        call = data
          .scan(/^    #   resp = client\.#{method}\({$.*?^    #   \}\)$/m)[0]
        result = data
          .scan(/^    #   resp\.to_h outputs the following:(.+?^    #   \})$/m)[0][0]
          .gsub(/^    #/, "")
          .gsub(/Time\.parse\("(\d{10}(?:\.\d{3})?)"\)/, 'Time.at(\1)') # devicefarm:* + many
        $stderr.puts "[d] #{result}" if ENV['DEBUG'].to_i > 2
        result = eval(result) # XXX FIXME FIXME FIXME XXX
        next if result.empty?
        next if result.is_a?(Hash) && result.values.all?{ |x| x.respond_to?(:empty?) && x.empty? } # databasemigrationservice:certificates
        examples << Example.new(title, call, result)
      end

      case examples.size
      when 0
        nil
      when 1
        examples[0].result
      when 2
        #raise "multiple examples found for #{sdk}:#{method}: " + examples.map(&:title).join(", ")
        # get one with shorter call definition
        examples.sort_by{ |x| x.call.size }[0].result
      end
    end

    def get_awscli_example(sdk, method, underscore: true, symbolize: true, transform_values: true)
      cmd = method.tr("_", "-")
      fname = "tmp/aws-cli/awscli/examples/#{sdk}/#{cmd}.rst"
      return nil unless File.exist?(fname)

      File.open(fname) do |f|
        line = f.gets
        line = f.gets while line.strip != "Output::"
        line = f.gets until line.start_with?("    ")
        resp = String.new
        while line.start_with?("    ")
          resp << line
          line = f.gets
        end
        r = JSON.parse(resp)
        _transform_values(r) if transform_values
        r.deep_transform_keys!{ |k| k.underscore.gsub(/\d+/,'_\0') } if underscore
        r.deep_transform_keys!(&:to_sym) if symbolize
        r
      end
    end

    def _transform_values obj
      case obj
      when Hash
        obj.each do |k,v|
          case v
          when Array
            v.each do |x|
              _transform_values(x) if x.is_a?(Hash)
            end
          when Hash
            _transform_values(v)
          when /\d+-\d+-\d+T\d+:\d+:\d+\+\d+:\d+/
            obj[k] = Time.parse(v) if k =~ /time$/i
          end
        end
      end
    end

    def get_api_structure(sdk, method)
      # Seahorse::Model::Operation
      api = Lsaws::SDKParser.new(sdk).get_method_api(method)
      FullAwsStub.new(api.output).stub
    end

    # generates skeleton response from "@example Response structure" rubydoc comment
    def get_rubydoc_structure(sdk, method)
      rdoc = Lsaws::SDKParser.new(sdk).get_method_rdoc(method)
      pos = rdoc.index(/^\s*# @example Response structure/)
      io = StringIO.new(rdoc[pos..-1])
      raise if io.gets !~ /^\s*# @example Response structure$/
      raise if io.gets !~ /^\s*\#$/
      res = {}
      loop do
        line = io.gets
        break unless line =~ /^\s*#\s+resp\.(.+)\s+#=>\s+(.+)$/
        t = $2
        a = $1.split(/(?:(\[0\])|\.)+/).map do |x|
          case x
          when "[0]"
            0
          when /^\w+$/
            x.to_sym
          when /^(\w+)\["(\w+)"\]$/
            [$1.to_sym, $2] # 2nd arg intentionally a String
          else
            raise "Unexpected #{x.inspect}"
          end
        end.flatten
        #$stderr.puts "[d] #{a}" if ENV['DEBUG'] == '2'
        dig_set(res, a, _gen_value(t))
      end
      res
    end

    def dig_set obj, path, value
      case path.size
      when 0
        raise "zero path"
      when 1
        #puts "[d] #{[obj, path, value]}"
        obj[path[0]] = value
      else
        if path[1] == 0 && path[2].is_a?(String)
          # path: ["reservations", 0, "groups"]
          key, key2 = path[0], path[2]
          obj[key] ||= []
          obj[key][0] ||= {}
          dig_set(obj[key][0], path[2..], value)
        else
          key = path[0]
          obj[key] ||= {}
          dig_set(obj[key], path[1..], value)
        end
      end
    end

    def _gen_value t
      case t
      when "Array"
        []
      when "Float"
        1.1
      when "Hash"
        {}
      when "Integer"
        0
      when "String"
        "String"
      when /String, one of "([^"]+)"/
        $1
      when "Time"
        Time.new(2022, 2, 2, 22, 22, 22)
      when "Boolean"
        false
      else
        raise "Don't know how to generate #{t[..50].inspect}"
      end
    end
  end
end
