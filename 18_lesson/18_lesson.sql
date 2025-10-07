CREATE TABLE goods
(
    goods_id    integer PRIMARY KEY,
    good_name   varchar(63) NOT NULL,
    good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0)
);
INSERT INTO goods (goods_id, good_name, good_price)
VALUES 	(1, 'Спички хозайственные', .50),
		(2, 'Автомобиль Ferrari FXX K', 185000000.01);

-- Продажи
CREATE TABLE sales
(
    sales_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    good_id     integer REFERENCES goods (goods_id),
    sales_time  timestamp with time zone DEFAULT now(),
    sales_qty   integer CHECK (sales_qty > 0)
);

INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);

-- отчет:
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;

-- с увеличением объёма данных отчет стал создаваться медленно
-- Принято решение денормализовать БД, создать таблицу
CREATE TABLE good_sum_mart
(
	good_name   varchar(63) NOT NULL,
	sum_sale	numeric(16, 2)NOT NULL
);

-- Функция для первичного насыщения таблицы в условиях одинаковых имен товаров
CREATE OR REPLACE FUNCTION begin_update_good_sum_mart()
RETURNS void
AS
$BODY$
BEGIN
    INSERT INTO good_sum_mart (good_name, sum_sale)
    SELECT G.good_name, (G.good_price * S.sales_qty)
    FROM goods G
    INNER JOIN sales S ON S.good_id = G.goods_id;
END;
$BODY$
LANGUAGE plpgsql;

-- запускаем функцию
SELECT begin_update_good_sum_mart();

-- проверяем, что в таблице
SELECT begin_update_good_sum_mart();

-- Триггер + функция при изменении продажи
CREATE OR REPLACE FUNCTION tf_sale_update()
  RETURNS TRIGGER
  AS
  $BODY$
  DECLARE
  v_new_sale_amount NUMERIC(16,2);
  v_good_name VARCHAR(63);
  v_old_sale_amount NUMERIC(16,2);

  BEGIN

  SELECT G.good_price * OLD.sales_qty
    INTO v_old_sale_amount
    FROM goods G
    WHERE G.goods_id = OLD.good_id;

  SELECT G.good_name, G.good_price * NEW.sales_qty
    INTO v_good_name, v_new_sale_amount
    FROM goods G
    WHERE G.goods_id = NEW.good_id;

  UPDATE good_sum_mart
    SET sum_sale = v_new_sale_amount
    WHERE good_name = v_good_name
    AND sum_sale = v_old_sale_amount;

    RETURN NEW;
  END;
  $BODY$
  LANGUAGE plpgsql;

-- Триггер + функция при удалении продажи
CREATE OR REPLACE FUNCTION tf_sale_canceled()
  RETURNS TRIGGER
  AS
  $BODY$
  DECLARE
    v_old_good_name VARCHAR(63);
    v_old_sale_amount NUMERIC(16,2);

  BEGIN

    SELECT G.good_name, G.good_price * OLD.sales_qty
      INTO v_old_good_name, v_old_sale_amount
      FROM goods G
      WHERE G.goods_id = OLD.good_id;

    DELETE FROM good_sum_mart
      WHERE good_name = v_old_good_name
      AND sum_sale = v_old_sale_amount;

    RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER tr_sale_canceled
AFTER DELETE
ON sales
FOR EACH ROW
EXECUTE FUNCTION tf_sale_canceled();


-- Триггер + функция при новой продаже
CREATE OR REPLACE FUNCTION tf_sale_added()
  RETURNS TRIGGER
  AS
  $BODY$
  DECLARE
    v_good_name VARCHAR(63);
    v_sale_amount NUMERIC(16,2);
  
  BEGIN

    SELECT G.good_name, G.good_price * NEW.sales_qty
      INTO v_good_name, v_sale_amount
      FROM goods G
      WHERE G.goods_id = NEW.good_id;


    INSERT INTO good_sum_mart (good_name, sum_sale)
    VALUES (v_good_name, v_sale_amount);
    
    
    RETURN NEW;
  END;
  $BODY$
  LANGUAGE plpgsql;


CREATE TRIGGER tr_sale_added
AFTER INSERT
ON sales
FOR EACH ROW
EXECUTE FUNCTION tf_sale_added();



-- Проверки
INSERT INTO sales (good_id, sales_qty) VALUES (1, 70);
UPDATE sales SET sales_qty = 69 WHERE sales_id = 5;
DELETE FROM sales WHERE sales_id = 5;
