-- =========================
-- SCRIPT DONNÉES DE TEST - Sprint 4
-- Date: 04-03-2026
-- Description: Nouvelles règles de gestion - Plusieurs clients par véhicule
-- Référence: Les données de Sprint 3 sont conservées et augmentées
-- =========================

-- =========================
-- RÉINITIALISATION DES TABLES DE DONNÉES (garde les structures Sprint 3)
-- =========================

-- Vider les réservations anciennes (garde hôtels, véhicules, lieux, distances, config)
DELETE FROM reservation WHERE date_heure_depart >= '2026-03-04';

-- =========================
-- DONNÉES DE TEST SPRINT 4 - 04-03-2026
-- =========================
-- Scénario de test pour les nouvelles règles:
-- 1. Un véhicule peut avoir plusieurs clients à la fois
-- 2. Les clients avec le plus de passagers sont traités en premier
-- 3. Après assignation d'un client, on remplit les places restantes
-- 4. Les clients proches de l'aéroport ont la priorité
-- =========================

-- Données pour tester le groupage de clients dans un même véhicule
-- TOUS LES CLIENTS ARRIVENT À 14:00 LE 04-03-2026
INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
-- Groupe 1: Clients avec beaucoup de passagers (à assigner ensemble)
('Rakoto Jean',1,4,'2026-03-04 14:00:00'),         -- 4 passagers -> Hotel Colbert (15.5 km)
('Randria Marie', 10, 2,'2026-03-04 14:00:00'),      -- 2 passagers -> Hotel Sunny (13.9 km) - peut partager avec Jean (4+2=6)

-- Groupe 2: Client moyen et clients légers
('Andriana Paul', 3, 3, '2026-03-04 11:00:00'),       -- 3 passagers -> Hotel Le Louvre (14.8 km)
('Raja Sophie', 10, 1, '2026-03-04 11:00:00'),        -- 1 passager -> Hotel Sunny (13.9 km) - peut partager avec Paul (3+1=4)
('Rabe Hery', 10, 2, '2026-03-04 11:00:00'),          -- 2 passagers -> Hotel Sunny (13.9 km) - peut partager (3+1+2=6)

-- Groupe 3: Clients avec même hôtel (même destination)
('Razaf Lanto', 2, 2, '2026-03-04 11:30:00'),         -- 2 passagers -> Carlton (16.2 km)
('Andriana Nivo', 2, 1, '2026-03-04 11:30:00'),       -- 1 passager -> Carlton (16.2 km) - destination identique (2+1=3)
('Ramanana Faly', 2, 2, '2026-03-04 11:30:00'),       -- 2 passager -> Carlton (16.2 km) - destination identique (2+1+2=5)

-- Groupe 4: Clients loin de l'aéroport
('Rabeson Tiara', 7, 1, '2026-03-04 11:30:00'),       -- 1 passager -> Belvedere (19.2 km)
('Rafary Jean', 7, 2, '2026-03-04 11:30:00'),         -- 2 passagers -> Belvedere (19.2 km) - même destination (1+2=3)

-- Groupe 5: Clients très proches de l'aéroport
('Rasolofo Manoa', 10, 3, '2026-03-04 15:00:00'),     -- 3 passagers -> Hotel Sunny (13.9 km - le plus proche)
('Randrianampoinimerina Fara', 9, 2, '2026-03-04 15:00:00'), -- 2 passagers -> Hotel Tana Plaza (14.3 km)

-- Groupe 6: Réservation unique importante (peut remplir seule un véhicule)
('Ravelo Stephane', 6, 6, '2026-03-04 15:10:00'),     -- 6 passagers -> Hotel Sakamanga (15.1 km)

-- Groupe 7: Petits clients pour remplissage
('Ryan Justin', 5, 1, '2026-03-04 17:00:00'),         -- 1 passager -> Radisson (16.7 km)
('Rolex Dany', 5, 1, '2026-03-04 17:00:00'),          -- 1 passager -> Radisson (16.7 km)
('Rene Michel', 5, 1, '2026-03-04 17:00:00');
-- =========================
-- EXPLICATIONS DES DONNÉES DE TEST
-- =========================

