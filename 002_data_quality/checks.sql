/* =========================================================
   CONTRÔLES QUALITÉ DES DONNÉES — OLIST (schéma stg)
   Constats et décisions : voir findings.md
   ========================================================= */


/* =========================================================
   CONTRÔLE 1 : UNICITÉ DES IDENTIFIANTS
   Résultat attendu : aucune ligne = pas de doublon
   ========================================================= */

-- 1.1 customers : customer_id
SELECT customer_id, COUNT(*) AS nb_occurrences
FROM stg.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 1.2 orders : order_id
SELECT order_id, COUNT(*) AS nb_occurrences
FROM stg.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 1.3 products : product_id
SELECT product_id, COUNT(*) AS nb_occurrences
FROM stg.products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- 1.4 sellers : seller_id
SELECT seller_id, COUNT(*) AS nb_occurrences
FROM stg.sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- 1.5 order_reviews : review_id
-- Anomalie : 789 review_id en double (voir findings.md, point 1)
SELECT review_id, COUNT(*) AS nb_occurrences
FROM stg.order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

-- 1.6 order_reviews : nombre de lignes concernées par ces doublons
-- Résultat : 1 603 lignes
SELECT COUNT(*) AS nb_lignes
FROM stg.order_reviews
WHERE review_id IN (
    SELECT review_id
    FROM stg.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
);

-- 1.7 order_reviews : le couple (review_id, order_id) est-il unique ?
-- Résultat : 0, donc c'est la vraie clé de la table
SELECT COUNT(*) AS nb_doublons
FROM (
    SELECT COUNT(*) OVER (PARTITION BY review_id, order_id) AS nb
    FROM stg.order_reviews
) AS t
WHERE nb > 1;


/* =========================================================
   CONTRÔLE 2 : INTÉGRITÉ RÉFÉRENTIELLE (lignes orphelines)
   Résultat attendu : 0 orphelin
   Résultat obtenu  : 0 sur les 6 liens
   ========================================================= */

-- 2.1 order_items -> orders : articles sans commande
SELECT COUNT(*) AS nb_orphelins
FROM stg.order_items AS oi
LEFT JOIN stg.orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 2.2 orders -> customers : commandes sans client
SELECT COUNT(*) AS nb_orphelins
FROM stg.orders AS o
LEFT JOIN stg.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 2.3 order_items -> products : articles sans produit
SELECT COUNT(*) AS nb_orphelins
FROM stg.order_items AS oi
LEFT JOIN stg.products AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 2.4 order_items -> sellers : articles sans vendeur
SELECT COUNT(*) AS nb_orphelins
FROM stg.order_items AS oi
LEFT JOIN stg.sellers AS s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- 2.5 order_payments -> orders : paiements sans commande
SELECT COUNT(*) AS nb_orphelins
FROM stg.order_payments AS op
LEFT JOIN stg.orders AS o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 2.6 order_reviews -> orders : avis sans commande
SELECT COUNT(*) AS nb_orphelins
FROM stg.order_reviews AS r
LEFT JOIN stg.orders AS o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 2.7 Observation : produits du catalogue jamais vendus
-- Résultat : 0
SELECT COUNT(*) AS nb_produits_jamais_vendus
FROM stg.products AS p
LEFT JOIN stg.order_items AS oi
    ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;


/* =========================================================
   CONTRÔLE 3 : VALEURS MANQUANTES
   - Colonnes texte     : NULL ou chaîne vide -> NULLIF(col, '') IS NULL
   - Nombres et dates   : NULL uniquement     -> col IS NULL
   ========================================================= */

-- 3.1 customers
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN NULLIF(customer_id, '') IS NULL THEN 1 ELSE 0 END)        AS missing_customer_id,
SUM(CASE WHEN NULLIF(customer_unique_id, '') IS NULL THEN 1 ELSE 0 END) AS missing_customer_unique_id,
SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END)       AS missing_customer_zip_code_prefix,
SUM(CASE WHEN NULLIF(customer_city, '') IS NULL THEN 1 ELSE 0 END)      AS missing_customer_city,
SUM(CASE WHEN NULLIF(customer_state, '') IS NULL THEN 1 ELSE 0 END)     AS missing_customer_state
FROM stg.customers;

