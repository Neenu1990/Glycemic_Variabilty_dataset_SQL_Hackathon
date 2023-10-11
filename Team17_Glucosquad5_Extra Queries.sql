-- EXTRA QUESTIONS 

--QUERY 1 Can you find patients from the demographics table whose last name contains ‘an’ 
--Provide their patient IDs and the position where ‘an’ appears in their last name. What insights can be derived from this information?

-- This SQL query retrieves the position of the substring 'an' within the 'lastname' column 
-- for patients whose last names contain 'an'.

SELECT
    patientid,
    STRPOS(lastname, 'an') AS mc_position -- Calculate the position of 'an' in the last name
FROM
    demographics
WHERE
    STRPOS(lastname, 'an') > 0 ; -- Filter records where 'an' is found in the last name
---------------------------------------------------------------------------------------------------

--QUERY 2 Can you generate a report that includes a list of patients from the demographics table with their full names, where each name is formatted as "Last Name, First Name," and the patient ID is left-padded with zeros to a total length of 8 characters? 
--Additionally, calculate the average age of these patients. How can this report be used for patient identification and analysis?
-- This SQL query generates a report with patient information.

-- This SQL query generates a report with patient information, excluding rows with NULL values.

SELECT
    LPAD(patientid::text, 8, '0') AS padded_patientid,
    CONCAT_WS(', ', lastname, firstname) AS full_name,
    ROUND(AVG(EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM dob))) AS average_age
FROM
    demographics
WHERE
    patientid IS NOT NULL -- Exclude rows where 'patientid' is NULL
    AND lastname IS NOT NULL -- Exclude rows where 'lastname' is NULL
    AND firstname IS NOT NULL -- Exclude rows where 'firstname' is NULL
    AND dob IS NOT NULL -- Exclude rows where 'dob' is NULL
GROUP BY
    padded_patientid, full_name;
---------------------------------------------------------------------------------------------------	

--QUERY 3 Can you retrieve a list of food items from the foodlog table, where the item's name is right-padded with underscores to a minimum length of 20 characters? Additionally, count the occurrences of each unique padded food item in the dataset. 
--How can this information help in analyzing food preferences?
-- Analyzes food log data, counts food item occurrences
-- Pads 'logged_food' with underscores for uniformity

SELECT
    RPAD(logged_food, 20, '_') AS padded_food_item, -- Pad food items with underscores
    COUNT(*) AS item_count -- Count occurrences of each padded food item
FROM
    foodlog
GROUP BY
    padded_food_item -- Group results by padded food item
ORDER BY
    item_count DESC; -- Sort results by item count in descending order
---------------------------------------------------------------------------------------------------

-- QUERY 4 Can you find all patients from the demographics table whose first names contain any of the specified substrings ('John', 'David', 'Sarah')? 
--Display their full names, first names, and the matched substring.

-- Select full names and first names where the first name contains 'John', 'David', or 'Sarah'.
SELECT
    CONCAT_WS(' ', d.firstname, d.lastname) AS full_name,
    d.firstname
FROM
    demographics AS d
WHERE
    POSITION('John' IN d.firstname) > 0
    OR POSITION('David' IN d.firstname) > 0
    OR POSITION('Sarah' IN d.firstname) > 0;
---------------------------------------------------------------------------------------------------	

--QUERY 5 Can you analyze the relationship between the last two digits of patients' birth years (DOB) and their mean heart rate (mean_hr) from the "demographics" and "hr" tables? 
--Specifically, we want to know if there's any correlation between the last two digits of birth years and mean heart rates. Additionally, can you identify any patterns or trends in the data?

-- Calculate the last two digits of birth years and retrieve mean heart rates
-- This query computes statistics related to patient birth years and mean heart rates.

WITH birth_year_last_two_digits AS (
  SELECT
    patientid,
    RIGHT(EXTRACT(YEAR FROM dob)::TEXT, 2) AS last_two_digits_of_birth_year
  FROM public.demographics
),
mean_heart_rates AS (
  SELECT
    h.patientid,
    AVG(h.mean_hr) AS avg_mean_hr
  FROM public.hr AS h
  GROUP BY h.patientid
)
SELECT
  byl2d.last_two_digits_of_birth_year,
  COUNT(*) AS num_patients,
  ROUND(AVG(mhr.avg_mean_hr)::NUMERIC, 2) AS avg_mean_hr,
  MAX(mhr.avg_mean_hr) AS max_mean_hr,
  MIN(mhr.avg_mean_hr) AS min_mean_hr
FROM birth_year_last_two_digits AS byl2d
LEFT JOIN mean_heart_rates AS mhr ON byl2d.patientid = mhr.patientid
GROUP BY byl2d.last_two_digits_of_birth_year
ORDER BY byl2d.last_two_digits_of_birth_year;

-- Calculate the Pearson correlation coefficient
-- This query calculates the Pearson correlation coefficient between 
-- last two digits of birth years and mean heart rates.

WITH birth_year_last_two_digits AS (
  SELECT
    patientid,
    RIGHT(EXTRACT(YEAR FROM dob)::TEXT, 2) AS last_two_digits_of_birth_year
  FROM public.demographics
),
mean_heart_rates AS (
  SELECT
    h.patientid,
    AVG(h.mean_hr) AS avg_mean_hr
  FROM public.hr AS h
  GROUP BY h.patientid
)
SELECT
  corr(
    byl2d.last_two_digits_of_birth_year::DOUBLE PRECISION,
    mhr.avg_mean_hr::DOUBLE PRECISION
  ) AS pearson_correlation_coefficient
FROM birth_year_last_two_digits AS byl2d
LEFT JOIN mean_heart_rates AS mhr ON byl2d.patientid = mhr.patientid;
---------------------------------------------------------------------------------------------------

