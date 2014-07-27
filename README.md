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
          permalink: '/hello',
          comment_count: 1
        },
        { title: 'test',
          permalink: '/test',
          comment_count: 0
        }
      ]
    }
  },

  # the schema
  { blog:
    { url: /^https?:\/\//,
      posts: [
        { title: String,
          permalink: /^\/[a-zA-Z0-9_\-\+\/]+$/,
          comment_count: Numeric
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
