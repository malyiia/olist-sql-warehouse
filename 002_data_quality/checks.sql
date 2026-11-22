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