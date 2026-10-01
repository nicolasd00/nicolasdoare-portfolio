# 📊 Analyse des performances d'une marketplace e-commerce

## 🎯 Présentation du projet

Ce projet a pour objectif d'analyser les performances commerciales de la marketplace brésilienne **Olist** à partir d'un jeu de données contenant près de **100 000 commandes**.

L'analyse est réalisée dans le cadre de mon portfolio de Data Analyst et vise à reproduire une problématique professionnelle : partir de données transactionnelles brutes afin de construire des indicateurs de performance, identifier des tendances et fournir des informations exploitables pour le pilotage de l'activité.

L'étude s'articule autour de quatre axes :

1. **Performance commerciale** — chiffre d'affaires, commandes et panier moyen
2. **Produits** — catégories, volumes et prix
3. **Clients & géographie** — fidélisation et répartition régionale
4. **Logistique & satisfaction** — délais, retards, avis et vendeurs

---

## 🛠️ Technologies utilisées

- **SQL / SQLite** : exploration, jointures, agrégations, CTE, `CASE WHEN` et analyses
- **SQLiteStudio** : gestion et interrogation de la base de données
- **Python / Pandas** : analyse complémentaire des données
- **Power BI** : création du tableau de bord final
- **Git / GitHub** : documentation et versionnement du projet

---

# 🗃️ Données & méthodologie

## Dataset

Les données utilisées proviennent du dataset public **Brazilian E-Commerce Public Dataset by Olist**.

La base contient **99 441 commandes** réparties dans 9 tables permettant notamment d'étudier :

- les commandes ;
- les clients ;
- les produits ;
- les vendeurs ;
- les paiements ;
- les avis clients ;
- la localisation géographique ;
- les délais de livraison.

### Principales tables utilisées

| Table | Description |
|---|---|
| `orders` | Informations sur les commandes et leurs statuts |
| `payments` | Paiements associés aux commandes |
| `customers` | Informations sur les clients |
| `order_items` | Produits présents dans les commandes |
| `products` | Informations sur les produits |
| `reviews` | Notes et avis clients |
| `sellers` | Informations sur les vendeurs |
| `product_category_name_translation` | Traduction des catégories de produits |

---

## Questions métier

L'analyse cherche notamment à répondre aux questions suivantes :

- Comment l'activité commerciale évolue-t-elle dans le temps ?
- La croissance du chiffre d'affaires provient-elle du volume ou du panier moyen ?
- Quelles catégories génèrent le plus de valeur ?
- Quelles catégories sont les plus vendues ?
- Les clients reviennent-ils effectuer plusieurs commandes ?
- Quelles régions concentrent l'activité ?
- Les délais de livraison sont-ils respectés ?
- Les retards sont-ils associés à une baisse de satisfaction ?
- Quels vendeurs combinent performance commerciale et satisfaction client ?

---

# 📌 Vue d'ensemble

| KPI | Résultat |
|---|---:|
| Commandes enregistrées | **99 441** |
| Commandes livrées | **96 478** |
| CA des commandes livrées | **15 422 461,77 R$** |
| Panier moyen | **159,86 R$** |
| Clients uniques | **96 096** |
| Clients récurrents observés | **3,00 %** |
| Délai moyen de livraison | **12,56 jours** |
| Taux de retard | **8,11 %** |
| Note moyenne globale | **4,09 / 5** |

> Le chiffre d'affaires présenté correspond à la somme des paiements associés aux commandes ayant le statut `delivered`. Les commandes annulées ou non finalisées sont exclues.

---

# 📈 Axe 1 — Performance commerciale

L'objectif de cette première partie est de comprendre **la dynamique globale de l'activité** et les facteurs expliquant l'évolution du chiffre d'affaires.

## Chiffre d'affaires des commandes livrées

```sql
SELECT 
    ROUND(SUM(p.payment_value), 2) AS total_revenue
FROM orders o
JOIN payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';
```

### Résultat

**15 422 461,77 R$**

Cette requête combine les informations de commande avec les paiements afin de ne conserver que les transactions correspondant à des commandes effectivement livrées.

---

## Nombre de commandes livrées

```sql
SELECT
    COUNT(*) AS delivered_orders
FROM orders
WHERE order_status = 'delivered';
```

### Résultat

**96 478 commandes**

