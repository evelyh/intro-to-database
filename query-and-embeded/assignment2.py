"""CSC343 Assignment 2

=== CSC343 Fall 2023 ===
Department of Computer Science,
University of Toronto

This code is provided solely for the personal and private use of
students taking the CSC343 course at the University of Toronto.
Copying for purposes other than this use is expressly prohibited.
All forms of distribution of this code, whether as given or with
any changes, are expressly prohibited.

Authors: Diane Horton and Marina Tawfik

All of the files in this directory and all subdirectories are:
Copyright (c) 2023

=== Module Description ===

This file contains the Markus class and some simple testing functions.
"""
import datetime as dt
import psycopg2 as pg
import psycopg2.extensions as pg_ext
import psycopg2.extras as pg_extras
from typing import Optional


class Markus:
    """A class that can work with data conforming to the schema in schema.ddl.

    === Instance Attributes ===
    connection: connection to a PostgreSQL database of Markus-related
        information.

    Representation invariants:
    - The database to which <connection> holds a reference conforms to the
      schema in schema.ddl.
    """
    connection: Optional[pg_ext.connection]

    def __init__(self) -> None:
        """Initialize this Markus instance, with no database connection
        yet.
        """
        self.connection = None

    def connect(self, dbname: str, username: str, password: str) -> bool:
        """Establish a connection to the database <dbname> using the
        username <username> and password <password>, and assign it to the
        instance attribute <connection>. In addition, set the search path
        to markus.

        Return True if the connection was made successfully, False otherwise.
        I.e., do NOT throw an error if making the connection fails.

        >>> a2 = Markus()
        >>> # The following example will only work if you change the dbname
        >>> # and password to your own credentials.
        >>> a2.connect("csc343h-marinat", "marinat", "")
        True
        >>> # In this example, the connection cannot be made.
        >>> a2.connect("invalid", "nonsense", "incorrect")
        False
        """
        try:
            self.connection = pg.connect(
                dbname=dbname, user=username, password=password,
                options="-c search_path=markus"
            )
            return True
        except pg.Error:
            return False

    def disconnect(self) -> bool:
        """Close this instance's connection to the database.

        Return True if closing the connection was successful, False otherwise.
        I.e., do NOT throw an error if closing the connection fails.

        >>> a2 = Markus()
        >>> # The following example will only work if you change the dbname
        >>> # and password to your own credentials.
        >>> a2.connect("csc343h-marinat", "marinat", "")
        True
        >>> a2.disconnect()
        True
        """
        try:
            if self.connection and not self.connection.closed:
                self.connection.close()
            return True
        except pg.Error:
            return False

    def get_groups_count(self, assignment: int) -> Optional[int]:
        """Return the number of groups defined for the assignment with
        ID <assignment>.

        Return None if the operation was unsuccessful i.e., do NOT throw
        an error.

        The operation is considered unsuccessful if <assignment> is an invalid
        assignment ID.

        Note: if <assignment> is a valid assignment ID but happens to have
        no groups defined, the operation is considered successful,
        with a returned count of 0.
        """
        try:
            cursor = self.connection.cursor()
            cursor.execute(
                "SELECT assignment_id FROM Assignment WHERE assignment_id=%s;", (assignment,)
            )
            if cursor.fetchone() is None:
                return None
            cursor.execute(
                """SELECT assignment_id, count(*) FROM AssignmentGroup 
                WHERE assignment_id = %s GROUP BY assignment_id;""", (assignment,)
            )
            if cursor.rowcount==0:
                return 0
            else: 
                return cursor.fetchone()[1]

        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            raise ex
            return

    def assign_grader(self, group: int, grader: str) -> bool:
        """Assign grader <grader> to the assignment group <group>, by updating
        the Grader table appropriately.

        If <group> has already been assigned a grader, update the Result table
        to reflect that the new grader is <grader>.

        Return True if the operation is successful, and False Otherwise.
        I.e., do NOT throw an error. If the operation is unsuccessful, no
        changes should be made to the database.

        The operation is considered unsuccessful if one or more of the following
        is True:
            * <group> is not a valid group ID i.e., it doesn't exist in the
              AssignmentGroup table.
            * <grader> is an invalid Markus username or is neither a
              TA nor an instructor.

        Note: if <grader> is already assigned to the assignment group <group>,
        the operation is considered to be successful.
        """
        try:
            cursor = self.connection.cursor()
            cursor.execute("select * from AssignmentGroup where group_id = %s;", (group,))
            if cursor.fetchone() is None:
                return False
            cursor.execute(
                """select * from MarkusUser where username = %s 
                and (type = 'TA' or type = 'instructor');""", (grader,))
            if cursor.fetchone() is None:
                return False

            cursor.execute("select * from Grader where group_id = %s;", (group,))
            if cursor.fetchone() is None:
                cursor.execute(
                    "insert into Grader(group_id, username) values (%s, %s);", (group, grader))
            else:
                cursor.execute(
                    "update Grader set username = '%s' where group_id = %s;", (grader, group))
            return True
        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            return

    def remove_student(self, username: str, date: dt.date) -> int:
        """Remove the student identified by <username> from all groups on
        assignments that have due date greater than (i.e., after) <date>.

        Return the number of groups the user was removed from, or -1 if the
        operation was unsuccessful, i.e. do NOT throw an error.

        The operation is considered unsuccessful if <username> is an invalid
        user or is not a student. Note: if <username> is a valid student but
        is not a member of any group, the operation is considered successful,
        but no deletion will occur.

        Make sure to delete any empty group(s) that result(s) from deleting the
        target memberships of <username>.

        Note: Compare the due date of an assignment on the precision of days.
        E.g., if <date> is 2023-09-01, an assignment due on 2023-09-01 23:59
        is not considered to be "after" that because it is not due on a later
        day.
        """
        try:
            num_deleted = 0
            cur = self.connection.cursor()

            # check if the username is valid or that it belongs to a student
            cur.execute("""SELECT type
                        FROM MarkusUser
                        WHERE username = %s;""", (username,))
            
            verify = cur.fetchone()
            
            if verify is None:  # username is invalid
                return -1
            
            if verify[0] != 'student': # user is not a student
                return -1 # TypeError: 'NoneType' object is not subscriptable
            
            # Get the groups that the student belongs to
            # Where the due dates is greater than the input date
            cur.execute("""SELECT M.group_id
                        FROM Membership M,
                        AssignmentGroup AG,
                        Assignment A
                        WHERE M.username = %s
                        AND M.group_id = AG.group_id
                        AND AG.assignment_id = A.assignment_id
                        AND (%s - A.due_date) < INTERVAL '0';""", (username, date))
            violated_groups = cur.fetchall() # [(1), (2)]
            
            if cur.rowcount > 0: # if user is a member of at least one group
                # get the return variable to be the groups deleted from the operation
                num_deleted = cur.rowcount

                # Delete the membership for each row
                for group in violated_groups:
                    cur.execute("""DELETE FROM Membership
                                WHERE group_id = %s;""", (group[0],))

                # Get empty groups
                cur.execute ("""(SELECT DISTINCT group_id FROM AssignmentGroup)
                             EXCEPT
                             (SELECT DISTINCT group_id FROM Membership);""")
                
                result = cur.fetchall()

                for entry in result:
                    cur.execute("""DELETE FROM AssignmentGroup
                                WHERE group_id = %s;""", (entry[0],))
            
            return num_deleted
        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            return

    def create_groups(
        self, assignment_to_group: int, other_assignment: int, repo_prefix: str
    ) -> bool:
        """Create student groups for <assignment_to_group> based on their
        performance in <other_assignment>. The repository URL of all created
        groups will start with <repo_prefix>.

        Find all students who are defined in the Users table and put each of
        them into a group for <assignment_to_group>.
        Suppose there are n. Each group will be of the maximum size allowed for
        the assignment (call that k), except for possibly one group of smaller
        size if n is not divisible by k.

        Note: k may be as low as 1.

        The choice of which students to put together is based on their grades on
        <other_assignment>, as recorded in table Result. (It makes no difference
        whether the grades were released or not.)  Starting from the
        highest grade on <other_assignment>, the top k students go into one
        group, then the next k students go into the next, and so on. The last
        n % k students form a smaller group.

        Students with no grade recorded for <other_assignment> come at the
        bottom of the list, after students who received zero. When there is a
        tie for grade (or non-grade) on <other_assignment>, take students in
        order by username, using alphabetical order from A to Z.

        When a group is created, its group ID is generated automatically because
        the group_id attribute of table AssignmentGroup uses the next value in
        a SQL SEQUENCE. The value of a group's attribute repo is
            repoPrefix + "/group_" + group_id

        Return True if the operation is successful, and False Otherwise.
        I.e., do NOT throw an error. If the operation is unsuccessful, no
        changes should be made to the database.

        The operation is considered unsuccessful if one or more of the following
        is True:
            * There is no assignment with ID <assignment_to_group> or
              no assignment with ID <other_assignment>.
            * One or more group(s) have already been defined for
              <assignment_to_group>.

        Note: If there are no students in the db, define no groups for
        <assignment_to_group>) and return True; the operation is considered
        successful. No changes should be made to the db in this case.

        Precondition: The group_min for <assignment_to_group> is 1.
        """
        sql_check_assignment = """
        SELECT group_max FROM Assignment WHERE assignment_id = %s
        """

        sql_check_no_groups = """
        SELECT * FROM AssignmentGroup WHERE assignment_id = %s  LIMIT 1
        """
        try:
            cur = self.connection.cursor()

            # Check if assignment_to_group is valid
            cur.execute(sql_check_assignment, (assignment_to_group,))
            if cur.fetchone() is None: 
                return False

            # Check if other_assignment is valid
            cur.execute(sql_check_assignment, (other_assignment,))
            if cur.fetchone() is None: 
                return False

            # Check if there are any groups assigned to assignment_to_group
            cur.execute(sql_check_no_groups, (assignment_to_group,))
            if cur.fetchone() is not None: 
                return False

            # Get the number of students that's registered on markus
            cur.execute("""SELECT count(username) FROM MarkusUser
                        WHERE type = 'student';""")
            total_students = cur.fetchone()[0]

            if total_students == 0: # There are no students in the DB
                return True
        

            # Get the max members allowed in a group for assignment_to_group
            cur.execute("""SELECT group_max FROM Assignment
                        WHERE assignment_id = %s;""", (assignment_to_group,))
            max_group_member = cur.fetchone()[0]

            # Get the number of groups to generate
            num_groups = total_students // max_group_member

            # Check for remainder (extra students)
            # If there are, add 1 to the number of groups
            left_over_stuents = total_students % max_group_member
            if left_over_stuents > 0:
                num_groups += 1

            # Get the maximum existing group_id
            cur.execute("""SELECT max(group_id) FROM AssignmentGroup;""")
            max_group_number = cur.fetchone()[0]
            
            # Insert the new groups into AssignmentGroup
            for i in range(1, num_groups + 1):
                repo_string = repo_prefix + "/group_" + str(max_group_number + i)
                cur.execute("""INSERT INTO AssignmentGroup(assignment_id, repo)
                            VALUES (%s, %s);""", (assignment_to_group, repo_string))
            
            # Get the students that have received a grade in other_assignment
            # Ordered by their grade and their username
            cur.execute("""SELECT username FROM Membership, Result, AssignmentGroup
                        WHERE Membership.group_id = Result.group_id
                        AND Membership.group_id = AssignmentGroup.group_id
                        AND AssignmentGroup.assignment_id = %s
                        ORDER BY mark DESC, username;""", (other_assignment,))
            student_with_grades = cur.fetchall()

            # Get the student that have no recorded grade in other_assignment
            cur.execute("""(SELECT username FROM MarkusUser
                        WHERE type = 'student')
                        EXCEPT
                        (SELECT username FROM Membership, Result, AssignmentGroup
                        WHERE Membership.group_id = Result.group_id
                        AND Membership.group_id = AssignmentGroup.group_id
                        AND AssignmentGroup.assignment_id = %s)
                        ORDER BY username;""", (other_assignment,))
            student_without_grades = cur.fetchall()

            # Combine all the students in a sorted fashion
            sorted_student = student_with_grades + student_without_grades

            # Assign these student into new groups
            current_group_number = max_group_number + 1
            curr_group_size = 0

            for student in sorted_student:
                if curr_group_size < max_group_member: # we have not exceeded the maximum group size
                    cur.execute("""INSERT INTO Membership(username, group_id)
                                VALUES (%s, %s);""", (student[0], current_group_number,))
                    curr_group_size += 1
                else: # the group is full
                    curr_group_size = 0
                    current_group_number += 1
                    cur.execute("""INSERT INTO Membership(username, group_id)
                                VALUES (%s, %s);""", (student[0], current_group_number,))
                    curr_group_size += 1

            return True
                
        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            return


