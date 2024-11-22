class Twitch
  class TwitchError < StandardError; end

  def initialize( client_id, client_secret, expires_in = Time.now())
    @twitch_api_url = 'api.twitch.tv/helix'
    @oauth_api_url = 'id.twitch.tv/oauth2/token'
    @client_id = client_id
    @client_secret = client_secret
    @app_token = ''
    @token_type = ''
    @expires_in = expires_in
    client_credential_grant()
  end

  def get_broadcaster_channel(broadcaster_login)
    broadcaster_id = get_broadcaster(broadcaster_login)['data'][0]['id']
    get_channel_info broadcaster_id
  end

  def get_broadcaster(broadcaster_login)
    get 'users', {login: broadcaster_login}
  end

  def get_stream_title(broadcaster_login)
    get_broadcaster_channel(broadcaster_login)['data'][0]['title']
  end

  def get_channel_info(broadcaster_id)
    get 'channels', {broadcaster_id: broadcaster_id}
  end

  private

  def get(method, query, body = {})
    if @expires_in <= Time.now()
      client_credential_grant
    end
    HTTParty.get(
      "https://#{@twitch_api_url}/#{method}",
      {
        headers: {
          'Cache-Control': 'no-cache',
          'Client-Id': "#{@client_id}",
          'Authorization': "Bearer #{@app_token}"
        },
        body: body,
        query: query
      }
    ).parsed_response
  end

  def client_credential_grant
    return unless @expires_in.nil? || @expires_in <= Time.now()
    result = HTTParty.post(
      "https://#{@oauth_api_url}",
      headers: {
        'Cache-Control': 'no-cache'
      }, body: {
        'client_id': @client_id,
        'client_secret': @client_secret,
        'grant_type': 'client_credentials'
      }
    ).parsed_response
    @app_token = result['access_token']
    @expires_in = @expires_in + result['expires_in'].to_i
    @token_type = result['token_type']
  end

end
