-- You can do some pretty useful things with arrays like:

-- finding the number of elements with ARRAY_LENGTH(<array>)
-- deduplicating elements with ARRAY_AGG(DISTINCT <field>)
-- ordering elements with ARRAY_AGG(<field> ORDER BY <field>)
-- limiting ARRAY_AGG(<field> LIMIT 5)

SELECT
  fullVisitorId,
  date,
  ARRAY_AGG(DISTINCT v2ProductName) AS products_viewed,
  ARRAY_LENGTH(ARRAY_AGG(DISTINCT v2ProductName)) AS distinct_products_viewed,
  ARRAY_AGG(DISTINCT pageTitle) AS pages_viewed,
  ARRAY_LENGTH(ARRAY_AGG(DISTINCT pageTitle)) AS distinct_pages_viewed
  FROM `data-to-insights.ecommerce.all_sessions`
WHERE visitId = 1501570398
GROUP BY fullVisitorId, date
ORDER BY date;


SELECT
  visitId,
  hits.page.pageTitle
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170801`
WHERE visitId = 1501570398;
-- ERROR => Cannot access field product on a value with type ARRAY> at [5:8]


--Before we can query REPEATED fields (arrays) normally, you must first break the arrays back into rows.

SELECT DISTINCT
  visitId,
  h.page.pageTitle
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170801`,
UNNEST(hits) AS h
WHERE visitId = 1501570398
LIMIT 10;

-- We need to UNNEST() arrays to bring the array elements back into rows
-- UNNEST() always follows the table name in your FROM clause (think of it conceptually like a pre-joined table)


--creating nested data with array and structs

SELECT STRUCT("Rudisha" as name, [23.4, 26.3, 26.4, 26.1] as splits) AS runner