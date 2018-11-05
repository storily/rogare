FROM heroku/heroku:18

# Permanent
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - &&\
    apt install -y nodejs ruby-bundler ruby-dev libopus-dev libpq-dev \
        libsodium-dev zlib1g-dev sudo &&\
    useradd -mU rogare && mkdir /app &&\
    npm i -g npm &&\
    apt autoremove -y && apt clean -y && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV RACK_ENV=production

# Build-only
COPY Gemfile Gemfile.lock package.json package-lock.json ./
RUN apt update && chown -R rogare:rogare . &&\
    apt install -y autoconf automake build-essential libtool &&\
    sudo -iu rogare sh -c "cd /app; bundle --path .bundle && npm ci --cache .npm" &&\
    apt remove -y autoconf automake build-essential libtool &&\
    apt autoremove -y && apt clean -y && rm -rf .npm /var/lib/apt/lists/*

# Source
USER rogare
COPY . .
