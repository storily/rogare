# frozen_string_literal: true

Sequel::Database.extension :pg_comment

Sequel.migration do
  up do
    run <<-KINDS
    CREATE TYPE name_kind AS ENUM (
        'male',
        '-male',
        'female',
        '-female',
        'enby',
        '-enby',
        'latin',
        '-latin',
        'english',
        '-english',
        'afram',
        '-afram',
        'indian',
        '-indian',
        'maori',
        '-maori',
        'pacific',
        '-pacific',
        'mideast',
        '-mideast',
        'maghreb',
        '-maghreb',
        'easteuro',
        '-easteuro',
        'french',
        '-french',
        'amerindian',
        '-amerindian',
        'aboriginal',
        '-aboriginal'
    );
    KINDS
  end

  down do
    run 'DROP TYPE name_kind;'
  end

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

    comment_on :column, :names__name, 'All in lowercase, spaces allowed but not preferred'
    comment_on :column, :names__surname, 'Whether the name is a surname'
    comment_on :column, :names__kinds, 'Male/female/enby plus the rough ethnic provenance'
    comment_on :column, :names__source, 'Freeform *short* source description/identifier'
    comment_on :column, :names__frequency, 'Mostly ignored. Frequency from the source.'
  end
end