--QUERY 6 Can you generate a report that shows the distribution of logged foods (logged_food) from the "foodlog" table, where each food item is categorized by its first letter (A-Z) and the number of times each category appears in the data?

-- Analyze food log data to categorize and count food items
-- This query groups food items into categories by converting them to uppercase
-- and then counts the occurrences of each category.

WITH food_categories AS (
  SELECT
    TRANSLATE(UPPER(logged_food), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') AS category,
    COUNT(*) AS category_count
  FROM public.foodlog
  GROUP BY category
)
SELECT
  category,
  SUM(category_count) AS total_count -- Sum the counts within each category
FROM food_categories
GROUP BY category -- Group results by category
ORDER BY category; -- Sort results alphabetically by category
---------------------------------------------------------------------------------------------------

-- QUERY 7 How can we identify significant increases in heart rate for patients

-- Identify and track significant increases in heart rate for patients
-- This query calculates fluctuations in mean heart rates, marks significant increases, 
-- and presents a structured view of patients' heart rate data.

WITH HeartRateFluctuations AS (
  SELECT
    patientid,
    datestamp,
    mean_hr,
    LAG(mean_hr) OVER (PARTITION BY patientid ORDER BY datestamp) AS previous_hr
  FROM
    public.hr
),
IncreasedHeartRateDays AS (
  SELECT
    patientid,
    datestamp,
    mean_hr,
    previous_hr,
    CASE
      WHEN previous_hr IS NOT NULL AND mean_hr > 1.1 * previous_hr THEN 1
      ELSE 0
    END AS increased_heart_rate
  FROM
    HeartRateFluctuations
)
SELECT
  patientid,
  datestamp,
  mean_hr,
  previous_hr,
  CASE
    WHEN increased_heart_rate = 1 THEN 'Yes'
    ELSE 'No'
  END AS significant_increase
FROM
  IncreasedHeartRateDays
WHERE
  increased_heart_rate = 1
ORDER BY
  patientid, datestamp;
  ---------------------------------------------------------------------------------------------------
  
--QUERY 8 Can you calculate the average heart rate (mean_hr) for each gender from the "demographics" and "hr" tables, and round it up to the nearest whole number.

-- Calculate and round up the average heart rate for each gender
-- This query computes the average heart rate for each gender by joining demographics and heart rate data, 
-- and then rounds up the result to the nearest whole number.

WITH avg_heart_rates AS (
  SELECT d.gender, ceil(AVG(h.mean_hr)) AS average_heart_rate
  FROM public.demographics AS d
  JOIN public.hr AS h ON d.patientid = h.patientid
  GROUP BY d.gender
)
SELECT gender, average_heart_rate
FROM avg_heart_rates;
---------------------------------------------------------------------------------------------------

--QUERY 9 Concatenate logged food items for each patient into a single array
-- Concatenate logged food items for each patient into a single array
-- This query aggregates individual food log entries into arrays for each patient 
-- and then concatenates those arrays into a single array, simplifying food item analysis.

WITH food_arrays AS (
  SELECT patientid, array_agg(logged_food) AS food_items_array
  FROM public.foodlog
  GROUP BY patientid
  ORDER BY patientid
)
SELECT patientid, array_agg(food_items) AS concatenated_food_items
FROM (
  SELECT patientid, unnest(food_items_array) AS food_items
  FROM food_arrays
) subquery
GROUP BY patientid
ORDER BY patientid;
---------------------------------------------------------------------------------------------------

--QUERY 10	How can we efficiently process and present food log data, including both concatenating food items into comma-separated strings and converting them back into arrays for further analysis.
-- Retrieve logged food items as comma-separated strings for each patient
-- This query compiles food log entries for each patient into comma-separated strings, 
-- simplifying the presentation of food consumption data.

SELECT patientid, array_to_string(array_agg(logged_food), ',') AS food_items_csv
FROM public.foodlog
GROUP BY patientid
ORDER BY patientid;

-- Convert comma-separated strings back into arrays
-- This query reverses the process, converting previously concatenated strings 
-- back into arrays for further analysis or manipulation.

WITH food_arrays AS (
  SELECT patientid, string_to_array(food_items_csv, ',') AS food_items_array
  FROM (
    SELECT patientid, array_to_string(array_agg(logged_food), ',') AS food_items_csv
    FROM public.foodlog
    GROUP BY patientid
  ) subquery
)
SELECT patientid, food_items_array
FROM food_arrays
ORDER BY patientid;
---------------------------------------------------------------------------------------------------

--QUERY 11 How can we ensure reproducibility when selecting a random sample of 10 patients from the 'demographics' table, while also excluding records with NULL values in the 'patientid,' 'firstname,' and 'lastname' columns?
--Set the seed for reproducibility
--This query initializes a seed value of 0.42 for random number generation, ensuring that subsequent random operations are reproducible.

SELECT setseed(0.42);

-- Generate a random sample of 10 patients from the "demographics" table, excluding NULL values
-- This query selects a random sample of 10 patients from the "demographics" table, 
-- ensuring that records with NULL values in the 'patientid,' 'firstname,' or 'lastname' columns are excluded.

SELECT patientid, firstname, lastname
FROM public.demographics
WHERE patientid IS NOT NULL
  AND firstname IS NOT NULL
  AND lastname IS NOT NULL
ORDER BY random()
LIMIT 10;
---------------------------------------------------------------------------------------------------

--QUERY 12 What is the patient's glucose level (glucose_value_mgdl) at the 75th percentile (3rd quartile) in the provided medical dataset, and how does it vary based on gender and age group?"
-- Categorize patients into age groups, calculate 75th percentile of glucose values
-- This query categorizes patients into age groups (0-20, 21-30, 31-40, and 41+),
-- and calculates the 75th percentile of glucose values for each age group and gender.

SELECT
    CASE
        WHEN EXTRACT(YEAR FROM age(dob))::integer <= 20 THEN '0-20'
        WHEN EXTRACT(YEAR FROM age(dob))::integer <= 30 THEN '21-30'
        WHEN EXTRACT(YEAR FROM age(dob))::integer <= 40 THEN '31-40'
        ELSE '41+'
    END AS age_group,
    gender,
    PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY glucose_value_mgdl) AS percentile_75th
