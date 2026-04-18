---USER_PROFILE TABLE AND LEFT JOIN QUERIES

---1. Return the entire table

Select *
from `workspace`.`default`.`user_profile`
limit 100;

---2. Select Unique records- To clean duplicates

Select DISTINCT
        USERID, 
        Gender, 
        Race,
        Age,
        Province
from `workspace`.`default`.`user_profile`
limit 100;

---3. Join the user-profile table on viewership table and convert UTC to SAST(+ 2hours) using a left join

SELECT 
    up.UserID,
    up.province,
    up.age,
      -- Step 1: Convert UTC to SAST (+2 hours)
    TO_TIMESTAMP(v.RecordDate2, 'M/d/yyyy H:mm') + INTERVAL '2 hours' AS session_start_sast,
    v.Channel2,
    v.`duration 2`,
    -- Step 2: Create time-based factors for the CVM team
    EXTRACT(HOUR FROM (TO_TIMESTAMP(v.RecordDate2, 'M/d/yyyy H:mm') + INTERVAL '2 hours')) AS hour_of_day,
    TRIM(TO_CHAR(TO_TIMESTAMP(v.RecordDate2, 'M/d/yyyy H:mm') + INTERVAL '2 hours', 'Day')) AS day_of_week
FROM `workspace`.`default`.`user_profile` AS up
LEFT JOIN `workspace`.`default`.`viewership` As v
    ON up.UserID = v.UserID0
-- Sorting by most recent activity for the CEO dashboard
ORDER BY session_start_sast DESC;

---4. Calculate the total viewership per province using a left join

SELECT 
    COALESCE(NULLIF(Province, ''), 'Unknown') AS Province,
    COUNT(DISTINCT up.UserID) AS total_subscribers,
    COUNT(v.Channel2) AS total_sessions,
    COUNT(v.UserID0) AS total_views,
    ROUND((SUM(UNIX_TIMESTAMP(v.`duration 2`)) / 3600.0) / NULLIF(COUNT(DISTINCT up.UserID), 0), 2) AS avg_hours_per_user
FROM `workspace`.`default`.`user_profile` AS up
LEFT JOIN `workspace`.`default`.`viewership` AS v
    ON up.UserID = v.UserID0
GROUP BY up.Province
ORDER BY total_views DESC;

---5. Checking viewership by race and gender using a left join

SELECT 
    COALESCE(NULLIF(up.Race, ''), 'unknown') AS Race,
    COALESCE(NULLIF(up.Gender, ''), 'unknown') AS Gender,
    COUNT(DISTINCT up.UserID) AS total_users,
    COUNT(v.Channel2) AS total_sessions,
    COUNT(v.UserID0) AS total_views
FROM `workspace`.`default`.`user_profile` AS up
LEFT JOIN `workspace`.`default`.`viewership` AS v
    ON up.UserID = v.UserID0
GROUP BY COALESCE(NULLIF(up.Race, ''), 'unknown'),
        COALESCE(NULLIF(up.Gender, ''), 'unknown')
ORDER BY Race ASC, total_views DESC;

---6. Checking the top 10 most successful channels a viewer watch and how long does a user stay per play using a left join

SELECT 
    v.Channel2,
    COUNT(DISTINCT v.UserID0) AS unique_viewers,
    COUNT(v.UserID0) AS total_plays,
    ROUND(SUM(UNIX_TIMESTAMP(v.`duration 2`)) / 3600.0, 2) AS total_hours_watched,
    -- Retention metric: How long does a user stay per play?
    ROUND(AVG(UNIX_TIMESTAMP(v.`duration 2`)) / 60.0, 2) AS avg_engagement_mins
FROM  `workspace`.`default`.`user_profile` AS up
left join `workspace`.`default`.`viewership` AS v
on up.UserID=v.UserID0 
GROUP BY v.Channel2
ORDER BY total_hours_watched DESC
LIMIT 10;

---7. Checking the usage by age cohort or Users into age-based group buckets using a left join 

SELECT 
    CASE 
        WHEN up.age < 18 THEN 'Under 18 (kids)'
        WHEN up.age BETWEEN 18 AND 24 THEN '18-24 (Youth)'
        WHEN up.age BETWEEN 25 AND 34 THEN '25-34 (young adult)'
        WHEN up.age BETWEEN 35 AND 44 THEN '35-44 (Adult)'
        WHEN up.age BETWEEN 45 AND 54 THEN '45-54 (Midlife)'
        ELSE '55+ (Seniors)'
    END AS age_cohort,
    COUNT(DISTINCT up.UserID) AS total_users,
    COUNT(v.UserID0) AS total_sessions,
    -- Normalized metric: Hours watched per user in this group
    ROUND((SUM(UNIX_TIMESTAMP(v.`duration 2`)) / 3600.0) / NULLIF(COUNT(DISTINCT up.UserID), 0), 2) AS avg_hours_per_user,
    -- Engagement metric: Length of a single sitting
    ROUND(AVG(UNIX_TIMESTAMP(v.`duration 2`)) / 60.0, 2) AS avg_session_duration_mins
FROM `workspace`.`default`.`user_profile` AS up
LEFT JOIN `workspace`.`default`.`viewership` AS v
    ON up.UserID = v.UserID0
GROUP BY age
ORDER BY avg_hours_per_user DESC;

--- VIEWERSHIP TABLE QUERIES

---1. Return the entire table from the Viewership table

select * 
from `workspace`.`default`.`viewership` 
limit 100;

---2. Select unique record- to clean duplicates

select Distinct
        UserID0,
        Channel2,
        RecordDate2,
        `Duration 2`
from `workspace`.`default`.`viewership` 
limit 100;

---3. Checking the daily viewer trends

SELECT 
    -- Convert UTC to South African Time and truncate to Date
    DATE(TO_TIMESTAMP(v.RecordDate2, 'M/d/yyyy H:mm') + INTERVAL '2 hours') AS sa_date,
    -- Extract Day Name to identify "Low Consumption" days
    TO_CHAR(TO_TIMESTAMP(v.RecordDate2, 'M/d/yyyy H:mm') + INTERVAL '2 hours', 'Day') AS day_name,
    COUNT(DISTINCT v.UserID0) AS daily_active_users,
    COUNT(v.Channel2) AS total_sessions,
    ROUND(SUM(UNIX_TIMESTAMP(v.`Duration 2`)) / 3600.0, 2) AS total_hours_watched,
    -- Average engagement per user on that day
    ROUND((SUM(UNIX_TIMESTAMP(v.`Duration 2`)) / 3600.0) / NULLIF(COUNT(DISTINCT v.UserID0), 0), 2) AS hours_per_user
FROM `workspace`.`default`.`viewership` AS v
GROUP BY 1, 2
ORDER BY 1 ASC;

