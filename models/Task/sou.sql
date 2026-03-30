{{ config(
    query_tag = 'dbt'
) }}

SELECT
   *
FROM SALESFORCE_RAW.SALESFORCE.ACCOUNT 
limit 2

