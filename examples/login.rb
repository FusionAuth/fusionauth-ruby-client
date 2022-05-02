require 'fusionauth/fusionauth_client'
require 'securerandom'

# Construct the FusionAuth Client
client = FusionAuth::FusionAuthClient.new(
    'APIKEY', 
    'http://localhost:9011'
)

application_id = '20ce6dac-b985-4c77-bb59-6369249f884b'

# Create a user + registration
id = SecureRandom.uuid
response = client.register(id, {
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

unless response.success_response
  print response.error_response
  exit
end

# Authenticate the user
response = client.login({
    :loginId => 'ruby.client.test@fusionauth.io',
    :password => 'password',
    :applicationId => application_id
})

if response.success_response
  user = response.success_response.user
  print user.id
else 
  print response.error_response
end
