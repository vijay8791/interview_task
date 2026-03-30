{{
    config(
        materialized = 'table',
        tags = ['marts', 'facts', 'daily']
    )
}}

with case_enriched as (

    select * from {{ ref('int_case_enriched') }}

),

dim_account as (

    select account_id, account_sk
    from {{ ref('dim_account') }}

),

dim_contact as (

    select contact_id, contact_sk
    from {{ ref('dim_contact') }}

),

dim_user as (

    select user_id, user_sk
    from {{ ref('dim_user') }}

),

window_metrics as (

    select
        case_id,
        row_number() over (
            partition by accountid
            order by createddate desc
        )                                           as case_recency_rank_in_account,

        count(*) over (
            partition by accountid
        )                                           as total_cases_for_account,

        count(*) over (
            partition by accountid, case_type
        )                                           as cases_by_type_for_account,

        sum(case when isclosed then 1 else 0 end) over (
            partition by accountid
        )                                           as closed_cases_for_account,

        lag(case_status) over (
            partition by accountid
            order by createddate
        )                                           as prev_case_status

    from case_enriched

),

final as (

    select
        md5(cast(ce.case_id as varchar))            as case_sk,
        ce.case_id,
        ce.casenumber                               as case_number,
        da.account_sk,
        dc.contact_sk,
        du.user_sk                                  as owner_sk,
        ce.accountid                                as account_id,
        ce.contactid                                as contact_id,
        ce.ownerid                                  as owner_id,
        ce.productid                                as product_id,
        ce.case_type,
        ce.case_status,
        ce.case_reason,
        ce.case_origin,
        ce.subject,
        ce.priority,
        ce.account_name,
        ce.account_industry,
        ce.contact_full_name,
        ce.contact_email,
        ce.owner_full_name,
        ce.owner_department,
        ce.isclosed                                 as is_closed,
        ce.isescalated                              as is_escalated,
        ce.is_sla_violation,
        ce.resolved_within_sla,
        ce.createddate                              as created_at,
        ce.closeddate                               as closed_at,
        ce.lastmodifieddate                         as last_modified_at,
        ce.slastartdate                             as sla_start_date,
        ce.slaexitdate                              as sla_exit_date,
        ce.hours_to_resolve,
        ce.days_to_resolve,
        ce.total_status_changes,
        ce.first_status_change_date,
        ce.last_status_change_date,
        wm.case_recency_rank_in_account,
        wm.total_cases_for_account,
        wm.cases_by_type_for_account,
        wm.closed_cases_for_account,
        wm.prev_case_status,
        {{ generate_audit_columns() }}

    from case_enriched          ce
    left join dim_account       da  on ce.accountid = da.account_id
    left join dim_contact       dc  on ce.contactid = dc.contact_id
    left join dim_user          du  on ce.ownerid   = du.user_id
    left join window_metrics    wm  on ce.case_id   = wm.case_id

)

select * from final