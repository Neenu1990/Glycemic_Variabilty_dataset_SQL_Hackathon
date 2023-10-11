-----------------------------------------------------------------------------------------------------------------------------------------------------
 --Numpy Ninja : SQL Hackathon October 2023                                                         --Team 17_Glucosquad
						       
				        --Glycemic Variability Dataset (Q:1-80)	
							   
-----------------------------------------------------------------------------------------------------------------------------------------------------
--1.Write a query to get a list of patients with event type of EGV and glucose (mgdl) greater than 155 .

-- Select distinct patient IDs, first names, and last names
SELECT DISTINCT
  d.patientid,
  d.firstname,
  d.lastname
FROM
  demographics AS d
JOIN
  dexcom AS dx
ON
  d.patientid = dx.patientid
JOIN
  eventtype AS et
ON
  dx.eventid = et.id
WHERE
  et.event_type = 'EGV'          -- Filter for 'EGV' events
  AND dx.glucose_value_mgdl > 155 -- Filter for glucose > 155
ORDER BY
  patientid;                      -- Order results by patient ID

-------------------------------------------------------------------------------------------------------------------------------------------------------
--2.How many patients consumed meals with at least 20 grams of protein in it?

-- Create an index named 'idx_tmp' on the 'foodlog' table to potentially optimize queries
-- involving the 'protein' and 'patientid' columns.
CREATE INDEX idx_tmp
ON foodlog(protein, patientid);

-- Calculate the count of distinct patient IDs (num_patients) from the 'foodlog' table
-- where the 'protein' value is greater than or equal to 20.
SELECT COUNT(DISTINCT f.patientid) AS num_patients
FROM foodlog AS f
WHERE f.protein >= 20;

--drop index idx_tmp;

-------------------------------------------------------------------------------------------------------------------------------------------------------
--3.Who consumed maximum calories during dinner? (assuming the dinner time is 6pm-8pm)

SELECT
  patientid,
  MAX(calorie) AS max_calorie
FROM
  foodlog
WHERE
  EXTRACT(HOUR FROM datetime) BETWEEN 18 AND 20 -- Filter for evening hours
GROUP BY
  patientid
ORDER BY
  max_calorie DESC -- Sort by maximum calorie intake in descending order
LIMIT 1; -- Retrieve the top patient

-------------------------------------------------------------------------------------------------------------------------------------------------------  
--4.Which patient showed a high level of stress on most days recorded for him/her?

SELECT
  e.patientid,            
  COUNT(*) AS high_stress_days
FROM
  eda AS e               
JOIN
  hr AS h                
ON
  e.patientid = h.patientid
WHERE
  e.mean_eda > 40        -- Filter for EDA > 40 (high stress)
  AND h.mean_hr > 100    -- Filter for HR > 100 (high stress)
GROUP BY
  e.patientid
ORDER BY
  high_stress_days DESC  -- Order by the count of high-stress days in descending order
LIMIT 1;                 -- Retrieve the patient with the highest count of high-stress days

-------------------------------------------------------------------------------------------------------------------------------------------------------   
--5.Based on mean HR and HRV alone, which patient would be considered least healthy?

-- Calculate Heart Rate Variability (HRV) and Mean Heart Rate for each patient
WITH PatientHealth AS (
    SELECT
        ibi.patientid,
        ROUND(((SUM(ibi.rmssd_ms)::numeric / COUNT(ibi.rmssd_ms)) * 600)::numeric, 2) AS hrv,
        ROUND(AVG(hr.mean_hr)::numeric, 2) AS mean_hr
    FROM
        ibi
    JOIN
        hr ON ibi.patientid = hr.patientid
    GROUP BY
        ibi.patientid
)
-- Find patients with abnormal HRV or Mean Heart Rate
SELECT
    patientid,            
    hrv,                  -- Heart Rate Variability (HRV)
    mean_hr               
FROM
    PatientHealth
WHERE
    hrv < 20 OR hrv > 200   -- Filter for abnormal HRV values
    OR mean_hr < 60 OR mean_hr > 100 -- Filter for abnormal Mean Heart Rate values
ORDER BY
    hrv ASC, mean_hr ASC -- Order by HRV and Mean Heart Rate in ascending order
LIMIT 1;                 -- Retrieve the patient with the most significant abnormalities

-------------------------------------------------------------------------------------------------------------------------------------------------------  
--6.Create a table that stores any Patient Demographics of your choice as the parent table. 
    --Create a child table that contains max_EDA and mean_HR per patient and inherits all columns from the parent table

CREATE TABLE Patient_Demographics (
   gender VARCHAR(10),
   firstname VARCHAR(100),
   lastname VARCHAR(100),
   patientid INT PRIMARY KEY,
   dob DATE,
   hba1c FLOAT
);

-- Create a table for patient statistics, inheriting the structure from Patient_Demographics and including maximum EDA (max_EDA) and mean heart rate (mean_HR).
CREATE TABLE Patient_Statistics (
   max_EDA FLOAT,
   mean_HR FLOAT
) INHERITS (Patient_Demographics);

-- Retrieve all records from the Patient_Statistics table.
SELECT * FROM Patient_Statistics;

-- Drop the Patient_Statistics table.
--DROP TABLE IF EXISTS Patient_Statistics;

-- Drop the Patient_Demographics table.
--DROP TABLE IF EXISTS Patient_Demographics;

-------------------------------------------------------------------------------------------------------------------------------------------------------   
--7.What percentage of the dataset is male vs what percentage is female?
-- Calculate gender distribution
SELECT 
  gender,  -- Gender category
  ROUND((COUNT(*)::DECIMAL / (SELECT COUNT(*) FROM demographics WHERE gender IS NOT NULL)) * 100, 2) AS percentage  -- Calculate the percentage of each gender category
FROM demographics
WHERE gender IS NOT NULL  -- Exclude NULL gender entries
GROUP BY gender;  -- Group by gender for distribution analysis

-------------------------------------------------------------------------------------------------------------------------------------------------------
--8.Which patient has the highest max eda?
-- Retrieve the patient with the highest maximum Electrodermal Activity (EDA).
SELECT 
    d.firstname,
    d.lastname,
    d.patientid,
    e.max_eda
FROM 
    demographics AS d
INNER JOIN 
    eda AS e
    ON d.patientid = e.patientid
ORDER BY
    e.max_eda DESC
LIMIT 1;