FROM
    demographics
JOIN
    dexcom ON demographics.patientid = dexcom.patientid
GROUP BY
    age_group, gender
ORDER BY
    age_group, gender;
---------------------------------------------------------------------------------------------------

--QUERY 13 What is the relationship between the variability in glucose levels (sample variance) and the average glucose values among different age groups and genders in the provided medical dataset, 
--and how can this information be leveraged to improve healthcare outcomes?

-- Calculate glucose statistics by age group and gender
-- This query computes glucose statistics, including sample variance and average values, for patients grouped by age and gender.

WITH glucose_stats AS (
    SELECT
        CASE
            WHEN EXTRACT(YEAR FROM age(demographics.dob)) <= 20 THEN '0-20'
            WHEN EXTRACT(YEAR FROM age(demographics.dob)) <= 30 THEN '21-30'
            WHEN EXTRACT(YEAR FROM age(demographics.dob)) <= 40 THEN '31-40'
            ELSE '41+'
        END AS age_group,
        demographics.gender,
        VAR_SAMP(dexcom.glucose_value_mgdl) AS sample_glucose_variance,
        AVG(dexcom.glucose_value_mgdl) AS average_glucose_value
    FROM
        demographics
    JOIN
        dexcom ON demographics.patientid = dexcom.patientid
    WHERE
        demographics.dob IS NOT NULL
    GROUP BY
        age_group, demographics.gender
    ORDER BY
        age_group, demographics.gender
)
SELECT
    age_group,
    gender,
    sample_glucose_variance,
    average_glucose_value
FROM
    glucose_stats;
---------------------------------------------------------------------------------------------------

--QUERY 14 Is there a significant difference in the population variances of glucose levels (glucose_value_mgdl) between male and female patients in the provided medical dataset? We want to determine if there is a statistically significant difference in glucose level variability between these gender groups
-- Calculate population variance of glucose values by gender
-- This query computes the population variance of glucose values for each gender.

WITH gender_glucose_variance AS (
    SELECT
        gender,
        VAR_POP(glucose_value_mgdl) AS population_variance
    FROM
        demographics
    JOIN
        dexcom ON demographics.patientid = dexcom.patientid
    GROUP BY
        gender
)
SELECT
    gender,
    population_variance
FROM
    gender_glucose_variance
WHERE
    population_variance IS NOT NULL; -- Exclude records with NULL variance values
---------------------------------------------------------------------------------------------------

--QUERY 15 Is there a significant relationship between a patient's mean heart rate (mean_hr) and their recorded blood glucose levels (glucose_value_mgdl) in the provided medical dataset?
-- Calculate the population covariance between mean heart rates and glucose values
-- This query computes the population covariance, measuring the relationship between mean heart rates and glucose values for patients.

SELECT
    COVAR_POP(mean_hr, glucose_value_mgdl) AS population_covariance
FROM
    hr
JOIN
    dexcom
ON
    hr.patientid = dexcom.patientid;
---------------------------------------------------------------------------------------------------

--QUERY 16 What are the most common starting substrings (e.g., the first three characters) of food item names logged by patients in the foodlog dataset, and how frequently do they appear
-- Analyze food log data by examining the starting three characters of food items
-- This query extracts the first three characters of food items and calculates their frequency, 
-- providing insights into common food item categories based on their initial characters.

SELECT
    SUBSTRING(logged_food FROM 1 FOR 3) AS starting_substring,
    COUNT(*) AS frequency
FROM foodlog
GROUP BY starting_substring
ORDER BY frequency DESC;
---------------------------------------------------------------------------------------------------

--QUERY 17 How can we efficiently replace spaces with underscores in logged food item names for patients
-- Replace spaces with underscores in logged food item names for patients
-- This query transforms food item names by replacing spaces with underscores, enhancing data consistency and readability.

SELECT
    patientid,
    REPLACE(logged_food, ' ', '_') AS food_with_underscore
FROM foodlog;
--QUERY 18 Find the total number of logged food items for each patient
-- Calculate the total number of food items logged for each patient
-- This query aggregates and counts the total number of food items logged for each patient.

SELECT
    patientid,
    ARRAY_LENGTH(ARRAY_AGG(logged_food), 1) AS total_food_items_logged
FROM foodlog
GROUP BY patientid
ORDER BY patientid;
---------------------------------------------------------------------------------------------------

--QUERY 19 Calculate the number of days since the last recorded event for each patient in the dexcom table using the NOW function
-- Calculate the days since the last event for each patient in the "dexcom" dataset
-- This query finds the maximum days elapsed since the last event date for each patient.

-- Calculate the days since the last event for each patient in the "dexcom" dataset
-- This query finds the maximum days elapsed since the last event date for each patient.
-- Calculate the days since the last event for each patient in the "dexcom" dataset
-- This query finds the maximum days elapsed since the last event date for each patient.
-- Calculate the days since the last event for each patient in the "dexcom" dataset
-- This query finds the maximum days elapsed since the last event date for each patient.

