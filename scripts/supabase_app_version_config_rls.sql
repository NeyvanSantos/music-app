-- Harden access to the OTA configuration table used by the client.
-- Run this in Supabase SQL Editor as a privileged role.

alter table public.app_version_config
  add column if not exists apk_sha256 text;

alter table public.app_version_config
  add column if not exists channel text not null default 'stable';

create unique index if not exists app_version_config_channel_uidx
  on public.app_version_config (channel);

alter table public.app_version_config enable row level security;

drop policy if exists "public can read app version config" on public.app_version_config;
create policy "public can read app version config"
on public.app_version_config
for select
to anon, authenticated
using (true);

drop policy if exists "service role manages app version config" on public.app_version_config;
create policy "service role manages app version config"
on public.app_version_config
for all
to service_role
using (true)
with check (true);

drop policy if exists "authenticated users cannot change app version config" on public.app_version_config;
create policy "authenticated users cannot change app version config"
on public.app_version_config
for all
to authenticated
using (false)
with check (false);

comment on table public.app_version_config is
'Stores OTA release metadata. Clients may read. Only service_role may insert, update, or delete rows.';
