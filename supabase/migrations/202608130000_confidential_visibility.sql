-- PostgreSQL requires a commit before a newly-added enum value is used.
alter type public.visibility_level add value if not exists 'confidential';
