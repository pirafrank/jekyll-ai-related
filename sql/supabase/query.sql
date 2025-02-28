-- list available tables
select tablename
from pg_tables
where schemaname = 'public'
order by tablename;

-- list available indexes and their table
select
  i.indexname,
  i.tablename
from pg_indexes i
where i.schemaname = 'public'
order by i.tablename;

-- list available similarity search functions
select  p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
from pg_proc p
join pg_namespace n on p.pronamespace = n.oid
where n.nspname = 'public'
and p.proname like '%similarity%'
order by p.proname;
;
