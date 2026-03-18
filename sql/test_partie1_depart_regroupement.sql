-- =============================================
-- TEST PARTIE 1: HEURE DE DEPART PAR REGROUPEMENT
-- Date de test: 2026-03-25
-- Objectif:
--   - Meme creneau 08:00-08:30
--   - Reservation la plus tardive non assignable
--   - Depart attendu sur l'heure de la derniere reservation assignee
-- =============================================

-- 1) Configuration active
UPDATE planning_config SET is_active = false WHERE is_active = true;
INSERT INTO planning_config (vitesse_moyenne, temps_attente, is_active)
VALUES (35.0, 30, true);

-- 2) Hotels minimaux
INSERT INTO hotel (nom, adresse)
SELECT 'Hotel Colbert Antananarivo', 'Antananarivo'
WHERE NOT EXISTS (SELECT 1 FROM hotel WHERE nom = 'Hotel Colbert Antananarivo');

INSERT INTO hotel (nom, adresse)
SELECT 'Carlton Madagascar', 'Antananarivo'
WHERE NOT EXISTS (SELECT 1 FROM hotel WHERE nom = 'Carlton Madagascar');

INSERT INTO hotel (nom, adresse)
SELECT 'Hotel Le Louvre', 'Antananarivo'
WHERE NOT EXISTS (SELECT 1 FROM hotel WHERE nom = 'Hotel Le Louvre');

-- 3) Lieux minimaux
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

-- 4) Distances minimales
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

-- 5) Vehicules (forcer un cas ou la reservation de 11 pax ne passe pas)
TRUNCATE TABLE vehicule RESTART IDENTITY CASCADE;
INSERT INTO vehicule (reference, place, type_carburant) VALUES
('P1-VH-01', 8, 'diesel'),
('P1-VH-02', 4, 'essence');

-- 6) Reservations du jour de test
DELETE FROM reservation WHERE DATE(date_heure_depart) = '2026-03-25';

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('P1-R1-08h10', (SELECT id FROM hotel WHERE nom = 'Hotel Colbert Antananarivo' LIMIT 1), 3, '2026-03-25 08:10:00'),
('P1-R2-08h20-NonAssigneePotentielle', (SELECT id FROM hotel WHERE nom = 'Carlton Madagascar' LIMIT 1), 11, '2026-03-25 08:20:00'),
('P1-R3-08h15', (SELECT id FROM hotel WHERE nom = 'Hotel Le Louvre' LIMIT 1), 2, '2026-03-25 08:15:00');

-- Verification donnees injectees
SELECT id, client, nb_passager, date_heure_depart
FROM reservation
WHERE DATE(date_heure_depart) = '2026-03-25'
ORDER BY date_heure_depart, id;

-- Attendu metier:
-- - R2 non assignee (11)
-- - Heure de depart regroupement calculee a 08:15 (R3), pas 08:20
