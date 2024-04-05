# FusionAuth Ruby Client ![semver 2.0.0 compliant](http://img.shields.io/badge/semver-2.0.0-brightgreen.svg?style=flat-square)

## Intro

<!--
tag::forDocSite[]
-->

This gem is the Ruby client library that helps connect Ruby applications
to the FusionAuth (<https://fusionauth.io>) Identity and User Management
platform.

## Installation

Add this line to your application’s Gemfile:

    gem 'fusionauth_client'

And then execute:

    bundle

Or install it yourself as:

    gem install fusionauth_client


## Examples

### Set Up

First, you have to make sure you have a running FusionAuth instance. If you don't have one already, the easiest way to install FusionAuth is [via Docker](https://fusionauth.io/docs/get-started/download-and-install/docker), but there are [other ways](https://fusionauth.io/docs/get-started/download-and-install). By default, it'll be running on `localhost:9011`.

Then, you have to [create an API Key](https://fusionauth.io/docs/apis/authentication#managing-api-keys) in the admin UI to allow calling API endpoints.

You are now ready to use this library!

### Response Handling

After every request is made, you need to check for any errors and handle them. To avoid cluttering things up, we'll omit the error handling in the next examples, but you should do something like the following.

```ruby
require 'fusionauth/fusionauth_client'
require 'pp'

# actual code

def handle_response(response)
  if response.was_successful
    pp response.success_response
  else
    print "status: #{response.status}"
    if response.exception
      # if we can't connect
      print response.exception
    end
    print response.error_response
    exit 1
  end
end
```

### Create the Client

To make requests to the API, first you need to create a `FusionAuthClient` instance with [the API Key created](https://fusionauth.io/docs/apis/authentication#managing-api-keys) and the server address where FusionAuth is running.

```ruby
require 'fusionauth/fusionauth_client'

# Construct the FusionAuth Client
client = FusionAuth::FusionAuthClient.new(
  '<paste the API Key you generated here>',
  'http://localhost:9011' # or change this to whatever address FusionAuth is running on
)
```

### Create an Application

To create an [Application](https://fusionauth.io/docs/get-started/core-concepts/applications), use the `createApplication()` method.

```ruby
response = client.create_application(
    '', # Leave this empty to automatically generate the UUID
    {
        :application => {
            :name => 'ChangeBank',
        }
    }
)

handle_response(response)
```

[Check the API docs for this endpoint](https://fusionauth.io/docs/apis/applications#create-an-application)

### Adding Roles to an Existing Application

To add [roles to an Application](https://fusionauth.io/docs/get-started/core-concepts/applications#roles), use `createApplicationRole()`.

```ruby
response = client.create_application_role(
    'd564255e-f767-466b-860d-6dcb63afe4cc', # Existing Application Id
    '', # Role Id - Leave this empty to automatically generate the UUID
    {
        :role => {
            :name => 'customer',
            :description => 'Default role for regular customers',
            :isDefault => true,
        }
    }
)

handle_response(response)
```

[Check the API docs for this endpoint](https://fusionauth.io/docs/apis/applications#create-an-application-role)

### Retrieve Application Details

To fetch details about an [Application](https://fusionauth.io/docs/get-started/core-concepts/applications), use `retrieveApplication()`.

```ruby
response = client.retrieve_application(
    'd564255e-f767-466b-860d-6dcb63afe4cc'
)

handle_response(response)
```

[Check the API docs for this endpoint](https://fusionauth.io/docs/apis/applications#retrieve-an-application)

### Delete an Application

To delete an [Application](https://fusionauth.io/docs/get-started/core-concepts/applications), use `deleteApplication()`.

```ruby
response = client.delete_application(
    'd564255e-f767-466b-860d-6dcb63afe4cc'
)

handle_response(response)
# Note that response.success_response will be empty
```

[Check the API docs for this endpoint](https://fusionauth.io/docs/apis/applications#delete-an-application)

### Lock a User

To [prevent a User from logging in](https://fusionauth.io/docs/get-started/core-concepts/users), use `deactivateUser()`.

```ruby
response = client.deactivate_user(
    'fa0bc822-793e-45ee-a7f4-04bfb6a28199',
)

handle_response(response)
```

[Check the API docs for this endpoint](https://fusionauth.io/docs/apis/users#delete-a-user)

### Registering a User

To [register a User in an Application](https://fusionauth.io/docs/get-started/core-concepts/users#registrations), use `register()`.

The code below also adds a `customer` role and a custom `appBackgroundColor` property to the User Registration.

```ruby
response = client.register(
    'fa0bc822-793e-45ee-a7f4-04bfb6a28199',
    {
        :registration => {
            :applicationId => 'd564255e-f767-466b-860d-6dcb63afe4cc',
            :roles => [
                'customer',
            ],
            :data => {
                :appBackgroundColor => '#096324',
            },
        },
    }
)

handle_response(response)
```

[Check the API docs for this endpoint](https://fusionauth.io/docs/apis/registrations#create-a-user-registration-for-an-existing-user)

# Documentation

Documentation can be found at
[doc](https://github.com/FusionAuth/fusionauth-ruby-client/tree/master/doc).

<!--
end::forDocSite[]
-->

## Questions and support


If you find any bugs in this library, [please open an issue](https://github.com/FusionAuth/fusionauth-ruby-client/issues). Note that changes to the `FusionAuthClient` class have to be done on the [FusionAuth Client Builder repository](https://github.com/FusionAuth/fusionauth-client-builder/blob/master/src/main/client/ruby.client.ftl), which is responsible for generating that file.

But if you have a question or support issue, we'd love to hear from you.

If you have a paid plan with support included, please [open a ticket in your account portal](https://account.fusionauth.io/account/support/). Learn more about [paid plan here](https://fusionauth.io/pricing).

Otherwise, please [post your question in the community forum](https://fusionauth.io/community/forum/).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/FusionAuth/fusionauth-ruby-client.

Note: if you want to change the `FusionAuthClient` class, you have to do it on the [FusionAuth Client Builder repository](https://github.com/FusionAuth/fusionauth-client-builder/blob/master/src/main/client/ruby.client.ftl), which is responsible for generating all client libraries we support.

## License

This code is available as open source under the terms of the [Apache v2.0 License](https://opensource.org/blog/license/apache-2-0).


## Upgrade Policy

This library is built automatically to keep track of the FusionAuth API, and may also receive updates with bug fixes, security patches, tests, code samples, or documentation changes.

These releases may also update dependencies, language engines, and operating systems, as we\'ll follow the deprecation and sunsetting policies of the underlying technologies that it uses.

This means that after a dependency (e.g. language, framework, or operating system) is deprecated by its maintainer, this library will also be deprecated by us, and will eventually be updated to use a newer version.