Sur les 99 441 commandes enregistrées dans la base, 96 478 ont été livrées.

Cela représente environ **97 % des commandes**.

---

## Panier moyen

Une commande peut être associée à plusieurs lignes dans la table `payments`.

Calculer directement `AVG(payment_value)` donnerait donc la moyenne d'un paiement et non le montant moyen réellement dépensé par commande.

Les paiements sont d'abord regroupés par `order_id`.

```sql
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
```

### Résultat

**159,86 R$**

Le panier moyen d'une commande livrée est donc d'environ **160 R$**.

Cette étape illustre l'importance de contrôler la **granularité des données** avant de calculer un indicateur.

---

## Évolution mensuelle du chiffre d'affaires

```sql
SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value), 2) AS revenue
FROM orders o
JOIN payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;
```

### Quelques résultats significatifs

| Mois | CA |
|---|---:|
| Janvier 2017 | 127 545,67 R$ |
| Mai 2017 | 567 066,73 R$ |
| Août 2017 | 646 000,61 R$ |
| Novembre 2017 | **1 153 528,05 R$** |
| Janvier 2018 | 1 078 606,86 R$ |
| Avril 2018 | 1 132 933,95 R$ |
| Août 2018 | 985 414,28 R$ |

Une forte progression de l'activité apparaît au cours de l'année 2017.

À mois comparable, le chiffre d'affaires passe notamment de **646 000,61 R$ en août 2017 à 985 414,28 R$ en août 2018**, soit une progression d'environ **52,5 %**.

Novembre 2017 constitue également un mois particulièrement élevé avec plus de **1,15 million de R$** de paiements associés aux commandes livrées.

Les premiers mois du dataset contiennent très peu d'observations. Ils doivent donc être interprétés avec prudence et ne sont pas représentatifs d'un mois complet d'activité.

---

## Évolution mensuelle du nombre de commandes

```sql
SELECT
    strftime('%Y-%m', order_purchase_timestamp) AS month,
    COUNT(*) AS orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY month
ORDER BY month;
```

### Quelques résultats

| Mois | Commandes |
|---|---:|
| Janvier 2017 | 750 |
| Mai 2017 | 3 546 |
| Août 2017 | 4 193 |
| Novembre 2017 | **7 289** |
| Janvier 2018 | 7 069 |
| Avril 2018 | 6 798 |
| Août 2018 | 6 351 |

L'évolution du nombre de commandes suit globalement celle du chiffre d'affaires.

La marketplace connaît une forte croissance de son volume d'activité pendant l'année 2017.

Le pic observé en novembre 2017 dans le chiffre d'affaires coïncide avec un pic du nombre de commandes : **7 289 commandes livrées**.

---

## Évolution mensuelle du panier moyen

Afin de déterminer si la croissance du CA provient du volume de commandes ou d'une augmentation du montant dépensé, le panier moyen est également analysé dans le temps.

```sql
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
```

### Quelques résultats

| Mois | Panier moyen |
|---|---:|
| Janvier 2017 | 170,06 R$ |
| Mai 2017 | 159,92 R$ |
| Août 2017 | 154,07 R$ |
| Novembre 2017 | 158,26 R$ |
| Janvier 2018 | 152,58 R$ |
| Avril 2018 | 166,66 R$ |
| Août 2018 | 155,16 R$ |

Sur la période où l'activité devient significative, le panier moyen reste relativement stable, généralement compris entre **145 et 170 R$**.

### 💡 Enseignement métier

La forte progression du chiffre d'affaires s'accompagne d'une hausse importante du nombre de commandes tandis que le panier moyen reste relativement stable.

Les données suggèrent donc que la croissance observée est principalement portée par **l'augmentation du volume de commandes** plutôt que par une hausse durable du montant dépensé par commande.

Novembre 2017 illustre particulièrement ce phénomène :

- **7 289 commandes livrées**
- **1 153 528,05 R$ de CA**
- **158,26 R$ de panier moyen**

Le pic de CA est accompagné d'une forte hausse du volume sans augmentation exceptionnelle du panier moyen.

---

# 🛍️ Axe 2 — Performance des produits

Après avoir étudié la croissance globale, l'analyse cherche à déterminer **quels produits génèrent cette activité et pourquoi**.

Deux dimensions sont comparées :

- le volume d'articles vendus ;
- la valeur générée par les produits.

---

