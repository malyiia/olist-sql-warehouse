USE olist;
GO

DROP TABLE IF EXISTS stg.geolocation;
CREATE TABLE stg.geolocation (
    geolocation_zip_code_prefix  NVARCHAR(50),
    geolocation_lat              DECIMAL (18,15),
    geolocation_lng              DECIMAL (18,15),
    geolocation_city             NVARCHAR(100),
    geolocation_state           NVARCHAR(100)
);

BULK INSERT stg.geolocation
FROM 'C:\data\olist\olist_geolocation_dataset.csv'
WITH (
    FORMAT = 'CSV',          -- gère les guillemets et les virgules dans le texte
    FIRSTROW = 2,            -- saute la ligne d'en-tête
    CODEPAGE = '65001',      -- UTF-8, pour les accents portugais
    ROWTERMINATOR = '0x0a'
);

SELECT COUNT(*) FROM stg.geolocation;  -- attendu : 1 000 163