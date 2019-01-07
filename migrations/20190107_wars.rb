# frozen_string_literal: true

Sequel.migration do
    change do
  
      enum types: %i[words lines pages minutes]
  
      alter_table(:wars_members) do
        Integer :total, null: true
        column :total_type, 'types', null: true, default: 'words'
        
      end
    end
  end
  