# ДЗ к 13 уроку

* Раскручиваем постгрес в контейнере, прокинув файл тестовой ДБ
* Входим в контейнер, создаем БД и заливаем данные из файла
  `createdb -U db_user -p 5432 demo`
  `psql -U db_user -p 5432 -d demo -f /root/demo.sql`
* Заходим в БД и делаем индекс
  `psql -U db_user -d demo`
  `create index on tickets(book_ref);`
* Общий запрос дает вывод, что индекс не используется
  `explain (costs, verbose, analyze)
select * from bookings as bkg inner join tickets as tct on bkg.book_ref = tct.book_ref;
                                                                  QUERY PLAN                                                                  
----------------------------------------------------------------------------------------------------------------------------------------------
 Hash Join  (cost=9164.73..32972.75 rows=366733 width=125) (actual time=56.323..372.677 rows=366733 loops=1)
   Output: bkg.book_ref, bkg.book_date, bkg.total_amount, tct.ticket_no, tct.book_ref, tct.passenger_id, tct.passenger_name, tct.contact_data
   Inner Unique: true
   Hash Cond: (tct.book_ref = bkg.book_ref)
   ->  Seq Scan on bookings.tickets tct  (cost=0.00..9843.33 rows=366733 width=104) (actual time=0.052..31.803 rows=366733 loops=1)
         Output: tct.ticket_no, tct.book_ref, tct.passenger_id, tct.passenger_name, tct.contact_data
   ->  Hash  (cost=4339.88..4339.88 rows=262788 width=21) (actual time=55.874..55.875 rows=262788 loops=1)
         Output: bkg.book_ref, bkg.book_date, bkg.total_amount
         Buckets: 131072  Batches: 4  Memory Usage: 4538kB
         ->  Seq Scan on bookings.bookings bkg  (cost=0.00..4339.88 rows=262788 width=21) (actual time=0.006..14.509 rows=262788 loops=1)
               Output: bkg.book_ref, bkg.book_date, bkg.total_amount
 Planning Time: 0.269 ms
 Execution Time: 382.994 ms`

 * Меняем запрос на тергетированный и получаем вывод с использованием индекса
  `EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM bookings bkg 
INNER JOIN tickets tct ON bkg.book_ref = tct.book_ref
WHERE tct.book_ref = 'ABC123';
                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.84..20.92 rows=2 width=125) (actual time=0.075..0.076 rows=0 loops=1)
   Buffers: shared hit=1 read=2
   ->  Index Scan using bookings_pkey on bookings bkg  (cost=0.42..8.44 rows=1 width=21) (actual time=0.075..0.075 rows=0 loops=1)
         Index Cond: (book_ref = 'ABC123'::bpchar)
         Buffers: shared hit=1 read=2
   ->  Index Scan using tickets_book_ref_idx on tickets tct  (cost=0.42..12.46 rows=2 width=104) (never executed)
         Index Cond: (book_ref = 'ABC123'::bpchar)
 Planning Time: 0.138 ms
 Execution Time: 0.101 ms`

 * Сделаем индекс для полнотекстового поиска для таблицы airports_data
  `CREATE INDEX airports_data_city_ru_fts_idx ON bookings.airports_data 
    USING gin (to_tsvector('russian', city->>'ru'));`
* Вывод говорит об использовании индекса
  `EXPLAIN (ANALYZE)
SELECT airport_code, airport_name->>'ru' as name_ru
FROM bookings.airports_data 
WHERE to_tsvector('russian', city->>'ru') @@ to_tsquery('russian', 'Москва');
                                                              QUERY PLAN                                                              
--------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on airports_data  (cost=8.54..12.81 rows=1 width=36) (actual time=0.020..0.021 rows=3 loops=1)
   Recheck Cond: (to_tsvector('russian'::regconfig, (city ->> 'ru'::text)) @@ '''москв'''::tsquery)
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on airports_data_city_ru_fts_idx  (cost=0.00..8.54 rows=1 width=0) (actual time=0.009..0.009 rows=3 loops=1)
         Index Cond: (to_tsvector('russian'::regconfig, (city ->> 'ru'::text)) @@ '''москв'''::tsquery)
 Planning Time: 0.270 ms
 Execution Time: 0.050 ms`

* Создаем индекс на часть таблицы
  `CREATE INDEX flights_cancelled_idx ON bookings.flights 
USING btree (scheduled_departure)
WHERE status = 'Cancelled';`
* Вывод запроса указывает на использование индекса
 `EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM bookings.flights 
WHERE status = 'Cancelled';
                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on flights  (cost=10.25..421.59 rows=400 width=63) (actual time=0.083..0.401 rows=414 loops=1)
   Recheck Cond: ((status)::text = 'Cancelled'::text)
   Heap Blocks: exact=271
   Buffers: shared hit=272
   ->  Bitmap Index Scan on flights_cancelled_idx  (cost=0.00..10.15 rows=400 width=0) (actual time=0.048..0.049 rows=414 loops=1)
         Buffers: shared hit=1
 Planning Time: 0.130 ms
 Execution Time: 0.442 ms`

 * Создаем индекс на несколько полей
 `CREATE INDEX flights_route_departure_idx ON bookings.flights 
USING btree (departure_airport, arrival_airport, scheduled_departure);`
* Вывод говорит об использовании индекса при запросе
  `EXPLAIN (ANALYZE, BUFFERS)
SELECT flight_no, scheduled_departure, status
FROM bookings.flights 
WHERE departure_airport = 'LED' 
AND arrival_airport = 'SVO'
AND scheduled_departure BETWEEN '2024-12-01' AND '2024-12-31'
ORDER BY scheduled_departure;`
` Index Scan using flights_route_departure_idx on flights  (cost=0.29..8.31 rows=1 width=23) (actual time=0.031..0.031 rows=0 loops=1)
   Index Cond: ((departure_airport = 'LED'::bpchar) AND (arrival_airport = 'SVO'::bpchar) AND (scheduled_departure >= '2024-12-01 00:00:00+00'::timestamp with time zone) AND (scheduled_departure <= '2024-12-31 00:00:00+00'::timestamp with time zone))
   Buffers: shared hit=2
 Planning Time: 0.135 ms
 Execution Time: 0.050 ms`


 * При некоторых запросах вместо поиска по индексу получался seqscan. Пришлось отключать его Set enable_seqscan = off