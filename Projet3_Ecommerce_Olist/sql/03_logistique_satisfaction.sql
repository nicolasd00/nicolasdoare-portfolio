-- ============================================================
-- PROJET : Analyse E-commerce Olist
-- PARTIE 3 : Analyse de la logistique et de la satisfaction
-- ============================================================


-- ------------------------------------------------------------
-- 14 - DELAI MOYEN DE LIVRAISON
-- Objectif :
-- Mesurer le nombre moyen de jours entre l'achat d'une
-- commande et sa réception effective par le client.
--
-- Seules les commandes livrées disposant d'une date de
-- livraison sont prises en compte.
-- ------------------------------------------------------------

SELECT
    ROUND(
        AVG(
            julianday(order_delivered_customer_date)
            - julianday(order_purchase_timestamp)
        ),
        2
    ) AS average_delivery_days
FROM orders
WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL;


-- ------------------------------------------------------------
-- 15 - TAUX DE COMMANDES LIVREES EN RETARD
-- Objectif :
-- Mesurer la proportion de commandes arrivées après la date
-- de livraison estimée communiquée au client.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS delivered_orders,

    SUM(
        CASE
            WHEN order_delivered_customer_date >
                 order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN order_delivered_customer_date >
                     order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        2
    ) AS late_delivery_rate

FROM orders
WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL;


-- ------------------------------------------------------------
-- 16 - NOTE MOYENNE DES CLIENTS
-- Objectif :
-- Mesurer le niveau global de satisfaction des clients
-- à partir des notes présentes dans la table reviews.
-- ------------------------------------------------------------

SELECT
    ROUND(AVG(review_score), 2) AS average_review_score
FROM reviews;


-- ------------------------------------------------------------
-- 17 - RETARD DE LIVRAISON VS SATISFACTION
-- Objectif :
-- Comparer la note moyenne des commandes livrées à temps
-- avec celle des commandes livrées après la date prévue.
--
-- Cette analyse permet d'identifier une association entre
-- performance logistique et satisfaction, mais ne permet pas
-- à elle seule d'établir une relation de causalité.
-- ------------------------------------------------------------

SELECT
    CASE
        WHEN o.order_delivered_customer_date >
             o.order_estimated_delivery_date
        THEN 'Late'
        ELSE 'On time'
    END AS delivery_status,

    COUNT(*) AS reviews,

    ROUND(AVG(r.review_score), 2) AS average_review_score

FROM orders o
JOIN reviews r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL

GROUP BY delivery_status;


-- ------------------------------------------------------------
-- 18 - DUREE DU RETARD VS SATISFACTION
-- Objectif :
-- Déterminer si la satisfaction évolue selon l'importance
-- du retard de livraison.
--
-- Les commandes sont segmentées en quatre groupes :
-- - livraison à l'heure
-- - retard de 1 à 3 jours
-- - retard de 4 à 7 jours
-- - retard de 8 jours ou plus
-- ------------------------------------------------------------

SELECT
    CASE
        WHEN julianday(o.order_delivered_customer_date)
             - julianday(o.order_estimated_delivery_date) <= 0
            THEN 'On time'

        WHEN julianday(o.order_delivered_customer_date)
             - julianday(o.order_estimated_delivery_date) <= 3
            THEN '1-3 days late'

        WHEN julianday(o.order_delivered_customer_date)
             - julianday(o.order_estimated_delivery_date) <= 7
            THEN '4-7 days late'

        ELSE '8+ days late'
    END AS delay_group,

    COUNT(*) AS orders,

    ROUND(
        AVG(r.review_score),
        2
    ) AS average_review_score

FROM orders o
JOIN reviews r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL

GROUP BY delay_group

ORDER BY
    CASE delay_group
        WHEN 'On time' THEN 1
        WHEN '1-3 days late' THEN 2
        WHEN '4-7 days late' THEN 3
        WHEN '8+ days late' THEN 4
    END;


-- ------------------------------------------------------------
-- 19 - PERFORMANCE DES VENDEURS
-- Objectif :
-- Comparer les principaux vendeurs en combinant plusieurs
-- dimensions de performance :
-- - nombre de commandes
-- - nombre d'articles vendus
-- - valeur des articles vendus
-- - satisfaction client
--
-- Seuls les vendeurs ayant au moins 100 commandes livrées
-- sont retenus afin de comparer des volumes significatifs.
-- ------------------------------------------------------------

SELECT
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS revenue,
    ROUND(AVG(r.review_score), 2) AS average_review_score

FROM order_items oi

JOIN orders o
    ON oi.order_id = o.order_id

LEFT JOIN reviews r
    ON oi.order_id = r.order_id

WHERE o.order_status = 'delivered'

GROUP BY oi.seller_id

HAVING COUNT(DISTINCT oi.order_id) >= 100

ORDER BY revenue DESC

LIMIT 20;