-- 3.2 geolocation
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN NULLIF(geolocation_zip_code_prefix, '') IS NULL THEN 1 ELSE 0 END) AS missing_geolocation_zip_code_prefix,
SUM(CASE WHEN NULLIF(geolocation_city, '') IS NULL THEN 1 ELSE 0 END)   AS missing_geolocation_city,
SUM(CASE WHEN NULLIF(geolocation_state, '') IS NULL THEN 1 ELSE 0 END)  AS missing_geolocation_state,
SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END)                AS missing_geolocation_lat,
SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END)                AS missing_geolocation_lng
FROM stg.geolocation;

-- 3.3 order_items
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN NULLIF(order_id, '') IS NULL THEN 1 ELSE 0 END)           AS missing_order_id,
SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END)                  AS missing_order_item_id,
SUM(CASE WHEN NULLIF(product_id, '') IS NULL THEN 1 ELSE 0 END)         AS missing_product_id,
SUM(CASE WHEN NULLIF(seller_id, '') IS NULL THEN 1 ELSE 0 END)          AS missing_seller_id,
SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END)            AS missing_shipping_limit_date,
SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END)                          AS missing_price,
SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END)                  AS missing_freight_value
FROM stg.order_items;

-- 3.4 order_payments
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN NULLIF(order_id, '') IS NULL THEN 1 ELSE 0 END)           AS missing_order_id,
SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END)             AS missing_payment_sequential,
SUM(CASE WHEN NULLIF(payment_type, '') IS NULL THEN 1 ELSE 0 END)       AS missing_payment_type,
SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END)           AS missing_payment_installments,
SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END)                  AS missing_payment_value
FROM stg.order_payments;

-- 3.5 order_reviews
-- Résultat : 58,7 % des avis sans message, 88,4 % sans titre (voir findings.md, point 2)
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN NULLIF(order_id, '') IS NULL THEN 1 ELSE 0 END)               AS missing_order_id,
SUM(CASE WHEN NULLIF(review_id, '') IS NULL THEN 1 ELSE 0 END)              AS missing_review_id,
SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END)                       AS missing_review_score,
SUM(CASE WHEN NULLIF(review_comment_title, '') IS NULL THEN 1 ELSE 0 END)   AS missing_review_comment_title,
SUM(CASE WHEN NULLIF(review_comment_message, '') IS NULL THEN 1 ELSE 0 END) AS missing_review_comment_message,
SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END)               AS missing_review_creation_date,
SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END)            AS missing_review_answer_timestamp,
CAST(100.0 * SUM(CASE WHEN NULLIF(review_comment_title, '') IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,1))                                            AS pct_missing_title,
CAST(100.0 * SUM(CASE WHEN NULLIF(review_comment_message, '') IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,1))                                            AS pct_missing_message
FROM stg.order_reviews;

-- 3.6 orders
-- Résultat : 0,2 % sans date d'approbation, 1,8 % sans date transporteur,
--            3,0 % sans date de livraison client (voir findings.md, point 4)
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN NULLIF(order_id, '') IS NULL THEN 1 ELSE 0 END)           AS missing_order_id,
SUM(CASE WHEN NULLIF(customer_id, '') IS NULL THEN 1 ELSE 0 END)        AS missing_customer_id,
SUM(CASE WHEN NULLIF(order_status, '') IS NULL THEN 1 ELSE 0 END)       AS missing_order_status,
SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END)       AS missing_order_purchase_timestamp,
SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END)              AS missing_order_approved_at,
SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END)   AS missing_order_delivered_carrier_date,
SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END)  AS missing_order_delivered_customer_date,
SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END)  AS missing_order_estimated_delivery_date,
CAST(100.0 * SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,1))                                        AS pct_missing_order_approved_at,
CAST(100.0 * SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,1))                                        AS pct_missing_order_delivered_carrier_date,
CAST(100.0 * SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,1))                                        AS pct_missing_order_delivered_customer_date
FROM stg.orders;

-- 3.7 product_category_name_translation
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN NULLIF(product_category_name, '') IS NULL THEN 1 ELSE 0 END)         AS missing_product_category_name,
SUM(CASE WHEN NULLIF(product_category_name_english, '') IS NULL THEN 1 ELSE 0 END) AS missing_product_category_name_english
FROM stg.product_category_name_translation;

