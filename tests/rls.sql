do $test$ declare uid uuid:=gen_random_uuid(); n int; rid uuid; ok boolean:=false; detail text; begin
 begin
 insert into auth.users(id,email) values(uid,'novacart-rls-test@example.invalid');
 perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'role','authenticated')::text,true);
 set local role authenticated;
 select count(*) into n from public.novacart_customers;
 if n<>0 then raise exception 'Nonmember saw customer data'; end if;
 reset role;
 raise exception 'TEST_OK';
 exception when others then detail:=SQLERRM;ok:=detail='TEST_OK'; end;
 insert into public.novacart_test_results(run_id,scenario,passed,evidence) values('rls-v1','Authenticated nonmember sees no customer data',ok,jsonb_build_object('detail',detail));
end $test$;
do $test$ declare uid uuid:=gen_random_uuid(); n int; ok boolean:=false; detail text; begin
 begin
 insert into auth.users(id,email) values(uid,'novacart-viewer-test@example.invalid');
 insert into public.novacart_members values(uid,'viewer');
 perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'role','authenticated')::text,true);
 set local role authenticated;
 select count(*) into n from public.novacart_customers;
 if n<>100 then raise exception 'Viewer expected 100 synthetic customers'; end if;
 reset role;
 raise exception 'TEST_OK';
 exception when others then detail:=SQLERRM;ok:=detail='TEST_OK'; end;
 insert into public.novacart_test_results(run_id,scenario,passed,evidence) values('rls-v1','Authorized viewer sees synthetic records',ok,jsonb_build_object('detail',detail));
end $test$;
do $test$ declare uid uuid:=gen_random_uuid(); rid uuid; rejected boolean:=false; ok boolean:=false; detail text; begin
 begin
 insert into auth.users(id,email) values(uid,'novacart-viewer-denial@example.invalid');
 insert into public.novacart_members values(uid,'viewer');
 select id into rid from public.novacart_refund_requests where status='pending' limit 1;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'role','authenticated')::text,true);
 set local role authenticated;
 begin perform public.novacart_approve(rid,'approve','This viewer must not approve');exception when others then rejected:=SQLERRM='FORBIDDEN';end;
 if not rejected then raise exception 'Viewer approval was not forbidden';end if;
 reset role;
 raise exception 'TEST_OK';
 exception when others then detail:=SQLERRM;ok:=detail='TEST_OK'; end;
 insert into public.novacart_test_results(run_id,scenario,passed,evidence) values('rls-v1','Viewer cannot approve refund',ok,jsonb_build_object('detail',detail));
end $test$;
do $test$ declare uid uuid:=gen_random_uuid(); rid uuid; result jsonb; ok boolean:=false; detail text; begin
 begin
 insert into auth.users(id,email) values(uid,'novacart-approver-test@example.invalid');
 insert into public.novacart_members values(uid,'approver');
 select id into rid from public.novacart_refund_requests where status='pending' limit 1;
 if rid is null then raise exception 'Missing test refund';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'role','authenticated')::text,true);
 set local role authenticated;
 result:=public.novacart_approve(rid,'approve','Explicit simulated test decision');
 if result->>'simulated'<>'true' then raise exception 'Not simulated';end if;
 if not exists(select 1 from public.novacart_refund_requests where id=rid and status='approved_simulated') then raise exception 'Approval not persisted';end if;
 reset role;
 raise exception 'TEST_OK';
 exception when others then detail:=SQLERRM;ok:=detail='TEST_OK'; end;
 insert into public.novacart_test_results(run_id,scenario,passed,evidence) values('rls-v1','Approver can approve simulated refund with audit',ok,jsonb_build_object('detail',detail,'changes_rolled_back',true));
end $test$;
