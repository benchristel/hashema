begin
  require 'rspec'
rescue LoadError => e
end

module Hashema
  module RSpecMatchers
    class ConformToSchema
      def initialize(schema)
        @schema = schema
      end

      def matches?(actual)
        @validator = Hashema::Validator.new(actual, @schema)
        @validator.valid?
      end

      def failure_message
        @validator.failure_message
      end

      def failure_message_for_should
        failure_message
      end

      def failure_message_when_negated
        "expected\n#{@actual.inspect}\nnot to match schema\n#{@schema.inspect}"
      end

      def failure_message_for_should_not
        failure_message_when_negated
      end

      def description
        "match schema\n#{@schema.inspect}"
      end
    end

    def conform_to_schema(schema)
      ConformToSchema.new(schema)
    end
  end
end

if Kernel.const_defined? 'RSpec'
  class Hashema::RSpecMatchers::ConformToSchema
    include RSpec::Matchers::Composable

    RSpec::Matchers.alias_matcher(
      :an_object_conforming_to_schema,
      :conform_to_schema
    ) do |description|
      description.sub("match schema\n", 'an object conforming to schema ')
    end
  end

  RSpec.configure do |config|
    config.include Hashema::RSpecMatchers
  end
end
