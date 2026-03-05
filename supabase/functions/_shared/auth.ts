import { getSupabaseClient } from './supabase-client.ts';

export async function getUserFromRequest(req: Request) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) throw new Error('Missing authorization header');

  const supabase = getSupabaseClient(authHeader);
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) throw new Error('Invalid token');

  return { user, supabase };
}
