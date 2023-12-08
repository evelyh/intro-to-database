set SEARCH_PATH to recording;

-- when you start to write datas, could you also think if my
-- design of schema makes sense? especially the following: (we'll discuss)
-- 1. no table to track all the bands, only their memberships
-- 2. did not record if a band played at a session, but direcly
-- record all its members at a session
-- 3. split staffs for a session by engineers and performers since
-- they can have multiple roles in a session
-- 4. the necessity of 'position' for People, since one person could
-- have multiple positions?

INSERT INTO 
    Studios(name, address)
VALUES
    ('Pawnee Recording Studio', '123 Valley spring lane, Pawnee, Indiana'),
    ('Pawnee Sound', '353 Western Ave, Pawnee, Indiana'),
    ('Eagleton Recording Studio', '829 Division, Eagleton, Indiana');


INSERT INTO 
    People(person_id, name, email, phone, type)
VALUES
    (1231, 'April Ludgate', '1@hotmail.com', '1', 'manager'),
    (1232, 'Leslie Knope', '2@hotmail.com', '2', 'manager'),
    (1233, 'Donna Meagle', '3@hotmail.com', '3', 'manager'),
    (1234, 'Tom Haverford', '4@hotmail.com', '4', 'manager'),
    (5678, 'Ben Wyatt', '5@hotmail.com', '5', 'recordingEngineer'),
    (9942, 'Ann Perkins', '6@hotmail.com', '6', 'recordingEngineer'),
    (6521, 'Chris Traeger', '7@hotmail.com', '7', 'recordingEngineer'),
    (6754, 'Andy Dwyer', '8@hotmail.com', '8', 'performer'),
    (4523, 'Andrew Burlinson', '9@hotmail.com', '9', 'performer'),
    (2224, 'Michael Chang', '10@hotmail.com', '10', 'performer'),
    (7832, 'James Pierson', '11@hotmail.com', '11', 'performer'),
    (1000, 'Duke Silver', '12@hotmail.com', '12', 'performer');


INSERT INTO 
    Certificates(name, organization)
VALUES
    ('ABCDEFGH-123I', 'EngineerUnion'),
    ('JKLMNOPQ-456R', 'EngineerUnion'),
    ('SOUND-123-AUDIO', 'MercenaryPark');


INSERT INTO
    CertifiedEngineers(engineer_id, certificate_id)
VALUES
    (5678, 1),
    (5678, 2),
    (9942, 3);

INSERT INTO
    Bands(name)
VALUES
    ('Mouse Rat');

INSERT INTO
    BandMembership(band_id, member_id, role)
VALUES
    (1, 6754, 'Vocalist'),
    (1, 4523, 'Guitarist'),
    (1, 2224, 'Vocalist/Bass'),
    (1, 7832, 'Drummer');


INSERT INTO
    Manages(studio_id, manager_id, start_date, end_date)
VALUES
    (1, 1231, '2008-03-21', '2017-01-13'),
    (1, 1234, '2017-01-13', '2018-12-02'), 
    (1, 1233, '2018-12-02', NULL),
    (2, 1233, '2011-05-07', NULL),
    (3, 1232, '2010-09-05', '2016-09-05'),
    (3, 1234, '2016-09-05', '2020-09-05'),
    (3, 1232, '2020-09-05', NULL);


INSERT INTO
    RecordSessions(studio_id, start_time, end_time, fee)
VALUES
    (1, '2023-01-08 10:00', '2023-01-08 15:00', 1500),
    (1, '2023-01-10 13:00', '2023-01-11 14:00', 1500),
    (1, '2023-01-12 18:00', '2023-01-13 20:00', 1500),
    (1, '2023-03-10 11:00', '2023-03-10 23:00', 2000),
    (1, '2023-03-11 13:00', '2023-03-12 15:00', 2000),
    (1, '2023-03-13 10:00', '2023-03-13 20:00', 1000),
    (3, '2023-09-25 11:00', '2023-09-26 23:00', 1000),
    (3, '2023-09-29 11:00', '2023-09-30 23:00', 1000);


INSERT INTO
    EngineersInSession(session_id, engineer_id)
VALUES
    (1, 5678),
    (1, 9942),
    (2, 5678),
    (2, 9942),
    (3, 5678),
    (3, 9942),
    (4, 5678),
    (5, 5678),
    (6, 6521),
    (7, 5678),
    (8, 5678);


INSERT INTO
    PerformersInSession(session_id, performer_id)
VALUES
    (1, 6754),
    (1, 4523),
    (1, 2224),
    (1, 7832),
    (1, 1000),--?
    (2, 6754),
    (2, 4523),
    (2, 2224),
    (2, 7832),
    (2, 1000),--?
    (3, 6754),
    (3, 4523),
    (3, 2224),
    (3, 7832),
    (3, 1000),--?
    (4, 6754),
    (4, 4523),
    (4, 2224),
    (4, 7832),
    (5, 6754),
    (5, 4523),
    (5, 2224),
    (5, 7832),
    (6, 6754),
    (6, 1234),--?
    (7, 6754),
    (8, 6754);


INSERT INTO
    RecordSegments(session_id, length, format)
VALUES
    (1, 60, 'WAV'),
    (1, 60, 'WAV'),
    (1, 60, 'WAV'),
    (1, 60, 'WAV'),
    (1, 60, 'WAV'),
    (1, 60, 'WAV'),
    (1, 60, 'WAV'),
    (1, 60, 'WAV'),
    (1, 60, 'WAV'),
    (1, 60, 'WAV'),
    (2, 60, 'WAV'),
    (2, 60, 'WAV'),
    (2, 60, 'WAV'),
    (2, 60, 'WAV'),
    (2, 60, 'WAV'),
    (3, 60, 'WAV'),
    (3, 60, 'WAV'),
    (3, 60, 'WAV'),
    (3, 60, 'WAV'),
    (4, 120, 'WAV'),
    (4, 120, 'WAV'),
    (6, 60, 'WAV'),
    (6, 60, 'WAV'),
    (6, 60, 'WAV'),
    (6, 60, 'WAV'),
    (6, 60, 'WAV'),
    (7, 180, 'AIFF'),
    (7, 180, 'AIFF'),
    (7, 180, 'AIFF'),
    (7, 180, 'AIFF'),
    (7, 180, 'AIFF'),
    (7, 180, 'AIFF'),
    (7, 180, 'AIFF'),
    (7, 180, 'AIFF'),
    (7, 180, 'AIFF'),
    (8, 180, 'WAV'),
    (8, 180, 'WAV'),
    (8, 180, 'WAV'),
    (8, 180, 'WAV'),
    (8, 180, 'WAV'),
    (8, 180, 'WAV');


INSERT INTO
    Tracks(name)
VALUES
    ('5,000 Candles in the Wind'),
    ('Catch Your Dream'),
    ('May Song'),
    ('The Pit'),
    ('Remember'),
    ('The Way You Look Tonight'),
    ('Another Song');


INSERT INTO
    SegmentsInTrack(track_id, segment_id)
VALUES
    (1, 11),
    (1, 12),
    (1, 13),
    (1, 14),
    (1, 15),
    (2, 16),
    (2, 17),
    (2, 18),
    (2, 19),
    (2, 20),
    (2, 21),
    (1, 22),
    (1, 23),
    (1, 24),
    (1, 25),
    (1, 26),
    (2, 22),
    (2, 23),
    (2, 24),
    (2, 25),
    (2, 26),
    (3, 32),
    (3, 33),
    (4, 34),
    (4, 35),
    (5, 36),
    (5, 37),
    (6, 38),
    (6, 39),
    (7, 40),
    (7, 41);


INSERT INTO
    Albums(name, release_date)
VALUES
    ('The Awesome Album', '2023-05-25'),
    ('Another Awesome Album', '2023-10-29');


INSERT INTO
    TracksInAlbum(album_id, track_id)
VALUES
    (1, 1),
    (1, 2),
    (2, 3),
    (2, 4),
    (2, 5),
    (2, 6),
    (2, 7);

