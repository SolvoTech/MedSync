// @ts-nocheck
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface SharedViewPayload {
  token?: string;
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const payload = (await req.json()) as SharedViewPayload;
  const token = payload.token?.replaceAll('-', '').trim().toUpperCase();

  if (!token) {
    return new Response(JSON.stringify({ ok: false, message: 'Token wajib diisi.' }), {
      status: 400,
      headers: { 'content-type': 'application/json' },
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  const supabase = createClient(supabaseUrl, serviceRole);

  const { data: access, error: accessError } = await supabase
    .from('shared_access_tokens')
    .select('id, care_person_id, token, token_display, is_active, expires_at')
    .eq('token', token)
    .eq('is_active', true)
    .single();

  if (accessError || access == null) {
    return new Response(JSON.stringify({ ok: false, message: 'Token tidak valid.' }), {
      status: 404,
      headers: { 'content-type': 'application/json' },
    });
  }

  if (access.expires_at != null && new Date(access.expires_at).getTime() < Date.now()) {
    return new Response(JSON.stringify({ ok: false, message: 'Token sudah kedaluwarsa.' }), {
      status: 410,
      headers: { 'content-type': 'application/json' },
    });
  }

  const { data: carePerson } = await supabase
    .from('care_persons')
    .select('id, display_name, relationship')
    .eq('id', access.care_person_id)
    .single();

  const today = new Date();
  const date = today.toISOString().slice(0, 10);

  const { data: tasks } = await supabase
    .from('task_logs')
    .select('id, task_type, status, scheduled_at, completed_at')
    .eq('care_person_id', access.care_person_id)
    .gte('scheduled_at', `${date}T00:00:00Z`)
    .lte('scheduled_at', `${date}T23:59:59Z`)
    .order('scheduled_at');

  return new Response(
    JSON.stringify({
      ok: true,
      tokenDisplay: access.token_display,
      carePerson,
      todayTasks: tasks ?? [],
      watermark: 'Dibagikan via MedSync',
    }),
    {
      headers: { 'content-type': 'application/json' },
      status: 200,
    },
  );
});
