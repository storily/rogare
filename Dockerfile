FROM passcod/archlinux
MAINTAINER Félix Saparelli me@passcod.name

RUN pacman -S --noconfirm --needed ruby sqlite &&\
  pacman -Scc --noconfirm &&\
  rm -rf /var/cache/pacman/pkg/*

RUN gem install --no-ri --no-rdoc bundler
CMD /.gem/ruby/2.1.0/bin/bundle exec foreman start
WORKDIR /app

ADD .bundle Gemfile Gemfile.lock vendor /app/
RUN pacman -S --noconfirm --needed base-devel &&\
  /.gem/ruby/2.1.0/bin/bundle install --deployment --binstubs &&\
  /usr/bin/bash -c "comm -13 <(pacman -Qg base|cut -c6-) <(pacman -Qg base-devel|cut -c12-)|xargs pacman -Rsn --noconfirm" &&\
  pacman -Scc --noconfirm &&\
  rm -rf /var/cache/pacman/pkg/*
  
ADD .env Procfile config.ru bot.rb web.rb plugins templates /app/
