
DROP TABLE IF EXISTS vehicule CASCADE;

CREATE TABLE vehicule (
    id SERIAL PRIMARY KEY,
    reference VARCHAR(100) NOT NULL UNIQUE,
    place INTEGER NOT NULL CHECK (place > 0),
    type_carburant VARCHAR(50) NOT NULL
);


CREATE INDEX idx_vehicule_reference ON vehicule(reference);

CREATE INDEX idx_vehicule_type_carburant ON vehicule(type_carburant);
