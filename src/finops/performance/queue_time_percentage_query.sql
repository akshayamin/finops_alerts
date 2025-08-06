create view aa_catalog.dw_ops.queue_time_summary_vw as
select 
sum(total_duration_ms - (execution_duration_ms + compilation_duration_ms)) * 100/sum(total_duration_ms) as queue_time_percentage
from system.query.history a
where 
compute.warehouse_id = '4b9b953939869799'
AND start_time >= current_timestamp() - interval '26 hours'
and statement_type = 'SELECT';