def setup(
    dbname: str, username: str, password: str, schema_path: str, data_path: str
) -> None:
    """Set up the testing environment for the database <dbname> using the
    username <username> and password <password> by importing the schema file
    at <schema_path> and the file containing the data at <data_path>.

    <schema_path> and <data_path> are the relative/absolute paths to the files
    containing the schema and the data respectively.
    """
    connection, cursor, schema_file, data_file = None, None, None, None
    try:
        connection = pg.connect(
            dbname=dbname, user=username, password=password,
            options="-c search_path=markus"
        )
        cursor = connection.cursor()

        schema_file = open(schema_path, "r")
        cursor.execute(schema_file.read())

        data_file = open(data_path, "r")
        cursor.execute(data_file.read())

        connection.commit()
    except Exception as ex:
        connection.rollback()
        raise Exception(f"Couldn't set up environment for tests: \n{ex}")
    finally:
        if cursor and not cursor.closed:
            cursor.close()
        if connection and not connection.closed:
            connection.close()
        if schema_file:
            schema_file.close()
        if data_file:
            data_file.close()


def test_get_groups_count() -> None:
    """Test method get_groups_count.
    """
    # TODO: Change the values of the following variables to connect to your
    #  own database:
    dbname = "csc343h-leiyunha"
    user = "leiyunha"
    password = "Evelyh1217"

    # The following uses the relative paths to the schema file and the data file
    # we have provided. For your own tests, you will want to make your own data
    # files to use for testing.
    schema_file = "./schema.ddl"
    data_file = "./data.sql"

    a2 = Markus()
    try:
        connected = a2.connect(dbname, user, password)

        # The following is an assert statement. It checks that the value for
        # connected is True. The message after the comma will be printed if
        # that is not the case (that is, if connected is False).
        # Use the same notation throughout your testing.
        assert connected, f"[Connect] Expected True | Got {connected}."

        # The following function call will set up the testing environment by
        # loading a fresh copy of the schema and the sample data we have
        # provided into your database. You can create more sample data files
        # and call the same function to load them into your database.
        setup(dbname, user, password, schema_file, data_file)

        # TODO: Test more methods here, or better yet, make more testing
        # functions, with each testing a different method, and call them from
        # the main block below.

        # ---------------------- Testing get_groups_count ---------------------#

        # Invalid assignment ID
        num = a2.get_groups_count(0)
        assert num is None, f"[Get Group Count] Expected: None. Got {num}."

        # Valid assignment ID. No groups recorded.
        num = a2.get_groups_count(3)
        assert num == 0, f"[Get Group Count] Expected: 0. Got {num}."

        # Valid assignment ID. Some groups recorded.
        num = a2.get_groups_count(1)
        assert num == 5, f"[Get Group Count] Expected: 5. Got {num}."

    finally:
        a2.disconnect()