-------------------------------------------------------------------------------------------------------------------------------------------------------
--9.Display details of the prediabetic patients.
-- Retrieve patient demographics for individuals with HbA1c levels between 5.7 and 6.4.
SELECT *
FROM demographics
WHERE hba1c >= 5.7 AND hba1c <= 6.4;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
--10.List the patients that fall into the highest EDA category by name, gender and age
-- Retrieve patient demographics, age, gender, and maximum Electrodermal Activity (EDA)
-- for individuals whose average maximum EDA is equal to or greater than 10.
SELECT
    d.firstname,
    d.lastname,
    d.gender,
    EXTRACT(YEAR FROM AGE(current_date, d.dob)) AS age,
    mec.max_eda
FROM
    demographics AS d
JOIN (
    SELECT
        e.patientid,
        MAX(e.max_eda) AS max_eda
    FROM
        eda AS e
    GROUP BY
        e.patientid
    HAVING
        AVG(e.max_eda) >= 10 -- Adjust this threshold if necessary
) AS mec
ON
    d.patientid = mec.patientid
ORDER BY
    mec.max_eda DESC;

-------------------------------------------------------------------------------------------------------------------------------------------------------
--11.How many patients have names starting with 'A'?

-- Count patients with first names starting with 'A' and group by first name.
SELECT COUNT(*) AS total_patients, firstname
FROM demographics
WHERE firstname LIKE 'A%'
GROUP BY firstname;

-------------------------------------------------------------------------------------------------------------------------------------------------------
--12.Show the distribution of patients across age.

-- Count patients in different age groups and categorize them accordingly.
SELECT
    CASE
        WHEN age BETWEEN 0 AND 19 THEN '0-19'
        WHEN age BETWEEN 20 AND 39 THEN '20-39'
        WHEN age BETWEEN 40 AND 59 THEN '40-59'
        WHEN age BETWEEN 60 AND 79 THEN '60-79'
        ELSE '80+'
    END AS age_group,
    COUNT(*) AS patient_count
FROM (
    SELECT
        EXTRACT(YEAR FROM AGE(current_date, dob)) AS age
    FROM demographics
    WHERE dob IS NOT NULL  -- Exclude rows with NULL date of birth (dob)
) AS age_data
GROUP BY age_group
ORDER BY age_group;

-------------------------------------------------------------------------------------------------------------------------------------------------------
--13.Display the Date and Time in 2 seperate columns for the patient who consumed only Egg

-- Retrieve the date and time of food entries for 'Egg' consumption.
SELECT patientid, datetime::DATE as Date, datetime::TIME as Time
FROM foodlog
WHERE logged_food = 'Egg';

-------------------------------------------------------------------------------------------------------------------------------------------------------
--14.Display list of patients along with the gender and hba1c for whom the glucose value is null.

-- Identify patients with missing glucose data.
SELECT DISTINCT d.patientid, d.gender, d.hba1c
FROM demographics d
JOIN dexcom dx ON dx.patientid = d.patientid
WHERE dx.glucose_value_mgdl IS NULL;

-------------------------------------------------------------------------------------------------------------------------------------------------------
--15.Rank patients in descending order of Max blood glucose value per day

-- Rank patients based on their maximum glucose levels recorded per day.
WITH max_glucose_per_day AS (
  SELECT
    patientid,
    datestamp,
    MAX(glucose_value_mgdl) AS max_glucose
  FROM dexcom
  WHERE glucose_value_mgdl IS NOT NULL
  GROUP BY patientid, datestamp
)

SELECT
  patientid,
  MAX(datestamp) AS datestamp,
  MAX(max_glucose) AS max_glucose,
  RANK() OVER (ORDER BY MAX(max_glucose) DESC) AS glucose_rank
FROM max_glucose_per_day
GROUP BY patientid
ORDER BY max_glucose DESC;  -- Sort max_glucose in descending order

-------------------------------------------------------------------------------------------------------------------------------------------------------   
--16.Assuming the IBI per patient is for every 10 milliseconds, calculate Patient-wise HRV from RMSSD.

-- Calculate and round Heart Rate Variability (HRV) for each patient.
SELECT
   ibi.patientid,
   ROUND(((SUM(ibi.rmssd_ms)::numeric / COUNT(ibi.rmssd_ms)) * 600)::numeric, 2) AS hrv
FROM
   ibi
GROUP BY
   ibi.patientid
ORDER BY
   ibi.patientid ASC;
-----------------------------------------------------------------------------------------------------------------------------------------------------
--17.What is the % of total daily calories consumed by patient 14 after 3pm Vs Before 3pm?

-- Calculates the percent of total daily calories Using Subqueries
  SELECT
  DATE(datetime) AS log_date,
  SUM(CASE WHEN EXTRACT(HOUR FROM datetime) >= 15 THEN calorie ELSE 0 END) AS calories_after_3pm,
  SUM(CASE WHEN EXTRACT(HOUR FROM datetime) < 15 THEN calorie ELSE 0 END) AS calories_before_3pm,
  SUM(calorie) AS total_calories,
  ROUND((SUM(CASE WHEN EXTRACT(HOUR FROM datetime) >= 15 THEN calorie ELSE 0 END) / SUM(calorie)) * 100, 2) AS percentage_after_3pm,
  ROUND((SUM(CASE WHEN EXTRACT(HOUR FROM datetime) < 15 THEN calorie ELSE 0 END) / SUM(calorie)) * 100, 2) AS percentage_before_3pm
  FROM foodlog
  WHERE patientid = 14
  GROUP BY log_date
  ORDER BY log_date;
----------------------------------------------------------------------------------------------------------------------------------------------- 
--18.Display 5 random patients with HbA1c less than 6.

--This Query Randomly displays 5 patients info where hba1c < 6 
  SELECT patientid,hba1c FROM demographics 
  WHERE hba1c < 6 
  ORDER BY RANDOM() 
  LIMIT 5;
----------------------------------------------------------------------------------------------------------------------------------------------- 
--19.Generate a random series of data using any column from any table as the base */

--Firstly Deleted records if already present Then inserted data using patientid from demographics table 
--and generate_series function 
  DELETE FROM demographics 
  WHERE patientid IN (SELECT patientid FROM demographics WHERE patientid in (17,18,19,20));
  INSERT INTO demographics(patientid) VALUES (generate_series(17,20));
  SELECT * FROM demographics WHERE patientid IN (17,18,19,20);

-----------------------------------------------------------------------------------------------------------------------------------------------
--20.Display the foods consumed by the youngest patient 
  
--Used sub-query to extract the youngest age of patient from demographics table
  SELECT DISTINCT demographics.patientid,foodlog.logged_food 
  FROM foodlog JOIN demographics
  ON demographics.patientid = foodlog.patientid
  WHERE foodlog.patientid = (SELECT demographics.patientid FROM demographics 
  ORDER BY EXTRACT('YEAR' FROM AGE(CURRENT_DATE,dob)) 
  LIMIT 1);

