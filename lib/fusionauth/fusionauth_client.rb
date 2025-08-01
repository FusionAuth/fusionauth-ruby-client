require 'ostruct'
require 'fusionauth/rest_client'

#
# Copyright (c) 2018-2025, FusionAuth, All Rights Reserved
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the License.
#

module FusionAuth
  #
  # This class is the the Ruby client library for the FusionAuth CIAM Platform {https://fusionauth.io}
  #
  # Each method on this class calls one of the APIs for FusionAuth. In most cases, the methods will take either a Hash, an
  # OpenStruct or any object that can be safely converted to JSON that conforms to the FusionAuth API interface. Likewise,
  # most methods will return an OpenStruct that contains the response JSON from FusionAuth.
  #
  # noinspection RubyInstanceMethodNamingConvention,RubyTooManyMethodsInspection,RubyParameterNamingConvention
  class FusionAuthClient
    attr_accessor :api_key, :base_url, :connect_timeout, :read_timeout, :tenant_id

    def initialize(api_key, base_url)
      @api_key = api_key
      @base_url = base_url
      @connect_timeout = 1000
      @read_timeout = 2000
      @tenant_id = nil
    end

    def set_tenant_id(tenant_id)
      @tenant_id = tenant_id
    end

    #
    # Takes an action on a user. The user being actioned is called the "actionee" and the user taking the action is called the
    # "actioner". Both user ids are required in the request object.
    #
    # @param request [OpenStruct, Hash] The action request that includes all the information about the action being taken including
    #     the Id of the action, any options and the duration (if applicable).
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def action_user(request)
      start.uri('/api/user/action')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Activates the FusionAuth Reactor using a license Id and optionally a license text (for air-gapped deployments)
    #
    # @param request [OpenStruct, Hash] An optional request that contains the license text to activate Reactor (useful for air-gap deployments of FusionAuth).
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def activate_reactor(request)
      start.uri('/api/reactor')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Adds a user to an existing family. The family Id must be specified.
    #
    # @param family_id [string] The Id of the family.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to determine which user to add to the family.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def add_user_to_family(family_id, request)
      start.uri('/api/user/family')
          .url_segment(family_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Approve a device grant.
    #
    # @param client_id [string] (Optional) The unique client identifier. The client Id is the Id of the FusionAuth Application in which you are attempting to authenticate.
    # @param client_secret [string] (Optional) The client secret. This value will be required if client authentication is enabled.
    # @param token [string] The access token used to identify the user.
    # @param user_code [string] The end-user verification code.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def approve_device(client_id, client_secret, token, user_code)
      body = {
        "client_id" => client_id,
        "client_secret" => client_secret,
        "token" => token,
        "user_code" => user_code
      }
      start.uri('/oauth2/device/approve')
          .body_handler(FusionAuth::FormDataBodyHandler.new(body))
          .post
          .go
    end

    #
    # Cancels the user action.
    #
    # @param action_id [string] The action Id of the action to cancel.
    # @param request [OpenStruct, Hash] The action request that contains the information about the cancellation.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def cancel_action(action_id, request)
      start.uri('/api/user/action')
          .url_segment(action_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .delete
          .go
    end

    #
    # Changes a user's password using the change password Id. This usually occurs after an email has been sent to the user
    # and they clicked on a link to reset their password.
    # 
    # As of version 1.32.2, prefer sending the changePasswordId in the request body. To do this, omit the first parameter, and set
    # the value in the request body.
    #
    # @param change_password_id [string] The change password Id used to find the user. This value is generated by FusionAuth once the change password workflow has been initiated.
    # @param request [OpenStruct, Hash] The change password request that contains all the information used to change the password.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def change_password(change_password_id, request)
      startAnonymous.uri('/api/user/change-password')
          .url_segment(change_password_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Changes a user's password using their access token (JWT) instead of the changePasswordId
    # A common use case for this method will be if you want to allow the user to change their own password.
    # 
    # Remember to send refreshToken in the request body if you want to get a new refresh token when login using the returned oneTimePassword.
    #
    # @param encoded_jwt [string] The encoded JWT (access token).
    # @param request [OpenStruct, Hash] The change password request that contains all the information used to change the password.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    # @deprecated This method has been renamed to change_password_using_jwt, use that method instead.
    def change_password_by_jwt(encoded_jwt, request)
      startAnonymous.uri('/api/user/change-password')
          .authorization('Bearer ' + encoded_jwt)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Changes a user's password using their identity (loginId and password). Using a loginId instead of the changePasswordId
    # bypasses the email verification and allows a password to be changed directly without first calling the #forgotPassword
    # method.
    #
    # @param request [OpenStruct, Hash] The change password request that contains all the information used to change the password.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def change_password_by_identity(request)
      start.uri('/api/user/change-password')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Changes a user's password using their access token (JWT) instead of the changePasswordId
    # A common use case for this method will be if you want to allow the user to change their own password.
    # 
    # Remember to send refreshToken in the request body if you want to get a new refresh token when login using the returned oneTimePassword.
    #
    # @param encoded_jwt [string] The encoded JWT (access token).
    # @param request [OpenStruct, Hash] The change password request that contains all the information used to change the password.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def change_password_using_jwt(encoded_jwt, request)
      startAnonymous.uri('/api/user/change-password')
          .authorization('Bearer ' + encoded_jwt)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Check to see if the user must obtain a Trust Token Id in order to complete a change password request.
    # When a user has enabled Two-Factor authentication, before you are allowed to use the Change Password API to change
    # your password, you must obtain a Trust Token by completing a Two-Factor Step-Up authentication.
    # 
    # An HTTP status code of 400 with a general error code of [TrustTokenRequired] indicates that a Trust Token is required to make a POST request to this API.
    #
    # @param change_password_id [string] The change password Id used to find the user. This value is generated by FusionAuth once the change password workflow has been initiated.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def check_change_password_using_id(change_password_id)
      startAnonymous.uri('/api/user/change-password')
          .url_segment(change_password_id)
          .get
          .go
    end

    #
    # Check to see if the user must obtain a Trust Token Id in order to complete a change password request.
    # When a user has enabled Two-Factor authentication, before you are allowed to use the Change Password API to change
    # your password, you must obtain a Trust Token by completing a Two-Factor Step-Up authentication.
    # 
    # An HTTP status code of 400 with a general error code of [TrustTokenRequired] indicates that a Trust Token is required to make a POST request to this API.
    #
    # @param encoded_jwt [string] The encoded JWT (access token).
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def check_change_password_using_jwt(encoded_jwt)
      startAnonymous.uri('/api/user/change-password')
          .authorization('Bearer ' + encoded_jwt)
          .get
          .go
    end

    #
    # Check to see if the user must obtain a Trust Request Id in order to complete a change password request.
    # When a user has enabled Two-Factor authentication, before you are allowed to use the Change Password API to change
    # your password, you must obtain a Trust Request Id by completing a Two-Factor Step-Up authentication.
    # 
    # An HTTP status code of 400 with a general error code of [TrustTokenRequired] indicates that a Trust Token is required to make a POST request to this API.
    #
    # @param login_id [string] The loginId of the User that you intend to change the password for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def check_change_password_using_login_id(login_id)
      start.uri('/api/user/change-password')
          .url_parameter('username', login_id)
          .get
          .go
    end

    #
    # Make a Client Credentials grant request to obtain an access token.
    #
    # @param client_id [string] (Optional) The client identifier. The client Id is the Id of the FusionAuth Entity in which you are attempting to authenticate.
    #     This parameter is optional when Basic Authorization is used to authenticate this request.
    # @param client_secret [string] (Optional) The client secret used to authenticate this request.
    #     This parameter is optional when Basic Authorization is used to authenticate this request.
    # @param scope [string] (Optional) This parameter is used to indicate which target entity you are requesting access. To request access to an entity, use the format target-entity:&lt;target-entity-id&gt;:&lt;roles&gt;. Roles are an optional comma separated list.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def client_credentials_grant(client_id, client_secret, scope)
      body = {
        "client_id" => client_id,
        "client_secret" => client_secret,
        "grant_type" => "client_credentials",
        "scope" => scope
      }
      startAnonymous.uri('/oauth2/token')
          .body_handler(FusionAuth::FormDataBodyHandler.new(body))
          .post
          .go
    end

    #
    # Adds a comment to the user's account.
    #
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the user comment.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def comment_on_user(request)
      start.uri('/api/user/comment')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Complete a WebAuthn authentication ceremony by validating the signature against the previously generated challenge without logging the user in
    #
    # @param request [OpenStruct, Hash] An object containing data necessary for completing the authentication ceremony
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def complete_web_authn_assertion(request)
      startAnonymous.uri('/api/webauthn/assert')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Complete a WebAuthn authentication ceremony by validating the signature against the previously generated challenge and then login the user in
    #
    # @param request [OpenStruct, Hash] An object containing data necessary for completing the authentication ceremony
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def complete_web_authn_login(request)
      startAnonymous.uri('/api/webauthn/login')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Complete a WebAuthn registration ceremony by validating the client request and saving the new credential
    #
    # @param request [OpenStruct, Hash] An object containing data necessary for completing the registration ceremony
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def complete_web_authn_registration(request)
      start.uri('/api/webauthn/register/complete')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates an API key. You can optionally specify a unique Id for the key, if not provided one will be generated.
    # an API key can only be created with equal or lesser authority. An API key cannot create another API key unless it is granted 
    # to that API key.
    # 
    # If an API key is locked to a tenant, it can only create API Keys for that same tenant.
    #
    # @param key_id [string] (Optional) The unique Id of the API key. If not provided a secure random Id will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information needed to create the APIKey.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_api_key(key_id, request)
      start.uri('/api/api-key')
          .url_segment(key_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates an application. You can optionally specify an Id for the application, if not provided one will be generated.
    #
    # @param application_id [string] (Optional) The Id to use for the application. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the application.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_application(application_id, request)
      start.uri('/api/application')
          .url_segment(application_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a new role for an application. You must specify the Id of the application you are creating the role for.
    # You can optionally specify an Id for the role inside the ApplicationRole object itself, if not provided one will be generated.
    #
    # @param application_id [string] The Id of the application to create the role on.
    # @param role_id [string] (Optional) The Id of the role. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the application role.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_application_role(application_id, role_id, request)
      start.uri('/api/application')
          .url_segment(application_id)
          .url_segment("role")
          .url_segment(role_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates an audit log with the message and user name (usually an email). Audit logs should be written anytime you
    # make changes to the FusionAuth database. When using the FusionAuth App web interface, any changes are automatically
    # written to the audit log. However, if you are accessing the API, you must write the audit logs yourself.
    #
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the audit log entry.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_audit_log(request)
      start.uri('/api/system/audit-log')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a connector.  You can optionally specify an Id for the connector, if not provided one will be generated.
    #
    # @param connector_id [string] (Optional) The Id for the connector. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the connector.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_connector(connector_id, request)
      start.uri('/api/connector')
          .url_segment(connector_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a user consent type. You can optionally specify an Id for the consent type, if not provided one will be generated.
    #
    # @param consent_id [string] (Optional) The Id for the consent. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the consent.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_consent(consent_id, request)
      start.uri('/api/consent')
          .url_segment(consent_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates an email template. You can optionally specify an Id for the template, if not provided one will be generated.
    #
    # @param email_template_id [string] (Optional) The Id for the template. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the email template.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_email_template(email_template_id, request)
      start.uri('/api/email/template')
          .url_segment(email_template_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates an Entity. You can optionally specify an Id for the Entity. If not provided one will be generated.
    #
    # @param entity_id [string] (Optional) The Id for the Entity. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the Entity.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_entity(entity_id, request)
      start.uri('/api/entity')
          .url_segment(entity_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a Entity Type. You can optionally specify an Id for the Entity Type, if not provided one will be generated.
    #
    # @param entity_type_id [string] (Optional) The Id for the Entity Type. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the Entity Type.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_entity_type(entity_type_id, request)
      start.uri('/api/entity/type')
          .url_segment(entity_type_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a new permission for an entity type. You must specify the Id of the entity type you are creating the permission for.
    # You can optionally specify an Id for the permission inside the EntityTypePermission object itself, if not provided one will be generated.
    #
    # @param entity_type_id [string] The Id of the entity type to create the permission on.
    # @param permission_id [string] (Optional) The Id of the permission. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the permission.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_entity_type_permission(entity_type_id, permission_id, request)
      start.uri('/api/entity/type')
          .url_segment(entity_type_id)
          .url_segment("permission")
          .url_segment(permission_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a family with the user Id in the request as the owner and sole member of the family. You can optionally specify an Id for the
    # family, if not provided one will be generated.
    #
    # @param family_id [string] (Optional) The Id for the family. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the family.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_family(family_id, request)
      start.uri('/api/user/family')
          .url_segment(family_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a form.  You can optionally specify an Id for the form, if not provided one will be generated.
    #
    # @param form_id [string] (Optional) The Id for the form. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the form.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_form(form_id, request)
      start.uri('/api/form')
          .url_segment(form_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a form field.  You can optionally specify an Id for the form, if not provided one will be generated.
    #
    # @param field_id [string] (Optional) The Id for the form field. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the form field.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_form_field(field_id, request)
      start.uri('/api/form/field')
          .url_segment(field_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a group. You can optionally specify an Id for the group, if not provided one will be generated.
    #
    # @param group_id [string] (Optional) The Id for the group. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the group.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_group(group_id, request)
      start.uri('/api/group')
          .url_segment(group_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a member in a group.
    #
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the group member(s).
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_group_members(request)
      start.uri('/api/group/member')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates an IP Access Control List. You can optionally specify an Id on this create request, if one is not provided one will be generated.
    #
    # @param access_control_list_id [string] (Optional) The Id for the IP Access Control List. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the IP Access Control List.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_ip_access_control_list(access_control_list_id, request)
      start.uri('/api/ip-acl')
          .url_segment(access_control_list_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates an identity provider. You can optionally specify an Id for the identity provider, if not provided one will be generated.
    #
    # @param identity_provider_id [string] (Optional) The Id of the identity provider. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the identity provider.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_identity_provider(identity_provider_id, request)
      start.uri('/api/identity-provider')
          .url_segment(identity_provider_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a Lambda. You can optionally specify an Id for the lambda, if not provided one will be generated.
    #
    # @param lambda_id [string] (Optional) The Id for the lambda. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the lambda.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_lambda(lambda_id, request)
      start.uri('/api/lambda')
          .url_segment(lambda_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates an message template. You can optionally specify an Id for the template, if not provided one will be generated.
    #
    # @param message_template_id [string] (Optional) The Id for the template. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the message template.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_message_template(message_template_id, request)
      start.uri('/api/message/template')
          .url_segment(message_template_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a messenger.  You can optionally specify an Id for the messenger, if not provided one will be generated.
    #
    # @param messenger_id [string] (Optional) The Id for the messenger. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the messenger.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_messenger(messenger_id, request)
      start.uri('/api/messenger')
          .url_segment(messenger_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a new custom OAuth scope for an application. You must specify the Id of the application you are creating the scope for.
    # You can optionally specify an Id for the OAuth scope on the URL, if not provided one will be generated.
    #
    # @param application_id [string] The Id of the application to create the OAuth scope on.
    # @param scope_id [string] (Optional) The Id of the OAuth scope. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the OAuth OAuth scope.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_o_auth_scope(application_id, scope_id, request)
      start.uri('/api/application')
          .url_segment(application_id)
          .url_segment("scope")
          .url_segment(scope_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a tenant. You can optionally specify an Id for the tenant, if not provided one will be generated.
    #
    # @param tenant_id [string] (Optional) The Id for the tenant. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the tenant.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_tenant(tenant_id, request)
      start.uri('/api/tenant')
          .url_segment(tenant_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a Theme. You can optionally specify an Id for the theme, if not provided one will be generated.
    #
    # @param theme_id [string] (Optional) The Id for the theme. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the theme.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_theme(theme_id, request)
      start.uri('/api/theme')
          .url_segment(theme_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a user. You can optionally specify an Id for the user, if not provided one will be generated.
    #
    # @param user_id [string] (Optional) The Id for the user. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_user(user_id, request)
      start.uri('/api/user')
          .url_segment(user_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a user action. This action cannot be taken on a user until this call successfully returns. Anytime after
    # that the user action can be applied to any user.
    #
    # @param user_action_id [string] (Optional) The Id for the user action. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the user action.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_user_action(user_action_id, request)
      start.uri('/api/user-action')
          .url_segment(user_action_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a user reason. This user action reason cannot be used when actioning a user until this call completes
    # successfully. Anytime after that the user action reason can be used.
    #
    # @param user_action_reason_id [string] (Optional) The Id for the user action reason. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the user action reason.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_user_action_reason(user_action_reason_id, request)
      start.uri('/api/user-action-reason')
          .url_segment(user_action_reason_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a single User consent.
    #
    # @param user_consent_id [string] (Optional) The Id for the User consent. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request that contains the user consent information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_user_consent(user_consent_id, request)
      start.uri('/api/user/consent')
          .url_segment(user_consent_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Link an external user from a 3rd party identity provider to a FusionAuth user.
    #
    # @param request [OpenStruct, Hash] The request object that contains all the information used to link the FusionAuth user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_user_link(request)
      start.uri('/api/identity-provider/link')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Creates a webhook. You can optionally specify an Id for the webhook, if not provided one will be generated.
    #
    # @param webhook_id [string] (Optional) The Id for the webhook. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the webhook.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def create_webhook(webhook_id, request)
      start.uri('/api/webhook')
          .url_segment(webhook_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Deactivates the application with the given Id.
    #
    # @param application_id [string] The Id of the application to deactivate.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def deactivate_application(application_id)
      start.uri('/api/application')
          .url_segment(application_id)
          .delete
          .go
    end

    #
    # Deactivates the FusionAuth Reactor.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def deactivate_reactor
      start.uri('/api/reactor')
          .delete
          .go
    end

    #
    # Deactivates the user with the given Id.
    #
    # @param user_id [string] The Id of the user to deactivate.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def deactivate_user(user_id)
      start.uri('/api/user')
          .url_segment(user_id)
          .delete
          .go
    end

    #
    # Deactivates the user action with the given Id.
    #
    # @param user_action_id [string] The Id of the user action to deactivate.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def deactivate_user_action(user_action_id)
      start.uri('/api/user-action')
          .url_segment(user_action_id)
          .delete
          .go
    end

    #
    # Deactivates the users with the given Ids.
    #
    # @param user_ids [Array] The ids of the users to deactivate.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    # @deprecated This method has been renamed to deactivate_users_by_ids, use that method instead.
    def deactivate_users(user_ids)
      start.uri('/api/user/bulk')
          .url_parameter('userId', user_ids)
          .url_parameter('dryRun', false)
          .url_parameter('hardDelete', false)
          .delete
          .go
    end

    #
    # Deactivates the users with the given Ids.
    #
    # @param user_ids [Array] The ids of the users to deactivate.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def deactivate_users_by_ids(user_ids)
      start.uri('/api/user/bulk')
          .url_parameter('userId', user_ids)
          .url_parameter('dryRun', false)
          .url_parameter('hardDelete', false)
          .delete
          .go
    end

    #
    # Deletes the API key for the given Id.
    #
    # @param key_id [string] The Id of the authentication API key to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_api_key(key_id)
      start.uri('/api/api-key')
          .url_segment(key_id)
          .delete
          .go
    end

    #
    # Hard deletes an application. This is a dangerous operation and should not be used in most circumstances. This will
    # delete the application, any registrations for that application, metrics and reports for the application, all the
    # roles for the application, and any other data associated with the application. This operation could take a very
    # long time, depending on the amount of data in your database.
    #
    # @param application_id [string] The Id of the application to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_application(application_id)
      start.uri('/api/application')
          .url_segment(application_id)
          .url_parameter('hardDelete', true)
          .delete
          .go
    end

    #
    # Hard deletes an application role. This is a dangerous operation and should not be used in most circumstances. This
    # permanently removes the given role from all users that had it.
    #
    # @param application_id [string] The Id of the application that the role belongs to.
    # @param role_id [string] The Id of the role to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_application_role(application_id, role_id)
      start.uri('/api/application')
          .url_segment(application_id)
          .url_segment("role")
          .url_segment(role_id)
          .delete
          .go
    end

    #
    # Deletes the connector for the given Id.
    #
    # @param connector_id [string] The Id of the connector to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_connector(connector_id)
      start.uri('/api/connector')
          .url_segment(connector_id)
          .delete
          .go
    end

    #
    # Deletes the consent for the given Id.
    #
    # @param consent_id [string] The Id of the consent to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_consent(consent_id)
      start.uri('/api/consent')
          .url_segment(consent_id)
          .delete
          .go
    end

    #
    # Deletes the email template for the given Id.
    #
    # @param email_template_id [string] The Id of the email template to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_email_template(email_template_id)
      start.uri('/api/email/template')
          .url_segment(email_template_id)
          .delete
          .go
    end

    #
    # Deletes the Entity for the given Id.
    #
    # @param entity_id [string] The Id of the Entity to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_entity(entity_id)
      start.uri('/api/entity')
          .url_segment(entity_id)
          .delete
          .go
    end

    #
    # Deletes an Entity Grant for the given User or Entity.
    #
    # @param entity_id [string] The Id of the Entity that the Entity Grant is being deleted for.
    # @param recipient_entity_id [string] (Optional) The Id of the Entity that the Entity Grant is for.
    # @param user_id [string] (Optional) The Id of the User that the Entity Grant is for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_entity_grant(entity_id, recipient_entity_id, user_id)
      start.uri('/api/entity')
          .url_segment(entity_id)
          .url_segment("grant")
          .url_parameter('recipientEntityId', recipient_entity_id)
          .url_parameter('userId', user_id)
          .delete
          .go
    end

    #
    # Deletes the Entity Type for the given Id.
    #
    # @param entity_type_id [string] The Id of the Entity Type to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_entity_type(entity_type_id)
      start.uri('/api/entity/type')
          .url_segment(entity_type_id)
          .delete
          .go
    end

    #
    # Hard deletes a permission. This is a dangerous operation and should not be used in most circumstances. This
    # permanently removes the given permission from all grants that had it.
    #
    # @param entity_type_id [string] The Id of the entityType the the permission belongs to.
    # @param permission_id [string] The Id of the permission to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_entity_type_permission(entity_type_id, permission_id)
      start.uri('/api/entity/type')
          .url_segment(entity_type_id)
          .url_segment("permission")
          .url_segment(permission_id)
          .delete
          .go
    end

    #
    # Deletes the form for the given Id.
    #
    # @param form_id [string] The Id of the form to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_form(form_id)
      start.uri('/api/form')
          .url_segment(form_id)
          .delete
          .go
    end

    #
    # Deletes the form field for the given Id.
    #
    # @param field_id [string] The Id of the form field to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_form_field(field_id)
      start.uri('/api/form/field')
          .url_segment(field_id)
          .delete
          .go
    end

    #
    # Deletes the group for the given Id.
    #
    # @param group_id [string] The Id of the group to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_group(group_id)
      start.uri('/api/group')
          .url_segment(group_id)
          .delete
          .go
    end

    #
    # Removes users as members of a group.
    #
    # @param request [OpenStruct, Hash] The member request that contains all the information used to remove members to the group.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_group_members(request)
      start.uri('/api/group/member')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .delete
          .go
    end

    #
    # Deletes the IP Access Control List for the given Id.
    #
    # @param ip_access_control_list_id [string] The Id of the IP Access Control List to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_ip_access_control_list(ip_access_control_list_id)
      start.uri('/api/ip-acl')
          .url_segment(ip_access_control_list_id)
          .delete
          .go
    end

    #
    # Deletes the identity provider for the given Id.
    #
    # @param identity_provider_id [string] The Id of the identity provider to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_identity_provider(identity_provider_id)
      start.uri('/api/identity-provider')
          .url_segment(identity_provider_id)
          .delete
          .go
    end

    #
    # Deletes the key for the given Id.
    #
    # @param key_id [string] The Id of the key to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_key(key_id)
      start.uri('/api/key')
          .url_segment(key_id)
          .delete
          .go
    end

    #
    # Deletes the lambda for the given Id.
    #
    # @param lambda_id [string] The Id of the lambda to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_lambda(lambda_id)
      start.uri('/api/lambda')
          .url_segment(lambda_id)
          .delete
          .go
    end

    #
    # Deletes the message template for the given Id.
    #
    # @param message_template_id [string] The Id of the message template to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_message_template(message_template_id)
      start.uri('/api/message/template')
          .url_segment(message_template_id)
          .delete
          .go
    end

    #
    # Deletes the messenger for the given Id.
    #
    # @param messenger_id [string] The Id of the messenger to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_messenger(messenger_id)
      start.uri('/api/messenger')
          .url_segment(messenger_id)
          .delete
          .go
    end

    #
    # Hard deletes a custom OAuth scope.
    # OAuth workflows that are still requesting the deleted OAuth scope may fail depending on the application's unknown scope policy.
    #
    # @param application_id [string] The Id of the application that the OAuth scope belongs to.
    # @param scope_id [string] The Id of the OAuth scope to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_o_auth_scope(application_id, scope_id)
      start.uri('/api/application')
          .url_segment(application_id)
          .url_segment("scope")
          .url_segment(scope_id)
          .delete
          .go
    end

    #
    # Deletes the user registration for the given user and application.
    #
    # @param user_id [string] The Id of the user whose registration is being deleted.
    # @param application_id [string] The Id of the application to remove the registration for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_registration(user_id, application_id)
      start.uri('/api/user/registration')
          .url_segment(user_id)
          .url_segment(application_id)
          .delete
          .go
    end

    #
    # Deletes the user registration for the given user and application along with the given JSON body that contains the event information.
    #
    # @param user_id [string] The Id of the user whose registration is being deleted.
    # @param application_id [string] The Id of the application to remove the registration for.
    # @param request [OpenStruct, Hash] The request body that contains the event information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_registration_with_request(user_id, application_id, request)
      start.uri('/api/user/registration')
          .url_segment(user_id)
          .url_segment(application_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .delete
          .go
    end

    #
    # Deletes the tenant based on the given Id on the URL. This permanently deletes all information, metrics, reports and data associated
    # with the tenant and everything under the tenant (applications, users, etc).
    #
    # @param tenant_id [string] The Id of the tenant to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_tenant(tenant_id)
      start.uri('/api/tenant')
          .url_segment(tenant_id)
          .delete
          .go
    end

    #
    # Deletes the tenant for the given Id asynchronously.
    # This method is helpful if you do not want to wait for the delete operation to complete.
    #
    # @param tenant_id [string] The Id of the tenant to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_tenant_async(tenant_id)
      start.uri('/api/tenant')
          .url_segment(tenant_id)
          .url_parameter('async', true)
          .delete
          .go
    end

    #
    # Deletes the tenant based on the given request (sent to the API as JSON). This permanently deletes all information, metrics, reports and data associated
    # with the tenant and everything under the tenant (applications, users, etc).
    #
    # @param tenant_id [string] The Id of the tenant to delete.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to delete the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_tenant_with_request(tenant_id, request)
      start.uri('/api/tenant')
          .url_segment(tenant_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .delete
          .go
    end

    #
    # Deletes the theme for the given Id.
    #
    # @param theme_id [string] The Id of the theme to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_theme(theme_id)
      start.uri('/api/theme')
          .url_segment(theme_id)
          .delete
          .go
    end

    #
    # Deletes the user for the given Id. This permanently deletes all information, metrics, reports and data associated
    # with the user.
    #
    # @param user_id [string] The Id of the user to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_user(user_id)
      start.uri('/api/user')
          .url_segment(user_id)
          .url_parameter('hardDelete', true)
          .delete
          .go
    end

    #
    # Deletes the user action for the given Id. This permanently deletes the user action and also any history and logs of
    # the action being applied to any users.
    #
    # @param user_action_id [string] The Id of the user action to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_user_action(user_action_id)
      start.uri('/api/user-action')
          .url_segment(user_action_id)
          .url_parameter('hardDelete', true)
          .delete
          .go
    end

    #
    # Deletes the user action reason for the given Id.
    #
    # @param user_action_reason_id [string] The Id of the user action reason to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_user_action_reason(user_action_reason_id)
      start.uri('/api/user-action-reason')
          .url_segment(user_action_reason_id)
          .delete
          .go
    end

    #
    # Remove an existing link that has been made from a 3rd party identity provider to a FusionAuth user.
    #
    # @param identity_provider_id [string] The unique Id of the identity provider.
    # @param identity_provider_user_id [string] The unique Id of the user in the 3rd party identity provider to unlink.
    # @param user_id [string] The unique Id of the FusionAuth user to unlink.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_user_link(identity_provider_id, identity_provider_user_id, user_id)
      start.uri('/api/identity-provider/link')
          .url_parameter('identityProviderId', identity_provider_id)
          .url_parameter('identityProviderUserId', identity_provider_user_id)
          .url_parameter('userId', user_id)
          .delete
          .go
    end

    #
    # Deletes the user based on the given request (sent to the API as JSON). This permanently deletes all information, metrics, reports and data associated
    # with the user.
    #
    # @param user_id [string] The Id of the user to delete (required).
    # @param request [OpenStruct, Hash] The request object that contains all the information used to delete the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_user_with_request(user_id, request)
      start.uri('/api/user')
          .url_segment(user_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .delete
          .go
    end

    #
    # Deletes the users with the given Ids, or users matching the provided JSON query or queryString.
    # The order of preference is Ids, query and then queryString, it is recommended to only provide one of the three for the request.
    # 
    # This method can be used to deactivate or permanently delete (hard-delete) users based upon the hardDelete boolean in the request body.
    # Using the dryRun parameter you may also request the result of the action without actually deleting or deactivating any users.
    #
    # @param request [OpenStruct, Hash] The UserDeleteRequest.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    # @deprecated This method has been renamed to delete_users_by_query, use that method instead.
    def delete_users(request)
      start.uri('/api/user/bulk')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .delete
          .go
    end

    #
    # Deletes the users with the given Ids, or users matching the provided JSON query or queryString.
    # The order of preference is Ids, query and then queryString, it is recommended to only provide one of the three for the request.
    # 
    # This method can be used to deactivate or permanently delete (hard-delete) users based upon the hardDelete boolean in the request body.
    # Using the dryRun parameter you may also request the result of the action without actually deleting or deactivating any users.
    #
    # @param request [OpenStruct, Hash] The UserDeleteRequest.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_users_by_query(request)
      start.uri('/api/user/bulk')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .delete
          .go
    end

    #
    # Deletes the WebAuthn credential for the given Id.
    #
    # @param id [string] The Id of the WebAuthn credential to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_web_authn_credential(id)
      start.uri('/api/webauthn')
          .url_segment(id)
          .delete
          .go
    end

    #
    # Deletes the webhook for the given Id.
    #
    # @param webhook_id [string] The Id of the webhook to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def delete_webhook(webhook_id)
      start.uri('/api/webhook')
          .url_segment(webhook_id)
          .delete
          .go
    end

    #
    # Disable two-factor authentication for a user.
    #
    # @param user_id [string] The Id of the User for which you're disabling two-factor authentication.
    # @param method_id [string] The two-factor method identifier you wish to disable
    # @param code [string] The two-factor code used verify the the caller knows the two-factor secret.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def disable_two_factor(user_id, method_id, code)
      start.uri('/api/user/two-factor')
          .url_segment(user_id)
          .url_parameter('methodId', method_id)
          .url_parameter('code', code)
          .delete
          .go
    end

    #
    # Disable two-factor authentication for a user using a JSON body rather than URL parameters.
    #
    # @param user_id [string] The Id of the User for which you're disabling two-factor authentication.
    # @param request [OpenStruct, Hash] The request information that contains the code and methodId along with any event information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def disable_two_factor_with_request(user_id, request)
      start.uri('/api/user/two-factor')
          .url_segment(user_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .delete
          .go
    end

    #
    # Enable two-factor authentication for a user.
    #
    # @param user_id [string] The Id of the user to enable two-factor authentication.
    # @param request [OpenStruct, Hash] The two-factor enable request information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def enable_two_factor(user_id, request)
      start.uri('/api/user/two-factor')
          .url_segment(user_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Exchanges an OAuth authorization code for an access token.
    # Makes a request to the Token endpoint to exchange the authorization code returned from the Authorize endpoint for an access token.
    #
    # @param code [string] The authorization code returned on the /oauth2/authorize response.
    # @param client_id [string] (Optional) The unique client identifier. The client Id is the Id of the FusionAuth Application in which you are attempting to authenticate.
    #     This parameter is optional when Basic Authorization is used to authenticate this request.
    # @param client_secret [string] (Optional) The client secret. This value will be required if client authentication is enabled.
    # @param redirect_uri [string] The URI to redirect to upon a successful request.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def exchange_o_auth_code_for_access_token(code, client_id, client_secret, redirect_uri)
      body = {
        "code" => code,
        "client_id" => client_id,
        "client_secret" => client_secret,
        "grant_type" => "authorization_code",
        "redirect_uri" => redirect_uri
      }
      startAnonymous.uri('/oauth2/token')
          .body_handler(FusionAuth::FormDataBodyHandler.new(body))
          .post
          .go
    end

    #
    # Exchanges an OAuth authorization code and code_verifier for an access token.
    # Makes a request to the Token endpoint to exchange the authorization code returned from the Authorize endpoint and a code_verifier for an access token.
    #
    # @param code [string] The authorization code returned on the /oauth2/authorize response.
    # @param client_id [string] (Optional) The unique client identifier. The client Id is the Id of the FusionAuth Application in which you are attempting to authenticate. This parameter is optional when the Authorization header is provided.
    #     This parameter is optional when Basic Authorization is used to authenticate this request.
    # @param client_secret [string] (Optional) The client secret. This value may optionally be provided in the request body instead of the Authorization header.
    # @param redirect_uri [string] The URI to redirect to upon a successful request.
    # @param code_verifier [string] The random string generated previously. Will be compared with the code_challenge sent previously, which allows the OAuth provider to authenticate your app.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def exchange_o_auth_code_for_access_token_using_pkce(code, client_id, client_secret, redirect_uri, code_verifier)
      body = {
        "code" => code,
        "client_id" => client_id,
        "client_secret" => client_secret,
        "grant_type" => "authorization_code",
        "redirect_uri" => redirect_uri,
        "code_verifier" => code_verifier
      }
      startAnonymous.uri('/oauth2/token')
          .body_handler(FusionAuth::FormDataBodyHandler.new(body))
          .post
          .go
    end

    #
    # Exchange a Refresh Token for an Access Token.
    # If you will be using the Refresh Token Grant, you will make a request to the Token endpoint to exchange the user’s refresh token for an access token.
    #
    # @param refresh_token [string] The refresh token that you would like to use to exchange for an access token.
    # @param client_id [string] (Optional) The unique client identifier. The client Id is the Id of the FusionAuth Application in which you are attempting to authenticate. This parameter is optional when the Authorization header is provided.
    #     This parameter is optional when Basic Authorization is used to authenticate this request.
    # @param client_secret [string] (Optional) The client secret. This value may optionally be provided in the request body instead of the Authorization header.
    # @param scope [string] (Optional) This parameter is optional and if omitted, the same scope requested during the authorization request will be used. If provided the scopes must match those requested during the initial authorization request.
    # @param user_code [string] (Optional) The end-user verification code. This code is required if using this endpoint to approve the Device Authorization.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def exchange_refresh_token_for_access_token(refresh_token, client_id, client_secret, scope, user_code)
      body = {
        "refresh_token" => refresh_token,
        "client_id" => client_id,
        "client_secret" => client_secret,
        "grant_type" => "refresh_token",
        "scope" => scope,
        "user_code" => user_code
      }
      startAnonymous.uri('/oauth2/token')
          .body_handler(FusionAuth::FormDataBodyHandler.new(body))
          .post
          .go
    end

    #
    # Exchange a refresh token for a new JWT.
    #
    # @param request [OpenStruct, Hash] The refresh request.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def exchange_refresh_token_for_jwt(request)
      startAnonymous.uri('/api/jwt/refresh')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Exchange User Credentials for a Token.
    # If you will be using the Resource Owner Password Credential Grant, you will make a request to the Token endpoint to exchange the user’s email and password for an access token.
    #
    # @param username [string] The login identifier of the user. The login identifier can be either the email or the username.
    # @param password [string] The user’s password.
    # @param client_id [string] (Optional) The unique client identifier. The client Id is the Id of the FusionAuth Application in which you are attempting to authenticate. This parameter is optional when the Authorization header is provided.
    #     This parameter is optional when Basic Authorization is used to authenticate this request.
    # @param client_secret [string] (Optional) The client secret. This value may optionally be provided in the request body instead of the Authorization header.
    # @param scope [string] (Optional) This parameter is optional and if omitted, the same scope requested during the authorization request will be used. If provided the scopes must match those requested during the initial authorization request.
    # @param user_code [string] (Optional) The end-user verification code. This code is required if using this endpoint to approve the Device Authorization.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def exchange_user_credentials_for_access_token(username, password, client_id, client_secret, scope, user_code)
      body = {
        "username" => username,
        "password" => password,
        "client_id" => client_id,
        "client_secret" => client_secret,
        "grant_type" => "password",
        "scope" => scope,
        "user_code" => user_code
      }
      startAnonymous.uri('/oauth2/token')
          .body_handler(FusionAuth::FormDataBodyHandler.new(body))
          .post
          .go
    end

    #
    # Begins the forgot password sequence, which kicks off an email to the user so that they can reset their password.
    #
    # @param request [OpenStruct, Hash] The request that contains the information about the user so that they can be emailed.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def forgot_password(request)
      start.uri('/api/user/forgot-password')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Generate a new Email Verification Id to be used with the Verify Email API. This API will not attempt to send an
    # email to the User. This API may be used to collect the verificationId for use with a third party system.
    #
    # @param email [string] The email address of the user that needs a new verification email.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def generate_email_verification_id(email)
      start.uri('/api/user/verify-email')
          .url_parameter('email', email)
          .url_parameter('sendVerifyEmail', false)
          .put
          .go
    end

    #
    # Generate a new RSA or EC key pair or an HMAC secret.
    #
    # @param key_id [string] (Optional) The Id for the key. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the key.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def generate_key(key_id, request)
      start.uri('/api/key/generate')
          .url_segment(key_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Generate a new Application Registration Verification Id to be used with the Verify Registration API. This API will not attempt to send an
    # email to the User. This API may be used to collect the verificationId for use with a third party system.
    #
    # @param email [string] The email address of the user that needs a new verification email.
    # @param application_id [string] The Id of the application to be verified.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def generate_registration_verification_id(email, application_id)
      start.uri('/api/user/verify-registration')
          .url_parameter('email', email)
          .url_parameter('sendVerifyPasswordEmail', false)
          .url_parameter('applicationId', application_id)
          .put
          .go
    end

    #
    # Generate two-factor recovery codes for a user. Generating two-factor recovery codes will invalidate any existing recovery codes. 
    #
    # @param user_id [string] The Id of the user to generate new Two Factor recovery codes.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def generate_two_factor_recovery_codes(user_id)
      start.uri('/api/user/two-factor/recovery-code')
          .url_segment(user_id)
          .post
          .go
    end

    #
    # Generate a Two Factor secret that can be used to enable Two Factor authentication for a User. The response will contain
    # both the secret and a Base32 encoded form of the secret which can be shown to a User when using a 2 Step Authentication
    # application such as Google Authenticator.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def generate_two_factor_secret
      start.uri('/api/two-factor/secret')
          .get
          .go
    end

    #
    # Generate a Two Factor secret that can be used to enable Two Factor authentication for a User. The response will contain
    # both the secret and a Base32 encoded form of the secret which can be shown to a User when using a 2 Step Authentication
    # application such as Google Authenticator.
    #
    # @param encoded_jwt [string] The encoded JWT (access token).
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def generate_two_factor_secret_using_jwt(encoded_jwt)
      startAnonymous.uri('/api/two-factor/secret')
          .authorization('Bearer ' + encoded_jwt)
          .get
          .go
    end

    #
    # Handles login via third-parties including Social login, external OAuth and OpenID Connect, and other
    # login systems.
    #
    # @param request [OpenStruct, Hash] The third-party login request that contains information from the third-party login
    #     providers that FusionAuth uses to reconcile the user's account.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def identity_provider_login(request)
      startAnonymous.uri('/api/identity-provider/login')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Import an existing RSA or EC key pair or an HMAC secret.
    #
    # @param key_id [string] (Optional) The Id for the key. If not provided a secure random UUID will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the key.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def import_key(key_id, request)
      start.uri('/api/key/import')
          .url_segment(key_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Bulk imports refresh tokens. This request performs minimal validation and runs batch inserts of refresh tokens with the
    # expectation that each token represents a user that already exists and is registered for the corresponding FusionAuth
    # Application. This is done to increases the insert performance.
    # 
    # Therefore, if you encounter an error due to a database key violation, the response will likely offer a generic
    # explanation. If you encounter an error, you may optionally enable additional validation to receive a JSON response
    # body with specific validation errors. This will slow the request down but will allow you to identify the cause of
    # the failure. See the validateDbConstraints request parameter.
    #
    # @param request [OpenStruct, Hash] The request that contains all the information about all the refresh tokens to import.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def import_refresh_tokens(request)
      start.uri('/api/user/refresh-token/import')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Bulk imports users. This request performs minimal validation and runs batch inserts of users with the expectation
    # that each user does not yet exist and each registration corresponds to an existing FusionAuth Application. This is done to
    # increases the insert performance.
    # 
    # Therefore, if you encounter an error due to a database key violation, the response will likely offer
    # a generic explanation. If you encounter an error, you may optionally enable additional validation to receive a JSON response
    # body with specific validation errors. This will slow the request down but will allow you to identify the cause of the failure. See
    # the validateDbConstraints request parameter.
    #
    # @param request [OpenStruct, Hash] The request that contains all the information about all the users to import.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def import_users(request)
      start.uri('/api/user/import')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Import a WebAuthn credential
    #
    # @param request [OpenStruct, Hash] An object containing data necessary for importing the credential
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def import_web_authn_credential(request)
      start.uri('/api/webauthn/import')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Inspect an access token issued as the result of the User based grant such as the Authorization Code Grant, Implicit Grant, the User Credentials Grant or the Refresh Grant.
    #
    # @param client_id [string] The unique client identifier. The client Id is the Id of the FusionAuth Application for which this token was generated.
    # @param token [string] The access token returned by this OAuth provider as the result of a successful client credentials grant.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def introspect_access_token(client_id, token)
      body = {
        "client_id" => client_id,
        "token" => token
      }
      startAnonymous.uri('/oauth2/introspect')
          .body_handler(FusionAuth::FormDataBodyHandler.new(body))
          .post
          .go
    end

    #
    # Inspect an access token issued as the result of the Client Credentials Grant.
    #
    # @param token [string] The access token returned by this OAuth provider as the result of a successful client credentials grant.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def introspect_client_credentials_access_token(token)
      body = {
        "token" => token
      }
      startAnonymous.uri('/oauth2/introspect')
          .body_handler(FusionAuth::FormDataBodyHandler.new(body))
          .post
          .go
    end

    #
    # Issue a new access token (JWT) for the requested Application after ensuring the provided JWT is valid. A valid
    # access token is properly signed and not expired.
    # <p>
    # This API may be used in an SSO configuration to issue new tokens for another application after the user has
    # obtained a valid token from authentication.
    #
    # @param application_id [string] The Application Id for which you are requesting a new access token be issued.
    # @param encoded_jwt [string] The encoded JWT (access token).
    # @param refresh_token [string] (Optional) An existing refresh token used to request a refresh token in addition to a JWT in the response.
    #     <p>The target application represented by the applicationId request parameter must have refresh
    #     tokens enabled in order to receive a refresh token in the response.</p>
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def issue_jwt(application_id, encoded_jwt, refresh_token)
      startAnonymous.uri('/api/jwt/issue')
          .authorization('Bearer ' + encoded_jwt)
          .url_parameter('applicationId', application_id)
          .url_parameter('refreshToken', refresh_token)
          .get
          .go
    end

    #
    # Authenticates a user to FusionAuth. 
    # 
    # This API optionally requires an API key. See <code>Application.loginConfiguration.requireAuthentication</code>.
    #
    # @param request [OpenStruct, Hash] The login request that contains the user credentials used to log them in.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def login(request)
      start.uri('/api/login')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Sends a ping to FusionAuth indicating that the user was automatically logged into an application. When using
    # FusionAuth's SSO or your own, you should call this if the user is already logged in centrally, but accesses an
    # application where they no longer have a session. This helps correctly track login counts, times and helps with
    # reporting.
    #
    # @param user_id [string] The Id of the user that was logged in.
    # @param application_id [string] The Id of the application that they logged into.
    # @param caller_ip_address [string] (Optional) The IP address of the end-user that is logging in. If a null value is provided
    #     the IP address will be that of the client or last proxy that sent the request.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def login_ping(user_id, application_id, caller_ip_address)
      start.uri('/api/login')
          .url_segment(user_id)
          .url_segment(application_id)
          .url_parameter('ipAddress', caller_ip_address)
          .put
          .go
    end

    #
    # Sends a ping to FusionAuth indicating that the user was automatically logged into an application. When using
    # FusionAuth's SSO or your own, you should call this if the user is already logged in centrally, but accesses an
    # application where they no longer have a session. This helps correctly track login counts, times and helps with
    # reporting.
    #
    # @param request [OpenStruct, Hash] The login request that contains the user credentials used to log them in.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def login_ping_with_request(request)
      start.uri('/api/login')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # The Logout API is intended to be used to remove the refresh token and access token cookies if they exist on the
    # client and revoke the refresh token stored. This API does nothing if the request does not contain an access
    # token or refresh token cookies.
    #
    # @param global [Boolean] When this value is set to true all the refresh tokens issued to the owner of the
    #     provided token will be revoked.
    # @param refresh_token [string] (Optional) The refresh_token as a request parameter instead of coming in via a cookie.
    #     If provided this takes precedence over the cookie.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def logout(global, refresh_token)
      startAnonymous.uri('/api/logout')
          .url_parameter('global', global)
          .url_parameter('refreshToken', refresh_token)
          .post
          .go
    end

    #
    # The Logout API is intended to be used to remove the refresh token and access token cookies if they exist on the
    # client and revoke the refresh token stored. This API takes the refresh token in the JSON body.
    #
    # @param request [OpenStruct, Hash] The request object that contains all the information used to logout the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def logout_with_request(request)
      startAnonymous.uri('/api/logout')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Retrieves the identity provider for the given domain. A 200 response code indicates the domain is managed
    # by a registered identity provider. A 404 indicates the domain is not managed.
    #
    # @param domain [string] The domain or email address to lookup.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def lookup_identity_provider(domain)
      start.uri('/api/identity-provider/lookup')
          .url_parameter('domain', domain)
          .get
          .go
    end

    #
    # Modifies a temporal user action by changing the expiration of the action and optionally adding a comment to the
    # action.
    #
    # @param action_id [string] The Id of the action to modify. This is technically the user action log Id.
    # @param request [OpenStruct, Hash] The request that contains all the information about the modification.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def modify_action(action_id, request)
      start.uri('/api/user/action')
          .url_segment(action_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Complete a login request using a passwordless code
    #
    # @param request [OpenStruct, Hash] The passwordless login request that contains all the information used to complete login.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def passwordless_login(request)
      startAnonymous.uri('/api/passwordless/login')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Updates an API key with the given Id.
    #
    # @param key_id [string] The Id of the API key. If not provided a secure random api key will be generated.
    # @param request [OpenStruct, Hash] The request object that contains all the information needed to create the API key.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_api_key(key_id, request)
      start.uri('/api/api-key')
          .url_segment(key_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the application with the given Id.
    #
    # @param application_id [string] The Id of the application to update.
    # @param request [OpenStruct, Hash] The request that contains just the new application information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_application(application_id, request)
      start.uri('/api/application')
          .url_segment(application_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the application role with the given Id for the application.
    #
    # @param application_id [string] The Id of the application that the role belongs to.
    # @param role_id [string] The Id of the role to update.
    # @param request [OpenStruct, Hash] The request that contains just the new role information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_application_role(application_id, role_id, request)
      start.uri('/api/application')
          .url_segment(application_id)
          .url_segment("role")
          .url_segment(role_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the connector with the given Id.
    #
    # @param connector_id [string] The Id of the connector to update.
    # @param request [OpenStruct, Hash] The request that contains just the new connector information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_connector(connector_id, request)
      start.uri('/api/connector')
          .url_segment(connector_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the consent with the given Id.
    #
    # @param consent_id [string] The Id of the consent to update.
    # @param request [OpenStruct, Hash] The request that contains just the new consent information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_consent(consent_id, request)
      start.uri('/api/consent')
          .url_segment(consent_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the email template with the given Id.
    #
    # @param email_template_id [string] The Id of the email template to update.
    # @param request [OpenStruct, Hash] The request that contains just the new email template information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_email_template(email_template_id, request)
      start.uri('/api/email/template')
          .url_segment(email_template_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the Entity with the given Id.
    #
    # @param entity_id [string] The Id of the Entity Type to update.
    # @param request [OpenStruct, Hash] The request that contains just the new Entity information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_entity(entity_id, request)
      start.uri('/api/entity')
          .url_segment(entity_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the Entity Type with the given Id.
    #
    # @param entity_type_id [string] The Id of the Entity Type to update.
    # @param request [OpenStruct, Hash] The request that contains just the new Entity Type information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_entity_type(entity_type_id, request)
      start.uri('/api/entity/type')
          .url_segment(entity_type_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Patches the permission with the given Id for the entity type.
    #
    # @param entity_type_id [string] The Id of the entityType that the permission belongs to.
    # @param permission_id [string] The Id of the permission to patch.
    # @param request [OpenStruct, Hash] The request that contains the new permission information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_entity_type_permission(entity_type_id, permission_id, request)
      start.uri('/api/entity/type')
          .url_segment(entity_type_id)
          .url_segment("permission")
          .url_segment(permission_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Patches the form with the given Id.
    #
    # @param form_id [string] The Id of the form to patch.
    # @param request [OpenStruct, Hash] The request object that contains the new form information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_form(form_id, request)
      start.uri('/api/form')
          .url_segment(form_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Patches the form field with the given Id.
    #
    # @param field_id [string] The Id of the form field to patch.
    # @param request [OpenStruct, Hash] The request object that contains the new form field information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_form_field(field_id, request)
      start.uri('/api/form/field')
          .url_segment(field_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the group with the given Id.
    #
    # @param group_id [string] The Id of the group to update.
    # @param request [OpenStruct, Hash] The request that contains just the new group information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_group(group_id, request)
      start.uri('/api/group')
          .url_segment(group_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Update the IP Access Control List with the given Id.
    #
    # @param access_control_list_id [string] The Id of the IP Access Control List to patch.
    # @param request [OpenStruct, Hash] The request that contains the new IP Access Control List information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_ip_access_control_list(access_control_list_id, request)
      start.uri('/api/ip-acl')
          .url_segment(access_control_list_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the identity provider with the given Id.
    #
    # @param identity_provider_id [string] The Id of the identity provider to update.
    # @param request [OpenStruct, Hash] The request object that contains just the updated identity provider information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_identity_provider(identity_provider_id, request)
      start.uri('/api/identity-provider')
          .url_segment(identity_provider_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the available integrations.
    #
    # @param request [OpenStruct, Hash] The request that contains just the new integration information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_integrations(request)
      start.uri('/api/integration')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the lambda with the given Id.
    #
    # @param lambda_id [string] The Id of the lambda to update.
    # @param request [OpenStruct, Hash] The request that contains just the new lambda information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_lambda(lambda_id, request)
      start.uri('/api/lambda')
          .url_segment(lambda_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the message template with the given Id.
    #
    # @param message_template_id [string] The Id of the message template to update.
    # @param request [OpenStruct, Hash] The request that contains just the new message template information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_message_template(message_template_id, request)
      start.uri('/api/message/template')
          .url_segment(message_template_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the messenger with the given Id.
    #
    # @param messenger_id [string] The Id of the messenger to update.
    # @param request [OpenStruct, Hash] The request that contains just the new messenger information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_messenger(messenger_id, request)
      start.uri('/api/messenger')
          .url_segment(messenger_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the custom OAuth scope with the given Id for the application.
    #
    # @param application_id [string] The Id of the application that the OAuth scope belongs to.
    # @param scope_id [string] The Id of the OAuth scope to update.
    # @param request [OpenStruct, Hash] The request that contains just the new OAuth scope information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_o_auth_scope(application_id, scope_id, request)
      start.uri('/api/application')
          .url_segment(application_id)
          .url_segment("scope")
          .url_segment(scope_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the registration for the user with the given Id and the application defined in the request.
    #
    # @param user_id [string] The Id of the user whose registration is going to be updated.
    # @param request [OpenStruct, Hash] The request that contains just the new registration information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_registration(user_id, request)
      start.uri('/api/user/registration')
          .url_segment(user_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the system configuration.
    #
    # @param request [OpenStruct, Hash] The request that contains just the new system configuration information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_system_configuration(request)
      start.uri('/api/system-configuration')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the tenant with the given Id.
    #
    # @param tenant_id [string] The Id of the tenant to update.
    # @param request [OpenStruct, Hash] The request that contains just the new tenant information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_tenant(tenant_id, request)
      start.uri('/api/tenant')
          .url_segment(tenant_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the theme with the given Id.
    #
    # @param theme_id [string] The Id of the theme to update.
    # @param request [OpenStruct, Hash] The request that contains just the new theme information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_theme(theme_id, request)
      start.uri('/api/theme')
          .url_segment(theme_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the user with the given Id.
    #
    # @param user_id [string] The Id of the user to update.
    # @param request [OpenStruct, Hash] The request that contains just the new user information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_user(user_id, request)
      start.uri('/api/user')
          .url_segment(user_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the user action with the given Id.
    #
    # @param user_action_id [string] The Id of the user action to update.
    # @param request [OpenStruct, Hash] The request that contains just the new user action information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_user_action(user_action_id, request)
      start.uri('/api/user-action')
          .url_segment(user_action_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, the user action reason with the given Id.
    #
    # @param user_action_reason_id [string] The Id of the user action reason to update.
    # @param request [OpenStruct, Hash] The request that contains just the new user action reason information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_user_action_reason(user_action_reason_id, request)
      start.uri('/api/user-action-reason')
          .url_segment(user_action_reason_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Updates, via PATCH, a single User consent by Id.
    #
    # @param user_consent_id [string] The User Consent Id
    # @param request [OpenStruct, Hash] The request that contains just the new user consent information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_user_consent(user_consent_id, request)
      start.uri('/api/user/consent')
          .url_segment(user_consent_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Patches the webhook with the given Id.
    #
    # @param webhook_id [string] The Id of the webhook to update.
    # @param request [OpenStruct, Hash] The request that contains the new webhook information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def patch_webhook(webhook_id, request)
      start.uri('/api/webhook')
          .url_segment(webhook_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .patch
          .go
    end

    #
    # Reactivates the application with the given Id.
    #
    # @param application_id [string] The Id of the application to reactivate.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def reactivate_application(application_id)
      start.uri('/api/application')
          .url_segment(application_id)
          .url_parameter('reactivate', true)
          .put
          .go
    end

    #
    # Reactivates the user with the given Id.
    #
    # @param user_id [string] The Id of the user to reactivate.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def reactivate_user(user_id)
      start.uri('/api/user')
          .url_segment(user_id)
          .url_parameter('reactivate', true)
          .put
          .go
    end

    #
    # Reactivates the user action with the given Id.
    #
    # @param user_action_id [string] The Id of the user action to reactivate.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def reactivate_user_action(user_action_id)
      start.uri('/api/user-action')
          .url_segment(user_action_id)
          .url_parameter('reactivate', true)
          .put
          .go
    end

    #
    # Reconcile a User to FusionAuth using JWT issued from another Identity Provider.
    #
    # @param request [OpenStruct, Hash] The reconcile request that contains the data to reconcile the User.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def reconcile_jwt(request)
      startAnonymous.uri('/api/jwt/reconcile')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Request a refresh of the Entity search index. This API is not generally necessary and the search index will become consistent in a
    # reasonable amount of time. There may be scenarios where you may wish to manually request an index refresh. One example may be 
    # if you are using the Search API or Delete Tenant API immediately following a Entity Create etc, you may wish to request a refresh to
    #  ensure the index immediately current before making a query request to the search index.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def refresh_entity_search_index
      start.uri('/api/entity/search')
          .put
          .go
    end

    #
    # Request a refresh of the User search index. This API is not generally necessary and the search index will become consistent in a
    # reasonable amount of time. There may be scenarios where you may wish to manually request an index refresh. One example may be 
    # if you are using the Search API or Delete Tenant API immediately following a User Create etc, you may wish to request a refresh to
    #  ensure the index immediately current before making a query request to the search index.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def refresh_user_search_index
      start.uri('/api/user/search')
          .put
          .go
    end

    #
    # Regenerates any keys that are used by the FusionAuth Reactor.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def regenerate_reactor_keys
      start.uri('/api/reactor')
          .put
          .go
    end

    #
    # Registers a user for an application. If you provide the User and the UserRegistration object on this request, it
    # will create the user as well as register them for the application. This is called a Full Registration. However, if
    # you only provide the UserRegistration object, then the user must already exist and they will be registered for the
    # application. The user Id can also be provided and it will either be used to look up an existing user or it will be
    # used for the newly created User.
    #
    # @param user_id [string] (Optional) The Id of the user being registered for the application and optionally created.
    # @param request [OpenStruct, Hash] The request that optionally contains the User and must contain the UserRegistration.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def register(user_id, request)
      start.uri('/api/user/registration')
          .url_segment(user_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Requests Elasticsearch to delete and rebuild the index for FusionAuth users or entities. Be very careful when running this request as it will 
    # increase the CPU and I/O load on your database until the operation completes. Generally speaking you do not ever need to run this operation unless 
    # instructed by FusionAuth support, or if you are migrating a database another system and you are not brining along the Elasticsearch index. 
    # 
    # You have been warned.
    #
    # @param request [OpenStruct, Hash] The request that contains the index name.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def reindex(request)
      start.uri('/api/system/reindex')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Removes a user from the family with the given Id.
    #
    # @param family_id [string] The Id of the family to remove the user from.
    # @param user_id [string] The Id of the user to remove from the family.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def remove_user_from_family(family_id, user_id)
      start.uri('/api/user/family')
          .url_segment(family_id)
          .url_segment(user_id)
          .delete
          .go
    end

    #
    # Re-sends the verification email to the user.
    #
    # @param email [string] The email address of the user that needs a new verification email.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def resend_email_verification(email)
      start.uri('/api/user/verify-email')
          .url_parameter('email', email)
          .put
          .go
    end

    #
    # Re-sends the verification email to the user. If the Application has configured a specific email template this will be used
    # instead of the tenant configuration.
    #
    # @param application_id [string] The unique Application Id to used to resolve an application specific email template.
    # @param email [string] The email address of the user that needs a new verification email.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def resend_email_verification_with_application_template(application_id, email)
      start.uri('/api/user/verify-email')
          .url_parameter('applicationId', application_id)
          .url_parameter('email', email)
          .put
          .go
    end

    #
    # Re-sends the application registration verification email to the user.
    #
    # @param email [string] The email address of the user that needs a new verification email.
    # @param application_id [string] The Id of the application to be verified.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def resend_registration_verification(email, application_id)
      start.uri('/api/user/verify-registration')
          .url_parameter('email', email)
          .url_parameter('applicationId', application_id)
          .put
          .go
    end

    #
    # Retrieves an authentication API key for the given Id.
    #
    # @param key_id [string] The Id of the API key to retrieve.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_api_key(key_id)
      start.uri('/api/api-key')
          .url_segment(key_id)
          .get
          .go
    end

    #
    # Retrieves a single action log (the log of a user action that was taken on a user previously) for the given Id.
    #
    # @param action_id [string] The Id of the action to retrieve.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_action(action_id)
      start.uri('/api/user/action')
          .url_segment(action_id)
          .get
          .go
    end

    #
    # Retrieves all the actions for the user with the given Id. This will return all time based actions that are active,
    # and inactive as well as non-time based actions.
    #
    # @param user_id [string] The Id of the user to fetch the actions for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_actions(user_id)
      start.uri('/api/user/action')
          .url_parameter('userId', user_id)
          .get
          .go
    end

    #
    # Retrieves all the actions for the user with the given Id that are currently preventing the User from logging in.
    #
    # @param user_id [string] The Id of the user to fetch the actions for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_actions_preventing_login(user_id)
      start.uri('/api/user/action')
          .url_parameter('userId', user_id)
          .url_parameter('preventingLogin', true)
          .get
          .go
    end

    #
    # Retrieves all the actions for the user with the given Id that are currently active.
    # An active action means one that is time based and has not been canceled, and has not ended.
    #
    # @param user_id [string] The Id of the user to fetch the actions for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_active_actions(user_id)
      start.uri('/api/user/action')
          .url_parameter('userId', user_id)
          .url_parameter('active', true)
          .get
          .go
    end

    #
    # Retrieves the application for the given Id or all the applications if the Id is null.
    #
    # @param application_id [string] (Optional) The application Id.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_application(application_id)
      start.uri('/api/application')
          .url_segment(application_id)
          .get
          .go
    end

    #
    # Retrieves all the applications.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_applications
      start.uri('/api/application')
          .get
          .go
    end

    #
    # Retrieves a single audit log for the given Id.
    #
    # @param audit_log_id [Numeric] The Id of the audit log to retrieve.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_audit_log(audit_log_id)
      start.uri('/api/system/audit-log')
          .url_segment(audit_log_id)
          .get
          .go
    end

    #
    # Retrieves the connector with the given Id.
    #
    # @param connector_id [string] The Id of the connector.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_connector(connector_id)
      start.uri('/api/connector')
          .url_segment(connector_id)
          .get
          .go
    end

    #
    # Retrieves all the connectors.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_connectors
      start.uri('/api/connector')
          .get
          .go
    end

    #
    # Retrieves the Consent for the given Id.
    #
    # @param consent_id [string] The Id of the consent.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_consent(consent_id)
      start.uri('/api/consent')
          .url_segment(consent_id)
          .get
          .go
    end

    #
    # Retrieves all the consent.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_consents
      start.uri('/api/consent')
          .get
          .go
    end

    #
    # Retrieves the daily active user report between the two instants. If you specify an application Id, it will only
    # return the daily active counts for that application.
    #
    # @param application_id [string] (Optional) The application Id.
    # @param start [OpenStruct, Hash] The start instant as UTC milliseconds since Epoch.
    # @param _end [OpenStruct, Hash] The end instant as UTC milliseconds since Epoch.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_daily_active_report(application_id, start, _end)
      start.uri('/api/report/daily-active-user')
          .url_parameter('applicationId', application_id)
          .url_parameter('start', start)
          .url_parameter('end', _end)
          .get
          .go
    end

    #
    # Retrieves the email template for the given Id. If you don't specify the Id, this will return all the email templates.
    #
    # @param email_template_id [string] (Optional) The Id of the email template.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_email_template(email_template_id)
      start.uri('/api/email/template')
          .url_segment(email_template_id)
          .get
          .go
    end

    #
    # Creates a preview of the email template provided in the request. This allows you to preview an email template that
    # hasn't been saved to the database yet. The entire email template does not need to be provided on the request. This
    # will create the preview based on whatever is given.
    #
    # @param request [OpenStruct, Hash] The request that contains the email template and optionally a locale to render it in.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_email_template_preview(request)
      start.uri('/api/email/template/preview')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Retrieves all the email templates.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_email_templates
      start.uri('/api/email/template')
          .get
          .go
    end

    #
    # Retrieves the Entity for the given Id.
    #
    # @param entity_id [string] The Id of the Entity.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_entity(entity_id)
      start.uri('/api/entity')
          .url_segment(entity_id)
          .get
          .go
    end

    #
    # Retrieves an Entity Grant for the given Entity and User/Entity.
    #
    # @param entity_id [string] The Id of the Entity.
    # @param recipient_entity_id [string] (Optional) The Id of the Entity that the Entity Grant is for.
    # @param user_id [string] (Optional) The Id of the User that the Entity Grant is for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_entity_grant(entity_id, recipient_entity_id, user_id)
      start.uri('/api/entity')
          .url_segment(entity_id)
          .url_segment("grant")
          .url_parameter('recipientEntityId', recipient_entity_id)
          .url_parameter('userId', user_id)
          .get
          .go
    end

    #
    # Retrieves the Entity Type for the given Id.
    #
    # @param entity_type_id [string] The Id of the Entity Type.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_entity_type(entity_type_id)
      start.uri('/api/entity/type')
          .url_segment(entity_type_id)
          .get
          .go
    end

    #
    # Retrieves all the Entity Types.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_entity_types
      start.uri('/api/entity/type')
          .get
          .go
    end

    #
    # Retrieves a single event log for the given Id.
    #
    # @param event_log_id [Numeric] The Id of the event log to retrieve.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_event_log(event_log_id)
      start.uri('/api/system/event-log')
          .url_segment(event_log_id)
          .get
          .go
    end

    #
    # Retrieves all the families that a user belongs to.
    #
    # @param user_id [string] The User's id
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_families(user_id)
      start.uri('/api/user/family')
          .url_parameter('userId', user_id)
          .get
          .go
    end

    #
    # Retrieves all the members of a family by the unique Family Id.
    #
    # @param family_id [string] The unique Id of the Family.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_family_members_by_family_id(family_id)
      start.uri('/api/user/family')
          .url_segment(family_id)
          .get
          .go
    end

    #
    # Retrieves the form with the given Id.
    #
    # @param form_id [string] The Id of the form.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_form(form_id)
      start.uri('/api/form')
          .url_segment(form_id)
          .get
          .go
    end

    #
    # Retrieves the form field with the given Id.
    #
    # @param field_id [string] The Id of the form field.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_form_field(field_id)
      start.uri('/api/form/field')
          .url_segment(field_id)
          .get
          .go
    end

    #
    # Retrieves all the forms fields
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_form_fields
      start.uri('/api/form/field')
          .get
          .go
    end

    #
    # Retrieves all the forms.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_forms
      start.uri('/api/form')
          .get
          .go
    end

    #
    # Retrieves the group for the given Id.
    #
    # @param group_id [string] The Id of the group.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_group(group_id)
      start.uri('/api/group')
          .url_segment(group_id)
          .get
          .go
    end

    #
    # Retrieves all the groups.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_groups
      start.uri('/api/group')
          .get
          .go
    end

    #
    # Retrieves the IP Access Control List with the given Id.
    #
    # @param ip_access_control_list_id [string] The Id of the IP Access Control List.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_ip_access_control_list(ip_access_control_list_id)
      start.uri('/api/ip-acl')
          .url_segment(ip_access_control_list_id)
          .get
          .go
    end

    #
    # Retrieves the identity provider for the given Id or all the identity providers if the Id is null.
    #
    # @param identity_provider_id [string] The identity provider Id.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_identity_provider(identity_provider_id)
      start.uri('/api/identity-provider')
          .url_segment(identity_provider_id)
          .get
          .go
    end

    #
    # Retrieves one or more identity provider for the given type. For types such as Google, Facebook, Twitter and LinkedIn, only a single 
    # identity provider can exist. For types such as OpenID Connect and SAMLv2 more than one identity provider can be configured so this request 
    # may return multiple identity providers.
    #
    # @param type [string] The type of the identity provider.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_identity_provider_by_type(type)
      start.uri('/api/identity-provider')
          .url_parameter('type', type)
          .get
          .go
    end

    #
    # Retrieves all the identity providers.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_identity_providers
      start.uri('/api/identity-provider')
          .get
          .go
    end

    #
    # Retrieves all the actions for the user with the given Id that are currently inactive.
    # An inactive action means one that is time based and has been canceled or has expired, or is not time based.
    #
    # @param user_id [string] The Id of the user to fetch the actions for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_inactive_actions(user_id)
      start.uri('/api/user/action')
          .url_parameter('userId', user_id)
          .url_parameter('active', false)
          .get
          .go
    end

    #
    # Retrieves all the applications that are currently inactive.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_inactive_applications
      start.uri('/api/application')
          .url_parameter('inactive', true)
          .get
          .go
    end

    #
    # Retrieves all the user actions that are currently inactive.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_inactive_user_actions
      start.uri('/api/user-action')
          .url_parameter('inactive', true)
          .get
          .go
    end

    #
    # Retrieves the available integrations.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_integration
      start.uri('/api/integration')
          .get
          .go
    end

    #
    # Retrieves the Public Key configured for verifying JSON Web Tokens (JWT) by the key Id (kid).
    #
    # @param key_id [string] The Id of the public key (kid).
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_jwt_public_key(key_id)
      startAnonymous.uri('/api/jwt/public-key')
          .url_parameter('kid', key_id)
          .get
          .go
    end

    #
    # Retrieves the Public Key configured for verifying the JSON Web Tokens (JWT) issued by the Login API by the Application Id.
    #
    # @param application_id [string] The Id of the Application for which this key is used.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_jwt_public_key_by_application_id(application_id)
      startAnonymous.uri('/api/jwt/public-key')
          .url_parameter('applicationId', application_id)
          .get
          .go
    end

    #
    # Retrieves all Public Keys configured for verifying JSON Web Tokens (JWT).
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_jwt_public_keys
      startAnonymous.uri('/api/jwt/public-key')
          .get
          .go
    end

    #
    # Returns public keys used by FusionAuth to cryptographically verify JWTs using the JSON Web Key format.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_json_web_key_set
      startAnonymous.uri('/.well-known/jwks.json')
          .get
          .go
    end

    #
    # Retrieves the key for the given Id.
    #
    # @param key_id [string] The Id of the key.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_key(key_id)
      start.uri('/api/key')
          .url_segment(key_id)
          .get
          .go
    end

    #
    # Retrieves all the keys.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_keys
      start.uri('/api/key')
          .get
          .go
    end

    #
    # Retrieves the lambda for the given Id.
    #
    # @param lambda_id [string] The Id of the lambda.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_lambda(lambda_id)
      start.uri('/api/lambda')
          .url_segment(lambda_id)
          .get
          .go
    end

    #
    # Retrieves all the lambdas.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_lambdas
      start.uri('/api/lambda')
          .get
          .go
    end

    #
    # Retrieves all the lambdas for the provided type.
    #
    # @param type [string] The type of the lambda to return.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_lambdas_by_type(type)
      start.uri('/api/lambda')
          .url_parameter('type', type)
          .get
          .go
    end

    #
    # Retrieves the login report between the two instants. If you specify an application Id, it will only return the
    # login counts for that application.
    #
    # @param application_id [string] (Optional) The application Id.
    # @param start [OpenStruct, Hash] The start instant as UTC milliseconds since Epoch.
    # @param _end [OpenStruct, Hash] The end instant as UTC milliseconds since Epoch.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_login_report(application_id, start, _end)
      start.uri('/api/report/login')
          .url_parameter('applicationId', application_id)
          .url_parameter('start', start)
          .url_parameter('end', _end)
          .get
          .go
    end

    #
    # Retrieves the message template for the given Id. If you don't specify the Id, this will return all the message templates.
    #
    # @param message_template_id [string] (Optional) The Id of the message template.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_message_template(message_template_id)
      start.uri('/api/message/template')
          .url_segment(message_template_id)
          .get
          .go
    end

    #
    # Creates a preview of the message template provided in the request, normalized to a given locale.
    #
    # @param request [OpenStruct, Hash] The request that contains the email template and optionally a locale to render it in.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_message_template_preview(request)
      start.uri('/api/message/template/preview')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Retrieves all the message templates.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_message_templates
      start.uri('/api/message/template')
          .get
          .go
    end

    #
    # Retrieves the messenger with the given Id.
    #
    # @param messenger_id [string] The Id of the messenger.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_messenger(messenger_id)
      start.uri('/api/messenger')
          .url_segment(messenger_id)
          .get
          .go
    end

    #
    # Retrieves all the messengers.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_messengers
      start.uri('/api/messenger')
          .get
          .go
    end

    #
    # Retrieves the monthly active user report between the two instants. If you specify an application Id, it will only
    # return the monthly active counts for that application.
    #
    # @param application_id [string] (Optional) The application Id.
    # @param start [OpenStruct, Hash] The start instant as UTC milliseconds since Epoch.
    # @param _end [OpenStruct, Hash] The end instant as UTC milliseconds since Epoch.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_monthly_active_report(application_id, start, _end)
      start.uri('/api/report/monthly-active-user')
          .url_parameter('applicationId', application_id)
          .url_parameter('start', start)
          .url_parameter('end', _end)
          .get
          .go
    end

    #
    # Retrieves a custom OAuth scope.
    #
    # @param application_id [string] The Id of the application that the OAuth scope belongs to.
    # @param scope_id [string] The Id of the OAuth scope to retrieve.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_o_auth_scope(application_id, scope_id)
      start.uri('/api/application')
          .url_segment(application_id)
          .url_segment("scope")
          .url_segment(scope_id)
          .get
          .go
    end

    #
    # Retrieves the Oauth2 configuration for the application for the given Application Id.
    #
    # @param application_id [string] The Id of the Application to retrieve OAuth configuration.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_oauth_configuration(application_id)
      start.uri('/api/application')
          .url_segment(application_id)
          .url_segment("oauth-configuration")
          .get
          .go
    end

    #
    # Returns the well known OpenID Configuration JSON document
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_open_id_configuration
      startAnonymous.uri('/.well-known/openid-configuration')
          .get
          .go
    end

    #
    # Retrieves the password validation rules for a specific tenant. This method requires a tenantId to be provided 
    # through the use of a Tenant scoped API key or an HTTP header X-FusionAuth-TenantId to specify the Tenant Id.
    # 
    # This API does not require an API key.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_password_validation_rules
      startAnonymous.uri('/api/tenant/password-validation-rules')
          .get
          .go
    end

    #
    # Retrieves the password validation rules for a specific tenant.
    # 
    # This API does not require an API key.
    #
    # @param tenant_id [string] The Id of the tenant.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_password_validation_rules_with_tenant_id(tenant_id)
      startAnonymous.uri('/api/tenant/password-validation-rules')
          .url_segment(tenant_id)
          .get
          .go
    end

    #
    # Retrieves all the children for the given parent email address.
    #
    # @param parent_email [string] The email of the parent.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_pending_children(parent_email)
      start.uri('/api/user/family/pending')
          .url_parameter('parentEmail', parent_email)
          .get
          .go
    end

    #
    # Retrieve a pending identity provider link. This is useful to validate a pending link and retrieve meta-data about the identity provider link.
    #
    # @param p_ending_link_id [string] The pending link Id.
    # @param user_id [string] The optional userId. When provided additional meta-data will be provided to identify how many links if any the user already has.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_pending_link(pending_link_id, user_id)
      start.uri('/api/identity-provider/link/pending')
          .url_segment(pending_link_id)
          .url_parameter('userId', user_id)
          .get
          .go
    end

    #
    # Retrieves the FusionAuth Reactor metrics.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_reactor_metrics
      start.uri('/api/reactor/metrics')
          .get
          .go
    end

    #
    # Retrieves the FusionAuth Reactor status.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_reactor_status
      start.uri('/api/reactor')
          .get
          .go
    end

    #
    # Retrieves the last number of login records.
    #
    # @param offset [Numeric] The initial record. e.g. 0 is the last login, 100 will be the 100th most recent login.
    # @param limit [Numeric] (Optional, defaults to 10) The number of records to retrieve.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_recent_logins(offset, limit)
      start.uri('/api/user/recent-login')
          .url_parameter('offset', offset)
          .url_parameter('limit', limit)
          .get
          .go
    end

    #
    # Retrieves a single refresh token by unique Id. This is not the same thing as the string value of the refresh token. If you have that, you already have what you need.
    #
    # @param token_id [string] The Id of the token.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_refresh_token_by_id(token_id)
      start.uri('/api/jwt/refresh')
          .url_segment(token_id)
          .get
          .go
    end

    #
    # Retrieves the refresh tokens that belong to the user with the given Id.
    #
    # @param user_id [string] The Id of the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_refresh_tokens(user_id)
      start.uri('/api/jwt/refresh')
          .url_parameter('userId', user_id)
          .get
          .go
    end

    #
    # Retrieves the user registration for the user with the given Id and the given application Id.
    #
    # @param user_id [string] The Id of the user.
    # @param application_id [string] The Id of the application.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_registration(user_id, application_id)
      start.uri('/api/user/registration')
          .url_segment(user_id)
          .url_segment(application_id)
          .get
          .go
    end

    #
    # Retrieves the registration report between the two instants. If you specify an application Id, it will only return
    # the registration counts for that application.
    #
    # @param application_id [string] (Optional) The application Id.
    # @param start [OpenStruct, Hash] The start instant as UTC milliseconds since Epoch.
    # @param _end [OpenStruct, Hash] The end instant as UTC milliseconds since Epoch.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_registration_report(application_id, start, _end)
      start.uri('/api/report/registration')
          .url_parameter('applicationId', application_id)
          .url_parameter('start', start)
          .url_parameter('end', _end)
          .get
          .go
    end

    #
    # Retrieve the status of a re-index process. A status code of 200 indicates the re-index is in progress, a status code of  
    # 404 indicates no re-index is in progress.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_reindex_status
      start.uri('/api/system/reindex')
          .get
          .go
    end

    #
    # Retrieves the system configuration.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_system_configuration
      start.uri('/api/system-configuration')
          .get
          .go
    end

    #
    # Retrieves the FusionAuth system health. This API will return 200 if the system is healthy, and 500 if the system is un-healthy.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_system_health
      startAnonymous.uri('/api/health')
          .get
          .go
    end

    #
    # Retrieves the FusionAuth system status. This request is anonymous and does not require an API key. When an API key is not provided the response will contain a single value in the JSON response indicating the current health check.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_system_status
      startAnonymous.uri('/api/status')
          .get
          .go
    end

    #
    # Retrieves the FusionAuth system status using an API key. Using an API key will cause the response to include the product version, health checks and various runtime metrics.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_system_status_using_api_key
      start.uri('/api/status')
          .get
          .go
    end

    #
    # Retrieves the tenant for the given Id.
    #
    # @param tenant_id [string] The Id of the tenant.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_tenant(tenant_id)
      start.uri('/api/tenant')
          .url_segment(tenant_id)
          .get
          .go
    end

    #
    # Retrieves all the tenants.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_tenants
      start.uri('/api/tenant')
          .get
          .go
    end

    #
    # Retrieves the theme for the given Id.
    #
    # @param theme_id [string] The Id of the theme.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_theme(theme_id)
      start.uri('/api/theme')
          .url_segment(theme_id)
          .get
          .go
    end

    #
    # Retrieves all the themes.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_themes
      start.uri('/api/theme')
          .get
          .go
    end

    #
    # Retrieves the totals report. This contains all the total counts for each application and the global registration
    # count.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_total_report
      start.uri('/api/report/totals')
          .get
          .go
    end

    #
    # Retrieve two-factor recovery codes for a user.
    #
    # @param user_id [string] The Id of the user to retrieve Two Factor recovery codes.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_two_factor_recovery_codes(user_id)
      start.uri('/api/user/two-factor/recovery-code')
          .url_segment(user_id)
          .get
          .go
    end

    #
    # Retrieve a user's two-factor status.
    # 
    # This can be used to see if a user will need to complete a two-factor challenge to complete a login,
    # and optionally identify the state of the two-factor trust across various applications.
    #
    # @param user_id [string] The user Id to retrieve the Two-Factor status.
    # @param application_id [string] The optional applicationId to verify.
    # @param two_factor_trust_id [string] The optional two-factor trust Id to verify.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_two_factor_status(user_id, application_id, two_factor_trust_id)
      start.uri('/api/two-factor/status')
          .url_parameter('userId', user_id)
          .url_parameter('applicationId', application_id)
          .url_segment(two_factor_trust_id)
          .get
          .go
    end

    #
    # Retrieves the user for the given Id.
    #
    # @param user_id [string] The Id of the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user(user_id)
      start.uri('/api/user')
          .url_segment(user_id)
          .get
          .go
    end

    #
    # Retrieves the user action for the given Id. If you pass in null for the Id, this will return all the user
    # actions.
    #
    # @param user_action_id [string] (Optional) The Id of the user action.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_action(user_action_id)
      start.uri('/api/user-action')
          .url_segment(user_action_id)
          .get
          .go
    end

    #
    # Retrieves the user action reason for the given Id. If you pass in null for the Id, this will return all the user
    # action reasons.
    #
    # @param user_action_reason_id [string] (Optional) The Id of the user action reason.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_action_reason(user_action_reason_id)
      start.uri('/api/user-action-reason')
          .url_segment(user_action_reason_id)
          .get
          .go
    end

    #
    # Retrieves all the user action reasons.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_action_reasons
      start.uri('/api/user-action-reason')
          .get
          .go
    end

    #
    # Retrieves all the user actions.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_actions
      start.uri('/api/user-action')
          .get
          .go
    end

    #
    # Retrieves the user by a change password Id. The intended use of this API is to retrieve a user after the forgot
    # password workflow has been initiated and you may not know the user's email or username.
    #
    # @param change_password_id [string] The unique change password Id that was sent via email or returned by the Forgot Password API.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_by_change_password_id(change_password_id)
      start.uri('/api/user')
          .url_parameter('changePasswordId', change_password_id)
          .get
          .go
    end

    #
    # Retrieves the user for the given email.
    #
    # @param email [string] The email of the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_by_email(email)
      start.uri('/api/user')
          .url_parameter('email', email)
          .get
          .go
    end

    #
    # Retrieves the user for the loginId. The loginId can be either the username or the email.
    #
    # @param login_id [string] The email or username of the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_by_login_id(login_id)
      start.uri('/api/user')
          .url_parameter('loginId', login_id)
          .get
          .go
    end

    #
    # Retrieves the user for the given username.
    #
    # @param username [string] The username of the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_by_username(username)
      start.uri('/api/user')
          .url_parameter('username', username)
          .get
          .go
    end

    #
    # Retrieves the user by a verificationId. The intended use of this API is to retrieve a user after the forgot
    # password workflow has been initiated and you may not know the user's email or username.
    #
    # @param verification_id [string] The unique verification Id that has been set on the user object.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_by_verification_id(verification_id)
      start.uri('/api/user')
          .url_parameter('verificationId', verification_id)
          .get
          .go
    end

    #
    # Retrieve a user_code that is part of an in-progress Device Authorization Grant.
    # 
    # This API is useful if you want to build your own login workflow to complete a device grant.
    #
    # @param client_id [string] The client Id.
    # @param client_secret [string] The client Id.
    # @param user_code [string] The end-user verification code.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_code(client_id, client_secret, user_code)
      body = {
        "client_id" => client_id,
        "client_secret" => client_secret,
        "user_code" => user_code
      }
      startAnonymous.uri('/oauth2/device/user-code')
          .body_handler(FusionAuth::FormDataBodyHandler.new(body))
          .get
          .go
    end

    #
    # Retrieve a user_code that is part of an in-progress Device Authorization Grant.
    # 
    # This API is useful if you want to build your own login workflow to complete a device grant.
    # 
    # This request will require an API key.
    #
    # @param user_code [string] The end-user verification code.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_code_using_api_key(user_code)
      body = {
        "user_code" => user_code
      }
      startAnonymous.uri('/oauth2/device/user-code')
          .body_handler(FusionAuth::FormDataBodyHandler.new(body))
          .get
          .go
    end

    #
    # Retrieves all the comments for the user with the given Id.
    #
    # @param user_id [string] The Id of the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_comments(user_id)
      start.uri('/api/user/comment')
          .url_segment(user_id)
          .get
          .go
    end

    #
    # Retrieve a single User consent by Id.
    #
    # @param user_consent_id [string] The User consent Id
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_consent(user_consent_id)
      start.uri('/api/user/consent')
          .url_segment(user_consent_id)
          .get
          .go
    end

    #
    # Retrieves all the consents for a User.
    #
    # @param user_id [string] The User's Id
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_consents(user_id)
      start.uri('/api/user/consent')
          .url_parameter('userId', user_id)
          .get
          .go
    end

    #
    # Call the UserInfo endpoint to retrieve User Claims from the access token issued by FusionAuth.
    #
    # @param encoded_jwt [string] The encoded JWT (access token).
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_info_from_access_token(encoded_jwt)
      startAnonymous.uri('/oauth2/userinfo')
          .authorization('Bearer ' + encoded_jwt)
          .get
          .go
    end

    #
    # Retrieve a single Identity Provider user (link).
    #
    # @param identity_provider_id [string] The unique Id of the identity provider.
    # @param identity_provider_user_id [string] The unique Id of the user in the 3rd party identity provider.
    # @param user_id [string] The unique Id of the FusionAuth user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_link(identity_provider_id, identity_provider_user_id, user_id)
      start.uri('/api/identity-provider/link')
          .url_parameter('identityProviderId', identity_provider_id)
          .url_parameter('identityProviderUserId', identity_provider_user_id)
          .url_parameter('userId', user_id)
          .get
          .go
    end

    #
    # Retrieve all Identity Provider users (links) for the user. Specify the optional identityProviderId to retrieve links for a particular IdP.
    #
    # @param identity_provider_id [string] (Optional) The unique Id of the identity provider. Specify this value to reduce the links returned to those for a particular IdP.
    # @param user_id [string] The unique Id of the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_links_by_user_id(identity_provider_id, user_id)
      start.uri('/api/identity-provider/link')
          .url_parameter('identityProviderId', identity_provider_id)
          .url_parameter('userId', user_id)
          .get
          .go
    end

    #
    # Retrieves the login report between the two instants for a particular user by Id. If you specify an application Id, it will only return the
    # login counts for that application.
    #
    # @param application_id [string] (Optional) The application Id.
    # @param user_id [string] The userId Id.
    # @param start [OpenStruct, Hash] The start instant as UTC milliseconds since Epoch.
    # @param _end [OpenStruct, Hash] The end instant as UTC milliseconds since Epoch.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_login_report(application_id, user_id, start, _end)
      start.uri('/api/report/login')
          .url_parameter('applicationId', application_id)
          .url_parameter('userId', user_id)
          .url_parameter('start', start)
          .url_parameter('end', _end)
          .get
          .go
    end

    #
    # Retrieves the login report between the two instants for a particular user by login Id. If you specify an application Id, it will only return the
    # login counts for that application.
    #
    # @param application_id [string] (Optional) The application Id.
    # @param login_id [string] The userId Id.
    # @param start [OpenStruct, Hash] The start instant as UTC milliseconds since Epoch.
    # @param _end [OpenStruct, Hash] The end instant as UTC milliseconds since Epoch.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_login_report_by_login_id(application_id, login_id, start, _end)
      start.uri('/api/report/login')
          .url_parameter('applicationId', application_id)
          .url_parameter('loginId', login_id)
          .url_parameter('start', start)
          .url_parameter('end', _end)
          .get
          .go
    end

    #
    # Retrieves the last number of login records for a user.
    #
    # @param user_id [string] The Id of the user.
    # @param offset [Numeric] The initial record. e.g. 0 is the last login, 100 will be the 100th most recent login.
    # @param limit [Numeric] (Optional, defaults to 10) The number of records to retrieve.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_recent_logins(user_id, offset, limit)
      start.uri('/api/user/recent-login')
          .url_parameter('userId', user_id)
          .url_parameter('offset', offset)
          .url_parameter('limit', limit)
          .get
          .go
    end

    #
    # Retrieves the user for the given Id. This method does not use an API key, instead it uses a JSON Web Token (JWT) for authentication.
    #
    # @param encoded_jwt [string] The encoded JWT (access token).
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_user_using_jwt(encoded_jwt)
      startAnonymous.uri('/api/user')
          .authorization('Bearer ' + encoded_jwt)
          .get
          .go
    end

    #
    # Retrieves the FusionAuth version string.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_version
      start.uri('/api/system/version')
          .get
          .go
    end

    #
    # Retrieves the WebAuthn credential for the given Id.
    #
    # @param id [string] The Id of the WebAuthn credential.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_web_authn_credential(id)
      start.uri('/api/webauthn')
          .url_segment(id)
          .get
          .go
    end

    #
    # Retrieves all WebAuthn credentials for the given user.
    #
    # @param user_id [string] The user's ID.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_web_authn_credentials_for_user(user_id)
      start.uri('/api/webauthn')
          .url_parameter('userId', user_id)
          .get
          .go
    end

    #
    # Retrieves the webhook for the given Id. If you pass in null for the Id, this will return all the webhooks.
    #
    # @param webhook_id [string] (Optional) The Id of the webhook.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_webhook(webhook_id)
      start.uri('/api/webhook')
          .url_segment(webhook_id)
          .get
          .go
    end

    #
    # Retrieves a single webhook attempt log for the given Id.
    #
    # @param webhook_attempt_log_id [string] The Id of the webhook attempt log to retrieve.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_webhook_attempt_log(webhook_attempt_log_id)
      start.uri('/api/system/webhook-attempt-log')
          .url_segment(webhook_attempt_log_id)
          .get
          .go
    end

    #
    # Retrieves a single webhook event log for the given Id.
    #
    # @param webhook_event_log_id [string] The Id of the webhook event log to retrieve.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_webhook_event_log(webhook_event_log_id)
      start.uri('/api/system/webhook-event-log')
          .url_segment(webhook_event_log_id)
          .get
          .go
    end

    #
    # Retrieves all the webhooks.
    #
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def retrieve_webhooks
      start.uri('/api/webhook')
          .get
          .go
    end

    #
    # Revokes refresh tokens.
    # 
    # Usage examples:
    #   - Delete a single refresh token, pass in only the token.
    #       revokeRefreshToken(token)
    # 
    #   - Delete all refresh tokens for a user, pass in only the userId.
    #       revokeRefreshToken(null, userId)
    # 
    #   - Delete all refresh tokens for a user for a specific application, pass in both the userId and the applicationId.
    #       revokeRefreshToken(null, userId, applicationId)
    # 
    #   - Delete all refresh tokens for an application
    #       revokeRefreshToken(null, null, applicationId)
    # 
    # Note: <code>null</code> may be handled differently depending upon the programming language.
    # 
    # See also: (method names may vary by language... but you'll figure it out)
    # 
    #  - revokeRefreshTokenById
    #  - revokeRefreshTokenByToken
    #  - revokeRefreshTokensByUserId
    #  - revokeRefreshTokensByApplicationId
    #  - revokeRefreshTokensByUserIdForApplication
    #
    # @param token [string] (Optional) The refresh token to delete.
    # @param user_id [string] (Optional) The user Id whose tokens to delete.
    # @param application_id [string] (Optional) The application Id of the tokens to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def revoke_refresh_token(token, user_id, application_id)
      start.uri('/api/jwt/refresh')
          .url_parameter('token', token)
          .url_parameter('userId', user_id)
          .url_parameter('applicationId', application_id)
          .delete
          .go
    end

    #
    # Revokes a single refresh token by the unique Id. The unique Id is not sensitive as it cannot be used to obtain another JWT.
    #
    # @param token_id [string] The unique Id of the token to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def revoke_refresh_token_by_id(token_id)
      start.uri('/api/jwt/refresh')
          .url_segment(token_id)
          .delete
          .go
    end

    #
    # Revokes a single refresh token by using the actual refresh token value. This refresh token value is sensitive, so  be careful with this API request.
    #
    # @param token [string] The refresh token to delete.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def revoke_refresh_token_by_token(token)
      start.uri('/api/jwt/refresh')
          .url_parameter('token', token)
          .delete
          .go
    end

    #
    # Revoke all refresh tokens that belong to an application by applicationId.
    #
    # @param application_id [string] The unique Id of the application that you want to delete all refresh tokens for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def revoke_refresh_tokens_by_application_id(application_id)
      start.uri('/api/jwt/refresh')
          .url_parameter('applicationId', application_id)
          .delete
          .go
    end

    #
    # Revoke all refresh tokens that belong to a user by user Id.
    #
    # @param user_id [string] The unique Id of the user that you want to delete all refresh tokens for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def revoke_refresh_tokens_by_user_id(user_id)
      start.uri('/api/jwt/refresh')
          .url_parameter('userId', user_id)
          .delete
          .go
    end

    #
    # Revoke all refresh tokens that belong to a user by user Id for a specific application by applicationId.
    #
    # @param user_id [string] The unique Id of the user that you want to delete all refresh tokens for.
    # @param application_id [string] The unique Id of the application that you want to delete refresh tokens for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def revoke_refresh_tokens_by_user_id_for_application(user_id, application_id)
      start.uri('/api/jwt/refresh')
          .url_parameter('userId', user_id)
          .url_parameter('applicationId', application_id)
          .delete
          .go
    end

    #
    # Revokes refresh tokens using the information in the JSON body. The handling for this method is the same as the revokeRefreshToken method
    # and is based on the information you provide in the RefreshDeleteRequest object. See that method for additional information.
    #
    # @param request [OpenStruct, Hash] The request information used to revoke the refresh tokens.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def revoke_refresh_tokens_with_request(request)
      start.uri('/api/jwt/refresh')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .delete
          .go
    end

    #
    # Revokes a single User consent by Id.
    #
    # @param user_consent_id [string] The User Consent Id
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def revoke_user_consent(user_consent_id)
      start.uri('/api/user/consent')
          .url_segment(user_consent_id)
          .delete
          .go
    end

    #
    # Searches applications with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_applications(request)
      start.uri('/api/application/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches the audit logs with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_audit_logs(request)
      start.uri('/api/system/audit-log/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches consents with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_consents(request)
      start.uri('/api/consent/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches email templates with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_email_templates(request)
      start.uri('/api/email/template/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches entities with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_entities(request)
      start.uri('/api/entity/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Retrieves the entities for the given Ids. If any Id is invalid, it is ignored.
    #
    # @param ids [Array] The entity ids to search for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_entities_by_ids(ids)
      start.uri('/api/entity/search')
          .url_parameter('ids', ids)
          .get
          .go
    end

    #
    # Searches Entity Grants with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_entity_grants(request)
      start.uri('/api/entity/grant/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches the entity types with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_entity_types(request)
      start.uri('/api/entity/type/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches the event logs with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_event_logs(request)
      start.uri('/api/system/event-log/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches group members with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_group_members(request)
      start.uri('/api/group/member/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches groups with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_groups(request)
      start.uri('/api/group/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches the IP Access Control Lists with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_ip_access_control_lists(request)
      start.uri('/api/ip-acl/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches identity providers with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_identity_providers(request)
      start.uri('/api/identity-provider/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches keys with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_keys(request)
      start.uri('/api/key/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches lambdas with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_lambdas(request)
      start.uri('/api/lambda/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches the login records with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_login_records(request)
      start.uri('/api/system/login-record/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches tenants with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_tenants(request)
      start.uri('/api/tenant/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches themes with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_themes(request)
      start.uri('/api/theme/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches user comments with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_user_comments(request)
      start.uri('/api/user/comment/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Retrieves the users for the given Ids. If any Id is invalid, it is ignored.
    #
    # @param ids [Array] The user ids to search for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    # @deprecated This method has been renamed to search_users_by_ids, use that method instead.
    def search_users(ids)
      start.uri('/api/user/search')
          .url_parameter('ids', ids)
          .get
          .go
    end

    #
    # Retrieves the users for the given Ids. If any Id is invalid, it is ignored.
    #
    # @param ids [Array] The user Ids to search for.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_users_by_ids(ids)
      start.uri('/api/user/search')
          .url_parameter('ids', ids)
          .get
          .go
    end

    #
    # Retrieves the users for the given search criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination constraints. Fields used: ids, query, queryString, numberOfResults, orderBy, startRow,
    #     and sortFields.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_users_by_query(request)
      start.uri('/api/user/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Retrieves the users for the given search criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination constraints. Fields used: ids, query, queryString, numberOfResults, orderBy, startRow,
    #     and sortFields.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    # @deprecated This method has been renamed to search_users_by_query, use that method instead.
    def search_users_by_query_string(request)
      start.uri('/api/user/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches the webhook event logs with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_webhook_event_logs(request)
      start.uri('/api/system/webhook-event-log/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Searches webhooks with the specified criteria and pagination.
    #
    # @param request [OpenStruct, Hash] The search criteria and pagination information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def search_webhooks(request)
      start.uri('/api/webhook/search')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Send an email using an email template Id. You can optionally provide <code>requestData</code> to access key value
    # pairs in the email template.
    #
    # @param email_template_id [string] The Id for the template.
    # @param request [OpenStruct, Hash] The send email request that contains all the information used to send the email.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def send_email(email_template_id, request)
      start.uri('/api/email/send')
          .url_segment(email_template_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Sends out an email to a parent that they need to register and create a family or need to log in and add a child to their existing family.
    #
    # @param request [OpenStruct, Hash] The request object that contains the parent email.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def send_family_request_email(request)
      start.uri('/api/user/family/request')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Send a passwordless authentication code in an email to complete login.
    #
    # @param request [OpenStruct, Hash] The passwordless send request that contains all the information used to send an email containing a code.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def send_passwordless_code(request)
      startAnonymous.uri('/api/passwordless/send')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Send a Two Factor authentication code to assist in setting up Two Factor authentication or disabling.
    #
    # @param request [OpenStruct, Hash] The request object that contains all the information used to send the code.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    # @deprecated This method has been renamed to send_two_factor_code_for_enable_disable, use that method instead.
    def send_two_factor_code(request)
      start.uri('/api/two-factor/send')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Send a Two Factor authentication code to assist in setting up Two Factor authentication or disabling.
    #
    # @param request [OpenStruct, Hash] The request object that contains all the information used to send the code.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def send_two_factor_code_for_enable_disable(request)
      start.uri('/api/two-factor/send')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Send a Two Factor authentication code to allow the completion of Two Factor authentication.
    #
    # @param two_factor_id [string] The Id returned by the Login API necessary to complete Two Factor authentication.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    # @deprecated This method has been renamed to send_two_factor_code_for_login_using_method, use that method instead.
    def send_two_factor_code_for_login(two_factor_id)
      startAnonymous.uri('/api/two-factor/send')
          .url_segment(two_factor_id)
          .post
          .go
    end

    #
    # Send a Two Factor authentication code to allow the completion of Two Factor authentication.
    #
    # @param two_factor_id [string] The Id returned by the Login API necessary to complete Two Factor authentication.
    # @param request [OpenStruct, Hash] The Two Factor send request that contains all the information used to send the Two Factor code to the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def send_two_factor_code_for_login_using_method(two_factor_id, request)
      startAnonymous.uri('/api/two-factor/send')
          .url_segment(two_factor_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Begins a login request for a 3rd party login that requires user interaction such as HYPR.
    #
    # @param request [OpenStruct, Hash] The third-party login request that contains information from the third-party login
    #     providers that FusionAuth uses to reconcile the user's account.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def start_identity_provider_login(request)
      start.uri('/api/identity-provider/start')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Start a passwordless login request by generating a passwordless code. This code can be sent to the User using the Send
    # Passwordless Code API or using a mechanism outside of FusionAuth. The passwordless login is completed by using the Passwordless Login API with this code.
    #
    # @param request [OpenStruct, Hash] The passwordless start request that contains all the information used to begin the passwordless login request.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def start_passwordless_login(request)
      start.uri('/api/passwordless/start')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Start a Two-Factor login request by generating a two-factor identifier. This code can then be sent to the Two Factor Send 
    # API (/api/two-factor/send)in order to send a one-time use code to a user. You can also use one-time use code returned 
    # to send the code out-of-band. The Two-Factor login is completed by making a request to the Two-Factor Login 
    # API (/api/two-factor/login). with the two-factor identifier and the one-time use code.
    # 
    # This API is intended to allow you to begin a Two-Factor login outside a normal login that originated from the Login API (/api/login).
    #
    # @param request [OpenStruct, Hash] The Two-Factor start request that contains all the information used to begin the Two-Factor login request.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def start_two_factor_login(request)
      start.uri('/api/two-factor/start')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Start a WebAuthn authentication ceremony by generating a new challenge for the user
    #
    # @param request [OpenStruct, Hash] An object containing data necessary for starting the authentication ceremony
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def start_web_authn_login(request)
      start.uri('/api/webauthn/start')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Start a WebAuthn registration ceremony by generating a new challenge for the user
    #
    # @param request [OpenStruct, Hash] An object containing data necessary for starting the registration ceremony
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def start_web_authn_registration(request)
      start.uri('/api/webauthn/register/start')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Complete login using a 2FA challenge
    #
    # @param request [OpenStruct, Hash] The login request that contains the user credentials used to log them in.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def two_factor_login(request)
      startAnonymous.uri('/api/two-factor/login')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Updates an API key with the given Id.
    #
    # @param key_id [string] The Id of the API key to update.
    # @param request [OpenStruct, Hash] The request that contains all the new API key information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_api_key(key_id, request)
      start.uri('/api/api-key')
          .url_segment(key_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the application with the given Id.
    #
    # @param application_id [string] The Id of the application to update.
    # @param request [OpenStruct, Hash] The request that contains all the new application information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_application(application_id, request)
      start.uri('/api/application')
          .url_segment(application_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the application role with the given Id for the application.
    #
    # @param application_id [string] The Id of the application that the role belongs to.
    # @param role_id [string] The Id of the role to update.
    # @param request [OpenStruct, Hash] The request that contains all the new role information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_application_role(application_id, role_id, request)
      start.uri('/api/application')
          .url_segment(application_id)
          .url_segment("role")
          .url_segment(role_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the connector with the given Id.
    #
    # @param connector_id [string] The Id of the connector to update.
    # @param request [OpenStruct, Hash] The request object that contains all the new connector information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_connector(connector_id, request)
      start.uri('/api/connector')
          .url_segment(connector_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the consent with the given Id.
    #
    # @param consent_id [string] The Id of the consent to update.
    # @param request [OpenStruct, Hash] The request that contains all the new consent information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_consent(consent_id, request)
      start.uri('/api/consent')
          .url_segment(consent_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the email template with the given Id.
    #
    # @param email_template_id [string] The Id of the email template to update.
    # @param request [OpenStruct, Hash] The request that contains all the new email template information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_email_template(email_template_id, request)
      start.uri('/api/email/template')
          .url_segment(email_template_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the Entity with the given Id.
    #
    # @param entity_id [string] The Id of the Entity to update.
    # @param request [OpenStruct, Hash] The request that contains all the new Entity information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_entity(entity_id, request)
      start.uri('/api/entity')
          .url_segment(entity_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the Entity Type with the given Id.
    #
    # @param entity_type_id [string] The Id of the Entity Type to update.
    # @param request [OpenStruct, Hash] The request that contains all the new Entity Type information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_entity_type(entity_type_id, request)
      start.uri('/api/entity/type')
          .url_segment(entity_type_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the permission with the given Id for the entity type.
    #
    # @param entity_type_id [string] The Id of the entityType that the permission belongs to.
    # @param permission_id [string] The Id of the permission to update.
    # @param request [OpenStruct, Hash] The request that contains all the new permission information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_entity_type_permission(entity_type_id, permission_id, request)
      start.uri('/api/entity/type')
          .url_segment(entity_type_id)
          .url_segment("permission")
          .url_segment(permission_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates a family with a given Id.
    #
    # @param family_id [string] The Id of the family to update.
    # @param request [OpenStruct, Hash] The request object that contains all the new family information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_family(family_id, request)
      start.uri('/api/user/family')
          .url_segment(family_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the form with the given Id.
    #
    # @param form_id [string] The Id of the form to update.
    # @param request [OpenStruct, Hash] The request object that contains all the new form information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_form(form_id, request)
      start.uri('/api/form')
          .url_segment(form_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the form field with the given Id.
    #
    # @param field_id [string] The Id of the form field to update.
    # @param request [OpenStruct, Hash] The request object that contains all the new form field information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_form_field(field_id, request)
      start.uri('/api/form/field')
          .url_segment(field_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the group with the given Id.
    #
    # @param group_id [string] The Id of the group to update.
    # @param request [OpenStruct, Hash] The request that contains all the new group information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_group(group_id, request)
      start.uri('/api/group')
          .url_segment(group_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Creates a member in a group.
    #
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the group member(s).
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_group_members(request)
      start.uri('/api/group/member')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the IP Access Control List with the given Id.
    #
    # @param access_control_list_id [string] The Id of the IP Access Control List to update.
    # @param request [OpenStruct, Hash] The request that contains all the new IP Access Control List information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_ip_access_control_list(access_control_list_id, request)
      start.uri('/api/ip-acl')
          .url_segment(access_control_list_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the identity provider with the given Id.
    #
    # @param identity_provider_id [string] The Id of the identity provider to update.
    # @param request [OpenStruct, Hash] The request object that contains the updated identity provider.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_identity_provider(identity_provider_id, request)
      start.uri('/api/identity-provider')
          .url_segment(identity_provider_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the available integrations.
    #
    # @param request [OpenStruct, Hash] The request that contains all the new integration information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_integrations(request)
      start.uri('/api/integration')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the key with the given Id.
    #
    # @param key_id [string] The Id of the key to update.
    # @param request [OpenStruct, Hash] The request that contains all the new key information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_key(key_id, request)
      start.uri('/api/key')
          .url_segment(key_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the lambda with the given Id.
    #
    # @param lambda_id [string] The Id of the lambda to update.
    # @param request [OpenStruct, Hash] The request that contains all the new lambda information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_lambda(lambda_id, request)
      start.uri('/api/lambda')
          .url_segment(lambda_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the message template with the given Id.
    #
    # @param message_template_id [string] The Id of the message template to update.
    # @param request [OpenStruct, Hash] The request that contains all the new message template information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_message_template(message_template_id, request)
      start.uri('/api/message/template')
          .url_segment(message_template_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the messenger with the given Id.
    #
    # @param messenger_id [string] The Id of the messenger to update.
    # @param request [OpenStruct, Hash] The request object that contains all the new messenger information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_messenger(messenger_id, request)
      start.uri('/api/messenger')
          .url_segment(messenger_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the OAuth scope with the given Id for the application.
    #
    # @param application_id [string] The Id of the application that the OAuth scope belongs to.
    # @param scope_id [string] The Id of the OAuth scope to update.
    # @param request [OpenStruct, Hash] The request that contains all the new OAuth scope information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_o_auth_scope(application_id, scope_id, request)
      start.uri('/api/application')
          .url_segment(application_id)
          .url_segment("scope")
          .url_segment(scope_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the registration for the user with the given Id and the application defined in the request.
    #
    # @param user_id [string] The Id of the user whose registration is going to be updated.
    # @param request [OpenStruct, Hash] The request that contains all the new registration information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_registration(user_id, request)
      start.uri('/api/user/registration')
          .url_segment(user_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the system configuration.
    #
    # @param request [OpenStruct, Hash] The request that contains all the new system configuration information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_system_configuration(request)
      start.uri('/api/system-configuration')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the tenant with the given Id.
    #
    # @param tenant_id [string] The Id of the tenant to update.
    # @param request [OpenStruct, Hash] The request that contains all the new tenant information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_tenant(tenant_id, request)
      start.uri('/api/tenant')
          .url_segment(tenant_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the theme with the given Id.
    #
    # @param theme_id [string] The Id of the theme to update.
    # @param request [OpenStruct, Hash] The request that contains all the new theme information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_theme(theme_id, request)
      start.uri('/api/theme')
          .url_segment(theme_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the user with the given Id.
    #
    # @param user_id [string] The Id of the user to update.
    # @param request [OpenStruct, Hash] The request that contains all the new user information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_user(user_id, request)
      start.uri('/api/user')
          .url_segment(user_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the user action with the given Id.
    #
    # @param user_action_id [string] The Id of the user action to update.
    # @param request [OpenStruct, Hash] The request that contains all the new user action information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_user_action(user_action_id, request)
      start.uri('/api/user-action')
          .url_segment(user_action_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the user action reason with the given Id.
    #
    # @param user_action_reason_id [string] The Id of the user action reason to update.
    # @param request [OpenStruct, Hash] The request that contains all the new user action reason information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_user_action_reason(user_action_reason_id, request)
      start.uri('/api/user-action-reason')
          .url_segment(user_action_reason_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates a single User consent by Id.
    #
    # @param user_consent_id [string] The User Consent Id
    # @param request [OpenStruct, Hash] The request that contains the user consent information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_user_consent(user_consent_id, request)
      start.uri('/api/user/consent')
          .url_segment(user_consent_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Updates the webhook with the given Id.
    #
    # @param webhook_id [string] The Id of the webhook to update.
    # @param request [OpenStruct, Hash] The request that contains all the new webhook information.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def update_webhook(webhook_id, request)
      start.uri('/api/webhook')
          .url_segment(webhook_id)
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .put
          .go
    end

    #
    # Creates or updates an Entity Grant. This is when a User/Entity is granted permissions to an Entity.
    #
    # @param entity_id [string] The Id of the Entity that the User/Entity is being granted access to.
    # @param request [OpenStruct, Hash] The request object that contains all the information used to create the Entity Grant.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def upsert_entity_grant(entity_id, request)
      start.uri('/api/entity')
          .url_segment(entity_id)
          .url_segment("grant")
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Validates the end-user provided user_code from the user-interaction of the Device Authorization Grant.
    # If you build your own activation form you should validate the user provided code prior to beginning the Authorization grant.
    #
    # @param user_code [string] The end-user verification code.
    # @param client_id [string] The client Id.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def validate_device(user_code, client_id)
      startAnonymous.uri('/oauth2/device/validate')
          .url_parameter('user_code', user_code)
          .url_parameter('client_id', client_id)
          .get
          .go
    end

    #
    # Validates the provided JWT (encoded JWT string) to ensure the token is valid. A valid access token is properly
    # signed and not expired.
    # <p>
    # This API may be used to verify the JWT as well as decode the encoded JWT into human readable identity claims.
    #
    # @param encoded_jwt [string] The encoded JWT (access token).
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def validate_jwt(encoded_jwt)
      startAnonymous.uri('/api/jwt/validate')
          .authorization('Bearer ' + encoded_jwt)
          .get
          .go
    end

    #
    # It's a JWT vending machine!
    # 
    # Issue a new access token (JWT) with the provided claims in the request. This JWT is not scoped to a tenant or user, it is a free form 
    # token that will contain what claims you provide.
    # <p>
    # The iat, exp and jti claims will be added by FusionAuth, all other claims must be provided by the caller.
    # 
    # If a TTL is not provided in the request, the TTL will be retrieved from the default Tenant or the Tenant specified on the request either 
    # by way of the X-FusionAuth-TenantId request header, or a tenant scoped API key.
    #
    # @param request [OpenStruct, Hash] The request that contains all the claims for this JWT.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def vend_jwt(request)
      start.uri('/api/jwt/vend')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Confirms a email verification. The Id given is usually from an email sent to the user.
    #
    # @param verification_id [string] The email verification Id sent to the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    # @deprecated This method has been renamed to verify_email_address and changed to take a JSON request body, use that method instead.
    def verify_email(verification_id)
      startAnonymous.uri('/api/user/verify-email')
          .url_segment(verification_id)
          .post
          .go
    end

    #
    # Confirms a user's email address. 
    # 
    # The request body will contain the verificationId. You may also be required to send a one-time use code based upon your configuration. When 
    # the tenant is configured to gate a user until their email address is verified, this procedures requires two values instead of one. 
    # The verificationId is a high entropy value and the one-time use code is a low entropy value that is easily entered in a user interactive form. The 
    # two values together are able to confirm a user's email address and mark the user's email address as verified.
    #
    # @param request [OpenStruct, Hash] The request that contains the verificationId and optional one-time use code paired with the verificationId.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def verify_email_address(request)
      startAnonymous.uri('/api/user/verify-email')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Administratively verify a user's email address. Use this method to bypass email verification for the user.
    # 
    # The request body will contain the userId to be verified. An API key is required when sending the userId in the request body.
    #
    # @param request [OpenStruct, Hash] The request that contains the userId to verify.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def verify_email_address_by_user_id(request)
      start.uri('/api/user/verify-email')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Confirms an application registration. The Id given is usually from an email sent to the user.
    #
    # @param verification_id [string] The registration verification Id sent to the user.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    # @deprecated This method has been renamed to verify_user_registration and changed to take a JSON request body, use that method instead.
    def verify_registration(verification_id)
      startAnonymous.uri('/api/user/verify-registration')
          .url_segment(verification_id)
          .post
          .go
    end

    #
    # Confirms a user's registration. 
    # 
    # The request body will contain the verificationId. You may also be required to send a one-time use code based upon your configuration. When 
    # the application is configured to gate a user until their registration is verified, this procedures requires two values instead of one. 
    # The verificationId is a high entropy value and the one-time use code is a low entropy value that is easily entered in a user interactive form. The 
    # two values together are able to confirm a user's registration and mark the user's registration as verified.
    #
    # @param request [OpenStruct, Hash] The request that contains the verificationId and optional one-time use code paired with the verificationId.
    # @return [FusionAuth::ClientResponse] The ClientResponse object.
    def verify_user_registration(request)
      startAnonymous.uri('/api/user/verify-registration')
          .body_handler(FusionAuth::JSONBodyHandler.new(request))
          .post
          .go
    end

    #
    # Starts the HTTP call
    #
    # @return [RESTClient] The RESTClient
    #
    private
    def start
      startAnonymous.authorization(@api_key)
    end

    private
    def startAnonymous
      client = RESTClient.new
                        .success_response_handler(FusionAuth::JSONResponseHandler.new(OpenStruct))
                        .error_response_handler(FusionAuth::JSONResponseHandler.new(OpenStruct))
                        .url(@base_url)
                        .connect_timeout(@connect_timeout)
                        .read_timeout(@read_timeout)
      if @tenant_id != nil
        client.header("X-FusionAuth-TenantId", @tenant_id)
      end
      client
    end
  end
end

