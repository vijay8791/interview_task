{{
    config(
        materialized = 'table',
        tags = ['intermediate']
    )
}}

with leads as (

    select * from {{ ref('stg_salesforce__lead') }}

),

users as (

    select
        user_id,
        firstname || ' ' || lastname as owner_full_name,
        department                   as owner_department
    from {{ ref('stg_salesforce__user') }}

),

status_map as (

    select * from {{ ref('seed_lead_status_map') }}

),

enriched as (

    select
        l.lead_id,
        l.ownerid,
        l.convertedaccountid,
        l.convertedcontactid,
        l.convertedopportunityid,
        l.salutation,
        l.firstname,
        l.lastname,
        l.firstname || ' ' || l.lastname as lead_full_name,
        l.title,
        l.company,
        l.industry,
        l.leadsource,
        l.status                          as lead_status,
        l.rating,
        l.annualrevenue,
        l.numberofemployees,
        l.productinterest__c              as product_interest,
        l.currentgenerators__c            as current_generators,
        l.numberoflocations__c            as number_of_locations,
        l.email,
        l.phone,
        l.city,
        l.state,
        l.country,
        l.isconverted,
        l.isdeleted,
        l.hasoptedoutofemail,
        l.donotcall,
        l.createddate,
        l.converteddate,
        l.lastmodifieddate,
        l.lastactivitydate,
        usr.owner_full_name,
        usr.owner_department,
        sm.status_label,
        sm.is_active        as status_is_active,
        sm.is_converted     as status_is_converted,
        sm.sort_order       as status_sort_order,
        datediff('day', l.createddate, l.converteddate) as days_to_convert,
        case
            when l.isconverted then 'Converted'
            when l.isdeleted   then 'Deleted'
            else 'Active'
        end                              as lead_lifecycle_stage

    from leads          l
    left join users     usr on l.ownerid  = usr.user_id
    left join status_map sm on l.status   = sm.lead_status

)

select * from enriched