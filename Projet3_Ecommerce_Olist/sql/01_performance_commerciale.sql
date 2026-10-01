-- ============================================================
-- PROJET : Analyse E-commerce Olist
-- PARTIE 1 : Analyse de la performance commerciale
-- ============================================================


-- ------------------------------------------------------------
-- 01 - CHIFFRE D'AFFAIRES
-- Objectif :
-- Calculer le montant total des paiements associés aux
-- commandes effectivement livrées.
-- ------------------------------------------------------------

SELECT 
    ROUND(SUM(p.payment_value), 2) AS total_revenue
FROM orders o
JOIN payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';


-- ------------------------------------------------------------
-- 02 - NOMBRE DE COMMANDES LIVREES
-- Objectif :
-- Mesurer le volume de commandes arrivées à leur terme.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS delivered_orders
FROM orders
WHERE order_status = 'delivered';


-- ------------------------------------------------------------
-- 03 - PANIER MOYEN
-- Objectif :
-- Calculer le montant moyen payé par commande.
--
-- Attention :
-- Une commande peut avoir plusieurs lignes de paiement.
-- Les paiements sont donc d'abord agrégés par order_id.
-- ------------------------------------------------------------

SELECT
    ROUND(AVG(order_value), 2) AS average_order_value
FROM (
    SELECT
        p.order_id,
        SUM(p.payment_value) AS order_value
    FROM payments p
    JOIN orders o
        ON p.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.order_id
);


-- ------------------------------------------------------------
-- 04 - CHIFFRE D'AFFAIRES MENSUEL
-- Objectif :
-- Étudier l'évolution de l'activité commerciale dans le temps.
-- ------------------------------------------------------------

SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value), 2) AS revenue
FROM orders o
JOIN payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;


-- ------------------------------------------------------------
-- 05 - NOMBRE DE COMMANDES PAR MOIS
-- Objectif :
-- Déterminer si l'évolution du CA est accompagnée d'une
-- évolution du volume de commandes.
-- ------------------------------------------------------------

SELECT
    strftime('%Y-%m', order_purchase_timestamp) AS month,
    COUNT(*) AS orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY month
ORDER BY month;


-- ------------------------------------------------------------
-- 06 - PANIER MOYEN MENSUEL
-- Objectif :
-- Déterminer si la croissance du CA provient du volume de
-- commandes ou d'une évolution du montant moyen dépensé.
-- ------------------------------------------------------------

WITH order_totals AS (
    SELECT
        o.order_id,
        o.order_purchase_timestamp,
        SUM(p.payment_value) AS order_value
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        o.order_purchase_timestamp
)

SELECT
    strftime('%Y-%m', order_purchase_timestamp) AS month,
    ROUND(AVG(order_value), 2) AS average_order_value
FROM order_totals
GROUP BY month
ORDER BY month;
