create or replace function public.novacart_inbound_unverified(external_id text,message text) returns jsonb language plpgsql security invoker set search_path='' as $$ declare tid uuid; begin
if coalesce(length(external_id),0) not between 1 and 200 or coalesce(length(message),0) not between 1 and 8000 then raise exception 'INVALID_INPUT'; end if;
insert into public.novacart_tickets(external_id,status,intent) values(external_id,'review','identity_verification') on conflict on constraint novacart_tickets_external_id_key do nothing returning id into tid;
if tid is null then return jsonb_build_object('duplicate',true); end if;
insert into public.novacart_messages(ticket_id,direction,body) values(tid,'inbound',message);
insert into public.novacart_escalations(ticket_id,reason) values(tid,'unverified_email_sender');
return jsonb_build_object('ticket_id',tid,'status','identity_verification_required'); end $$;
revoke all on function public.novacart_inbound_unverified(text,text) from public,anon,authenticated;
grant execute on function public.novacart_inbound_unverified(text,text) to service_role;