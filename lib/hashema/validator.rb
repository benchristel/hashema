module Hashema
  class Validator
    def initialize(actual, schema)
      @actual = actual
      @schema = schema
      @withholding_judgement = false
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
      if actual.is_a? Hash
        if Set.new(schema.keys) == Set.new(actual.keys)
          match_hash_with_same_keys! actual, schema, path
        else
          report_mismatched_key_sets! actual, schema, path
        end
      else
        report_error "expected #{format_path path} to be a Hash, but got #{actual.class}"
        false
      end
    end

    def match_hash_with_same_keys!(actual, schema, path)
      recording_mismatches actual, schema, path do
        actual.all? do |key, value|
          match! value, schema[key], path + [key]
        end
      end
    end

    def report_mismatched_key_sets!(actual, schema, path)
      extras = actual.keys - schema.keys
      missing = schema.keys - actual.keys
      error = "expected #{format_path path} to have a different set of keys\n"
      error += "the extra keys were:\n  #{extras.map(&:inspect).join("\n  ")}\n" if extras.any?
      error += "the missing keys were:\n  #{missing.map(&:inspect).join("\n  ")}\n" if missing.any?
      report_error error
      false
    end

    def match_array!(actual, schema, path)
      if actual.is_a? Array
        recording_mismatches actual, schema, path do
          actual.is_a? Array and
          actual.each_with_index.all? { |elem, i| match! elem, schema[0], path + [i] }
        end
      else
        report_error "expected #{format_path path} to be an Array, but got #{actual.class}"
        false
      end
    end

    def match_alternatives!(actual, alternatives, path)
      recording_mismatches actual, alternatives, path do
        alternatives.any? do |alternative|
          withholding_judgement actual, alternatives, path do
            match! actual, alternative, path
          end
        end
      end
    end

    def match_with_triple_equals!(actual, expected, path)
      recording_mismatches actual, expected, path do
        expected === actual
      end
    end

    def withholding_judgement(actual, schema, path)
      original_withholding_judgement = @withholding_judgement
      @withholding_judgement = true
      returned = yield
      @withholding_judgement = original_withholding_judgement
      returned
    end

    def recording_mismatches(actual, schema, path)
      if yield
        true
      else
        report_error "expected #{format_path path} to match\n#{schema.inspect}\nbut got\n#{actual.inspect}"
        false
      end
    end

    def report_error(error)
      unless @withholding_judgement
        @mismatch ||= error
      end
    end

    def format_path(path)
      "/#{path.join("/")}"
    end
  end
end
