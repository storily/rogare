FROM ruby
MAINTAINER Félix Saparelli me@passcod.name

RUN apt update \
  && apt install -y sqlite build-essential ca-certificates ruby-dev \
  && gem install bundler
CMD bundle exec foreman start
WORKDIR /app

ADD Gemfile Gemfile.lock /app/
RUN bundle install

ADD .env Procfile config.ru bot.rb web.rb /app/
ADD plugins /app/plugins
ADD templates /app/templates
