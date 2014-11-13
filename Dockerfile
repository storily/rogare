FROM passcod/archlinux
MAINTAINER Félix Saparelli me@passcod.name

RUN pacman -S --noconfirm --needed ruby sqlite &&\
  pacman -Scc --noconfirm &&\
  rm -rf /var/cache/pacman/pkg/*

RUN gem install --no-ri --no-rdoc bundler
ADD . /app
WORKDIR /app
RUN /.gem/ruby/2.1.0/bin/bundle install --deployment --local --binstubs
CMD /.gem/ruby/2.1.0/bin/bundle exec foreman start
