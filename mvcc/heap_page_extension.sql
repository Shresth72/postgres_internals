create function heap_page(relname text, pageno_from integer, pageno_to integer)

returns table (ctid tid, state text, xmin text, xmin_age integer, xmax text,
hhu text, /*heap hot update - the version is referenced from an index, traverse to the next version using ctid ref */
hot text, /* heap only tuple - the version is created only in heap without the index update*/
t_ctid tid
)
AS $$
select (pageno,lp)::text::tid as ctid,
    case lp_flags
    when 0 then 'unused'
    when 1 then 'normal'
    when 2 then 'redirect to '||lp_off
    when 3 then 'dead'
    end as state,
    t_xmin || case
    when (t_infomask & 256+512) = 256+512 then ' f'
    when (t_infomask & 256) > 0 then ' c'
    when (t_infomask & 512) > 0 then ' a'
    else ''
    end as xmin,
    age(t_xmin) as xmin_age,
    t_xmax || case
    when (t_infomask & 1024) > 0 then ' c'
    when (t_infomask & 2048) > 0 then ' a'
    else ''
    end as xmax,
    case when (t_infomask2 & 16384) > 0 then 't' end as hhu,
    case when (t_infomask2 & 32768) > 0 then 't' end as hot,
    t_ctid
from generate_series(pageno_from, pageno_to) p(pageno),
    heap_page_items(get_raw_page(relname,pageno))
order by pageno, lp;
$$ language sql;
