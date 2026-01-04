CREATE OR REPLACE FUNCTION insert_user_to_auth(
    email text,
    password text
) RETURNS UUID AS $$
DECLARE
  user_id uuid;
  encrypted_pw text;
BEGIN
  user_id := gen_random_uuid();
  encrypted_pw := crypt(password, gen_salt('bf'));
  
  INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES
    (gen_random_uuid(), user_id, 'authenticated', 'authenticated', email, encrypted_pw, '2023-05-03 19:41:43.585805+00', '2023-04-22 13:10:03.275387+00', '2023-04-22 13:10:31.458239+00', '{"provider":"email","providers":["email"]}', '{}', '2023-05-03 19:41:43.580424+00', '2023-05-03 19:41:43.585948+00', '', '', '', '');
  
  INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES
    (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, email)::jsonb, 'email', '2023-05-03 19:41:43.582456+00', '2023-05-03 19:41:43.582497+00', '2023-05-03 19:41:43.582497+00');
  
  RETURN user_id;
END;
$$ LANGUAGE plpgsql;


SET search_path TO public, auth, extensions;

-- Disable RLS for the duration of data insertion to avoid permission issues
-- This is a common practice for sample data scripts.
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.foot_metrics DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.foot_scans DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_questionnaires DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.prompt_templates DISABLE ROW LEVEL SECURITY;

-- 1. Insert/Reference auth.users and then public.users
-- The user ala@zestyswiss.

-- Seed default AI prompt template for podology
INSERT INTO public.prompt_templates (key, system_prompt)
VALUES (
  'podology_default',
  'You are a professional AI assistant specialized in podiatry and foot biomechanics.\nYour role is to assist licensed podiatrists by interpreting foot scan measurements, highlighting biomechanical patterns, and suggesting professional hypotheses.\nRules: No medical diagnosis, no prescriptions. Use cautious wording (may indicate / could suggest). Encourage clinical correlation.\nStructure: Observations, Interpretation, Potential implications, Points to monitor, Clinical reminder.'
)
ON CONFLICT (key) DO UPDATE SET system_prompt = EXCLUDED.system_prompt;