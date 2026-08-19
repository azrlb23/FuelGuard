import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { Redis } from 'https://esm.sh/@upstash/redis@1.28.4'

// CORS Headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-requested-with, *',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

// Helper untuk inisialisasi Upstash Redis secara aman tanpa crash saat Deno boot
function getRedis() {
  const url = Deno.env.get('UPSTASH_REDIS_REST_URL')
  const token = Deno.env.get('UPSTASH_REDIS_REST_TOKEN')
  if (!url || !token) {
    console.warn('UPSTASH_REDIS_REST_URL atau UPSTASH_REDIS_REST_TOKEN belum dikonfigurasi di Supabase Secrets.')
    return null
  }
  try {
    return new Redis({ url, token })
  } catch (e) {
    console.error('Gagal inisialisasi Upstash Redis client:', e)
    return null
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const email = body?.email?.trim().toLowerCase() || body?.payload?.email?.trim().toLowerCase() || ''
    const password = body?.password || body?.payload?.password || ''

    if (!email || !password) {
      return new Response(
        JSON.stringify({ success: false, message: 'Email dan password wajib diisi.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // cf-connecting-ip / x-real-ip are set by the trusted edge proxy and cannot be
    // spoofed by the client. x-forwarded-for CAN have an attacker-supplied first
    // entry, so if we must fall back to it, use the last hop (closest to our
    // infrastructure) instead of the first (closest to the client) to prevent
    // trivial IP-lockout bypass by sending a random X-Forwarded-For value.
    const forwardedFor = req.headers.get('x-forwarded-for')
    const clientIp = req.headers.get('cf-connecting-ip')
      || req.headers.get('x-real-ip')
      || (forwardedFor ? forwardedFor.split(',').pop().trim() : null)
      || 'unknown_ip'

    // Key Redis Terpisah untuk Akun (Email) & IP
    const emailKey = `fuelguard:failed_login:email:${email}`
    const ipKey = `fuelguard:failed_login:ip:${clientIp}`

    // 1. DUA ATURAN LOCKOUT BERBEDA:
    // A. Based on AKUN (Email): 5x Gagal ➡️ Kunci Akun 1 Menit (60s)
    // B. Based on IP Address  : 5x Gagal ➡️ Kunci IP 10 Menit (600s)
    let emailFailedCount = 0
    let ipFailedCount = 0

    const redis = getRedis()

    if (redis) {
      try {
        const [eCount, iCount] = await Promise.all([
          redis.get<number>(emailKey),
          redis.get<number>(ipKey)
        ])
        emailFailedCount = eCount || 0
        ipFailedCount = iCount || 0
      } catch (err) {
        console.error('Redis read check error:', err)
      }
    }

    // Cek Kunci Berdasarkan Akun (Email) -> Kunci 1 Menit
    if (emailFailedCount >= 5) {
      return new Response(
        JSON.stringify({
          success: false,
          reason: 'account_rate_limit_exceeded',
          message: 'Akun ini sedang dikunci sementara selama 1 menit karena 5x kesalahan password. Silakan tunggu 1 menit.',
          remainingAttempts: 0
        }),
        {
          status: 429,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Cek Kunci Berdasarkan IP Address -> Kunci 10 Menit
    if (ipFailedCount >= 5) {
      return new Response(
        JSON.stringify({
          success: false,
          reason: 'ip_rate_limit_exceeded',
          message: 'IP Anda sedang dikunci sementara selama 10 menit karena 5x kesalahan password dari IP ini. Silakan tunggu 10 menit.',
          remainingAttempts: 0
        }),
        {
          status: 429,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // 2. Verifikasi Autentikasi dengan Supabase Auth
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    const supabaseAnon = createClient(supabaseUrl, supabaseAnonKey)

    const { data, error } = await supabaseAnon.auth.signInWithPassword({ email, password })

    if (error) {
      // 🚨 LOGIN GAGAL: Update counter & atur TTL masing-masing:
      // - Email TTL: 60 detik (1 menit)
      // - IP TTL: 600 detik (10 menit)
      let newEmailCount = emailFailedCount + 1
      let newIpCount = ipFailedCount + 1

      if (redis) {
        try {
          const [eInc, iInc] = await Promise.all([
            redis.incr(emailKey),
            redis.incr(ipKey)
          ])
          newEmailCount = eInc
          newIpCount = iInc

          if (newEmailCount === 1) await redis.expire(emailKey, 60)   // TTL Akun: 1 Menit (60 detik)
          if (newIpCount === 1) await redis.expire(ipKey, 600)        // TTL IP: 10 Menit (600 detik)
        } catch (err) {
          console.error('Upstash Redis INCR error:', err)
        }
      }

      const maxCount = Math.max(newEmailCount, newIpCount)
      const remainingAttempts = Math.max(0, 5 - maxCount)

      if (newEmailCount >= 5) {
        return new Response(
          JSON.stringify({
            success: false,
            reason: 'account_rate_limit_exceeded',
            message: 'Batas 5x kesalahan password untuk akun ini tercapai! Akun dikunci selama 1 menit.',
            remainingAttempts: 0,
          }),
          {
            status: 429,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        )
      }

      if (newIpCount >= 5) {
        return new Response(
          JSON.stringify({
            success: false,
            reason: 'ip_rate_limit_exceeded',
            message: 'Batas 5x kesalahan password dari IP ini tercapai! IP dikunci selama 10 menit.',
            remainingAttempts: 0,
          }),
          {
            status: 429,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        )
      }

      return new Response(
        JSON.stringify({
          success: false,
          reason: 'invalid_credentials',
          message: `Email atau password salah. Sisa percobaan sebelum dikunci: ${remainingAttempts} kali.`,
          remainingAttempts: remainingAttempts,
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
            'X-RateLimit-Remaining': remainingAttempts.toString(),
          },
        }
      )
    }

    // 🟢 LOGIN BERHASIL: Hapus & reset counter kegagalan di Redis untuk Email & IP
    if (redis) {
      try {
        await Promise.all([
          redis.del(emailKey),
          redis.del(ipKey)
        ])
      } catch (err) {
        console.error('Failed to reset Redis login counter:', err)
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        session: data.session,
        user: data.user,
        message: 'Login berhasil.',
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (err: any) {
    return new Response(
      JSON.stringify({ success: false, message: err.message || 'Internal Server Error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
