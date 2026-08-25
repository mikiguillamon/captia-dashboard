-- Aislamiento RLS para accounts (raíz del tenant, ADR-0002).
-- Lectura/actualización limitadas a la cuenta del contexto; la inserción está
-- permitida para los flujos de provisión internos (signup/onboarding) y queda
-- registrada como decisión en 01-01-SUMMARY. El threat model T1-01 protege
-- lecturas cruzadas de datos de cliente, cubiertas por USING estricto.
-- NULLIF: current_setting devuelve '' tras un SET LOCAL revertido; evita que el
-- cast ::bigint lance error en lugar de negar.
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS accounts_tenant_read ON accounts;
CREATE POLICY accounts_tenant_read ON accounts
  FOR SELECT
  USING (
    id = NULLIF(current_setting('app.account_id', true), '')::bigint
  );

DROP POLICY IF EXISTS accounts_tenant_update ON accounts;
CREATE POLICY accounts_tenant_update ON accounts
  FOR UPDATE
  USING (
    id = NULLIF(current_setting('app.account_id', true), '')::bigint
  )
  WITH CHECK (
    id = NULLIF(current_setting('app.account_id', true), '')::bigint
  );

DROP POLICY IF EXISTS accounts_provision_insert ON accounts;
CREATE POLICY accounts_provision_insert ON accounts
  FOR INSERT
  WITH CHECK (true);

-- Provisión controlada: ActiveRecord usa INSERT ... RETURNING y PostgreSQL exige
-- visibilidad de la fila insertada vía políticas SELECT. Esta política solo se
-- activa dentro de Tenancy::Context.provisioning (flujos internos de alta de
-- cuentas); en cualquier otro contexto sigue el deny-by-default estricto.
DROP POLICY IF EXISTS accounts_provision_read ON accounts;
CREATE POLICY accounts_provision_read ON accounts
  FOR SELECT
  USING (current_setting('app.provisioning', true) = 'on');
