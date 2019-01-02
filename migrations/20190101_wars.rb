# frozen_string_literal: true

Sequel::Database.extension :pg_comment

Sequel.migration do
  change do
    create_table(:wars) do
      Integer :id, identity: true, primary_key: true
      column :created, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      column :updated, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')

      column :start, 'timestamp with time zone', null: false
      Integer :seconds, null: false
      Integer :creator_id, null: false
      column :channels, 'text[]', null: false

      column :cancelled, 'timestamp with time zone'
      Integer :canceller_id

      Boolean :started, null: false, default: false
      Boolean :ended, null: false, default: false
    end

    comment_on :column, :wars__start, 'When this war is slated to start'
    comment_on :column, :wars__seconds, 'How long the war will run for'
    comment_on :column, :wars__creator_id, 'Who created this war. Note the creator may leave the war.'
    comment_on :column, :wars__cancelled, 'If the war is cancelled, and when that was done'
    comment_on :column, :wars__canceller_id, 'If the war was cancelled by a known user, who that is'
    comment_on :column, :wars__channels, 'What channels this war should broadcast to'
    comment_on :column, :wars__started, 'If this war was announced as having started'
    comment_on :column, :wars__ended, 'If this war was announced as having ended'

    create_table(:wars_members) do
      Integer :user_id, null: false
      Integer :war_id, null: false

      primary_key [:user_id, :war_id]
      index [:war_id, :user_id], type: 'btree'
    end
  end
end
