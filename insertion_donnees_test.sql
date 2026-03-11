-- =========================
-- SCRIPT D'INSERTION DE DONNÉES DE TEST
-- Date: 11-03-2026
-- Description: Insertion de données pour tester le système de planification
-- Basé sur: 02-03-2026-reinitialisation.sql (adapté à la structure Sprint 3/4)
-- =========================

-- =========================
-- INSERTION HÔTELS
-- =========================
-- Note: L'aéroport est géré dans la table 'lieu' avec le code 'IVATO'

INSERT INTO hotel (nom, adresse) VALUES
('Aéroport de Madagascar', 'Ivato, Antananarivo'),
('Hotel Ibis', 'Centre-ville, Antananarivo'),
('Hotel du Louvre', 'Lalana Rainandriamampandry, Antananarivo'),
('Hotel Carlton', 'Anosy, Antananarivo'),
('Hotel Colbert', 'Rue Prince Ratsimamanga, Antananarivo');

-- =========================
-- INSERTION LIEUX
-- =========================

INSERT INTO lieu (code, libelle) VALUES
('IVATO', 'Aéroport International Ivato'),
('IBIS', 'Hotel Ibis'),
('LOUVRE', 'Hotel du Louvre'),
('CARLTON', 'Hotel Carlton'),
('COLBERT', 'Hotel Colbert');

-- =========================
-- INSERTION DISTANCES
-- =========================
-- Distances de l'aéroport vers les hôtels

INSERT INTO distance (from_lieu, to_lieu, km) VALUES
-- Aéroport -> Hôtels
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'IBIS'), 15.00),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'LOUVRE'), 20.00),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'CARLTON'), 25.00),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'COLBERT'), 20.00),

-- Distances entre hôtels
((SELECT id FROM lieu WHERE code = 'IBIS'), (SELECT id FROM lieu WHERE code = 'LOUVRE'), 8.00),
((SELECT id FROM lieu WHERE code = 'IBIS'), (SELECT id FROM lieu WHERE code = 'COLBERT'), 12.00),
((SELECT id FROM lieu WHERE code = 'IBIS'), (SELECT id FROM lieu WHERE code = 'CARLTON'), 15.00),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'COLBERT'), 7.00),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'CARLTON'), 10.00),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'CARLTON'), 6.00);

-- =========================
-- INSERTION PARAMÈTRES DE PLANIFICATION
-- =========================

INSERT INTO planning_config (vitesse_moyenne, temps_attente, is_active) VALUES
(30.00, 30, true);

-- =========================
-- INSERTION VÉHICULES
-- =========================

INSERT INTO vehicule (reference, place, type_carburant) VALUES
('VH-001', 10, 'diesel'),
('VH-002', 10, 'essence'),
('VH-003', 5,  'diesel'),
('VH-004', 11, 'diesel'),
('VH-005', 4,  'essence');

-- =========================
-- INSERTION RÉSERVATIONS
-- =========================
-- Scénario de test: plusieurs clients le même jour avec des heures différentes
-- pour tester le groupage de clients dans les véhicules

-- Date: 2026-03-15
INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('Client C001', (SELECT id FROM hotel WHERE nom LIKE '%Ibis%' LIMIT 1), 8, '2026-03-15 08:00:00'),
('Client C002', (SELECT id FROM hotel WHERE nom LIKE '%Louvre%' LIMIT 1), 4, '2026-03-15 08:15:00'),
('Client C004', (SELECT id FROM hotel WHERE nom LIKE '%Colbert%' LIMIT 1), 11, '2026-03-15 08:30:00'),
('Client C003', (SELECT id FROM hotel WHERE nom LIKE '%Carlton%' LIMIT 1), 2, '2026-03-15 09:00:00'),
('Client C005', (SELECT id FROM hotel WHERE nom LIKE '%Ibis%' LIMIT 1), 3, '2026-03-16 10:00:00');

-- =========================
-- VÉRIFICATIONS POST-INSERTION
-- =========================

-- Vérifier le nombre d'hôtels
SELECT COUNT(*) as 'Nombre d_hotels' FROM hotel;

-- Vérifier le nombre de lieux
SELECT COUNT(*) as 'Nombre de lieux' FROM lieu;

-- Vérifier le nombre de véhicules
SELECT COUNT(*) as 'Nombre de vehicules' FROM vehicule;

-- Vérifier le nombre de réservations
SELECT COUNT(*) as 'Nombre de reservations' FROM reservation;

-- Vérifier le nombre de distances
SELECT COUNT(*) as 'Nombre de distances' FROM distance;

-- Vérifier la configuration active
SELECT * FROM planning_config WHERE is_active = true;

-- Afficher les réservations du 15-03-2026
SELECT 
    r.id,
    r.client,
    r.nb_passager,
    h.nom as hotel,
    r.date_heure_depart
FROM reservation r
JOIN hotel h ON r.id_hotel = h.id
WHERE DATE(r.date_heure_depart) = '2026-03-15'
ORDER BY r.date_heure_depart;

-- =========================
-- FIN DU SCRIPT D'INSERTION
-- =========================
