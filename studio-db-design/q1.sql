SET search_path TO recording;
-- DROP TABLE IF EXISTS q1 CASCADE;

-- create table q1 (
--     studio_name varchar(25) NOT NULL,
--     manager_id interger NOT NULL,
--     manager_name varchar(20) NOT NULL,
--     num_contributed integer NOT NULL
-- );

DROP VIEW IF EXISTS Managers CASCADE;
DROP VIEW IF EXISTS Contribution CASCADE;
DROP VIEW IF EXISTS ContributionCount CASCADE;


create view Managers as
select Studios.name as studio_name, Studios.studio_id as studio_id, People.person_id as manager_id, People.name as manager_name
from Studios natural join Manages join People
on Manages.manager_id = People.person_id
where end_date is NULL;

create view Contribution as
select Studios.studio_id as studio_id, count(distinct album_id) as num_contributed
from Studios natural join RecordSessions natural join RecordSegments 
natural join SegmentsInTrack natural join TracksInAlbum
group by Studios.studio_id;

create view ContributionCount as
select Studios.studio_id as studio_id, COALESCE(num_contributed, 0) as num_contributed
from Studios natural full join Contribution;

select Managers.studio_name as studio_name, Managers.manager_id, manager_name, num_contributed
from Managers natural join ContributionCount;