# Rogare

IRC bot for NaNoWriMo (NZ channel).

- Runs on Heroku with one dyno.
- Queries [Cogitare](https://cogitare.nz) for the `!plot` command.
- Has various built-in lists of names for the `!name` command.

## Configuration

- `IRC_CHANNELS=` Space-delimited list of channels the bot should connect
  to. The first one will be "mainchan", to which messages that aren't
  replies to commands or patterns (such as responses from webhooks)
  will be sent.

- `IRC_NICK=`

- `IRC_PORT=`

- `IRC_REALNAME=`

- `IRC_SERVER=`

- `IRC_SSL=` `0` for no encryption, `1` for SSL without verification,
  `2` for verified SSL.

- `RACK_ENV=` Currently only used for Bundler loading. Defaults to `production`.

- `DICERE_URL=` Point to the Dicere API url.

- `REDIS_URL=` Point to a Redis server.

## Installation & Development

To run locally:

1. Clone this repo,
2. Create a `.env` file with the configuration above in the form `KEY="value"`,
3. Install the dependencies: `bundle`,
4. If using rbenv, run `rbenv rehash`,
5. Start the bot: `bundle exec foreman start`.

The bot needs to be restarted at every change.

