create view {{CATALOG_NAME}}.{{SCHEMA_NAME}}.queue_time_summary_vw as
select 
sum(total_duration_ms - (execution_duration_ms + compilation_duration_ms)) * 100/sum(total_duration_ms) as queue_time_percentage
from system.query.history a
where 
compute.warehouse_id = '{{WAREHOUSE_ID}}'
AND start_time >= current_timestamp() - interval '{{TIME_INTERVAL}} hours'
and statement_type = '{{STATEMENT_TYPE}}';
