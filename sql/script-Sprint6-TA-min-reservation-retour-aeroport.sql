-- =========================================================================================
-- SCENARIO TEST TA - MINIMUM DE RESERVATIONS ASSIGNEES + RETOUR AEROPORT
-- Date: 17-03-2026
-- Objectif:
--   1) Montrer quel vehicule retourne en premier a l'aeroport apres un trajet
--   2) Verifier la priorite du vehicule ayant le moins de courses assignees
--
-- IMPORTANT:
--   - Ce script utilise UNE date de test unique: 2026-03-24
--   - Executer ensuite /planning/result avec cette date
-- =========================================================================================

-- =========================================================================================
-- 0) CONFIGURATION ACTIVE (vitesse = 40 km/h, attente = 30 min)
-- =========================================================================================
UPDATE planning_config SET is_active = false WHERE is_active = true;

INSERT INTO planning_config (vitesse_moyenne, temps_attente, is_active)
VALUES (40.0, 30, true);

-- =========================================================================================
-- 1) FLOTTE DEDIEE AU TEST (2 vehicules de 9 places)
--    - Diesel prioritaire en cas d'egalite totale
-- =========================================================================================
DELETE FROM vehicule WHERE reference LIKE 'TA-VH-%';

INSERT INTO vehicule (reference, place, type_carburant) VALUES
('TA-VH-01', 9, 'diesel'),
('TA-VH-02', 9, 'essence');

-- =========================================================================================
-- 2) SECURISATION DES LIEUX NECESSAIRES
-- =========================================================================================
INSERT INTO lieu (code, libelle)
SELECT 'IVATO', 'Aeroport International Ivato'
WHERE NOT EXISTS (SELECT 1 FROM lieu WHERE code = 'IVATO');

INSERT INTO lieu (code, libelle)
SELECT 'COLBERT', 'Hotel Colbert Antananarivo'
WHERE NOT EXISTS (SELECT 1 FROM lieu WHERE code = 'COLBERT');

INSERT INTO lieu (code, libelle)
SELECT 'BELVEDERE', 'Hotel Belvedere'
WHERE NOT EXISTS (SELECT 1 FROM lieu WHERE code = 'BELVEDERE');

INSERT INTO lieu (code, libelle)
SELECT 'SUNNY', 'Hotel Sunny'
WHERE NOT EXISTS (SELECT 1 FROM lieu WHERE code = 'SUNNY');

-- =========================================================================================
-- 2-bis) DONNEES HOTEL (MANQUANTES)
-- =========================================================================================
-- Ces donnees sont utiles pour les ecrans/formulaires de reservation qui lisent la table hotel.
INSERT INTO hotel (nom, adresse)
SELECT 'Hotel Colbert Antananarivo', 'Rue Prince Ratsimamanga, Antananarivo'
WHERE NOT EXISTS (SELECT 1 FROM hotel WHERE nom = 'Hotel Colbert Antananarivo');

INSERT INTO hotel (nom, adresse)
SELECT 'Hotel Belvedere', 'Route dAnkadimbahoaka, Antananarivo'
WHERE NOT EXISTS (SELECT 1 FROM hotel WHERE nom = 'Hotel Belvedere');

INSERT INTO hotel (nom, adresse)
SELECT 'Hotel Sunny', 'Rue Rainibetsimisaraka, Antananarivo'
WHERE NOT EXISTS (SELECT 1 FROM hotel WHERE nom = 'Hotel Sunny');

-- =========================================================================================
-- 3) DISTANCES MINIMALES REQUISES POUR LE CALCUL DES HEURES DE RETOUR
-- =========================================================================================
INSERT INTO distance (from_lieu, to_lieu, km)
SELECT (SELECT id FROM lieu WHERE code = 'IVATO'),
       (SELECT id FROM lieu WHERE code = 'COLBERT'),
       15.5
WHERE NOT EXISTS (
    SELECT 1
    FROM distance d
    WHERE (d.from_lieu = (SELECT id FROM lieu WHERE code = 'IVATO')
       AND d.to_lieu   = (SELECT id FROM lieu WHERE code = 'COLBERT'))
       OR
          (d.from_lieu = (SELECT id FROM lieu WHERE code = 'COLBERT')
       AND d.to_lieu   = (SELECT id FROM lieu WHERE code = 'IVATO'))
);

INSERT INTO distance (from_lieu, to_lieu, km)
SELECT (SELECT id FROM lieu WHERE code = 'IVATO'),
       (SELECT id FROM lieu WHERE code = 'BELVEDERE'),
       19.2
WHERE NOT EXISTS (
    SELECT 1
    FROM distance d
    WHERE (d.from_lieu = (SELECT id FROM lieu WHERE code = 'IVATO')
       AND d.to_lieu   = (SELECT id FROM lieu WHERE code = 'BELVEDERE'))
       OR
          (d.from_lieu = (SELECT id FROM lieu WHERE code = 'BELVEDERE')
       AND d.to_lieu   = (SELECT id FROM lieu WHERE code = 'IVATO'))
);

