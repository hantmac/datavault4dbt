{%- macro snowflake__sat_v1(sat_v0, hashkey, hashdiff, src_ldts, src_rsrc, ledts_alias) -%}

{%- set end_of_all_times = var('dbtvault_scalefree.end_of_all_times','8888-12-31T23-59-59') -%}
{%- set timestamp_format = var('dbtvault_scalefree.timestamp_format','%Y-%m-%dT%H-%M-%S') -%}
{%- set hash = var('dbtvault_scalefree.hash', 'MD5') -%}
{%- set hash_dtype = var('dbtvault_scalefree.hash_datatype', 'STRING') -%}
{%- set hash_alg, unknown_key, error_key = dbtvault_scalefree.hash_default_values(hash_function=hash,hash_datatype=hash_dtype) -%}

{%- set source_relation = ref(sat_v0) -%}
{%- set all_columns = dbtvault_scalefree.source_columns(source_relation=source_relation) -%}
{%- set exclude = [hashkey, hashdiff, src_ldts, src_rsrc] -%}
{%- set source_columns_to_select = dbtvault_scalefree.process_columns_to_select(all_columns, exclude) -%}

{{ dbtvault_scalefree.prepend_generated_by() }}

WITH
{#- Calculate ledts based on the ldts of the earlier record. #}
end_dated_source AS 
(    
    SELECT
        {{ hashkey }},
        {{ src_rsrc }},
        {{ src_ldts }},
        COALESCE(LEAD({{ src_ldts }} - INTERVAL '1 MICROSECOND') OVER (PARTITION BY {{ hashkey }} ORDER BY {{ src_ldts }}),{{ dbtvault_scalefree.string_to_timestamp(timestamp_format['snowflake'], end_of_all_times['snowflake']) }}) AS {{ ledts_alias }},
        {{ hashdiff }},
        {{ dbtvault_scalefree.print_list(source_columns_to_select) | lower }}
    FROM 
        {{ source_relation | lower }}
    WHERE 
        {{ hashdiff }} != {{ error_key }}
)
SELECT 
  * 
FROM 
  end_dated_source

{%- endmacro -%}
