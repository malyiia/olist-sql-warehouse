# Contrôles qualité des données — Olist

Contrôles réalisés sur les tables brutes du schéma `stg`.
Requêtes : [`checks.sql`](checks.sql)

## Synthèse

| # | Table | Problème | Volume | Décision |
|---|-------|----------|--------|----------|
| 1 | order_reviews | `review_id` non unique | 789 review_id, 1 603 lignes | Conserver toutes les lignes |
| 2 | order_reviews | Commentaires d'avis vides | 58,7 % des avis (message), 88,4 % (titre) | Conserver |
| 3 | products | Informations produit manquantes | 610 produits (1,9 %), 1,4 % des articles vendus | Conserver, catégorie « non renseignée » |
| 4 | orders | Commandes `delivered` sans date de livraison | 8 commandes | Conserver, exclure des calculs de délai |
| 5 | orders | Commandes `delivered` sans date d'approbation | 14 commandes | Conserver, exclure des calculs de délai d'approbation |
| 6 | orders | Remise au transporteur avant l'approbation | 1 359 commandes, dont 16 à plus de 7 jours | Tolérer jusqu'à 7 jours, signaler les 16 |
| 7 | orders | Livraison client avant remise au transporteur | 23 commandes | Signaler, exclure des calculs de délai |

## Détail des constats

### 1. `review_id` non unique dans order_reviews

- **Contrôle** : unicité de `review_id` (requêtes 1.5 à 1.7)
- **Constat** : 789 `review_id` distincts apparaissent plusieurs fois, soit 1 603 lignes concernées et 814 lignes en surplus.
- **Analyse** : ce ne sont pas des doublons exacts. Les lignes d'un même `review_id` ont des `order_id` différents. Le couple (`review_id`, `order_id`) est unique.
- **Cause probable** : un client laisse un seul avis pour plusieurs commandes passées ensemble, et cet avis est rattaché à chacune d'elles.
- **Décision** : conserver toutes les lignes. Supprimer les « doublons » ferait perdre le lien entre l'avis et certaines commandes.
- **Impact sur le modèle** : la clé de la table est (`review_id`, `order_id`), pas `review_id` seul.

### 2. Commentaires d'avis vides

- **Contrôle** : valeurs manquantes dans order_reviews (requête 3.5)
- **Constat** : 58,7 % des avis n'ont pas de message et 88,4 % n'ont pas de titre. La note (`review_score`) est toujours renseignée.
- **Analyse** : le commentaire est un champ facultatif. Un client peut noter sans écrire.
- **Décision** : conserver. Ce n'est pas une anomalie.
- **Impact sur le modèle** : les analyses de satisfaction s'appuieront sur la note, pas sur le texte.

### 3. Informations produit manquantes

- **Contrôle** : valeurs manquantes dans products (requête 3.8), puis vérifications (requêtes 3.12 à 3.14)
- **Constat** :
    - 610 produits (1,9 %) n'ont ni catégorie, ni longueur de nom, ni longueur de description, ni nombre de photos.
    - 2 produits (0,01 %) n'ont ni poids ni dimensions.
    - Les 610 produits sans catégorie représentent 1 603 articles vendus, soit 1,4 % des 112 650 articles de order_items.
- **Analyse** : les quatre colonnes descriptives sont vides sur les mêmes 610 produits. Ce sont des fiches produits incomplètes, pas des erreurs isolées. Ces produits pèsent un peu moins dans les ventes (1,4 %) que dans le catalogue (1,9 %). Sur les 2 produits sans poids ni dimensions, un seul fait partie de ces 610 : le manque d'informations logistiques est donc un problème distinct.
- **Décision** : conserver ces produits, car ils ont bien été vendus. Remplacer la catégorie manquante par « non renseignée » dans le modèle.
- **Impact sur le modèle** : 1,4 % des articles vendus seront regroupés sous « non renseignée » et resteront visibles dans les analyses par catégorie. Les 2 produits sans poids seront exclus des analyses de frais de port.

### 4. Dates de livraison vides

- **Contrôle** : valeurs manquantes dans orders (requête 3.6), puis répartition par statut (requêtes 3.10 et 3.11)
- **Constat** : 0,2 % des commandes n'ont pas de date d'approbation, 1,8 % pas de date de remise au transporteur et 3,0 % pas de date de livraison client.
- **Analyse** : le taux de dates vides augmente à chaque étape du cycle de vie de la commande. La répartition par statut confirme que la plupart des dates de livraison vides concernent des commandes non livrées (shipped, canceled, processing…), ce qui est normal. En revanche, 8 commandes au statut `delivered` n'ont pas de date de livraison client : c'est une incohérence (statut mis à jour sans la date, ou date perdue).
- **Décision** : conserver toutes les commandes. Les 8 commandes `delivered` sans date sont signalées comme anomalie et exclues des calculs de délai de livraison.
- **Impact sur le modèle** : les calculs de délai de livraison ne porteront que sur les commandes `delivered` avec une date de livraison renseignée.

