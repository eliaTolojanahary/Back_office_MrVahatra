-- =========================================================
-- TEST PARTIE 2: REASSIGNATION VERS PROCHAINE VRAIE RESERVATION
-- Date de test: 2026-03-26
-- Objectif:
--   - Un creneau du matin avec reservation non assignee
--   - Aucun creneau intermediaire rempli
--   - Report direct vers le prochain creneau reel (12:00)
-- =========================================================

-- 1) Configuration active
UPDATE planning_config SET is_active = false WHERE is_active = true;
INSERT INTO planning_config (vitesse_moyenne, temps_attente, is_active)
VALUES (35.0, 30, true);

-- 2) Hotels
INSERT INTO hotel (nom, adresse)
SELECT 'Hotel Colbert Antananarivo', 'Antananarivo'
WHERE NOT EXISTS (SELECT 1 FROM hotel WHERE nom = 'Hotel Colbert Antananarivo');

INSERT INTO hotel (nom, adresse)
SELECT 'Carlton Madagascar', 'Antananarivo'
WHERE NOT EXISTS (SELECT 1 FROM hotel WHERE nom = 'Carlton Madagascar');

INSERT INTO hotel (nom, adresse)
SELECT 'Hotel Le Louvre', 'Antananarivo'
WHERE NOT EXISTS (SELECT 1 FROM hotel WHERE nom = 'Hotel Le Louvre');

-- 3) Lieux
INSERT INTO lieu (code, libelle)
SELECT 'IVATO', 'Aeroport International Ivato'
WHERE NOT EXISTS (SELECT 1 FROM lieu WHERE code = 'IVATO');

INSERT INTO lieu (code, libelle)
SELECT 'COLBERT', 'Hotel Colbert Antananarivo'
WHERE NOT EXISTS (SELECT 1 FROM lieu WHERE code = 'COLBERT');

INSERT INTO lieu (code, libelle)
SELECT 'CARLTON', 'Carlton Madagascar'
WHERE NOT EXISTS (SELECT 1 FROM lieu WHERE code = 'CARLTON');

INSERT INTO lieu (code, libelle)
SELECT 'LOUVRE', 'Hotel Le Louvre'
WHERE NOT EXISTS (SELECT 1 FROM lieu WHERE code = 'LOUVRE');

-- 4) Distances
INSERT INTO distance (from_lieu, to_lieu, km)
SELECT (SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'COLBERT'), 18.0
WHERE NOT EXISTS (
    SELECT 1 FROM distance
    WHERE from_lieu = (SELECT id FROM lieu WHERE code = 'IVATO')
      AND to_lieu = (SELECT id FROM lieu WHERE code = 'COLBERT')
);

INSERT INTO distance (from_lieu, to_lieu, km)
SELECT (SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'CARLTON'), 16.0
WHERE NOT EXISTS (
    SELECT 1 FROM distance
    WHERE from_lieu = (SELECT id FROM lieu WHERE code = 'IVATO')
      AND to_lieu = (SELECT id FROM lieu WHERE code = 'CARLTON')
);

INSERT INTO distance (from_lieu, to_lieu, km)
SELECT (SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'LOUVRE'), 19.0
WHERE NOT EXISTS (
    SELECT 1 FROM distance
    WHERE from_lieu = (SELECT id FROM lieu WHERE code = 'IVATO')
      AND to_lieu = (SELECT id FROM lieu WHERE code = 'LOUVRE')
);

-- 5) Vehicules limites pour forcer non-assignation le matin
TRUNCATE TABLE vehicule RESTART IDENTITY CASCADE;
INSERT INTO vehicule (reference, place, type_carburant) VALUES
('P2-VH-01', 5, 'diesel'),
('P2-VH-02', 4, 'essence');

-- 6) Reservations
DELETE FROM reservation WHERE DATE(date_heure_depart) = '2026-03-26';

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('P2-R1-08h00', (SELECT id FROM hotel WHERE nom = 'Hotel Colbert Antananarivo' LIMIT 1), 4, '2026-03-26 08:00:00'),
('P2-R2-08h10-NonAssigneePotentielle', (SELECT id FROM hotel WHERE nom = 'Carlton Madagascar' LIMIT 1), 7, '2026-03-26 08:10:00'),
('P2-R3-12h00-ProchainCreneauReel', (SELECT id FROM hotel WHERE nom = 'Hotel Le Louvre' LIMIT 1), 3, '2026-03-26 12:00:00');

SELECT id, client, nb_passager, date_heure_depart
FROM reservation
WHERE DATE(date_heure_depart) = '2026-03-26'
ORDER BY date_heure_depart, id;

-- Attendu metier:
-- - Reservation non assignee du matin reportee vers 12:00
-- - Pas de tentative sur creneaux vides 08:30, 09:00, 09:30, etc.
