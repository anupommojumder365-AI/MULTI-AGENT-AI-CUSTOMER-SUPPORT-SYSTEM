create function public.novacart_order_api(action text, customer text default null, order_number text default null) returns jsonb language plpgsql security invoker set search_path='' as $$
declare o public.novacart_orders; begin
 if action='customer_lookup' then return (select to_jsonb(c) from public.novacart_customers c where c.id=customer); end if;
 if action='order_history' then return (select coalesce(jsonb_agg(o),'[]') from public.novacart_orders o where o.customer_id=customer); end if;
 select * into o from public.novacart_orders where id=order_number and customer_id=customer;
 if not found then return jsonb_build_object('error','not_found'); end if;
 if action='order_lookup' then return to_jsonb(o);
 elsif action='shipping_status' then return jsonb_build_object('status',o.status,'tracking',o.tracking,'carrier',o.carrier,'promised_at',o.promised_at);
 elsif action='refund_status' then return (select coalesce(jsonb_agg(r),'[]') from public.novacart_refund_requests r where r.order_id=o.id);
 elsif action='refund_eligibility' then return jsonb_build_object('eligible',o.status='lost' or (o.status in ('processing','shipped','delayed') and now()>=o.promised_at+interval '7 days'),'approval_required',true,'simulated',true);
 else raise exception 'INVALID_ACTION'; end if;
end $$;
revoke all on function public.novacart_order_api from public,anon; grant execute on function public.novacart_order_api to authenticated,service_role;
create function public.novacart_record_failure(p jsonb) returns jsonb language plpgsql security invoker set search_path='' as $$
declare tid uuid; begin
 tid:=(p->>'ticket_id')::uuid;
 if tid is not null then
 update public.novacart_tickets set status='error',updated_at=now() where id=tid and status='processing';
 insert into public.novacart_escalations(ticket_id,reason) values(tid,'provider_failure') on conflict(ticket_id) do nothing;
 end if;
 insert into public.novacart_workflow_logs(ticket_id,event,detail) values(tid,'workflow_error',jsonb_build_object('execution_id',left(p->>'execution_id',100),'message',left(p->>'message',500)));
 return jsonb_build_object('recorded',true,'ticket_id',tid);
end $$;
revoke all on function public.novacart_record_failure from public,anon,authenticated; grant execute on function public.novacart_record_failure to service_role;
create function public.novacart_maintenance() returns jsonb language plpgsql security invoker set search_path='' as $$
declare stale int; begin
 with u as (update public.novacart_tickets set status='error',updated_at=now() where status='processing' and updated_at<now()-interval '15 minutes' returning id)
 insert into public.novacart_escalations(ticket_id,reason) select id,'stale_execution' from u on conflict(ticket_id) do nothing;
 get diagnostics stale=row_count;
 insert into public.novacart_workflow_logs(event,detail) values('maintenance_report',jsonb_build_object('stale_escalations',stale,'pending_approvals',(select count(*) from public.novacart_refund_requests where status='pending'),'held_messages',(select count(*) from public.novacart_outbox where status='held')));
 return jsonb_build_object('stale_escalations',stale,'outbound_sent',0);
end $$;
revoke all on function public.novacart_maintenance from public,anon,authenticated; grant execute on function public.novacart_maintenance to service_role;
create function public.novacart_retry_case(ticket uuid) returns jsonb language plpgsql security invoker set search_path='' as $$
declare t public.novacart_tickets; result jsonb; begin
 select * into t from public.novacart_tickets where id=ticket for update;
 if not found or t.status<>'error' then raise exception 'NOT_RETRYABLE'; end if;
 if (select count(*) from public.novacart_workflow_logs where ticket_id=ticket and event='retry_requested')>=3 then raise exception 'RETRY_LIMIT'; end if;
 insert into public.novacart_workflow_logs(ticket_id,event) values(ticket,'retry_requested');
 update public.novacart_tickets set status='processing',updated_at=now() where id=ticket;
 select jsonb_build_object('ticket_id',t.id,'duplicate',false,'customer',(select jsonb_build_object('id',c.id,'name',c.name) from public.novacart_customers c where c.id=t.customer_id),'order',(select to_jsonb(o) from public.novacart_orders o where o.id=t.order_id),'message',(select body from public.novacart_messages where ticket_id=t.id and direction='inbound' order by created_at limit 1),'policies',(select jsonb_agg(jsonb_build_object('id',id,'title',title,'content',content)) from public.novacart_knowledge where active),'execution_mode','sandbox','agents','[]'::jsonb) into result;
 return result;
end $$;
revoke all on function public.novacart_retry_case from public,anon,authenticated; grant execute on function public.novacart_retry_case to service_role;
