-- =========================================================================================
-- SCRIPT DE TEST DES RÈGLES DE GESTION - Sprint 4
-- Date: 11-03-2026
-- Objectif: Valider le bon fonctionnement des règles de planification
-- =========================================================================================

-- =========================================================================================
-- CONTEXTE DES TESTS
-- =========================================================================================
-- Véhicules disponibles (7 au total):
--   VH-001: 4 places, diesel
--   VH-002: 4 places, essence
--   VH-003: 2 places, diesel
--   VH-004: 5 places, diesel
--   VH-005: 5 places, essence
--   VH-006: 3 places, diesel
--   VH-007: 7 places, diesel
-- =========================================================================================

-- Nettoyer les anciennes données de test
DELETE FROM reservation WHERE date_heure_depart >= '2026-03-11';

-- =========================================================================================
-- TEST 1 : RÈGLE 1 - Priorité aux réservations avec le plus de passagers
-- =========================================================================================
-- Objectif: Vérifier que les réservations sont traitées par ordre décroissant de nb_passager
-- Résultat attendu: 
--   - Jean (6 passagers) traité en PREMIER -> VH-007 (7 places)
--   - Paul (5 passagers) traité en DEUXIÈME -> VH-004 (5 places diesel) ou VH-005
--   - Marie (4 passagers) traité en TROISIÈME -> VH-001 (4 places diesel)
-- =========================================================================================

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('Rakoto Jean', 1, 6, '2026-03-11 10:00:00'),      -- 6 passagers -> Priorité 1
('Andriana Paul', 3, 5, '2026-03-11 10:00:00'),    -- 5 passagers -> Priorité 2
('Randria Marie', 2, 4, '2026-03-11 10:00:00');    -- 4 passagers -> Priorité 3

-- VÉRIFICATION TEST 1:
-- Lancer le planning pour la date 2026-03-11
-- Dans l'interface: /planning/result avec datePlanning = 2026-03-11
--
-- RÉSULTAT ATTENDU:
-- VH-007 (7 places): Jean (6 passagers) + 1 place libre
-- VH-004 ou VH-005 (5 places): Paul (5 passagers) + 0 place libre
-- VH-001 (4 places diesel): Marie (4 passagers) + 0 place libre

-- =========================================================================================
-- NETTOYAGE AVANT TEST 2
-- =========================================================================================
DELETE FROM reservation WHERE date_heure_depart >= '2026-03-11';

-- =========================================================================================
-- TEST 2 : RÈGLE 2a - Véhicule avec le nombre de places le plus proche
-- =========================================================================================
-- Objectif: Vérifier que le système choisit le véhicule avec le minimum de places suffisantes
-- Résultat attendu: 
--   - Sophie (2 passagers) -> VH-003 (2 places) et PAS VH-006 (3 places) ni VH-001 (4 places)
--   - Luc (3 passagers) -> VH-006 (3 places) et PAS VH-001 (4 places)
--   - Emma (5 passagers) -> VH-004 (5 places diesel) et PAS VH-007 (7 places)
-- =========================================================================================

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('Raja Sophie', 10, 2, '2026-03-11 11:00:00'),     -- 2 passagers -> VH-003 (2 places exactes)
('Rabe Luc', 5, 3, '2026-03-11 11:00:00'),         -- 3 passagers -> VH-006 (3 places exactes)
('Razaf Emma', 4, 5, '2026-03-11 11:00:00');       -- 5 passagers -> VH-004 ou VH-005 (5 places exactes)

-- VÉRIFICATION TEST 2:
-- RÉSULTAT ATTENDU:
-- VH-004 ou VH-005 (5 places): Emma (5 passagers)    <- Traité en PREMIER (plus de passagers)
-- VH-006 (3 places): Luc (3 passagers)               <- Traité en DEUXIÈME
-- VH-003 (2 places): Sophie (2 passagers)            <- Traité en DERNIER

-- =========================================================================================
-- NETTOYAGE AVANT TEST 3
-- =========================================================================================
DELETE FROM reservation WHERE date_heure_depart >= '2026-03-11';