## Catégories générant le plus de valeur

```sql
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
```

### Top 10

| Rang | Catégorie | Valeur des articles vendus |
|---:|---|---:|
| 1 | Health & Beauty | **1 233 131,72 R$** |
| 2 | Watches & Gifts | **1 166 176,98 R$** |
| 3 | Bed, Bath & Table | **1 023 434,76 R$** |
| 4 | Sports & Leisure | 954 852,55 R$ |
| 5 | Computers & Accessories | 888 724,61 R$ |
| 6 | Furniture & Decor | 711 927,69 R$ |
| 7 | Housewares | 615 628,69 R$ |
| 8 | Cool Stuff | 610 204,10 R$ |
| 9 | Auto | 578 966,65 R$ |
| 10 | Toys | 471 286,48 R$ |

**Health & Beauty** est la catégorie générant la plus grande valeur de produits vendus avec plus de **1,23 million de R$**.

Cependant, le classement par valeur ne suffit pas à déterminer pourquoi une catégorie est performante.

> **Note méthodologique :** cet indicateur utilise `order_items.price`. Il représente la valeur des articles vendus et ne doit pas être confondu avec le CA calculé à partir de `payment_value`.

---

## Catégories les plus vendues en volume

```sql
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
```

### Top 10

| Rang | Catégorie | Articles vendus |
|---:|---|---:|
| 1 | Bed, Bath & Table | **10 953** |
| 2 | Health & Beauty | **9 465** |
| 3 | Sports & Leisure | **8 431** |
| 4 | Furniture & Decor | 8 160 |
| 5 | Computers & Accessories | 7 644 |
| 6 | Housewares | 6 795 |
| 7 | Watches & Gifts | 5 859 |
| 8 | Telephony | 4 430 |
| 9 | Garden Tools | 4 268 |
| 10 | Auto | 4 140 |

Le classement change lorsque l'on observe le volume.

**Bed, Bath & Table** devient première avec 10 953 articles, alors que **Watches & Gifts** est seulement septième malgré sa deuxième place en valeur.

Cela suggère une différence importante de prix moyen.

---

## Prix moyen par catégorie

Afin d'éviter de surinterpréter des catégories très peu représentées, seules celles comptabilisant au moins **100 articles vendus** sont conservées.

```sql
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
```

### Catégories aux prix moyens les plus élevés

| Catégorie | Articles vendus | Prix moyen |
|---|---:|---:|
| Computers | 199 | **1 098,92 R$** |
| Home Appliances 2 | 231 | **467,33 R$** |
| Agro Industry & Commerce | 206 | **342,55 R$** |
| Musical Instruments | 651 | **283,13 R$** |
| Small Appliances | 658 | **277,74 R$** |
| Fixed Telephony | 255 | 216,92 R$ |
| Construction Tools Safety | 183 | 211,88 R$ |
| Watches & Gifts | 5 859 | **199,04 R$** |
| Furniture Bedroom | 103 | 184,97 R$ |
| Air Conditioning | 289 | 184,51 R$ |

### 💡 Enseignement métier

Trois modèles de performance apparaissent :

**Volume élevé + prix modéré → Bed, Bath & Table**

- 10 953 articles
- 93,44 R$ de prix moyen
- environ 1,02 million de R$ générés

**Volume important + prix élevé → Watches & Gifts**

- 5 859 articles
- 199,04 R$ de prix moyen
- plus de 1,16 million de R$ générés

**Faible volume + prix très élevé → Computers**

- 199 articles
- 1 098,92 R$ de prix moyen

La performance d'une catégorie doit donc être analysée conjointement en **volume, prix et valeur générée**.

---

# 👥 Axe 3 — Clients & géographie

Cette partie cherche à comprendre **qui génère l'activité**, si les clients reviennent et où les commandes sont concentrées.

---

## Identification des clients uniques

Dans le dataset Olist, `customer_id` ne correspond pas nécessairement à un client permanent.

Un même client effectuant plusieurs commandes peut disposer de plusieurs `customer_id`.

La variable `customer_unique_id` permet d'identifier un même client à travers différentes commandes.

```sql
SELECT
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;
```

### Résultat

**96 096 clients uniques**

Cette distinction est essentielle pour éviter de surestimer le nombre réel de clients et pour analyser correctement leur récurrence d'achat.

---

## Récurrence d'achat

```sql
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
```

