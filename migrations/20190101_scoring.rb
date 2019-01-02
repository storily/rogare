# frozen_string_literal: true

Sequel.migration do
  up do
    run <<-SCOREUP
      -- https://github.com/JDBurnZ/postgresql-anyarray/blob/master/stable/anyarray_uniq.sql
      CREATE FUNCTION anyarray_uniq(with_array anyarray) RETURNS anyarray
          LANGUAGE plpgsql
          AS $$
      DECLARE
          -- The variable used to track iteration over "with_array".
          loop_offset integer;

          -- The array to be returned by this function.
          return_array with_array%TYPE := '{}';
      BEGIN
          IF with_array IS NULL THEN
              return NULL;
          END IF;

          IF with_array = '{}' THEN
              return return_array;
          END IF;

          -- Iterate over each element in "concat_array".
          FOR loop_offset IN ARRAY_LOWER(with_array, 1)..ARRAY_UPPER(with_array, 1) LOOP
              IF with_array[loop_offset] IS NULL THEN
                  IF NOT EXISTS(
                      SELECT 1
                      FROM UNNEST(return_array) AS s(a)
                      WHERE a IS NULL
                  ) THEN
                      return_array = ARRAY_APPEND(return_array, with_array[loop_offset]);
                  END IF;
              -- When an array contains a NULL value, ANY() returns NULL instead of FALSE...
              ELSEIF NOT(with_array[loop_offset] = ANY(return_array))
                  OR NOT(NULL IS DISTINCT FROM (with_array[loop_offset] = ANY(return_array))) THEN
                  return_array = ARRAY_APPEND(return_array, with_array[loop_offset]);
              END IF;
          END LOOP;

          RETURN return_array;
      END;
      $$;

      -- https://stackoverflow.com/a/22677955/231788
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
    SCOREUP
  end

  down do
    run <<-SCOREDOWN
      DROP FUNCTION anyarray_uniq(with_array anyarray);
      DROP AGGREGATE array_cat_agg(anyarray);
      DROP FUNCTION namekind_adjustment(name_kind[]);
      DROP MATERIALIZED VIEW names_scored_raw CASCADE;
    SCOREDOWN
  end
end
