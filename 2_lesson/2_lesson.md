
# ДЗ для 2 урока  

- БД была развернута в docker compose вместе с pgAdmin на Ubuntu  

- Создаем таблицу:  
  
  `create table if not exists persons (
  id serial,
  first_name varchar,
  last_name varchar
  );`

- Начинаем наполнение БД через транзакцию с ручным комитом  
begin;
insert into persons(first_name, last_name) values('timur', 'zverev');
insert into persons(first_name, last_name) values('petr', 'abalmasov');
commit;

- Смотрим уровень изоляции  
  `show transaction isolation level`
  * read committed
# isolation level read commited
- Не меняя уровень изоляции, создаем транзакцию в 1 сессии и делаем новую запись в БД
  `begin;
  insert into persons(first_name, last_name) values('andrey', 'kuzin');`

- Во второй сессии новой записи не видно, потому что стоит уровень изоляции read commited, а значит в другой сессии или под другим пользователем можно прочитать только закоммиченные записи.

- Завершил 1ю транзакцию командой commit
- Сделал повторно во второй сесии 
  `select * from persons;`
- Новую запись стало видно - причину такого поведения указал выше - в другой сессии или под другим пользователем можно прочитать только закоммиченные записи

# isolation level repeatable read

- Создаем транзацию с указанием уровня изоляции repeatable read
  `begin isolation level repeatable read;
insert into persons(first_name, last_name) values('georg', 'dobryakov');`
- Во второй сессии делаем 2 команды
  `begin isolation level repeatable read;`
  `select * from persons;`
- Новых значений не показывает.
- После коммита в первой сессии, во второй сессии новое значение не появилось
- После коммита во второй сессии, новое значение появилось
- Такое поведение происходит из-за уровня изоляции. Пока действует repeatable read, другая сессия видит только записи, которые были при активации уровня изоляции - как будто создается некое временное окружение


