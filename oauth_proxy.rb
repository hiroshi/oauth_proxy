require 'sinatra/base'
require 'oauth'
require 'oauth2'
require 'json'
require 'yaml'

class OAuthProxy < Sinatra::Base
  set :public_folder, File.dirname(__FILE__) + '/public'
  enable :sessions
  enable :logging
  # http://stackoverflow.com/a/5677589/338986
  configure :development do
    set :session_secret, "secret"
  end

  def self.symbolize_keys(hash)
    if hash.is_a?(Hash)
      hash.inject({}) {|h, p| h.merge(p[0].to_sym => symbolize_keys(p[1]))}
    else
      hash
    end
  end

  # Get provider info from yml
  PROVIDERS = YAML.load_file(File.dirname(__FILE__) + "/providers.yml").inject({}) do |h,p|
    h.merge(p[0] => symbolize_keys(p[1]))
  end
  # Get secrets from ENV
  SECRETS = ENV['SECRETS'].split(/\s+/).inject({}) do |h, e|
    site, key, secret = e.split(/:/)
    h.merge(site => {:key => key, :secret => secret})
  end

  def consumer(site)
    OAuth::Consumer.new(SECRETS[site][:key], SECRETS[site][:secret], PROVIDERS[site][:consumer_options])
  end

  def client(site)
    options = {:ssl => {:ca_file => '/etc/ssl/ca-bundle.pem'}}.merge(PROVIDERS[site][:client_options])
    OAuth2::Client.new(SECRETS[site][:key], SECRETS[site][:secret], options)
  end

  get '/:site/login' do |site|
    oauth_callback_url = "#{request.scheme}://#{request.host_with_port}/#{site}/oauth"
    case PROVIDERS[site][:oauth_version]
    when 1
      request_token = consumer(site).get_request_token(:oauth_callback => oauth_callback_url)
      session[site] = {
        :request_token => request_token.token,
        :request_token_secret => request_token.secret,
      }
      authorize_url = request_token.authorize_url
    when 2
      authorize_url = client(site).auth_code.authorize_url(:redirect_uri => oauth_callback_url, :scope => "user")
    end
    redirect authorize_url
  end

  get '/:site/oauth' do |site|
    case PROVIDERS[site][:oauth_version]
    when 1
      request_token = OAuth::RequestToken.new(consumer(site), session[site][:request_token], session[site][:request_token_secret])
      access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
      response.set_cookie("#{site}_token_secret", :value => access_token.secret, :httponly => true)
    when 2
      access_token = client(site).auth_code.get_token(params[:code])
    end
    response.set_cookie("#{site}_token", :value => access_token.token, :httponly => true)
    
    <<-HTML
<!doctype html>
<html>
<script type="text/javascript">
  window.close();
</script>
</html>
  HTML
  end

  get '/:site/api' do |site|
    url = params[:url]
    callback = params[:callback]
    case PROVIDERS[site][:oauth_version]
    when 1
      access_token = OAuth::AccessToken.new(consumer(site), request.cookies["#{site}_token"], request.cookies["#{site}_token_secret"])
      result = access_token.get(url)
    when 2
      access_token = OAuth2::AccessToken.new(client(site), request.cookies["#{site}_token"])
      begin
        result = access_token.get(url)
      rescue => e
        p e
      end
    end
    
    content_type "application/json"
    "#{callback}(#{result.body})"
  end
end
