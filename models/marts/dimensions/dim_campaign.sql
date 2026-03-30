{{
    config(
        materialized = 'table',
        tags = ['marts', 'dimensions']
    )
}}

with campaigns as (

    select * from {{ ref('stg_salesforce__campaign') }}

),

users as (

    select
        user_id,
        firstname || ' ' || lastname as owner_full_name
    from {{ ref('stg_salesforce__user') }}

),

final as (

    select
        md5(cast(c.campaign_id as varchar))  as campaign_sk,
        c.campaign_id,
        c.name              as campaign_name,
        c.type              as campaign_type,
        c.status            as campaign_status,
        c.isactive          as is_active,
        c.description,
        c.startdate         as start_date,
        c.enddate           as end_date,
        c.budgetedcost      as budgeted_cost,
        c.actualcost        as actual_cost,
        c.expectedrevenue   as expected_revenue,
        c.numbersent        as number_sent,
        c.numberofleads             as number_of_leads,
        c.numberofconvertedleads    as number_of_converted_leads,
        c.numberofcontacts          as number_of_contacts,
        c.numberofresponses         as number_of_responses,
        c.numberofopportunities     as number_of_opportunities,
        c.numberofwonopportunities  as number_of_won_opportunities,
        c.amountallopportunities    as amount_all_opportunities,
        c.amountwonopportunities    as amount_won_opportunities,
        case
            when c.numberofleads = 0 or c.numberofleads is null then null
            else c.numberofconvertedleads / c.numberofleads
        end                         as lead_conversion_rate,
        case
            when c.numberofopportunities = 0
              or c.numberofopportunities is null then null
            else c.numberofwonopportunities / c.numberofopportunities
        end                         as opportunity_win_rate,
        c.ownerid           as owner_id,
        u.owner_full_name,
        c.parentid          as parent_campaign_id,
        c.createddate       as created_at,
        c.lastmodifieddate  as last_modified_at

    from campaigns  c
    left join users u on c.ownerid = u.user_id

)

select * from final