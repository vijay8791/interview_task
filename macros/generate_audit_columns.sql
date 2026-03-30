{% macro generate_audit_columns() %}
    {% set audit_columns = [
        ('current_user()',                                              'created_by'),
        ('convert_timezone(\'UTC\', current_timestamp())::timestamp_ntz', 'dbt_loaded_at'),
        ('\'{{ invocation_id }}\'',                                    'dbt_invocation_id'),
        ('\'{{ this.schema }}\'',                                      'dbt_schema'),
        ('\'{{ this.name }}\'',                                        'dbt_model_name')
    ] %}
    {% for expression, alias in audit_columns %}
        {{ expression }} as {{ alias }}
        {%- if not loop.last %},{% endif %}
    {% endfor %}
{% endmacro %}