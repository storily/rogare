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

- `WOLFRAM_KEY=` With a valid Wolfram|Alpha key for the `!calc` command.

## Installation & Development

To run locally:

1. Clone this repo,
2. Create a `.env` file with the configuration above in the form `KEY="value"`,
3. Install the dependencies: `bundle`,
4. If using rbenv, run `rbenv rehash`,
5. Start the bot: `bundle exec foreman start`.

The bot needs to be restarted at every change.

The bot was previously a Cinch IRC bot, so has peculiarities from that time.

Database structure files are in the schema folder. Load in lexicographic order.

## Name frequency compute thing

Names are loaded in postgres (all-lowercase). Then two views are materialised
that compute the score of each unique name. The score is then log-normalised to
give a smoother distribution for querying.

This uses the [`anyarray_uniq`](https://github.com/JDBurnZ/postgresql-anyarray/blob/master/stable/anyarray_uniq.sql) function from JDBurnZ, and the [`array_cat_agg`](https://stackoverflow.com/a/22677955/231788) aggregate from Craig Ringer.

The compute was kept as two views instead of inlining to ease inspection.
