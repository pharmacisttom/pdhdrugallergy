create extension if not exists pgcrypto;

create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  organization text,
  role text not null check (role in ('admin', 'staff')) default 'staff',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.patients (
  id uuid primary key default gen_random_uuid(),
  hn text not null unique,
  cid text,
  hospcode text,
  full_name text not null,
  birth_date date,
  sex text check (sex in ('ชาย', 'หญิง', 'ไม่ระบุ')) default 'ไม่ระบุ',
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
  severity text check (severity in ('ไม่รุนแรง', 'ปานกลาง', 'รุนแรง', 'ไม่ระบุ')) default 'ไม่ระบุ',
  onset_date date,
  source text,
  note text,
  typedx text,
  informant text,
  informhosp text,
  risk text,
  status text check (status in ('รออนุมัติ', 'ยืนยันแล้ว', 'ยกเลิก')) default 'รออนุมัติ',
  created_by uuid references auth.users(id) on delete set null,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists patients_hn_idx on public.patients (hn);
create index if not exists patients_full_name_idx on public.patients (full_name);
create index if not exists drug_allergies_patient_id_idx on public.drug_allergies (patient_id);
create index if not exists drug_allergies_status_idx on public.drug_allergies (status);

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
  );
$$;

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

alter table public.user_profiles enable row level security;
alter table public.patients enable row level security;
alter table public.drug_allergies enable row level security;

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
