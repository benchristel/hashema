module Hashema
  class Schema < Struct.new(:ideal)
    def compare(real)
      self.class.const_get('Comparison').new(real, ideal)
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
        mismatches = type_mismatches
        if mismatches.empty?
          mismatches = element_mismatches
        end
        mismatches
      end

      def type_mismatches
        if actual.is_a? ::Array
          []
        else
          [Mismatch.new(actual, ::Array, [])]
        end
      end

      def element_mismatches
        mismatches = []
        actual.each_with_index.map do |actual, i|

          comparison = expected.compare(actual)

          if !comparison.match?
            mismatch_location = [i]
            mismatch_actual = comparison.mismatches[0].actual
            mismatch_expected = comparison.mismatches[0].expected
            mismatch_location = [i] + comparison.mismatches[0].location
            mismatches << Mismatch.new(mismatch_actual, mismatch_expected, mismatch_location)
          end
        end
        mismatches
      end
    end
  end

  class Mismatch < Struct.new(:actual, :expected, :location)
  end
end