### Résultats

| KPI | Résultat |
|---|---:|
| Clients avec au moins une commande livrée | **93 358** |
| Clients ayant commandé plusieurs fois | **2 801** |
| Taux de clients récurrents | **3,00 %** |

Environ **97 % des clients observés n'ont qu'une seule commande livrée** sur la période analysée.

Cette faible récurrence, rapprochée de la forte augmentation du volume de commandes, suggère que la croissance pourrait être davantage associée à **l'acquisition de nouveaux clients** qu'aux achats répétés de clients existants.

Cette hypothèse nécessiterait cependant une analyse par cohortes pour être confirmée.

---

## Répartition géographique des commandes

```sql
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
```

### Top 10 des États

| État | Commandes livrées |
|---|---:|
| SP — São Paulo | **40 501** |
| RJ — Rio de Janeiro | **12 350** |
| MG — Minas Gerais | **11 354** |
| RS — Rio Grande do Sul | 5 345 |
| PR — Paraná | 4 923 |
| SC — Santa Catarina | 3 546 |
| BA — Bahia | 3 256 |
| DF — Distrito Federal | 2 080 |
| ES — Espírito Santo | 1 995 |
| GO — Goiás | 1 957 |

L'activité présente une forte concentration géographique.

**São Paulo représente à lui seul environ 42 % des commandes livrées.**

São Paulo, Rio de Janeiro et Minas Gerais représentent ensemble environ **deux tiers des commandes livrées**.

---

## Chiffre d'affaires par État

```sql
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
```

### Principaux résultats

| État | Commandes | CA |
|---|---:|---:|
| SP | 40 500 | **5 770 266,19 R$** |
| RJ | 12 350 | **2 055 690,45 R$** |
| MG | 11 354 | **1 819 277,61 R$** |
| RS | 5 345 | 861 802,40 R$ |
| PR | 4 923 | 781 919,55 R$ |
| SC | 3 546 | 595 208,40 R$ |
| BA | 3 256 | 591 270,60 R$ |
| DF | 2 080 | 346 146,17 R$ |
| GO | 1 957 | 334 294,22 R$ |
| ES | 1 995 | 317 682,65 R$ |

São Paulo domine également en valeur avec environ **5,77 millions de R$**.

Cependant, cette domination repose surtout sur le volume :

- São Paulo : environ **142 R$ par commande**
- Rio de Janeiro : environ **166 R$**
- Minas Gerais : environ **160 R$**

### 💡 Enseignement métier

L'activité d'Olist apparaît à la fois :

- fortement dépendante de l'acquisition de clients ;
- très concentrée géographiquement ;
- particulièrement dépendante de São Paulo en termes de volume.

Le marché générant le plus de CA n'est pas nécessairement celui présentant la valeur moyenne par commande la plus élevée.

---

# 🚚 Axe 4 — Logistique & satisfaction client

Après avoir analysé **quand, quoi, où et auprès de qui Olist vend**, cette dernière partie étudie ce qui se passe après la commande.

L'objectif principal est de tester l'hypothèse suivante :

> **Les performances logistiques sont-elles associées à la satisfaction des clients ?**

---

## Délai moyen de livraison

```sql
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
```

### Résultat

**12,56 jours**

Une commande livrée met en moyenne 12,56 jours entre sa date d'achat et sa réception.

Cette moyenne ne permet cependant pas de savoir si la date annoncée au client a été respectée.

---

## Taux de retard

```sql
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
```

### Résultats

| KPI | Résultat |
|---|---:|
| Commandes livrées | **96 478** |
| Commandes en retard | **7 826** |
| Taux de retard | **8,11 %** |

Environ **92 % des commandes sont donc livrées au plus tard à la date prévue**.

Le retard reste minoritaire, mais concerne tout de même près d'une commande sur douze.

---

## Satisfaction globale

```sql
SELECT
    ROUND(AVG(review_score), 2) AS average_review_score
FROM reviews;
```

### Résultat

**4,09 / 5**

La satisfaction globale apparaît relativement élevée.

Cette moyenne masque cependant des expériences très différentes selon les conditions de livraison.

---

## Retard de livraison vs satisfaction

```sql
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
```

### Résultats

| Statut | Avis | Note moyenne |
|---|---:|---:|
| À l'heure | **88 661** | **4,29 / 5** |
| En retard | **7 700** | **2,57 / 5** |

