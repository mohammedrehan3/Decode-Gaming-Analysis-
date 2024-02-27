-- TASK 2 GAMING ANALYSIS --



--1. Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0 --

--Solution--

SELECT PLAYER_DETAILS.P_ID,LEVEL_DETAILS.Dev_ID,PLAYER_DETAILS.PName,LEVEL_DETAILS.Level,LEVEL_DETAILS.Difficulty 
from LEVEL_DETAILS,PLAYER_DETAILS
WHERE LEVEL=0





--2. Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 stages are crossed --

--Solution--

SELECT PLAYER_DETAILS.L1_Code,AVG(Kill_Count) as Avg_killCount,LEVEL_DETAILS.Lives_Earned
FROM PLAYER_DETAILS,LEVEL_DETAILS
WHERE Lives_Earned=2
GROUP BY L1_Code,Lives_Earned
HAVING COUNT(Stages_crossed) >=3




-- 3. Find the total number of stages crossed at each difficulty level for Level 2 with players
--using `zm_series` devices. Arrange the result in decreasing order of the total number of stages crossed --

-- solution--

SELECT LEVEL_DETAILS.Dev_ID,LEVEL_DETAILS.Level,SUM(Stages_crossed) AS Totalstagescrossed
FROM LEVEL_DETAILS
WHERE LEVEL_DETAILS.Level=2 and LEVEL_DETAILS.Dev_ID LIKE 'zm%'
GROUP BY LEVEL_DETAILS.Dev_ID,LEVEL_DETAILS.Level
ORDER BY SUM(stages_crossed) DESC






--4. Extract `P_ID` and the total number of unique dates for those players who have played
 --games on multiple days --

 --solution--

 SELECT LEVEL_DETAILS.P_ID,COUNT(DISTINCT CONVERT (date, start_datetime)) AS UNIQUE_DATES
 FROM LEVEL_DETAILS
 GROUP BY P_ID
 HAVING COUNT(DISTINCT CONVERT (date, start_datetime))>1

 


 --5. Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the
 --average kill count for Medium difficulty.--

 --Solution--

SELECT LEVEL_DETAILS.P_ID, LEVEL_DETAILS.Level, SUM(kill_count) AS Total_Kill_Count
FROM LEVEL_DETAILS 
JOIN (
    SELECT AVG(kill_count) AS Avg_Kill_Count
    FROM LEVEL_DETAILS
    WHERE Difficulty = 'Medium'
) AS AvgKillCounts ON kill_count > AvgKillCounts.Avg_Kill_Count
GROUP BY LEVEL_DETAILS.P_ID, LEVEL_DETAILS.Level;


 

-- 6. Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level 0
--Arrange in ascending order of level.--

--Solution--


SELECT LEVEL_DETAILS.Level,SUM(Lives_Earned) as Count_lives,PLAYER_DETAILS.L1_Code,PLAYER_DETAILS.L2_Code
FROM LEVEL_DETAILS,PLAYER_DETAILS
WHERE LEVEL_DETAILS.Level <>0
GROUP BY PLAYER_DETAILS.L1_Code,PLAYER_DETAILS.L2_Code,LEVEL_DETAILS.Level
ORDER BY LEVEL_DETAILS.Level DESC




