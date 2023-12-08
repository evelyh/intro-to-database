SET search_path TO recording;

-- DROP TABLE IF EXISTS q4 CASCADE;

-- create table q4 (
--     album_name varchar(25) NOT NULL,
--     num_sessions integer NOT NULL,
--     num_participants integer NOT NULL
-- );

drop view if exists session_for_album CASCADE;
drop view if exists num_sessions_per_album CASCADE;
drop view if exists max_sessions_album CASCADE;
drop view if exists performers_for_albumCASCADE;


create view session_for_album as (
    select distinct album_id, session_id
    from TracksInAlbum T, SegmentsInTrack S, RecordSegments R
    where T.track_id = S.track_id
    and S.segment_id = R.segment_id
);

create view num_sessions_per_album as (
    select album_id, count(session_id) as num_sessions
    from session_for_album
    group by album_id
);

create view max_sessions_album as (
    select album_id, num_sessions
    from num_sessions_per_album
    where num_sessions = (
        select max(num_sessions) 
        from num_sessions_per_album
    )
);

create view performers_for_album as (
    select M.album_id, count(distinct performer_id) as num_participants
    from max_sessions_album M, session_for_album S, PerformersInSession P
    where M.album_id = S.album_id
    and S.session_id = P.session_id
    group by M.album_id
);

select name as album_name,
num_sessions, num_participants
from Albums A,
max_sessions_album M,
performers_for_album P
where A.album_id = M.album_id
and M.album_id = P.album_id;