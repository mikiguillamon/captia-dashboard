# frozen_string_literal: true

require "test_helper"

# CRM-01/02/03: CRUD de leads/contactos + conversión, autorización por
# capacidad y aislamiento RLS cross-account.
class CrmLeadsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @account = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Ventas Co", status: "active") }

    # Usuario interno con rol "comercial" a nivel cuenta.
    @user = User.create!(email_address: "sales@test.com", password: "password123456",
                         account_id: @account.id)
    Tenancy::RoleAssignment.create!(user: @user, scope_type: "Tenancy::Account",
                                    scope_id: @account.id, role: "comercial")
    sign_in_as(@user)
  end

  test "index lista leads de la cuenta" do
    Tenancy::Context.with(account_id: @account.id) do
      CRM::Lead.create!(email: "l@test.com", name: "Lead Uno", account_id: @account.id)
      CRM::Lead.create!(email: "m@test.com", name: "Lead Dos", account_id: @account.id)
    end

    get crm_leads_path
    assert_response :success
    assert_select "li", count: 2
  end

  test "crear lead persiste vinculado a la cuenta" do
    assert_difference -> { Tenancy::Context.with(account_id: @account.id) { CRM::Lead.count } }, 1 do
      post crm_leads_path, params: { crm_lead: { name: "Nuevo Lead", email: "nuevo@test.com" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
  end

  test "convertir lead crea cuenta cliente y contacto" do
    lead = Tenancy::Context.with(account_id: @account.id) do
      CRM::Lead.create!(email: "conv@test.com", name: "Ada Lovelace", company: "Analytical Engines",
                        account_id: @account.id)
    end

    assert_difference -> { Tenancy::Context.provisioning { Tenancy::Account.count } }, 1 do
      post convert_crm_lead_path(lead)
    end
    assert_response :redirect

    lead = Tenancy::Context.with(account_id: @account.id) { CRM::Lead.find(lead.id) }
    assert_equal "converted", lead.status
    assert lead.converted_at.present?
  end

  test "usuario sin manage_leads obtiene 403" do
    other = User.create!(email_address: "cliente@test.com", password: "password123456",
                         account_id: @account.id)
    # cliente (operativo) sin capacidades CRM.
    Tenancy::RoleAssignment.create!(user: other, scope_type: "Tenancy::Account",
                                    scope_id: @account.id, role: "operativo")
    sign_in_as(other)

    get crm_leads_path
    assert_response :forbidden
  end

  test "aislamiento RLS: lead de otra cuenta no visible" do
    beta = Tenancy::Context.provisioning { Tenancy::Account.create!(name: "Beta", status: "active") }
    Tenancy::Context.with(account_id: beta.id) do
      CRM::Lead.create!(email: "beta@test.com", name: "Lead Beta", account_id: beta.id)
    end

    get crm_leads_path
    assert_response :success
    assert_select "li", count: 0
  end
end
