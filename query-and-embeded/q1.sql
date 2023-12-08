-- Distributions.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
	assignment_id integer NOT NULL,
	average_mark_percent real DEFAULT NULL,
	num_80_100 integer NOT NULL,
	num_60_79 integer NOT NULL,
	num_50_59 integer NOT NULL,
	num_0_49 integer NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS ExistGrades CASCADE;
DROP VIEW IF EXISTS TotalMarkEachAssignment CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW TotalMarkEachAssignment AS 
SELECT assignment_id, sum(weight) AS total_mark FROM RubricItem
GROUP BY assignment_id;

CREATE VIEW ExistGrades AS 
select Result.mark / total_mark * 100 as percentage_grade, 
TotalMarkEachAssignment.assignment_id as assignment_id, Result.group_id as group_id
from TotalMarkEachAssignment natural join AssignmentGroup natural join Result;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1
select assignment_id, avg(percentage_grade) as average_mark_percent,
count(case when percentage_grade >= 80 then group_id end) as num_80_100,
count(case when percentage_grade >= 60 and percentage_grade < 80 then group_id end) as num_60_79,
count(case when percentage_grade >= 50 and percentage_grade < 60 then group_id end) as num_50_59,
count(case when percentage_grade < 50 then group_id end) as num_0_49
from ExistGrades natural full join Assignment
group by assignment_id;