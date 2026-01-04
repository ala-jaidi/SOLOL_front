-- Enable Row Level Security on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.foot_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.foot_scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_questionnaires ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prompt_templates ENABLE ROW LEVEL SECURITY;

-- Users table policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
CREATE POLICY "Users can view their own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
CREATE POLICY "Users can insert their own profile" ON public.users
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
CREATE POLICY "Users can update their own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (true);

DROP POLICY IF EXISTS "Users can delete their own profile" ON public.users;
CREATE POLICY "Users can delete their own profile" ON public.users
  FOR DELETE USING (auth.uid() = id);

-- Patients table policies (accessible by authenticated users)
DROP POLICY IF EXISTS "Authenticated users can view patients" ON public.patients;
CREATE POLICY "Authenticated users can view patients" ON public.patients
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can insert patients" ON public.patients;
CREATE POLICY "Authenticated users can insert patients" ON public.patients
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can update patients" ON public.patients;
CREATE POLICY "Authenticated users can update patients" ON public.patients
  FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can delete patients" ON public.patients;
CREATE POLICY "Authenticated users can delete patients" ON public.patients
  FOR DELETE USING (auth.role() = 'authenticated');

-- Sessions table policies
DROP POLICY IF EXISTS "Authenticated users can view sessions" ON public.sessions;
CREATE POLICY "Authenticated users can view sessions" ON public.sessions
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can insert sessions" ON public.sessions;
CREATE POLICY "Authenticated users can insert sessions" ON public.sessions
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can update sessions" ON public.sessions;
CREATE POLICY "Authenticated users can update sessions" ON public.sessions
  FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can delete sessions" ON public.sessions;
CREATE POLICY "Authenticated users can delete sessions" ON public.sessions
  FOR DELETE USING (auth.role() = 'authenticated');

-- Foot metrics table policies
DROP POLICY IF EXISTS "Authenticated users can view foot metrics" ON public.foot_metrics;
CREATE POLICY "Authenticated users can view foot metrics" ON public.foot_metrics
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can insert foot metrics" ON public.foot_metrics;
CREATE POLICY "Authenticated users can insert foot metrics" ON public.foot_metrics
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can update foot metrics" ON public.foot_metrics;
CREATE POLICY "Authenticated users can update foot metrics" ON public.foot_metrics
  FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can delete foot metrics" ON public.foot_metrics;
CREATE POLICY "Authenticated users can delete foot metrics" ON public.foot_metrics
  FOR DELETE USING (auth.role() = 'authenticated');

-- Foot scans table policies
DROP POLICY IF EXISTS "Authenticated users can view foot scans" ON public.foot_scans;
CREATE POLICY "Authenticated users can view foot scans" ON public.foot_scans
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can insert foot scans" ON public.foot_scans;
CREATE POLICY "Authenticated users can insert foot scans" ON public.foot_scans
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can update foot scans" ON public.foot_scans;
CREATE POLICY "Authenticated users can update foot scans" ON public.foot_scans
  FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can delete foot scans" ON public.foot_scans;
CREATE POLICY "Authenticated users can delete foot scans" ON public.foot_scans
  FOR DELETE USING (auth.role() = 'authenticated');

-- Medical questionnaires table policies
DROP POLICY IF EXISTS "Authenticated users can view questionnaires" ON public.medical_questionnaires;
CREATE POLICY "Authenticated users can view questionnaires" ON public.medical_questionnaires
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can insert questionnaires" ON public.medical_questionnaires;
CREATE POLICY "Authenticated users can insert questionnaires" ON public.medical_questionnaires
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can update questionnaires" ON public.medical_questionnaires;
CREATE POLICY "Authenticated users can update questionnaires" ON public.medical_questionnaires
  FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can delete questionnaires" ON public.medical_questionnaires;
CREATE POLICY "Authenticated users can delete questionnaires" ON public.medical_questionnaires
  FOR DELETE USING (auth.role() = 'authenticated');

-- Notifications table policies (users can only see their own)
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own notifications" ON public.notifications;
CREATE POLICY "Users can insert their own notifications" ON public.notifications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
CREATE POLICY "Users can delete their own notifications" ON public.notifications
  FOR DELETE USING (auth.uid() = user_id);

-- Chat messages table policies (users can only see their own)
DROP POLICY IF EXISTS "Users can view their own messages" ON public.chat_messages;
CREATE POLICY "Users can view their own messages" ON public.chat_messages
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own messages" ON public.chat_messages;
CREATE POLICY "Users can insert their own messages" ON public.chat_messages
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own messages" ON public.chat_messages;
CREATE POLICY "Users can update their own messages" ON public.chat_messages
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own messages" ON public.chat_messages;
CREATE POLICY "Users can delete their own messages" ON public.chat_messages
  FOR DELETE USING (auth.uid() = user_id);

-- Prompt templates table policies
DROP POLICY IF EXISTS "Authenticated users can view prompt templates" ON public.prompt_templates;
CREATE POLICY "Authenticated users can view prompt templates" ON public.prompt_templates
  FOR SELECT USING (auth.role() = 'authenticated');