-----------------------------------------------------------------------------------------------------------------------------------------------
--21.Identify the patients that has letter 'h' in their first name and print the last letter of their first name.

--Identified the required patients using like and RIGHT function
  SELECT patientid,firstname,RIGHT(firstname,1) AS LastLetterOfFirstname
  FROM demographics 
  WHERE firstname LIKE 'h%' 
  OR firstname LIKE '%h' 
  OR firstname LIKE '%h%';

-----------------------------------------------------------------------------------------------------------------------------------------------
--22.Calculate the time spent by each patient outside the recommended blood glucose range*/

  WITH glucose_duration AS (
  SELECT
  demographics.patientid,
  dexcom.datestamp,
  dexcom.glucose_value_mgdl,
  CASE
  WHEN dexcom.glucose_value_mgdl < 55 OR dexcom.glucose_value_mgdl > 200 THEN
  EXTRACT(EPOCH FROM (
  LEAD(dexcom.datestamp, 1, dexcom.datestamp) OVER (PARTITION BY dexcom.patientid ORDER BY dexcom.datestamp)
  - dexcom.datestamp)
  )
  ELSE
  0  
  END AS duration_outside_range_in_secs
  FROM
  demographics
  JOIN
  dexcom ON demographics.patientid = dexcom.patientid
  )
  SELECT
  patientid,
  CAST(SUM(duration_outside_range_in_secs) / 60.0 AS integer) AS time_spent_outside_range_in_minutes
  FROM
  glucose_duration
  GROUP BY
  patientid;

-----------------------------------------------------------------------------------------------------------------------------------------------
--23.Show the time in minutes recorded by the Dexcom for every patient*/

  SELECT DATE(datestamp),patientid,
  SUM(FLOOR(EXTRACT(EPOCH FROM datestamp::timestamp::time)/60)) AS TimeInMinutes
  FROM dexcom
  GROUP BY patientid,DATE(datestamp)
  ORDER BY patientid,DATE(datestamp);
 
-----------------------------------------------------------------------------------------------------------------------------------------------
--24.List all the food eaten by patient Phill Collins*/

  SELECT DISTINCT foodlog.logged_food FROM foodlog 
  JOIN demographics
  ON demographics.patientid = foodlog.patientid
  WHERE demographics.firstname = 'Phill' AND demographics.lastname = 'Collins';
  
-----------------------------------------------------------------------------------------------------------------------------------------------
--25.Create a stored procedure to delete the min_EDA column in the table EDA*/
  
--Created a dummy column and copied the values of min_EDA to dummy before deleting it.*/
--ALTER TABLE eda ADD COLUMN dummy real default 0;
--UPDATE eda
--SET dummy = min_EDA; 
  
  CREATE OR REPLACE PROCEDURE DELmin_EDA()
  language plpgsql
  AS $$
  BEGIN
  ALTER TABLE eda DROP COLUMN min_EDA; 
  END
  $$;
  
  CALL DELmin_EDA(); -- Call the procedure
  SELECT eda.min_eda FROM eda; --To check if the column min_eda got deleted

-----------------------------------------------------------------------------------------------------------------------------------------------
--26.When is the most common time of day for people to consume spinach?*/
  
-- SELECT datetime,patientid FROM foodlog WHERE logged_food= 'Spinach' 
--   Spinach is consumed three times during afternoon(12:45 - 14:00)
  
  SELECT 
  CASE
  WHEN EXTRACT(HOUR FROM datetime) >= 9 AND EXTRACT(HOUR FROM datetime) < 12 THEN 'Morning'
  WHEN EXTRACT(HOUR FROM datetime) >= 12 AND EXTRACT(HOUR FROM datetime) < 15 THEN 'Afternoon'
  WHEN EXTRACT(HOUR FROM datetime) >= 15 AND EXTRACT(HOUR FROM datetime) < 18 THEN 'Evening'
  WHEN EXTRACT(HOUR FROM datetime) >= 18 AND EXTRACT(HOUR FROM datetime) < 21 THEN 'NIGHT'
  ELSE 'LATENIGHT'
  END AS consumption_time,
  COUNT(*) AS total_consumption 
  FROM
  foodlog
  WHERE logged_food = 'Spinach'
  GROUP BY
  consumption_time
  ORDER BY
  total_consumption DESC
  LIMIT 1;
  
--Based on the above Query Afternoon is the most common time when spinach is consumed*/

-----------------------------------------------------------------------------------------------------------------------------------------------
--27.Classify each patient based on their HRV range as high, low or normal*/

--Created a CTE and used formula HRV=AVg of RMSSD per patient * 600
--to calculate HRV range */
  WITH CTE_hrv AS(
  SELECT DISTINCT(patientid),AVG(rmssd_ms)*600 AS hrv 
  FROM ibi
  GROUP BY patientid
  )
  SELECT CTE_hrv.patientid,
  (
  CASE
  WHEN CTE_hrv.hrv < 20 THEN 'HIGH'
  WHEN CTE_hrv.hrv > 20 AND  CTE_hrv.hrv < 200 THEN 'NORMAL'
  ELSE 'LOW'
  END
  ) HRVRangeStatus
  FROM CTE_hrv;

-----------------------------------------------------------------------------------------------------------------------------------------------
--28.List full name of all patients with 'an' in either their first or last names*/
 
--Combined first and last name te get full name of patients and used Like to get the result*/
  SELECT firstname||' '||lastname AS fullname 
  FROM demographics
  WHERE firstname LIKE '%an' OR firstname LIKE 'an%' OR firstname LIKE '%an%'
  OR lastname LIKE '%an' OR lastname LIKE 'an%' OR lastname LIKE '%an%';

-----------------------------------------------------------------------------------------------------------------------------------------------
--29.Display a pie chart of gender vs average HbA1c */
   
  SELECT gender,AVG(hba1c) FROM demographics
  GROUP BY gender;
-----------------------------------------------------------------------------------------------------------------------------------------------
--30.The recommended daily allowance of fiber is approximately 25 grams a day. 
--What % of this does every patient get on average?

--Calculated percent using avg() function */
  SELECT foodlog.patientid,
  FLOOR(AVG(foodlog.dietary_fiber)*100 / 25) AS PercentOfFiber
  FROM foodlog 
  GROUP BY foodlog.patientid
  ORDER BY foodlog.patientid;
  
-----------------------------------------------------------------------------------------------------------------------------------------------
--31.What is the relationship between EDA and Mean HR? */
   
