SET search_path TO recording;

-- DROP TABLE IF EXISTS q3 CASCADE;

-- create table q3 (
--     person_id integer NOT NULL,
--     name varchar(20) NOT NULL
-- );

drop view if exists total_time_per_session CASCADE;
drop view if exists longest_session CASCADE;
drop view if exists participants_in_session CASCADE;

create view total_time_per_session as (
    select session_id, sum(length) as total_length
    from RecordSegments
    group by session_id
);

create view longest_session as (
    select session_id
    from total_time_per_session
    where total_length = (
        select max(total_length)
        from total_time_per_session
    )
);

create view participants_in_session as (
    select P.performer_id
    from PerformersInSession P, longest_session T
    where P.session_id = T.session_id
);

select distinct person_id, name
from People, participants_in_session P
where person_id = P.performer_id;