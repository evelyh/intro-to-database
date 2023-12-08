
-- Did not:
-- 1. "Each session has at least one recording engineer, and at most 3"
-- 2. "A track appears on at least one album"
-- 3. "An album containes as least two tracks"
-- These three constraints were not enforced since we do not want null values in our tables, 
-- we split these One-to-N relationship and record one membership per row.
-- 4. We did not record the participation of band in a session, instead just record the 
-- participation of a single performer. Band participation information can be done by query.

-- Assumptions:
-- 1. We assumed Duke Silver is a performer and manager Tom Haverford also plays
-- since these information was not specified


DROP SCHEMA IF EXISTS recording CASCADE;
CREATE SCHEMA recording;
SET SEARCH_PATH TO recording;


-- The relation "Studios" contains three attributes:
-- 'studio_id' is an integer representing the unique identifier for each studio.
-- 'name' is a string representing the name of the studio.
-- 'address' is a string representing the address of the studio.

CREATE TABLE Studios (
    studio_id SERIAL PRIMARY KEY,
    name varchar(25) NOT NULL,
    address varchar(50) NOT NULL
);


-- Define a new data type: 'usertype', it can only
-- have 4 values that corresponds to a job position.
-- The job positions are:
-- Recording Engineer, Performer, Manager, or N/A
-- if we know nothing about the user.

CREATE TYPE usertype AS ENUM (
    'recordingEngineer', 'performer', 'manager');


-- The relation "People" contains 5 attributes:
-- 'person_id' is an integer representing the unique identifier for each person.
-- 'name' is a string representing the full name of a person.
-- 'email' is a string representing the person's email address.
-- 'phone' is a string representing the person's phone number.
-- 'type' is a string representing the person's main job position.
-- Note: one person can have multiple roles but not recorded here.
-- Each row represents the necessary information about all people in the DB.
-- (i.e. management, bands, sound engineers).

CREATE TABLE People (
    person_id integer PRIMARY KEY,
    name varchar(20) NOT NULL,
    email varchar(30) NOT NULL,
    phone varchar(15) NOT NULL,
    type usertype NOT NULL
);


-- The relation "Certificates" contains 3 attributes:
-- 'certificate_id' is an integer that represents 
-- the unique identifier for each certificate.
-- 'name' is a string that represents the code of the certificate.
-- 'organization' is a string that represents the institute issuing the certificate.

CREATE TABLE Certificates (
    certificate_id SERIAL PRIMARY KEY,
    name varchar(25) NOT NULL,
    organization varchar(25) NOT NULL
);


-- The relation "CertifiedEngineers" contains 3 attributes:
-- 'enginner_id' refers to a person in the 'People' relation who is a recording engineer.
-- 'certificate_id' refers to a certificate in the 'Certificates' relation.
-- Each row represents a recording engineer who has recieved a certificate.

CREATE TABLE CertifiedEngineers (
    engineer_id integer REFERENCES People(person_id) ON DELETE CASCADE,
    certificate_id integer REFERENCES Certificates ON DELETE CASCADE,
    PRIMARY KEY(engineer_id, certificate_id)
);


-- The relation "Bands" contains 2 attributes:
-- 'band_id' is an integer that represents the unique identifier of the band.
-- 'name' is a string that represents the name of the band.

CREATE TABLE Bands(
    band_id SERIAL PRIMARY KEY,
    name varchar(25) NOT NULL
);


-- The relation "BandMembership" contains 4 attributes:
-- 'band_id' refers to a band in the 'Bands' relation.
-- 'member_id' refers to a person in the 'People' relation who is a performer.
-- 'role' is a string that represents a member's role in the band.
-- Note that role could be "guitarist", "bass", "vocalist", "drummer", etc.

CREATE TABLE BandMembership (
    band_id integer REFERENCES Bands ON DELETE CASCADE,
    member_id integer REFERENCES People(person_id) ON DELETE CASCADE,
    role varchar(25) NOT NULL,
    PRIMARY KEY(band_id, member_id)
);


-- The relation "Manages" contains 5 attributes:
-- 'studio_id' refers to a studio in the "Studios" relation.
-- 'manager_id' refers to a person in the "People" relation who is a mamager.
-- 'start_date' represents the date that a manager starts managing a studio.
-- 'end_date' represents the date that a manager stops managing a studio.
-- Note that 'end_date' for a current manager would be NULL.

