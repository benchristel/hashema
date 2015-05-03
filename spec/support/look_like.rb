module Hashema
  module DevelopmentMatchers
    class LookLike
      def initialize(expected)
        @expected = expected
      end

      def matches?(actual)
        @actual = actual
        actual.gsub(/\s+/, ' ').strip == @expected.gsub(/\s+/, ' ').strip
      end

      def failure_message
        "#{@actual}\nshould look like\n#{@expected}"
      end

      def failure_message_for_should
        failure_message
      end

      def failure_message_when_negated
        "expected #{@actual.inspect}\nnot to look like #{@expected}"
      end

      def failure_message_for_should_not
        failure_message_when_negated
      end

      def description
        "look like\n#{@expected.inspect}"
      end
    end

    def look_like(expected)
      LookLike.new(expected)
    end
  end
end

RSpec.configure do |config|
  config.include Hashema::DevelopmentMatchers
end
