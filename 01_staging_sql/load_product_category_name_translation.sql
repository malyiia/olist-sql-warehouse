USE olist;
GO

DROP TABLE IF EXISTS stg.product_category_name_translation;
CREATE TABLE stg.product_category_name_translation (
    product_category_name            NVARCHAR(100),
    product_category_name_english    NVARCHAR(100)
);

BULK INSERT stg.product_category_name_translation
FROM 'C:\data\olist\product_category_name_translation.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    ROWTERMINATOR = '0x0d0a'
);

SELECT COUNT(*) FROM stg.product_category_name_translation;  -- attendu : 71