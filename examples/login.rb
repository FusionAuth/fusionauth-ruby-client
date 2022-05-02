require 'fusionauth/fusionauth_client'
require 'securerandom'

# Construct the FusionAuth Client
client = FusionAuth::FusionAuthClient.new(
    'APIKEY', 
    'http://localhost:9011'
)

application_id = '20ce6dac-b985-4c77-bb59-6369249f884b'

# Authenticate a user
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
