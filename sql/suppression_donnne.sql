-- =========================================================================================
-- SCRIPT UNIQUE: SUPPRESSION + CREATION + DONNEES + ASSIGNEMENT
-- Date: 18-03-2026
-- Base cible: PostgreSQL
-- =========================================================================================



-- =========================================================================================
-- ETAPE 1: SUPPRESSION DES TABLES (ordre dependant)
-- =========================================================================================
DROP TABLE IF EXISTS assignement CASCADE;
DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS distance CASCADE;
DROP TABLE IF EXISTS planning_config CASCADE;
DROP TABLE IF EXISTS vehicule CASCADE;
DROP TABLE IF EXISTS lieu CASCADE;
DROP TABLE IF EXISTS hotel CASCADE;

-- =========================================================================================
-- ETAPE 2: CREATION DES TABLES
-- =========================================================================================
CREATE TABLE hotel (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(200) NOT NULL,
    adresse TEXT NOT NULL
);

CREATE TABLE lieu (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(200) NOT NULL
);

CREATE INDEX idx_lieu_code ON lieu(code);

CREATE TABLE vehicule (
    id SERIAL PRIMARY KEY,
    reference VARCHAR(50) NOT NULL UNIQUE,
    place INTEGER NOT NULL CHECK (place > 0),
    type_carburant VARCHAR(20) NOT NULL CHECK (type_carburant IN ('diesel', 'essence', 'Diesel', 'Essence')),
    heure_disponibilite TIME
);

CREATE TABLE planning_config (
    id SERIAL PRIMARY KEY,
    vitesse_moyenne NUMERIC(10,2) NOT NULL CHECK (vitesse_moyenne > 0),
    temps_attente INTEGER NOT NULL CHECK (temps_attente >= 0),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_planning_config_active ON planning_config(is_active);

CREATE TABLE distance (
    id SERIAL PRIMARY KEY,
    from_lieu INTEGER NOT NULL,
    to_lieu INTEGER NOT NULL,
    km NUMERIC(10,2) NOT NULL CHECK (km > 0),
    CONSTRAINT fk_distance_from_lieu FOREIGN KEY (from_lieu) REFERENCES lieu(id),
    CONSTRAINT fk_distance_to_lieu FOREIGN KEY (to_lieu) REFERENCES lieu(id),
    CONSTRAINT chk_different_lieu CHECK (from_lieu <> to_lieu),
    CONSTRAINT unique_distance_pair UNIQUE (from_lieu, to_lieu)
);

CREATE INDEX idx_distance_from ON distance(from_lieu);
CREATE INDEX idx_distance_to ON distance(to_lieu);

CREATE TABLE reservation (
    id SERIAL PRIMARY KEY,
    client VARCHAR(100) NOT NULL,
    id_hotel INTEGER NOT NULL,
    nb_passager INTEGER NOT NULL CHECK (nb_passager > 0),
    date_heure_depart TIMESTAMP NOT NULL,
    CONSTRAINT fk_reservation_hotel FOREIGN KEY (id_hotel) REFERENCES hotel(id)
);

CREATE TABLE assignement (
    id SERIAL PRIMARY KEY,
    id_reservation INTEGER NOT NULL,
    id_vehicule INTEGER NOT NULL,
    nb_passager_assigne INTEGER NOT NULL CHECK (nb_passager_assigne > 0),
    date_planning DATE NOT NULL,
    creneau VARCHAR(30),
    heure_depart VARCHAR(5),
    heure_retour VARCHAR(5),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_assignement_reservation FOREIGN KEY (id_reservation) REFERENCES reservation(id) ON DELETE CASCADE,
    CONSTRAINT fk_assignement_vehicule FOREIGN KEY (id_vehicule) REFERENCES vehicule(id) ON DELETE CASCADE,
    CONSTRAINT uq_assignement UNIQUE (date_planning, id_reservation, id_vehicule, creneau)
);

CREATE INDEX idx_assignement_date ON assignement(date_planning);
CREATE INDEX idx_assignement_reservation ON assignement(id_reservation);
CREATE INDEX idx_assignement_vehicule ON assignement(id_vehicule);

-- =========================================================================================
-- ETAPE 3: INSERTION DES DONNEES
-- =========================================================================================

-- HOTELS
INSERT INTO hotel (nom, adresse) VALUES
('Hotel Colbert Antananarivo', 'Rue Prince Ratsimamanga, Antananarivo'),
('Carlton Madagascar', 'Anosy, Antananarivo'),
('Hotel Le Louvre', 'Lalana Rainandriamampandry, Antananarivo'),
('Palissandre Hotel', 'Faravohitra, Antananarivo'),
('Radisson Blu Waterfront', 'Ambodivona, Antananarivo'),
('Hotel Sakamanga', 'Rue Andriandahifotsy, Antananarivo'),
('Hotel Sunny', 'Rue Rainibetsimisaraka, Antananarivo');

-- LIEUX
INSERT INTO lieu (code, libelle) VALUES
('IVATO', 'Aeroport International Ivato'),
('COLBERT', 'Hotel Colbert Antananarivo'),
('CARLTON', 'Carlton Madagascar'),
('LOUVRE', 'Hotel Le Louvre'),
('PALISSANDRE', 'Palissandre Hotel'),
('RADISSON', 'Radisson Blu Waterfront'),
('SAKAMANGA', 'Hotel Sakamanga'),
('SUNNY', 'Hotel Sunny');

-- DISTANCES
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

-- CONFIGURATION
INSERT INTO planning_config (vitesse_moyenne, temps_attente, is_active) VALUES
(35.0, 30, true);

-- VEHICULES
INSERT INTO vehicule (reference, place, type_carburant, heure_disponibilite) VALUES
('VH-101', 12, 'diesel', '08:00:00'),
('VH-102', 10, 'diesel', '08:00:00'),
('VH-103', 8, 'essence', '08:00:00'),
('VH-104', 6, 'diesel', '08:00:00'),
('VH-105', 4, 'essence', '08:00:00'),
('VH-106', 4, 'diesel', '08:00:00');

-- RESERVATIONS
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



-- =========================================================================================
-- ETAPE 4: VERIFICATIONS RAPIDES
-- =========================================================================================
SELECT 'hotel' AS table_name, COUNT(*) AS nombre_lignes FROM hotel
UNION ALL SELECT 'lieu', COUNT(*) FROM lieu
UNION ALL SELECT 'distance', COUNT(*) FROM distance
UNION ALL SELECT 'planning_config', COUNT(*) FROM planning_config
UNION ALL SELECT 'vehicule', COUNT(*) FROM vehicule
UNION ALL SELECT 'reservation', COUNT(*) FROM reservation
UNION ALL SELECT 'assignement', COUNT(*) FROM assignement;

SELECT a.id,
       a.date_planning,
       a.creneau,
       r.client,
       v.reference AS vehicule,
       a.nb_passager_assigne,
       a.heure_depart,
       a.heure_retour
FROM assignement a
JOIN reservation r ON r.id = a.id_reservation
JOIN vehicule v ON v.id = a.id_vehicule
ORDER BY a.date_planning, a.creneau, v.reference, r.client;
