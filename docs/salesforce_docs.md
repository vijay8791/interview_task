{% docs opportunity_outcome %}
Derived field classifying each opportunity as Won, Lost, or Open.
- Won: isclosed = true and iswon = true
- Lost: isclosed = true and iswon = false
- Open: isclosed = false
{% enddocs %}

{% docs lead_lifecycle_stage %}
Derived field classifying each lead's current lifecycle position.
- Converted: lead has been converted to an account/contact/opportunity
- Deleted: lead record has been soft-deleted in Salesforce
- Active: lead is open and being worked
{% enddocs %}

{% docs days_to_close %}
Number of days between the opportunity created date and the close date.
Negative values indicate the close date was set before the record was created.
{% enddocs %}

{% docs days_to_convert %}
Number of days between the lead created date and the conversion date.
NULL for leads that have not yet been converted.
{% enddocs %}

{% docs account_sk %}
Surrogate key generated using md5() on the natural Salesforce account ID.
Used for joins between fact and dimension tables.
{% enddocs %}

{% docs dbt_loaded_at %}
UTC timestamp when this row was last loaded by dbt.
Generated via the generate_audit_columns() macro.
{% enddocs %}

{% docs is_sla_violation %}
Indicates whether the case breached its SLA agreement.
Sourced from the custom Salesforce field slaviolation__c.
{% enddocs %}

{% docs pipeline_phase %}
High-level grouping of opportunity stages for funnel reporting.
Values: Early, Mid, Late, Closed.
Sourced from seed_opportunity_stage_map.
{% enddocs %}