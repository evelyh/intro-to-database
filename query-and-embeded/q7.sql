-- High coverage.

SET search_path TO markus;
DROP TABLE IF EXISTS q7 CASCADE;

CREATE TABLE q7 (
	grader varchar(25) NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS assignment_groups CASCADE;
DROP VIEW IF EXISTS assignment_grader CASCADE;
DROP VIEW IF EXISTS grader_in_all_assignment CASCADE;
DROP VIEW IF EXISTS assignment_student_group CASCADE;
DROP VIEW IF EXISTS grader_students CASCADE;
DROP VIEW IF EXISTS all_possible_grader_students CASCADE;
DROP VIEW IF EXISTS grader_not_all_student CASCADE;


-- Define views for your intermediate steps here:

-- Get assignment ID and group ID that belongs to this assignment
CREATE VIEW assignment_groups AS (
	SELECT assignment_id, ROW_NUMBER() OVER 
	(ORDER BY assignment_id) 
	AS group_id
	FROM AssignmentGroup
);

-- Get the grader responsible for this assignment
CREATE VIEW assignment_grader AS (
	SELECT assignment_id, username AS grader
	FROM assignment_groups A, Grader G
	WHERE G.group_id = A.group_id
);

-- Get the grader that is assigned to every assignment
CREATE VIEW grader_in_all_assignment AS (
	SELECT grader 
	FROM assignment_grader
	GROUP BY grader
	HAVING count(DISTINCT assignment_id) = (
		SELECT count(DISTINCT assignment_id)
		FROM assignment_grader
	)
);

-- Get the grouping of the assignment ID, the group ID, and the grader in charge
CREATE VIEW assignment_student_group AS (
	SELECT assignment_id, A.group_id,
	username AS student
	FROM assignment_groups A, Membership M
	WHERE M.group_id = A.group_id 
	ORDER BY assignment_id
);

create view grader_students as (
	select distinct G.username as grader, M.username as student
	from Grader G, AssignmentGroup A, Membership M
	where G.group_id = A.group_id and A.group_id = M.group_id
);

create view all_possible_grader_students as (
	select distinct M1.username as grader, M2.username as student
	from MarkusUser M1 cross join MarkusUser M2
	where (M1.type = 'TA' or M1.type = 'instructor') and M2.type = 'student'
);

-- Get the grader that didn't grade an assignment for all students
CREATE VIEW grader_not_all_student AS (
	select distinct grader from 
	(select * from all_possible_grader_students 
	except 
	select * from grader_students) as foo
);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q7(grader)
(SELECT grader 
FROM grader_in_all_assignment)
EXCEPT
(SELECT grader
FROM grader_not_all_student);