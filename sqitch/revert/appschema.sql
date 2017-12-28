-- Revert emailsubs:appschema from pg

BEGIN;

DROP SCHEMA emailsubs;

COMMIT;