INSERT INTO distance (from_lieu, to_lieu, km)
SELECT (SELECT id FROM lieu WHERE code = 'IVATO'),
       (SELECT id FROM lieu WHERE code = 'SUNNY'),
       13.9
WHERE NOT EXISTS (
    SELECT 1
    FROM distance d
    WHERE (d.from_lieu = (SELECT id FROM lieu WHERE code = 'IVATO')
       AND d.to_lieu   = (SELECT id FROM lieu WHERE code = 'SUNNY'))
       OR
          (d.from_lieu = (SELECT id FROM lieu WHERE code = 'SUNNY')
       AND d.to_lieu   = (SELECT id FROM lieu WHERE code = 'IVATO'))
);

-- =========================================================================================
-- 4) NETTOYAGE DES RESERVATIONS DE CETTE DATE
-- =========================================================================================
DELETE FROM reservation WHERE DATE(date_heure_depart) = '2026-03-24';

-- =========================================================================================
-- 5) INSERTION DES RESERVATIONS DE TEST
--
-- Sequence voulue:
--   A) 08:00/08:05 : 2 reservations de 9 passagers
--      -> TA-VH-01 (diesel) prend la premiere (egalite totale, diesel prioritaire)
--      -> TA-VH-02 prend la deuxieme (TA-VH-01 encore en trajet)
--
--   B) 08:55 : nouvelle reservation
--      -> le vehicule revenu le plus tot reprend en premier
--
--   C) 10:00 : nouvelle reservation
--      -> les deux vehicules sont disponibles
--      -> doit choisir celui avec le MOINS DE COURSES deja assignees
-- =========================================================================================
INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('TA-R1-COLBERT-9P',   (SELECT id FROM hotel WHERE nom = 'Hotel Colbert Antananarivo'), 9, '2026-03-24 08:00:00'),
('TA-R2-BELVEDERE-9P', (SELECT id FROM hotel WHERE nom = 'Hotel Belvedere'),             9, '2026-03-24 08:05:00'),
('TA-R3-SUNNY-9P',     (SELECT id FROM hotel WHERE nom = 'Hotel Sunny'),                 9, '2026-03-24 08:55:00'),
('TA-R4-COLBERT-9P',   (SELECT id FROM hotel WHERE nom = 'Hotel Colbert Antananarivo'), 9, '2026-03-24 10:00:00');

-- =========================================================================================
-- 5-bis) REINITIALISATION DES CLES (SEQUENCES)
-- =========================================================================================
-- A executer apres les INSERT pour aligner les prochaines valeurs d'ID.
SELECT setval(pg_get_serial_sequence('planning_config', 'id'), COALESCE((SELECT MAX(id) FROM planning_config), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('vehicule', 'id'),       COALESCE((SELECT MAX(id) FROM vehicule), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('lieu', 'id'),           COALESCE((SELECT MAX(id) FROM lieu), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('hotel', 'id'),          COALESCE((SELECT MAX(id) FROM hotel), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('distance', 'id'),       COALESCE((SELECT MAX(id) FROM distance), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('reservation', 'id'),    COALESCE((SELECT MAX(id) FROM reservation), 0) + 1, false);

-- =========================================================================================
-- 6) VERIFICATIONS SQL RAPIDES
-- =========================================================================================
SELECT id, reference, place, type_carburant
FROM vehicule
WHERE reference LIKE 'TA-VH-%'
ORDER BY reference;

SELECT r.id, r.client, h.nom AS hotel, r.nb_passager, r.date_heure_depart
FROM reservation r
LEFT JOIN hotel h ON h.id = r.id_hotel
WHERE DATE(date_heure_depart) = '2026-03-24'
ORDER BY r.date_heure_depart, r.id;

SELECT l1.code AS from_code, l2.code AS to_code, d.km
FROM distance d
JOIN lieu l1 ON l1.id = d.from_lieu
JOIN lieu l2 ON l2.id = d.to_lieu
WHERE (l1.code = 'IVATO' AND l2.code IN ('COLBERT', 'BELVEDERE', 'SUNNY'))
   OR (l2.code = 'IVATO' AND l1.code IN ('COLBERT', 'BELVEDERE', 'SUNNY'))
ORDER BY from_code, to_code;

-- =========================================================================================
-- 7) COMMENT TESTER DANS L'APPLICATION
-- =========================================================================================
-- 1. Ouvrir /planning/result
-- 2. Saisir la date: 2026-03-24
-- 3. Verifier dans le resultat:
--    - Quel vehicule revient en premier apres le creneau 08:00-08:30
--    - Sur la reservation de 10:00, le vehicule choisi doit etre
--      celui avec le moins de courses assignees
-- =========================================================================================
