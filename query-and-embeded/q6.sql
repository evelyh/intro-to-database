-- Steady work.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q6 CASCADE;

CREATE TABLE q6 (
	group_id integer NOT NULL,
	first_file varchar(25) DEFAULT NULL,
	first_time timestamp DEFAULT NULL,
	first_submitter varchar(25) DEFAULT NULL,
	last_file varchar(25) DEFAULT NULL,
	last_time timestamp DEFAULT NULL,
	last_submitter varchar(25) DEFAULT NULL,
	elapsed_time interval DEFAULT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS A1Submissions CASCADE;
DROP VIEW IF EXISTS FirstSubmissions CASCADE;
DROP VIEW IF EXISTS LastSubmissions CASCADE;
DROP VIEW IF EXISTS FirstLastCombo CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW A1Submissions AS 
select AssignmentGroup.group_id as group_id,
min(submission_date) as first_time, max(submission_date) as last_time, 
max(submission_date) - min(submission_date) as elapsed_time
from Assignment natural join AssignmentGroup natural join Submissions
where description = 'A1'
group by group_id;

create view FirstSubmissions as
select A1Submissions.group_id as group_id, file_name as first_file,
username as first_submitter
from A1Submissions natural join Submissions
where submission_date = first_time;

create view LastSubmissions as 
select A1Submissions.group_id as group_id, file_name as last_file,
username as last_submitter
from A1Submissions natural join Submissions
where submission_date = last_time;

create view FirstLastCombo as 
select FirstSubmissions.group_id as group_id, first_file, first_submitter, last_file, last_submitter
from FirstSubmissions cross join LastSubmissions
where FirstSubmissions.group_id = LastSubmissions.group_id;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q6
select A1Submissions.group_id as group_id, first_file, first_time,
first_submitter, last_file, last_time, last_submitter, elapsed_time
from A1Submissions natural join FirstLastCombo;