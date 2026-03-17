-- =========================================================================================
-- SCRIPT DE TEST DES RÈGLES DE GESTION - Sprint 4
-- Date: 11-03-2026
-- Objectif: Valider le bon fonctionnement des règles de planification
-- =========================================================================================

-- =========================================================================================
-- CRÉATION DES HÔTELS
-- =========================================================================================
-- IMPORTANT: Exécuter cette section UNE SEULE FOIS pour créer les hôtels
-- Si les hôtels existent déjà, commenter cette section

-- Supprimer les anciens hôtels de test (optionnel - attention aux contraintes FK)
-- DELETE FROM hotel WHERE nom LIKE '%Colbert%' OR nom LIKE '%Carlton%' OR nom LIKE '%Louvre%';

-- Création des 10 hôtels pour les tests
INSERT INTO hotel (nom, adresse) VALUES
('Hotel Colbert Antananarivo', 'Rue Prince Ratsimamanga, Antananarivo'),
('Carlton Madagascar', 'Anosy, Antananarivo'),
('Hotel Le Louvre', 'Lalana Rainandriamampandry, Antananarivo'),
('Palissandre Hotel', 'Ivandry, Antananarivo'),
('Radisson Blu Waterfront', 'Rue Solombavambahoaka, Antananarivo'),
('Hotel Sakamanga', 'Rue Andriandahifotsy, Antananarivo'),
('Hotel Belvedere', 'Route dAnkadimbahoaka, Antananarivo'),
('Hotel La Ribaudiere', 'Route de lUniversite, Antananarivo'),
('Hotel Tana Plaza', 'Avenue de lIndependance, Antananarivo'),
('Hotel Sunny', 'Rue Rainibetsimisaraka, Antananarivo');

-- Vérifier la création des hôtels
SELECT * FROM hotel ORDER BY nom;

-- =========================================================================================
-- CRÉATION DES LIEUX (AÉROPORT + HÔTELS)
-- =========================================================================================
-- IMPORTANT: Exécuter cette section UNE SEULE FOIS pour créer les lieux
-- Si les lieux existent déjà, commenter cette section

-- Supprimer les anciens lieux de test (optionnel - attention aux contraintes FK)
-- DELETE FROM lieu WHERE code IN ('IVATO', 'COLBERT', 'CARLTON', 'LOUVRE', 'PALISSANDRE', 'RADISSON', 'SAKAMANGA', 'BELVEDERE', 'RIBAUDIERE', 'TANAPLAZA', 'SUNNY');

-- Création de l'aéroport
INSERT INTO lieu (code, libelle) VALUES
('IVATO', 'Aéroport International Ivato');

-- Création des lieux correspondant aux hôtels
INSERT INTO lieu (code, libelle) VALUES
('COLBERT', 'Hotel Colbert Antananarivo'),
('CARLTON', 'Carlton Madagascar'),
('LOUVRE', 'Hotel Le Louvre'),
('PALISSANDRE', 'Palissandre Hotel'),
('RADISSON', 'Radisson Blu Waterfront'),
('SAKAMANGA', 'Hotel Sakamanga'),
('BELVEDERE', 'Hotel Belvedere'),
('RIBAUDIERE', 'Hotel La Ribaudiere'),
('TANAPLAZA', 'Hotel Tana Plaza'),
('SUNNY', 'Hotel Sunny');

-- Vérifier la création des lieux
SELECT * FROM lieu ORDER BY code;

-- =========================================================================================
-- CRÉATION DES DISTANCES
-- =========================================================================================
-- IMPORTANT: Exécuter cette section UNE SEULE FOIS pour créer les distances
-- Si les distances existent déjà, commenter cette section

-- Supprimer les anciennes distances de test (optionnel)
-- DELETE FROM distance WHERE from_lieu IN (SELECT id FROM lieu WHERE code IN ('IVATO', 'COLBERT', 'CARLTON', 'LOUVRE', 'PALISSANDRE', 'RADISSON', 'SAKAMANGA', 'BELVEDERE', 'RIBAUDIERE', 'TANAPLAZA', 'SUNNY'));

-- Distances de l'aéroport Ivato vers tous les hôtels
INSERT INTO distance (from_lieu, to_lieu, km) VALUES
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'COLBERT'), 15.5),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'CARLTON'), 16.2),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'LOUVRE'), 14.8),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'PALISSANDRE'), 18.3),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 16.7),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 15.1),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 19.2),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 17.5),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 14.3),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 13.9),

-- Distances entre hôtels (matrice complète)
-- COLBERT vers autres hôtels
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'CARLTON'), 3.5),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'LOUVRE'), 2.1),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'PALISSANDRE'), 5.8),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 4.2),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 2.8),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 6.3),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 4.9),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 1.7),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 2.3),

-- CARLTON vers autres hôtels (sauf COLBERT déjà fait)
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'LOUVRE'), 2.9),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'PALISSANDRE'), 6.1),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 1.8),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 3.2),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 7.1),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 5.3),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 2.6),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 3.8),

