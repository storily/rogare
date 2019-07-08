# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:projects) do
      add_column :unit, 'text', null: false, default: 'words'
      add_column :sync_unit, 'boolean', null: false, default: true
      add_column :unit_synced, 'timestamp with time zone', null: true
    end

    comment_on :column, %i[projects unit], 'The unit in which this project’s total is counted'
    comment_on :column, %i[projects sync_unit], 'Whether this project’s unit is synced, or set here'
    comment_on :column, %i[projects unit_synced], 'When the unit was last synced'
  end
end