-- =========================================================================================
-- TEST 3 : RÈGLE 2b - Priorité au diesel si égalité de places
-- =========================================================================================
-- Objectif: Vérifier que si deux véhicules ont le même nombre de places, le diesel est choisi
-- Contexte: VH-001 (4 places diesel) vs VH-002 (4 places essence)
--           VH-004 (5 places diesel) vs VH-005 (5 places essence)
-- Résultat attendu: Les véhicules diesel sont choisis en priorité
-- =========================================================================================

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('Client A', 1, 5, '2026-03-11 12:00:00'),         -- 5 passagers -> VH-004 (diesel) prioritaire
('Client B', 2, 5, '2026-03-11 12:00:00'),         -- 5 passagers -> VH-005 (essence) car VH-004 pris
('Client C', 3, 4, '2026-03-11 12:00:00'),         -- 4 passagers -> VH-001 (diesel) prioritaire
('Client D', 4, 4, '2026-03-11 12:00:00');         -- 4 passagers -> VH-002 (essence) car VH-001 pris

-- VÉRIFICATION TEST 3:
-- RÉSULTAT ATTENDU:
-- VH-004 (5 places diesel): Client A (5 passagers)   <- DIESEL choisi en priorité
-- VH-005 (5 places essence): Client B (5 passagers)  <- Essence car diesel déjà pris
-- VH-001 (4 places diesel): Client C (4 passagers)   <- DIESEL choisi en priorité
-- VH-002 (4 places essence): Client D (4 passagers)  <- Essence car diesel déjà pris

-- =========================================================================================
-- NETTOYAGE AVANT TEST 4
-- =========================================================================================
DELETE FROM reservation WHERE date_heure_depart >= '2026-03-11';

-- =========================================================================================
-- TEST 4 : RÈGLE 3 - Maximisation du véhicule avant de passer au suivant
-- =========================================================================================
-- Objectif: Vérifier que le système remplit au maximum un véhicule avant d'en utiliser un autre
-- Résultat attendu: 
--   - VH-007 doit avoir : Rakoto (4) + Randria (2) + Raja (1) = 7 passagers (PLEIN)
--   - Un seul véhicule utilisé au lieu de trois
-- =========================================================================================

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('Rakoto Tiavo', 1, 4, '2026-03-11 13:00:00'),     -- 4 passagers -> VH-007 commence
('Randria Nivo', 2, 2, '2026-03-11 13:00:00'),     -- 2 passagers -> Ajouté à VH-007 (4+2=6)
('Raja Faly', 3, 1, '2026-03-11 13:00:00');        -- 1 passager  -> Ajouté à VH-007 (6+1=7 PLEIN)

-- VÉRIFICATION TEST 4:
-- RÉSULTAT ATTENDU:
-- VH-007 (7 places): Rakoto (4) + Randria (2) + Raja (1) = 7 passagers
-- Nombre de véhicules utilisés: 1 seul (optimisation maximale)

-- =========================================================================================
-- NETTOYAGE AVANT TEST 5
-- =========================================================================================
DELETE FROM reservation WHERE date_heure_depart >= '2026-03-11';

-- =========================================================================================
-- TEST 5 : COMBINAISON DE TOUTES LES RÈGLES
-- =========================================================================================
-- Objectif: Tester toutes les règles ensemble dans un scénario réaliste complexe
-- =========================================================================================

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
-- Groupe 1: Plus gros groupe (traité en PREMIER)
('Alpha Group', 1, 6, '2026-03-11 14:00:00'),      -- 6 passagers -> VH-007 (7 places)

-- Groupe 2: Groupes moyens
('Beta Team', 2, 5, '2026-03-11 14:00:00'),        -- 5 passagers -> VH-004 (diesel prioritaire)
('Gamma Inc', 3, 4, '2026-03-11 14:00:00'),        -- 4 passagers -> VH-001 (diesel prioritaire)
('Delta Co', 4, 4, '2026-03-11 14:00:00'),         -- 4 passagers -> VH-002 (essence car VH-001 pris)

-- Groupe 3: Petits groupes (doivent remplir VH-007)
('Epsilon SA', 5, 3, '2026-03-11 14:00:00'),       -- 3 passagers -> Candidat pour VH-007 ou VH-006
('Zeta Ltd', 6, 2, '2026-03-11 14:00:00'),         -- 2 passagers -> Candidat pour remplissage
('Eta Partners', 7, 1, '2026-03-11 14:00:00');     -- 1 passager  -> Doit remplir VH-007 (6+1=7)

