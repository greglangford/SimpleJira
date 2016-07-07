require "rest-client"
require "json"

module SimpleJira
  class Client

    def initialize(username, password, baseurl)
      baseurl = baseurl += "/rest/api/2"
      @rest_client = RestClient::Resource.new(baseurl, :user => username, :password => password)
    end

    def get_issue(key, params={})
      request(:get, "/issue/#{key}", params)
    end

    def get_issue_transitions(key, params={})
      request(:get, "/issue/#{key}/transitions", params)
    end

    def set_issue_transition(key, transition_id, message)
      params = {
        "update": {
          "comment": [
            {
              "add": {
                "body": message
              }
            }
          ]
        },
        "transition": {
          "id": transition_id
        }
      }

      request(:post, "/issue/#{key}/transitions?expand=transitions.fields", params)
    end

    private

      def request(method, path, params=nil)
        case method
        when :get
          if params
            path = path + '?' + hash_to_params(params)
          end

          begin
            res = @rest_client[path].get
          rescue => e
            response = e
          end

          if not response
            code = res.code
            raw = res.to_str
            response = JSON.parse(raw)
          else
            code = response.http_code
            response = JSON.parse(response.response.to_s)
          end

          [code, response]

        when :post
          if not params
            params = {}
          end

          begin
            puts params
            res = @rest_client[path].post params.to_json, :content_type => "application/json"
          rescue => e
            response = e
          end

          if not response
            code = res.code
            raw = res.to_str

            # some shitty hack incase no JSON is returned
            begin
              response = JSON.parse(raw)
            rescue JSON::ParserError
              response = {}
            end
          else
            code = response.http_code
            response = JSON.parse(response.response.to_s)
          end

          [code, response]
        end
      end

      def hash_to_params(myhash)
        myhash.map { |k, v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }.join("&")
      end
  end
end
