-- =========================
-- Table GENRE
-- =========================
CREATE TABLE genre (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(20) NOT NULL
);

-- =========================
-- Table CLIENT
-- =========================
CREATE TABLE client (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    prenom VARCHAR(50) NOT NULL,
    num_tel VARCHAR(20),
    email VARCHAR(100),
    id_genre INTEGER,

    CONSTRAINT fk_client_genre
        FOREIGN KEY (id_genre)
        REFERENCES genre(id)
);

-- =========================
-- Table TYPE_CARBURANT
-- =========================
CREATE TABLE type_carburant (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(30) NOT NULL
);

-- =========================
-- Table VEHICULE
-- =========================
CREATE TABLE vehicule (
    id SERIAL PRIMARY KEY,
    num_matriculation VARCHAR(20) NOT NULL,
    marque VARCHAR(50),
    modele VARCHAR(50),
    capacite INTEGER NOT NULL CHECK (capacite > 0),
    id_type_carburant INTEGER,

    CONSTRAINT fk_vehicule_carburant
        FOREIGN KEY (id_type_carburant)
        REFERENCES type_carburant(id)
);

-- =========================
-- Table PARAMETRE_VEHICULE
-- =========================
CREATE TABLE parametre_vehicule (
    id SERIAL PRIMARY KEY,
    temps_attente INTEGER NOT NULL CHECK (temps_attente >= 0),
    vitesse NUMERIC(5,2) NOT NULL CHECK (vitesse > 0),
    id_vehicule INTEGER UNIQUE,

    CONSTRAINT fk_parametre_vehicule
        FOREIGN KEY (id_vehicule)
        REFERENCES vehicule(id)
        ON DELETE CASCADE
);

-- =========================
-- Table VOL
-- =========================
CREATE TABLE vol (
    id SERIAL PRIMARY KEY,
    lieu_depart VARCHAR(100) NOT NULL,
    lieu_arrive VARCHAR(100) NOT NULL,
    temps_depart TIMESTAMP NOT NULL,
    temps_arrive TIMESTAMP NOT NULL
);

-- =========================
-- Table HOTEL
-- =========================
CREATE TABLE hotel (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    adresse VARCHAR(150)
);

-- =========================
-- Table RESERVATION
-- =========================
CREATE TABLE reservation (
    id SERIAL PRIMARY KEY,
    id_client INTEGER NOT NULL,
    id_vol INTEGER NOT NULL,
    id_hotel INTEGER NOT NULL,
    nb_passager INTEGER NOT NULL CHECK (nb_passager > 0),
    date_heure_depart TIMESTAMP NOT NULL,
    distance_hotel NUMERIC(6,2) NOT NULL CHECK (distance_hotel >= 0),

    CONSTRAINT fk_reservation_client
        FOREIGN KEY (id_client)
        REFERENCES client(id),

    CONSTRAINT fk_reservation_vol
        FOREIGN KEY (id_vol)
        REFERENCES vol(id),

    CONSTRAINT fk_reservation_hotel
        FOREIGN KEY (id_hotel)
        REFERENCES hotel(id)
);
