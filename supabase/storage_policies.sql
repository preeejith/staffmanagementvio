-- ============================================================
-- SUPABASE STORAGE BUCKETS & POLICIES
-- Run this AFTER schema.sql in Supabase SQL Editor
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- Create Buckets
-- ────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('employee-documents', 'employee-documents', false),
  ('expense-bills',      'expense-bills',      false),
  ('banners',            'banners',            true),
  ('profile-photos',     'profile-photos',     true)
ON CONFLICT (id) DO NOTHING;

-- ════════════════════════════════════════════════════════════
-- BUCKET: employee-documents (private)
-- Path convention: {user_id}/aadhaar.jpg | {user_id}/licence.jpg
-- ════════════════════════════════════════════════════════════

-- Employee: upload to their own folder only
CREATE POLICY "emp_docs_insert_own"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'employee-documents'
    AND auth.uid()::text = (string_to_array(name, '/'))[1]
  );

-- Employee: read their own files only
CREATE POLICY "emp_docs_select_own"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'employee-documents'
    AND (
      auth.uid()::text = (string_to_array(name, '/'))[1]
      OR is_admin()
    )
  );

-- Admin: update/delete any document
CREATE POLICY "emp_docs_update_admin"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'employee-documents' AND is_admin());

CREATE POLICY "emp_docs_delete_admin"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'employee-documents' AND is_admin());

-- ════════════════════════════════════════════════════════════
-- BUCKET: expense-bills (private)
-- Path convention: {user_id}/{expense_id}/{timestamp}.jpg
-- ════════════════════════════════════════════════════════════

CREATE POLICY "bills_insert_own"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'expense-bills'
    AND auth.uid()::text = (string_to_array(name, '/'))[1]
  );

CREATE POLICY "bills_select"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'expense-bills'
    AND (
      auth.uid()::text = (string_to_array(name, '/'))[1]
      OR is_admin()
    )
  );

CREATE POLICY "bills_delete_own_or_admin"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'expense-bills'
    AND (
      auth.uid()::text = (string_to_array(name, '/'))[1]
      OR is_admin()
    )
  );

-- ════════════════════════════════════════════════════════════
-- BUCKET: banners (public read)
-- ════════════════════════════════════════════════════════════

CREATE POLICY "banners_select_all"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'banners');

CREATE POLICY "banners_insert_admin"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'banners' AND is_admin());

CREATE POLICY "banners_update_admin"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'banners' AND is_admin());

CREATE POLICY "banners_delete_admin"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'banners' AND is_admin());

-- ════════════════════════════════════════════════════════════
-- BUCKET: profile-photos (public read)
-- ════════════════════════════════════════════════════════════

CREATE POLICY "photos_select_all"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profile-photos');

-- Employee uploads to their own folder
CREATE POLICY "photos_insert_own"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-photos'
    AND auth.uid()::text = (string_to_array(name, '/'))[1]
  );

-- Admin can manage all
CREATE POLICY "photos_manage_admin"
  ON storage.objects FOR ALL
  USING (bucket_id = 'profile-photos' AND is_admin());
