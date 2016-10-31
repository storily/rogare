FROM passcod/archlinux
MAINTAINER Félix Saparelli me@passcod.name

RUN pacman -Sy --noconfirm --needed ruby sqlite base-devel
RUN gem install --no-ri --no-rdoc bundler
CMD /.gem/ruby/2.3.0/bin/bundle exec foreman start
WORKDIR /app

ADD Gemfile Gemfile.lock /app/
RUN /.gem/ruby/2.3.0/bin/bundle install --binstubs

ADD .env Procfile config.ru bot.rb web.rb /app/
ADD plugins /app/plugins
ADD templates /app/templates
