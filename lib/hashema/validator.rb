module Hashema
  class Validator
    def initialize(actual, schema)
      @actual = actual
      @schema = schema
      match! @actual, @schema
    end

    def valid?
      !!@match
    end

    def failure_message
      @mismatch
    end

    private

    def match!(actual, schema, path=[])
      @match = begin
        if schema.is_a? Hash
          match_hash! actual, schema, path
        elsif schema.is_a? Array and schema.length == 1
          match_array! actual, schema, path
        elsif schema.is_a? Array and schema.length > 1
          match_alternatives! actual, schema, path
        else
          match_with_triple_equals! actual, schema, path
        end
      end
    end

    def match_hash!(actual, schema, path)
      recording_mismatches actual, schema, path do
        schema.keys.sort == actual.keys.sort and
        actual.all? do |key, value|
          match! value, schema[key], path + [key]
        end
      end
    end

    def match_array!(actual, schema, path)
      recording_mismatches actual, schema, path do
        actual.is_a? Array and
        actual.each_with_index.all? { |elem, i| match! elem, schema[0], path + [i] }
      end
    end

    def match_alternatives!(actual, alternatives, path)
      recording_mismatches actual, alternatives, path, true do
        alternatives.any? do |alternative|
          match! actual, alternative, path
        end
      end
    end

    def match_with_triple_equals!(actual, expected, path)
      recording_mismatches actual, expected, path do
        expected === actual
      end
    end

    def recording_mismatches(actual, schema, path, overwrite=false)
      if yield
        true
      else
        mismatch = "expected /#{path.join("/")} to match\n#{schema.inspect}\nbut got\n#{actual.inspect}"
        @mismatch = mismatch if !@mismatch || overwrite
        false
      end
    end
  end
end
