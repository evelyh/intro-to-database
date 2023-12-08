SET search_path TO recording;
-- DROP TABLE IF EXISTS q2 CASCADE;

-- create table q2 (
--     person_id integer NOT NULL,
--     num_sessiosn integer NOT NULL
-- );

DROP VIEW IF EXISTS Performers CASCADE;

create view Performers as
select performer_id, count(session_id) as num_sessions
from PerformersInSession
group by performer_id;

select People.person_id as person_id, COALESCE(num_sessions, 0) as num_sessions
from Performers full join People on Performers.performer_id = People.person_id;
