create function public.novacart_prepare(p jsonb) returns jsonb language plpgsql security invoker set search_path='' as $$
declare c public.novacart_customers; o public.novacart_orders; t public.novacart_tickets; policies jsonb; eligible boolean:=false; why text; begin
 if jsonb_typeof(p)<>'object' or coalesce(length(trim(p->>'external_id')),0) not between 1 and 200 or coalesce(length(trim(p->>'message')),0) not between 1 and 8000 or coalesce(p->>'email','') !~ '^[A-Za-z0-9._%+-]+@example[.]invalid$' then raise exception 'INVALID_INPUT'; end if;
 if p->>'verified_identity' is distinct from 'true' then raise exception 'IDENTITY_NOT_VERIFIED'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p->>'external_id',0));
 select * into t from public.novacart_tickets where external_id=p->>'external_id';
 if found then return jsonb_build_object('duplicate',true,'ticket_id',t.id,'status',t.status); end if;
 select * into c from public.novacart_customers where email=lower(p->>'email');
 if c.id is not null then select * into o from public.novacart_orders where id=p->>'order_id' and customer_id=c.id; end if;
 why:=case when c.id is null then 'unknown_customer' when o.id is null then 'order_not_found_or_not_owned' when o.status='lost' then 'carrier_lost' when o.status in ('shipped','delayed','processing') and now()>=o.promised_at+interval '7 days' then 'non_delivery_7_days_overdue' when o.status='delivered' and o.delivered_at>=now()-interval '30 days' and not exists(select 1 from public.novacart_order_items i join public.novacart_products pr on pr.id=i.product_id where i.order_id=o.id and not pr.returnable) then 'return_inspection_required' else 'investigation_required' end;
 eligible:=why in ('carrier_lost','non_delivery_7_days_overdue');
 insert into public.novacart_tickets(external_id,customer_id,order_id) values(p->>'external_id',c.id,o.id) returning * into t;
 insert into public.novacart_messages(ticket_id,direction,body) values(t.id,'inbound',p->>'message');
 select jsonb_agg(jsonb_build_object('id',id,'title',title,'content',content)) into policies from public.novacart_knowledge where active and category in ('refund','return','shipping','security');
 insert into public.novacart_workflow_logs(ticket_id,event) values(t.id,'prepared');
 return jsonb_build_object('duplicate',false,'ticket_id',t.id,'message',p->>'message','customer',case when c.id is null then null else jsonb_build_object('id',c.id,'name',c.name) end,'order',case when o.id is null then null else to_jsonb(o) end,'eligibility',jsonb_build_object('eligible',eligible,'reason',why,'simulated',true),'policies',policies,'retrieval_mode','category_fallback','execution_mode','sandbox');
end $$;
revoke all on function public.novacart_prepare from public,anon,authenticated; grant execute on function public.novacart_prepare to service_role;
create function public.novacart_finalize(p jsonb) returns jsonb language plpgsql security invoker set search_path='' as $$
declare t public.novacart_tickets; o public.novacart_orders; a jsonb; eligible boolean; rr uuid; reply text; reason text; begin
 select * into t from public.novacart_tickets where id=(p->>'ticket_id')::uuid for update;
 if not found then raise exception 'TICKET_NOT_FOUND'; end if;
 if t.status<>'processing' then return jsonb_build_object('ticket_id',t.id,'duplicate',true,'status',t.status); end if;
 if jsonb_typeof(p->'agents')<>'array' or jsonb_array_length(p->'agents')<>8 then raise exception 'EIGHT_AGENT_RESULTS_REQUIRED'; end if;
 for a in select value from jsonb_array_elements(p->'agents') loop
 if coalesce(a->>'agent','') not in ('Orchestrator','Intent Classification','Knowledge Retrieval','Order Resolution','Refund Decision','Customer Response','Human Escalation','QA Evaluation') or jsonb_typeof(a->'output')<>'object' then raise exception 'INVALID_AGENT_OUTPUT'; end if;
 end loop;
 if (select count(distinct value->>'agent') from jsonb_array_elements(p->'agents'))<>8 then raise exception 'DUPLICATE_AGENT_ROLE'; end if;
 select * into o from public.novacart_orders where id=t.order_id;
 eligible:=o.status='lost' or (o.status in ('shipped','delayed','processing') and now()>=o.promised_at+interval '7 days');
 reason:=case when eligible then 'verified_non_delivery' else 'manual_investigation' end;
 if eligible and exists(select 1 from public.novacart_messages where ticket_id=t.id and direction='inbound' and body ~* '(refund|money back)') then
 insert into public.novacart_refund_requests(ticket_id,order_id,amount,reason) values(t.id,o.id,o.total,reason) on conflict(order_id) do nothing;
 select id into rr from public.novacart_refund_requests where order_id=o.id;
 end if;
 reply:=case when o.id is null then 'Please confirm your order number through the verified support channel so our team can investigate.' when rr is not null then format('Your order %s is recorded as %s. A simulated refund review request has been recorded for GBP %s. It requires human approval; no payment has been issued.',o.id,o.status,o.total) else format('Your order %s is recorded as %s. Our team will review the delivery or return request. No refund has been approved or issued.',o.id,o.status) end;
 for a in select value from jsonb_array_elements(p->'agents') loop
 insert into public.novacart_agent_executions(ticket_id,agent,output,model) values(t.id,a->>'agent',a->'output',coalesce(a->>'model','unverified'));
 end loop;
 update public.novacart_tickets set status='review',intent=case when rr is not null then 'refund' else 'support' end,response=reply,updated_at=now() where id=t.id;
 insert into public.novacart_messages(ticket_id,direction,body) values(t.id,'draft',reply);
 insert into public.novacart_escalations(ticket_id,reason) values(t.id,reason);
 insert into public.novacart_outbox(ticket_id,channel,payload) values(t.id,'gmail',jsonb_build_object('draft',reply,'send_authorized',false)),(t.id,'slack',jsonb_build_object('ticket_id',t.id,'status','review','simulated',true));
 insert into public.novacart_qa_evaluations(ticket_id,passed,checks) values(t.id,true,jsonb_build_object('type','deterministic_guard','grounded_template',true,'no_financial_action',true,'human_review_required',true));
 insert into public.novacart_audit_logs(actor,event,entity,detail) values('workflow','support_prepared_for_human_review',t.id::text,jsonb_build_object('simulated',true));
 insert into public.novacart_workflow_logs(ticket_id,event) values(t.id,'completed_held');
 return jsonb_build_object('ticket_id',t.id,'refund_id',rr,'response',reply,'status','review','simulated',true,'outbound_status','held');
