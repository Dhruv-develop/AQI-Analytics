USE aqi_project;

CREATE TABLE aqi_raw (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    City          VARCHAR(100),
    Date          VARCHAR(20),          -- Keep as string to preserve raw format
    PM2_5         VARCHAR(20),          -- Use VARCHAR to catch bad entries
    PM10          VARCHAR(20),
    NO            VARCHAR(20),
    NO2           VARCHAR(20),
    NOx           VARCHAR(20),
    NH3           VARCHAR(20),
    CO            VARCHAR(20),
    SO2           VARCHAR(20),
    O3            VARCHAR(20),
    Benzene       VARCHAR(20),
    Toluene       VARCHAR(20),
    Xylene        VARCHAR(20),
    AQI           VARCHAR(20),
    AQI_Bucket    VARCHAR(50),
);

-- Problem Statement 1: Raw AQI Data Ingestion
-- Objective: Store raw air quality data safely for analysis.
-- •	Import AQI dataset into MySQL as a raw table
-- •	Validate data types and null values using SQL
-- •	Preserve raw data for audit and comparison


SELECT COUNT(*) FROM aqi_raw;

SELECT * FROM aqi_raw;

DESCRIBE aqi_raw;

SET SQL_SAFE_UPDATES = 0;

UPDATE aqi_raw
SET 
    PM2_5 = NULLIF(TRIM(PM2_5), ''),
    PM10  = NULLIF(TRIM(PM10), ''),
    NO    = NULLIF(TRIM(NO), ''),
    NO2   = NULLIF(TRIM(NO2), ''),
    NOx   = NULLIF(TRIM(NOx), ''),
    NH3   = NULLIF(TRIM(NH3), ''),
    CO    = NULLIF(TRIM(CO), ''),
    SO2   = NULLIF(TRIM(SO2), ''),
    O3    = NULLIF(TRIM(O3), ''),
    Benzene = NULLIF(TRIM(Benzene), ''),
    Toluene = NULLIF(TRIM(Toluene), ''),
    Xylene  = NULLIF(TRIM(Xylene), ''),
    AQI     = NULLIF(TRIM(AQI), ''),
    AQI_Bucket = NULLIF(TRIM(AQI_Bucket),'');
    
SELECT * FROM aqi_raw;

ALTER TABLE aqi_raw
MODIFY PM2_5   DECIMAL(10,2),
MODIFY PM10    DECIMAL(10,2),
MODIFY NO      DECIMAL(10,2),
MODIFY NO2     DECIMAL(10,2),
MODIFY NOx     DECIMAL(10,2),
MODIFY NH3     DECIMAL(10,2),
MODIFY CO      DECIMAL(10,2),
MODIFY SO2     DECIMAL(10,2),
MODIFY O3      DECIMAL(10,2),
MODIFY Benzene DECIMAL(10,2),
MODIFY Toluene DECIMAL(10,2),
MODIFY Xylene  DECIMAL(10,2),
MODIFY AQI     DECIMAL(10,2),
MODIFY Date    DATE;

DESCRIBE aqi_raw;

SELECT city,date,count(*) as duplicate_count
FROM aqi_raw 
GROUP BY city,date
HAVING duplicate_count>1;

SELECT * FROM aqi_cleaned;

DESCRIBE aqi_cleaned;

ALTER TABLE aqi_cleaned
MODIFY Date DATE;

SET SQL_SAFE_UPDATES = 0;

UPDATE aqi_cleaned
SET 
    PM_Ratio = ROUND(PM_Ratio, 4),
    NO2_NOx_Ratio = ROUND(NO2_NOx_Ratio, 4),
    CO_O3_Ratio = ROUND(CO_O3_Ratio, 4),
    SO2_NO2_Ratio = ROUND(SO2_NO2_Ratio, 4);
    

-- Problem Statement 5: Advanced SQL Analytics on Cleaned Data
-- Objective: Generate insights using SQL-only analysis.
-- Use cleaned tables to perform:
-- •	Joins:
-- o	Join AQI data with derived city/month tables

SELECT 
    a.City,
    a.Date,
    a.AQI,
    a.Month,
    a.Year,
    a.Monthly_AQI
FROM aqi_cleaned AS a; 
-- JOIN (
--     SELECT 
--         City,
--         Year,
--         Month,
--         -- ROUND(AVG(AQI),2) AS Monthly_AQI, 
--         Monthly_AQI
--     FROM aqi_cleaned
--     -- GROUP BY City, Year, Month 
-- ) m
-- ON a.City = m.City 
-- AND a.Year = m.Year 
-- AND a.Month = m.Month;



-- •	Subqueries:
-- o	Identify cities with AQI above national average
SELECT AVG(AQI) FROM aqi_cleaned;
SELECT City, ROUND(AVG(AQI),2) AS City_AQI
FROM aqi_cleaned
GROUP BY City
HAVING AVG(AQI) > (
    SELECT AVG(AQI) FROM aqi_cleaned
);




-- •	Window Functions:
-- o	Rank cities by AQI within each year
SELECT 
    City,
    YEAR(Date) AS Year,
    AVG(AQI) AS Avg_AQI,
    RANK() OVER (PARTITION BY YEAR(Date) ORDER BY AVG(AQI) DESC) AS Rank_in_Year
FROM aqi_cleaned
GROUP BY City, YEAR(Date);

-- o	Compute moving average AQI per city

SELECT 
    City,
    Date,
    AQI,
    AVG(AQI) OVER (
        PARTITION BY City
        ORDER BY Date
    ) AS Moving_Avg_AQI
FROM aqi_cleaned;


-- •	DQL & DML:
-- o	Maintain summary tables

CREATE TABLE IF NOT EXISTS aqi_city_summary (
    City           VARCHAR(100) PRIMARY KEY,
    Avg_AQI        FLOAT,
    Max_AQI        FLOAT,
    Min_AQI        FLOAT,
    Dominant_Bucket VARCHAR(50),
    Total_Days     INT
);

INSERT INTO aqi_city_summary
SELECT
    City,
    ROUND(AVG(AQI), 2),
    MAX(AQI),
    MIN(AQI),
    -- Most frequent AQI bucket
    (SELECT AQI_Bucket
     FROM aqi_cleaned c2
     WHERE c2.City = c1.City AND AQI_Bucket IS NOT NULL
     GROUP BY AQI_Bucket ORDER BY COUNT(*) DESC LIMIT 1),
    COUNT(DISTINCT Date)
FROM aqi_cleaned c1
GROUP BY City;
    
    
    
SELECT * FROM aqi_city_summary;
