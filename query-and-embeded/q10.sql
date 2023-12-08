-- A1 report.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q10 CASCADE;

CREATE TABLE q10 (
	group_id bigint NOT NULL,
	mark real DEFAULT NULL,
	compared_to_average real DEFAULT NULL,
	status varchar(5) DEFAULT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS A1_groups CASCADE;
DROP VIEW IF EXISTS total_weights_A1 CASCADE;
DROP VIEW IF EXISTS grades_as_percentage CASCADE;
DROP VIEW IF EXISTS A1_average CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW A1_groups AS (
	SELECT assignment_id, group_id FROM AssignmentGroup
	where assignment_id = 1
);

-- Get the total weight for the assignment
CREATE VIEW total_weights_A1 AS (
	SELECT assignment_id, sum(weight) as total_weight
	FROM RubricItem
	WHERE assignment_id = 1
	GROUP BY assignment_id
);

-- Convert the grade to percentage
CREATE VIEW grades_as_percentage AS (
	SELECT TW.assignment_id, Result.group_id, 
	(mark / total_weight * 100) AS percentage_grade
	FROM total_weights_A1 AS TW,
	A1_groups as A1G,
	Result
	WHERE TW.assignment_id = 1
	AND Result.group_id = A1G.group_id
);

CREATE VIEW A1_average AS (
	SELECT assignment_id, 
	avg(percentage_grade) as average_grade
	FROM grades_as_percentage
	GROUP BY assignment_id
);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q10(group_id, mark, compared_to_average, status)
(
	SELECT A1_groups.group_id, 
	percentage_grade as mark, 
	(percentage_grade - average_grade) as compared_to_average,
	CASE 
	WHEN percentage_grade - average_grade > 0 THEN 'above'
	WHEN percentage_grade - average_grade = 0 THEN 'at'
	WHEN percentage_grade - average_grade < 0 THEN 'below'
	ELSE NULL
	END
	FROM A1_average, 
	A1_groups LEFT JOIN grades_as_percentage G
	ON A1_groups.group_id = G.group_id
	ORDER BY group_id
);