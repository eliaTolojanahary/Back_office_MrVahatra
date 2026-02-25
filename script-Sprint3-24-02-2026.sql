-- =========================
-- Table HOTEL (Sprint 3, pour cohérence avec reservation)
-- =========================

DROP TABLE IF EXISTS hotel CASCADE;
CREATE TABLE hotel (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(200) NOT NULL,
    adresse TEXT NOT NULL
);

-- =========================
-- Données de test pour HOTEL
-- =========================

INSERT INTO hotel (nom, adresse) VALUES
('Hotel Colbert Antananarivo', 'Rue Prince Ratsimamanga, Antananarivo'),
('Carlton Madagascar', 'Anosy, Antananarivo'),
('Hotel Le Louvre', 'Lalana Rainandriamampandry, Antananarivo'),
('Palissandre Hotel', 'Ivandry, Antananarivo'),
('Radisson Blu Waterfront', 'Rue Solombavambahoaka, Antananarivo'),
('Hotel Sakamanga', 'Rue Andriandahifotsy, Antananarivo'),
('Hotel Belvedere', 'Route dAnkadimbahoaka, Antananarivo'),
('Hotel La Ribaudiere', 'Route de lUniversite, Antananarivo'),
('Hotel Tana Plaza', 'Avenue de lIndependance, Antananarivo'),
('Hotel Sunny', 'Rue Rainibetsimisaraka, Antananarivo');

-- =========================

-- =========================
-- Table RESERVATION (structure Sprint 1)
-- =========================

DROP TABLE IF EXISTS reservation CASCADE;
CREATE TABLE reservation (
    id SERIAL PRIMARY KEY,
    client VARCHAR(100) NOT NULL,
    id_hotel INTEGER NOT NULL,
    nb_passager INTEGER NOT NULL CHECK (nb_passager > 0),
    date_heure_depart TIMESTAMP NOT NULL,
    CONSTRAINT fk_reservation_hotel
        FOREIGN KEY (id_hotel)
        REFERENCES hotel(id)
);

-- =========================
-- Données de test pour RESERVATION
-- =========================

-- Réservations pour le 24-02-2026 (pour tester la planification)
INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('Jean Rakoto', 1, 4, '2026-02-24 08:30:00'),        -- 4 passagers -> Hotel Colbert
('Marie Randria', 10, 1, '2026-02-24 09:00:00'),     -- 1 passager -> Hotel Sunny
('Paul Andrian', 3, 3, '2026-02-24 10:15:00'),       -- 3 passagers -> Hotel Le Louvre
('Sophie Raja', 5, 2, '2026-02-24 11:00:00'),        -- 2 passagers -> Radisson
('Hery Rabe', 6, 5, '2026-02-24 12:30:00'),          -- 5 passagers -> Sakamanga
('Lanto Razaf', 2, 2, '2026-02-24 13:45:00'),        -- 2 passagers -> Carlton
('Nivo Andriana', 7, 1, '2026-02-24 14:00:00'),      -- 1 passager -> Belvedere
('Faly Ramanana', 4, 6, '2026-02-24 15:30:00');      -- 6 passagers -> Palissandre (ne pourra pas être assigné si pas assez de véhicules)

-- Réservations pour le 25-02-2026 (autre date)
INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES
('Tsiky Raveloson', 8, 3, '2026-02-25 09:00:00'),
('Diary Rafenohery', 9, 2, '2026-02-25 10:30:00');

-- =========================
-- Table VEHICULE
-- =========================
    
DROP TABLE IF EXISTS vehicule CASCADE;
CREATE TABLE vehicule (
    id SERIAL PRIMARY KEY,
    reference VARCHAR(50) NOT NULL UNIQUE,
    place INTEGER NOT NULL CHECK (place > 0),
    type_carburant VARCHAR(20) NOT NULL CHECK (type_carburant IN ('diesel', 'essence', 'Diesel', 'Essence'))
);

