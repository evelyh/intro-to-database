-- Inseparable.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q9 CASCADE;

CREATE TABLE q9 (
	student1 varchar(25) NOT NULL,
	student2 varchar(25) NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS assignment_groups CASCADE;
DROP VIEW IF EXISTS multi_member_group_assignments CASCADE;
DROP VIEW IF EXISTS groups_in_multi_member_assignment CASCADE;
DROP VIEW IF EXISTS student_in_multi_member_group CASCADE;
DROP VIEW IF EXISTS pairs_for_assignment CASCADE;
DROP VIEW IF EXISTS pairs_in_every_assignment CASCADE;

-- Define views for your intermediate steps here:
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

-- Get the group IDs that has more than 1 members in multi-member assignments
CREATE VIEW groups_in_multi_member_assignment AS (
	SELECT A.assignment_id, A.group_id
	FROM multi_member_group_assignments M natural join AssignmentGroup A natural join Membership MS
	GROUP BY A.assignment_id, A.group_id
	HAVING count(MS.username) > 1
);

-- Get the students that belong to a multi-member group for an assignment
CREATE VIEW student_in_multi_member_group AS (
	SELECT M.assignment_id, M.group_id, username AS student
	FROM groups_in_multi_member_assignment M, Membership
	WHERE M.group_id = Membership.group_id
);

-- Get the pair of students and the corresponding assignment IDs that both worked on
CREATE VIEW pairs_for_assignment AS (
	SELECT S1.assignment_id,
	S1.student AS student1,
	S2.student AS student2
	FROM student_in_multi_member_group S1,
	student_in_multi_member_group S2
	WHERE S1.assignment_id = S2.assignment_id
	AND S1.group_id = S2.group_id
	AND S1.student < S2.student
	ORDER BY S1.assignment_id
);

-- Get the pair of students that appeared in every multi-member assignments
CREATE VIEW pairs_in_every_assignment AS (
	SELECT P1.student1, P1.student2
	FROM pairs_for_assignment P1
	GROUP BY P1.student1, P1.student2
	HAVING count(DISTINCT assignment_id) = (
		SELECT count(DISTINCT assignment_id)
		FROM multi_member_group_assignments
	)
);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q9(student1, student2)
(
	SELECT student1, student2
	FROM pairs_in_every_assignment
);