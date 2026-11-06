-- Synthetic historical queue fixtures; these are not successful AI executions.
insert into public.novacart_tickets(external_id,customer_id,order_id,status,intent,priority,response)
select 'seed-history-'||i,o.customer_id,o.id,'review',case when o.status='lost' then 'refund' when o.status='delivered' then 'return' else 'shipping' end,'normal','Synthetic historical demonstration ticket. Human review pending.'
from generate_series(1,20) i join public.novacart_orders o on o.id='NC-O'||lpad(i::text,4,'0') on conflict(external_id) do nothing;
insert into public.novacart_messages(ticket_id,direction,body)
select id,'inbound',case when intent='refund' then 'My parcel was marked lost. Please review a refund.' when intent='return' then 'I would like to return the item. What should I do next?' else 'Please help me check my delivery status.' end
from public.novacart_tickets t where external_id like 'seed-history-%' and not exists(select 1 from public.novacart_messages m where m.ticket_id=t.id);
insert into public.novacart_refund_requests(ticket_id,order_id,amount,reason)
select t.id,o.id,o.total,'synthetic_historical_lost_parcel' from public.novacart_tickets t join public.novacart_orders o on o.id=t.order_id where t.external_id like 'seed-history-%' and o.status='lost' on conflict(order_id) do nothing;
insert into public.novacart_escalations(ticket_id,reason)
select id,'synthetic_historical_review' from public.novacart_tickets where external_id like 'seed-history-%' on conflict(ticket_id) do nothing;
insert into public.novacart_audit_logs(actor,event,entity,detail) values('demo_seed','synthetic_historical_data_loaded','NovaCart',jsonb_build_object('not_ai_execution',true));