-- =========================
-- Données de test pour VEHICULE
-- =========================

-- Véhicules avec différentes configurations pour tester les règles métier
INSERT INTO vehicule (reference, place, type_carburant) VALUES
('VH-001', 4, 'diesel'),     -- 4 places diesel
('VH-002', 4, 'essence'),    -- 4 places essence (moins prioritaire que VH-001)
('VH-003', 2, 'diesel'),     -- 2 places diesel
('VH-004', 5, 'diesel'),     -- 5 places diesel
('VH-005', 5, 'essence'),    -- 5 places essence (moins prioritaire que VH-004)
('VH-006', 3, 'diesel'),     -- 3 places diesel
('VH-007', 7, 'diesel');     -- 7 places diesel (pour grands groupes)

-- Configuration pour tester :
-- - VH-001 et VH-002 (même places, diesel prioritaire)
-- - VH-004 et VH-005 (même places, diesel prioritaire)
-- - Pas assez de véhicules pour toutes les réservations du 24-02 (8 réservations, 7 véhicules)
-- =========================
-- SCRIPT DE CRÉATION - Sprint 3
-- Date: 24-02-2026
-- =========================

-- =========================
-- SCRIPT DE RÉINITIALISATION
-- =========================

DROP TABLE IF EXISTS distance CASCADE;
DROP TABLE IF EXISTS lieu CASCADE;
DROP TABLE IF EXISTS planning_config CASCADE;

-- =========================
-- Table LIEU
-- =========================

CREATE TABLE lieu (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(200) NOT NULL
);

CREATE INDEX idx_lieu_code ON lieu(code);

-- =========================
-- Table DISTANCE
-- =========================

CREATE TABLE distance (
    id SERIAL PRIMARY KEY,
    from_lieu INTEGER NOT NULL,
    to_lieu INTEGER NOT NULL,
    km NUMERIC(10,2) NOT NULL CHECK (km > 0),
    
    CONSTRAINT fk_distance_from_lieu
        FOREIGN KEY (from_lieu)
        REFERENCES lieu(id),
    
    CONSTRAINT fk_distance_to_lieu
        FOREIGN KEY (to_lieu)
        REFERENCES lieu(id),
    
    CONSTRAINT chk_different_lieu
        CHECK (from_lieu != to_lieu),
    
    CONSTRAINT unique_distance_pair
        UNIQUE (from_lieu, to_lieu)
);

CREATE INDEX idx_distance_from ON distance(from_lieu);
CREATE INDEX idx_distance_to ON distance(to_lieu);

-- =========================
-- Table PLANNING_CONFIG
-- =========================

