{{
    config(
        materialized = 'table',
        tags = ['intermediate']
    )
}}

with opportunities as (

    select * from {{ ref('stg_salesforce__opportunity') }}

),

accounts as (

    select
        account_id,
        name              as account_name,
        industry          as account_industry,
        type              as account_type,
        rating            as account_rating,
        annualrevenue     as account_annual_revenue,
        numberofemployees as account_employee_count,
        billingcountry    as account_billing_country,
        billingstate      as account_billing_state
    from {{ ref('stg_salesforce__account') }}

),

users as (

    select
        user_id,
        firstname || ' ' || lastname as owner_full_name,
        title                        as owner_title,
        department                   as owner_department
    from {{ ref('stg_salesforce__user') }}

),

campaigns as (

    select
        campaign_id,
        name   as campaign_name,
        type   as campaign_type,
        status as campaign_status
    from {{ ref('stg_salesforce__campaign') }}

),

stage_map as (

    select * from {{ ref('seed_opportunity_stage_map') }}

),

enriched as (

    select
        opp.opportunity_id,
        opp.accountid,
        opp.ownerid,
        opp.campaignid,
        opp.contactid,
        opp.name                        as opportunity_name,
        opp.type                        as opportunity_type,
        opp.stagename,
        opp.leadsource,
        opp.forecastcategory,
        opp.forecastcategoryname,
        sm.stage_label,
        sm.pipeline_phase,
        sm.sort_order                   as stage_sort_order,
        opp.amount,
        opp.probability,
        opp.expectedrevenue,
        opp.totalopportunityquantity,
        opp.isclosed,
        opp.iswon,
        opp.isprivate,
        opp.hasopportunitylineitem,
        opp.closedate,
        opp.createddate,
        opp.lastmodifieddate,
        opp.laststagechangedate,
        opp.lastactivitydate,
        opp.fiscalyear,
        opp.fiscalquarter,
        acc.account_name,
        acc.account_industry,
        acc.account_type,
        acc.account_rating,
        acc.account_annual_revenue,
        acc.account_employee_count,
        acc.account_billing_country,
        acc.account_billing_state,
        usr.owner_full_name,
        usr.owner_title,
        usr.owner_department,
        cam.campaign_name,
        cam.campaign_type,
        cam.campaign_status,
        datediff('day', opp.createddate, opp.closedate) as days_to_close,
        case
            when opp.iswon    then 'Won'
            when opp.isclosed then 'Lost'
            else 'Open'
        end                                             as opportunity_outcome,
        case
            when opp.totalopportunityquantity = 0
              or opp.totalopportunityquantity is null then null
            else opp.amount / opp.totalopportunityquantity
        end                                             as avg_unit_price

    from opportunities      opp
    left join accounts      acc on opp.accountid  = acc.account_id
    left join users         usr on opp.ownerid    = usr.user_id
    left join campaigns     cam on opp.campaignid = cam.campaign_id
    left join stage_map     sm  on opp.stagename  = sm.stage_name

)

select * from enriched