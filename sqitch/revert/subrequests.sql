-- Revert emailsubs:subrequests from pg

BEGIN;

DROP TABLE emailsubs.subrequests;

COMMIT;