### 5. Commandes sans date d'approbation

- **Contrôle** : dates d'approbation vides par statut (requêtes 3.15 et 3.16)
- **Constat** : 160 commandes (0,2 %) n'ont pas de date d'approbation : 141 sont annulées, 14 sont livrées et 5 ont le statut `created`.
- **Analyse** : une commande peut être annulée avant l'approbation du paiement, ce qui est normal (de même pour le statut `created`). En revanche, les 14 commandes `delivered` ont forcément été approuvées : la date d'approbation a été perdue.
- **Décision** : conserver ces commandes et signaler les 14 commandes livrées comme anomalie.
- **Impact sur le modèle** : les calculs de délai d'approbation (achat → approbation) excluront les commandes sans date.

### 6. Remise au transporteur avant l'approbation du paiement

- **Contrôle** : cohérence des dates de commande (requêtes 4.3 et 4.6a à 4.6c)- **Constat** : 1 359 commandes (1,4 %) ont été remises au transporteur avant
  l'approbation du paiement. Écart médian : 17 h (Q1 : 2 h, Q3 : 26 h, max : 171 jours).
  - 242 commandes : moins d'1 heure
  - 631 commandes : 1 à 24 heures
  - 470 commandes : 1 à 7 jours
  - 16 commandes : plus de 7 jours
- **Analyse** : pour la grande majorité des commandes, l'écart est de quelques heures
  à quelques jours. Cela peut s'expliquer par un décalage d'horodatage entre systèmes
  ou par des vendeurs qui expédient avant la confirmation définitive du paiement.
  La moyenne (24 h) est tirée vers le haut par quelques valeurs extrêmes, d'où
  l'utilisation de la médiane. Les 16 commandes avec plus de 7 jours d'écart sont
  aberrantes.
- **Décision** : tolérer un écart de 7 jours maximum. Signaler les 16 commandes au-delà
  comme anomalies.
- **Impact sur le modèle** : les 16 commandes aberrantes seront exclues des calculs
  de délai entre approbation et expédition.

### 7. Livraison client avant la remise au transporteur

- **Contrôle** : cohérence des dates de commande (requête 4.4)
- **Constat** : 23 commandes ont une date de livraison client antérieure à la date de remise au transporteur.
- **Analyse** : c'est physiquement impossible : il s'agit d'erreurs de saisie de dates.
- **Décision** : conserver ces commandes et les signaler comme anomalies.
- **Impact sur le modèle** : ces 23 commandes seront exclues des calculs de délai de livraison.

## Contrôles sans anomalie

| Contrôle | Table | Résultat |
|----------|-------|----------|
| Unicité de `customer_id` | customers | ✅ aucun doublon |
| Unicité de `order_id` | orders | ✅ aucun doublon |
| Unicité de `product_id` | products | ✅ aucun doublon |
| Unicité de `seller_id` | sellers | ✅ aucun doublon |
| Articles sans commande (order_items → orders) | order_items | ✅ 0 orphelin |
| Commandes sans client (orders → customers) | orders | ✅ 0 orphelin |
| Articles sans produit (order_items → products) | order_items | ✅ 0 orphelin |
| Articles sans vendeur (order_items → sellers) | order_items | ✅ 0 orphelin |
| Paiements sans commande (order_payments → orders) | order_payments | ✅ 0 orphelin |
| Avis sans commande (order_reviews → orders) | order_reviews | ✅ 0 orphelin |
| Valeurs manquantes | customers | ✅ aucune |
| Valeurs manquantes | geolocation | ✅ aucune |
| Valeurs manquantes | order_items | ✅ aucune |
| Valeurs manquantes | order_payments | ✅ aucune |
| Valeurs manquantes | sellers | ✅ aucune |
| Valeurs manquantes | product_category_name_translation | ✅ aucune |
| Approbation avant l'achat | orders | ✅ 0 commande |
| Livraison client avant l'achat | orders | ✅ 0 commande |
| Livraison estimée avant l'achat | orders | ✅ 0 commande |

## Observations

- Les 32 951 produits du catalogue ont tous été vendus au moins une fois (requête 2.7).
  Le catalogue semble avoir été extrait à partir des commandes : il ne représente
  probablement pas l'offre complète de la plateforme.