-- 3.8 products
-- Résultat : 610 produits (1,9 %) sans infos descriptives, 2 sans poids ni dimensions
--            (voir findings.md, point 3)
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN NULLIF(product_id, '') IS NULL THEN 1 ELSE 0 END)            AS missing_product_id,
SUM(CASE WHEN NULLIF(product_category_name, '') IS NULL THEN 1 ELSE 0 END) AS missing_product_category_name,
SUM(CASE WHEN product_name_length IS NULL THEN 1 ELSE 0 END)               AS missing_product_name_length,
SUM(CASE WHEN product_description_length IS NULL THEN 1 ELSE 0 END)        AS missing_product_description_length,
SUM(CASE WHEN product_phtos_qty IS NULL THEN 1 ELSE 0 END)                 AS missing_product_phtos_qty,
SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END)                  AS missing_product_weight_g,
SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END)                 AS missing_product_length_cm,
SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END)                 AS missing_product_height_cm,
SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END)                  AS missing_product_width_cm,
CAST(100.0 * SUM(CASE WHEN NULLIF(product_category_name, '') IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,1))                                           AS pct_missing_product_category_name,
CAST(100.0 * SUM(CASE WHEN product_name_length IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,1))                                           AS pct_missing_product_name_length,
CAST(100.0 * SUM(CASE WHEN product_description_length IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,1))                                           AS pct_missing_product_description_length,
CAST(100.0 * SUM(CASE WHEN product_phtos_qty IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,1))                                           AS pct_missing_product_phtos_qty,
CAST(100.0 * SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,2))                                           AS pct_missing_product_weight_g,
CAST(100.0 * SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,2))                                           AS pct_missing_product_length_cm,
CAST(100.0 * SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,2))                                           AS pct_missing_product_height_cm,
CAST(100.0 * SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END)
     / COUNT(*) AS DECIMAL(5,2))                                           AS pct_missing_product_width_cm
FROM stg.products;

-- 3.9 sellers
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN NULLIF(seller_id, '') IS NULL THEN 1 ELSE 0 END)          AS missing_seller_id,
SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END)         AS missing_seller_zip_code_prefix,
SUM(CASE WHEN NULLIF(seller_city, '') IS NULL THEN 1 ELSE 0 END)        AS missing_seller_city,
SUM(CASE WHEN NULLIF(seller_state, '') IS NULL THEN 1 ELSE 0 END)       AS missing_seller_state
FROM stg.sellers;


/* ---------------------------------------------------------
   Approfondissements du contrôle 3
   --------------------------------------------------------- */

-- 3.10 orders : dates de livraison client vides, par statut
-- Résultat : les dates vides concernent surtout des commandes non livrées
SELECT order_status,
       COUNT(*) AS nb_commandes,
       SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS nb_sans_date_livraison
FROM stg.orders
GROUP BY order_status
ORDER BY nb_sans_date_livraison DESC;

-- 3.11 orders : commandes 'delivered' sans date de livraison client
-- Anomalie : 8 commandes (voir findings.md, point 4)
SELECT *
FROM stg.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- 3.12 products : les 4 colonnes descriptives manquent-elles sur les mêmes produits ?
-- Résultat attendu : 610
SELECT COUNT(*) AS nb_produits_incomplets
FROM stg.products
WHERE NULLIF(product_category_name, '') IS NULL
  AND product_name_length IS NULL
  AND product_description_length IS NULL
  AND product_phtos_qty IS NULL;

-- 3.13 products : les 2 produits sans poids ni dimensions
-- Résultat : un seul fait partie des 610 produits sans catégorie
SELECT product_id, product_category_name, product_weight_g, product_length_cm
FROM stg.products
WHERE product_weight_g IS NULL;

-- 3.14 order_items : articles vendus dont le produit n'a pas de catégorie
-- Résultat : 1 603 articles, soit 1,4 % des 112 650 articles
SELECT COUNT(*) AS nb_articles_vendus
FROM (
    SELECT p.product_id
    FROM stg.products AS p
    WHERE NULLIF(p.product_category_name, '') IS NULL
) AS products_without_category
INNER JOIN stg.order_items AS oi
    ON products_without_category.product_id = oi.product_id;


-- 3.15 orders : commandes sans date d'approbation, par statut
-- Résultat : 160 commandes (141 canceled, 14 delivered, 5 created)
SELECT order_status, COUNT(*) AS nb_commandes
FROM stg.orders
WHERE order_approved_at IS NULL
GROUP BY order_status
ORDER BY nb_commandes DESC;

-- 3.16 orders : commandes sans date d'approbation hors statuts normaux
-- Anomalie : 14 commandes delivered (voir findings.md, point 5)
SELECT *
FROM stg.orders
WHERE order_approved_at IS NULL
  AND order_status NOT IN ('canceled', 'created');