--Based on the result there is weak correlation between EDA and Mean HR */
  SELECT CORR(eda.mean_eda,hr.mean_hr) AS Correlation
  FROM eda JOIN hr
  ON eda.patientid = hr.patientid;
  
-----------------------------------------------------------------------------------------------------------------------------------------------
--32.Show the patient that spent the maximum time out of blood glucose range*/
    
  SELECT DISTINCT(patientid),COUNT(glucose_value_mgdl) AS MaxTimeOutOfGlucoseRange 
  FROM dexcom 
  WHERE glucose_value_mgdl < 55 OR glucose_value_mgdl > 200
  GROUP BY patientid
  ORDER BY COUNT(glucose_value_mgdl) DESC
  LIMIT 1;
  
-----------------------------------------------------------------------------------------------------------------------------------------------------
                             
-- 33.Create a User Defined function that returns min glucose value and patient ID for any date entered.

-- It takes the target_date as input and returns a table with patient_id and min_glucose columns.
CREATE OR REPLACE FUNCTION GetMinGlucoseForDate(target_date DATE)
RETURNS TABLE (patient_id BIGINT, min_glucose REAL)
AS $$
BEGIN
    -- Query the dexcom table to find the minimum glucose value for each patient on the target date.
    RETURN QUERY (
        SELECT patientid, MIN(glucose_value_mgdl) AS min_glucose_value
        FROM dexcom
        WHERE DATE(datestamp) = target_date
        GROUP BY patientid
    );
END;
$$ LANGUAGE plpgsql;

-- Call the function with a specific date to retrieve the minimum glucose values for that date.
SELECT * FROM GetMinGlucoseForDate('2020-02-13');

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 34.Write a query to find the day of highest mean HR value for each patient and display it along with the patient id.

-- Calculate the mean HR for each patient on each highest_mean_date
WITH MeanHeartRates AS (
    SELECT
        patientid,
        datestamp AS highest_mean_date,
        mean_hr
    FROM
        hr
),
-- Rank the mean HR values in descending order for each patient
RankHighestMean AS (
    SELECT
        patientid,
        highest_mean_date,
        mean_hr,
        RANK() OVER (PARTITION BY patientid ORDER BY mean_hr DESC) AS rank
    FROM
        MeanHeartRates
)
-- Select the rows where the rank is 1 (highest mean HR) for each patient
SELECT
    patientid,
    highest_mean_date AS day_of_highest_mean_hr,
    mean_hr AS highest_mean_hr
FROM
    RankHighestMean
WHERE
    rank = 1;

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 35.Create view to store Patient ID, Date, Avg Glucose value and Patient Day to every patient, ranging from 1-11 based on every patients minimum date and maximum date (eg: Day1,Day2 for each patient)

-- Create or replace a view named PatientGlucoseView
CREATE OR REPLACE VIEW PatientGlucoseView AS
WITH PatientDateRanges AS (
    -- Step 1: Calculate the minimum and maximum dates for each patient
    SELECT
        patientid,
        MIN(DATE_TRUNC('day', datestamp)) AS min_date,
        MAX(DATE_TRUNC('day', datestamp)) AS max_date
    FROM
        dexcom
    GROUP BY
        patientid
)
SELECT
    d.patientid AS patient_id,
    d.datestamp AS date,
    CONCAT('Day', 
           FLOOR(EXTRACT(EPOCH FROM (d.datestamp - pdr.min_date)) / (60*60*24)) + 1
          ) AS patient_day,-- Calculate the patient's day based on the date
    AVG(d.glucose_value_mgdl) AS avg_glucose_value-- Calculate the average glucose value
FROM
    dexcom d
JOIN
    PatientDateRanges pdr ON d.patientid = pdr.patientid
-- Step 2: Filter date within 11 days of the minimum date
WHERE
    d.datestamp BETWEEN pdr.min_date AND (pdr.min_date + INTERVAL '10 days')
GROUP BY
    d.patientid, d.datestamp, pdr.min_date;

SELECT * FROM PatientGlucoseView ORDER BY patient_id, date;

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 36.Using width bucket functions, group patients into 4 HRV categories

-- Create a view to categorize patients based on HRV
CREATE OR REPLACE VIEW HRV_Categories AS
SELECT DISTINCT
    patientid,
    ROUND(AVG(rmssd_ms * 600)) AS hrv_value,
    width_bucket(AVG(rmssd_ms * 600), MIN(AVG(rmssd_ms * 600)) OVER (), MAX(AVG(rmssd_ms * 600)) OVER (), 3) AS hrv_category
FROM
    ibi
GROUP BY
    patientid
ORDER BY
    patientid;

SELECT * FROM HRV_Categories

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 37.Is there a correlation between High EDA and  HRV. If so, display this data by querying the relevant tables?

-- This CTE selects distinct patient IDs who have a maximum EDA value greater than 2.0
WITH HighEDA AS (
    SELECT DISTINCT e.patientid
    FROM eda e
    WHERE e.max_eda > 2.0 
)

-- Select and calculate HRV, EDA, and their correlation for patients in HighEDA
SELECT
    AVG(i.rmssd_ms * 600) AS HRV,  -- Calculate the average HRV for patients in HighEDA
    AVG(e.max_eda) AS EDA,         -- Calculate the average maximum EDA for patients in HighEDA
    CORR(i.rmssd_ms * 600, e.max_eda) AS Correlation  -- Calculate the correlation between HRV and EDA
FROM ibi i
JOIN eda e ON i.patientid = e.patientid
WHERE i.patientid IN (SELECT * FROM HighEDA);

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 38.List hypoglycemic patients by age and gender?

-- Select distinct patient names, ages, and genders of patients with hypoglycemia (glucose_value_mgdl < 70).
SELECT DISTINCT
	CONCAT(dg.firstname, ' ', dg.lastname) AS hypoglycemic_patient_name, -- Concatenate first and last names for patient name.
    DATE_PART('year', AGE(current_date, dg.dob)) AS age, -- Calculate the age based on date of birth (dob).
    dg.gender -- Gender information.
FROM
    demographics dg
JOIN
    dexcom d ON dg.patientid = d.patientid -- Join demographics and dexcom tables on patientid.
WHERE
    d.glucose_value_mgdl < 70; -- Filter for patients with glucose values less than 70 mg/dL (hypoglycemia).

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 39.Write a query using recursive view(use the given dataset only)

CREATE OR REPLACE RECURSIVE VIEW PatientGlucoseHistory(patientid,
        glucose_value_mgdl,
        datestamp) AS
