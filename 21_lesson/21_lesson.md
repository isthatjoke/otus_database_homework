# ДЗ к 21 уроку

- Создаем докер компоуз с 3 БД
- заходим на первую и создаем таблицы
  `sudo docker compose exec -it postgres1 psql -U postgres`
```sql
CREATE TABLE test (
    id SERIAL PRIMARY KEY,
    rows VARCHAR(50)
);

CREATE TABLE test2 (
    id SERIAL PRIMARY KEY,
    rows VARCHAR(50)
);
```
- включаем логическую репликацию и перезагружаем конфиг
  ```sql
  ALTER SYSTEM SET wal_level = logical;
  ALTER SYSTEM SET max_replication_slots = 10;
  ALTER SYSTEM SET max_wal_senders = 10;
  SELECT pg_reload_conf();
  ```

- создаем публикацию таблицы test
  `CREATE PUBLICATION pub_test_vm1 FOR TABLE test;`

- создаем пользователя для репликации и накидываем права
  ```sql
  CREATE USER rpl_user WITH REPLICATION LOGIN PASSWORD 'rpl_pwd';
  GRANT USAGE ON SCHEMA public TO rpl_user;
  GRANT SELECT ON test TO rpl_user;
  GRANT SELECT ON test2 TO rpl_user;
  ```

- на 2й ВМ делаем таблицы
```sql
CREATE TABLE test (
    id SERIAL PRIMARY KEY,
    rows VARCHAR(50)
);
CREATE TABLE test2 (
    id SERIAL PRIMARY KEY,
    rows VARCHAR(50)
);
```

- также включаем логическую репликацию и перезагружаем конфиг
```sql
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_replication_slots = 10;
ALTER SYSTEM SET max_wal_senders = 10;
SELECT pg_reload_conf();
```

- создаем публикацию таблицы test2
`CREATE PUBLICATION pub_test_vm2 FOR TABLE test2;`

- создаем пользователя для репликации и накидываем права
  ```sql
  CREATE USER rpl_user WITH REPLICATION LOGIN PASSWORD 'rpl_pwd';
  GRANT USAGE ON SCHEMA public TO rpl_user;
  GRANT SELECT ON test TO rpl_user;
  GRANT SELECT ON test2 TO rpl_user;
  ```
- подписываемся на публикацию с 1й ВМ
```sql
CREATE SUBSCRIPTION sub_test_from_vm1
CONNECTION 'host=postgres1 port=5432 user=rpl_user dbname=postgres password=rpl_pwd'
PUBLICATION pub_test_vm1;
```

- заходим снова на 1 ВМ и подписываемся на 2ю ВМ
```sql
CREATE SUBSCRIPTION sub_test_from_vm2
CONNECTION 'host=postgres2 port=5432 user=rpl_user dbname=postgres password=rpl_pwd'
PUBLICATION pub_test_vm2;
```

- теперь на 3 ВМ подписываемся на обе публикаци (с 1 и 2 ВМ)
```sql
CREATE TABLE test (
    id SERIAL PRIMARY KEY,
    rows VARCHAR(50)
);
CREATE TABLE test2 (
    id SERIAL PRIMARY KEY,
    rows VARCHAR(50)
);
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_replication_slots = 10;
ALTER SYSTEM SET max_wal_senders = 10;
SELECT pg_reload_conf();
CREATE USER rpl_user WITH REPLICATION LOGIN PASSWORD 'rpl_pwd';
GRANT USAGE ON SCHEMA public TO rpl_user;

CREATE SUBSCRIPTION sub_test_from_vm3
CONNECTION 'host=postgres1 port=5432 user=rpl_user dbname=postgres password=rpl_pwd'
PUBLICATION pub_test_vm1;

CREATE SUBSCRIPTION sub_test2_from_vm3
CONNECTION 'host=postgres2 port=5432 user=rpl_user dbname=postgres password=rpl_pwd'
PUBLICATION pub_test_vm2;

```

- на 1 ВМ вносим значение в таблицу test
  `insert into test values (1, 'test1');`

- на 2 ВМ проверяем в таблице test и записываем в таблицу test2
  `select * from test;`
  `insert into test2 values (1, 'test2');`

- на 1 машине проверяем таблицу test2
  `select * from test2;`

- на 3 машине проверяем обе таблицы
```sql
select * from test;
select * from test2;
```