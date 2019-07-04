# frozen_string_literal: true

Sequel.migration do
  up do
    run 'DROP type types;'
    create_enum :war_total_types, %w[words lines pages minutes]
  end

  change do
    alter_table(:wars_members) do
      drop_column :total
      drop_column :total_type
    end

    alter_table(:wars_members) do
      add_column :starting, Integer, null: false, default: 0
      add_column :ending, Integer, null: false, default: 0
      add_column :total_type, 'war_total_types', null: true, default: 'words'
    end
  end

  down do
    run 'DROP type war_total_types;'
  end
end
