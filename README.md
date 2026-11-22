# Olist SQL Warehouse

Projet personnel de data engineering en SQL Server : transformer les données brutes
d'un site e-commerce brésilien (Olist, ~100 000 commandes) en entrepôt analytique.

## Objectifs
- Charger les données brutes (schéma `stg`)
- Contrôler la qualité des données
- Construire un modèle en étoile (schéma `dwh`)
- Historiser les clients en SCD2
- Répondre à des questions métier avec des CTE et des fonctions de fenêtrage
- Optimiser les requêtes (plans d'exécution, index)

## Stack
SQL Server 2025 Developer · SSMS 22 · Git

## Avancement
- [x] Setup de la base
- [ ] Chargement des données
- [ ] Qualité des données
- [ ] Modèle en étoile
- [ ] SCD2
- [ ] Analyses
- [ ] Optimisation

## Données
[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)