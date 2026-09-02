# frozen_string_literal: true

# Validador JSON Schema (subconjunto Draft-07) sobre columnas JSONB.
#
# Alternativa custom a la gema activerecord-json_validator decidida en
# 02-CONTEXT.md (evita dependencia externa; comportamiento cubierto por tests).
# Cubre el subconjunto que usan los CONFIG_SCHEMA de Fase 2:
#   type, properties, required, items, enum, format (básico), adicionalProperties=false
#
# Uso (en cada subclase STI):
#   validates :configuration,
#     json_schema: { schema: ->(record) { record.class::CONFIG_SCHEMA } }
class JsonSchemaValidator < ActiveModel::EachValidator
  FORMATS = {
    "email" => ->(v) { v.is_a?(String) && URI::MailTo::EMAIL_REGEXP.match?(v) },
    "uri"   => lambda { |v|
      return false unless v.is_a?(String)

      begin
        URI.parse(v).scheme.present?
      rescue URI::InvalidURIError
        false
      end
    }
  }.freeze

  def validate_each(record, attribute, value)
    schema = deep_stringify_keys(options[:schema].call(record))
    return if value.nil?

    unless value.is_a?(Hash)
      record.errors.add(attribute, :invalid, message: "debe ser un objeto")
      return
    end

    errors = []
    # Normalizamos el valor a claves string: los CONFIG_SCHEMA se declaran con
    # claves símbolo (concisión) pero JSONB entrega/acepta claves string.
    validate_object(deep_stringify_keys(value), schema, errors, "config")
    errors.each { |msg| record.errors.add(attribute, "inválida: #{msg}") }
  end

  private

  def deep_stringify_keys(obj)
    case obj
    when Hash
      obj.each_with_object({}) do |(k, v), acc|
        acc[k.to_s] = deep_stringify_keys(v)
      end
    when Array
      obj.map { |item| deep_stringify_keys(item) }
    else
      obj
    end
  end

  def validate_object(object, schema, errors, path)
    properties = schema["properties"] || {}
    required   = schema["required"] || []

    # required: todos los campos obligatorios presentes
    required.each do |key|
      errors << "#{path}.#{key} es obligatorio" unless object.key?(key)
    end

    object.each do |key, val|
      schema = properties[key]
      if schema.nil?
        # strict mode: propiedades no declaradas rechazadas (AC Plan 03)
        errors << "#{path}.#{key} no está permitido por el esquema"
        next
      end

      validate_value(val, schema, "#{path}.#{key}", errors)
    end
  end

  def validate_value(value, schema, path, errors)
    expected = schema["type"]

    unless type_matches?(value, expected)
      errors << "#{path} debe ser del tipo #{expected}"
      return
    end

    case expected
    when "object"
      # objetos anidados (p.ej. escalation_rules items) no empleados hoy; defensa
      validate_object(value, schema, errors, path) unless value.nil?
    when "array"
      item_schema = schema["items"]
      return unless item_schema

      value.each_with_index do |item, idx|
        item_path = "#{path}[#{idx}]"
        if item_schema["type"] && !type_matches?(item, item_schema["type"])
          errors << "#{item_path} debe ser del tipo #{item_schema['type']}"
          next
        end
        if item_schema["type"] == "object"
          validate_object(item, item_schema, errors, item_path)
        else
          validate_scalar_constraints(item, item_schema, item_path, errors)
        end
      end
    end

    validate_scalar_constraints(value, schema, path, errors)
  end

  # enum + format sobre escalares (incluye items de arrays)
  def validate_scalar_constraints(value, schema, path, errors)
    if schema.key?("enum") && !schema["enum"].include?(value)
      errors << "#{path} debe ser uno de: #{schema['enum'].join(', ')}"
    end

    fmt = FORMATS[schema["format"]]
    return unless fmt

    errors << "#{path} no cumple el formato #{schema['format']}" unless fmt.call(value)
  end

  def type_matches?(value, expected)
    case expected
    when "object"  then value.is_a?(Hash)
    when "array"   then value.is_a?(Array)
    when "string"  then value.is_a?(String)
    when "boolean" then value == true || value == false
    when "integer" then value.is_a?(Integer)
    when "number"  then value.is_a?(Numeric)
    when nil       then true
    else true
    end
  end
end
