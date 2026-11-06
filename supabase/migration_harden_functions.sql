-- Hardening for SECURITY DEFINER trigger functions. Run once in the Supabase SQL editor.
-- 1) Pin search_path so a definer function can't be hijacked by objects in another schema.
--    (Bodies already use fully-qualified public.* names, so behaviour is unchanged.)
alter function public.handle_new_user()       set search_path = public;
alter function public.auto_activity_log()     set search_path = public;
alter function public.enforce_tax_year_lock() set search_path = public;
-- 2) These are trigger-only functions; they should not be callable as /rest/v1/rpc/*.
--    Triggers fire regardless of EXECUTE privilege, so nothing in the app is affected.
revoke execute on function public.handle_new_user()       from public, anon, authenticated;
revoke execute on function public.auto_activity_log()     from public, anon, authenticated;
revoke execute on function public.enforce_tax_year_lock() from public, anon, authenticated;
