CREATE OR REPLACE FUNCTION upgrade_serial_to_identity(tbl regclass, col name)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  colnum smallint;
  seqid oid;
  count int;
BEGIN
  -- find column number
  SELECT attnum INTO colnum FROM pg_attribute WHERE attrelid = tbl AND attname = col;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'column does not exist';
  END IF;

  -- find sequence
  SELECT INTO seqid objid
    FROM pg_depend
    WHERE (refclassid, refobjid, refobjsubid) = ('pg_class'::regclass, tbl, colnum)
      AND classid = 'pg_class'::regclass AND objsubid = 0
      AND deptype = 'a';

  GET DIAGNOSTICS count = ROW_COUNT;
  IF count < 1 THEN
    RAISE EXCEPTION 'no linked sequence found';
  ELSIF count > 1 THEN
    RAISE EXCEPTION 'more than one linked sequence found';
  END IF;

  -- drop the default
  EXECUTE 'ALTER TABLE ' || tbl || ' ALTER COLUMN ' || quote_ident(col) || ' DROP DEFAULT';

  -- change the dependency between column and sequence to internal
  UPDATE pg_depend
    SET deptype = 'i'
    WHERE (classid, objid, objsubid) = ('pg_class'::regclass, seqid, 0)
      AND deptype = 'a';

  -- mark the column as identity column
  UPDATE pg_attribute
    SET attidentity = 'd'
    WHERE attrelid = tbl
      AND attname = col;
END;
$$;

select upgrade_serial_to_identity('sassbot.goals', 'id');
select upgrade_serial_to_identity('sassbot.names', 'id');
select upgrade_serial_to_identity('sassbot.users', 'id');
select upgrade_serial_to_identity('sassbot.wars', 'id');
select upgrade_serial_to_identity('sassbot.wordcounts', 'id');
drop function upgrade_serial_to_identity;

drop index names_frequency_idx;
drop index names_kinds_idx;
drop index names_name_idx;
drop index names_source_idx;
create index names_frequency_index on names using btree (frequency);
create index names_kinds_index on names using btree (kinds);
create index names_name_index on names using btree (name);
create index names_source_index on names using btree (source);

alter sequence nanos_id_seq rename to novels_id_seq;
alter table novels drop column curve;
alter table novels rename constraint nanos_pkey to novels_pkey;

drop index users_discord_id_idx;
drop index users_nano_user_idx;
drop index users_nick_idx;
update users set discord_id = -13 where nick = 'RebeccaLC16';
alter table users add constraint users_discord_id_key unique (discord_id);
create index users_nano_user_index on users using btree (nano_user);
create index users_nick_index on users using btree (nick);

alter table wars rename constraint wars_canceller_fkey to wars_canceller_id_fkey;
alter table wars rename constraint wars_creator_fkey to wars_creator_id_fkey;

alter table wars_members rename constraint users_wars_pkey to wars_members_pkey;
drop index users_wars_war_id_user_id_index;
create index wars_members_war_id_user_id_index on wars_members using btree (war_id, user_id);
alter table wars_members rename constraint users_wars_user_id_fkey to wars_members_user_id_fkey;
alter table wars_members rename constraint users_wars_war_id_fkey to wars_members_war_id_fkey;

alter table wordcounts rename constraint wordcounts_novel_id_as_at_unique to wordcounts_novel_id_as_at_key;

create table schema_migrations (filename text primary key);
insert into schema_migrations (filename) values ('20180101_goals.rb'), ('20180201_name_kinds.rb'), ('20180301_names.rb'), ('20180401_novels.rb'), ('20180501_scoring.rb'), ('20180601_users.rb'), ('20180701_wars.rb'), ('20180801_wordcounts.rb'), ('20180901_zz_foreign_keys.rb');
