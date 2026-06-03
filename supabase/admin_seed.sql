insert into public.user_profiles (id, email, full_name, organization, role)
select
  id,
  email,
  'ผู้ดูแลระบบ',
  'โรงพยาบาลปลวกแดง',
  'admin'
from auth.users
where email = 'pharmacisttom@gmail.com'
on conflict (id) do update
set role = 'admin',
    email = excluded.email,
    full_name = excluded.full_name,
    organization = excluded.organization,
    updated_at = now();
