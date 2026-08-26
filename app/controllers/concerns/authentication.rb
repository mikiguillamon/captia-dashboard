module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    # SEG-03 / AC-006 (puente skeleton): mientras no existan memberships
    # (01-03), "organizaciones del usuario" = organizaciones de su cuenta.
    # Si alguna exige MFA y el usuario carece de enrollment confirmado, el
    # login se bloquea ANTES de crear Session de acceso.
    def organization_requires_mfa?(user)
      return false if user.account_id.nil?
      return false if user.mfa_enrollment&.confirmed?

      Tenancy::Context.with(account_id: user.account_id) do
        Tenancy::Organization.where(require_mfa: true).exists?
      end
    rescue ActiveRecord::RecordNotFound
      false
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
