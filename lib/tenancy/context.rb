# frozen_string_literal: true

module Tenancy
  # ÚNICO punto de acceso a datos tenant (D-07 / ADR-0002).
  #
  # Toda consulta o escritura sobre tablas tenant DEBE ejecutarse dentro de
  # Tenancy::Context.with(account_id:, organization_id:), que abre una
  # transacción ActiveRecord y fija SET LOCAL app.account_id (y
  # app.organization_id si aplica) para que las políticas RLS de PostgreSQL
  # apliquen. Fuera de este bloque las políticas niegan por defecto.
  #
  # Workers fijan el contexto a partir de los argumentos del job — prohibido
  # eludir este helper (PITFALL #1).
  module Context
    Error = Class.new(StandardError)

    class << self
      def with(account_id:, organization_id: nil)
        raise ArgumentError, "account_id es obligatorio" if account_id.nil?

        ActiveRecord::Base.connection.transaction do
          set_local_guc("app.account_id", account_id)
          set_local_guc("app.organization_id", organization_id) if organization_id
          yield
        end
      end

      # Bloque SOLO para flujos internos de provisión (alta de cuentas en
      # signup/onboarding administrativo). Permite INSERT..RETURNING sobre la
      # tabla accounts sin conocer aún su id. Nunca usar para consultas tenant.
      def provisioning
        ActiveRecord::Base.connection.transaction do
          conn = ActiveRecord::Base.connection
          conn.execute(
            "SELECT set_config(#{conn.quote('app.provisioning')}, #{conn.quote('on')}, true)"
          )
          yield
        end
      end

      private

      # set_config(..., true) equivale a SET LOCAL: válido solo durante la transacción.
      def set_local_guc(name, value)
        conn = ActiveRecord::Base.connection
        Integer(value) # coerción temprana: nunca interpolar entrada sin validar
        conn.execute(
          "SELECT set_config(#{conn.quote(name)}, #{conn.quote(Integer(value).to_s)}, true)"
        )
      end
    end
  end
end
