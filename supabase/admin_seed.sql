insert into public.user_profiles (id, email, full_name, organization, role)
values (
  'd7e5e52a-cf12-4f3f-a279-019b1b747565',
  'pharmacisttom+admin@gmail.com',
  'ผู้ดูแลระบบ',
  'โรงพยาบาลปลวกแดง',
  'admin'
)
on conflict (id) do update
set role = 'admin',
    email = excluded.email,
    full_name = excluded.full_name,
    organization = excluded.organization,
    updated_at = now();
