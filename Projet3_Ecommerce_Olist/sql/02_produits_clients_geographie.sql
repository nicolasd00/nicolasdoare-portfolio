-- ============================================================
-- PROJET : Analyse E-commerce Olist
-- PARTIE 2 : Analyse des produits, clients et géographie
-- ============================================================


-- ------------------------------------------------------------
-- 07 - TOP 10 DES CATEGORIES PAR VALEUR DES VENTES
-- Objectif :
-- Identifier les catégories de produits générant la plus
-- grande valeur sur les commandes effectivement livrées.
--
-- Attention :
-- Cet indicateur utilise order_items.price et représente donc
-- la valeur des articles vendus, et non les paiements encaissés.
-- ------------------------------------------------------------

SELECT
    t.product_category_name_english AS category,
    ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY t.product_category_name_english
ORDER BY revenue DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 08 - TOP 10 DES CATEGORIES PAR VOLUME
-- Objectif :
-- Identifier les catégories ayant vendu le plus grand nombre
-- d'articles afin de comparer volume et valeur générée.
-- ------------------------------------------------------------

SELECT
    t.product_category_name_english AS category,
    COUNT(*) AS items_sold
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY t.product_category_name_english
ORDER BY items_sold DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 09 - PRIX MOYEN PAR CATEGORIE
-- Objectif :
-- Comparer le prix moyen des articles entre les différentes
-- catégories afin de mieux expliquer leur performance.
--
-- Seules les catégories comptabilisant au moins 100 articles
-- vendus sont retenues afin d'éviter les résultats reposant
-- sur un volume trop faible.
-- ------------------------------------------------------------

SELECT
    t.product_category_name_english AS category,
    COUNT(*) AS items_sold,
    ROUND(AVG(oi.price), 2) AS average_price
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY t.product_category_name_english
HAVING COUNT(*) >= 100
ORDER BY average_price DESC;


-- ------------------------------------------------------------
-- 10 - NOMBRE DE CLIENTS UNIQUES
-- Objectif :
-- Déterminer le nombre réel de clients présents dans la base.
--
-- Attention :
-- customer_id est associé à une commande et ne permet pas
-- d'identifier un même client entre plusieurs commandes.
-- customer_unique_id est donc utilisé pour cette analyse.
-- ------------------------------------------------------------

SELECT
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;


-- ------------------------------------------------------------
-- 11 - TAUX DE CLIENTS RECURRENTS
-- Objectif :
-- Mesurer la proportion de clients ayant effectué plusieurs
-- commandes livrées sur la période étudiée.
--
-- Les commandes sont d'abord regroupées au niveau du
-- customer_unique_id afin d'identifier correctement les
-- achats répétés d'un même client.
-- ------------------------------------------------------------

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS number_of_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS customers,

    SUM(
        CASE
            WHEN number_of_orders > 1 THEN 1
            ELSE 0
        END
    ) AS repeat_customers,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN number_of_orders > 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS repeat_customer_rate

FROM customer_orders;


-- ------------------------------------------------------------
-- 12 - TOP 10 DES ETATS PAR NOMBRE DE COMMANDES
-- Objectif :
-- Identifier les zones géographiques concentrant le plus
-- grand volume de commandes livrées.
-- ------------------------------------------------------------

SELECT
    c.customer_state,
    COUNT(*) AS orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY orders DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 13 - CHIFFRE D'AFFAIRES PAR ETAT
-- Objectif :
-- Comparer la performance commerciale des différents Etats
-- en combinant volume de commandes et chiffre d'affaires.
-- ------------------------------------------------------------

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(p.payment_value), 2) AS revenue
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC;
