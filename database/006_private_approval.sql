alter function public.novacart_approve(uuid,text,text) set schema novacart_private;
grant usage on schema novacart_private to authenticated;
create function public.novacart_approve(refund uuid, decision text, note text) returns jsonb language sql security invoker set search_path='' as $$ select novacart_private.novacart_approve(refund,decision,note) $$;
revoke all on function public.novacart_approve from public,anon; grant execute on function public.novacart_approve to authenticated;
