module Hashema
  class Schema < Struct.new(:expected)
    def compare(actual)
      self.class.const_get('Comparison').new(actual, expected)
    end
  end

  class Comparison < Struct.new(:actual, :expected)
    def match?
      mismatches.empty?
    end

    def mismatches
      @mismatches ||= find_mismatches
    end
  end

  class Atom < Schema
    class Comparison < Hashema::Comparison
      def find_mismatches
        expected === actual ? [] : [Mismatch.new(actual, expected, [])]
      end
    end
  end

  class Array < Schema
    class Comparison < Hashema::Comparison
      def find_mismatches
        type_mismatches || element_mismatches
      end

      def type_mismatches
        actual.is_a?(::Array) ? nil : [Mismatch.new(actual, ::Array, [])]
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

  class Mismatch < Struct.new(:actual, :expected, :location)
    def self.at(location, original)
      new original.actual,
          original.expected,
          [location] + original.location
    end
  end
end