end $$;
revoke all on function public.novacart_finalize from public,anon,authenticated; grant execute on function public.novacart_finalize to service_role;
create schema novacart_private;
revoke all on schema novacart_private from public,anon,authenticated;
create function public.novacart_dashboard() returns jsonb language sql stable security invoker set search_path='' as $$
 select jsonb_build_object('members',(select coalesce(jsonb_agg(x),'[]') from public.novacart_members x),'tickets',(select coalesce(jsonb_agg(x),'[]') from (select * from public.novacart_tickets order by created_at desc limit 100) x),'customers',(select coalesce(jsonb_agg(x),'[]') from public.novacart_customers x),'orders',(select coalesce(jsonb_agg(x),'[]') from public.novacart_orders x),'refunds',(select coalesce(jsonb_agg(x),'[]') from public.novacart_refund_requests x),'escalations',(select coalesce(jsonb_agg(x),'[]') from public.novacart_escalations x),'knowledge',(select coalesce(jsonb_agg(x),'[]') from (select id,title,content,category,embedding is not null as embedded from public.novacart_knowledge) x),'agents',(select coalesce(jsonb_agg(x),'[]') from (select * from public.novacart_agent_executions order by created_at desc limit 200) x),'qa',(select coalesce(jsonb_agg(x),'[]') from public.novacart_qa_evaluations x),'tests',(select coalesce(jsonb_agg(x),'[]') from public.novacart_test_results x),'logs',(select coalesce(jsonb_agg(x),'[]') from (select * from public.novacart_workflow_logs order by created_at desc limit 200) x),'outbox',(select coalesce(jsonb_agg(x),'[]') from public.novacart_outbox x));
$$;
revoke all on function public.novacart_dashboard from public,anon; grant execute on function public.novacart_dashboard to authenticated,service_role;
create function public.novacart_approve(refund uuid, decision text, note text) returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.novacart_refund_requests; begin
 if auth.uid() is null or not exists(select 1 from public.novacart_members where user_id=auth.uid() and role in ('approver','admin')) then raise exception 'FORBIDDEN'; end if;
 if decision not in ('approve','reject') or coalesce(length(trim(note)),0) not between 5 and 1000 then raise exception 'INVALID_DECISION'; end if;
 select * into r from public.novacart_refund_requests where id=refund for update;
 if not found or r.status<>'pending' then raise exception 'NOT_PENDING'; end if;
 insert into public.novacart_refund_approvals(refund_id,actor,decision,note) values(refund,auth.uid(),decision,note);
 update public.novacart_refund_requests set status=case when decision='approve' then 'approved_simulated' else 'rejected' end where id=refund;
 insert into public.novacart_audit_logs(actor,event,entity,detail) values(auth.uid()::text,'refund_'||decision,refund::text,jsonb_build_object('simulated',true));
 return jsonb_build_object('simulated',true,'decision',decision);
end $$;
revoke all on function public.novacart_approve from public,anon; grant execute on function public.novacart_approve to authenticated;
