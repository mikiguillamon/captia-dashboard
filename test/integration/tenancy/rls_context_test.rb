# frozen_string_literal: true

require "test_helper"

module Tenancy
  # Prueba negativa del aislamiento RLS (D-07, threat T1-01):
  # sin contexto transaccional las tablas tenant devuelven 0 filas y los
  # intentos de escritura fuera de contexto son rechazados por PostgreSQL.
  #
  # Nota: los tests de Rails van envueltos en una transacción externa, así que
  # SET LOCAL dentro de Context.with vive hasta el fin del test (savepoint).
  # Para simular el estado real "fuera de contexto" usamos clear_tenant_context!,
  # que restablece el baseline de sesión (mismo estado que deja un request real
  # al terminar su transacción).
  class RlsContextTest < ActionDispatch::IntegrationTest
    test "insertar y leer dentro de Context.with funciona" do
      alpha = create_account!("Alpha")

      Tenancy::Context.with(account_id: alpha.id) do
        org = Tenancy::Organization.create!(name: "Org Alpha 1", account: alpha)
        assert_equal 1, Tenancy::Organization.count
        assert_not_nil org.id
      end
    end

    test "consulta tenant SIN contexto devuelve 0 filas" do
      alpha = create_account!("Alpha")
      Tenancy::Context.with(account_id: alpha.id) do
        Tenancy::Organization.create!(name: "Org Alpha", account: alpha)
      end

      clear_tenant_context!
      # Sin contexto: la política USING no encuentra app.account_id → 0 filas.
      assert_equal 0, Tenancy::Organization.count, "RLS debe negar filas sin contexto"
      assert_equal 0, Tenancy::Account.count, "Accounts también denegadas sin contexto"
    end

    test "escribir tenant SIN contexto es rechazado por RLS" do
      alpha = create_account!("Alpha")
      clear_tenant_context!
      # Segunda barrera (PostgreSQL): WITH CHECK exige account_id == contexto.
      # SQL crudo para saltarnos validaciones de la capa aplicación.
      conn = ActiveRecord::Base.connection
      error = assert_raises(ActiveRecord::StatementInvalid) do
        conn.execute(
          "INSERT INTO organizations (account_id, name, created_at, updated_at) " \
          "VALUES (#{alpha.id}, 'Ilegal', now(), now())"
        )
      end
      assert_match(/row-level security/, error.message)
    end

    test "no se pueden leer organizaciones de otra cuenta aunque haya contexto propio" do
      alpha = create_account!("Alpha")
      beta = create_account!("Beta")

      alpha_org_id = Tenancy::Context.with(account_id: alpha.id) do
        Tenancy::Organization.create!(name: "Org Alpha", account: alpha).id
      end

      clear_tenant_context!
      Tenancy::Context.with(account_id: beta.id) do
        assert_equal 0, Tenancy::Organization.where(id: alpha_org_id).count,
                     "Datos de otra cuenta no deben ser visibles"
        assert_equal 0, Tenancy::Account.where(id: alpha.id).count,
                     "La cuenta ajena tampoco debe ser visible"
        # Control positivo: la cuenta propia SÍ es visible con contexto válido.
        assert_equal 1, Tenancy::Account.where(id: beta.id).count
      end
    end

    private

    def create_account!(name)
      # El alta de cuentas es un flujo de provisión interno (signup/onboarding).
      Tenancy::Context.provisioning do
        Tenancy::Account.create!(name: name)
      end
    end

    # Restablece el baseline de sesión: equivale al estado de una conexión del
    # pool tras completarse un request real (SET LOCAL ya revertido).
    def clear_tenant_context!
      conn = ActiveRecord::Base.connection
      %w[app.account_id app.organization_id app.provisioning].each do |guc|
        conn.execute("SELECT set_config('#{guc}', '', false)")
      end
    end
  end
end
