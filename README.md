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

# Create the client
api_key = 'bf69486b-4733-4470-a592-f1bfce7af580'
fusionauth_address = 'http://localhost:9011'
client = FusionAuth::FusionAuthClient.new(api_key, fusionauth_address)

# Create a user + registration
id = SecureRandom.uuid
client.register!(id, {
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
response = client.login!({
    :loginId => 'ruby.client.test@fusionauth.io',
    :password => 'password',
    :applicationId => application_id
})
user = response.user
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/FusionAuth/fusionauth-ruby-client. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [Apache v2.0 License](https://opensource.org/licenses/Apache-2.0).

