-- Aislamiento RLS para organizations (D-07): deny-by-default.
-- NULLIF: tras un SET LOCAL revertido en la misma sesión, current_setting
-- devuelve '' (no NULL); sin NULLIF el cast ::bigint fallaría en vez de negar.
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS organizations_tenant_isolation ON organizations;
CREATE POLICY organizations_tenant_isolation ON organizations
  USING (
    account_id = NULLIF(current_setting('app.account_id', true), '')::bigint
  )
  WITH CHECK (
    account_id = NULLIF(current_setting('app.account_id', true), '')::bigint
  );
