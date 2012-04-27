OAuth Proxy
===========

Supported OAuth Providers
-------------------------

- Twitter
- Github

You can add another providers to providers.yml

"SECRETS" environment variable
------------------------------

### Heroku

    heroku config:add SECRETS="github:{key}:{secret} twitter:{key}:{secret}"

### local

    SECRETS="github:{key}:{secret} twitter:{key}:{secret}" bundle exec rackup ./config.ru