def test_assign_grader() -> None:
    """Test method assign_grader.
    """
    dbname = "csc343h-leiyunha"
    user = "leiyunha"
    password = "Evelyh1217"
    schema_file = "./schema.ddl"
    data_file = "./data.sql"
    a2 = Markus()
    try:
        connected = a2.connect(dbname, user, password)
        assert connected, f"[Connect] Expected True | Got {connected}."
        setup(dbname, user, password, schema_file, data_file)
        cursor = self.connection.cursor()

        # Valid assignment
        res = a2.assign_grader(9, "lupinr4")
        assert res is True, f"Expected: True. Got {res}."
        cursor.execute("select username from Grader where group_id = 9;")
        ret = cursor.fetchone()[1]
        assert ret == "lupinr4", f"Expected grader: lupinr4. Got{ret}"

        # Valid update
        res = a2.assign_grader(9, "snapes")
        assert res is True, f"Expected: True. Got {res}."
        cursor.execute("select username from Grader where group_id = 9;")
        ret = cursor.fetchone()[1]
        assert ret == "snapes", f"Expected grader: snapes. Got{ret}"

        # Invalid username
        num = a2.assign_grader(10, "weaslyr30")
        assert res is False, f"Expected: False. Got {res}."

        # Invalid group_id
        num = a2.assign_grader(11, "snapes")
        assert res is False, f"Expected: False. Got {res}."

    finally:
        a2.disconnect()


