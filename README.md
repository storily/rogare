# Rogare

Discord bot.

- Runs on Heroku with one dyno.
- Queries [Cogitare](https://cogitare.nz) for the `!plot` command.
- Uses a Postgres database for all data.
- Has a `!name` generator/picker based on real data.
- Also provides `!wordcount`, `!choose`, `!wordwar`, many others.
- Does novel and goal management.

## Configuration

- `DISCORD_TOKEN=` The discord bot token.

- `RACK_ENV=` Currently only used for Bundler loading. Defaults to `production`.

- `DICERE_URL=` Point to the Dicere API url.

- `DATABASE_URL=` Points to a Postgres server (defaults to a local server).

- `DB_SCHEMA=` The database schema to use (for namespacing inside a single Postgres instance, defaults to `public`).

- `WOLFRAM_KEY=` With a valid Wolfram|Alpha key for the `!calc` command.

- `COMMANDS_WHITELIST=` (Optional, useful in dev.) Only loads the comma-separated commands.

## Installation & Development

To run locally:

1. Create a Postgres database,
2. Clone this repo,
3. Create a `.env` file with the configuration above in the form `KEY="value"`,
4. Install the dependencies: `bundle`,
5. Run the migrations: `rake db:migrate`,
6. Start the bot: `foreman start`.

You might need to prefix commands with `bundle exec`.

The bot needs to be restarted at every change.

The bot was previously a Cinch IRC bot, so has peculiarities from that time.

Use `rake fix` to run the lint check and fixer (good to do before pushing).

Migrations timestamped in 2018 are the initial schema (the migration system was
established in 2019). When creating a new migration, use today’s date.

After creating a migration, run it with `rake db:migrate`, then immediately run
`rake db:redo`, to test its rollback.

Use `rake console` to get a shell with most of the same context as the app. Note
that commands are not loaded automatically.

## Name frequency compute thing

Names are loaded in postgres (all-lowercase). Then two views are materialised
that compute the score of each unique name. The score is then log-normalised to
give a smoother distribution for querying.

This uses the [`anyarray_uniq`](https://github.com/JDBurnZ/postgresql-anyarray/blob/master/stable/anyarray_uniq.sql) function from JDBurnZ, and the [`array_cat_agg`](https://stackoverflow.com/a/22677955/231788) aggregate from Craig Ringer.

The compute was kept as two views instead of inlining to ease inspection.
