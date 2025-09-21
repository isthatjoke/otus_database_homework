# ДЗ к 8 уроку

* Поднимаем убунту в контейнере и заходим в него
* Устанавливаем постгрес 17 
* Меняем в файле конфигурации создание чекпоинтов каждые 30 секунд
  `checkpoint_timeout = 30s`
* Выполняем проверку lsn
  `select pg_current_wal_insert_lsn();
 pg_current_wal_insert_lsn 
---------------------------
 0/152DA30
(1 row)`
* Делаем тестовые данные
  `pgbench -i -s 50 -U postgres postgres`
* Запускаем нагрузочное тестирование смешанного цикла (чтение + запись) в течение 10 минут
  `pgbench -c 20 -j 4 -T 600 -P 10 -U postgres postgres`
* Снова измеряем lsn
  `pg_current_wal_insert_lsn 
---------------------------
 0/D5CC18F8
(1 row)`
* Измеряем разницу lsn
  `select '0/D5CC18F8'::pg_lsn - '0/152DA30'::pg_lsn;
  ?column?  
------------
 3564715720
(1 row)`
* Теперь можно посчитать, какой объем данных приходится на 1 контрольную точку
  `SELECT 
    '3,564,715,720 bytes'::text as total_wal,
    '600 seconds'::text as test_duration,
    '30 seconds'::text as checkpoint_interval,
    (3564715720 / (600 / 30)) as bytes_per_checkpoint,
    (3564715720 / (600 / 30)) / (1024 * 1024) as mb_per_checkpoint;
      total_wal      | test_duration | checkpoint_interval | bytes_per_checkpoint | mb_per_checkpoint 
---------------------+---------------+---------------------+----------------------+-------------------
 3,564,715,720 bytes | 600 seconds   | 30 seconds          |            178235786 |               169`

* Далее запрашиваем статистику чекпоинтера
  `SELECT * FROM pg_stat_checkpointer;
 num_timed | num_requested | restartpoints_timed | restartpoints_req | restartpoints_done | write_time | sync_time | buffers_written |          stats_reset
          
-----------+---------------+---------------------+-------------------+--------------------+------------+-----------+-----------------+---------------------
----------
       390 |             6 |                   0 |                 0 |                  0 |     763779 |    146803 |            7195 | 2025-09-20 09:09:43.
835214+03`

* Из статистики видно, что за 10 минут создалось 390 контрольных точек по рассписанию и 6 контрольных точек принудительно. скорее всего такое поведение из-за интенсивной записи pgbench и малого размера max_wal_size

* Выключаем синхронный коммит и начинаем тестирование
  `SET synchronous_commit TO off`
  `pgbench -c 10 -j 2 -T 60 postgres
pgbench (17.6 (Ubuntu 17.6-1.pgdg24.04+1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 50
query mode: simple
number of clients: 10
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 40313
number of failed transactions: 0 (0.000%)
latency average = 15.032 ms
initial connection time = 17.407 ms
tps = 665.261125 (without initial connection time)`
* Включаем синхронный режим и делаем то же самое
  `pgbench -c 10 -j 2 -T 60 postgres
pgbench (17.6 (Ubuntu 17.6-1.pgdg24.04+1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 50
query mode: simple
number of clients: 10
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 40240
number of failed transactions: 0 (0.000%)
latency average = 15.189 ms
initial connection time = 16.216 ms
tps = 658.353266 (without initial connection time)`
* Разнца совсем небольшая. но несинхронный режим опаснее, может повлечь потерю данных при сбое

* Создаем новый кластер с контрольными суммами
  `initdb -D /var/lib/postgresql/pgdata_test_checksum --data-checksums`
* Запускаем кластер на другом порту
  `pg_ctl -D /var/lib/postgresql/pgdata_test_checksum -o "-p 5433" start`
* Подключаем к новому кластеру
  `psql -p 5433`
* Создаем таблицу и записываем немного данных
  `CREATE TABLE test_checksum(id INT, name TEXT);
INSERT INTO test_checksum VALUES (1, 'Вася'), (2, 'Петя'), (3, 'Саша');`
* Находим wal файл таблицы
  `psql -p 5433 -c "SELECT pg_relation_filepath('test_checksum');"
 pg_relation_filepath 
----------------------
 base/5/16388`
* Останавливаем кластер
  `pg_ctl -D /var/lib/postgresql/pgdata_test_checksum stop`
* Устанавливаем hexedit, открывае файл и правим пару битов
  `hexedit /var/lib/postgresql/pgdata_test_checksum/base/5/16388`
* Запускаем кластер
  `pg_ctl -D /var/lib/postgresql/pgdata_test_checksum -o "-p 5433" start`
* Заходим в psql, пытаемся сделать выборку и получаем ошибку
  `SELECT * FROM test_checksum;
2025-09-21 18:32:16.200 MSK [11991] WARNING:  page verification failed, calculated checksum 22910 but expected 27947
2025-09-21 18:32:16.200 MSK [11991] ERROR:  invalid page in block 0 of relation base/5/16388
2025-09-21 18:32:16.200 MSK [11991] STATEMENT:  SELECT * FROM test_checksum;
WARNING:  page verification failed, calculated checksum 22910 but expected 27947
ERROR:  invalid page in block 0 of relation base/5/16388`
* Далее 3 пути - удалять таблицу и делать заново, либо из бэкапа восстанавливать, либо пытаться через расширение инспекции страниц вытащить живые данные
