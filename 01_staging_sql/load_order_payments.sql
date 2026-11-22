USE olist;
GO

DROP TABLE IF EXISTS stg.order_payments;
CREATE TABLE stg.order_payments (
    order_id             NVARCHAR(100),
    payment_sequential   INT,
    payment_type         NVARCHAR(50),
    payment_installments INT,
    payment_value        DECIMAL (10,2)
);

BULK INSERT stg.order_payments
FROM 'C:\data\olist\olist_order_payments_dataset.csv'
WITH (
    FORMAT = 'CSV',          -- gère les guillemets et les virgules dans le texte
    FIRSTROW = 2,            -- saute la ligne d'en-tête
    CODEPAGE = '65001',      -- UTF-8, pour les accents portugais
    ROWTERMINATOR = '0x0a'
);

SELECT COUNT(*) FROM stg.order_payments;  -- attendu : 112 650