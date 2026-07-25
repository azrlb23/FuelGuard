import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('⚠️ Supabase URL atau Key belum diset di file .env!')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export const logActivity = async (action, details) => {
  const { data: { user } } = await supabase.auth.getUser()
  if (user) {
    await supabase.from('activity_logs').insert({
      user_id: user.id,
      action,
      details,
      timestamp: new Date().toISOString()
    })
  }
}