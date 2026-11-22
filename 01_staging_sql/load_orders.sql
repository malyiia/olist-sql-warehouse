USE olist;
GO

DROP TABLE IF EXISTS stg.orders;
CREATE TABLE stg.orders (
    order_id                        NVARCHAR(100),
    customer_id                     NVARCHAR(100),
    order_status                    NVARCHAR(100),
    order_purchase_timestamp        DATETIME,
    order_approved_at               DATETIME,
    order_delivered_carrier_date    DATETIME,
    order_delivered_customer_date   DATETIME,
    order_estimated_delivery_date   DATETIME
    );

BULK INSERT stg.orders
FROM 'C:\data\olist\olist_orders_dataset.csv'
WITH (
    FORMAT = 'CSV',          -- gère les guillemets et les virgules dans le texte
    FIRSTROW = 2,            -- saute la ligne d'en-tête
    CODEPAGE = '65001',      -- UTF-8, pour les accents portugais
    ROWTERMINATOR = '0x0a'
);

SELECT COUNT(*) FROM stg.orders;  -- attendu : 112 650