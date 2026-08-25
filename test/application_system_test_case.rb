require "test_helper"
require "capybara/cuprite"

# Driver cuprite: CDP directo contra Chrome instalado (sin chromedriver).
Capybara.register_driver(:cuprite_headless) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 1280, 800 ],
    process_timeout: 15,
    timeout: 20
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite_headless
end
