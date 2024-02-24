game_analysis_result
select * 
from game_analysis.player_details pd
join game_analysis.level_details2 ld
on pd.P_ID = ld.P_ID;

-- Q1) Extract P_ID,Dev_ID,PName and Difficulty_level of all players 
-- at level 0

select pd.P_ID,ld.Dev_ID,pd.PName, ld.Difficulty
from game_analysis.player_details pd
join game_analysis.level_details2 ld
on pd.P_ID = ld.P_ID
where ld.level = 0;

-- Q2) Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast
--    3 stages are crossed

select pd.L1_Code , avg(ld.Kill_Count)
from game_analysis.player_details pd
join game_analysis.level_details2 ld
on pd.P_ID = ld.P_ID
where ld.Lives_Earned = 2 and ld.Stages_crossed >=3
group by pd.L1_Code;

-- Q3) Find the total number of stages crossed at each diffuculty level
-- where for Level2 with players use zm_series devices. Arrange the result
-- in decsreasing order of total number of stages crossed.

select ld.Difficulty,count(Stages_crossed) `Total Stages Crossed`
from game_analysis.player_details pd
join game_analysis.level_details2 ld
on pd.P_ID = ld.P_ID
where ld.Dev_ID like '%zm%'
group by ld.Difficulty
order by `Total Stages Crossed` desc;


-- Q4) Extract P_ID and the total number of unique dates for those players 
-- who have played games on multiple days.
select pd.P_ID,count(distinct ld.TimeStamp) as 'Total number of unique dates'
from game_analysis.player_details pd
join game_analysis.level_details2 ld
on pd.P_ID = ld.P_ID
group by pd.P_ID
having  count(distinct ld.TimeStamp) > 1;


-- Q5) Find P_ID and level wise sum of kill_counts where kill_count
-- is greater than avg kill count for the Medium difficulty.

select pd.P_ID,ld.Difficulty,sum(ld.Kill_Count) as 'sum of kill counts'
from game_analysis.player_details pd
join game_analysis.level_details2 ld
on pd.P_ID = ld.P_ID
join(
		select avg(Kill_Count) as avg_kill_count
        from game_analysis.level_details2 as ld
        where ld.Difficulty = 'Medium'
        ) as avg_kill
where ld.kill_count > avg_kill.avg_kill_count
group by pd.P_ID,ld.Difficulty;

-- Q6)  Find Level and its corresponding Level code wise sum of lives earned 
-- excluding level 0. Arrange in asecending order of level.

select ld.Level,pd.L1_Code,pd.L2_Code,sum(ld.Lives_Earned) as 'Total lives Earned'
from game_analysis.player_details pd
join game_analysis.level_details2 ld
on pd.P_ID = ld.P_ID
where ld.Level <> 0
group by ld.Level,pd.L1_Code,pd.L2_Code
order by ld.Level;


-- Q7) Find Top 3 score based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well.


WITH RankedScores AS (
    SELECT ld.Dev_ID,
           ld.Difficulty,
           ld.Score,
           ROW_NUMBER() OVER (PARTITION BY ld.Dev_ID ORDER BY ld.Score ASC) 
           AS ranks
    FROM game_analysis.player_details as pd
    JOIN game_analysis.level_details2 as ld
    ON pd.P_ID = ld.P_ID
)
SELECT dev_id,
       score,
       difficulty
FROM RankedScores
WHERE ranks <= 3;

-- Q8) Find first_login datetime for each device id
select  ld.Dev_ID,min(ld.TimeStamp) as 'first_login datetime'
from player_details as pd
join level_details2 as ld
on pd.P_ID = ld.P_ID
group by ld.Dev_ID;

-- Q9) Find Top 5 score based on each difficulty level and Rank them in 
-- increasing order using Rank. Display dev_id as well.

WITH RankedScores AS (
    SELECT ld.Difficulty,
			ld.Score,
           RANK() OVER (PARTITION BY ld.Difficulty ORDER BY ld.Score asc,ld.Difficulty asc) AS ranks
    FROM game_analysis.player_details as pd
    join game_analysis.level_details2 as ld
    on pd.P_ID = ld.P_ID
)
SELECT difficulty,score
FROM RankedScores
WHERE ranks <= 5;

-- Q10) Find the device ID that is first logged in(based on start_datetime) 
-- for each player(p_id). Output should contain player id, device id and 
-- first login datetime.

SELECT 
    t1.P_ID,
    Dev_ID,
    TimeStamp AS first_login_datetime
FROM 
    level_details2 t1
JOIN (
    -- Subquery to find the earliest start_datetime for each player
    SELECT 
        ld.P_ID,
        MIN(TimeStamp) AS first_login
    FROM 
        level_details2 as ld
    GROUP BY 
        P_ID
) t2 ON t1.P_ID = t2.P_ID AND t1.TimeStamp = t2.first_login;


-- Q11) For each player and date, how many kill_count played so far by the player. That is, the total number of games played 
-- by the player until that date.
-- a) window function

