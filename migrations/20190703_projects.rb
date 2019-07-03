# frozen_string_literal: true

Sequel.migration do
  change do
    create_enum :project_type, %w[nano camp]

    create_table(:projects) do
      Integer :id, identity: true, primary_key: true
      column :created, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')
      column :updated, 'timestamp with time zone', null: false, default: Sequel.lit('CURRENT_TIMESTAMP')

      column :type, 'project_type', null: false

      Integer :user_id, null: false
      Boolean :participating, null: false, default: false

      column :start, 'timestamp with time zone', null: false
      column :finish, 'timestamp with time zone', null: false

      Integer :words, null: true
      column :words_synced, 'timestamp with time zone', null: true

      Integer :goal, null: true
      Boolean :sync_goal, null: false, default: true
      column :goal_synced, 'timestamp with time zone', null: true

      index :user_id, type: 'btree'
      index :participating, type: 'btree'
      index :start, type: 'btree'
      index :finish, type: 'btree'
      index %i[user_id participating], type: 'btree'
      index %i[start finish], type: 'btree'
      index %i[user_id start finish participating], type: 'btree'
    end

    comment_on :column, %i[projects created], 'When this project was added to the db'
    comment_on :column, %i[projects updated], 'When this project was last updated'
    comment_on :column, %i[projects type], 'What type of project this is'
    comment_on :column, %i[projects user_id], 'Who this project belongs to'
    comment_on :column, %i[projects participating], 'Whether the user is participating'
    comment_on :column, %i[projects start], 'When this project starts counting'
    comment_on :column, %i[projects finish], 'When this project stops counting'
    comment_on :column, %i[projects words], 'How many words this project currently has, as synced last'
    comment_on :column, %i[projects words_synced], 'When the words were last synced'
    comment_on :column, %i[projects goal], 'This project’s goal, if there is one'
    comment_on :column, %i[projects sync_goal], 'Whether this project’s goal is synced, or set here'
    comment_on :column, %i[projects goal_synced], 'The last time the goal was synced'
  end
end
