# frozen_string_literal: true

require "json"
require "active_support/core_ext/hash"
require "active_support/core_ext/string/inflections"

module AwsCliSample
  class << self

    def get_rubydoc_example(sdk, method)
      rdoc = Lsaws::SDKParser.new(sdk).get_method_rdoc(method)
      examples = []
      rdoc.scan(/^\s*# @example Example:/) do
        pos = Regexp.last_match.offset(0).first
        io = StringIO.new(rdoc[pos..-1])
        example_title = io.gets.split("@example ",2).last

        raise if io.gets !~ /^\s*\#$/
        data = String.new
        loop do
          line = io.gets
          break unless line == "    #\n" || line.start_with?("    #   ")
          data << line
        end
        r = data
          .scan(/^    #   resp\.to_h outputs the following:(.+?^    #   \})$/m)[0][0]
          .gsub(/^    #/, "")
        r = eval(r) # XXX FIXME FIXME FIXME XXX
        examples << [example_title, r]
      end
      case examples.size
      when 0
        raise "no examples found for #{sdk}:#{method}"
      when 1
        return examples[0][1]
      when 2
        raise "multiple examples found for #{sdk}:#{method}"
      end
    end

    def get(sdk, cmd, underscore: true, symbolize: true, transform_values: true)
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

    # generates skeleton response from "@example Response structure" rubydoc comment
    def generate(sdk, method)
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
        a = $1.split(/(\[0\])?\./).map{ |x| x == "[0]" ? 0 : x.to_sym }
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
      when "Integer"
        0
      when "String"
        ""
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
