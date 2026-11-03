ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

# El dumper de schema.rb no serializa políticas RLS: las aplicamos de forma
# idempotente en la base de tests (serializado con advisory lock para
# parallelize). Dev/producción las aplican vía migración EnableTenancyRls.
if Rails.env.test?
  conn = ActiveRecord::Base.connection
  %w[accounts organizations crm_leads crm_contacts crm_opportunities pipeline_stages service_instances].each do |table|
    conn.execute("ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY")
    conn.execute("ALTER TABLE #{table} FORCE ROW LEVEL SECURITY")
  end
  conn.transaction do
    conn.execute("SELECT pg_advisory_xact_lock(20260825)")
    %w[accounts_rls organizations_rls crm_service_rls].each do |file|
      File.read(Rails.root.join("db/policies/#{file}.sql"))
          .split(/;\s*$/).map(&:strip).reject(&:empty?)
          .reject { |stmt| stmt.start_with?("ALTER TABLE") }
          .each { |stmt| conn.execute(stmt) }
    end
  end
end

module ActiveSupport
  class TestCase
    # La suite corre en serie por defecto. La autorización de tenancy usa
    # Tenancy::Context (SET LOCAL app.account_id dentro de una transacción) con
    # un pool de conexiones reducido (max_connections: 5) y RLS FORCE en 9 tablas.
    # Bajo `parallelize(workers: :number_of_processors)` los forks heredan estado
    # de conexión/SET LOCAL entrelazado y la suite cuelga silenciosamente (deadlock
    # en advisory lock + DDL de RLS). Serial es determinista y verde (~4s).
    # Opt-in a paralelismo con PARALLEL_WORKERS > 1 solo si se subsana la
    # concurrencia del contexto tenant (no está pendiente en este momento).
    parallelize(workers: Integer(ENV.fetch("PARALLEL_WORKERS", 1)))

    # El rate_limit usa el cache store (memory en test): sin esta limpieza,
    # los intentos acumulados entre suites del mismo proceso disparan el
    # límite de login de forma intermitente según el orden de ejecución.
    setup do
      Rails.cache.clear
    end

    # Sin fixtures: los tests crean sus propios datos. El chequeo previo de FK
    # de FixtureSet escribe en pg_catalog.pg_constraint, vedado al rol
    # no-superusuario captia_app (ADR-0002).
    #
    # Add more helper methods to be used by all tests here...
  end
end
