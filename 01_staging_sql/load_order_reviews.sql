USE olist;
GO

DROP TABLE IF EXISTS stg.order_reviews;
CREATE TABLE stg.order_reviews (
    review_id               NVARCHAR(100),
    order_id                NVARCHAR(100),
    review_score            INT,
    review_comment_title    NVARCHAR(100),
    review_comment_message  NVARCHAR(250),
    review_creation_date    DATETIME,
    review_answer_timestamp DATETIME
    );

BULK INSERT stg.order_reviews
FROM 'C:\data\olist\olist_order_reviews_dataset.csv'
WITH (
    FORMAT = 'CSV',          -- gère les guillemets et les virgules dans le texte
    FIRSTROW = 2,            -- saute la ligne d'en-tête
    CODEPAGE = '65001',      -- UTF-8, pour les accents portugais
    ROWTERMINATOR = '0x0d0a'
);

SELECT COUNT(*) FROM stg.order_reviews;  -- attendu : 112 650