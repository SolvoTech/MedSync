# Supabase Setup (MedSync)

## Local prerequisites
- Supabase CLI installed
- Authenticated to your Supabase account

## Link project
```bash
supabase login
supabase link --project-ref <your-project-ref>
```

## Run migration
```bash
supabase db push
```

## Deploy edge functions
```bash
supabase functions deploy daily-task-check
supabase functions deploy shared-view
```

## Required secrets for edge functions
```bash
supabase secrets set SUPABASE_URL=<url>
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```