SELECT 
    pd.PName, 
    ld.TimeStamp, 
    SUM(ld.Kill_Count) OVER (PARTITION BY pd.P_ID ORDER BY ld.TimeStamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as games_played_so_far
FROM 
    player_details as pd
JOIN 
    level_details2 as ld ON pd.P_ID = ld.P_ID
ORDER BY 
    pd.P_ID, 
    ld.TimeStamp;

-- b) without window function

SELECT 
    pd.PName, 
    ld.TimeStamp, 
    (SELECT SUM(kill_count) FROM level_details2 as ld2 WHERE ld2.P_ID = ld.P_ID AND ld2.TimeStamp <= ld.TimeStamp) as games_played_so_far
FROM 
    player_details as pd
JOIN 
    level_details2 as ld ON pd.P_ID = ld.P_ID
ORDER BY 
    pd.PName, 
    ld.TimeStamp;
    
    
-- Q12) Find the cumulative sum of stages crossed over a start_datetime 

SELECT 
	pd.P_ID, 
    ld.TimeStamp as start_datetime, 
    (SELECT SUM(ld2.Stages_crossed) FROM level_details2 as ld2 WHERE ld2.P_ID = ld.P_ID AND ld2.TimeStamp <= ld.TimeStamp)
    as cumulative_stages_crossed
FROM 
    player_details as pd
JOIN 
    level_details2 as ld ON pd.P_ID = ld.P_ID
ORDER BY 
    pd.P_ID, 
    ld.TimeStamp;
    
 -- 12) Find the cumulative sum of an stages crossed over a start_datetime 
-- for each player id but exclude the most recent start_datetime   

    SELECT 
    pd.P_ID, 
    ld.TimeStamp, 
    (SELECT SUM(ld2.stages_crossed) FROM level_details2 as ld2 WHERE ld2.P_ID = ld.P_ID AND ld2.timestamp < ld.timestamp) 
    as cumulative_stages_crossed
FROM 
    player_details as pd
JOIN 
    level_details2 as ld ON pd.P_ID = ld.P_ID
WHERE 
    ld.TimeStamp < (SELECT MAX(ld3.TimeStamp) FROM level_details2 as ld3 WHERE ld3.P_ID = ld.P_ID)
ORDER BY 
    pd.P_ID, 
    ld.TimeStamp;
    
    
-- Q14) Extract top 3 highest sum of score for each device id and the corresponding player_id
    
	SELECT 
    Dev_ID,
    P_ID, 
    total_score
FROM 
    (
        SELECT 
           ld.Dev_ID,
            pd.P_ID, 
            SUM(ld.Score) as total_score, 
            ROW_NUMBER() OVER (PARTITION BY ld.Dev_ID ORDER BY SUM(ld.Score) DESC) as ranks
        FROM 
            player_details as pd
        JOIN 
            level_details2 as ld ON pd.P_ID = ld.P_ID
        GROUP BY 
            ld.Dev_ID, 
            pd.P_ID
    ) as tmp
WHERE 
    ranks <= 3
ORDER BY 
    tmp.Dev_ID ,
	total_score DESC;


-- 15) Find players who scored more than 50% of the avg score scored by sum of 
-- scores for each player_id
SELECT 
    pd.PName
FROM 
    player_details as  pd
WHERE 
    pd.P_ID IN (
        SELECT 
            ld.P_ID
        FROM 
            level_details2 as ld
        GROUP BY 
            ld.P_ID
        HAVING 
            SUM(ld.Score) > (
                SELECT 
                    0.5 * AVG(score_sum)
                FROM 
                    (
                        SELECT 
                            P_ID, 
                            SUM(score) as score_sum
                        FROM 
                            level_details2
                            GROUP BY 
                            P_ID
                    ) subquery
            )
    );
    
    
-- Q16) Create a stored procedure to find top n headshots_count based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well.

DELIMITER //
CREATE PROCEDURE GetTopNHeadshots(IN N INT)
BEGIN
    SELECT 
        Dev_ID, 
        P_ID, 
        Headshots_Count, 
        Difficulty,
        @row_number:=CASE
            WHEN @Dev_ID = Dev_ID THEN @row_number + 1
            ELSE 1
        END AS Ranks,
        @Dev_ID:=Dev_ID AS Clr_dev_id
    FROM 
        (
            SELECT 
                Dev_ID, 
                pd.P_ID, 
                ld.Headshots_Count, 
                ld.Difficulty
            FROM 
                game_analysis.player_details as pd
            JOIN 
                game_analysis.level_details2 as ld ON pd.P_ID = ld.P_ID
            ORDER BY 
                Dev_ID, 
                ld.Headshots_Count DESC
        )as tmp, (SELECT @Dev_ID:=0, @row_number:=0) r
    HAVING 
        Ranks <= N;
END //
DELIMITER ;

-- Call the stored procedure with N=5
CALL GetTopNHeadshots(5);



-- Q17) Create a function to return sum of Score for a given player_id.

drop function if exists GetTotalScore;
DELIMITER //
CREATE FUNCTION GetTotalScore(unique_P_ID INT)
RETURNS INT DETERMINISTIC
BEGIN
    DECLARE total_score INT;
    SELECT SUM(Score) INTO total_score
    FROM level_details2 
    WHERE P_ID = unique_P_ID;
    RETURN total_score;
END //
DELIMITER ;

SELECT GetTotalScore(558);