--7. Find the top 3 scores based on each `Dev_ID` and rank them in increasing order 
-- using Row_Number`. Display the difficulty as well --

WITH RankedScores AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Score ASC) AS Rank
    FROM LEVEL_DETAILS
)
SELECT Dev_ID, Score, Difficulty
FROM RankedScores
WHERE Rank <= 3;




-- 8. Find the `first_login` datetime for each device ID --

--Solution--

SELECT Dev_ID, MIN(start_datetime) AS First_Login_DateTime
FROM LEVEL_DETAILS
GROUP BY Dev_ID;



--9.Find the top 5 scores based on each difficulty level and rank them in increasing order
--using `Rank`. Display `Dev_ID` as well.

-- Solution --

WITH RankedScores AS (
    SELECT Dev_ID, Difficulty,Score,
           RANK() OVER (PARTITION BY Difficulty ORDER BY Score ASC) AS Rank
    FROM LEVEL_DETAILS
)
SELECT Dev_ID, Difficulty,Score, Rank
FROM RankedScores
WHERE Rank <= 5;




--10. Find the device ID that is first logged in (based on `start_datetime`) for each player(`P_ID`). 
--Output should contain player ID, device ID, and first login datetime.

--Solution--

SELECT LEVEL_DETAILS.P_ID, LEVEL_DETAILS.Dev_ID, LEVEL_DETAILS.start_datetime AS First_Login_DateTime
FROM LEVEL_DETAILS 
INNER JOIN (
    SELECT P_ID, MIN(start_datetime) AS Min_Start_DateTime
    FROM LEVEL_DETAILS
    GROUP BY P_ID
) AS MinDates ON LEVEL_DETAILS.P_ID = MinDates.P_ID AND LEVEL_DETAILS.start_datetime = MinDates.Min_Start_DateTime;






--11.For each player and date, determine how many `kill_counts` were played by the playerso far.

--Solutions--

--a) Using window functions

SELECT P_ID, start_datetime, 
       SUM(kill_count) OVER (PARTITION BY P_ID ORDER BY start_datetime) AS Total_Kill_Count
FROM LEVEL_DETAILS



--b) Without window functions

SELECT ld1.P_ID, ld1.start_datetime, 
       SUM(ld2.kill_count) AS Total_Kill_Count
FROM LEVEL_DETAILS ld1
JOIN LEVEL_DETAILS ld2 ON ld1.P_ID = ld2.P_ID AND ld1.start_datetime >= ld2.start_datetime
GROUP BY ld1.P_ID, ld1.start_datetime





--12. Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`,
--excluding the most recent `start_datetime`.

--Solution--

SELECT P_ID, start_datetime, 
       SUM(Stages_Crossed) OVER (PARTITION BY P_ID ORDER BY start_datetime) AS Cumulative_Stages_Crossed
FROM (
    SELECT P_ID, start_datetime, Stages_Crossed,
           ROW_NUMBER() OVER (PARTITION BY P_ID ORDER BY start_datetime DESC) AS rn
    FROM LEVEL_DETAILS
) AS sub
WHERE rn > 1;




--13. Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.

--Solution --

WITH RankedScores AS (
    SELECT P_ID, Dev_ID, SUM(Score) AS Total_Score,
           ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY SUM(Score) DESC) AS Rank
    FROM LEVEL_DETAILS
    GROUP BY P_ID, Dev_ID
)
SELECT P_ID, Dev_ID, Total_Score
FROM RankedScores
WHERE Rank <= 3;












--14. Find players who scored more than 50% of the average score, scored by the sum of
--scores for each `P_ID`.

--Solution--


WITH PlayerScores AS (
    SELECT P_ID, SUM(Score) AS Total_Score
    FROM LEVEL_DETAILS
    GROUP BY P_ID
)
SELECT P_ID, Total_Score
FROM PlayerScores
WHERE Total_Score > (
    SELECT 0.5 * AVG(Total_Score)
    FROM PlayerScores
);




--15. Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID`
---and rank them in increasing order using `Row_Number`. Display the difficulty as well.

--Solution--

CREATE PROCEDURE GetTopHeadshotsCount
    @n INT
AS
BEGIN
    SET NOCOUNT ON;

    WITH RankedHeadshots AS (
        SELECT Dev_ID, Difficulty, Headshots_count,
               ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Headshots_count ASC) AS Rank
        FROM LEVEL_DETAILS
    )
    SELECT Dev_ID, Difficulty, Headshots_count, Rank
    FROM RankedHeadshots
    WHERE Rank <= @n;
END;

EXEC GetTopHeadshotsCount @n = 2;



---end---
