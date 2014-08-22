RSpec::Matchers.define :conform_to_schema do |schema|
  match do |actual|
    @schema = schema
    @actual = actual
    @validator = Hashema::Validator.new(actual, schema)
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
end
