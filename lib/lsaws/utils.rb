# frozen_string_literal: true

class Lsaws
  module Utils
    # copypasted from lib/active_support/core_ext/hash/keys.rb
    def self._deep_transform_keys_in_object!(object, &block)
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
  end
end
