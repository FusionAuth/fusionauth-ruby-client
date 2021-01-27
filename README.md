# FusionAuth::FusionAuthClient

This gem is the Ruby client library that helps connect Ruby applications to the FusionAuth (https://fusionauth.io) Identity and User Management platform.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fusionauth_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fusionauth_client

## Usage

Once the gem is installed, you can call FusionAuth APIs like this:

```ruby
require 'fusionauth/fusionauth_client'

# Construct the FusionAuth Client
client = FusionAuth::FusionAuthClient.new(
    '<YOUR_API_KEY>', 
    'http://localhost:9011'
)

# Create a user + registration
id = SecureRandom.uuid
client.register(id, {
    :user => {
        :firstName => 'Ruby',
        :lastName => 'Client',
        :email => 'ruby.client.test@fusionauth.io',
        :password => 'password'
    },
    :registration => {
        :applicationId => application_id,
        :data => {
            :foo => 'bar'
        },
        :preferredLanguages => %w(en fr),
        :roles => %w(user)
    }
})

# Authenticate the user
response = client.login({
    :loginId => 'ruby.client.test@fusionauth.io',
    :password => 'password',
    :applicationId => application_id
})
user = response.success.response.user
```

## Questions and support

If you have a question or support issue regarding this client library, we'd love to hear from you.

If you have a paid edition with support included, please [open a ticket with via your account portal](https://account.fusionauth.io/account/support/). Learn more about [paid editions here](https://fusionauth.io/pricing/).

Otherwise, please [post your question in the community forum](https://fusionauth.io/community/forum/).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/FusionAuth/fusionauth-ruby-client.

## License

This code is available as open source under the terms of the [Apache v2.0 License](https://opensource.org/licenses/Apache-2.0).

