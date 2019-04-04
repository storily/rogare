# frozen_string_literal: true

Sequel.migration do
  change do
    create_enum :types, %w[words lines pages minutes]

    alter_table(:wars_members) do
      add_column :total, Integer, null: true
      add_column :total_type, 'types', null: true, default: 'words'
    end
  end
end
