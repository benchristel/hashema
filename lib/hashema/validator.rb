require_relative './compiler'

module Hashema
  module Validatable
    class Base
      def initialize(value, schema)
        @value.public_send(m, *args, &b)
      end

      def method_missing(m, *args, &b)
        @value.public_send(m, *args, &b)
      end
    end

    class Hash
      def initialize(hash, schema)
        @delegate = hash
        @schema = schema
      end

      def valid?
        Set.new(keys) == Set.new(schema.keys) &&
        each_pair do |k, v|
          Hashema::Validatable.make(v, schema[k]).valid?
        end
      end

      def problem
        if Set.new(keys) != Set.new(schema.keys)
          "hash key mismatch"
        elsif problem_child = find { not Hashema::Validatable.make(v, schema[k]).valid? }
          problem_child.problem
        else
          "none"
        end
      end
    end
  end

  class Validator
    def initialize(actual, schema, options={})
      @actual = actual
      @schema = schema
      @compiled_schema = compile @schema, options
      match! @actual, @schema
    end

    def compile(schema, options={})
      Hashema::Compiler.compile(schema, options)
    end

    def valid?
      comparison.match?
    end

    def failure_message
      comparison.mismatches[0].message
    end

    def comparison
      @comparison ||= @compiled_schema.compare(@actual)
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
        if hash_key_sets_equal? Set.new(schema.keys), Set.new(actual.keys)
          match_hash_with_same_keys! actual, schema, path
        else
          report_mismatched_key_sets! actual, schema, path
        end
      else
        report_error "expected #{format_path path} to be a Hash, but got #{actual.class}"
        false
      end
    end

    def hash_key_sets_equal?(keys1, keys2)
      if indifferent_access?
        keys1.map(&:to_s) == keys2.map(&:to_s)
      else
        keys1 == keys2
      end
    end

    def match_hash_with_same_keys!(actual, schema, path)
      recording_mismatches actual, schema, path do
        actual.all? do |key, value|
          Validator.new(value, schema[key]).valid?
          #match! value, schema[key], path + [key]
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

    def indifferent_access?
      @options[:with_indifferent_access]
    end
  end
end
