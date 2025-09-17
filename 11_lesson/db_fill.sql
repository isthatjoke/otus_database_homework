-- Заполняем таблицу product_types
INSERT INTO product_types(id, type_name) VALUES(1, 'Онлайн-курс');
INSERT INTO product_types(id, type_name) VALUES(2, 'Вебинар');
INSERT INTO product_types(id, type_name) VALUES(3, 'Книга');
INSERT INTO product_types(id, type_name) VALUES(4, 'Консультация');

-- Заполняем таблицу products
INSERT INTO products(id, name, type_id, price) VALUES(1, 'Основы искусственного интеллекта', 1, 15000);
INSERT INTO products(id, name, type_id, price) VALUES(2, 'Технологии обработки больших данных', 1, 50000);
INSERT INTO products(id, name, type_id, price) VALUES(3, 'Программирование глубоких нейронных сетей', 1, 30000);
INSERT INTO products(id, name, type_id, price) VALUES(4, 'Нейронные сети для анализа текстов', 1, 50000);
INSERT INTO products(id, name, type_id, price) VALUES(5, 'Нейронные сети для анализа изображений', 1, 50000);
INSERT INTO products(id, name, type_id, price) VALUES(6, 'Инженерия искусственного интеллекта', 1, 60000);
INSERT INTO products(id, name, type_id, price) VALUES(7, 'Как стать DataScientist''ом', 2, 0);
INSERT INTO products(id, name, type_id, price) VALUES(8, 'Планирование карьеры в DataScience', 2, 2000);
INSERT INTO products(id, name, type_id, price) VALUES(9, 'Области применения нейросетей: в какой развивать экспертность', 2, 4000);
INSERT INTO products(id, name, type_id, price) VALUES(10, 'Программирование глубоких нейронных сетей на Python', 3, 1000);
INSERT INTO products(id, name, type_id, price) VALUES(11, 'Математика для DataScience', 3, 2000);
INSERT INTO products(id, name, type_id, price) VALUES(12, 'Основы визуализации данных', 3, 500);
INSERT INTO products(id, name, price) VALUES(13, 'Анализ временных рядов', 30000);

-- Заполняем таблицу customers
INSERT INTO customers(id, name, email) VALUES(1, 'Иван Петров', 'petrov@mail.ru');
INSERT INTO customers(id, name, email) VALUES(2, 'Петр Иванов', 'ivanov@gmail.com');
INSERT INTO customers(id, name, email) VALUES(3, 'Тимофей Сергеев', 'ts@gmail.com');
INSERT INTO customers(id, name, email) VALUES(4, 'Даша Корнеева', 'dasha.korneeva@mail.ru');
INSERT INTO customers(id, name, email) VALUES(5, 'Иван Иван', 'petrov@mail.ru');
INSERT INTO customers(id, name, email) VALUES(6, 'Сергей Щербаков', 'user156@yandex.ru');
INSERT INTO customers(id, name, email) VALUES(7, 'Катя Самарина', 'kate@mail.ru');
INSERT INTO customers(id, name, email) VALUES(8, 'Андрей Котов', 'a.kotoff@yandex.ru');

-- Заполняем таблицу orders
INSERT INTO orders(id, order_date, customer_id) VALUES(1, '2021-01-11', 1);
INSERT INTO orders(id, order_date, customer_id) VALUES(2, '2021-01-15', 3);
INSERT INTO orders(id, order_date, customer_id) VALUES(3, '2021-01-20', 4);
INSERT INTO orders(id, order_date, customer_id) VALUES(4, '2021-01-12', 2);
INSERT INTO orders(id, order_date, customer_id) VALUES(5, '2021-01-25', 8);
INSERT INTO orders(id, order_date, customer_id) VALUES(6, '2021-01-30', 1);

-- Заполняем таблицу sales
INSERT INTO sales(product_id, order_id, quantity) VALUES(3, 1, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(4, 6, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(10, 2, 2);
INSERT INTO sales(product_id, order_id, quantity) VALUES(11, 2, 2);
INSERT INTO sales(product_id, order_id, quantity) VALUES(3, 3, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(4, 3, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(5, 3, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(1, 4, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(6, 5, 1);