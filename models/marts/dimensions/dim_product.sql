{{
    config(
        materialized = 'table',
        tags = ['marts', 'dimensions']
    )
}}

with products as (

    select * from {{ ref('stg_salesforce__product_2') }}

),

pricebook_entries as (

    select
        product2id,
        min(unitprice) as min_unit_price,
        max(unitprice) as max_unit_price,
        avg(unitprice) as avg_unit_price,
        count(*)       as pricebook_entry_count
    from {{ ref('stg_salesforce__pricebook_entry') }}
    where isactive = true
      and isdeleted = false
    group by 1

),

final as (

    select
        md5(cast(p.product_id as varchar))  as product_sk,
        p.product_id,
        p.name                      as product_name,
        p.productcode               as product_code,
        p.stockkeepingunit          as sku,
        p.family                    as product_family,
        p.type                      as product_type,
        p.productclass              as product_class,
        p.quantityunitofmeasure     as unit_of_measure,
        p.description,
        p.isactive                  as is_active,
        p.isarchived                as is_archived,
        pe.min_unit_price,
        pe.max_unit_price,
        pe.avg_unit_price,
        pe.pricebook_entry_count,
        p.createddate               as created_at,
        p.lastmodifieddate          as last_modified_at

    from products   p
    left join pricebook_entries pe on p.product_id = pe.product2id

)

select * from final