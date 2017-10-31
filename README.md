# Rogare

IRC bot for NaNoWriMo (NZ channel).

- Runs on Heroku with one dyno.
- Queries [Cogitare](https://cogitare.nz) for the `!plot` command.
- Has various built-in lists of names for the `!name` command.
- Also provides `!wordcount`, `!choose`, and `!wordwar`.

## Configuration

- `IRC_CHANNELS=` List of channels the bot should connect to.

- `IRC_NICK=`

- `IRC_PORT=`

- `IRC_REALNAME=`

- `IRC_SERVER=`

- `IRC_SSL=` `0` for no encryption, `1` for SSL without verification,
  `2` for verified SSL.

- `RACK_ENV=` Currently only used for Bundler loading. Defaults to `production`.

- `DICERE_URL=` Point to the Dicere API url.

- `REDIS_URL=` Points to a redis server (defaults to a local server).

## Installation & Development

To run locally:

1. Clone this repo,
2. Create a `.env` file with the configuration above in the form `KEY="value"`,
3. Install the dependencies: `bundle`,
4. If using rbenv, run `rbenv rehash`,
5. Start the bot: `bundle exec foreman start`.

The bot needs to be restarted at every change.