-- =========================
-- Règles à tester :
-- =========================

-- 1. GROUPAGE PAR NOMBRE DE PASSAGERS
--    Ordre de traitement : 6 passagers (Ravelo) > 4 passagers (Rakoto) > 3 passagers (Andriana, Rasolofo, Rafalimanana)
--    > 2 passagers (Randria, Razaf, Rabeson, Rene...) > 1 passager (Raja, Nivo, Ramanana, Ryan...)

-- 2. GROUPAGE PAR PROXIMITÉ AÉROPORT
--    Après tri par passagers, les clients proches de l'aéroport sont visités en premier :
--    - Hotel Sunny (13.9 km) - le plus proche
--    - Hotel Tana Plaza (14.3 km)
--    - Hotel Le Louvre (14.8 km)
--    - Hotel Colbert (15.5 km)
--    - Hotel Sakamanga (15.1 km)
--    - Hotel Radisson (16.7 km)
--    - Hotel Carlton (16.2 km)
--    - Hotel Belvedere (19.2 km) - le plus loin

-- 3. ASSIGNATION DE VÉHICULES
--    Avec les 7 véhicules disponibles et 15 réservations :
--    - Ravelo (6) peut remplir VH-007 (7 places) = 1 véhicule
--    - Rakoto (4) + Randria (2) = 6 places -> VH-001 ou VH-004 (diesel prioritaire)
--    - Andriana (3) + Raja (1) + Rabe (2) = 6 passagers -> Même véhicule possible
--    - Razaf (2) + Andriana (1) + Ramanana (2) = 5 passagers -> Partage possible (VH-004 ou VH-005)
--    - Rabeson (1) + Rafary (2) = 3 passagers -> VH-006 (3 places)
--    - Rasolofo (3) + Randrianampoinimerina (2) = 5 passagers -> VH-004 ou VH-005
--    - Ryan (1) + Rolex (1) + Rene (1) = 3 passagers -> VH-006 ou autre
--    - Ramamonjisoa (4) -> VH-001, VH-002, VH-004, VH-005
--    - Rafalimanana (3) -> partage possible ou véhicule seul

-- =========================
-- NOTES IMPORTANTES
-- =========================

-- Note 1: TOUS les clients arrivent à la MÊME DATE ET MÊME HEURE (14:00 le 04-03-2026).
--         Cela teste la capacité du système à planifier plusieurs clients simultanément
--         et optimiser l'utilisation des véhicules pour un départ massif de l'aéroport.

-- Note 2: Les hôtels sont choisis pour tester :
--         - Clients avec même destination (Carlton) -> trajet optimisé
--         - Clients clients avec destinations proches (Sunny, Tana Plaza)
--         - Clients loin de l'aéroport (Belvedere, Palissandre)

-- Note 3: Les capacités des véhicules :
--         - VH-001 (4 diesel), VH-002 (4 essence) - Priorité VH-001
--         - VH-003 (2 diesel), VH-004 (5 diesel), VH-005 (5 essence) - Priorité VH-004
--         - VH-006 (3 diesel), VH-007 (7 diesel)

-- Note 4: Avec les 15 réservations et 7 véhicules, environ 7-9 réservations
--         seront assignées selon les capacités et les règles de groupage

-- =========================
-- VÉRIFICATIONS POST-INSERTION
-- =========================

-- Vérifier le nombre de réservations pour le 04-03-2026
SELECT COUNT(*) as 'Nombre de réservations pour 04-03-2026'
FROM reservation 
WHERE DATE(date_heure_depart) = '2026-03-04';

-- Vérifier le nombre total de passagers
SELECT SUM(nb_passager) as 'Total passagers'
FROM reservation 
WHERE DATE(date_heure_depart) = '2026-03-04';

--   SELECT client, nb_passager, (SELECT libelle FROM hotel h WHERE h.id = reservation.id_hotel) as hotel,date_heure_depart FROM reservation WHERE DATE(date_heure_depart) = '2026-03-04' ORDER BY nb_passager DESC, date_heure_depart ASC;

-- =========================
-- FIN SCRIPT SPRINT 4
-- =========================
