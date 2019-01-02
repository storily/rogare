# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:names) do
      Integer :id, identity: true, primary_key: true

      String :name, null: false
      Boolean :surname, null: false, default: false
      column :kinds, 'name_kind[]'

      column :added, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      String :source

      Float :frequency, null: false, default: 1.0

      constraint(:names_frequency_max) do
        frequency <= 100.0
      end

      constraint(:names_frequency_min) do
        frequency >= 0.0
      end

      index :name, type: 'btree'
      index :kinds, type: 'btree'
      index :source, type: 'btree'
      index :frequency, type: 'btree'
    end

    comment_on :column, %i[names name], 'All in lowercase, spaces allowed but not preferred'
    comment_on :column, %i[names surname], 'Whether the name is a surname'
    comment_on :column, %i[names kinds], 'Male/female/enby plus the rough ethnic provenance'
    comment_on :column, %i[names source], 'Freeform *short* source description/identifier'
    comment_on :column, %i[names frequency], 'Mostly ignored. Frequency from the source.'
  end
end
