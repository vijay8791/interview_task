{{
    config(
        materialized = 'table',
        tags = ['marts', 'dimensions']
    )
}}

with accounts as (

    select * from {{ ref('stg_salesforce__account') }}

),

users as (

    select
        user_id,
        firstname || ' ' || lastname as owner_full_name
    from {{ ref('stg_salesforce__user') }}

),

final as (

    select
        md5(cast(a.account_id as varchar))  as account_sk,
        a.account_id,
        a.name                  as account_name,
        a.type                  as account_type,
        a.industry,
        a.rating,
        a.website,
        a.accountnumber         as account_number,
        a.ownership,
        a.tickersymbol          as ticker_symbol,
        a.description,
        a.annualrevenue         as annual_revenue,
        a.numberofemployees     as number_of_employees,
        a.billingstreet         as billing_street,
        a.billingcity           as billing_city,
        a.billingstate          as billing_state,
        a.billingpostalcode     as billing_postal_code,
        a.billingcountry        as billing_country,
        a.sla__c                as sla_tier,
        a.slaexpirationdate__c  as sla_expiration_date,
        a.slaserialnumber__c    as sla_serial_number,
        a.customerpriority__c   as customer_priority,
        a.active__c             as is_active,
        a.ownerid               as owner_id,
        u.owner_full_name,
        a.parentid              as parent_account_id,
        a.createddate           as created_at,
        a.lastmodifieddate      as last_modified_at

    from accounts   a
    left join users u on a.ownerid = u.user_id

)

select * from final