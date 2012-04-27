require "./oauth_proxy"
# http://devcenter.heroku.com/articles/ruby#logging
$stdout.sync = true

run Rack::URLMap.new("/" => OAuthProxy.new)
