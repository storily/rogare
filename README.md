# Rogare

Discord bot for NaNoWriMo (NZ channel).

- Runs on Heroku with one dyno.
- Queries [Cogitare](https://cogitare.nz) for the `!plot` command.
- Uses a Postgres database for all data.
- Has a `!name` generator/picker based on real data.
- Also provides `!wordcount`, `!choose`, and `!wordwar`.

## Configuration

- `DISCORD_TOKEN=` The discord bot token.

- `RACK_ENV=` Currently only used for Bundler loading. Defaults to `production`.

- `DICERE_URL=` Point to the Dicere API url.

- `DATABASE_URL=` Points to a Postgres server (defaults to a local server).

- `DB_SCHEMA=` The database schema to use (for namespacing inside a single Postgres instance, defaults to `public`).

- `WOLFRAM_KEY=` With a valid Wolfram|Alpha key for the `!calc` plugin.

## Installation & Development

To run locally:

1. Clone this repo,
2. Create a `.env` file with the configuration above in the form `KEY="value"`,
3. Install the dependencies: `bundle`,
4. If using rbenv, run `rbenv rehash`,
5. Start the bot: `bundle exec foreman start`.

The bot needs to be restarted at every change.

The bot was previously a Cinch IRC bot, so has peculiarities from that time.