SELECT
    d.patientid,
    EXTRACT(DAY FROM NOW() - MAX(d.last_event_date))::INTEGER AS days_since_last_event
FROM
    (SELECT
        patientid,
        MAX(datestamp) AS last_event_date
    FROM
        dexcom
    GROUP BY
        patientid) AS d
GROUP BY
    d.patientid;
---------------------------------------------------------------------------------------------------

--QUERY 20 What is the most common event type recorded for each patient, and how does it correlate with their HbA1c levels
-- Common Table Expression (CTE) to calculate event counts for each patient
WITH EventCounts AS (
    SELECT
        d.patientid,
        COUNT(e.event_type) AS event_count  -- Count the events for each patient
    FROM
        demographics d
    LEFT JOIN
        dexcom dx ON d.patientid = dx.patientid  -- Join demographics and dexcom tables
    LEFT JOIN
        eventtype e ON dx.eventid = e.id  -- Join with the eventtype table to get event types
    GROUP BY
        d.patientid, d.hba1c  -- Group by patient and their HbA1c levels
)
SELECT
    ec.patientid,
    mode() WITHIN GROUP (ORDER BY e.event_type) AS most_common_event_type,  -- Calculate the mode (most common event type)
    CORR(d.hba1c, ec.event_count::numeric) AS correlation_hba1c_event_count  -- Calculate the correlation between HbA1c and event counts
FROM
    EventCounts ec
LEFT JOIN
    demographics d ON ec.patientid = d.patientid  -- Join the CTE with demographics to get patient details
LEFT JOIN
    dexcom dx ON ec.patientid = dx.patientid  -- Join with dexcom to get event details
LEFT JOIN
    eventtype e ON dx.eventid = e.id  -- Join with eventtype to get event types
GROUP BY
    ec.patientid, d.hba1c;  -- Group by patient and their HbA1c levels
---------------------------------------------------------------------------------------------------

--QUERY 21 How many patients have their birthdays in each month, and what is the total count of patients born in each month?

-- Calculate the number of patients born in each month
SELECT
    TO_CHAR(dob, 'Month') AS birth_month,    -- Full month name
    TO_CHAR(dob, 'MM') AS month_number,       -- Month number
    COUNT(*) AS patient_count                -- Count of patients
FROM
    public.demographics
WHERE
    dob IS NOT NULL                          -- Exclude NULL birth dates
GROUP BY
    birth_month, month_number                -- Group by month name and number
ORDER BY
    month_number;                            -- Order by month number
---------------------------------------------------------------------------------------------------

