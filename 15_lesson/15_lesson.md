# ДЗ к 15 уроку

* Раскручиваем БД в докере и пробласывает файл для создания базы
* Входим в контейнер, создаем БД и заливаем данные из файла
  `createdb -U db_user -p 5432 demo`
  `psql -U db_user -p 5432 -d demo -f /root/demo.sql`
* Для секционирования остаемся на таблице bookings, берем по диапазону дат
* Делаем тестовый запрос
  `explain analyze select * from bookings where book_date::date = '2017-07-14';
                                                        QUERY PLAN                                                         
---------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..5162.12 rows=1314 width=21) (actual time=0.121..13.425 rows=5705 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   ->  Parallel Seq Scan on bookings  (cost=0.00..4030.72 rows=773 width=21) (actual time=0.010..10.211 rows=2852 loops=2)
         Filter: ((book_date)::date = '2017-07-14'::date)
         Rows Removed by Filter: 128542
 Planning Time: 0.075 ms
 Execution Time: 13.626 ms`

 * Создаем головную таблицу для секционирования
   `CREATE TABLE bookings.bookings_partitioned (
    book_ref character(6) NOT NULL,
    book_date timestamp with time zone NOT NULL,
    total_amount numeric(10,2) NOT NULL
) PARTITION BY RANGE (book_date);`
* Предварительно посмотрев крайние даты, делаем 3 таблицы для секционирования
`CREATE TABLE bookings.bookings_201706 PARTITION OF bookings.bookings_partitioned
    FOR VALUES FROM ('2017-06-01 00:00:00+00') TO ('2017-07-01 00:00:00+00');

CREATE TABLE bookings.bookings_201707 PARTITION OF bookings.bookings_partitioned
    FOR VALUES FROM ('2017-07-01 00:00:00+00') TO ('2017-08-01 00:00:00+00');

CREATE TABLE bookings.bookings_201708 PARTITION OF bookings.bookings_partitioned
    FOR VALUES FROM ('2017-08-01 00:00:00+00') TO ('2017-09-01 00:00:00+00');`

* Создаем индекс для первичного ключа
`CREATE UNIQUE INDEX bookings_partitioned_pkey ON bookings.bookings_partitioned (book_ref);`
* Создаем также дефолтную таблицу
  `CREATE TABLE bookings.bookings_default PARTITION OF bookings.bookings_partitioned
    DEFAULT;`
* Переносим данные
  `INSERT INTO bookings.bookings_partitioned 
SELECT * FROM bookings.bookings;`
* Проверим распределение
`SELECT 
    tableoid::regclass as partition,
    count(*) as row_count,
    min(book_date) as min_date,
    max(book_date) as max_date
FROM bookings.bookings_partitioned 
GROUP BY partition
ORDER BY min_date;
    partition    | row_count |        min_date        |        max_date        
-----------------+-----------+------------------------+------------------------
 bookings_201706 |      7730 | 2017-06-21 11:05:00+00 | 2017-06-30 23:59:00+00
 bookings_201707 |    167268 | 2017-07-01 00:00:00+00 | 2017-07-31 23:59:00+00
 bookings_201708 |     87790 | 2017-08-01 00:00:00+00 | 2017-08-15 15:00:00+00`

 * Переименуем таблицы и удалим старую
`ALTER TABLE bookings.tickets DROP CONSTRAINT tickets_book_ref_fkey;`
`ALTER TABLE bookings.bookings RENAME TO bookings_old;`
`ALTER TABLE bookings.bookings_partitioned RENAME TO bookings;`

* Создадим индексы для партиций
  `CREATE UNIQUE INDEX bookings_201706_book_ref_uidx ON bookings.bookings_201706 (book_ref);
CREATE UNIQUE INDEX bookings_201707_book_ref_uidx ON bookings.bookings_201707 (book_ref);
CREATE UNIQUE INDEX bookings_201708_book_ref_uidx ON bookings.bookings_201708 (book_ref);
CREATE UNIQUE INDEX bookings_default_book_ref_uidx ON bookings.bookings_default (book_ref);`
* Создаем индекс на основной таблице
  `CREATE UNIQUE INDEX bookings_book_ref_date_uidx ON bookings.bookings (book_ref, book_date);`

* Делаем запрос для оценки изменения производительности
  `explain analyze select * from bookings where book_date::date = '2017-07-14';
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..5148.36 rows=1319 width=21) (actual time=4.647..9.777 rows=5705 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Append  (cost=0.00..4016.46 rows=549 width=21) (actual time=2.250..6.446 rows=1902 loops=3)
         ->  Parallel Seq Scan on bookings_201707 bookings_2  (cost=0.00..2541.89 rows=492 width=21) (actual time=0.006..4.080 rows=1902 loops=3)
               Filter: ((book_date)::date = '2017-07-14'::date)
               Rows Removed by Filter: 53854
         ->  Parallel Seq Scan on bookings_201708 bookings_3  (cost=0.00..1334.62 rows=258 width=21) (actual time=3.100..3.100 rows=0 loops=2)
               Filter: ((book_date)::date = '2017-07-14'::date)
               Rows Removed by Filter: 43895
         ->  Parallel Seq Scan on bookings_201706 bookings_1  (cost=0.00..118.21 rows=23 width=21) (actual time=0.526..0.526 rows=0 loops=1)
               Filter: ((book_date)::date = '2017-07-14'::date)
               Rows Removed by Filter: 7730
         ->  Parallel Seq Scan on bookings_default bookings_4  (cost=0.00..19.00 rows=3 width=52) (actual time=0.002..0.002 rows=0 loops=1)
               Filter: ((book_date)::date = '2017-07-14'::date)
 Planning Time: 0.489 ms
 Execution Time: 9.990 ms`
* При запросе с правильным типом дат еще эффективнее
  `EXPLAIN ANALYZE SELECT * FROM bookings 
WHERE book_date >= '2017-07-14 00:00:00+00' 
  AND book_date < '2017-07-15 00:00:00+00';
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on bookings_201707 bookings  (cost=107.27..1259.58 rows=5754 width=21) (actual time=0.359..1.880 rows=5705 loops=1)
   Recheck Cond: ((book_date >= '2017-07-14 00:00:00+00'::timestamp with time zone) AND (book_date < '2017-07-15 00:00:00+00'::timestamp with time zone))
   Heap Blocks: exact=1062
   ->  Bitmap Index Scan on bookings_201707_book_date_idx  (cost=0.00..105.83 rows=5754 width=0) (actual time=0.254..0.254 rows=5705 loops=1)
         Index Cond: ((book_date >= '2017-07-14 00:00:00+00'::timestamp with time zone) AND (book_date < '2017-07-15 00:00:00+00'::timestamp with time zone))
 Planning Time: 0.143 ms
 Execution Time: 2.074 ms`