CREATE TABLE Manages (
    studio_id integer REFERENCES Studios ON DELETE CASCADE,
    manager_id integer REFERENCES People(person_id) ON DELETE CASCADE,
    start_date date NOT NULL,
    end_date date,
    PRIMARY KEY (studio_id, manager_id, start_date)
);


-- Defining a type "positiveFloat" representing
-- the fee that a band pays for a studio recording session.

CREATE DOMAIN positiveFloat AS real
    DEFAULT NULL
    CHECK (VALUE > 0.0);


-- The relation "RecordSessions" contains 5 attributes:
-- 'session_id' is a integer that uniquely identifies a recording session.
-- 'studio_id' refers to a studio in the "Studios" relation.
-- 'start_time" represents the time that the session started.
-- 'end_time" represents the time that the session ended.
-- 'fee' represents the fee that the band paid for the recording session.

CREATE TABLE RecordSessions (
    session_id SERIAL PRIMARY KEY,
    studio_id integer REFERENCES Studios ON DELETE CASCADE,
    start_time timestamp NOT NULL,
    end_time timestamp NOT NULL,
    fee positiveFloat NOT NULL
);


-- The relation "EngineerInSession" contains 3 attributes:
-- 'session_id' refers to a recording session in the "RecordSessions" relation.
-- 'engineer_id' refers to the recording engineer for a session.

CREATE TABLE EngineersInSession (
    session_id integer REFERENCES RecordSessions ON DELETE CASCADE,
    engineer_id integer REFERENCES People(person_id) ON DELETE CASCADE,
    PRIMARY KEY (session_id, engineer_id)
);


-- The relation "PerformerInSession" contains 3 attributes:
-- 'session_id' refers to a recording session in the "RecordSessions" relation.
-- 'performer_id' refers to a person in the "People" relation who plays in a session.

CREATE TABLE PerformersInSession (
    session_id integer REFERENCES RecordSessions ON DELETE CASCADE,
    performer_id integer REFERENCES People(person_id) ON DELETE CASCADE,
    PRIMARY KEY (session_id, performer_id)
);


-- The relation "RecordSegments" contains 3 attributes:
-- 'segment_id' is an integer that uniquely identifies the recorded segment.
-- 'session_id' refers to a recording session in the "RecordSessions" relation.
-- 'length' is an integer that represents the duration of the segment, in seconds.
-- 'format' is a string that represents the format that the segment 
-- is recorded in (i.e. WAV, MP4, AIFF, etc.)
-- Note that if a session has no recorded segment, there will be no entries
-- of the 'session_id' above.

CREATE TABLE RecordSegments (
    segment_id SERIAL PRIMARY KEY,
    session_id integer REFERENCES RecordSessions ON DELETE CASCADE,
    length integer NOT NULL,
    format varchar(10) NOT NULL
);


-- The relation "Tracks" contains 2 attributes:
-- 'track_id' is an integer that uniquely identifies the track.
-- 'name' is a string that represents the name of the track.

CREATE TABLE Tracks (
    track_id SERIAL PRIMARY KEY,
    name varchar(25) NOT NULL
);


-- The relation "SegmentsInTrack" contains 3 attributes:
-- 'track_id' refers to a track in the "Tracks" relation.
-- 'segment_id' refers to a recording segment in the "RecordSegments" relation.
-- Each row of this relation represents which segments belong to each track.

CREATE TABLE SegmentsInTrack (
    track_id integer REFERENCES Tracks ON DELETE CASCADE,
    segment_id integer REFERENCES RecordSegments ON DELETE CASCADE,
    PRIMARY KEY (track_id, segment_id)
);


-- The relation "Albums" contains 3 attributes:
-- 'album_id' is an integer that uniquely identifies the album.
-- 'name' is a string that represents the name of the album.
-- 'release_date' is the date that the album is released.

CREATE TABLE Albums (
    album_id SERIAL PRIMARY KEY,
    name varchar(25) NOT NULL,
    release_date date NOT NULL
);


-- The relation "TracksInAlbum" contains 2 attributes:
-- 'album_id' refers to an album in the "Albums" relation.
-- 'track_id' refers to a track in the "Tracks" relation.
-- Each row of this relation represents which tracks belong to each album.

CREATE TABLE TracksInAlbum (
    album_id integer REFERENCES Albums ON DELETE CASCADE,
    track_id integer REFERENCES Tracks ON DELETE CASCADE,
    PRIMARY KEY (album_id, track_id)
);