{{
    config(
        materialized = 'table',
        tags = ['marts', 'facts', 'daily']
    )
}}

with lead_enriched as (

    select * from {{ ref('int_lead_enriched') }}

),

dim_user as (

    select user_id, user_sk
    from {{ ref('dim_user') }}

),

window_metrics as (

    select
        lead_id,
        row_number() over (
            partition by industry, leadsource
            order by createddate desc
        )                                               as recency_rank_in_industry_source,

        count(*) over (
            partition by company
        )                                               as total_leads_from_company,

        count(*) over (
            partition by ownerid
        )                                               as total_leads_for_owner,

        sum(case when isconverted then 1 else 0 end) over (
            partition by ownerid
        )                                               as converted_leads_for_owner,

        lag(lead_status) over (
            partition by ownerid
            order by createddate
        )                                               as prev_lead_status_for_owner

    from lead_enriched

),

final as (

    select
        md5(cast(le.lead_id as varchar))            as lead_sk,
        le.lead_id,
        du.user_sk                                  as owner_sk,
        le.ownerid                                  as owner_id,
        le.convertedaccountid                       as converted_account_id,
        le.convertedcontactid                       as converted_contact_id,
        le.convertedopportunityid                   as converted_opportunity_id,
        le.lead_full_name,
        le.title,
        le.company,
        le.industry,
        le.leadsource                               as lead_source,
        le.lead_status,
        le.status_label,
        le.status_sort_order,
        le.rating,
        le.product_interest,
        le.annualrevenue                            as annual_revenue,
        le.numberofemployees                        as number_of_employees,
        le.city,
        le.state,
        le.country,
        le.email,
        le.phone,
        le.owner_full_name,
        le.owner_department,
        le.isconverted                              as is_converted,
        le.hasoptedoutofemail                       as has_opted_out_of_email,
        le.donotcall                                as do_not_call,
        le.lead_lifecycle_stage,
        le.createddate                              as created_at,
        le.converteddate                            as converted_at,
        le.lastmodifieddate                         as last_modified_at,
        le.lastactivitydate                         as last_activity_at,
        le.days_to_convert,
        wm.recency_rank_in_industry_source,
        wm.total_leads_from_company,
        wm.total_leads_for_owner,
        wm.converted_leads_for_owner,
        wm.prev_lead_status_for_owner,
        case
            when wm.total_leads_for_owner = 0
              or wm.total_leads_for_owner is null then null
            else wm.converted_leads_for_owner / wm.total_leads_for_owner
        end                                         as owner_conversion_rate,
        {{ generate_audit_columns() }}

    from lead_enriched              le
    left join dim_user              du  on le.ownerid = du.user_id
    left join window_metrics        wm  on le.lead_id = wm.lead_id

)

select * from final