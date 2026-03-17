// @ts-nocheck
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async () => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

  const supabase = createClient(supabaseUrl, serviceRole);
  const now = new Date();
  const todayIso = now.toISOString().slice(0, 10);

  // Phase 1 implementation:
  // - this function is intentionally conservative and returns metadata.
  // - full daily task reconciliation and streak mutation will be added in next slice.
  const { count: pendingCount, error } = await supabase
    .from('task_logs')
    .select('id', { count: 'exact', head: true })
    .eq('status', 'pending')
    .gte('scheduled_at', `${todayIso}T00:00:00Z`)
    .lte('scheduled_at', `${todayIso}T23:59:59Z`);

  if (error) {
    return new Response(JSON.stringify({ ok: false, message: error.message }), {
      status: 500,
      headers: { 'content-type': 'application/json' },
    });
  }

  return new Response(
    JSON.stringify({
      ok: true,
      date: todayIso,
      pendingTasksToday: pendingCount ?? 0,
      nextStep: 'Implement mark-missed + streak update + summary notifications',
    }),
    {
      status: 200,
      headers: { 'content-type': 'application/json' },
    },
  );
});