La différence est importante : les commandes livrées à temps obtiennent une note moyenne de **4,29/5**, contre seulement **2,57/5** lorsqu'elles arrivent en retard.

Cela représente une différence de **1,72 point**, soit environ **40 % de moins** par rapport à la note des commandes livrées à temps.

> Cette analyse montre une **association** entre retard et insatisfaction. Elle ne permet pas, à elle seule, d'établir une relation de causalité.

---

## Durée du retard vs satisfaction

Pour approfondir cette relation, les retards sont répartis en plusieurs niveaux.

```sql
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
    ROUND(AVG(r.review_score), 2) AS average_review_score

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
```

### Résultats

| Retard | Commandes / avis | Note moyenne |
|---|---:|---:|
| À l'heure | **88 653** | **4,29 / 5** |
| 1–3 jours | **2 651** | **3,77 / 5** |
| 4–7 jours | **1 777** | **2,32 / 5** |
| 8 jours ou plus | **3 280** | **1,74 / 5** |

### 💡 Enseignement métier majeur

Une tendance particulièrement nette apparaît :

**plus le retard augmente, plus la satisfaction diminue.**

La note passe progressivement de :

**4,29 → 3,77 → 2,32 → 1,74**

La différence entre une livraison à l'heure et un retard d'au moins 8 jours atteint **2,55 points sur 5**.

Les retards courts sont déjà associés à une baisse de satisfaction, mais celle-ci devient particulièrement importante lorsque le retard dépasse **3 jours**.

La réduction des retards les plus importants apparaît donc comme un axe potentiel d'amélioration de l'expérience client.

---

## Performance des vendeurs

La dernière analyse combine performance commerciale et satisfaction.

Seuls les vendeurs ayant au moins **100 commandes livrées** sont conservés afin d'éviter les comparaisons sur des volumes trop faibles.

```sql
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
```

### Top 10

| Vendeur | Commandes | Articles | Valeur | Note |
|---|---:|---:|---:|---:|
| `4869f7...` | 1 124 | 1 148 | **226 987,93 R$** | 4,14 |
| `532435...` | 348 | 400 | **217 940,44 R$** | 4,13 |
| `4a3ca9...` | 1 772 | 1 971 | **199 408,32 R$** | 3,83 |
| `fa1c13...` | 578 | 579 | **190 917,14 R$** | 4,37 |
| `7c67e1...` | 973 | 1 366 | **188 063,83 R$** | 3,35 |
| `7e93a4...` | 319 | 322 | **165 981,49 R$** | 4,36 |
| `da8622...` | 1 311 | 1 571 | **162 303,67 R$** | 4,08 |
| `7a67c8...` | 1 145 | 1 159 | **140 238,65 R$** | 4,27 |
| `1025f0...` | 910 | 1 434 | **139 720,16 R$** | 3,87 |
| `955fee...` | 1 261 | 1 474 | **131 906,71 R$** | 4,09 |

Les vendeurs présentent des profils très différents.

Le vendeur `4869f7...` arrive en tête avec près de **227 000 R$** générés, 1 124 commandes et une note de **4,14/5**.

Le vendeur `7c67e1...` génère environ **188 064 R$**, mais sa note moyenne n'est que de **3,35/5**.

À l'inverse, `fa1c13...` génère environ **190 917 R$** avec seulement 578 commandes tout en conservant une note élevée de **4,37/5**.

### 💡 Enseignement métier

La performance d'un vendeur ne devrait pas être évaluée uniquement à partir de ses ventes.

Un pilotage plus complet devrait combiner :

- chiffre d'affaires / valeur générée ;
- nombre de commandes ;
- nombre d'articles ;
- satisfaction client ;
- taux de retard ;
- taux d'annulation.

Cela permettrait d'identifier aussi bien les **vendeurs à forte valeur et forte satisfaction** que ceux générant beaucoup d'activité mais présentant des problèmes d'expérience client.

---

# 🔎 Synthèse des principaux enseignements

## 📈 La croissance est principalement portée par le volume

Le chiffre d'affaires des commandes livrées atteint **15,42 millions de R$** pour un panier moyen de **159,86 R$**.

L'augmentation du nombre de commandes est beaucoup plus marquée que celle du panier moyen.

La croissance observée semble donc principalement portée par **le volume de commandes**.

