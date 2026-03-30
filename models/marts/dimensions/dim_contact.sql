{{
    config(
        materialized = 'table',
        tags = ['marts', 'dimensions']
    )
}}

with contacts as (

    select * from {{ ref('stg_salesforce__contact') }}

),

accounts as (

    select
        account_id,
        name as account_name
    from {{ ref('stg_salesforce__account') }}

),

final as (

    select
    md5(cast(c.contact_id as varchar))  as contact_sk,
        c.contact_id,
        c.salutation,
        c.firstname                             as first_name,
        c.lastname                              as last_name,
        c.firstname || ' ' || c.lastname        as full_name,
        c.title,
        c.department,
        c.email,
        c.phone,
        c.mobilephone                           as mobile_phone,
        c.mailingstreet                         as mailing_street,
        c.mailingcity                           as mailing_city,
        c.mailingstate                          as mailing_state,
        c.mailingpostalcode                     as mailing_postal_code,
        c.mailingcountry                        as mailing_country,
        c.leadsource                            as lead_source,
        c.birthdate,
        c.hasoptedoutofemail                    as has_opted_out_of_email,
        c.hasoptedoutoffax                      as has_opted_out_of_fax,
        c.donotcall                             as do_not_call,
        c.level__c                              as contact_level,
        c.languages__c                          as languages,
        c.accountid                             as account_id,
        acc.account_name,
        c.ownerid                               as owner_id,
        c.reportstoid                           as reports_to_id,
        c.createddate                           as created_at,
        c.lastmodifieddate                      as last_modified_at

    from contacts   c
    left join accounts acc on c.accountid = acc.account_id

)

select * from final