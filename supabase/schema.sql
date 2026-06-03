create extension if not exists pgcrypto;

create table if not exists public.organizations (
  hospcode text primary key,
  name text not null,
  org_type text not null default 'รพ.สต.',
  tambon text,
  amphur text,
  province text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  organization text,
  hospcode text references public.organizations(hospcode) on delete set null,
  role text not null default 'staff',
  approved boolean not null default false,
  status text not null default 'offline',
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.patients (
  id uuid primary key default gen_random_uuid(),
  hn text not null unique,
  cid text,
  hospcode text references public.organizations(hospcode) on delete set null,
  full_name text not null,
  birth_date date,
  sex text default 'ไม่ระบุ',
  phone text,
  address text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.drug_allergies (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  drug_name text not null,
  generic_name text,
  reaction text not null,
  severity text default 'ไม่ระบุ',
  onset_date date,
  source text,
  note text,
  photo_paths jsonb not null default '[]'::jsonb,
  typedx text,
  informant text,
  informhosp text,
  risk text,
  status text default 'รออนุมัติ',
  created_by uuid references auth.users(id) on delete set null,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.organizations add column if not exists org_type text not null default 'รพ.สต.';
alter table public.organizations add column if not exists tambon text;
alter table public.organizations add column if not exists amphur text;
alter table public.organizations add column if not exists province text;
alter table public.organizations add column if not exists is_active boolean not null default true;

alter table public.user_profiles add column if not exists hospcode text references public.organizations(hospcode) on delete set null;
alter table public.user_profiles add column if not exists approved boolean not null default false;
alter table public.user_profiles add column if not exists status text not null default 'offline';
alter table public.user_profiles add column if not exists last_seen_at timestamptz;

alter table public.patients add column if not exists hospcode text references public.organizations(hospcode) on delete set null;
alter table public.drug_allergies add column if not exists typedx text;
alter table public.drug_allergies add column if not exists informant text;
alter table public.drug_allergies add column if not exists informhosp text;
alter table public.drug_allergies add column if not exists risk text;
alter table public.drug_allergies add column if not exists photo_paths jsonb not null default '[]'::jsonb;

insert into storage.buckets (id, name, public)
values ('allergy-photos', 'allergy-photos', true)
on conflict (id) do update set public = true;

do $$
declare constraint_name text;
begin
  for constraint_name in
    select conname
    from pg_constraint
    where conrelid = 'public.patients'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) like '%sex%'
  loop
    execute format('alter table public.patients drop constraint if exists %I', constraint_name);
  end loop;

  for constraint_name in
    select conname
    from pg_constraint
    where conrelid = 'public.drug_allergies'::regclass
      and contype = 'c'
      and (pg_get_constraintdef(oid) like '%severity%' or pg_get_constraintdef(oid) like '%status%')
  loop
    execute format('alter table public.drug_allergies drop constraint if exists %I', constraint_name);
  end loop;
end $$;

alter table public.patients
  add constraint patients_sex_check check (sex in ('ชาย', 'หญิง', 'ไม่ระบุ'));

alter table public.drug_allergies
  add constraint drug_allergies_severity_check check (severity in ('ไม่รุนแรง', 'ปานกลาง', 'รุนแรง', 'ไม่ระบุ'));

alter table public.drug_allergies
  add constraint drug_allergies_status_check check (status in ('รออนุมัติ', 'ยืนยันแล้ว', 'ยกเลิก'));

alter table public.user_profiles
  drop constraint if exists user_profiles_role_check;

alter table public.user_profiles
  add constraint user_profiles_role_check check (role in ('admin', 'staff'));

alter table public.user_profiles
  drop constraint if exists user_profiles_status_check;

alter table public.user_profiles
  add constraint user_profiles_status_check check (status in ('online', 'offline'));

create index if not exists patients_hn_idx on public.patients (hn);
create index if not exists patients_hospcode_idx on public.patients (hospcode);
create index if not exists patients_full_name_idx on public.patients (full_name);
create index if not exists drug_allergies_patient_id_idx on public.drug_allergies (patient_id);
create index if not exists drug_allergies_status_idx on public.drug_allergies (status);
create index if not exists user_profiles_hospcode_idx on public.user_profiles (hospcode);
create index if not exists user_profiles_last_seen_idx on public.user_profiles (last_seen_at);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_profiles
    where id = auth.uid()
      and role = 'admin'
      and approved = true
  );
$$;

drop trigger if exists set_organizations_updated_at on public.organizations;
create trigger set_organizations_updated_at
before update on public.organizations
for each row execute function public.set_updated_at();

drop trigger if exists set_user_profiles_updated_at on public.user_profiles;
create trigger set_user_profiles_updated_at
before update on public.user_profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_patients_updated_at on public.patients;
create trigger set_patients_updated_at
before update on public.patients
for each row execute function public.set_updated_at();

drop trigger if exists set_drug_allergies_updated_at on public.drug_allergies;
create trigger set_drug_allergies_updated_at
before update on public.drug_allergies
for each row execute function public.set_updated_at();

alter table public.organizations enable row level security;
alter table public.user_profiles enable row level security;
alter table public.patients enable row level security;
alter table public.drug_allergies enable row level security;

drop policy if exists "Authenticated users can read organizations" on public.organizations;
create policy "Authenticated users can read organizations"
on public.organizations for select
to authenticated
using (true);

drop policy if exists "Admins can manage organizations" on public.organizations;
create policy "Admins can manage organizations"
on public.organizations for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Users can read their own profile" on public.user_profiles;
create policy "Users can read their own profile"
on public.user_profiles for select
to authenticated
using (id = auth.uid() or public.is_admin());

drop policy if exists "Users can create their own staff profile" on public.user_profiles;
create policy "Users can create their own staff profile"
on public.user_profiles for insert
to authenticated
with check (id = auth.uid() and role = 'staff');

drop policy if exists "Users can update own staff profile" on public.user_profiles;
create policy "Users can update own staff profile"
on public.user_profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid() and role = 'staff');

