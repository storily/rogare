# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:novels) do
      Integer :id, identity: true, primary_key: true
      column :created, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      column :updated, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      column :started, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')

      Integer :user_id, null: false
      String :name
      Boolean :finished, null: false, default: false

      index :user_id, type: 'btree'
      index :started, type: 'btree'
      index %i[finished started], type: 'btree'
    end

    comment_on :column, %i[novels started], 'When the novel was actually started'
    comment_on :column, %i[novels name], 'Aka title'
    comment_on :column, %i[novels finished], 'Novels marked finished cannot be updated'
  end
end
