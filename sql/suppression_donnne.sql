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
('Hotel1', 'Hotel1'),
('Hotel2', 'Hotel2');

-- LIEUX
INSERT INTO lieu (code, libelle) VALUES
('IVATO', 'IVATO'),
('Hotel1', 'Hotel1'),
('Hotel2', 'Hotel2');

-- DISTANCES
INSERT INTO distance (from_lieu, to_lieu, km) VALUES
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'Hotel1'), 90.0),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'Hotel2'), 35.0),
((SELECT id FROM lieu WHERE code = 'Hotel1'), (SELECT id FROM lieu WHERE code = 'Hotel2'), 60.0);

-- CONFIGURATION
INSERT INTO planning_config (vitesse_moyenne, temps_attente, is_active) VALUES
(50.0, 30, true);

-- VEHICULES
INSERT INTO vehicule (reference, place, type_carburant, heure_disponibilite) VALUES
('Vehicule1', 5, 'diesel', '09:00:00'),
('Vehicule2', 5, 'essence', '09:00:00'),
('Vehicule3', 12, 'diesel', '00:00:00'),
('Vehicule4', 9, 'diesel', '09:00:00'),
('Vehicule5', 12, 'essence', '13:00:00');

-- RESERVATIONS
INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('Client1', (SELECT id FROM hotel WHERE nom = 'Hotel1' LIMIT 1), 7, '2026-03-19 09:00:00'),
('Client2', (SELECT id FROM hotel WHERE nom = 'Hotel2' LIMIT 1), 20, '2026-03-19 08:00:00'),
('Client3', (SELECT id FROM hotel WHERE nom = 'Hotel1' LIMIT 1), 3, '2026-03-19 09:10:00'),
('Client4', (SELECT id FROM hotel WHERE nom = 'Hotel1' LIMIT 1), 10, '2026-03-19 09:15:00'),
('Client5', (SELECT id FROM hotel WHERE nom = 'Hotel1' LIMIT 1), 5, '2026-03-19 09:20:00'),
('Client6', (SELECT id FROM hotel WHERE nom = 'Hotel1' LIMIT 1), 12, '2026-03-19 13:30:00');