# frozen_string_literal: true

Sequel.migration do
  up do
    run <<-KINDS
    CREATE TYPE name_kind AS ENUM (
        'male',
        '-male',
        'female',
        '-female',
        'enby',
        '-enby',
        'latin',
        '-latin',
        'english',
        '-english',
        'afram',
        '-afram',
        'indian',
        '-indian',
        'maori',
        '-maori',
        'pacific',
        '-pacific',
        'mideast',
        '-mideast',
        'maghreb',
        '-maghreb',
        'easteuro',
        '-easteuro',
        'french',
        '-french',
        'amerindian',
        '-amerindian',
        'aboriginal',
        '-aboriginal'
    );
    KINDS
  end

  down do
    run 'DROP TYPE name_kind;'
  end
end
