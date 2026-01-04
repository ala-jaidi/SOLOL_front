-- Pending migrations: make updated_at triggers idempotent and safe to re-apply
-- This file includes only the statements that must run again on the remote DB.

-- Ensure trigger function is present
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate triggers safely (drop-if-exists then create)
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_patients_updated_at ON public.patients;
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON public.patients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sessions_updated_at ON public.sessions;
CREATE TRIGGER update_sessions_updated_at BEFORE UPDATE ON public.sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_foot_metrics_updated_at ON public.foot_metrics;
CREATE TRIGGER update_foot_metrics_updated_at BEFORE UPDATE ON public.foot_metrics FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_foot_scans_updated_at ON public.foot_scans;
CREATE TRIGGER update_foot_scans_updated_at BEFORE UPDATE ON public.foot_scans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_questionnaires_updated_at ON public.medical_questionnaires;
CREATE TRIGGER update_questionnaires_updated_at BEFORE UPDATE ON public.medical_questionnaires FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
