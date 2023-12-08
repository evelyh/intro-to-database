-- Solo superior.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
	assignment_id integer NOT NULL,
	description varchar(100) NOT NULL,
	num_solo integer NOT NULL,
	average_solo real NOT NULL,
	num_collaborators integer NOT NULL,
	average_collaborators real NOT NULL,
	average_students_per_group real NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS CompleteGrading CASCADE;
DROP VIEW IF EXISTS AssignmentGroupMemberCount CASCADE;
DROP VIEW IF EXISTS BothTypeGroupAssignemnt CASCADE;
DROP VIEW IF EXISTS TotalMarkEachAssignment CASCADE;
DROP VIEW IF EXISTS PercentageGrade CASCADE;
DROP VIEW IF EXISTS QualifiedAssignmentGroupAvg CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW CompleteGrading AS
(select distinct assignment_id from AssignmentGroup)
except
(select distinct assignment_id
from Result natural full join AssignmentGroup
where mark is null
group by assignment_id);

create view AssignmentGroupMemberCount as 
select assignment_id, group_id, count(username) as num_mem
from CompleteGrading natural join AssignmentGroup natural join Membership
group by assignment_id, group_id;

create view BothTypeGroupAssignment as
select assignment_id, 
count(case when num_mem = 1 then group_id end) as num_solo,
sum(case when num_mem > 1 then num_mem end) as num_collaborators,
(sum(case when num_mem > 1 then num_mem end) + count(case when num_mem = 1 then group_id end)) / count(group_id) as average_students_per_group
from AssignmentGroupMemberCount
group by assignment_id
having count(case when num_mem = 1 then group_id end) != 0 
and count(case when num_mem > 1 then group_id end) != 0;

CREATE VIEW TotalMarkEachAssignment AS 
SELECT assignment_id, sum(weight) AS total_mark FROM RubricItem
GROUP BY assignment_id;

CREATE VIEW PercentageGrade AS 
SELECT Result.group_id AS group_id, mark / total_mark * 100 AS mark
FROM BothTypeGroupAssignment natural join AssignmentGroup natural join Result natural join TotalMarkEachAssignment;

create view QualifiedAssignmentGroupAvg as 
select BothTypeGroupAssignment.assignment_id,
avg(case when num_mem = 1 then mark end) as average_solo,
avg(case when num_mem > 1 then mark end) as average_collaborators
from BothTypeGroupAssignment natural join AssignmentGroupMemberCount natural join PercentageGrade
group by BothTypeGroupAssignment.assignment_id;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
select QualifiedAssignmentGroupAvg.assignment_id as assignment_id, 
description, num_solo, average_solo,
num_collaborators, average_collaborators, average_students_per_group
from QualifiedAssignmentGroupAvg natural join Assignment natural join BothTypeGroupAssignment
where average_solo > average_collaborators;