-- VÉRIFICATION TEST 5:
-- RÉSULTAT ATTENDU (ordre de traitement):
-- 1. Alpha (6) -> VH-007, puis maximisation:
--    - Essai Eta (1) : 6+1=7 ✅ -> VH-007 PLEIN
-- 2. Beta (5) -> VH-004 (diesel prioritaire)
-- 3. Gamma (4) -> VH-001 (diesel prioritaire)
-- 4. Delta (4) -> VH-002 (essence)
-- 5. Epsilon (3) -> VH-006 (3 places exactes)
-- 6. Zeta (2) -> VH-003 (2 places exactes)
--
-- VÉHICULES UTILISÉS: 6 véhicules sur 7
-- VH-007: Alpha (6) + Eta (1) = 7 passagers (PLEIN)
-- VH-004: Beta (5)
-- VH-001: Gamma (4)
-- VH-002: Delta (4)
-- VH-006: Epsilon (3)
-- VH-003: Zeta (2)

-- =========================================================================================
-- NETTOYAGE AVANT TEST 6
-- =========================================================================================
DELETE FROM reservation WHERE date_heure_depart >= '2026-03-11';

-- =========================================================================================
-- TEST 6 : SCÉNARIO DE MAXIMISATION COMPLEXE
-- =========================================================================================
-- Objectif: Tester la maximisation avec plusieurs candidats possibles
-- =========================================================================================

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('Client 1', 1, 4, '2026-03-11 15:00:00'),         -- 4 passagers -> VH-007 (7 places)
('Client 2', 2, 3, '2026-03-11 15:00:00'),         -- 3 passagers -> Peut remplir VH-007 ? NON (4+3=7) -> Priorité
('Client 3', 3, 2, '2026-03-11 15:00:00'),         -- 2 passagers -> Alternative pour VH-007
('Client 4', 4, 1, '2026-03-11 15:00:00');         -- 1 passager  -> Alternative pour VH-007

-- VÉRIFICATION TEST 6:
-- RÉSULTAT ATTENDU (algorithme de maximisation):
-- 1. Client 1 (4) -> VH-007, reste 3 places
-- 2. Maximisation recherche la PLUS GRANDE réservation qui peut entrer:
--    - Client 2 (3) ✅ peut entrer, c'est la plus grande -> Ajouté (4+3=7 PLEIN)
-- 3. Client 3 (2) -> Nouveau véhicule VH-003 (2 places exactes)
-- 4. Client 4 (1) -> Peut remplir VH-003 ? NON (déjà 2+0=2 plein)
--    -> Aucun véhicule disponible, non assigné OU nouveau véhicule
--
-- VH-007: Client 1 (4) + Client 2 (3) = 7 passagers (PLEIN)
-- VH-003: Client 3 (2)
-- VH-006 ou autre: Client 4 (1)

-- =========================================================================================
-- INSTRUCTIONS D'UTILISATION
-- =========================================================================================

-- Pour tester:
-- 1. Exécuter un des blocs de test ci-dessus
-- 2. Aller sur: http://localhost:8080/planning/selection-date
-- 3. Entrer la date: 2026-03-11
-- 4. Valider et observer les résultats
-- 5. Vérifier que les règles sont respectées selon les "RÉSULTAT ATTENDU"

-- Pour voir toutes les réservations de test:
SELECT 
    client, 
    nb_passager, 
    (SELECT nom FROM hotel h WHERE h.id = reservation.id_hotel) as hotel,
    date_heure_depart 
FROM reservation 
WHERE DATE(date_heure_depart) = '2026-03-11' 
ORDER BY nb_passager DESC, date_heure_depart ASC;

-- Pour compter le nombre total de passagers:
SELECT 
    COUNT(*) as nb_reservations,
    SUM(nb_passager) as total_passagers
FROM reservation 
WHERE DATE(date_heure_depart) = '2026-03-11';

-- =========================================================================================
-- FIN DU SCRIPT DE TEST
-- =========================================================================================
