require "test_helper"
require "capybara/cuprite"

# Driver cuprite: CDP directo contra Chrome instalado (sin chromedriver).
Capybara.register_driver(:cuprite_headless) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 1280, 800 ],
    process_timeout: 30,
    timeout: 30
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite_headless

  # Los navegadores headless en paralelo agotan recursos y provocan crashes
  # de Chrome: los system tests corren en serie.
  parallelize(workers: 1)

  # Arranques en frío de Chrome/Puma en suite completa pueden superar el
  # default de 2s en el primer render tras submit.
  Capybara.default_max_wait_time = 6
end
