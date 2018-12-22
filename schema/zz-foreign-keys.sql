ALTER TABLE ONLY goals
    ADD CONSTRAINT goals_novel_id_fkey FOREIGN KEY (novel_id) REFERENCES novels(id);

ALTER TABLE ONLY novels
    ADD CONSTRAINT nanos_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY wars_members
    ADD CONSTRAINT wars_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE ONLY wars_members
    ADD CONSTRAINT wars_members_war_id_fkey FOREIGN KEY (war_id) REFERENCES wars(id);

ALTER TABLE ONLY wars
    ADD CONSTRAINT wars_canceller_fkey FOREIGN KEY (canceller_id) REFERENCES users(id);
ALTER TABLE ONLY wars
    ADD CONSTRAINT wars_creator_fkey FOREIGN KEY (creator_id) REFERENCES users(id);

ALTER TABLE ONLY wordcounts
    ADD CONSTRAINT wordcounts_novel_id_fkey FOREIGN KEY (novel_id) REFERENCES novels(id);
