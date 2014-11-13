FROM passcod/archlinux
MAINTAINER Félix Saparelli me@passcod.name

RUN pacman -Sy --noconfirm ruby base-devel sqlite &&\
  pacman -Scc --noconfirm &&\
  rm -rf /var/cache/pacman/pkg/*

RUN gem install --no-ri --no-rdoc bundler
ADD . /app
WORKDIR /app
RUN /.gem/ruby/2.1.0/bin/bundle install
CMD /.gem/ruby/2.1.0/bin/bundle exec foreman start
