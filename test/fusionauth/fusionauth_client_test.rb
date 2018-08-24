require 'test_helper'
require 'securerandom'

module FusionAuth
  class FusionAuthClientTest < Minitest::Test

    def handle_response (response)
      unless response.was_successful
        raise "Status = #{response.status} error body = #{response.error_response}"
      end
    end

    def test_application_crud
      id = SecureRandom.uuid
      client = FusionAuth::FusionAuthClient.new('API-KEY', 'http://localhost:9011')
      response = client.create_application(id, {
          :application => {
              :name => 'Test application',
              :roles => [
                  {
                      :isDefault => false,
                      :name => 'admin',
                      :isSuperRole => true,
                      :description => 'Admin role'
                  },
                  {
                      :isDefault => true,
                      :name => 'user',
                      :description => 'User role'
                  }
              ]
          }
      })
      handle_response(response)
      assert_equal 'Test application', response.success_response.application.name
      assert_equal 'admin', response.success_response.application.roles[0].name
      assert_equal 'user', response.success_response.application.roles[1].name

      # Create a new role
      role_response = client.create_application_role(id, nil, {
          :role => {
              :isDefault => true,
              :name => 'new role',
              :description => 'New role description'
          }
      })
      handle_response(role_response)
      application_role = role_response.success_response
      response = client.retrieve_application(id)
      handle_response(response)
      assert_equal 'admin', response.success_response.application.roles[0].name
      assert_equal 'new role', response.success_response.application.roles[1].name
      assert_equal 'user', response.success_response.application.roles[2].name

      # Update the role
      client.update_application_role(id, application_role.role.id, {
          :role => {
              :isDefault => false,
              :name => 'new role',
              :description => 'New role description'
          }
      })
      handle_response(response)
      response = client.retrieve_application(id)
      handle_response(response)
      assert !response.success_response.application.roles[1].isDefault

      # Delete the role
      client.delete_application_role(id, application_role.role.id)
      handle_response(response)
      response = client.retrieve_application(id)
      handle_response(response)
      assert_equal 'admin', response.success_response.application.roles[0].name
      assert_equal 'user', response.success_response.application.roles[1].name

      # Deactivate the application
      response = client.deactivate_application(id)
      handle_response(response)
      assert_nil response.success_response
      response = client.retrieve_application(id)
      handle_response(response)
      assert !response.success_response.application.active

      # Reactivate the application
      response = client.reactivate_application(id)
      handle_response(response)
      assert response.success_response.application.active
      response = client.retrieve_application(id)
      handle_response(response)
      assert response.success_response.application.active

      # Hard delete the application
      response = client.delete_application(id)
      handle_response(response)
      assert_nil response.success_response
      response = client.retrieve_application(id)
      assert_nil response.success_response
      assert_equal 404, response.status
    end

    def test_email_template_crud
      id = SecureRandom.uuid
      client = FusionAuth::FusionAuthClient.new('API-KEY', 'http://localhost:9011')

      # Create the email template
      response = client.create_email_template(id, {
          :emailTemplate => {
              :defaultFromName => 'Dude',
              :defaultHtmlTemplate => 'HTML Template',
              :defaultSubject => 'Subject',
              :defaultTextTemplate => 'Text Template',
              :fromEmail => 'from@fusionauth.io',
              :localizedFromNames => {
                  :fr => 'From fr'
              },
              :name => 'Test Template'
          }
      })
      handle_response(response)

      # Retrieve the email template
      response = client.retrieve_email_template(id)
      handle_response(response)
      assert_equal 'Test Template', response.success_response.emailTemplate.name

      # Update the email tempalte
      response = client.update_email_template(id, {
          :emailTemplate => {
              :defaultFromName => 'Dude',
              :defaultHtmlTemplate => 'HTML Template',
              :defaultSubject => 'Subject',
              :defaultTextTemplate => 'Text Template',
              :fromEmail => 'from@fusionauth.io',
              :localizedFromNames => {
                  :fr => 'From fr'
              },
              :name => 'Test Template updated'
          }
      })
      handle_response(response)
      response = client.retrieve_email_template(id)
      handle_response(response)
      assert_equal 'Test Template updated', response.success_response.emailTemplate.name

      # Preview it
      response = client.retrieve_email_template_preview(
          {
              :emailTemplate => {
                  :defaultFromName => 'Dude',
                  :defaultHtmlTemplate => 'HTML Template',
                  :defaultSubject => 'Subject',
                  :defaultTextTemplate => 'Text Template',
                  :fromEmail => 'from@fusionauth.io',
                  :localizedFromNames => {
                      :fr => 'From fr'
                  },
                  :name => 'Test Template updated'
              },
              :locale => 'fr'
          }
      )
      handle_response(response)
      assert_equal 'From fr', response.success_response.email.from['display'] # Display is a reserved method in Object in Ruby

      # Delete the email template
      response = client.delete_email_template(id)
      assert_nil response.success_response
      response = client.retrieve_email_template(id) # Don't use the bang version because it will explode using the lambda passed into the constructor
      assert_equal 404, response.status
    end

    def test_user_crud
      id = SecureRandom.uuid
      client = FusionAuth::FusionAuthClient.new('API-KEY', 'http://localhost:9011')

      # Create a user
      response = client.create_user(id, {
          :user => {
              :firstName => 'Ruby',
              :lastName => 'Client',
              :email => 'ruby.client.test@fusionauth.io',
              :password => 'password'
          }
      })
      handle_response(response)

      # Retrieve the user
      response = client.retrieve_user(id)
      handle_response(response)
      puts response.was_successful
      puts response.status
      assert_equal 'ruby.client.test@fusionauth.io', response.success_response.user.email

      # Update the user
      response = client.update_user(id, {
          :user => {
              :firstName => 'Ruby updated',
              :lastName => 'Client updated',
              :email => 'ruby.client.test+updated@fusionauth.io',
              :password => 'password updated'
          }
      })
      handle_response(response)
      assert_equal 'ruby.client.test+updated@fusionauth.io', response.success_response.user.email
      response = client.retrieve_user(id)
      handle_response(response)
      assert_equal 'ruby.client.test+updated@fusionauth.io', response.success_response.user.email

      # Delete the user
      response = client.delete_user(id)
      handle_response(response)
      assert_nil response.success_response
      response = client.retrieve_user(id)
      assert_equal 404, response.status
    end

    def test_user_registration_crud_and_login
      id = SecureRandom.uuid
      application_id = SecureRandom.uuid
      client = FusionAuth::FusionAuthClient.new('API-KEY', 'http://localhost:9011')

      # Create an application
      response = client.create_application(application_id, {
          :application => {
              :name => 'Test application',
              :roles => [
                  {
                      :isDefault => false,
                      :name => 'admin',
                      :isSuperRole => true,
                      :description => 'Admin role'
                  },
                  {
                      :isDefault => true,
                      :name => 'user',
                      :description => 'User role'
                  }
              ]
          }
      })
      handle_response(response)

      # Create a user + registration
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
                  :attributes => {
                      :foo => 'bar'
                  },
                  :preferredLanguages => %w(en fr)
              },
              :roles => %w(user)
          }
      })
      handle_response(response)

      # Authenticate the user
      response = client.login({
          :loginId => 'ruby.client.test@fusionauth.io',
          :password => 'password',
          :applicationId => application_id
      })
      handle_response(response)
      assert_equal 'ruby.client.test@fusionauth.io', response.success_response.user.email

      # Retrieve the registration
      response = client.retrieve_registration(id, application_id)
      handle_response(response)
      assert_equal 'user', response.success_response.registration.roles[0]
      assert_equal 'bar', response.success_response.registration.data.foo

      # Update the registration
      response = client.update_registration(id, {
          :registration => {
              :applicationId => application_id,
              :data => {
                  :attributes => {
                      :foo => 'bar updated'
                  },
                  :preferredLanguages => %w(en fr)
              },
              :roles => %w(admin)
          }
      })
      handle_response(response)
      assert_equal 'admin', response.success_response.registration.roles[0]
      assert_equal 'bar updated', response.success_response.registration.data.foo
      response = client.retrieve_registration(id, application_id)
      handle_response(response)
      assert_equal 'admin', response.success_response.registration.roles[0]
      assert_equal 'bar updated', response.success_response.registration.data.foo

      # Delete the registration
      response = client.delete_registration(id, application_id)
      assert_nil response.success_response
      response = client.retrieve_registration(id, application_id)
      assert_equal 404, response.status

      # Delete the application & user as clean-up
      client.delete_application(application_id)
      client.delete_user(id)
    end
  end
end