def test_remove_students() -> None:
    dbname = "csc343h-majianx1"
    user = "majianx1"
    password = "@DavidMA0808"

    schema_file = "./schema.ddl"
    data_file = "./data.sql"

    a2 = Markus()

    try:
        connected = a2.connect(dbname, user, password)
        assert connected, f"[Connect] Expected True | Got {connected}."
        setup(dbname, user, password, schema_file, data_file)
        cursor = a2.connection.cursor()

        # Test case on Markus
        res = a2.remove_student(username='student1', date=dt.date(2023, 10, 18))
        assert res == 2, f"Expected: 2. Actual: {res}."

    finally:
        a2.disconnect()

def test_create_groups():
    dbname = "csc343h-majianx1"
    user = "majianx1"
    password = "@DavidMA0808"

    schema_file = "./schema.ddl"
    data_file = "./data.sql"

    a2 = Markus()

    connected = a2.connect(dbname, user, password)
    assert connected, f"[Connect] Expected True | Got {connected}."
    setup(dbname, user, password, schema_file, data_file)
    cursor = a2.connection.cursor()

    # Test case on Markus
    res = a2.create_groups(assignment_to_group=2, other_assignment=1, repo_prefix='generated')
    assert res is True, f"Expected: True. Actual: {res}"




if __name__ == "__main__":
    # Un comment-out the next two lines if you would like to run the doctest
    # examples (see ">>>" in the methods connect and disconnect)
    # import doctest
    # doctest.testmod()

    # test_get_groups_count()
    # test_remove_students()
    test_create_groups()