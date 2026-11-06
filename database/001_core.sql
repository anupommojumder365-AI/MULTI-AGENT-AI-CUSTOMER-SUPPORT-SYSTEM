create extension if not exists vector with schema extensions;
create table public.novacart_members (user_id uuid primary key references auth.users(id), role text not null check(role in ('viewer','operator','approver','admin')));
create table public.novacart_customers (id text primary key, name text not null, email text unique not null check(email like '%@example.invalid'), created_at timestamptz not null default now());
create table public.novacart_products (id text primary key, name text not null, price numeric(12,2) not null check(price>0), returnable boolean not null default true);
create table public.novacart_orders (id text primary key, customer_id text not null references public.novacart_customers, status text not null check(status in ('processing','shipped','delayed','delivered','lost','cancelled')), ordered_at timestamptz not null, promised_at timestamptz not null, delivered_at timestamptz, total numeric(12,2) not null check(total>0), currency text not null default 'GBP' check(currency='GBP'), tracking text, carrier text default 'NovaShip Demo');
create index on public.novacart_orders(customer_id);
create table public.novacart_order_items (id bigint generated always as identity primary key, order_id text not null references public.novacart_orders, product_id text not null references public.novacart_products, quantity int not null check(quantity>0), unit_price numeric(12,2) not null check(unit_price>0));
create index on public.novacart_order_items(order_id); create index on public.novacart_order_items(product_id);
create table public.novacart_tickets (id uuid primary key default gen_random_uuid(), external_id text unique not null, customer_id text references public.novacart_customers, order_id text references public.novacart_orders, status text not null default 'processing' check(status in ('processing','review','resolved','error')), intent text, priority text default 'normal', response text, created_at timestamptz default now(), updated_at timestamptz default now());
create index on public.novacart_tickets(customer_id); create index on public.novacart_tickets(order_id); create index on public.novacart_tickets(status,created_at);
create table public.novacart_messages (id uuid primary key default gen_random_uuid(), ticket_id uuid not null references public.novacart_tickets, direction text not null check(direction in ('inbound','draft')), body text not null check(length(body) between 1 and 8000), created_at timestamptz default now());
create index on public.novacart_messages(ticket_id);
create table public.novacart_refund_requests (id uuid primary key default gen_random_uuid(), ticket_id uuid not null references public.novacart_tickets, order_id text unique not null references public.novacart_orders, amount numeric(12,2) not null check(amount>0), reason text not null, status text not null default 'pending' check(status in ('pending','approved_simulated','rejected')), simulated boolean not null default true check(simulated), created_at timestamptz default now());
create index on public.novacart_refund_requests(ticket_id);
create table public.novacart_refund_approvals (id uuid primary key default gen_random_uuid(), refund_id uuid unique not null references public.novacart_refund_requests, actor uuid not null references auth.users, decision text not null check(decision in ('approve','reject')), note text not null, created_at timestamptz default now());
create index on public.novacart_refund_approvals(actor);
create table public.novacart_escalations (id uuid primary key default gen_random_uuid(), ticket_id uuid unique not null references public.novacart_tickets, reason text not null, status text not null default 'open', created_at timestamptz default now());
create table public.novacart_knowledge (id text primary key, title text not null, content text not null, category text not null, version int not null default 1, active boolean not null default true, embedding extensions.vector(1536), embedding_model text, created_at timestamptz default now());
create index on public.novacart_knowledge using gin(to_tsvector('english',title||' '||content));
create index on public.novacart_knowledge using hnsw(embedding extensions.vector_cosine_ops);
create table public.novacart_agent_executions (id uuid primary key default gen_random_uuid(), ticket_id uuid not null references public.novacart_tickets, agent text not null, output jsonb not null, model text not null, created_at timestamptz default now());
create index on public.novacart_agent_executions(ticket_id);
create table public.novacart_workflow_logs (id uuid primary key default gen_random_uuid(), ticket_id uuid references public.novacart_tickets, event text not null, detail jsonb not null default '{}', created_at timestamptz default now());
create index on public.novacart_workflow_logs(ticket_id);
create table public.novacart_qa_evaluations (id uuid primary key default gen_random_uuid(), ticket_id uuid references public.novacart_tickets, passed boolean not null, checks jsonb not null, created_at timestamptz default now());
create index on public.novacart_qa_evaluations(ticket_id);
create table public.novacart_audit_logs (id uuid primary key default gen_random_uuid(), actor text not null, event text not null, entity text not null, detail jsonb not null default '{}', created_at timestamptz default now());
create table public.novacart_outbox (id uuid primary key default gen_random_uuid(), ticket_id uuid not null references public.novacart_tickets, channel text not null check(channel in ('gmail','slack')), payload jsonb not null, status text not null default 'held' check(status in ('held','sent','failed')), attempts int not null default 0 check(attempts between 0 and 3), next_attempt_at timestamptz default now(), unique(ticket_id,channel));
create table public.novacart_test_results (id bigint generated always as identity primary key, run_id text not null, scenario text not null, passed boolean not null, evidence jsonb not null, created_at timestamptz default now());
do $$ declare t text; begin
 for t in select tablename from pg_tables where schemaname='public' and tablename like 'novacart_%' loop
 execute format('alter table public.%I enable row level security',t);
 execute format('revoke all on public.%I from anon, authenticated',t);
 execute format('grant all on public.%I to service_role',t);
 execute format('grant select on public.%I to authenticated',t);
 if t='novacart_members' then
 execute 'create policy member_self on public.novacart_members for select to authenticated using(user_id=(select auth.uid()))';
 else
 execute format('create policy staff_read on public.%I for select to authenticated using(exists(select 1 from public.novacart_members where user_id=(select auth.uid())))',t);
 end if;
 end loop;
end $$;
grant usage,select on sequence public.novacart_order_items_id_seq, public.novacart_test_results_id_seq to service_role;
create function public.novacart_match_knowledge(query_embedding extensions.vector(1536), match_count int default 5) returns table(id text,title text,content text,similarity float) language sql stable security invoker set search_path='' as $$
 select k.id,k.title,k.content,1-(k.embedding operator(extensions.<=>) query_embedding) from public.novacart_knowledge k where k.active and k.embedding is not null order by k.embedding operator(extensions.<=>) query_embedding limit least(greatest(match_count,1),10)
$$;
revoke all on function public.novacart_match_knowledge from public,anon; grant execute on function public.novacart_match_knowledge to authenticated,service_role;
