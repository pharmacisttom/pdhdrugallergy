insert into public.user_profiles (id, email, full_name, organization, role, approved, status, last_seen_at)
select
  id,
  email,
  'ผู้ดูแลระบบ',
  'โรงพยาบาลปลวกแดง',
  'admin',
  true,
  'online',
  now()
from auth.users
where email = 'pharmacisttom@gmail.com'
on conflict (id) do update
set role = 'admin',
    approved = true,
    status = 'online',
    last_seen_at = now(),
    email = excluded.email,
    full_name = excluded.full_name,
    organization = excluded.organization,
    updated_at = now();
