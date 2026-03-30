{{
    config(
        materialized = 'table',
        tags = ['marts', 'dimensions']
    )
}}

with users as (

    select * from {{ ref('stg_salesforce__user') }}

),

user_roles as (

    select
        user_role_id,
        name as role_name
    from {{ ref('stg_salesforce__user_role') }}

),

final as (

    select
        md5(cast(u.user_id as varchar))  as user_sk,
        u.user_id,
        u.username,
        u.firstname                         as first_name,
        u.lastname                          as last_name,
        u.firstname || ' ' || u.lastname    as full_name,
        u.alias,
        u.title,
        u.department,
        u.division,
        u.companyname                       as company_name,
        u.employeenumber                    as employee_number,
        u.email,
        u.phone,
        u.mobilephone                       as mobile_phone,
        u.usertype                          as user_type,
        u.isactive                          as is_active,
        u.forecastenabled                   as is_forecast_enabled,
        u.timezonesidkey                    as timezone,
        u.localesidkey                      as locale,
        u.languagelocalekey                 as language,
        u.userroleid                        as user_role_id,
        ur.role_name,
        u.managerid                         as manager_id,
        u.profileid                         as profile_id,
        u.lastlogindate                     as last_login_at,
        u.createddate                       as created_at,
        u.lastmodifieddate                  as last_modified_at

    from users      u
    left join user_roles ur on u.userroleid = ur.user_role_id

)

select * from final