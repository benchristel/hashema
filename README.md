# hashema

Hashema lets you validate JSONable objects (hashes and arrays) against a schema, and assert their validity in your RSpec examples.

## Validating an object against a schema

The API of `Hashema::Validator` consists of an initializer and two instance methods: `valid?` and `failure_message`. The initializer takes an object to validate and a schema, in that order. `valid?` will return `true` iff the object conforms to the schema. If `valid?` is `false`, `failure_message` will return a description of the failure.

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

## RSpec matcher usage

```ruby
expect(datum).to conform_to_schema schema
```
