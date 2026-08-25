require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "rechaza contraseñas con menos de 12 caracteres" do
    user = User.new(email_address: "corta@captia.test", password: "corta-12345")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 12 characters)"
  end

  test "acepta contraseñas de 12 caracteres o más" do
    user = User.new(email_address: "larga@captia.test", password: "doce-exacto!")
    assert_equal 12, user.password.length
    assert user.valid?
  end
end
