require_relative '../lib/hashema'

describe "a string" do
  it "matches an equal string" do
    expect('a string').to conform_to_schema 'a string'
  end

  it "does not match an unequal string" do
    expect('a string').not_to conform_to_schema 'a different string'
  end

  it "matches a matching regexp" do
    expect("2JGJ683").to conform_to_schema /^\d[A-Z]{3}\d{3}$/
  end

  it "does not match a non-matching regexp" do
    expect("shtoo").not_to conform_to_schema /^\d[A-Z]{3}\d{3}$/
  end
end

describe "a number" do
  it "matches an equal number" do
    expect(1).to conform_to_schema(1.0)
  end

  it "does not match an unequal number" do
    expect(1).not_to conform_to_schema(2)
  end

  it 'matches a range that includes it' do
    expect(1).to conform_to_schema(0..3)
  end

  it 'does not match a range that excludes it' do
    expect(1).not_to conform_to_schema(2..3)
  end
end

describe "an object" do
  it "matches its class" do
    expect("a string").to conform_to_schema String
  end

  it "matches its class's superclass" do
    expect("a string").to conform_to_schema Object
  end

  it "does not match a class of which it is not an instance" do
    expect("a string").not_to conform_to_schema Numeric
  end

  it "matches an array of alternatives if it matches any of the alternatives" do
    expect('milk').to conform_to_schema ['milk', 'juice']
  end

  it "does not match an array of alternatives if it matches none of the alternatives" do
    expect('milk').not_to conform_to_schema ['wine', 'beer']
  end
end

describe "a hash" do
  it "matches a schema hash with the same set of keys if corresponding values match" do
    expect({a: 1, b: 2}).to conform_to_schema({a: Numeric, b: Numeric})
  end

  it "does not match a schema hash with a different set of keys" do
    expect({a: 1, b: 2}).not_to conform_to_schema({a: Numeric})
    expect({a: 1, b: 2}).not_to conform_to_schema({a: Numeric, b: Numeric, c: Numeric})
  end

  it "does not match a schema hash if any corresponding values do not match" do
    expect({a: 1, b: 2}).not_to conform_to_schema({a: String, b: Numeric})
  end

  it "does not match an array" do
    expect({}).not_to conform_to_schema(['squirrel'])
  end

  it "does not match a number" do
    expect({}).not_to conform_to_schema(0)
  end
end

describe "an array" do
  it "matches a schema array of one element if each of its elements matches the schema element" do
    expect([1,2,3]).to conform_to_schema([Numeric])
  end

  it "does not match a schema array if any of its elements does not match the schema element" do
    expect([1,2,'q']).not_to conform_to_schema([Numeric])
  end

  it "does not match a hash" do
    expect([]).not_to conform_to_schema({})
  end

  it "does not match a number" do
    expect([]).not_to conform_to_schema(0)
  end
end

describe "a mock that expects an object conforming to a schema" do
  it 'is satisfied by an object with the schema' do
    mock = double foo: nil
    expect(mock).to receive(:foo).with an_object_conforming_to_schema bar: String

    mock.foo bar: 'a'
  end
end

describe "a mock that does not expect an object conforming to a schema" do
  it 'is satisfied by an object that violates the schema' do
    mock = double foo: nil
    expect(mock).not_to receive(:foo).with an_object_conforming_to_schema bar: String

    mock.foo bar: 'a', buzz: 1
  end
end
