module Hashema
  class Schema < Struct.new(:expected)
    # A Schema is a Comparison factory.
    def compare(actual)
      self.class.const_get('Comparison').new(actual, expected)
    end

    def inspect
      expected.inspect
    end
  end

  class Comparison < Struct.new(:actual, :expected)
    def match?
      mismatches.empty?
    end

    def mismatches
      @mismatches ||= find_mismatches
    end

    private

    def find_mismatches
      raise NotImplementedError.new(
        "#{self.class.name} must implement find_mismatches"
      )
    end
  end

  class Atom < Schema
    class Comparison < Hashema::Comparison

      private

      def find_mismatches
        expected === actual ? [] : [Mismatch.new(actual, expected, [])]
      end
    end
  end

  class Array < Schema
    class Comparison < Hashema::Comparison

      private

      def find_mismatches
        type_mismatches || element_mismatches
      end

      def type_mismatches
        expectation = "be an Array, but got #{actual.class}"
        actual.is_a?(::Array) ? nil : [Mismatch.new(actual, ::Array, [], expectation)]
      end

      def element_mismatches
        actual.each_with_index.flat_map do |element, i|
          element_comparison = expected.compare(element)

          element_comparison.mismatches.map do |mismatch|
            Mismatch.at i, mismatch
          end
        end
      end
    end
  end

  class Hash < Schema
    class Comparison < Hashema::Comparison

      private

      def find_mismatches
        type_mismatch || (keyset_mismatch + value_mismatches)
      end

      def type_mismatch
        expectation = "be a Hash, but got #{actual.class}"
        actual.is_a?(::Hash) ? nil : [Mismatch.new(actual, ::Hash, [], expectation)]
      end

      def keyset_mismatch
        if expected_keys != actual_keys
          missing_keys_expectation = missing_keys.any? ? "\nmissing keys were:\n\t#{missing_keys.map(&:inspect).join("\n\t")}" : ''
          extra_keys_expectation = extra_keys.any? ? "\nextra keys were:\n\t#{extra_keys.map(&:inspect).join("\n\t")}" : ''
          expectation = "have a different set of keys" + missing_keys_expectation + extra_keys_expectation
          [Mismatch.new(actual, expected, [], expectation)]
        else
          []
        end
      end

      def value_mismatches
        actual.flat_map do |key, value|
          if in? key, expected_keys
            value_comparison = fetch(key, expected).compare(value)

            value_comparison.mismatches.map do |mismatch|
              Mismatch.at key, mismatch
            end
          else
            []
          end
        end
      end

      def expected_keys
        @expected_keys ||= Set.new(expected.keys)
      end

      def actual_keys
        @actual_keys ||= Set.new(actual.keys)
      end

      def extra_keys
        @extra_keys ||= actual.keys.reject do |k|
          in? k, expected_keys
        end
      end

      def missing_keys
        @missing_keys ||= expected.keys.reject do |k|
          in? k, actual_keys
        end
      end

      def in?(key, set)
        set.include?(key)
      end

      def fetch(key, hash)
        hash[key]
      end
    end
  end

  class Alternatives < Schema
    def initialize(*args)
      super(args)
    end

    class Comparison < Hashema::Comparison

      private

      def find_mismatches
        if expected.none? { |alternative| alternative.compare(actual).match? }
          [Mismatch.new(actual, expected, [])]
        else
          []
        end
      end
    end
  end

  class HashWithIndifferentAccess < Schema
    class Comparison < Hashema::Hash::Comparison

      private

      def expected_keys
        @expected_keys ||= Set.new(expected.keys.map(&method(:symbol_to_string)))
      end

      def actual_keys
        @actual_keys ||= Set.new(actual.keys.map(&method(:symbol_to_string)))
      end

      def in?(key, set)
        set.include?(symbol_to_string(key))
      end

      def fetch(key, hash)
        return hash[symbol_to_string(key)] if hash.has_key? symbol_to_string(key)
        return hash[string_to_symbol(key)] if hash.has_key? string_to_symbol(key)
      end

      def string_to_symbol(key)
        key.is_a?(String) ? key.to_sym : key
      end

      def symbol_to_string(key)
        key.is_a?(Symbol) ? key.to_s : key
      end
    end
  end

  class Mismatch < Struct.new(:actual, :expected, :location, :verb)
    def self.at(location, original)
      new original.actual,
          original.expected,
          [location] + original.location
    end

    def message
      "expected /#{location.join '/'} to #{verb}"
    end

    private

    def verb
      super || "match\n\t#{expected.inspect}\nbut got\n\t#{actual.inspect}"
    end
  end
end
