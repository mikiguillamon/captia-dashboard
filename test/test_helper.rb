ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

# El dumper de schema.rb no serializa políticas RLS: las aplicamos de forma
# idempotente en la base de tests (serializado con advisory lock para
# parallelize). Dev/producción las aplican vía migración EnableTenancyRls.
if Rails.env.test?
  conn = ActiveRecord::Base.connection
  %w[accounts organizations].each do |table|
    conn.execute("ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY")
    conn.execute("ALTER TABLE #{table} FORCE ROW LEVEL SECURITY")
  end
  conn.transaction do
    conn.execute("SELECT pg_advisory_xact_lock(20260825)")
    %w[accounts_rls organizations_rls].each do |file|
      File.read(Rails.root.join("db/policies/#{file}.sql"))
          .split(/;\s*$/).map(&:strip).reject(&:empty?)
          .reject { |stmt| stmt.start_with?("ALTER TABLE") }
          .each { |stmt| conn.execute(stmt) }
    end
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Sin fixtures: los tests crean sus propios datos. El chequeo previo de FK
    # de FixtureSet escribe en pg_catalog.pg_constraint, vedado al rol
    # no-superusuario captia_app (ADR-0002).
    #
    # Add more helper methods to be used by all tests here...
  end
end
