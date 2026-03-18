-- =========================
-- SCRIPT RESET + NOUVELLES DONNEES
-- Date: 18-03-2026
-- Description: Vide puis reinjecte des donnees de test coherentes
-- Tables: hotel, vehicule, reservation, lieu, distance, planning_config
-- =========================

-- =========================
-- ETAPE 1: RESET DES DONNEES
-- =========================
TRUNCATE TABLE hotel RESTART IDENTITY CASCADE;
TRUNCATE TABLE reservation RESTART IDENTITY CASCADE;

TRUNCATE TABLE vehicule RESTART IDENTITY CASCADE;
TRUNCATE TABLE lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE planning_config RESTART IDENTITY CASCADE;

-- =========================
-- ETAPE 2: HOTELS
-- =========================

INSERT INTO hotel (nom, adresse) VALUES
('Hotel Colbert Antananarivo', 'Rue Prince Ratsimamanga, Antananarivo'),
('Carlton Madagascar', 'Anosy, Antananarivo'),
('Hotel Le Louvre', 'Lalana Rainandriamampandry, Antananarivo'),
('Palissandre Hotel', 'Faravohitra, Antananarivo'),
('Radisson Blu Waterfront', 'Ambodivona, Antananarivo'),
('Hotel Sakamanga', 'Rue Andriandahifotsy, Antananarivo'),
('Hotel Sunny', 'Rue Rainibetsimisaraka, Antananarivo');

-- =========================
-- ETAPE 3: LIEUX
-- =========================

INSERT INTO lieu (code, libelle) VALUES
('IVATO', 'Aeroport International Ivato'),
('COLBERT', 'Hotel Colbert Antananarivo'),
('CARLTON', 'Carlton Madagascar'),
('LOUVRE', 'Hotel Le Louvre'),
('PALISSANDRE', 'Palissandre Hotel'),
('RADISSON', 'Radisson Blu Waterfront'),
('SAKAMANGA', 'Hotel Sakamanga'),
('SUNNY', 'Hotel Sunny');

-- =========================
-- ETAPE 4: DISTANCES
-- Regle: un seul sens par paire (pas de doublons symetriques)
-- =========================

INSERT INTO distance (from_lieu, to_lieu, km) VALUES
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'COLBERT'), 18.0),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'CARLTON'), 16.0),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'LOUVRE'), 19.0),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'PALISSANDRE'), 14.0),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 13.0),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 17.0),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 21.0),

((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'CARLTON'), 5.0),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'LOUVRE'), 3.0),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'PALISSANDRE'), 6.0),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 7.0),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 4.0),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 6.0),

((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'LOUVRE'), 4.0),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'PALISSANDRE'), 6.0),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 5.0),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 7.0),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 8.0),

((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'PALISSANDRE'), 5.0),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 6.0),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 5.0),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 7.0),

((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 4.0),
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 6.0),
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 9.0),

((SELECT id FROM lieu WHERE code = 'RADISSON'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 6.0),
((SELECT id FROM lieu WHERE code = 'RADISSON'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 8.0),

((SELECT id FROM lieu WHERE code = 'SAKAMANGA'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 5.0);

-- =========================
-- ETAPE 5: CONFIG PLANIFICATION
-- =========================

INSERT INTO planning_config (vitesse_moyenne, temps_attente, is_active) VALUES
(35.0, 30, true);

-- =========================
-- ETAPE 6: VEHICULES
-- =========================

INSERT INTO vehicule (reference, place, type_carburant) VALUES
('VH-101', 12, 'diesel'),
('VH-102', 10, 'diesel'),
('VH-103', 8, 'essence'),
('VH-104', 6, 'diesel'),
('VH-105', 4, 'essence'),
('VH-106', 4, 'diesel');

-- =========================
-- ETAPE 7: RESERVATIONS
-- =========================

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('CL-2026-001', (SELECT id FROM hotel WHERE nom = 'Hotel Colbert Antananarivo' LIMIT 1), 3, '2026-03-24 08:10:00'),
('CL-2026-002', (SELECT id FROM hotel WHERE nom = 'Carlton Madagascar' LIMIT 1), 11, '2026-03-24 08:20:00'),
('CL-2026-003', (SELECT id FROM hotel WHERE nom = 'Hotel Le Louvre' LIMIT 1), 2, '2026-03-24 08:15:00'),
('CL-2026-004', (SELECT id FROM hotel WHERE nom = 'Palissandre Hotel' LIMIT 1), 4, '2026-03-24 09:05:00'),
('CL-2026-005', (SELECT id FROM hotel WHERE nom = 'Radisson Blu Waterfront' LIMIT 1), 1, '2026-03-24 09:25:00'),
('CL-2026-006', (SELECT id FROM hotel WHERE nom = 'Hotel Sakamanga' LIMIT 1), 7, '2026-03-24 10:00:00'),
('CL-2026-007', (SELECT id FROM hotel WHERE nom = 'Hotel Sunny' LIMIT 1), 5, '2026-03-24 10:20:00'),
('CL-2026-008', (SELECT id FROM hotel WHERE nom = 'Hotel Colbert Antananarivo' LIMIT 1), 9, '2026-03-24 11:00:00'),
('CL-2026-009', (SELECT id FROM hotel WHERE nom = 'Carlton Madagascar' LIMIT 1), 2, '2026-03-24 11:10:00'),
('CL-2026-010', (SELECT id FROM hotel WHERE nom = 'Hotel Le Louvre' LIMIT 1), 6, '2026-03-24 11:30:00'),
('CL-2026-011', (SELECT id FROM hotel WHERE nom = 'Radisson Blu Waterfront' LIMIT 1), 13, '2026-03-24 12:00:00'),
('CL-2026-012', (SELECT id FROM hotel WHERE nom = 'Hotel Sunny' LIMIT 1), 2, '2026-03-24 12:20:00');

-- =========================
-- VERIFICATIONS RAPIDES
-- =========================

SELECT 'hotel' AS table_name, COUNT(*) AS nombre_lignes FROM hotel
UNION ALL
SELECT 'lieu', COUNT(*) FROM lieu
UNION ALL
SELECT 'distance', COUNT(*) FROM distance
UNION ALL
SELECT 'vehicule', COUNT(*) FROM vehicule
UNION ALL
SELECT 'reservation', COUNT(*) FROM reservation
UNION ALL
SELECT 'planning_config', COUNT(*) FROM planning_config;

SELECT id, client, id_hotel, nb_passager, date_heure_depart
FROM reservation
ORDER BY date_heure_depart, id;

-- =========================
-- FIN DU SCRIPT
-- =========================
