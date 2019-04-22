# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:suggestions) do
      Integer :id, identity: true, primary_key: true
      column :created, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      column :updated, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')

      Integer :user_id, null: false
      String :text
      Boolean :processed, null: false, default: false
    end
  end
end
