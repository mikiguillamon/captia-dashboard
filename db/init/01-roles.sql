-- Roles y bases de datos locales de desarrollo (se ejecuta solo en el primer arranque del volumen).
-- Principio ADR-0002/T1-01: Rails se conecta SIEMPRE como rol NO superusuario y sin BYPASSRLS.
-- En producción habrá dos roles (owner de migraciones vs runtime); en dev unificamos el rol
-- no-superusuario captia_app como propietario de objetos, cubierto por FORCE ROW LEVEL SECURITY.
\set ON_ERROR_STOP on

CREATE ROLE captia_app LOGIN PASSWORD 'captia'
  NOSUPERUSER NOCREATEDB NOBYPASSRLS;

ALTER DATABASE captia_dev OWNER TO captia_app;
CREATE DATABASE captia_test OWNER captia_app;

\connect captia_dev
ALTER SCHEMA public OWNER TO captia_app;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE, CREATE ON SCHEMA public TO captia_app;

\connect captia_test
ALTER SCHEMA public OWNER TO captia_app;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE, CREATE ON SCHEMA public TO captia_app;
