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
