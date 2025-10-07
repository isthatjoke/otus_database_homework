# ДЗ к 18 уроку

* Разворачиваем БД в докере
* Входим в контейнер и накатывает команды из файла hw_triggers.sql
* Создадим дополнительное ограничение на имя товара для таблицы good_sum_mart, чтобы можно было реализовать простым путем функцию по первичному насыщению таблицы. К тому же быстрее будет брать данные из таблицы по имени товара, так как будет создан индекс
  `ALTER TABLE good_sum_mart ADD CONSTRAINT unique_good_name UNIQUE (good_name);`
* Далее создадим функцию первичного насыщения с проверкой на уже существующие в ней товары. В случае конфликта, будет производить пересчет суммы для данного товара
  ```sql
  CREATE OR REPLACE FUNCTION begin_add_good_sum_mart()
    RETURNS void
    AS
    $BODY$
      BEGIN

        INSERT INTO good_sum_mart (good_name, sum_sale)
          SELECT G.good_name, sum(G.good_price * S.sales_qty)
          FROM goods G
          INNER JOIN sales S ON S.good_id = G.goods_id
          GROUP BY G.good_name
          ON CONFLICT (good_name) 
          DO UPDATE SET sum_sale = EXCLUDED.sum_sale;
      END;
    $BODY$
  LANGUAGE plpgsql;
```

* Создаем триггерную функцию и триггер пересчета суммы (вообще это неправильно для состоявшихся продаж, но в нашем варианте пусть будет, чисто тренеровка) в good_sum_mart, если стоимость товара изменилась. Можно использовать и begin_add_good_sum_mart, но она смотрит по всем, а лучше сделать только по нужному товару. В функцию добавил защиту от NULL и также защиту от вставки значения с 0 (только при условии срабатывания защиты по NULL выше, грубо говоря), если такого айди товара не найдется в таблице продаж. Можно было бы попробовать сделать с left join, но оставим, как есть

```sql
  CREATE OR REPLACE FUNCTION tf_price_changed()
  RETURNS TRIGGER
  AS
  $BODY$
    BEGIN

      IF NEW.good_price <> OLD.good_price THEN
        UPDATE good_sum_mart
        SET sum_sale = (
            SELECT COALESCE(sum(G.good_price * S.sales_qty),0)
            FROM goods G
            INNER JOIN sales S 
            ON S.good_id = G.goods_id 
            WHERE G.goods_id = NEW.goods_id)
        WHERE good_name = NEW.good_name 
        AND EXISTS (SELECT 1 FROM sales WHERE good_id = NEW.goods_id);
      END IF;
      RETURN NEW;
    END;
  $BODY$
  LANGUAGE plpgsql;
```

```sql
CREATE TRIGGER tr_price_changed
AFTER UPDATE
ON goods
FOR EACH ROW
EXECUTE FUNCTION tf_price_changed();
```

* Создаем для условия изменения названия
  
```sql
CREATE OR REPLACE FUNCTION tf_name_changed()
RETURNS TRIGGER
AS
$BODY$
BEGIN
    UPDATE good_sum_mart
    SET good_name = NEW.good_name
    WHERE good_name = OLD.good_name;
    RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;
```

```sql
CREATE TRIGGER tr_name_changed
AFTER UPDATE
ON goods
FOR EACH ROW
EXECUTE FUNCTION tf_name_changed();
```

* Создаем триггер на добавление данных в таблицу продаж
  
```sql
CREATE OR REPLACE FUNCTION tf_sale_added()
  RETURNS TRIGGER
  AS
  $BODY$
  BEGIN
    INSERT INTO good_sum_mart (good_name, sum_sale)
    SELECT 
        G.good_name,
        G.good_price * NEW.sales_qty
    FROM goods G
    WHERE G.goods_id = NEW.good_id
    ON CONFLICT (good_name)
    DO UPDATE SET sum_sale = good_sum_mart.sum_sale + EXCLUDED.sum_sale;
    RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;
```

```sql
CREATE TRIGGER tr_sale_added
AFTER INSERT
ON sales
FOR EACH ROW
EXECUTE FUNCTION tf_sale_added();
```

* Триггер и функция на удаление продажи сделаем (вдруг произошел возврат или отмена продажи). На удаление товара делать не будем, странно, если удалим исторические продажи, когда перестали продавать товар
  
```sql
CREATE OR REPLACE FUNCTION tf_sale_canceled()
  RETURNS TRIGGER
  AS
  $BODY$
  BEGIN
    UPDATE good_sum_mart 
    SET sum_sale = sum_sale - (SELECT
                        G.good_price * OLD.sales_qty
                        FROM goods G
                        WHERE G.goods_id = OLD.good_id)
    WHERE good_name = (
        SELECT G.good_name
        FROM goods G
        WHERE G.goods_id = OLD.good_id
    );
    RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql;
```

```sql
CREATE TRIGGER tr_sale_canceled
AFTER DELETE
ON sales
FOR EACH ROW
EXECUTE FUNCTION tf_sale_canceled();
```

* Схема витрина+триггер предпочтительнее отчета по требованию - можно сохранить исторические данные по продажам при изменении цены
* Сделаем триггеры и функции для условия, если нет ограничения по уникальности имена в таблице good_sum_mart;
* Удалим требование
  `ALTER TABLE good_sum_mart DROP CONSTRAINT unique_good_name;`
* Прошлые триггеры удалили, названия можно переиспользовать
* Триггер на добавление записи в good_sum_mart;
  
  ```sql
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
  ```

```sql
CREATE TRIGGER tr_sale_added
AFTER INSERT
ON sales
FOR EACH ROW
EXECUTE FUNCTION tf_sale_added();
```

* Удаление продажи
  
```sql
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
```

```sql
CREATE TRIGGER tr_sale_canceled
AFTER DELETE
ON sales
FOR EACH ROW
EXECUTE FUNCTION tf_sale_canceled();
```


* Функция для первичного насыщения таблицы в условиях одинаковых имен товаров
  
```sql
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
```

* Триггер + функция при изменении продажи
  
```sql  
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
```

```sql
CREATE TRIGGER tr_sale_update
AFTER UPDATE
ON sales
FOR EACH ROW
EXECUTE FUNCTION tf_sale_update();
```
