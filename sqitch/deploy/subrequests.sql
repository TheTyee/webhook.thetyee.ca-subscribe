-- Deploy emailsubs:subrequests to pg
-- requires: appschema

BEGIN;

SET client_min_messages = 'warning';
 
CREATE TABLE emailsubs.subrequests (
    id          SERIAL PRIMARY KEY NOT NULL UNIQUE,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    email     TEXT        NULL,
    campaign  TEXT        NULL,
    daily     TEXT        NULL,
    weekly    TEXT        NULL,
    national  TEXT        NULL
);

COMMIT;
