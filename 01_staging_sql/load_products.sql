USE olist;
GO

DROP TABLE IF EXISTS stg.products;
CREATE TABLE stg.products (
    product_id                  NVARCHAR(100),
    product_category_name       NVARCHAR(100),
    product_name_length         INT,
    product_description_length  INT,
    product_phtos_qty           INT,
    product_weight_g            INT,
    product_length_cm           INT,
    product_height_cm           INT,
    product_width_cm            INT
);

BULK INSERT stg.products
FROM 'C:\data\olist\olist_products_dataset.csv'
WITH (
    FORMAT = 'CSV',          -- gère les guillemets et les virgules dans le texte
    FIRSTROW = 2,            -- saute la ligne d'en-tête
    CODEPAGE = '65001',      -- UTF-8, pour les accents portugais
    ROWTERMINATOR = '0x0a'
);

SELECT COUNT(*) FROM stg.products;  -- attendu : 112 650