drop policy if exists "Admins can manage profiles" on public.user_profiles;
create policy "Admins can manage profiles"
on public.user_profiles for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Authenticated users can read patients" on public.patients;
create policy "Authenticated users can read patients"
on public.patients for select
to authenticated
using (true);

drop policy if exists "Authenticated users can insert patients" on public.patients;
create policy "Authenticated users can insert patients"
on public.patients for insert
to authenticated
with check (true);

drop policy if exists "Authenticated users can update patients" on public.patients;
create policy "Authenticated users can update patients"
on public.patients for update
to authenticated
using (true)
with check (true);

drop policy if exists "Admins can delete patients" on public.patients;
create policy "Admins can delete patients"
on public.patients for delete
to authenticated
using (public.is_admin());

drop policy if exists "Authenticated users can read allergy records" on public.drug_allergies;
create policy "Authenticated users can read allergy records"
on public.drug_allergies for select
to authenticated
using (true);

drop policy if exists "Authenticated users can insert allergy records" on public.drug_allergies;
create policy "Authenticated users can insert allergy records"
on public.drug_allergies for insert
to authenticated
with check (true);

drop policy if exists "Admins can update allergy records" on public.drug_allergies;
create policy "Admins can update allergy records"
on public.drug_allergies for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Admins can delete allergy records" on public.drug_allergies;
create policy "Admins can delete allergy records"
on public.drug_allergies for delete
to authenticated
using (public.is_admin());

drop policy if exists "Authenticated users can read allergy photos" on storage.objects;
create policy "Authenticated users can read allergy photos"
on storage.objects for select
to authenticated
using (bucket_id = 'allergy-photos');

drop policy if exists "Authenticated users can upload allergy photos" on storage.objects;
create policy "Authenticated users can upload allergy photos"
on storage.objects for insert
to authenticated
with check (bucket_id = 'allergy-photos');

drop policy if exists "Authenticated users can update allergy photos" on storage.objects;
create policy "Authenticated users can update allergy photos"
on storage.objects for update
to authenticated
using (bucket_id = 'allergy-photos')
with check (bucket_id = 'allergy-photos');

drop policy if exists "Admins can delete allergy photos" on storage.objects;
create policy "Admins can delete allergy photos"
on storage.objects for delete
to authenticated
using (bucket_id = 'allergy-photos' and public.is_admin());
