# frozen_string_literal: true

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

      unique %i[novel_id as_at]
      index :as_at, type: 'btree'
      index :novel_id, type: 'btree'
    end

    comment_on :column, %i[wordcounts words], 'The absolute number of words in the novel at the recorded moment'
    comment_on :column, %i[wordcounts as_at], 'The moment when the amount of words was recorded'
    comment_on :column, %i[wordcounts created], 'The moment when this record was created'
  end
end
