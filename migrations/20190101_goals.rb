# frozen_string_literal: true

Sequel::Database.extension :pg_comment

Sequel.migration do
  change do
    create_table(:goals) do
      Integer :id, identity: true, primary_key: true

      column :created, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      column :updated, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      column :removed, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')

      Integer :novel_id, null: false
      Integer :parent_id

      String :name
      Integer :words, null: false

      Date :start, null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      Date :finish

      String :curve, null: false, default: 'linear'
      Boolean :repeat, null: false, default: false

      constraint(:goals_repeat_finish_presence) do
        Sequel.case(
          { repeat: Sequel.lit('finish IS NOT NULL') },
          true
        )
      end

      constraint(:goals_start_finish_gt) do
        Sequel.case(
          { Sequel.lit('finish IS NULL') => true },
          Sequel.lit('finish > start')
        )
      end

      constraint(:goals_words_minimum) do
        words > 0
      end
    end

    comment_on :column, :goals__removed, 'If the goal was deleted, and when'
    comment_on :column, :goals__parent_id, %(
      This is both to explicit the repeat parent/child relationships, and to
      disambiguate whether a goal should be considered past (“has a child”) in
      some odd timezone-of-database-server-related cases
    )

    comment_on :column, :goals__name, 'An optional name for human-friendly disambiguation'
    comment_on :column, :goals__words, 'Wordcount to reach, counting from the moment the goal starts'

    comment_on :column, :goals__start, %(
      A date, re-interpreted in application code to mean the right thing in the
      user’s current timezone
    )

    comment_on :column, :goals__finish, 'Similarly to start. A goal finishes on the end of its finish day'

    comment_on :column, :goals__curve, 'The curve to be used for calculating words to go at a date'
    comment_on :column, :goals__repeat, 'Whether the goal should be repeated when it reaches its finish'
  end
end