---

## 🛍️ Les catégories suivent différents modèles de performance

**Bed, Bath & Table** repose principalement sur un volume très important.

**Watches & Gifts** combine volume et prix moyen élevé.

**Computers** présente au contraire un prix très élevé mais un faible volume.

La valeur générée doit donc être décomposée entre **volume et prix**.

---

## 👥 La récurrence d'achat observée est faible

Parmi les **93 358 clients ayant au moins une commande livrée**, seulement **2 801 ont commandé plusieurs fois**, soit **3 %**.

La croissance pourrait donc être davantage associée à l'acquisition de nouveaux clients qu'à la répétition des achats.

---

## 🇧🇷 L'activité est fortement concentrée géographiquement

São Paulo représente environ **42 % des commandes livrées**.

Avec Rio de Janeiro et Minas Gerais, les trois premiers États concentrent environ **deux tiers des commandes**.

---

## 🚚 La majorité des commandes respecte la date annoncée

Le délai moyen de livraison est de **12,56 jours**.

**8,11 % des commandes livrées arrivent après la date estimée.**

---

## ⭐ Le retard est fortement associé à l'insatisfaction

| Livraison | Note moyenne |
|---|---:|
| À l'heure | **4,29 / 5** |
| 1–3 jours de retard | **3,77 / 5** |
| 4–7 jours de retard | **2,32 / 5** |
| 8+ jours de retard | **1,74 / 5** |

Il s'agit de l'un des résultats les plus marquants de l'étude : **la satisfaction diminue fortement à mesure que le retard augmente.**

---

# 💡 Recommandations métier

### Réduire prioritairement les retards importants

Les commandes présentant au moins 8 jours de retard obtiennent une note moyenne de seulement **1,74/5**.

Une analyse complémentaire par vendeur, région ou catégorie permettrait d'identifier les principales sources de ces retards.

### Développer la fidélisation

Avec seulement **3 % de clients récurrents observés**, l'analyse du parcours après le premier achat pourrait permettre d'identifier des opportunités de rétention.

Une analyse par cohortes constituerait une prochaine étape pertinente.

### Piloter les vendeurs avec plusieurs dimensions

Le volume ou la valeur générée ne devraient pas constituer les seuls critères.

Le suivi pourrait combiner :

- ventes ;
- volume ;
- satisfaction ;
- délais ;
- taux de retard ;
- taux d'annulation.

### Adapter les décisions commerciales aux catégories

Les catégories présentent des profils différents selon leur volume et leur prix moyen.

Les stratégies commerciales pourraient donc être adaptées selon que la performance repose sur :

- un **fort volume** ;
- un **prix élevé** ;
- ou la combinaison des deux.

---

# ⚠️ Limites de l'analyse

Plusieurs limites doivent être prises en compte.

Le dataset couvre une période déterminée et ne permet pas d'observer l'intégralité du cycle de vie des clients.

Le taux de 3 % correspond donc à une **récurrence d'achat observée sur la période**, et non à un taux de rétention définitif.

Les analyses relatives aux avis mettent en évidence des **associations descriptives**, mais ne permettent pas d'établir à elles seules une relation causale.

Certaines analyses pourraient également être approfondies en croisant davantage les vendeurs, régions, catégories de produits et caractéristiques logistiques.

---

## Compétences SQL mobilisées

Ce projet met notamment en pratique :

`JOIN` · `LEFT JOIN` · `GROUP BY` · `HAVING` · `CASE WHEN` · `CTE` · `COUNT DISTINCT` · agrégations · manipulation de dates · contrôle de granularité · segmentation et analyse de KPI.

# 🚀 Suite du projet

La partie SQL a permis de transformer les données transactionnelles en indicateurs métier et de faire émerger plusieurs axes d'analyse.

## Power BI

La prochaine étape consiste à construire un dashboard interactif permettant de suivre :

- chiffre d'affaires ;
- nombre de commandes ;
- panier moyen ;
- évolution mensuelle ;
- catégories de produits ;
- répartition géographique ;
- délais et retards ;
- satisfaction client ;
- performance des vendeurs.

## Python

Une analyse complémentaire pourra ensuite permettre :

- d'étudier les distributions ;
- d'approfondir les relations entre variables ;
- de réaliser une analyse par cohortes ;
- d'étudier la rétention ;
- de segmenter les clients.

---