WITH RECURSIVE GlucoseHistory AS (
    -- Anchor query: Select initial data from dexcom
    SELECT
        d.patientid,
        d.glucose_value_mgdl,
        d.datestamp
    FROM
        dexcom d
    UNION ALL
    -- Recursive query: Join with demographics based on patientid
    SELECT
        d.patientid,
        dglc.glucose_value_mgdl,
        d.datestamp
    FROM
        dexcom d
    INNER JOIN
        GlucoseHistory dglc ON d.patientid = dglc.patientid
)
-- Select data from the CTE joined with demographics
SELECT
    dh.patientid,
    dh.glucose_value_mgdl,
    dh.datestamp,
    dm.firstname,
    dm.lastname,
    dm.hba1c,
    dm.dob,
    dm.gender
FROM
    GlucoseHistory dh
INNER JOIN
    demographics dm ON dh.patientid = dm.patientid;
	
SELECT * FROM PatientGlucoseHistory

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 40.Create a stored procedure that adds a column to table IBI. The column should just be the date part extracted from IBI.Date

-- Create a function (stored procedure)
CREATE OR REPLACE FUNCTION AddDatePartColumnToIBI()
RETURNS VOID AS $$
BEGIN
    -- Check if the new column already exists
    IF NOT EXISTS (
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'ibi' AND column_name = 'DatePart'
    ) THEN
        -- Add the new column 'DatePart' as DATE data type
        EXECUTE 'ALTER TABLE ibi ADD COLUMN DatePart DATE';

        -- Update the 'DatePart' column with the date part extracted from the 'datestamp' column
        EXECUTE 'UPDATE ibi SET DatePart = DATE(datestamp)';

        -- Display a message indicating that the column has been added
        RAISE NOTICE 'DatePart column added to ibi table.';
    ELSE
        -- If the column already exists, do nothing and display a message indicating that
        RAISE NOTICE 'DatePart column already exists in ibi table. No action taken.';
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT AddDatePartColumnToIBI();

SELECT DATESTAMP,DATEPART FROM IBI

-- ALTER TABLE ibi DROP COLUMN IF EXISTS DatePart;

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 41.Fetch the list of Patient ID's whose sugar consumption exceeded 30 grams on a meal from FoodLog table. 

SELECT DISTINCT patientid
FROM FoodLog
WHERE Sugar > 30
ORDER BY patientid;

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 42.How many patients are celebrating their birthday this month?

-- Count the number of records in the demographics table where the date of birth matches the current month and day.
SELECT COUNT(*) -- Count the number of matching records.
FROM demographics -- From the demographics table.
WHERE
    EXTRACT(MONTH FROM dob) = EXTRACT(MONTH FROM CURRENT_DATE) -- Match the month of birth with the current month.
    AND EXTRACT(DAY FROM dob) = EXTRACT(DAY FROM CURRENT_DATE); -- Match the day of birth with the current day.


-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 43.How many different types of events were recorded in the Dexcom tables? Display counts against each Event type

-- Count and list the event types along with the count of events for each type.
SELECT
    et.event_type, -- Select the event type.
    COUNT(*) AS event_count -- Count the number of events and give it an alias 'event_count'.
FROM
    eventtype et -- From the eventtype table, which likely contains event types.
JOIN
    dexcom d ON et.id = d.eventid -- Join with the dexcom table based on event IDs.
GROUP BY
    et.event_type -- Group the results by event type.
ORDER BY
    event_count DESC; -- Order the results by event count in descending order.

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 44.How many prediabetic/diabetic patients also had a high level of stress?

-- Create a Common Table Expression (CTE) to classify patients based on HbA1c levels and determine their stress levels.
WITH PatientStatus AS (
    SELECT
        d.patientid,
        CASE
            WHEN d.hba1c >= 5.7 AND d.hba1c < 6.5 THEN 'Prediabetic' -- Prediabetic Patients
            WHEN d.hba1c >= 6.5 THEN 'Diabetic' -- Diabetic patients
            ELSE 'Normal'
        END AS diabetes_status,
        CASE
            WHEN 
			MAX(e.mean_eda) > 40 
			OR 
			MAX(h.mean_hr) > 100 
			OR AVG(i.rmssd_ms) * 600 < 20 
			THEN 'High Stress'
            ELSE 'Normal Stress'
        END AS stress_level
    FROM
        demographics d
    JOIN eda e ON d.patientid = e.patientid
    JOIN hr h ON d.patientid = h.patientid
    JOIN ibi i ON d.patientid = i.patientid
    GROUP BY
        d.patientid, d.hba1c
)
-- Query to count patients in different diabetes status categories and total stress levels.
SELECT
    COUNT(*) FILTER (WHERE diabetes_status = 'Prediabetic') AS prediabetic_count,
    COUNT(*) FILTER (WHERE diabetes_status = 'Diabetic') AS diabetic_count,
    COUNT(*) FILTER (WHERE diabetes_status IN ('Prediabetic', 'Diabetic')) AS total_count
FROM
    PatientStatus;

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 45.List the food that coincided with the time of highest blood sugar for every patient

-- Create a Common Table Expression (CTE) to find the maximum blood sugar level for each patient.
WITH MaxBloodSugar AS (
    -- Subquery to find the maximum blood sugar level for each patient
    SELECT
        d.patientid,
        MAX(dc.glucose_value_mgdl) AS max_glucose
    FROM
        demographics d
    JOIN
        dexcom dc ON d.patientid = dc.patientid
    GROUP BY
        d.patientid
)
-- Query to list the food that coincided with the time of the highest blood sugar for every patient.
SELECT
    d.patientid,
    dc.datestamp AS high_blood_sugar_time,
    fl.logged_food AS food_entry
FROM
    MaxBloodSugar m
JOIN
    dexcom dc ON m.patientid = dc.patientid 
	AND 
	m.max_glucose = dc.glucose_value_mgdl
JOIN
    demographics d 
	ON 
	m.patientid = d.patientid
JOIN
    foodlog fl 
	ON 
	m.patientid = fl.patientid 
	AND dc.datestamp = fl.datetime
ORDER BY
    m.patientid, dc.datestamp;

-- select * from DEXCOM WHERE PATIENTID=14 AND DATESTAMP='2020-06-11 18:15:00'
-- select * from foodlog WHERE PATIENTID=14 AND DATETIME='2020-06-11 18:15:00'

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 46.How many patients have first names with length >7 letters?

-- Count the number of patients whose first names are longer than 7 characters.
SELECT COUNT(*) AS patient_count -- Count and give an alias 'patient_count' to the result.
FROM demographics -- From the demographics table.
WHERE LENGTH(firstname) > 7; -- Filter for records where the length of the first name is greater than 7 characters.

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 47.List all foods logged that end with 'se'. Ensure that the output is in Title Case

