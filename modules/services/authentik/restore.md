# Restoring Backup

Backup location on the server: /tmp/authentik.sql.gz

```bash
sudo systemctl stop authentik.service
sudo systemctl stop authentik-worker.service
sudo systemctl stop authentik-migrate.service
```

```bash
sudo -u postgres psql -d postgres -c "DROP DATABASE authentik;"
sudo systemctl restart postgresql
sudo -u postgres bash -lc 'gunzip -c /tmp/authentik.sql.gz | psql -v ON_ERROR_STOP=1 -d authentik'
sudo -u postgres psql -d postgres -c "ALTER DATABASE authentik OWNER TO authentik;"
```

```bash
sudo -u postgres psql -d authentik <<'SQL'
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT n.nspname, c.relname, c.relkind
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relowner = (SELECT oid FROM pg_roles WHERE rolname='postgres')
      AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
      AND n.nspname NOT LIKE 'pg_temp_%'
      AND n.nspname NOT LIKE 'pg_toast_temp_%'
      AND c.relkind IN ('r','p','v','m','f')  -- table, partitioned table, view, matview, foreign table
  LOOP
    EXECUTE format(
      'ALTER %s %I.%I OWNER TO authentik;',
      CASE r.relkind
        WHEN 'v' THEN 'VIEW'
        WHEN 'm' THEN 'MATERIALIZED VIEW'
        ELSE 'TABLE'
      END,
      r.nspname, r.relname
    );
  END LOOP;
END $$;
SQL
```

```bash
sudo -u postgres psql -d authentik <<'SQL'
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT n.nspname, c.relname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'S'
      AND c.relowner = (SELECT oid FROM pg_roles WHERE rolname='postgres')
      AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
      AND NOT EXISTS (
        SELECT 1
        FROM pg_depend d
        WHERE d.objid = c.oid
          AND d.deptype IN ('a','i')  -- auto/internal deps = owned-by/identity-style
      )
  LOOP
    EXECUTE format('ALTER SEQUENCE %I.%I OWNER TO authentik;', r.nspname, r.relname);
  END LOOP;
END $$;
SQL
```

```bash
sudo -u postgres psql -d authentik <<'SQL'
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proowner = (SELECT oid FROM pg_roles WHERE rolname='postgres')
      AND n.nspname NOT IN ('pg_catalog','information_schema')
      AND n.nspname NOT LIKE 'pg_toast%'
      AND n.nspname NOT LIKE 'pg_temp_%'
  LOOP
    EXECUTE format('ALTER FUNCTION %I.%I(%s) OWNER TO authentik;', r.nspname, r.proname, r.args);
  END LOOP;
END $$;
SQL
```

```bash
sudo systemctl start authentik.service
```