--QUERY 22 With respect to foodlog table, We need to perform several operations on this data using regular expressions and string functions. Please explain how we can achieve the following tasks using SQL queries:
--•	Find all rows where the logged_food column contains the word 'cheese' in a case-insensitive manner. Additionally, list all matches of 'cheese' within each food item.
--•	Replace all occurrences of the word 'son' with 'daughter' in the logged_food column while preserving case sensitivity.
--•	Extract the first word from the logged_food column.
--•	Determine the position of the substring 'cheese' in the logged_food column (case-insensitive      

WITH ComplexRegexQuery AS (
    SELECT
        patientid,
        logged_food,
        -- Use REGEXP_MATCHES to find all food items containing 'cheese' (case-insensitive)
        REGEXP_MATCHES(logged_food, 'cheese', 'i') AS cheese_matches,
        -- Use REGEXP_REPLACE to replace 'Cheese' with 'fullfatcheese' in logged_food
        REGEXP_REPLACE(logged_food, 'Cheese', 'FullFatCheese', 'gi') AS modified_logged_food,
        -- Use REGEXP_SUBSTR to extract the first word from logged_food
        REGEXP_SUBSTR(logged_food, '\w+') AS first_word,
        -- Use POSITION to find the position of 'cheese' in logged_food
        POSITION('cheese' IN LOWER(logged_food)) AS cheese_position
    FROM
        public.foodlog
)
SELECT
    patientid,
    logged_food,
    cheese_matches,
    modified_logged_food,
    first_word,
    cheese_position
FROM
    ComplexRegexQuery
WHERE
    -- Filter rows where 'cheese' (case-insensitive) is present in logged_food
    EXISTS (SELECT 1 FROM unnest(cheese_matches) AS m WHERE m ~* 'cheese');
---------------------------------------------------------------------------------------------------

--QUERY 23 Analyze the foodlog data to determine the length of logged_food entries for each patient while also identifying if there are any leading or trailing spaces in those entries?"

WITH FoodlogEntryAnalysis AS (
    SELECT
        patientid,
        logged_food,
        LENGTH(logged_food) AS entry_length,
        LENGTH(TRIM(logged_food)) AS trimmed_length,
        LENGTH(RTRIM(logged_food)) AS rtrimmed_length,
        LENGTH(LTRIM(logged_food)) AS ltrimmed_length,
        CASE
            WHEN LENGTH(logged_food) > LENGTH(TRIM(logged_food)) THEN 'Leading spaces detected'
            ELSE 'No leading spaces'
        END AS leading_space_status,
        CASE
            WHEN LENGTH(logged_food) > LENGTH(RTRIM(logged_food)) THEN 'Trailing spaces detected'
            ELSE 'No trailing spaces'
        END AS trailing_space_status
    FROM
        public.foodlog
)
SELECT
    patientid,
    logged_food,
    entry_length,
    trimmed_length,
    rtrimmed_length,
    ltrimmed_length,
    leading_space_status,
    trailing_space_status
FROM
    FoodlogEntryAnalysis;
---------------------------------------------------------------------------------------------------

--QUERY 24 Analyze the foodlog data to extract and format the food item names in a reversed order, and then split them to identify specific components, while also calculating the average length of food item names
WITH FoodItemAnalysis AS (
    SELECT
        patientid,
        logged_food,
        REVERSE(logged_food) AS reversed_food,
        SPLIT_PART(REVERSE(logged_food), ',', 1) AS last_component,
        SPLIT_PART(REVERSE(logged_food), ',', 2) AS second_last_component,
        SPLIT_PART(REVERSE(logged_food), ',', 3) AS third_last_component,
        LENGTH(logged_food) AS food_length
    FROM
        public.foodlog
)
SELECT
    patientid,
    logged_food,
    reversed_food,
    last_component,
    second_last_component,
    third_last_component,
    AVG(food_length) AS average_food_length
FROM
    FoodItemAnalysis
WHERE
    last_component IS NOT NULL
    AND second_last_component IS NOT NULL
GROUP BY
    patientid,
    logged_food,
    reversed_food,
    last_component,
    second_last_component,
    third_last_component;

---------------------------------------------------------------------------------------------------

--QUERY 25 Calculate the maximum glucose value and cumulative distribution for each patient
WITH GlucoseCumulativeDistribution AS (
    SELECT
        d.patientid,
        MAX(d.glucose_value_mgdl) AS max_glucose_value,
        -- Calculate the cumulative distribution based on max glucose values
        CUME_DIST() OVER (ORDER BY MAX(d.glucose_value_mgdl) DESC) AS cumulative_distribution
    FROM
        public.dexcom AS d
    GROUP BY
        d.patientid
)
-- Select patient demographics for the top 5 patients with the highest cumulative distribution
SELECT
    g.patientid,
    g.cumulative_distribution,
    dm.firstname,
    dm.lastname,
    dm.gender,
    dm.dob
FROM
    GlucoseCumulativeDistribution AS g
-- Join with demographics table to get patient information
JOIN
    public.demographics AS dm ON g.patientid = dm.patientid
-- Filter for patients with cumulative distribution less than or equal to 0.2
WHERE
    g.cumulative_distribution <= 0.2
-- Order the results by cumulative distribution in descending order
ORDER BY
    g.cumulative_distribution DESC
-- Limit the results to the top 5 patients
LIMIT
    5;

---------------------------------------------------------------------------------------------------

--QUERY 26  Retrieve patient glucose data and calculate the difference in glucose values between consecutive readings for each patient.
WITH GlucoseValueDifference AS (
    SELECT
        d.patientid,
        d.glucose_value_mgdl,
        d.datestamp AS current_timestamp,
        LEAD(d.glucose_value_mgdl) OVER (PARTITION BY d.patientid ORDER BY d.datestamp) AS next_glucose_value,
        d.datestamp AS next_timestamp,
        LEAD(d.datestamp) OVER (PARTITION BY d.patientid ORDER BY d.datestamp) AS next_reading_timestamp,
        d.glucose_value_mgdl - LEAD(d.glucose_value_mgdl) OVER (PARTITION BY d.patientid ORDER BY d.datestamp) AS glucose_difference
    FROM
        public.dexcom AS d
)
-- Select patient glucose data and the difference in glucose values between consecutive readings
SELECT
    patientid,
    glucose_value_mgdl,
    current_timestamp,
    next_timestamp,
    next_glucose_value,
    next_reading_timestamp,
    glucose_difference
FROM
    GlucoseValueDifference
ORDER BY
    patientid,
    current_timestamp;
---------------------------------------------------------------------------------------------------

--QUERY 27 Based on the linear regression analysis between Interbeat Interval (rmssd_ms) and glucose values (glucose_value_mgdl), can we conclude that Interbeat Interval is a statistically significant predictor of glucose levels? How well does the linear regression model explain the variability in glucose values
SELECT
    REGR_SLOPE(rmssd_ms, glucose_value_mgdl) AS slope,
    REGR_INTERCEPT(rmssd_ms, glucose_value_mgdl) AS intercept,
    REGR_R2(rmssd_ms, glucose_value_mgdl) AS r_squared
FROM
    ibi
JOIN
    dexcom ON ibi.patientid = dexcom.patientid
WHERE
    rmssd_ms IS NOT NULL
    AND glucose_value_mgdl IS NOT NULL;
---------------------------------------------------------------------------------------------------

--QUERY 28 In the 'foodlog' table, find the top 5 patients who have logged the highest number of food items.
-- Find the top 5 patients with the highest number of food items logged
SELECT
  patientid,
  (array_upper(string_to_array(logged_food, ','), 1)) AS food_item_count
FROM
  foodlog
ORDER BY
  food_item_count DESC
LIMIT 5;
---------------------------------------------------------------------------------------------------

--QUERY 29 Find out the lowercase first names of all patients along with the total number of food items logged by each patient.
-- Retrieve patient first names in lowercase and total food items logged
SELECT
  d.patientid,
  LOWER(d.firstname) AS lowercase_firstname,
  COUNT(f.patientid) AS total_food_items_logged
FROM
  demographics d
LEFT JOIN
  foodlog f ON d.patientid = f.patientid
GROUP BY
  d.patientid, d.firstname
ORDER BY
  d.patientid;
---------------------------------------------------------------------------------------------------

--QUERY 30 Can you retrieve the patient IDs, first names, and last names for patients whose mean heart rate is greater than 80, and if the first name or last name is missing, replace it with 'Unknown
SELECT
    demographics.patientid,
    COALESCE(demographics.firstname, 'Unknown') AS patient_firstname,
    COALESCE(demographics.lastname, 'Unknown') AS patient_lastname
FROM
    demographics
WHERE
    demographics.patientid IN (
        SELECT DISTINCT patientid
        FROM hr
        WHERE mean_hr > 80
---------------------------------------------------------------------------------------------------
		
--QUERY 31 Select patient information from the "demographics" table.
SELECT
    demographics.patientid,          -- Patient ID
    demographics.firstname,           -- First Name

    -- Replace the last name with null for patients whose last name is 'Doe'.
    NULLIF(demographics.lastname, 'Doe') AS patient_lastname
FROM
    demographics
WHERE
    -- Filter patients based on their IDs.
    demographics.patientid IN (
        -- Subquery to retrieve distinct patient IDs from the "ibi" table
        -- where the value in the "rmssd_ms" column is less than 50.
        SELECT DISTINCT patientid
        FROM ibi
        WHERE rmssd_ms < 50
    );
---------------------------------------------------------------------------------------------------
		
--QUERY 32 For each patient, can you provide a concatenated list of logged foods along with their total calorie count?
		WITH FoodCalories AS (
    SELECT
        patientid,
        logged_food,
        SUM(calorie) AS total_calories
    FROM
        foodlog
    GROUP BY
        patientid, logged_food
)
SELECT
    fc.patientid,
    STRING_AGG(fc.logged_food || ' (' || fc.total_calories || ' calories)', ', ') AS food_with_calories
FROM
    FoodCalories fc
GROUP BY
    fc.patientid;
---------------------------------------------------------------------------------------------------
		
--QUERY 33 IdentifY patients who have logged their meals more than five times and categorizes their most common dietary preference.
-- Identify patients who have logged their meals more than five times a day on average.
WITH MealCounts AS (
    SELECT
        f.patientid,
        COUNT(*) AS daily_meal_count
    FROM
        foodlog f
    GROUP BY
        f.patientid, DATE(f.datetime) -- Count meals per patient per day
),
PatientsWithHighMealFrequency AS (
    SELECT
        mc.patientid
    FROM
        MealCounts mc
    GROUP BY
        mc.patientid
    HAVING
        AVG(mc.daily_meal_count) > 5 -- Filter patients with average daily meal count > 5
)
---------------------------------------------------------------------------------------------------
		
--QUERY 33 IdentifY patients who have logged their meals more than five times and categorizes their most common dietary preference.
-- Identify patients who have logged their meals more than five times
WITH FoodArrays AS (
    SELECT
        f.patientid,
        REGEXP_SPLIT_TO_ARRAY(f.logged_food, E'\\s*,\\s*') AS food_array
    FROM
        foodlog f
),

ExplodedFoods AS (
    SELECT
        patientid,
        UNNEST(food_array) AS food_item
    FROM
        FoodArrays
),

CategorizedFoods AS (
    SELECT
        ef.patientid,
        ef.food_item,
        CASE
            WHEN food_item ~* E'\\b(apple|banana|orange|grape|strawberry|...\\b)' THEN 'Fruit'
            WHEN food_item ~* E'\\b(broccoli|spinach|carrot|kale|lettuce|...\\b)' THEN 'Vegetable'
            WHEN food_item ~* E'\\b(chicken|beef|salmon|tofu|...\\b)' THEN 'Protein'
            WHEN food_item ~* E'\\b(rice|pasta|bread|potato|...\\b)' THEN 'Carb'
            ELSE 'Other'
        END AS food_group
    FROM
        ExplodedFoods ef
),

FoodGroupFrequencies AS (
    SELECT
        patientid,
        food_group,
        COUNT(*) AS frequency
    FROM
        CategorizedFoods
    GROUP BY
        patientid, food_group
)

SELECT
    f.patientid,
    d.firstname,
    d.lastname,
    (SELECT food_group FROM FoodGroupFrequencies WHERE patientid = f.patientid ORDER BY frequency DESC LIMIT 1) AS most_common_diet
FROM
    foodlog f
JOIN
    demographics d ON f.patientid = d.patientid
GROUP BY
    f.patientid, d.firstname, d.lastname
HAVING
    COUNT(*) > 5;
---------------------------------------------------------------------------------------------------
		
--QUERY 34 For each patient in the 'demographics' table, can you provide a breakdown of their logged meals by food item, including the number of times each food item has been logged?
-- Use REGEXP_SPLIT_TO_TABLE to extract food items from the 'logged_food' column
WITH FoodItems AS (
    SELECT
        f.patientid,
        TRIM(food_item) AS food_item
    FROM
        foodlog f
    CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(f.logged_food, E'\\s*,\\s*') AS food_item
)

-- Count the number of meals logged for each food item and patient
SELECT
    d.patientid,
    d.firstname,
    d.lastname,
    fi.food_item,
    COUNT(*) AS meal_count
FROM
    demographics d
JOIN
    FoodItems fi ON d.patientid = fi.patientid
GROUP BY
    d.patientid, d.firstname, d.lastname, fi.food_item
ORDER BY
    d.patientid, meal_count DESC;
---------------------------------------------------------------------------------------------------
		
--QUERY 35 For each patient in the 'demographics' table, can you provide a summary of their dietary information, including the total dietary fiber, sugar, total fat, protein, calorie, and total carbohydrate intake?
		SELECT
    d.patientid,
    d.firstname,
    d.lastname,
    ARRAY_DIMS(array_agg(f.dietary_fiber)) AS dietary_fiber_summary,
    ARRAY_DIMS(array_agg(f.sugar)) AS sugar_summary,
    ARRAY_DIMS(array_agg(f.total_fat)) AS total_fat_summary,
    ARRAY_DIMS(array_agg(f.protein)) AS protein_summary,
    ARRAY_DIMS(array_agg(f.calorie)) AS calorie_summary,
    ARRAY_DIMS(array_agg(f.total_carb)) AS total_carb_summary
FROM
    demographics d
LEFT JOIN
    foodlog f ON d.patientid = f.patientid
GROUP BY
    d.patientid, d.firstname, d.lastname
ORDER BY
    d.patientid;
---------------------------------------------------------------------------------------------------
		
--QUERY 36 Can you provide a summary of dietary information for each patient in JSON format, including their dietary fiber, sugar, total fat, protein, calorie, and total carbohydrate intake?
SELECT
    f.patientid,
    d.firstname,
    d.lastname,
    ARRAY_TO_JSON(ARRAY[f.dietary_fiber, f.sugar, f.total_fat, f.protein, f.calorie, f.total_carb]) AS dietary_info_json
FROM
    foodlog f
JOIN
    demographics d ON f.patientid = d.patientid
ORDER BY
    f.patientid;
---------------------------------------------------------------------------------------------------
		
--QUERY 37 Which patients have the highest and lowest recorded glucose values (blood sugar levels)?
SELECT
    patientid,
    GREATEST(MAX(glucose_value_mgdl), MAX(glucose_value_mgdl)) AS highest_glucose,
    LEAST(MIN(glucose_value_mgdl), MIN(glucose_value_mgdl)) AS lowest_glucose
FROM
    dexcom
GROUP BY
    patientid;

---------------------------------------------------------------------------------------------------
		
--QUERY 38 Find the average sample covariance between 'rmssd_ms' and 'mean_hr' for patients in the 'ibi' and 'hr' tables
-- Calculate the average of sample covariances between 'rmssd_ms' and 'mean_hr' for individual patients.

SELECT AVG(sample_covariance) AS avg_sample_covariance
FROM (
    -- Subquery: Calculate sample covariances for each patient and their heart rate data.
    SELECT i.patientid,
           COVAR_SAMP(i.rmssd_ms, h.mean_hr) AS sample_covariance
    FROM ibi i
    JOIN hr h ON i.patientid = h.patientid
    GROUP BY i.patientid
) AS subquery;

---------------------------------------------------------------------------------------------------
		
--QUERY 39 Calculate both the sample standard deviation and variance of 'glucose_value_mgdl' for male patients (gender = 'Male') in the 'dexcom' table.
SELECT STDDEV_SAMP(glucose_value_mgdl) AS sample_stddev,
       VARIANCE(glucose_value_mgdl) AS variance
FROM dexcom
WHERE patientid IN (
    SELECT patientid
    FROM demographics
    WHERE gender = 'MALE'
);

---------------------------------------------------------------------------------------------------
		
-- QUERY 40 Retrieve the patient IDs and the total number of unique characters in their last names. Order the results by the number of unique characters in descending order.

-- Calculate and order patients by the count of unique characters in their last names.
SELECT
  patientid, 
  CHAR_LENGTH(lastname) - CHAR_LENGTH(REGEXP_REPLACE(lastname, '(.).*?\\1', '\\1', 'g')) AS unique_char_count
-- Calculate the unique character count by subtracting the length after removing duplicate characters.
FROM demographics -- From the demographics table
ORDER BY unique_char_count DESC; -- Order the results in descending order of unique character count.


---------------------------------------------------------------------------------------------------
		
-- QUERY 41 Retrieve a list of patients along with their patient IDs and the DENSE RANK of their average glucose levels from the Dexcom table. Order the results by patient ID and rank in ascending order.
-- Rank patients by their average glucose values using DENSE_RANK.

-- Create a Common Table Expression (CTE) to calculate the average glucose values and rank patients.
WITH RankedPatients AS (
  SELECT
    d.patientid, 
    AVG(dex.glucose_value_mgdl) AS avg_glucose, 
    DENSE_RANK() OVER (ORDER BY AVG(dex.glucose_value_mgdl)) AS dense_rank -- Rank patients based on average glucose
  FROM demographics d
  LEFT JOIN dexcom dex ON d.patientid = dex.patientid
  GROUP BY d.patientid
)

-- Select patient ID, average glucose, and dense rank from the CTE.
SELECT
  patientid, 
  avg_glucose, 
  dense_rank -- Dense rank based on average glucose
FROM RankedPatients
ORDER BY patientid, dense_rank; -- Order the results by patient ID and dense rank.

-----------------------------------------------------------------------------------------------------
		
-- QUERY 42 Calculate the percent rank of each patient's maximum EDA value within their gender group

-- Create a Common Table Expression (CTE) named GenderMaxEDA
-- This CTE calculates the maximum electrodermal activity (EDA) for each patient by gender
WITH GenderMaxEDA AS (
    SELECT
        d.gender,                
        e.patientid,             
        MAX(e.max_eda) AS max_eda -- Calculate the maximum EDA for each patient
    FROM
        demographics d          
    JOIN
        eda e                    
    ON
        d.patientid = e.patientid -- Join the tables on patient ID
    GROUP BY
        d.gender, e.patientid   -- Group the results by gender and patient ID
)

-- Select and analyze the data from the GenderMaxEDA CTE
SELECT
    gender,                              
    patientid,                          
    max_eda,                             
    PERCENT_RANK() OVER (PARTITION BY gender ORDER BY max_eda) AS percent_rank_within_gender
    -- Calculate the percent rank of each patient's max EDA within their gender group
FROM
    GenderMaxEDA
ORDER BY
    gender, percent_rank_within_gender;  -- Order the results by gender and percent rank

---------------------------------------------------------------------------------------------------
		
-- QUERY 43 Group patients by gender and aggregate maximum EDA values into a JSON array.

-- Select gender and JSON array of maximum EDA values.
SELECT
    gender, 
    json_agg(max_eda) AS max_eda_values -- Aggregate maximum EDA values into a JSON array
FROM (
    -- Subquery to calculate maximum EDA values for each patient within each gender.
    SELECT
        d.gender, 
        e.patientid,
        ROUND(MAX(e.max_eda)::NUMERIC,2) AS max_eda -- Maximum EDA value
    FROM demographics d
    JOIN eda e ON d.patientid = e.patientid
    GROUP BY d.gender, e.patientid
) AS gender_max_eda -- Alias for the subquery
GROUP BY gender; -- Group the results by gender

---------------------------------------------------------------------------------------------------

--QUERY 44 Display the count patients in  diabetic,prediabetic and normal category based on HbA1c value using a Bar Chart.

--We'll categorize patients based on their HbA1c values into diabetic (HbA1c >= 6.5), prediabetic (HbA1c between 5.7 and 6.4), and normal (HbA1c < 5.7).

SELECT
    CASE
        WHEN hba1c >= 6.5 THEN 'Diabetic'
        WHEN hba1c >= 5.7 AND hba1c < 6.5 THEN 'Prediabetic'
        ELSE 'Normal'
    END AS hba1c_category,
    COUNT(*) AS patient_count
FROM
    demographics
GROUP BY
    hba1c_category; -- No Diabetic Patients
---------------------------------------------------------------------------------------------------
--QUERY 45 Display each patients HRV and Mean glucose value  as  3 different groups.  (uses the NTILE() function to distribute rows into 3 buckets) 

--The PostgreSQL NTILE() function allows you to divide ordered rows in the partition into a specified number of ranked groups as equal size as possible. 
--These ranked groups are called buckets.

SELECT
    patientid,
    hrv,
    glucose_value,
    NTILE(3) OVER (ORDER BY hrv) AS hrv_group,
    NTILE(3) OVER (ORDER BY glucose_value) AS glucose_group
FROM
    hrv_bloodsugar
ORDER BY patientid;
---------------------------------------------------------------------------------------------------

--QUERY 46 Using ROW_NUMBER() function to get the patient demographucs deatils with 3rd highest Hba1c value. 

WITH ranked_hba1c AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY hba1c DESC) AS rank
    FROM
        demographics d 
)
SELECT  * FROM ranked_hba1c
WHERE rank = 3;
---------------------------------------------------------------------------------------------------

