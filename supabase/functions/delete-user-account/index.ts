// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
    try {
      // Get the authorization header
      const authHeader = req.headers.get('Authorization')
      if (!authHeader) {
        return new Response(
          JSON.stringify({ error: 'No authorization header' }),
          { status: 401, headers: { 'Content-Type': 'application/json' } }
        )
      }

      // Create Supabase client with user's token to verify identity
      const supabaseClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        { global: { headers: { Authorization: authHeader } } }
      )

      // Get the authenticated user
      const { data: { user }, error: userError } = await supabaseClient.auth.getUser()

      if (userError || !user) {
        return new Response(
          JSON.stringify({ error: 'Unauthorized' }),
          { status: 401, headers: { 'Content-Type': 'application/json' } }
        )
      }

      const userId = user.id

      // Create admin client with service role key
      const supabaseAdmin = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
      )

      // Step 1: Delete user profile from profiles table
      const { error: profileError } = await supabaseAdmin
        .from('profiles')
        .delete()
        .eq('id', userId)

      if (profileError) {
        console.error('Error deleting profile:', profileError)
        return new Response(
          JSON.stringify({ error: 'Failed to delete profile', details: profileError.message }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
      }

      // Step 2: Delete user from Supabase Auth
      const { error: authError } = await supabaseAdmin.auth.admin.deleteUser(userId)

      if (authError) {
        console.error('Error deleting auth user:', authError)
        return new Response(
          JSON.stringify({ error: 'Failed to delete auth user', details: authError.message }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
      }

      return new Response(
        JSON.stringify({ message: 'User account deleted successfully', userId }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )

    } catch (error) {
      console.error('Unexpected error:', error)
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      return new Response(
        JSON.stringify({ error: 'Internal server error', details: errorMessage }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }
  })

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/delete-user-account' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
