CREATE TABLE Users (
user_id SERIAL PRIMARY KEY,
username VARCHAR(50) NOT NULL,
age INTEGER,
gender VARCHAR(10)
);

CREATE TABLE Reactions (
reaction_id SERIAL PRIMARY KEY,
user_id INTEGER REFERENCES Users(user_id),
target_user_id INTEGER REFERENCES Users(user_id),
reaction_type VARCHAR(10) CHECK (reaction_type IN ('like', 'dislike'))
);

CREATE TABLE Meetings (
meeting_id SERIAL PRIMARY KEY,
user1_id INTEGER REFERENCES Users(user_id),
user2_id INTEGER REFERENCES Users(user_id),
meeting_date DATE
);

CREATE OR REPLACE FUNCTION create_matching_pairs()
RETURNS VOID AS $$
BEGIN
INSERT INTO Meetings (user1_id, user2_id, meeting_date)
SELECT r1.user_id, r1.target_user_id, CURRENT_DATE
FROM Reactions r1
JOIN Reactions r2 ON r1.user_id = r2.target_user_id AND r1.target_user_id = r2.user_id
WHERE r1.reaction_type = 'like' AND r2.reaction_type = 'like'
AND NOT EXISTS (
SELECT 1
FROM Meetings m
WHERE (m.user1_id = r1.user_id AND m.user2_id = r1.target_user_id)
OR (m.user1_id = r1.target_user_id AND m.user2_id = r1.user_id)
);
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION assign_meeting_dates()
RETURNS VOID AS $$
BEGIN
WITH RankedMeetings AS (
SELECT meeting_id, ROW_NUMBER() OVER (PARTITION BY meeting_date ORDER BY meeting_id) as row_num
FROM Meetings
)
UPDATE Meetings
SET meeting_date = CURRENT_DATE + row_num - 1
FROM RankedMeetings
WHERE Meetings.meeting_id = RankedMeetings.meeting_id;
END
$$ LANGUAGE plpgsql;
