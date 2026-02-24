import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// APNs JWT generation using Web Crypto API
async function generateAPNsJWT(keyId: string, teamId: string, privateKeyPEM: string): Promise<string> {
  const header = {
    alg: "ES256",
    kid: keyId
  }

  const now = Math.floor(Date.now() / 1000)
  const payload = {
    iss: teamId,
    iat: now
  }

  // Base64url encode header and payload
  const encodedHeader = btoa(JSON.stringify(header)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
  const encodedPayload = btoa(JSON.stringify(payload)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
  const message = `${encodedHeader}.${encodedPayload}`

  // Import the P8 private key
  const pemContents = privateKeyPEM
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')

  const binaryKey = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign']
  )

  // Sign the message
  const encoder = new TextEncoder()
  const signature = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' },
    cryptoKey,
    encoder.encode(message)
  )

  // Convert signature to base64url
  const signatureArray = new Uint8Array(signature)
  const signatureBase64 = btoa(String.fromCharCode(...signatureArray))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')

  return `${message}.${signatureBase64}`
}

async function sendAPNsNotification(
  deviceToken: string,
  title: string,
  body: string,
  bundleId: string,
  jwt: string,
  isProduction: boolean = true
): Promise<void> {
  const apnsUrl = isProduction
    ? 'https://api.push.apple.com'
    : 'https://api.sandbox.push.apple.com'

  const payload = {
    aps: {
      alert: {
        title,
        body
      },
      sound: 'default'
    }
  }

  const response = await fetch(`${apnsUrl}/3/device/${deviceToken}`, {
    method: 'POST',
    headers: {
      'authorization': `bearer ${jwt}`,
      'apns-topic': bundleId,
      'apns-push-type': 'alert',
      'apns-priority': '10'
    },
    body: JSON.stringify(payload)
  })

  if (!response.ok) {
    const errorText = await response.text()
    console.error(`APNs error for token ${deviceToken}: ${response.status} - ${errorText}`)
    throw new Error(`APNs error: ${response.status} - ${errorText}`)
  }

  console.log(`Successfully sent notification to ${deviceToken}`)
}

Deno.serve(async (req) => {
  try {
    // Create Supabase admin client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Parse request body
    const { user_id, title, body } = await req.json()

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_id, title, body' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get device tokens for this user
    const { data: tokens, error: tokenError } = await supabaseAdmin
      .from('device_tokens')
      .select('token')
      .eq('user_id', user_id)

    if (tokenError) {
      throw new Error(`Failed to fetch device tokens: ${tokenError.message}`)
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No device tokens found for this user' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get APNs credentials from environment
    const keyId = Deno.env.get('APNS_KEY_ID')
    const teamId = Deno.env.get('APNS_TEAM_ID')
    const bundleId = Deno.env.get('APNS_BUNDLE_ID')
    const privateKey = Deno.env.get('APNS_PRIVATE_KEY')

    if (!keyId || !teamId || !bundleId || !privateKey) {
      throw new Error('Missing APNs credentials in environment')
    }

    // Generate JWT for APNs
    const jwt = await generateAPNsJWT(keyId, teamId, privateKey)

    // Send notifications to all device tokens
    // Try sandbox first (for development builds), fall back to production
    const results = await Promise.allSettled(
      tokens.map(async ({ token }) => {
        try {
          // Try sandbox first (Xcode builds use sandbox)
          await sendAPNsNotification(token, title, body, bundleId, jwt, false)
          console.log(`Sent via sandbox to ${token}`)
        } catch (sandboxError) {
          // If sandbox fails, try production (TestFlight/App Store builds)
          console.log(`Sandbox failed for ${token}, trying production...`)
          await sendAPNsNotification(token, title, body, bundleId, jwt, true)
          console.log(`Sent via production to ${token}`)
        }
      })
    )

    const successful = results.filter(r => r.status === 'fulfilled').length
    const failed = results.filter(r => r.status === 'rejected').length

    return new Response(
      JSON.stringify({
        message: 'Notifications sent',
        successful,
        failed,
        total: tokens.length
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error sending notification:', error)
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
