# frozen_string_literal: true

Sequel::Database.extension :pg_comment

Sequel.migration do
  change do
    create_table(:wordcounts) do
      Integer :id, identity: true, primary_key: true
      column :created, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      column :as_at, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')

      Integer :novel_id, null: false
      Integer :words, null: false

      constraint(:wordcounts_words_minimum) do
        words >= 0
      end

      index [:novel_id, :as_at], type: 'btree', unique: true
      index :as_at, type: 'btree'
      index :novel_id, type: 'btree'
    end

    comment_on :column, :wordcount__words, 'The absolute number of words in the novel at the recorded moment'
    comment_on :column, :wordcount__as_at, 'The moment when the amount of words was recorded'
    comment_on :column, :wordcount__created, 'The moment when this record was created'
  end
end
