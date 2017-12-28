-- Verify emailsubs:appschema on pg

BEGIN;

SELECT pg_catalog.has_schema_privilege('emailsubs', 'usage');


ROLLBACK;
