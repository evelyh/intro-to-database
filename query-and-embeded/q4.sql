-- Grader report.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	assignment_id integer NOT NULL,
	username varchar(25) NOT NULL,
	num_marked integer NOT NULL,
	num_not_marked integer NOT NULL,
	min_mark real DEFAULT NULL,
	max_mark real DEFAULT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS AssignmentsWithGraders CASCADE;
DROP VIEW IF EXISTS TotalMarkEachAssignment CASCADE;
DROP VIEW IF EXISTS PercentageGrade CASCADE;
DROP VIEW IF EXISTS MarkedGroups CASCADE;
DROP VIEW IF EXISTS UnmarkedGroups CASCADE;
DROP VIEW IF EXISTS ans1 CASCADE;


-- left with assignments that have graders
CREATE VIEW AssignmentsWithGraders AS 
SELECT assignment_id, username, Grader.group_id 
FROM Grader JOIN AssignmentGroup 
ON Grader.group_id = AssignmentGroup.group_id;

CREATE VIEW TotalMarkEachAssignment AS 
SELECT assignment_id, sum(weight) AS total_mark FROM RubricItem
GROUP BY assignment_id;

CREATE VIEW PercentageGrade AS 
SELECT Result.group_id AS group_id, 
Result.mark / TotalMarkEachAssignment.total_mark * 100 AS mark
FROM AssignmentsWithGraders, Result, TotalMarkEachAssignment
WHERE AssignmentsWithGraders.assignment_id = TotalMarkEachAssignment.assignment_id AND
Result.group_id = AssignmentsWithGraders.group_id;

CREATE VIEW MarkedGroups AS 
SELECT assignment_id, username, max(mark) AS max_mark, 
min(mark) AS min_mark, count(PercentageGrade.group_id) AS num_marked
FROM AssignmentsWithGraders JOIN PercentageGrade 
ON AssignmentsWithGraders.group_id = PercentageGrade.group_id
GROUP BY assignment_id, username;

CREATE VIEW UnmarkedGroups AS 
SELECT assignment_id, username, count(*) AS num_not_marked
FROM AssignmentsWithGraders FULL JOIN Result 
ON AssignmentsWithGraders.group_id = Result.group_id
WHERE mark IS NULL
GROUP BY assignment_id, username;

create view ans1 as
select distinct AssignmentsWithGraders.assignment_id as assignment_id,
AssignmentsWithGraders.username as username,
max_mark, min_mark, num_marked
from AssignmentsWithGraders full join MarkedGroups 
on AssignmentsWithGraders.assignment_id = MarkedGroups.assignment_id 
and AssignmentsWithGraders.username = MarkedGroups.username;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
(SELECT ans1.assignment_id AS assignment_id, ans1.username AS username, 
COALESCE(num_marked, 0) AS num_marked, COALESCE(num_not_marked, 0) AS num_not_marked, min_mark, max_mark
FROM ans1 full join UnmarkedGroups
ON ans1.assignment_id = UnmarkedGroups.assignment_id AND 
ans1.username = UnmarkedGroups.username);