--QUERY 47 Using cumulative distribution function calculate the Blood Sugar for each patient partitioned by gender.
--The CUME_DIST() function returns the cumulative distribution of a value within a set of values. 
--In other words, it returns the relative position of a value in a set of values.

   SELECT
       d.patientid,
       ROUND(AVG(dc.glucose_value_mgdl)::numeric,2)::double precision AS Blood_Sugar,
       d.gender,
       ROUND(cume_dist() OVER (PARTITION BY gender ORDER BY AVG(dc.glucose_value_mgdl))::numeric,2)::double precision AS cumulative_distribution
    FROM
        demographics d JOIN 
        dexcom dc ON d.patientid = dc.patientid
    GROUP BY d.patientid;

---------------------------------------------------------------------------------------------------
--QUERY 48 Categorize patients into age groups and calculate cumulative distribution of glucose values.

-- Select the age group, glucose value, and cumulative distribution.
SELECT
    age_group, 
    glucose_value_mgdl, 
    cume_dist() OVER (PARTITION BY age_group ORDER BY glucose_value_mgdl) AS glucose_cume_dist -- Calculate cumulative distribution
FROM (
    -- Subquery to calculate dynamically calculated age group and glucose values from the dexcom and demographics tables.
    SELECT
        CASE
            WHEN age >= 18 AND age < 30 THEN '18-29' -- Age group 18-29
            WHEN age >= 30 AND age < 45 THEN '30-44' -- Age group 30-44
            ELSE '45+' -- Age group 45+
        END AS age_group, -- Calculate age group based on age
        glucose_value_mgdl 
    FROM (
        SELECT
            EXTRACT(YEAR FROM AGE(dob)) AS age, -- Calculate age from date of birth (dob)
            glucose_value_mgdl 
        FROM dexcom
        JOIN demographics ON dexcom.patientid = demographics.patientid
    ) AS age_glucose
) AS age_group_glucose; -- Alias for the subquery
---------------------------------------------------------------------------------------------------
-- QUERY 49 Calculate the Median RMSSD Value from IBI Table per Patient
		
