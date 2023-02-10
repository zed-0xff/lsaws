# frozen_string_literal: true

module Lsaws
  module Utils
    # copypasted from lib/active_support/core_ext/hash/keys.rb
    def _deep_transform_keys_in_object!(object, &block)
      case object
      when Hash
        object.each_key do |key|
          value = object.delete(key)
          object[yield(key)] = _deep_transform_keys_in_object!(value, &block)
        end
        object
      when Array
        object.map! { |e| _deep_transform_keys_in_object!(e, &block) }
      else
        object
      end
    end

    def _deep_transform_keys_in_object(object, &block)
      case object
      when Hash
        object.each_with_object(object.class.new) do |(key, value), result|
          result[yield(key)] = _deep_transform_keys_in_object(value, &block)
        end
      when Array
        object.map { |e| _deep_transform_keys_in_object(e, &block) }
      else
        object
      end
    end

    # "2022-11-15 10:49:00 UTC" => "2022-11-15T10:49:00+00:00"
    def to_iso8601(s)
      s.gsub(/([0-9-]{10}) ([0-9:]+{8}) UTC/, '\1T\2+00:00')
    end

    # "2022-11-15T10:49:00+00:00" => "2022-11-15 10:49:00 UTC"
    def from_iso8601(s)
      s.gsub(/([0-9-]{10})T([0-9:]+{8})\+00:00/, '\1 \2 UTC')
    end
  end
end
