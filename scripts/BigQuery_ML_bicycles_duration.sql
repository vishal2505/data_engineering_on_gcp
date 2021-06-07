CREATE OR REPLACE MODEL
  bike_model.model
OPTIONS
  (input_label_cols=['duration'],
    model_type='linear_reg') AS
SELECT
  duration,
  start_station_name,
  CAST(EXTRACT(dayofweek
    FROM
      start_date) AS STRING) AS dayofweek,
  CAST(EXTRACT(hour
    FROM
      start_date) AS STRING) AS hourofday
FROM
  `bigquery-public-data`.london_bicycles.cycle_hire;

--

SELECT * FROM ML.EVALUATE(MODEL `bike_model.model`);

-- The mean absolute error is 1026 seconds or about 17 minutes. 
-- This means that we should expect to be able to predict the duration of bicycle rentals with an average error of about 17 minutes.


CREATE OR REPLACE MODEL
  bike_model.model_weekday
OPTIONS
  (input_label_cols=['duration'],
    model_type='linear_reg') AS
SELECT
  duration,
  start_station_name,
IF
  (EXTRACT(dayofweek
    FROM
      start_date) BETWEEN 2 AND 6,
    'weekday',
    'weekend') AS dayofweek,
  CAST(EXTRACT(hour
    FROM
      start_date) AS STRING) AS hourofday
FROM
  `bigquery-public-data`.london_bicycles.cycle_hire;


SELECT * FROM ML.EVALUATE(MODEL `bike_model.model_weekday`);

-- This model results in a mean absolute error of 967 seconds which is less than the 1026 seconds for the original model.

CREATE OR REPLACE MODEL
  bike_model.model_bucketized
OPTIONS
  (input_label_cols=['duration'],
    model_type='linear_reg') AS
SELECT
  duration,
  start_station_name,
IF
  (EXTRACT(dayofweek
    FROM
      start_date) BETWEEN 2 AND 6,
    'weekday',
    'weekend') AS dayofweek,
  ML.BUCKETIZE(EXTRACT(hour
    FROM
      start_date),
    [5, 10, 17]) AS hourofday
FROM
  `bigquery-public-data`.london_bicycles.cycle_hire;

SELECT * FROM ML.EVALUATE(MODEL `bike_model.model_bucketized`);


-- This model results in a mean absolute error of 901 seconds which is less than the 967 seconds for the weekday-weekend model. Futher improvement!


-- =================
-- Make Predictions
-- =================


-- Our best model contains several data transformations. Wouldn’t it be nice if BigQuery could remember the sets of transformations we did at the time of training 
-- and automatically apply them at the time of prediction? It can, using the TRANSFORM clause!

CREATE OR REPLACE MODEL
  bike_model.model_bucketized TRANSFORM(* EXCEPT(start_date),
  IF
    (EXTRACT(dayofweek
      FROM
        start_date) BETWEEN 2 AND 6,
      'weekday',
      'weekend') AS dayofweek,
    ML.BUCKETIZE(EXTRACT(HOUR
      FROM
        start_date),
      [5, 10, 17]) AS hourofday )
OPTIONS
  (input_label_cols=['duration'],
    model_type='linear_reg') AS
SELECT
  duration,
  start_station_name,
  start_date
FROM
  `bigquery-public-data`.london_bicycles.cycle_hire;

SELECT
  *
FROM
  ML.PREDICT(MODEL bike_model.model_bucketized,
    (
    SELECT
      'Park Lane , Hyde Park' AS start_station_name,
      CURRENT_TIMESTAMP() AS start_date) );

-- Row	predicted_duration	start_station_name	start_date	
--1	
--2160.730034059081
--Park Lane , Hyde Park
--2021-06-07 07:31:17.374929 UTC

-- To make batch predictions on a sample of 100 rows in the training set use the query:

SELECT
  *
FROM
  ML.PREDICT(MODEL bike_model.model_bucketized,
    (
    SELECT
      start_station_name,
      start_date
    FROM
      `bigquery-public-data`.london_bicycles.cycle_hire
    LIMIT
      100) );





