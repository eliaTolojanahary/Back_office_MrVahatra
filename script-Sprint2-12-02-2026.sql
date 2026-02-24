

DROP TABLE IF EXISTS vehicule CASCADE;
DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS hotel CASCADE;
DROP TABLE IF EXISTS token CASCADE;

CREATE TABLE vehicule (
    id SERIAL PRIMARY KEY,
    reference VARCHAR(100) NOT NULL UNIQUE,
    place INTEGER NOT NULL CHECK (place > 0),
    type_carburant VARCHAR(50) NOT NULL
);


CREATE INDEX idx_vehicule_reference ON vehicule(reference);

CREATE INDEX idx_vehicule_type_carburant ON vehicule(type_carburant);

-- =========================
-- SCRIPT DE CRÉATION - Sprint 2
-- Date: 12-02-2026
-- =========================

-- =========================
-- Table HOTEL
-- =========================

CREATE TABLE hotel (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(200) NOT NULL,
    adresse TEXT NOT NULL
);

-- =========================
-- Table TOKEN (Nouvelle)
-- =========================

CREATE TABLE token (
    id SERIAL PRIMARY KEY,
    token VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiration TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    user_id INTEGER,  -- Nullable pour l'instant, FK à ajouter plus tard
    type VARCHAR(50) DEFAULT 'AUTH'  -- 'AUTH', 'API', etc.
);

-- Index pour améliorer les performances de recherche
CREATE INDEX idx_token_value ON token(token);
CREATE INDEX idx_token_expiration ON token(expiration);
CREATE INDEX idx_token_active ON token(is_active);

-- =========================
-- Table RESERVATION
-- =========================

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
-- Données pour la table HOTEL
-- =========================

INSERT INTO hotel (nom, adresse) VALUES
('Hotel Colbert Antananarivo', 'Amboditsiry, Antananarivo, Madagascar'),
('Carlton Madagascar', 'Anosy, Antananarivo, Madagascar'),
('Hotel Le Louvre', 'Avenue de l''Indépendance, Antananarivo, Madagascar'),
('Palissandre Hotel', 'Ivandry, Antananarivo, Madagascar'),
('Radisson Blu Waterfront', 'Ambodivona, Antananarivo, Madagascar'),
('Hotel Sakamanga', 'Rue Ratsimilaho, Antananarivo, Madagascar'),
('Hotel Belvedere', 'Route d''Andraisoro, Antananarivo, Madagascar'),
('Hotel La Ribaudiere', 'Route de l''Université, Antananarivo, Madagascar'),
('Hotel Tana Plaza', 'Rue Patrice Lumumba, Antananarivo, Madagascar'),
('Hotel Sunny', 'Analakely, Antananarivo, Madagascar');

