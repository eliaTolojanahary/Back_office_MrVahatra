-- =========================================================================================
-- SCRIPT DE TEST DES RÈGLES DE GESTION - Sprint 6
-- Date: 17-03-2026
-- Objectif:
--   1) Tester chaque règle de gestion individuellement
--   2) Tester toutes les règles combinées dans un scénario final
-- =========================================================================================

-- =========================================================================================
-- PRÉREQUIS
-- =========================================================================================
-- Ce script suppose que les tables suivantes existent déjà:
--   reservation, vehicule, lieu, planning_config
--
-- Il suppose aussi qu'un lieu avec code = 'IVATO' existe.
-- Sinon, créer ce lieu avant les tests.

-- =========================================================================================
-- MISE A JOUR DU SCHEMA
-- =========================================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vehicule' AND column_name = 'heure_disponibilite') THEN
        ALTER TABLE vehicule ADD COLUMN heure_disponibilite TIME;
    END IF;
END $$;

-- =========================================================================================
-- CONFIGURATION ACTIVE DU PLANNING (TEMPS D'ATTENTE = 30 MIN)
-- =========================================================================================
UPDATE planning_config SET is_active = false WHERE is_active = true;

INSERT INTO planning_config (vitesse_moyenne, temps_attente, is_active)
VALUES (40.0, 30, true);

-- Vérification config active
SELECT id, vitesse_moyenne, temps_attente, is_active, date_creation
FROM planning_config
WHERE is_active = true
ORDER BY date_creation DESC
LIMIT 1;

-- =========================================================================================
-- FLOTTE DE TEST SPRINT 6 (OPTIONNEL MAIS RECOMMANDÉ)
-- =========================================================================================
-- On crée une flotte dédiée pour rendre les tests reproductibles.
-- Si vous voulez garder vos véhicules existants, commentez ce bloc.

DELETE FROM vehicule WHERE reference LIKE 'S6-VH-%';

INSERT INTO vehicule (reference, place, type_carburant, heure_disponibilite) VALUES
('S6-VH-001', 2, 'diesel', '08:00:00'),
('S6-VH-002', 3, 'diesel', '08:00:00'),
('S6-VH-003', 4, 'diesel', '08:00:00'),
('S6-VH-004', 4, 'essence', '08:00:00'),
('S6-VH-005', 5, 'diesel', '08:00:00'),
('S6-VH-006', 5, 'essence', '08:00:00'),
('S6-VH-007', 7, 'diesel', '08:00:00');

SELECT * FROM vehicule WHERE reference LIKE 'S6-VH-%' ORDER BY reference;

-- =========================================================================================
-- AIDE: IDS DES LIEUX HÔTELS
-- =========================================================================================
-- Les réservations utilisent id_hotel. Dans votre code, la jointure se fait avec table lieu.
-- Utiliser les sous-requêtes ci-dessous évite les erreurs d'ID en dur.

-- Exemples utiles:

INSERT INTO lieu (code, libelle) VALUES 
('IVATO', 'Aéroport International Ivato'),
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
-- (SELECT id FROM lieu WHERE code = 'COLBERT')
-- (SELECT id FROM lieu WHERE code = 'CARLTON')
-- (SELECT id FROM lieu WHERE code = 'LOUVRE')
-- (SELECT id FROM lieu WHERE code = 'RADISSON')
-- (SELECT id FROM lieu WHERE code = 'SAKAMANGA')
-- (SELECT id FROM lieu WHERE code = 'SUNNY')

-- =========================================================================================
-- BASE DE NETTOYAGE COMMUNE SPRINT 6
-- =========================================================================================
DELETE FROM reservation WHERE DATE(date_heure_depart) BETWEEN '2026-03-17' AND '2026-03-23';

-- =========================================================================================
-- TEST 1 : RÈGLE - PRIORITÉ AU PLUS GRAND NOMBRE DE PASSAGERS
-- =========================================================================================
-- Date test: 2026-03-17
-- Attendu: traitement des réservations par nb_passager DESC

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('S6-T1-Client-6P', (SELECT id FROM lieu WHERE code = 'COLBERT'), 1, '2026-03-17 09:00:00'),
('S6-T1-Client-6P', (SELECT id FROM lieu WHERE code = 'COLBERT'), 6, '2026-03-17 09:00:00'),
('S6-T1-Client-4P', (SELECT id FROM lieu WHERE code = 'CARLTON'), 4, '2026-03-17 09:00:00'),
('S6-T1-Client-2P', (SELECT id FROM lieu WHERE code = 'LOUVRE'), 2, '2026-03-17 09:00:00');

-- Vérif données test 1
SELECT client, nb_passager, date_heure_depart
FROM reservation
WHERE DATE(date_heure_depart) = '2026-03-17'
ORDER BY nb_passager DESC, date_heure_depart ASC;

-- =========================================================================================
-- NETTOYAGE AVANT TEST 2
-- =========================================================================================
DELETE FROM reservation WHERE DATE(date_heure_depart) = '2026-03-17';

-- =========================================================================================
-- TEST 2 : RÈGLE - VÉHICULE LE PLUS PROCHE EN CAPACITÉ (MIN >= DEMANDE)
-- =========================================================================================
-- Date test: 2026-03-18
-- Attendu:
--   2 passagers -> véhicule 2 places
--   3 passagers -> véhicule 3 places
--   5 passagers -> véhicule 5 places

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('S6-T2-Client-2P', (SELECT id FROM lieu WHERE code = 'SUNNY'), 2, '2026-03-18 10:00:00'),
('S6-T2-Client-3P', (SELECT id FROM lieu WHERE code = 'RADISSON'), 3, '2026-03-18 10:00:00'),
('S6-T2-Client-5P', (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 5, '2026-03-18 10:00:00');

SELECT client, nb_passager, date_heure_depart
FROM reservation
WHERE DATE(date_heure_depart) = '2026-03-18'
ORDER BY nb_passager DESC, date_heure_depart ASC;

-- =========================================================================================
-- NETTOYAGE AVANT TEST 3
-- =========================================================================================
DELETE FROM reservation WHERE DATE(date_heure_depart) = '2026-03-18';

-- =========================================================================================
-- TEST 3 : RÈGLE - PRIORITÉ DIESEL SI MÊME NOMBRE DE PLACES
-- =========================================================================================
-- Date test: 2026-03-19
-- Attendu: pour 4 places => diesel avant essence ; pour 5 places idem

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('S6-T3-Client-5P-A', (SELECT id FROM lieu WHERE code = 'COLBERT'), 5, '2026-03-19 11:00:00'),
('S6-T3-Client-5P-B', (SELECT id FROM lieu WHERE code = 'CARLTON'), 5, '2026-03-19 11:00:00'),
('S6-T3-Client-4P-A', (SELECT id FROM lieu WHERE code = 'LOUVRE'), 4, '2026-03-19 11:00:00'),
('S6-T3-Client-4P-B', (SELECT id FROM lieu WHERE code = 'SUNNY'), 4, '2026-03-19 11:00:00');

SELECT client, nb_passager, date_heure_depart
FROM reservation
WHERE DATE(date_heure_depart) = '2026-03-19'
ORDER BY nb_passager DESC, client ASC;

-- =========================================================================================
-- NETTOYAGE AVANT TEST 4
-- =========================================================================================
DELETE FROM reservation WHERE DATE(date_heure_depart) = '2026-03-19';

-- =========================================================================================
-- TEST 4 : RÈGLE - MAXIMISER UN VÉHICULE AVANT D'EN OUVRIR UN AUTRE
-- =========================================================================================
-- Date test: 2026-03-20
-- Attendu: combinaison optimale de passagers pour remplir au mieux un véhicule

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('S6-T4-Client-4P', (SELECT id FROM lieu WHERE code = 'COLBERT'), 4, '2026-03-20 12:00:00'),
('S6-T4-Client-2P', (SELECT id FROM lieu WHERE code = 'CARLTON'), 2, '2026-03-20 12:00:00'),
('S6-T4-Client-1P', (SELECT id FROM lieu WHERE code = 'LOUVRE'), 1, '2026-03-20 12:00:00');

SELECT client, nb_passager, date_heure_depart
FROM reservation
WHERE DATE(date_heure_depart) = '2026-03-20'
ORDER BY nb_passager DESC, client ASC;

-- =========================================================================================
-- NETTOYAGE AVANT TEST 5
-- =========================================================================================
DELETE FROM reservation WHERE DATE(date_heure_depart) = '2026-03-20';

-- =========================================================================================
-- TEST 5 : RÈGLE - REGROUPEMENT PAR FENÊTRE TEMPORELLE (temps_attente = 30min)
-- =========================================================================================
-- Date test: 2026-03-21
-- Attendu côté page réservation:
--   Créneau 08:00-08:30 -> 2 réservations
--   Créneau 08:30-09:00 -> 2 réservations
--   Créneau 09:00-09:30 -> 1 réservation

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('S6-T5-Client-A', (SELECT id FROM lieu WHERE code = 'COLBERT'), 2, '2026-03-21 08:05:00'),
('S6-T5-Client-B', (SELECT id FROM lieu WHERE code = 'CARLTON'), 1, '2026-03-21 08:20:00'),
('S6-T5-Client-C', (SELECT id FROM lieu WHERE code = 'LOUVRE'), 3, '2026-03-21 08:35:00'),
('S6-T5-Client-D', (SELECT id FROM lieu WHERE code = 'RADISSON'), 2, '2026-03-21 08:55:00'),
('S6-T5-Client-E', (SELECT id FROM lieu WHERE code = 'SUNNY'), 4, '2026-03-21 09:10:00');

SELECT client, nb_passager, date_heure_depart
FROM reservation
WHERE DATE(date_heure_depart) = '2026-03-21'
ORDER BY date_heure_depart ASC;

-- =========================================================================================
-- NETTOYAGE AVANT TEST 6
-- =========================================================================================
DELETE FROM reservation WHERE DATE(date_heure_depart) = '2026-03-21';

-- =========================================================================================
-- TEST 6 : RÈGLE - RÉUTILISATION D'UN VÉHICULE APRÈS RETOUR À L'AÉROPORT
-- =========================================================================================
-- Date test: 2026-03-22
-- Attendu: un véhicule déjà utilisé peut reprendre une réservation plus tard
--          s'il est revenu avant l'heure de la nouvelle réservation.

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
-- Rotation 1
('S6-T6-Trip1-A', (SELECT id FROM lieu WHERE code = 'COLBERT'), 2, '2026-03-22 08:00:00'),
('S6-T6-Trip1-B', (SELECT id FROM lieu WHERE code = 'LOUVRE'), 1, '2026-03-22 08:10:00'),

-- Rotation 2 (plus tard)
('S6-T6-Trip2-A', (SELECT id FROM lieu WHERE code = 'SUNNY'), 2, '2026-03-22 10:30:00'),
('S6-T6-Trip2-B', (SELECT id FROM lieu WHERE code = 'CARLTON'), 1, '2026-03-22 10:40:00');

SELECT client, nb_passager, date_heure_depart
FROM reservation
WHERE DATE(date_heure_depart) = '2026-03-22'
ORDER BY date_heure_depart ASC;

-- =========================================================================================
-- NETTOYAGE AVANT TEST FINAL
-- =========================================================================================
DELETE FROM reservation WHERE DATE(date_heure_depart) = '2026-03-22';

-- =========================================================================================
-- TEST FINAL : TOUTES LES RÈGLES COMBINÉES
-- =========================================================================================
-- Date test: 2026-03-23
-- Règles combinées:
--   - Priorité nb_passager DESC
--   - Capacité minimale suffisante
--   - Priorité diesel si égalité
--   - Maximisation du véhicule
--   - Fenêtres temporelles de 30 min
--   - Réutilisation après retour

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
-- Fenêtre 08:00-08:30
('S6-FINAL-A', (SELECT id FROM lieu WHERE code = 'COLBERT'), 6, '2026-03-23 08:00:00'),
('S6-FINAL-B', (SELECT id FROM lieu WHERE code = 'CARLTON'), 1, '2026-03-23 08:10:00'),
('S6-FINAL-C', (SELECT id FROM lieu WHERE code = 'LOUVRE'), 4, '2026-03-23 08:15:00'),

-- Fenêtre 08:30-09:00
('S6-FINAL-D', (SELECT id FROM lieu WHERE code = 'RADISSON'), 5, '2026-03-23 08:35:00'),
('S6-FINAL-E', (SELECT id FROM lieu WHERE code = 'SUNNY'), 2, '2026-03-23 08:50:00'),

-- Fenêtre 10:30-11:00 (candidats réutilisation)
('S6-FINAL-F', (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 3, '2026-03-23 10:30:00'),
('S6-FINAL-G', (SELECT id FROM lieu WHERE code = 'COLBERT'), 2, '2026-03-23 10:45:00'),

-- Fenêtre 11:00-11:30
('S6-FINAL-H', (SELECT id FROM lieu WHERE code = 'CARLTON'), 4, '2026-03-23 11:05:00');

SELECT client, nb_passager, date_heure_depart
FROM reservation
WHERE DATE(date_heure_depart) = '2026-03-23'
ORDER BY date_heure_depart ASC, nb_passager DESC;

-- =========================================================================================
-- INSTRUCTIONS D'EXÉCUTION / VÉRIFICATION
-- =========================================================================================
-- 1) Exécuter un bloc de test (ou tout le script)
-- 2) Aller sur /planning/selection-date
-- 3) Tester la date correspondante
-- 4) Vérifier:
--    - /planning/reservations-by-date : affichage par créneaux de temps d'attente
--    - /planning/result : affectation selon règles métier
--
-- Conseil:
--   Exécuter chaque test séparément pour lire plus facilement les résultats UI.

-- =========================================================================================
-- FIN SCRIPT SPRINT 6
-- =========================================================================================
