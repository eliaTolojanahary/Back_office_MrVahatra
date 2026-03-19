-- =========================================================================================
-- SCRIPT UNIQUE: SUPPRESSION + CREATION + DONNEES + ASSIGNEMENT
-- Date: 18-03-2026
-- Base cible: PostgreSQL
-- =========================================================================================
-- =========================================================================================
-- ETAPE 1: SUPPRESSION DES DONNEES (ordre dependant)
-- =========================================================================================
TRUNCATE TABLE assignement CASCADE;
TRUNCATE TABLE reservation CASCADE;
TRUNCATE TABLE distance CASCADE;
TRUNCATE TABLE planning_config CASCADE;
TRUNCATE TABLE vehicule CASCADE;
TRUNCATE TABLE lieu CASCADE;
TRUNCATE TABLE hotel CASCADE;



