create extension if not exists pgcrypto;
create table if not exists public.visitor_records(
 id uuid primary key default gen_random_uuid(),
 full_name text not null check(char_length(trim(full_name)) between 2 and 120),
 position text not null check(char_length(trim(position)) between 2 and 120),
 reason text not null check(char_length(trim(reason)) between 2 and 1000),
 created_at timestamptz not null default now()
);
alter table public.visitor_records add column if not exists destination text;
alter table public.visitor_records add column if not exists departure_token_hash text;
alter table public.visitor_records add column if not exists departed_at timestamptz;
create index if not exists visitor_records_created_at_idx on public.visitor_records(created_at desc);
create table if not exists public.admin_users(user_id uuid primary key references auth.users(id) on delete cascade,created_at timestamptz not null default now());
alter table public.visitor_records enable row level security;
alter table public.admin_users enable row level security;
drop policy if exists "Public can register visitors" on public.visitor_records;
create policy "Public can register visitors" on public.visitor_records for insert to anon,authenticated
 with check(char_length(trim(full_name)) between 2 and 120 and char_length(trim(position)) between 2 and 120 and char_length(trim(reason)) between 2 and 1000 and destination is not null and char_length(trim(destination)) between 2 and 120 and departure_token_hash is not null and char_length(departure_token_hash)=64);
create or replace function public.is_school_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.admin_users where user_id=(select auth.uid()));
$$;
revoke all on function public.is_school_admin() from public;
grant execute on function public.is_school_admin() to authenticated;
drop policy if exists "Only school admins can view visitor records" on public.visitor_records;
create policy "Only school admins can view visitor records" on public.visitor_records for select to authenticated using(public.is_school_admin());
drop policy if exists "Admins can view own membership" on public.admin_users;
create policy "Admins can view own membership" on public.admin_users for select to authenticated using(user_id=(select auth.uid()));
grant insert on public.visitor_records to anon,authenticated;
grant select on public.visitor_records to authenticated;
grant select on public.admin_users to authenticated;
create or replace function public.record_visitor_departure(p_token_hash text)
returns boolean language plpgsql security definer set search_path='' as $$
declare changed_count integer;
begin
 if p_token_hash is null or length(p_token_hash) <> 64 then return false; end if;
 update public.visitor_records
 set departed_at=now()
 where departure_token_hash=p_token_hash and departed_at is null;
 get diagnostics changed_count = row_count;
 return changed_count=1;
end;
$$;
revoke all on function public.record_visitor_departure(text) from public;
grant execute on function public.record_visitor_departure(text) to anon,authenticated;
-- Admin account authorization remains manual:
-- insert into public.admin_users(user_id) select id from auth.users where email='admin@school.example';
-- Never expose the service_role key in the browser.
