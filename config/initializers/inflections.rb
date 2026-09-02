# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

# Fase 2: el namespace CRM (app/models/crm/) debe resolverse como constant «CRM»
# (todas mayúsculas), no «Crm». Zeitwerk cameliza el directorio crm/ a Crm por
# defecto, lo que rompería la autocarga de CRM::Lead/Contact/Opportunity.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "CRM"
end
