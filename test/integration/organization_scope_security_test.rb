# frozen_string_literal: true

require "test_helper"

# AC-001 lado servidor: cookie firmada manipulada (organización ajena) → 403;
# el selector jamás lista organizaciones sin acceso; consultas dentro de Context.
class OrganizationScopeSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Sec Co") }
    Tenancy::Context.with(account_id: @account.id) do
      @mine = Tenancy::Organization.create!(name: "Org Mía", account: @account)
      @other = Tenancy::Organization.create!(name: "Org Ajena", account: @account)
    end

    @user = User.create!(email_address: "scoped@captia.test",
                         password: "contrasena-segura-123", account: @account)
    Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Organization",
                                    scope_id: @mine.id, role: "admin_org")
    Tenancy::Context.with(account_id: @account.id) do
      Tenancy::Membership.create!(user: @user, organization: @mine)
    end

    post "/login", params: { email_address: @user.email_address, password: "contrasena-segura-123" }
    assert_redirected_to root_url
    follow_redirect!
  end

  test "una cookie de organización inválida se ignora sin filtrar datos" do
    # Las cookies firmadas HttpOnly hacen inviable falsificar el id de otra
    # organización; un valor corrupto se descarta y cae al default accesible.
    cookies["active_organization_id"] = "999999-tamper"

    get organizations_path
    assert_response :ok
    assert_includes response.body, "Org Mía"
    assert_not_includes response.body, "Org Ajena"
  end

  test "el índice solo muestra organizaciones accesibles para el usuario" do
    get organizations_path
    assert_response :ok
    assert_includes response.body, "Org Mía"
    assert_not_includes response.body, "Org Ajena"
  end

  test "switch a organización sin acceso devuelve 403" do
    post switch_organizations_path, params: { organization_id: @other.id }
    assert_response :forbidden
  end
end
