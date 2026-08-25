# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_account_id

  private

  # Puente provisional del walking skeleton: la cuenta del usuario vía
  # users.account_id hasta que memberships (01-03) sea la fuente canónica.
  def current_account_id
    Current.user&.account_id
  end
end