-- Select distinct food items ending with 'se,' convert them to title case, and order them alphabetically.
SELECT DISTINCT
    INITCAP(logged_food) AS logged_food_in_title_case -- Convert the logged_food column to title case.
FROM 
    foodlog -- From the foodlog table.
WHERE 
    logged_food LIKE '%se' -- Filter for food items that end with 'se.'
ORDER BY 
    logged_food_in_title_case; -- Order the results in ascending order of the title-cased food names.

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 48.List the patients who had a birthday the same week as their glucose or IBI readings

-- Select distinct patient information for patients with data in dexcom or ibi tables based on week-by-week comparison.
SELECT DISTINCT
    dg.patientid, 
    dg.firstname, 
    dg.lastname, 
    dg.dob 
FROM demographics dg 
LEFT JOIN dexcom d -- Left join with the dexcom table
    ON dg.patientid = d.patientid 
    AND DATE_PART('week', dg.dob) = DATE_PART('week', d.datestamp)
LEFT JOIN ibi i -- Left join with the ibi table
    ON dg.patientid = i.patientid 
    AND DATE_PART('week', dg.dob) = DATE_PART('week', i.datestamp)
WHERE d.patientid IS NOT NULL OR i.patientid IS NOT NULL; -- Filter for patients with data in either dexcom or ibi tables.

-----------------------------------------------------------------------------------------------------------------------------------------------------

---49 Assuming breakfast is between 8 am and 11 am. How many patients ate a meal with bananas in it?
SELECT count(distinct patientid) FROM foodlog 
WHERE EXTRACT(HOUR FROM datetime) BETWEEN 8 AND 11 
AND logged_food like '%Banana%';

-----------------------------------------------------------------------------------------------------------------------------------------------------
--50 Create a User defined function that returns the age of any patient based on input

CREATE OR REPLACE FUNCTION AgeOfPatient(patientIdno bigint)
RETURNS TABLE (age interval)
AS $$
BEGIN
RETURN QUERY(
              SELECT AGE(CURRENT_DATE,dob)
              FROM demographics
	          WHERE patientid = patientIdno
              );
END;
$$ LANGUAGE plpgsql;

SELECT * FROM AgeOfPatient(1);

-----------------------------------------------------------------------------------------------------------------------------------------------------
--51 Based on Number of hyper and hypoglycemic incidents per patient, which patient has the least control over their blood sugar?

SELECT patientid
FROM dexcom
WHERE glucose_value_mgdl < 70 OR glucose_value_mgdl >= 126
GROUP BY patientid
ORDER BY COUNT(1) DESC LIMIT 1;

-----------------------------------------------------------------------------------------------------------------------------------------------------
---52 Display patients details with event details and minimum heart rate

SELECT DISTINCT d.patientid,d.gender,d.hba1c,d.dob,e.event_type
,(SELECT MIN(min_hr) FROM hr WHERE patientid=d.patientid)
FROM demographics d
JOIN dexcom dx
ON d.patientid = dx.patientid
JOIN eventtype e
ON dx.eventid = e.id
order by d.patientid;

-----------------------------------------------------------------------------------------------------------------------------------------------------
--53 Display a list of patients whose daily max_eda lies between 40 and 50.

SELECT distinct patientid
FROM eda
WHERE max_eda BETWEEN 40 AND 50;

-----------------------------------------------------------------------------------------------------------------------------------------------------
--54 Count the number of hyper and hypoglycemic incidents per patient

SELECT second.patientid, first.hypo_incidents, second.hyper_incidents
FROM
(SELECT patientid,COUNT(glucose_value_mgdl)as hypo_incidents
FROM dexcom 
WHERE glucose_value_mgdl <70
GROUP BY patientid)first
FULL JOIN
(SELECT patientid,COUNT(glucose_value_mgdl )as hyper_incidents
FROM dexcom 
WHERE glucose_value_mgdl >=126
GROUP BY patientid)second
ON first.patientid = second.patientid
order by patientid;

-----------------------------------------------------------------------------------------------------------------------------------------------------
--55 What is the variance from mean  for all patients for the table IBI?

SELECT patientid,VARIANCE(mean_ibi_ms)AS Variance
FROM ibi
group by patientid;

-----------------------------------------------------------------------------------------------------------------------------------------------------
--56 Create a view that combines all relevant patient demographics and lab markers into one. Call this view ‘Patient_Overview’.

CREATE OR REPLACE VIEW Patient_Overview AS 
SELECT DISTINCT d.patientid,d.firstname ||' '|| d.lastname AS patient_name, d.gender, d.hba1c
,AVG(h.mean_hr) as mean_hr
FROM demographics d
JOIN hr h
ON d.patientid = h.patientid
GROUP BY d.patientid
ORDER BY d.patientid;


SELECT * FROM Patient_Overview;

---DROP VIEW Patient_Overview;

-----------------------------------------------------------------------------------------------------------------------------------------------------
--57 Create a table that stores an array of biomarkers: Min(Glucose Value), Avg(Mean_HR), Max(Max_EDA) for every patient. 
---The result should look like this: (Link in next cell)

CREATE TABLE Array_of_biometrics AS
SELECT CAST (d.patientid AS int) AS pid ,
			CAST ('{'||MIN(glucose_value_mgdl)||','||AVG(mean_hr)||','||MAX(max_eda)||'}'
                  AS numeric[]) AS biomarkers
		FROM demographics d
		INNER JOIN eda e ON d.patientid = e.patientid
		INNER JOIN HR AS H ON d.patientid = h.patientid
		INNER JOIN dexcom AS dx ON d.patientid = dx.patientid
		GROUP BY d.patientid
		ORDER BY d.patientid;

-----------------------------------------------------------------------------------------------------------------------------------------------------
--58 Assuming lunch is between 12pm and 2pm. Calculate the total number of calories consumed by each patient for lunch on "2020-02-24"

SELECT patientid, SUM(calorie) as total_calories
FROM foodlog
WHERE EXTRACT(HOUR FROM datetime) BETWEEN 12 AND 14 
AND DATE(datetime)= '2020-02-24'
GROUP BY patientid;

-----------------------------------------------------------------------------------------------------------------------------------------------------
---59 What is the total length of time recorded for each patient(in hours) in the Dexcom table?

SELECT patientid,round(EXTRACT(EPOCH FROM (max(datestamp) - min(datestamp)))/3600) AS total_hours from dexcom
group by patientid
order by patientid;

-----------------------------------------------------------------------------------------------------------------------------------------------------
---60 Display the first, last name, patient age and max glucose reading in one string for every patient

