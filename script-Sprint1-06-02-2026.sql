-- =========================
-- SCRIPT DE CRÉATION - Sprint 1
-- Date: 06-02-2026
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
