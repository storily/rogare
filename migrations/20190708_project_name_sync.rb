# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:projects) do
      add_column :sync_name, 'boolean', null: false, default: true
      add_column :name_synced, 'timestamp with time zone', null: true
    end

    comment_on :column, %i[projects sync_name], 'Whether this project’s name is synced, or set here'
    comment_on :column, %i[projects name_synced], 'When the name was last synced'
  end
end
