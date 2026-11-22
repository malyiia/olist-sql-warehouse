USE olist;
GO

DROP TABLE IF EXISTS stg.sellers;
CREATE TABLE stg.sellers (
    seller_id                   NVARCHAR(100),
    seller_zip_code_prefix      INT,
    seller_city                 NVARCHAR(100),
    seller_state                NVARCHAR(10)
);

BULK INSERT stg.sellers
FROM 'C:\data\olist\olist_sellers_dataset.csv'
WITH (
    FORMAT = 'CSV',          -- gère les guillemets et les virgules dans le texte
    FIRSTROW = 2,            -- saute la ligne d'en-tête
    CODEPAGE = '65001',      -- UTF-8, pour les accents portugais
    ROWTERMINATOR = '0x0a'
);

SELECT COUNT(*) FROM stg.sellers;  -- attendu : 303 847