-- This query calculates the median HRV (Heart Rate Variability) for each unique patient.
-- HRV is an important metric for assessing heart health and stress levels.

SELECT
    patientid, -- Select the patient ID for identification in the result.
    percentile_cont(0.5) WITHIN GROUP (ORDER BY rmssd_ms * 600) AS median_hrv
    -- Calculate the 50th percentile (median) of HRV within each patient's data.
    -- The ORDER BY clause sorts the data by HRV values multiplied by 600 for ordering.

FROM
    ibi
    -- This query operates on the "ibi" table, which contains data related to heart rate variability.

GROUP BY
    patientid; -- Group the results by patient ID to calculate median HRV for each patient.
		
---------------------------------------------------------------------------------------------------
-- QUERY 50 Identify the patients with overlapping date ranges of EDA measurements
-- Find patients with overlapping date ranges of EDA measurements.
WITH OverlappingEda AS (
    SELECT
        patientid,
        range_intersect_agg(date_range) AS overlapping_ranges
    FROM (
        SELECT
            patientid,
            tsrange(datestamp, datestamp + interval '1 day', '[]') AS date_range
        FROM
            eda
    ) AS date_ranges
    GROUP BY
        patientid
    HAVING
        count(*) > 1
)
SELECT
    o.patientid,
    o.overlapping_ranges
FROM
    OverlappingEda o;
---------------------------------------------------------------------------------------------------
		
		
		
		
		