CREATE TABLE planning_config (
    id SERIAL PRIMARY KEY,
    vitesse_moyenne NUMERIC(10,2) NOT NULL CHECK (vitesse_moyenne > 0),  -- en km/h
    temps_attente INTEGER NOT NULL CHECK (temps_attente >= 0),           -- en minutes
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Index pour récupérer rapidement la config active
CREATE INDEX idx_planning_config_active ON planning_config(is_active);

-- =========================
-- Données pour la table LIEU
-- =========================

-- Aéroport
INSERT INTO lieu (code, libelle) VALUES
('IVATO', 'Aéroport International Ivato');

-- Hôtels de Tananarive
INSERT INTO lieu (code, libelle) VALUES
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

-- =========================
-- Données pour la table DISTANCE
-- =========================

-- Distances de l'aéroport Ivato vers les hôtels (en km)
INSERT INTO distance (from_lieu, to_lieu, km) VALUES
-- Aéroport -> Hôtels
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'COLBERT'), 15.5),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'CARLTON'), 16.2),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'LOUVRE'), 14.8),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'PALISSANDRE'), 18.3),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 16.7),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 15.1),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 19.2),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 17.5),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 14.3),
((SELECT id FROM lieu WHERE code = 'IVATO'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 13.9);

-- Distances entre hôtels (sans couples symétriques)
INSERT INTO distance (from_lieu, to_lieu, km) VALUES
-- COLBERT vers autres hôtels
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'CARLTON'), 3.5),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'LOUVRE'), 2.1),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'PALISSANDRE'), 5.8),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 4.2),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 2.8),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 6.3),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 4.9),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 1.7),
((SELECT id FROM lieu WHERE code = 'COLBERT'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 2.3),

-- CARLTON vers autres hôtels (sauf COLBERT déjà fait)
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'LOUVRE'), 2.9),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'PALISSANDRE'), 6.1),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 1.8),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 3.2),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 7.1),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 5.3),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 2.6),
((SELECT id FROM lieu WHERE code = 'CARLTON'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 3.8),

-- LOUVRE vers autres hôtels (sauf COLBERT, CARLTON déjà faits)
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'PALISSANDRE'), 4.7),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 3.1),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 1.5),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 5.9),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 4.2),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 1.9),
((SELECT id FROM lieu WHERE code = 'LOUVRE'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 1.2),

-- PALISSANDRE vers autres hôtels (sauf précédents)
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'RADISSON'), 4.8),
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 5.3),
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 3.2),
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 2.1),
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 6.5),
((SELECT id FROM lieu WHERE code = 'PALISSANDRE'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 6.9),

-- RADISSON vers autres hôtels (sauf précédents)
((SELECT id FROM lieu WHERE code = 'RADISSON'), (SELECT id FROM lieu WHERE code = 'SAKAMANGA'), 3.7),
((SELECT id FROM lieu WHERE code = 'RADISSON'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 6.4),
((SELECT id FROM lieu WHERE code = 'RADISSON'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 4.7),
((SELECT id FROM lieu WHERE code = 'RADISSON'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 3.1),
((SELECT id FROM lieu WHERE code = 'RADISSON'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 4.2),

-- SAKAMANGA vers autres hôtels (sauf précédents)
((SELECT id FROM lieu WHERE code = 'SAKAMANGA'), (SELECT id FROM lieu WHERE code = 'BELVEDERE'), 5.8),
((SELECT id FROM lieu WHERE code = 'SAKAMANGA'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 3.9),
((SELECT id FROM lieu WHERE code = 'SAKAMANGA'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 2.2),
((SELECT id FROM lieu WHERE code = 'SAKAMANGA'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 1.8),

-- BELVEDERE vers autres hôtels (sauf précédents)
((SELECT id FROM lieu WHERE code = 'BELVEDERE'), (SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), 2.8),
((SELECT id FROM lieu WHERE code = 'BELVEDERE'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 7.2),
((SELECT id FROM lieu WHERE code = 'BELVEDERE'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 7.6),

-- RIBAUDIERE vers autres hôtels (sauf précédents)
((SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), (SELECT id FROM lieu WHERE code = 'TANAPLAZA'), 5.4),
((SELECT id FROM lieu WHERE code = 'RIBAUDIERE'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 5.9),

-- TANAPLAZA vers dernier hôtel
((SELECT id FROM lieu WHERE code = 'TANAPLAZA'), (SELECT id FROM lieu WHERE code = 'SUNNY'), 0.9);

-- =========================
-- Configuration Planning par défaut
-- =========================

INSERT INTO planning_config (vitesse_moyenne, temps_attente, is_active) VALUES
(40.0, 15, TRUE);  -- Vitesse moyenne: 40 km/h, Temps d'attente: 15 minutes

-- =========================
-- Commentaires et notes
-- =========================

-- Note: Les distances sont approximatives et basées sur la géographie de Tananarive
-- La contrainte unique_distance_pair garantit qu'on ne peut pas avoir deux fois la même paire
-- La contrainte chk_different_lieu empêche les distances d'un lieu vers lui-même
-- La table planning_config permet de modifier les paramètres système sans modifier le code
