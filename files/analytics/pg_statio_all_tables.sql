SELECT row_to_json(t)
from (
SELECT *,
((heap_blks_hit*100) / NULLIF((heap_blks_hit + heap_blks_read), 0)) AS heap_blks_cache_ratio,
((idx_blks_hit*100) / NULLIF((idx_blks_hit + idx_blks_read), 0)) AS idx_blks_cache_ratio,
((tidx_blks_hit*100) / NULLIF((tidx_blks_hit + tidx_blks_read), 0)) AS tidx_blks_cache_ratio,
((toast_blks_hit*100) / NULLIF((toast_blks_hit + toast_blks_read), 0)) AS toast_blks_cache_ratio
FROM pg_statio_all_tables
) t;
