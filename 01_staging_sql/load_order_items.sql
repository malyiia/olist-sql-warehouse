USE olist;
GO

DROP TABLE IF EXISTS stg.order_items;
CREATE TABLE stg.order_items (
    order_id             NVARCHAR(100),
    order_item_id        INT,
    product_id           NVARCHAR(100),
    seller_id            NVARCHAR(100),
    shipping_limit_date  DATETIME,
    price                DECIMAL (6,2),
    freight_value        DECIMAL (5,2)
);

BULK INSERT stg.order_items
FROM 'C:\data\olist\olist_order_items_dataset.csv'
WITH (
    FORMAT = 'CSV',          -- gère les guillemets et les virgules dans le texte
    FIRSTROW = 2,            -- saute la ligne d'en-tête
    CODEPAGE = '65001',      -- UTF-8, pour les accents portugais
    ROWTERMINATOR = '0x0a'
);

SELECT COUNT(*) FROM stg.order_items;  -- attendu : 112 650