-- LOUVRE vers autres hôtels (sauf COLBERT, CARLTON déjà faits)
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'PALISSANDRE'), 4.7),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 3.1),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 1.5),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 5.9),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 4.2),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 1.9),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 1.2),

-- PALISSANDRE vers autres hôtels (sauf précédents)
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 4.8),
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 5.3),
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 3.2),
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 2.1),
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 6.5),
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 6.9),

-- RADISSON vers autres hôtels (sauf précédents)
((SELECT id FROM lieu WHERE code = 'RADISSON'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 3.7),
((SELECT id FROM lieu WHERE code = 'RADISSON'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 6.4),
((SELECT id FROM lieu WHERE code = 'RADISSON'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 4.7),
((SELECT id FROM lieu WHERE code = 'RADISSON'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 3.1),
((SELECT id FROM lieu WHERE code = 'RADISSON'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 4.2),

-- SAKAMANGA vers autres hôtels (sauf précédents)
((SELECT id FROM lieu WHERE code = 'SAKAMANGA'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 5.8),
((SELECT id FROM lieu WHERE code = 'SAKAMANGA'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 3.9),
((SELECT id FROM lieu WHERE code = 'SAKAMANGA'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 2.2),
((SELECT id FROM lieu WHERE code = 'SAKAMANGA'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 1.8),

-- BELVEDERE vers autres hôtels (sauf précédents)
((SELECT id FROM lieu WHERE code = 'BELVEDERE'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 2.8),
((SELECT id FROM lieu WHERE code = 'BELVEDERE'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 7.2),
((SELECT id FROM lieu WHERE code = 'BELVEDERE'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 7.6),

-- RIBAUDIERE vers autres hôtels (sauf précédents)
((SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 5.4),
((SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 5.9),

-- TANAPLAZA vers dernier hôtel
((SELECT id FROM lieu WHERE code = 'TANAPLAZA'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 0.9);

-- Vérifier la création des distances
SELECT 
    ld.libelle as depart, 
    la.libelle as arrivee, 
    d.km as distance_km
FROM distance d
JOIN lieu ld ON d.from_lieu = ld.id
JOIN lieu la ON d.to_lieu = la.id
ORDER BY depart, arrivee;

-- =========================================================================================
-- CRÉATION DES VÉHICULES DE TEST
-- =========================================================================================
-- IMPORTANT: Exécuter ce script UNE SEULE FOIS pour créer les véhicules
-- Si les véhicules existent déjà, commenter cette section

-- Supprimer les anciens véhicules de test (optionnel - attention aux contraintes FK)
-- DELETE FROM vehicule WHERE reference LIKE 'VH-%';

-- Création des 7 véhicules pour les tests
INSERT INTO vehicule (reference, place, type_carburant) VALUES
('VH-001', 4, 'diesel'),     -- 4 places diesel
('VH-002', 4, 'essence'),    -- 4 places essence (moins prioritaire que VH-001)
('VH-003', 2, 'diesel'),     -- 2 places diesel
('VH-004', 5, 'diesel'),     -- 5 places diesel
('VH-005', 5, 'essence'),    -- 5 places essence (moins prioritaire que VH-004)
('VH-006', 3, 'diesel'),     -- 3 places diesel
('VH-007', 7, 'diesel');     -- 7 places diesel (pour grands groupes)

-- Vérifier la création des véhicules
SELECT * FROM vehicule WHERE reference LIKE 'VH-%' ORDER BY reference;

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



-------------
INSERT INTO vehicule (reference, place, type_carburant) VALUES
('Vehicule001', 12, 'diesel'),     -- 4 places diesel
('Vehicule002', 5, 'essence'),    -- 4 places essence (moins prioritaire que Vehicule001)
('Vehicule003', 5, 'diesel'),     -- 2 places diesel
('Vehicule004', 12, 'essence'),     -- 5 places diesel


INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('Client1', 2, 7, '2026-03-12 09:00:00'),      -- 6 passagers -> Priorité 1
('Client2', 2, 11, '2026-03-12 09:00:00'),    -- 5 passagers -> Priorité 2
('Client3', 2, 3, '2026-03-12 09:00:00'),      -- 6 passagers -> Priorité 1
('Client4', 2, 1, '2026-03-12 09:00:00'),      -- 6 passagers -> Priorité 1
('Client5', 2, 2, '2026-03-12 09:00:00'),      -- 6 passagers -> Priorité 1
('Client6', 2, 20, '2026-03-12 09:00:00'),      -- 6 passagers -> Priorité 1


INSERT INTO lieu (code, libelle) VALUES
('IVATO', 'Aéroport International Ivato');

-- Création des lieux correspondant aux hôtels
INSERT INTO lieu (code, libelle) VALUES
('COLBERT', 'Hotel1'),
