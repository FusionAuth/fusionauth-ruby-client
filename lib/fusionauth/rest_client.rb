require 'base64'
require 'json'
require 'net/http'

module FusionAuth
  class RESTClient
    def initialize
      @url = ''.dup
      @parameters = {}
      @proxy = {}
      @headers = {}
      @body_handler = nil
      @certificate = nil
      @connect_timeout = 1000
      @read_timeout = 2000
      @error_response_handler = nil
      @error_type = nil
      @method = nil
      @success_response_handler = nil
    end

    def authorization(authorization)
      @headers['Authorization'] = authorization
      self
    end

    def basic_authorization(username, password)
      if username != nil && password != nil
        credentials = username + ':' + password

        encoded = Base64.encode64(credentials)
        @headers['Authorization'] = "Basic #{encoded}"
      end

      self
    end

    #
    # Sets the BodyHandler for this RESTClient
    #
    # @param body_handler [BodyHandler] The body handler.
    # @return [RESTClient] this
    #
    def body_handler(body_handler)
      @body_handler = body_handler
      self
    end

    def certificate(certificate)
      @certificate = certificate
      self
    end

    def connect_timeout(connect_timeout)
      @connect_timeout = connect_timeout
      self
    end

    def read_timeout(read_timeout)
      @read_timeout = read_timeout
      self
    end

    def delete
      @method = 'DELETE'
      self
    end

    def error_response_handler(error_response_handler)
      @error_response_handler = error_response_handler
      self
    end

    def get
      @method = 'GET'
      self
    end

    def go
      if @url.size == 0
        raise ArgumentError, 'You must specify a URL'
      end

      if @method == nil
        raise ArgumentError, 'You must specify a HTTP method'
      end

      response = ClientResponse.new
      response.request = (@body_handler != nil) ? @body_handler.body_object : nil
      response.method = @method

      begin
        if @parameters.length > 0
          if @url.index('?') == nil
            @url<<'?'
          end

          list = []
          @parameters.each { |key, values|
            values.each { |value|
              list<<"#{URI.encode_www_form_component(key)}=#{URI.encode_www_form_component(value)}"
            }
          }

          @url<<list.join('&')
        end

        response.url = URI(@url)
        opts = {:p_addr => @proxy[:p_addr], :p_port => @proxy[:p_port], :p_user => @proxy[:p_user], :p_pass => @proxy[:p_pass], :open_timeout => @connect_timeout, :read_timeout => @read_timeout}
        if @certificate != nil
          opts[:cert] = @certificate
        end
        if response.url.scheme == 'https'
          opts[:use_ssl] = true
        end
        if @body_handler != nil
          @body_handler.set_headers(@headers)
        end

        http_response = nil
        Net::HTTP.start(response.url.hostname, response.url.port, opts) { |http|
          request = nil
          if @method == 'COPY'
            request = Net::HTTP::Copy.new(response.url, @headers)
          elsif @method == 'DELETE'
            request = Net::HTTP::Delete.new(response.url, @headers)
          elsif @method == 'GET'
            request = Net::HTTP::Get.new(response.url, @headers)
          elsif @method == 'HEAD'
            request = Net::HTTP::Head.new(response.url, @headers)
          elsif @method == 'LOCK'
            request = Net::HTTP::Lock.new(response.url, @headers)
          elsif @method == 'MKCOL'
            request = Net::HTTP::Mkcol.new(response.url, @headers)
          elsif @method == 'MOVE'
            request = Net::HTTP::Move.new(response.url, @headers)
          elsif @method == 'OPTIONS'
            request = Net::HTTP::Options.new(response.url, @headers)
          elsif @method == 'PATCH'
            request = Net::HTTP::Patch.new(response.url, @headers)
          elsif @method == 'POST'
            request = Net::HTTP::Post.new(response.url, @headers)
          elsif @method == 'PROPFIND'
            request = Net::HTTP::Propfind.new(response.url, @headers)
          elsif @method == 'PROPPATCH'
            request = Net::HTTP::Proppatch.new(response.url, @headers)
          elsif @method == 'PUT'
            request = Net::HTTP::Put.new(response.url, @headers)
          elsif @method == 'TRACE'
            request = Net::HTTP::Trace.new(response.url, @headers)
          elsif @method == 'UNLOCK'
            request = Net::HTTP::Unlock.new(response.url, @headers)
          else
            raise ArgumentError, "Invalid HTTP method #{@method}"
          end

          request.body = response.request
          http_response = http.request(request)
        }

        response.status = http_response.code.to_i
        if response.status < 200 || response.status > 299
          if http_response.class.body_permitted? && !http_response.body.nil? && http_response.body.size > 0 && @error_response_handler != nil
            response.error_response = @error_response_handler.call(http_response.body)
          end
        elsif http_response.class.body_permitted? && !http_response.body.nil? && http_response.body.size > 0 && @success_response_handler != nil
          response.success_response = @success_response_handler.call(http_response.body)
        end
      rescue Exception => e
        response.status = -1
        response.exception = e
        # e.backtrace.each {|l| p l}
      end

      response
    end

    def header(name, value)
      @headers[name] = value
      self
    end

    def headers(headers)
      @headers.merge!(headers)
      self
    end

    def post
      @method = 'POST'
      self
    end

    def put
      @method = 'PUT'
      self
    end

    def success_response_handler(success_response_handler)
      @success_response_handler = success_response_handler
      self
    end

    def uri(uri)
      if @url.size == 0
        self
      end

      if @url[@url.size - 1] == '/' && uri[0] == '/'
        @url<<uri[1..uri.size]
      elsif @url[@url.size - 1] != '/' && uri[0] != '/'
        @url<<"/#{uri}"
      else
        @url<<uri
      end

      self
    end

    def url(url)
      @url = url.dup
      self
    end

    #
    # Add a URL parameter as a key value pair.
    #
    # @param name [String] The URL parameter name.
    # @param value [String} ]The url parameter value. The <code>.toString()</ code> method will be used to
    #              get the <code>String</code> used in the URL parameter. If the object type is a
    #             @link Collection} a key value pair will be added for each value in the collection.
    #             @link ZonedDateTime} will also be handled uniquely in that the <code>long</ code> will
    #              be used to set in the request using <code>ZonedDateTime.toInstant().toEpochMilli()</code>
    # @return This.
    #
    def url_parameter(name, value)
      if value == nil
        return self
      end

      if value.is_a? Array
        @parameters[name] = value
      else
        values = @parameters[name]
        if values == nil
          values = []
          @parameters[name] = values
        end
        values<<value
      end

      self
    end

    #
    # Append a url path segment. <p>
    # For Example: <pre>
    #     .url("http://www.foo.com ")
    #     .urlSegment(" bar ")
    #   </pre>
    # This will result in a url of <code>http://www.foo.com/bar</code>
    #
    # @param value The url path segment. A nil value will be ignored.
    # @return This.
    #/
    def url_segment(value)
      if value == nil
        return self
      end

      if @url[@url.size - 1] != '/'
        @url<<'/'
      end

      @url<<value
      self
    end

    private
    def to_http_uri(uri)
      uri.path + (uri.query == nil ? '' : "?#{uri.query}")
    end
  end

  class ClientResponse
    attr_accessor :url, :request, :method, :status, :success_response, :error_response, :exception

    def was_successful
      @status >= 200 && @status <= 299
    end
  end

  class JSONBodyHandler
    attr_accessor :length, :body

    def initialize(body_object)
      @body = JSON.generate(body_object)
    end

    #
    # Returns the body String for the request
    #
    # @return [String] The body as a String
    def body_object
      @body
    end

    #
    # Sets any headers necessary for the body to be processed.
    #
    # @param headers [Hash] The headers hash to add any headers needed by this BodyHandler
    # @return [Object] The object
    def set_headers(headers)
      headers['Length'] = body.bytesize.to_s
      headers['Content-Type'] = 'application/json'
      nil
    end
  end

  class JSONResponseHandler
    attr_accessor :type

    def initialize(type)
      @type = type
    end

    def call(body)
      JSON.parse(body, :object_class => @type)
    end
  end
end
