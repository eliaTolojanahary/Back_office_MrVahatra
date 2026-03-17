-- =========================
-- SCRIPT DE SUPPRESSION DES DONNÉES
-- Date: 11-03-2026
-- Description: Suppression de toutes les données des tables (Sprint 4)
-- Note: Les structures des tables sont conservées, seules les données sont supprimées
-- =========================

-- Suppression des données de toutes les tables
TRUNCATE TABLE reservation RESTART IDENTITY CASCADE;
TRUNCATE TABLE hotel RESTART IDENTITY CASCADE;
TRUNCATE TABLE vehicule RESTART IDENTITY CASCADE;

TRUNCATE TABLE lieu RESTART IDENTITY CASCADE;
TRUNCATE TABLE distance RESTART IDENTITY CASCADE;
TRUNCATE TABLE planning_config RESTART IDENTITY CASCADE;

-- =========================
-- VÉRIFICATIONS POST-SUPPRESSION
-- =========================

-- Vérifier que les tables sont vides
SELECT 'hotel' as table_name, COUNT(*) as nombre_lignes FROM hotel
UNION ALL
SELECT 'lieu', COUNT(*) FROM lieu
UNION ALL
SELECT 'distance', COUNT(*) FROM distance
UNION ALL
SELECT 'vehicule', COUNT(*) FROM vehicule
UNION ALL
SELECT 'reservation', COUNT(*) FROM reservation
UNION ALL
SELECT 'planning_config', COUNT(*) FROM planning_config;

-- =========================
-- FIN DU SCRIPT DE SUPPRESSION
-- =========================
