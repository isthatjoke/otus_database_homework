# ДЗ к 11 уроку

* Поднимаем постгрес в контейнере
* Подключаемся к контейнеру и заходим в psql
* Делаем таблицы и наполняем БД (файлы structure и db_fill)
* Делаем прямое соединение - получаем покупателей и их заказы
  `SELECT c.name AS customer_name, o.order_date
   FROM customers c
   INNER JOIN orders o ON c.id = o.customer_id;`
* Делаем левостороннее соединение - получаем всех покупателей и их заказы (если есть)
  `SELECT c.name AS customer_name, o.order_date
   FROM customers c
   LEFT JOIN orders o ON c.id = o.customer_id
   ORDER BY c.name;`
* Делаем кросс соединение - поулчаем все возможные комбинации типов продуктов и покупателей
  `SELECT pt.type_name, c.name AS customer_name
   FROM product_types pt
   CROSS JOIN customers c
   ORDER BY pt.type_name, c.name;`
* Делаем полное соединение - получаем все продукты и все заказы с их связями
  `SELECT p.name AS product_name, o.order_date, s.quantity
    FROM products p
    FULL OUTER JOIN sales s ON p.id = s.product_id
    FULL OUTER JOIN orders o ON s.order_id = o.id
    ORDER BY p.name;`
* Комбинированный запрос с разными типами соединений - получаем детальную информация о продажах с разными типами соединений
  `SELECT 
    c.name AS customer_name,
    c.email,
    o.order_date,
    p.name AS product_name,
    pt.type_name AS product_type,
    p.price,
    s.quantity,
    (p.price * s.quantity) AS total_amount
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
LEFT JOIN sales s ON o.id = s.order_id
LEFT JOIN products p ON s.product_id = p.id
LEFT JOIN product_types pt ON p.type_id = pt.id
ORDER BY c.name, o.order_date;`