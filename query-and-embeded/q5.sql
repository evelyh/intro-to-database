-- Uneven workloads.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
	assignment_id integer NOT NULL,
	username varchar(25) NOT NULL,
	num_assigned integer NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS AssignedNum CASCADE;
DROP VIEW IF EXISTS FilteredAssignment CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW AssignedNum AS 
select assignment_id, username, count(Grader.group_id) as num_assigned
from Grader natural join AssignmentGroup
group by assignment_id, username;

create view FilteredAssignment as 
select assignment_id
from AssignedNum
group by assignment_id
having max(num_assigned) - min(num_assigned) > 10;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5
select assignment_id, username, num_assigned
from AssignedNum natural join FilteredAssignment;