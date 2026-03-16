-- ============================================================
-- STAFF MANAGEMENT SYSTEM — SUPABASE SCHEMA (FIXED ORDER)
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- TABLE: workplaces (before profiles so FK can reference it)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS workplaces (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name              text NOT NULL,
  description       text,
  location          text,
  instructions      text,
  contact_name      text,
  contact_phone     text,
  contact_email     text,
  is_featured       boolean DEFAULT false,
  banner_image_url  text,
  assigned_employees uuid[] DEFAULT '{}',
  is_active         boolean DEFAULT true,
  created_at        timestamptz DEFAULT now()
);

-- ────────────────────────────────────────────────────────────
-- TABLE: profiles
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id                    uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name                  text NOT NULL,
  email                 text NOT NULL,
  phone                 text,
  aadhaar_number        text,
  aadhaar_url           text,
  driving_licence_url   text,
  role                  text NOT NULL DEFAULT 'employee'
                          CHECK (role IN ('superadmin', 'admin', 'employee')),
  assigned_workplace_id uuid REFERENCES workplaces(id) ON DELETE SET NULL,
  is_active             boolean DEFAULT true,
  profile_photo_url     text,
  created_at            timestamptz DEFAULT now(),
  created_by            uuid REFERENCES auth.users(id)
);

-- ────────────────────────────────────────────────────────────
-- TABLE: expenses
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS expenses (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id     uuid REFERENCES profiles(id) ON DELETE SET NULL,
  workplace_id    uuid REFERENCES workplaces(id) ON DELETE SET NULL,
  date            date NOT NULL DEFAULT CURRENT_DATE,
  description     text NOT NULL,
  amount          numeric(10, 2) NOT NULL,
  bill_image_urls text[] DEFAULT '{}',
  status          text DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected')),
  admin_notes     text,
  submitted_at    timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- ────────────────────────────────────────────────────────────
-- TABLE: banners
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS banners (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title         text NOT NULL,
  subtitle      text,
  image_url     text,
  workplace_id  uuid REFERENCES workplaces(id) ON DELETE SET NULL,
  display_order integer DEFAULT 0,
  is_active     boolean DEFAULT true,
  created_at    timestamptz DEFAULT now()
);

-- ────────────────────────────────────────────────────────────
-- TABLE: announcements
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS announcements (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title           text NOT NULL,
  body            text NOT NULL,
  target_audience text DEFAULT 'all',
  is_active       boolean DEFAULT true,
  created_at      timestamptz DEFAULT now()
);

-- ────────────────────────────────────────────────────────────
-- TABLE: audit_logs
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_logs (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id     uuid REFERENCES auth.users(id),
  action       text,
  target_table text,
  target_id    uuid,
  details      jsonb,
  created_at   timestamptz DEFAULT now()
);

-- ────────────────────────────────────────────────────────────
-- HELPER FUNCTION: is_admin()
-- NOTE: Must be defined AFTER the profiles table exists
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role IN ('admin', 'superadmin')
  );
$$;

-- ────────────────────────────────────────────────────────────
-- TRIGGER: auto-create profile on auth.users insert
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO profiles (id, name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'employee')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ────────────────────────────────────────────────────────────
-- TRIGGER: auto-update expenses.updated_at
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS expenses_updated_at ON expenses;
CREATE TRIGGER expenses_updated_at
  BEFORE UPDATE ON expenses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ════════════════════════════════════════════════════════════

ALTER TABLE profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE workplaces    ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses      ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners       ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs    ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────
-- RLS: profiles
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
CREATE POLICY "profiles_select_own"
  ON profiles FOR SELECT
  USING (auth.uid() = id OR is_admin());

DROP POLICY IF EXISTS "profiles_insert_admin" ON profiles;
CREATE POLICY "profiles_insert_admin"
  ON profiles FOR INSERT
  WITH CHECK (is_admin());

DROP POLICY IF EXISTS "profiles_update" ON profiles;
CREATE POLICY "profiles_update"
  ON profiles FOR UPDATE
  USING (auth.uid() = id OR is_admin());

DROP POLICY IF EXISTS "profiles_delete_superadmin" ON profiles;
CREATE POLICY "profiles_delete_superadmin"
  ON profiles FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'superadmin'
    )
  );

-- ────────────────────────────────────────────────────────────
-- RLS: workplaces
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "workplaces_select_auth" ON workplaces;
CREATE POLICY "workplaces_select_auth"
  ON workplaces FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "workplaces_insert_admin" ON workplaces;
CREATE POLICY "workplaces_insert_admin"
  ON workplaces FOR INSERT
  WITH CHECK (is_admin());

DROP POLICY IF EXISTS "workplaces_update_admin" ON workplaces;
CREATE POLICY "workplaces_update_admin"
  ON workplaces FOR UPDATE
  USING (is_admin());

DROP POLICY IF EXISTS "workplaces_delete_admin" ON workplaces;
CREATE POLICY "workplaces_delete_admin"
  ON workplaces FOR DELETE
  USING (is_admin());

-- ────────────────────────────────────────────────────────────
-- RLS: expenses
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "expenses_select" ON expenses;
CREATE POLICY "expenses_select"
  ON expenses FOR SELECT
  USING (auth.uid() = employee_id OR is_admin());

DROP POLICY IF EXISTS "expenses_insert_own" ON expenses;
CREATE POLICY "expenses_insert_own"
  ON expenses FOR INSERT
  WITH CHECK (auth.uid() = employee_id);

DROP POLICY IF EXISTS "expenses_update_admin" ON expenses;
CREATE POLICY "expenses_update_admin"
  ON expenses FOR UPDATE
  USING (is_admin());

DROP POLICY IF EXISTS "expenses_delete_admin" ON expenses;
CREATE POLICY "expenses_delete_admin"
  ON expenses FOR DELETE
  USING (is_admin());

-- ────────────────────────────────────────────────────────────
-- RLS: banners
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "banners_select_auth" ON banners;
CREATE POLICY "banners_select_auth"
  ON banners FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "banners_write_admin" ON banners;
CREATE POLICY "banners_write_admin"
  ON banners FOR ALL
  USING (is_admin());

-- ────────────────────────────────────────────────────────────
-- RLS: announcements
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "announcements_select_auth" ON announcements;
CREATE POLICY "announcements_select_auth"
  ON announcements FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "announcements_write_admin" ON announcements;
CREATE POLICY "announcements_write_admin"
  ON announcements FOR ALL
  USING (is_admin());

-- ────────────────────────────────────────────────────────────
-- RLS: audit_logs
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "audit_logs_select_admin" ON audit_logs;
CREATE POLICY "audit_logs_select_admin"
  ON audit_logs FOR SELECT
  USING (is_admin());

DROP POLICY IF EXISTS "audit_logs_insert_admin" ON audit_logs;
CREATE POLICY "audit_logs_insert_admin"
  ON audit_logs FOR INSERT
  WITH CHECK (is_admin());

-- ════════════════════════════════════════════════════════════
-- INDEXES
-- ════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_profiles_role         ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_workplace     ON profiles(assigned_workplace_id);
CREATE INDEX IF NOT EXISTS idx_expenses_employee      ON expenses(employee_id);
CREATE INDEX IF NOT EXISTS idx_expenses_status        ON expenses(status);
CREATE INDEX IF NOT EXISTS idx_expenses_submitted_at  ON expenses(submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_banners_order          ON banners(display_order);
CREATE INDEX IF NOT EXISTS idx_announcements_active   ON announcements(is_active);