SELECT d.patientid, d.firstname ||'  ,  '||d.lastname
|| '  ,  '|| AGE(CURRENT_DATE,d.dob)|| '  ,  '|| MAX(dx.glucose_value_mgdl)AS oneString
FROM demographics d
JOIN dexcom dx
ON d.patientid = dx.patientid
GROUP BY d.patientid
order by d.patientid;

-----------------------------------------------------------------------------------------------------------------------------------------------------
---61 What is the average age of all patients in the database?

SELECT AVG(age) as average_age
FROM
(SELECT patientid, AGE(CURRENT_DATE,dob)AS age
FROM demographics
GROUP BY patientid)a;

-----------------------------------------------------------------------------------------------------------------------------------------------------
--62 Display All female patients with age less than 50
SELECT patientid, gender,AGE(CURRENT_DATE,dob)AS age
FROM demographics
WHERE gender='FEMALE' AND EXTRACT(YEAR FROM AGE(CURRENT_DATE,dob))< 50
order by patientid;

-----------------------------------------------------------------------------------------------------------------------------------------------------
---63 Display count of Event ID, Event Subtype and the first letter of the event subtype. Display all events 

SELECT id as event_id,event_subtype,LEFT(event_subtype,1) as first_letter,count(1) as cnt
FROM eventtype
GROUP BY id,event_subtype,LEFT(event_subtype,1)
order by id;

-----------------------------------------------------------------------------------------------------------------------------------------------------
---64 List the foods consumed by  the patient(s) whose eventype is "Estimated Glucose Value".
SELECT DISTINCT  f.logged_food FROM dexcom d
JOIN eventtype e
ON d.eventid = e.id
JOIN foodlog f
ON d.patientid = f.patientid
WHERE e.event_subtype='Estimated Glucose Value'

-----------------------------------------------------------------------------------------------------------------------------------------------------

--65. Rank the patients' health based on HRV and Control of blood sugar(AKA min time spent out of range)

--Step 1 :Create a 'hrv' field to table  'ibi' to store Heat Rate Variability
--Add 'hrv' field to table 'ibi'

ALTER TABLE ibi
ADD COLUMN hrv numeric;
--Update field 'hrv' 
UPDATE ibi
SET hrv = (SELECT AVG(rmssd_ms) * 600
           FROM ibi AS sub
           WHERE sub.patientid = ibi.patientid);
		   
--Step 2 : Create Table named 'hrv_bloodSugar' with HRV and Blood sugar data

CREATE TABLE hrv_bloodSugar AS
SELECT
    d.patientid,
	ROUND(AVG(dc.glucose_value_mgdl)) AS Glucose_Value,
	ROUND(AVG(ibi.hrv)) AS HRV
FROM
   demographics d
JOIN
    dexcom dc ON d.patientid = dc.patientid
JOIN 
    ibi ON d.patientid = ibi.patientid
GROUP BY d.patientid
ORDER BY d.patientid;

--Step 3 : Query to Rank patients health based on HRV and control of bloodsugar  
		   
WITH hrv_ranks AS (
    SELECT
        patientid,
        RANK() OVER (ORDER BY hrv DESC) AS hrv_rank
    FROM
        hrv_bloodsugar
),
bs_ranks AS (
    SELECT
        patientid,
        RANK() OVER (ORDER BY glucose_value ASC) AS bloodsugar_rank
    FROM
       hrv_bloodsugar
)
SELECT
    hrvbs.patientid,
	hrvbs.HRV AS HRV_Value,
	hrvbs.Glucose_Value,
	hrv.hrv_rank AS hrv_rank,
    bs.bloodsugar_rank bloodsugar_rank  
FROM
    hrv_bloodsugar hrvbs
LEFT JOIN
    hrv_ranks hrv ON hrvbs.patientid = hrv.patientid
LEFT JOIN
    bs_ranks bs ON hrvbs.patientid = bs.patientid;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
--66. Create a trigger on the foodlog table that warns a person about any food logged that has more than 20 grams of sugar. The user should not be stopped from inserting the row. Only a warning is needed

CREATE FUNCTION check_sugar_limit() --Create trigger function
RETURNS TRIGGER AS $$
BEGIN 
    IF NEW.sugar > 20 THEN
        -- Raise a warning
        RAISE WARNING 'The food item inserted has more than 20 grams of sugar.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--Drop Function
DROP FUNCTION check_sugar_limit();

 --CREATE TRIGGER statement
 
CREATE TRIGGER sugar_limit_trigger 
AFTER INSERT ON foodlog
FOR EACH ROW
EXECUTE FUNCTION check_sugar_limit();

--Drop a Trigger
DROP TRIGGER sugar_limit_trigger ON foodlog;

--Trying to Insert a record on foodlog table with sugar greater than 20 grams.

INSERT INTO foodlog(
	datetime, logged_food, calorie, total_carb, dietary_fiber, sugar, protein, total_fat, patientid)
	VALUES ('2020-02-13 18:30:00', 'Juice', 413, 56, 2.3, 55, 12, 3,4);
--The record will be inserted with a warning message "The food item inserted has more than 20 grams of sugar"
----------------------------------------------------------------------------------------------------------
--67. Display all the patients with high heart rate and prediabetic

 SELECT
    d.patientid,
    d.firstname,
	d.lastname,
    d.gender,
	ROUND(AVG(hr.max_hr)) AS Max_heart_rate
FROM
    demographics d
JOIN
     hr ON d.patientid = hr.patientid
GROUP BY d.patientid
HAVING
     d.hba1c>=5.7 AND d.hba1c<=6.4 ---- filtering out Prediabetic patients 
ORDER BY Max_heart_rate DESC;
      
------------------------------------------------------------------------------------------------------------------
--68. Display patients information who have tachycardia HR and a glucose value greater than 200.

SELECT
    dc.patientid,
    ROUND(AVG(hr.mean_hr)) AS Tachycardia_HR,
    ROUND(MAX(dc.glucose_value_mgdl)) AS Glucose_Value
FROM
    dexcom dc
JOIN
     hr ON dc.patientid = hr.patientid
GROUP BY dc.patientid
HAVING
    AVG(hr.mean_hr) > 100 AND MAX(dc.glucose_value_mgdl) > 200; 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--69. Calculate the number of hypoglycemic incident per patient per day where glucose drops under 55
--use a common table expression (CTE) named hypoglycemic_incidents to count the number of hypoglycemic incidents (glucose drops under 55) per patient per day.

