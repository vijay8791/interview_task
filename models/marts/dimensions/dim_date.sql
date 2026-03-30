{{
    config(
        materialized = 'table',
        tags = ['marts', 'dimensions']
    )
}}

with date_spine as (

    select
        dateadd('day', seq4(), '{{ var("min_date") }}'::date) as date_day
    from table(generator(rowcount => 4383))  -- 2018-01-01 to 2029-12-31 (~12 years)

),

final as (

    select
        date_day,
        year(date_day)                                          as year_number,
        month(date_day)                                         as month_number,
        monthname(date_day)                                     as month_name,
        day(date_day)                                           as day_of_month,
        dayofweek(date_day)                                     as day_of_week,
        dayname(date_day)                                       as day_name,
        weekofyear(date_day)                                    as week_of_year,
        quarter(date_day)                                       as quarter_number,
        'Q' || quarter(date_day) || ' ' || year(date_day)      as quarter_label,
        case when dayofweek(date_day) in (0, 6) then true
             else false end                                     as is_weekend,
        case when date_day = last_day(date_day) then true
             else false end                                     as is_last_day_of_month,
        date_trunc('month', date_day)                           as first_day_of_month,
        last_day(date_day)                                      as last_day_of_month,
        date_trunc('year', date_day)                            as first_day_of_year,
        -- fiscal year (April start based on var)
        case when month(date_day) >= {{ var('fiscal_year_start_month') }}
             then year(date_day) + 1
             else year(date_day)
        end                                                     as fiscal_year,
        case
            when month(date_day) >= {{ var('fiscal_year_start_month') }}
            then ceil((month(date_day) - {{ var('fiscal_year_start_month') }} + 1) / 3.0)
            else ceil((month(date_day) + 12 - {{ var('fiscal_year_start_month') }} + 1) / 3.0)
        end                                                     as fiscal_quarter

    from date_spine

)

select * from final