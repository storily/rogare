# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:goals) do
      add_foreign_key [:novel_id], :novels
      add_foreign_key [:parent_id], :goals
    end

    alter_table(:novels) do
      add_foreign_key [:user_id], :users
    end

    alter_table(:wars_members) do
      add_foreign_key [:user_id], :users
      add_foreign_key [:war_id], :wars
    end

    alter_table(:wars) do
      add_foreign_key [:canceller_id], :users
      add_foreign_key [:creator_id], :users
    end

    alter_table(:wordcounts) do
      add_foreign_key [:novel_id], :novels
    end
  end

  down do
    alter_table(:goals) do
      drop_foreign_key [:novel_id]
      drop_foreign_key [:parent_id]
    end

    alter_table(:novels) do
      drop_foreign_key [:user_id]
    end

    alter_table(:wars_members) do
      drop_foreign_key [:user_id]
      drop_foreign_key [:war_id]
    end

    alter_table(:wars) do
      drop_foreign_key [:canceller_id]
      drop_foreign_key [:creator_id]
    end

    alter_table(:wordcounts) do
      drop_foreign_key [:novel_id]
    end
  end
end
