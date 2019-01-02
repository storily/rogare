# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:users) do
      Integer :id, identity: true, primary_key: true
      column :first_seen, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      column :last_seen, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      column :updated, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')

      Bignum :discord_id, null: false
      String :nano_user
      String :nick
      String :tz, null: false, default: 'Pacific/Auckland'

      index :discord_id, unique: true, type: 'btree'
      index :nano_user, type: 'btree'
      index :nick, type: 'btree'
    end

    comment_on :column, %i[users first_seen], 'When the user was first seen by the bot'
    comment_on :column, %i[users last_seen], 'When the user was last seen by the bot, smoothed somewhat'
    comment_on :column, %i[users updated], 'Not counting last_seen updates'

    comment_on :column, %i[users discord_id], 'The opaque ID Discord uniquely assigns each user'
    comment_on :column, %i[users nano_user], 'NaNoWriMo participant name, as submitted by the user'
    comment_on :column, %i[users nick], 'The latest Discord nick the user was seen using'
  end
end
