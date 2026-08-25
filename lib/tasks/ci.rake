# frozen_string_literal: true

# Gate de calidad de fase (QUALITY_BAR / D-02, D-08):
#   rake ci = test completo + estilo + seguridad estática.
# Fallar en CUALQUIER aviso de brakeman (estricto por defecto; el proyecto es
# security-sensitive: identidad, MFA, aislamiento).
desc "Gates de calidad: tests + rubocop + brakeman"
task ci: %w[test:all rubocop brakeman_gate]

desc "Brakeman estricto: cualquier warning falla el gate"
task :brakeman_gate do
  sh "bundle exec brakeman --no-pager -q --exit-on-warn"
end
