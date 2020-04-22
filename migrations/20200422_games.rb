# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:games) do
      Integer :id, identity: true, primary_key: true

      foreign_key :creator_id, :users, null: true
      TrueClass :enabled, null: false, default: true
      String :text, null: false
    end

    comment_on :column, %i[games creator_id], "The ID of the user who created this entry"
    comment_on :column, %i[games enabled], "Whether this now playing entry is used in the bot game rotation"
    comment_on :column, %i[games text], "The text to display in the game field of the bot's Discord profile"
  end

  down do
    drop_table(:games)
  end
end
