SELECT row_to_json(t)
from (
SELECT * FROM pg_stat_activity
) t;
