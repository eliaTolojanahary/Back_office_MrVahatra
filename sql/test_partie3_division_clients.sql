-- =============================================
-- TEST PARTIE 3: DIVISION DES CLIENTS
-- Date de test: 2026-03-27
-- Objectif:
--   - Reservation trop grande pour un seul vehicule
--   - Division en plusieurs affectations
--   - Reliquat non assigne si capacite insuffisante
-- =============================================

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

-- 5) Vehicules: capacite totale partielle pour montrer division + reliquat
TRUNCATE TABLE vehicule RESTART IDENTITY CASCADE;
INSERT INTO vehicule (reference, place, type_carburant) VALUES
('P3-VH-01', 6, 'diesel'),
('P3-VH-02', 4, 'diesel'),
('P3-VH-03', 3, 'essence');

-- 6) Reservations
DELETE FROM reservation WHERE DATE(date_heure_depart) = '2026-03-27';

INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('P3-R1-ClientMassif-14', (SELECT id FROM hotel WHERE nom = 'Hotel Colbert Antananarivo' LIMIT 1), 14, '2026-03-27 08:00:00'),
('P3-R2-Secondaire', (SELECT id FROM hotel WHERE nom = 'Carlton Madagascar' LIMIT 1), 2, '2026-03-27 08:10:00');

SELECT id, client, nb_passager, date_heure_depart
FROM reservation
WHERE DATE(date_heure_depart) = '2026-03-27'
ORDER BY date_heure_depart, id;

-- Attendu metier:
-- - P3-R1 doit etre divisee sur plusieurs vehicules
-- - Capacite dispo = 13 (6+4+3), donc reliquat 1 non assigne
-- - P3-R2 peut rester non assignee selon disponibilite restante
