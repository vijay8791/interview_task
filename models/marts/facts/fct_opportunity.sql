{{
    config(
        materialized = 'incremental',
        unique_key   = 'opportunity_id',
        on_schema_change = 'sync_all_columns',
        tags = ['marts', 'facts', 'daily']
    )
}}

with opportunity_enriched as (

    select * from {{ ref('int_opportunity_enriched') }}

    {% if is_incremental() %}
        where lastmodifieddate > (select max(last_modified_at) from {{ this }})
    {% endif %}

),

dim_account as (

    select account_id, account_sk
    from {{ ref('dim_account') }}

),

dim_user as (

    select user_id, user_sk
    from {{ ref('dim_user') }}

),

dim_campaign as (

    select campaign_id, campaign_sk
    from {{ ref('dim_campaign') }}

),

ranked as (

    select
        opportunity_id,
        row_number() over (
            partition by accountid
            order by amount desc nulls last
        )                                               as rank_by_amount_in_account,

        row_number() over (
            partition by accountid
            order by createddate desc
        )                                               as rank_by_recency_in_account,

        sum(amount) over (
            partition by accountid
        )                                               as total_account_pipeline,

        lag(stagename) over (
            partition by accountid
            order by createddate
        )                                               as prev_opportunity_stage,

        sum(case when iswon then amount else 0 end) over (
            partition by fiscalyear, fiscalquarter
            order by createddate
            rows between unbounded preceding and current row
        )                                               as running_won_amount_in_quarter

    from opportunity_enriched

),

final as (

    select
        md5(cast(oe.opportunity_id as varchar))     as opportunity_sk,
        oe.opportunity_id,
        da.account_sk,
        du.user_sk                                  as owner_sk,
        dc.campaign_sk,
        oe.accountid                                as account_id,
        oe.ownerid                                  as owner_id,
        oe.campaignid                               as campaign_id,
        oe.contactid                                as contact_id,
        oe.opportunity_name,
        oe.opportunity_type,
        oe.stagename,
        oe.stage_label,
        oe.pipeline_phase,
        oe.stage_sort_order,
        oe.leadsource                               as lead_source,
        oe.forecastcategory                         as forecast_category,
        oe.forecastcategoryname                     as forecast_category_name,
        oe.account_name,
        oe.account_industry,
        oe.account_billing_country,
        oe.owner_full_name,
        oe.owner_department,
        oe.campaign_name,
        oe.campaign_type,
        oe.amount,
        oe.probability,
        oe.expectedrevenue                          as expected_revenue,
        oe.totalopportunityquantity                 as total_quantity,
        oe.avg_unit_price,
        oe.isclosed                                 as is_closed,
        oe.iswon                                    as is_won,
        oe.isprivate                                as is_private,
        oe.opportunity_outcome,
        oe.closedate                                as close_date,
        oe.createddate                              as created_at,
        oe.lastmodifieddate                         as last_modified_at,
        oe.laststagechangedate                      as last_stage_change_date,
        oe.fiscalyear                               as fiscal_year,
        oe.fiscalquarter                            as fiscal_quarter,
        oe.days_to_close,
        r.rank_by_amount_in_account,
        r.rank_by_recency_in_account,
        r.total_account_pipeline,
        r.prev_opportunity_stage,
        r.running_won_amount_in_quarter,
        {{ generate_audit_columns() }}

    from opportunity_enriched   oe
    left join dim_account       da  on oe.accountid  = da.account_id
    left join dim_user          du  on oe.ownerid    = du.user_id
    left join dim_campaign      dc  on oe.campaignid = dc.campaign_id
    left join ranked            r   on oe.opportunity_id = r.opportunity_id

)

select * from final