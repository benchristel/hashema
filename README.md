# hashema

Hashema lets you validate JSONable objects (hashes and arrays) against a schema, and assert their validity in your RSpec examples.

## Installation

```bash
gem install hashema
```

Or, if you're using [bundler](https://rubygems.org/gems/bundler), put this in your `Gemfile`:

```bash
gem 'hashema'
```

Hashema hooks into your RSpec config to provide the `conform_to_schema` matcher. If `rspec` is listed in your `Gemfile`, you should be able to use `conform_to_schema` in your tests with no further setup.

## RSpec usage

With hashema and RSpec, it's easy to ensure your JSON APIs return the data your clients expect.

```ruby
describe BlogSerializer do
  before { @serializer = BlogSerializer.new(Blog.create) }

  describe '#as_json' do
    subject { @serializer.as_json }

    SCHEMA = {
      url: /^https?:\/\/.+/,
      posts: [
        { title: String,
          published: [true, false]
        }
      ]
    }

    it { is_expected_to conform_to_schema SCHEMA }
  end
end
```

## The Schema DSL by example

### Allowing any value

```ruby
expect(
  Rotation.new('squirrel')
).to conform_to_schema Object
```

### Checking for an exact match

```ruby
expect(
  {error: 'not found'}
).to conform_to_schema({error: 'not found'})
```

### Checking for membership in a class

```ruby
expect(
  {berzerker: 'pasta'}
).to conform_to_schema Hash
```

### Checking that a string value matches a regular expression

```ruby
expect(
  'Hello! My name is Fridge.'
).to conform_to_schema /^Hello! My name is \w+\.$/
```

### Checking for inclusion in a set of alternatives

```ruby
expect(
  {is_awesome: true}
).to conform_to_schema({is_awesome: [true, false]})
```

### Checking for inclusion in a range of legal values

```ruby
expect(
  {kyu_rank: 17}
).to conform_to_schema({kyu_rank: 1..30})
```

### Checking that all elements of an array share a schema

```ruby
expect(
  [{name: 'Melody'}, {name: 'Elias'}, {name: 'Yoda'}]
).to conform_to_schema [{name: String}]
```

### Matching an array of items that may have different schemas

```ruby
expect(
  [{cash: '12.33'}, {credit: '28.95'}, {cash: '40.70'}]
).to conform_to_schema [[{cash: /^\d+\.\d\d$/}, {credit: /^\d+\.\d\d$/}]]
```

## Hashema without RSpec

There are times when you want to validate the structure of a data object in your production code. For example, if your program parses data from a user-created file, you might want to check that the data you read in match the schema you expect. For such situations, you can use `Hashema::Validator`.

The API of `Hashema::Validator` consists of an initializer and two instance methods: `valid?` and `failure_message`. The initializer takes an object to validate and a schema, in that order. `valid?` will return `true` iff the object conforms to the schema.

```ruby
validator = Hashema::Validator.new(
  # the object to validate
  { blog:
    { url: 'http://www.blagoblag.com',
      posts: [
        { title: 'hello',
          published: true
        },
        { title: 'test',
          published: false
        }
      ]
    }
  },

  # the schema
  { blog:
    { url: /^https?:\/\//,
      posts: [
        { title: String,
          published: [true, false]
        }
      ]
    }
  }
)

validator.valid? # true
```

If `valid?` is `false`, `failure_message` will return a human-readable description of the failure, which includes, at a minimum:

- the path through the data structure to the point where the first mismatch occurred
- the expected value at that point
- the actual value

```ruby
validator = Hashema::Validator.new(
  # the object to validate
  { blog:
    { url: 'http://www.blagoblag.com',
      posts: [
        { title: 'hello',
          published: true
        },
        { title: 123,
          published: false
        }
      ]
    }
  },

  # the schema
  { blog:
    { url: /^https?:\/\//,
      posts: [
        { title: String,
          published: [true, false]
        }
      ]
    }
  }
)

validator.valid? # false
puts validator.failure_message
# prints:
#   expected /blog/posts/1/title to match
#   String
#   but got
#   123
```
