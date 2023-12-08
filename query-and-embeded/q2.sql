-- Getting soft?

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
	grader_username varchar(25) NOT NULL,
	grader_name varchar(100) NOT NULL,
	average_mark_all_assignments real NOT NULL,
	mark_change_first_last real NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS GraderAssignedAll CASCADE;
DROP VIEW IF EXISTS GraderCompleteTen CASCADE;
DROP VIEW IF EXISTS TotalMarkEachAssignment CASCADE;
DROP VIEW IF EXISTS IndividualPercentageGrades CASCADE;
DROP VIEW IF EXISTS GraderAvg CASCADE;
DROP VIEW IF EXISTS Comparison CASCADE;
DROP VIEW IF EXISTS MinGrade CASCADE;
DROP VIEW IF EXISTS TiredGrader CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW GraderAssignedAll AS
(select distinct username from Grader) except
(select distinct username from ((select username, assignment_id
from MarkusUser, Assignment
where MarkusUser.type = 'TA')
except
(select distinct username, assignment_id
from Grader natural join AssignmentGroup)) as foo);

create view GraderCompleteTen as
select distinct username
from GraderAssignedAll natural join Grader natural join Result natural join AssignmentGroup
group by username, assignment_id
having count(mark) > 10;

CREATE VIEW TotalMarkEachAssignment AS 
SELECT assignment_id, sum(weight) AS total_mark 
FROM RubricItem
GROUP BY assignment_id;

create view IndividualPercentageGrades as 
select username as student, Membership.group_id as group_id, 
AssignmentGroup.assignment_id as assignment_id, mark / total_mark * 100 as percentage_grade
from Membership natural join Result natural join AssignmentGroup natural join TotalMarkEachAssignment;

create view GraderAvg as 
select username, assignment_id, avg(percentage_grade) as avg_each, due_date
from GraderCompleteTen natural join Grader natural join IndividualPercentageGrades natural join Assignment
group by username, assignment_id, due_date;

--every assignment that has higher avg than all earlier assignments
create view Comparison as 
select * from GraderAvg A1
where A1.avg_each > 
(select max(A2.avg_each) from GraderAvg A2 
where A1.username = A2.username and A1.due_date > A2.due_date); 

create view MinGrade as 
select * from GraderAvg except select * from Comparison;

--only min grade is not included in comparison
create view TiredGrader as 
select username 
from GraderAvg
group by username
having min(avg_each) = all (select avg_each from MinGrade where MinGrade.username = GraderAvg.username)
and min(due_date) = all (select due_date from MinGrade where MinGrade.username = GraderAvg.username); 

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
select username as grader_username, (firstname || ' ' || surname) as grader_name,
avg(avg_each) as average_mark_all_assignments, max(avg_each) - min(avg_each) as mark_change_first_last
from TiredGrader natural join GraderAvg natural join MarkusUser
group by username, firstname, surname;