WITH hypoglycemic_incidents AS (
    SELECT
        patientid,
        DATE_TRUNC('day', datestamp) AS incident_day,
        COUNT(*) AS incident_count
    FROM
        dexcom as dc
    WHERE
        glucose_value_mgdl < 55
    GROUP BY
        patientid, incident_day
)
SELECT
    patientid,
    incident_day,
    incident_count
FROM
    hypoglycemic_incidents
ORDER BY
    patientid, incident_day;
	
----------------------------------------------------------------------------------------------------------------------------
--70. List the day wise calories intake for each patient.
SELECT
    patientid,
    DATE_TRUNC('day', datetime) AS date,
    SUM(calorie) AS Total_calories_consumed --Sum function to calulate total calories per day for each patient
FROM
    foodlog
GROUP BY
    patientid,DATE_TRUNC('day', datetime)
ORDER BY
    patientid,date;
------------------------------------------------------------------------------------------------------------------------------------
--71. Display the demographic details for the patient that had the maximum time below recommended blood glucose range

WITH below_range_times AS (
    SELECT
        dc.patientid,
        SUM(CASE WHEN dc.glucose_value_mgdl < 55 THEN 1 ELSE 0 END) AS time_below_range
    FROM
        dexcom dc
    GROUP BY
        dc.patientid
	ORDER BY 
	    dc.patientid
)
SELECT
    d.patientid,
    d.firstname,
    d.lastname,
	d.gender,
    MAX(brt.time_below_range) AS max_time_in_below_range
FROM
   below_range_times brt
JOIN
    demographics d ON brt.patientid = d.patientid
GROUP BY d.patientid
ORDER BY max_time_in_below_range DESC
limit 1;

----------------------------------------------------------------------------------------------------------------
--72. How many patients have a minimum HR below the medically recommended level(ie, below 60)?

SELECT COUNT(DISTINCT hr.patientid) AS patients_below_minimum_hr
FROM hr 
JOIN
    (
        SELECT
            patientid,
            MAX(min_hr) AS min_heart_rate --Considering the highest value of each patient mininum heart rate
        FROM
            hr
        GROUP BY
            patientid
    ) AS mhr ON hr.patientid = mhr.patientid
WHERE
    min_heart_rate < 60;
-----------------------------------------------------------------------------------------------------------------------
--73. Create a trigger to raise notice and prevent the deletion of a record from ‘Patient_Overview’.

--Create a function to handle the DELETE operation on the view:

CREATE FUNCTION prevent_delete_from_patient_overview() 
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Deletion from Patient_Overview view is not allowed';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


--Drop Function
DROP FUNCTION prevent_delete_from_patient_overview();

--Create a trigger to call the function for DELETE operations on the view:

CREATE TRIGGER prevent_delete_trigger
INSTEAD OF DELETE ON Patient_Overview
FOR EACH ROW
EXECUTE FUNCTION prevent_delete_from_patient_overview();
--This approach uses an INSTEAD OF DELETE trigger to call a function that raises a notice and returns NULL, effectively preventing the deletion from the view.

--Drop a Trigger
DROP TRIGGER prevent_delete_trigger ON Patient_Overview;

--Trying to delete a record from the view 'Patient_Overview'
DELETE FROM Patient_Overview
WHERE patientid=1;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
--74. What is the average heart rate, age and gender of the every patient in the dataset?

SELECT
    d.patientid,
    ROUND(AVG(hr.mean_hr)) AS average_heart_rate,
    EXTRACT(YEAR FROM AGE(NOW(), d.dob)) AS age,
    d.gender
FROM
   demographics d
JOIN
     hr ON d.patientid = hr.patientid
GROUP BY
     d.patientid
ORDER BY 
     d.patientid;

-------------------------------------------------------------------------------------------------------------------------------
--75. What is the daily total calories consumed by every patient?

SELECT
    patientid,
    DATE_TRUNC('day', datetime) AS date,
    SUM(calorie) AS Total_calories_consumed --Sum function to calulate total calories per day for each patient
FROM
    foodlog
GROUP BY
    patientid,DATE_TRUNC('day', datetime)
ORDER BY
    patientid,date;

--------------------------------------------------------------------------------------------------------------------------------------
--76. Write a query to classify max EDA into 5 categories and display the number of patients in each category.

SELECT
    CASE
        WHEN max_eda BETWEEN 0 AND 0.2 THEN 'VERY LOW'
        WHEN max_eda BETWEEN 0.2 AND 0.4 THEN 'LOW'
        WHEN max_eda BETWEEN 0.4 AND 0.6 THEN 'MEDIUM'
        WHEN max_eda BETWEEN 0.6 AND 0.8 THEN 'HIGH'
        ELSE 'VERY HIGH'
    END AS max_eda_category,
    COUNT(patientid) AS number_of_patients
FROM
    eda
GROUP BY
    max_eda_category;
-----------------------------------------------------------------------------------------------------------------------
--77. List the daily max HR for patient with event type Exercise.

SELECT
    hr.patientid,
    MAX(hr.max_hr) AS max_heart_rate, --MAX function to retrieve the maximum heart rate
    DATE_TRUNC('day', hr.datestamp) AS date
FROM hr
JOIN
    dexcom dc ON  hr.patientid=dc.patientid
WHERE
    dc.eventid = 16 --eventid is 16 for event type Excercise 
GROUP BY
    hr.patientid, DATE_TRUNC('day', hr.datestamp)
ORDER BY
    hr.patientid, DATE_TRUNC('day', hr.datestamp);

----------------------------------------------------------------------------------------------------------------------------------
--78. What is the standard deviation from mean for all patients for the table HR?

SELECT d.patientid,STDDEV(hr.mean_hr) AS standard_deviation --STDDEV function to calculate standard deviation
FROM demographics d
JOIN hr ON d.patientid=hr.patientid
GROUP BY d.patientid
ORDER BY d.patientid; --Gives the Patients ID in ascending order

-------------------------------------------------------------------------------------------------------------------------------------------
--79. Give the demographic details of the patient with event type ID of 16.

SELECT distinct(d.patientid),d.gender,d.dob,d.firstname,d.lastname    
FROM
    demographics d
JOIN
    dexcom dc ON d.patientid = dc.patientid 
WHERE
    dc.eventid = 16; --Filtering patients with event type is equal to 16.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--80. Display list of patients along with their gender having a tachycardia mean HR.    
	   
SELECT d.patientid,d.gender, AVG(hr.mean_hr) AS Tachycardia_mean_HR
FROM demographics d JOIN hr ON d.patientid = hr.patientid
GROUP BY d.patientid
HAVING
    AVG(hr.mean_hr) > 100; --Tachycardiais the medical term for a heart rate over 100 beats a minute.

-------------------------------------------------------------------------------------------------------------------------------------------------------







