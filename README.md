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

## Name frequency compute thing

Names are loaded in postgres (all-lowercase). Then two views are materialised
that compute the score of each unique name. The score is then log-normalised to
give a smoother distribution for querying.

This uses the [`anyarray_uniq`](https://github.com/JDBurnZ/postgresql-anyarray/blob/master/stable/anyarray_uniq.sql) function from JDBurnZ (to be copied in), and the [`array_cat_agg`](https://stackoverflow.com/a/22677955/231788) aggregate from Craig Ringer (shown below).

The compute was kept as two views instead of inlining to ease inspection.

```sql
CREATE AGGREGATE array_cat_agg(anyarray) (
  SFUNC=array_cat,
  STYPE=anyarray
);

CREATE OR REPLACE FUNCTION namekind_adjustment(name_kind[]) RETURNS name_kind[]
AS $$
DECLARE
  intermediate name_kind[] := $1;
  kind name_kind;
BEGIN
  FOREACH kind IN ARRAY $1
  LOOP
    IF kind::text LIKE '-%' THEN
      intermediate := array_remove(intermediate, substring(kind::text from 2)::name_kind);
      intermediate := array_remove(intermediate, kind);
    END IF;
  END LOOP;
  RETURN intermediate;
END; $$ LANGUAGE plpgsql
RETURNS NULL ON NULL INPUT
PARALLEL SAFE
IMMUTABLE
COST 10;

DROP MATERIALIZED VIEW names_scored_raw CASCADE;

CREATE MATERIALIZED VIEW names_scored_raw AS (
  SELECT
    name, surname,
    anyarray_uniq(array_agg(source)) AS sources,
    namekind_adjustment(anyarray_uniq(array_cat_agg(kinds))) AS kinds,
    (count(*)::double precision / (SELECT count(*) FROM names)) AS score
  FROM names
  GROUP BY name, surname
);

CREATE MATERIALIZED VIEW names_scored AS (
  SELECT
    name,
    surname,
    sources,
    kinds,
    ln(score * 1000000) * 100 / (
      SELECT ln(max(score) * 1000000) FROM names_scored_raw
    ) AS score
  FROM names_scored_raw
);

CREATE INDEX names_scored_score_idx ON names_scored USING btree (score);
CREATE INDEX names_scored_kinds_idx ON names_scored USING gin (kinds);
CREATE INDEX names_scored_kinds_rare_idx ON names_scored USING gin (kinds) WHERE score <= 20;
CREATE INDEX names_scored_kinds_common_idx ON names_scored USING gin (kinds) WHERE score >= 50;
```
