-- Aislamiento RLS para modelos de Fase 2 (CRM + catálogo de servicios), D-07/ADR-0002.
-- Sigue el patrón NULLIF-safe de accounts_rls/organizations_rls:
-- current_setting devuelve '' tras un SET LOCAL revertido; sin NULLIF el cast
-- ::bigint fallaría en lugar de negar la fila (deny-by-default).
--
-- CRM (crm_leads, crm_contacts, crm_opportunities, pipeline_stages):
--   ámbito de cuenta directo vía account_id = app.account_id.
-- service_instances:
--   ámbito via organization_id → cadena de cuenta: la organización debe
--   pertenecer a la cuenta del contexto. Proporciona aislamiento por org
--   sin exigir un GUC app.organization_id (que Tenancy::Context solo fija
--   cuando hay organización concreta resuelta).

-- CRM leads -------------------------------------------------------------------
ALTER TABLE crm_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_leads FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS crm_leads_tenant_isolation ON crm_leads;
CREATE POLICY crm_leads_tenant_isolation ON crm_leads
  USING (
    account_id = NULLIF(current_setting('app.account_id', true), '')::bigint
  )
  WITH CHECK (
    account_id = NULLIF(current_setting('app.account_id', true), '')::bigint
  );

-- CRM contacts ----------------------------------------------------------------
ALTER TABLE crm_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_contacts FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS crm_contacts_tenant_isolation ON crm_contacts;
CREATE POLICY crm_contacts_tenant_isolation ON crm_contacts
  USING (
    account_id = NULLIF(current_setting('app.account_id', true), '')::bigint
  )
  WITH CHECK (
    account_id = NULLIF(current_setting('app.account_id', true), '')::bigint
  );

-- CRM opportunities -----------------------------------------------------------
ALTER TABLE crm_opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_opportunities FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS crm_opportunities_tenant_isolation ON crm_opportunities;
CREATE POLICY crm_opportunities_tenant_isolation ON crm_opportunities
  USING (
    account_id = NULLIF(current_setting('app.account_id', true), '')::bigint
  )
  WITH CHECK (
    account_id = NULLIF(current_setting('app.account_id', true), '')::bigint
  );

-- pipeline stages -------------------------------------------------------------
ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_stages FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pipeline_stages_tenant_isolation ON pipeline_stages;
CREATE POLICY pipeline_stages_tenant_isolation ON pipeline_stages
  USING (
    account_id = NULLIF(current_setting('app.account_id', true), '')::bigint
  )
  WITH CHECK (
    account_id = NULLIF(current_setting('app.account_id', true), '')::bigint
  );

-- service instances -----------------------------------------------------------
ALTER TABLE service_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_instances FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS service_instances_tenant_isolation ON service_instances;
CREATE POLICY service_instances_tenant_isolation ON service_instances
  USING (
    organization_id IN (
      SELECT id
      FROM organizations
      WHERE account_id = NULLIF(current_setting('app.account_id', true), '')::bigint
    )
  )
  WITH CHECK (
    organization_id IN (
      SELECT id
      FROM organizations
      WHERE account_id = NULLIF(current_setting('app.account_id', true), '')::bigint
    )
  );