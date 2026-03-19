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



