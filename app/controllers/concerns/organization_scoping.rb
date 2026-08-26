# frozen_string_literal: true

# AC-001: resuelve la organización activa desde cookie firmada validando que
# el usuario tiene acceso (membership directa o rol a nivel cuenta).
# TODAS las consultas sobre tablas tenant van dentro de Tenancy::Context
# (D-07); los resultados se materializan porque SET LOCAL vive solo durante
# la transacción del bloque.
module OrganizationScoping
  extend ActiveSupport::Concern

  included do
    helper_method :current_organization, :accessible_organizations
  end

  private

  def current_organization
    @current_organization ||= resolve_active_organization
  end

  def accessible_organizations
    @accessible_organizations ||= begin
      return [] unless Current.user&.account_id

      Tenancy::Context.with(account_id: Current.user.account_id) do
        accessible_scope.order(:created_at).to_a
      end
    end
  end

  def require_organization_membership!
    current_organization || render(plain: "Forbidden", status: :forbidden) && false
  end

  def set_active_organization!(organization)
    cookies.signed[:active_organization_id] = {
      value: organization.id, httponly: true, same_site: :lax
    }
    @current_organization = organization
    @accessible_organizations = nil
  end

  def resolve_active_organization
    return nil unless Current.user&.account_id

    candidates = accessible_organizations
    return nil if candidates.empty?

    org_id = cookies.signed[:active_organization_id]
    candidates.find { |o| o.id == org_id } || candidates.first
  end

  def accessible_scope
    account_id = Current.user.account_id

    has_account_role = Current.user.role_assignments.exists?(
      scope_type: "Tenancy::Account", scope_id: account_id
    )
    if has_account_role
      Tenancy::Organization.where(account_id: account_id)
    else
      Tenancy::Organization.joins(:memberships).where(memberships: { user_id: Current.user.id })
    end
  end
end
