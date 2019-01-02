# frozen_string_literal: true

Sequel::Database.extension :pg_comment

Sequel.migration do
  change do
    create_table(:users) do
      Integer :id, identity: true, primary_key: true
      Bignum :discord_id, null: false
      String :nick
      String :nano_user
      column :first_seen, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      column :last_seen, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      column :updated, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      String :tz, null: false, default: 'Pacific/Auckland'

      index :discord_id, unique: true, type: 'btree'
      index :nano_user, type: 'btree'
      index :nick, type: 'btree'
    end

    comment_on :column, :users__discord_id, 'The opaque ID Discord uniquely assigns each user'
    comment_on :column, :users__nick, 'The latest Discord nick the user was seen using'
    comment_on :column, :users__nano_user, 'NaNoWriMo participant name, as submitted by the user'
    comment_on :column, :users__first_seen, 'When the user was first seen by the bot'
    comment_on :column, :users__last_seen, 'When the user was last seen by the bot, smoothed somewhat'
    comment_on :column, :users__updated, 'Not counting last_seen updates'
  end
end
