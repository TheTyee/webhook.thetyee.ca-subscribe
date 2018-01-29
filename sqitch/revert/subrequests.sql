-- Revert emailsubs:subrequests from pg

BEGIN;

DROP TABLE subrequests;

COMMIT;
