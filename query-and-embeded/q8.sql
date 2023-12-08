-- Never solo by choice.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q8 CASCADE;

CREATE TABLE q8 (
	username varchar(25) NOT NULL,
	group_average real NOT NULL,
	solo_average real DEFAULT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS assignment_groups CASCADE;
DROP VIEW IF EXISTS multi_member_group_assignments CASCADE;
DROP VIEW IF EXISTS solo_assignments CASCADE;
DROP VIEW IF EXISTS student_submitted_for_assignment CASCADE;
DROP VIEW IF EXISTS one_submission_per_assignment CASCADE;
DROP VIEW IF EXISTS groups_in_multi_member_assignment CASCADE;
DROP VIEW IF EXISTS student_in_multi_member_group CASCADE;
DROP VIEW IF EXISTS in_a_group_for_assignment CASCADE;
DROP VIEW IF EXISTS filtered_students CASCADE;
DROP VIEW IF EXISTS total_weights_per_assignment CASCADE;
DROP VIEW IF EXISTS grades_as_percentage CASCADE;
DROP VIEW IF EXISTS student_solo_average_grades CASCADE;
DROP VIEW IF EXISTS student_multi_average_grades CASCADE;


-- Define views for your intermediate steps here:

-- Get assignment ID and group ID that belongs to this assignment
CREATE VIEW assignment_groups AS (
	SELECT assignment_id, ROW_NUMBER() OVER 
	(ORDER BY assignment_id) 
	AS group_id
	FROM AssignmentGroup
);

-- Get the assignments that allows multiple members
CREATE VIEW multi_member_group_assignments AS (
	SELECT assignment_id
	FROM Assignment A
	WHERE A.group_max > 1
);

-- Get the assignments that can only be solo
CREATE VIEW solo_assignments AS (
	(SELECT assignment_id FROM Assignment)
	EXCEPT
	(SELECT assignment_id 
	FROM multi_member_group_assignments)
);

-- Get the assignments that a student has submitted for
CREATE VIEW student_submitted_for_assignment AS (
	SELECT distinct S.username AS student,
	assignment_id
	FROM AssignmentGroup AG natural join Submissions S
);

-- Get the student that has one file submission per assignment
CREATE VIEW one_submission_per_assignment AS (
	SELECT student
	FROM student_submitted_for_assignment S,
	Assignment A
	GROUP BY student
	HAVING count(DISTINCT S.assignment_id) = (
		SELECT count(DISTINCT assignment_id)
		FROM Assignment
	)
);

-- Get the group IDs that belongs to the multi-member assignments
CREATE VIEW groups_in_multi_member_assignment AS (
	SELECT A.assignment_id, A.group_id
	FROM multi_member_group_assignments M natural join AssignmentGroup A natural join Membership MS
	GROUP BY A.assignment_id, A.group_id
	HAVING count(MS.username) > 1
);

-- Get the students that belong to a multi-member group for an assignment
CREATE VIEW student_in_multi_member_group AS (
	SELECT M.assignment_id, username AS student
	FROM groups_in_multi_member_assignment M, Membership
	WHERE M.group_id = Membership.group_id
);

-- Get the students that submitted 
CREATE VIEW in_a_group_for_assignment AS (
	SELECT student
	FROM student_in_multi_member_group S,
	Assignment A
	GROUP BY student
	HAVING count(DISTINCT S.assignment_id) = (
		SELECT count(DISTINCT assignment_id)
		FROM multi_member_group_assignments
	)
);

-- Get the students that satisfy both requirements
CREATE VIEW filtered_students AS (
	(SELECT student FROM one_submission_per_assignment)
	INTERSECT
	(SELECT student FROM in_a_group_for_assignment)
);

-- Get the total weight for the assignment
CREATE VIEW total_weights_per_assignment AS (
	SELECT assignment_id, sum(weight) as total_weight
	FROM RubricItem
	GROUP BY assignment_id
);

-- Convert the grade to percentage
CREATE VIEW grades_as_percentage AS (
	SELECT Result.group_id AS group_id, AssignmentGroup.assignment_id as assignment_id,
	mark / total_weight * 100 AS percentage_grade
	FROM Result natural join AssignmentGroup natural join total_weights_per_assignment
);

create view filtered_students_assignments_grades as (
	select student, assignment_id, percentage_grade
	FROM filtered_students F,
	Membership M,
	grades_as_percentage G
	WHERE M.username = student
	AND M.group_id = G.group_id
);

CREATE VIEW student_solo_average_grades AS (
	select student, COALESCE(avg(percentage_grade), null) as solo_average
	from filtered_students_assignments_grades FG natural right join (solo_assignments S cross join filtered_students)
	group by student
);

-- Get the students and their percentage grades for the solo assignments
CREATE VIEW student_multi_average_grades AS (
	select student, COALESCE(avg(percentage_grade), null) as group_average
	from filtered_students_assignments_grades FG natural right join (multi_member_group_assignments S cross join filtered_students)
	group by student
);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q8(username, group_average, solo_average)
(SELECT S.student AS username, M.group_average, S.solo_average
FROM student_solo_average_grades S natural join
student_multi_average_grades M);

