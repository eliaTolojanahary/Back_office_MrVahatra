-- =========================================================================================
-- SCRIPT DE CRÉATION DES VÉHICULES DE TEST
-- Date: 11-03-2026
-- Objectif: Créer les 7 véhicules nécessaires pour tester les règles de gestion
-- =========================================================================================

-- =========================================================================================
-- VÉRIFICATION ET NETTOYAGE (optionnel)
-- =========================================================================================
-- Vérifier si les véhicules existent déjà
SELECT * FROM vehicule WHERE reference LIKE 'VH-%' ORDER BY reference;

-- Si vous voulez supprimer les anciens véhicules de test (ATTENTION: décommenter avec précaution)
-- DELETE FROM vehicule WHERE reference IN ('VH-001', 'VH-002', 'VH-003', 'VH-004', 'VH-005', 'VH-006', 'VH-007');

-- =========================================================================================
-- CRÉATION DES VÉHICULES
-- =========================================================================================

INSERT INTO vehicule (reference, place, type_carburant) VALUES
('VH-001', 4, 'diesel'),     -- 4 places diesel
('VH-002', 4, 'essence'),    -- 4 places essence (pour tester règle 2b: diesel prioritaire)
('VH-003', 2, 'diesel'),     -- 2 places diesel (véhicule minimal)
('VH-004', 5, 'diesel'),     -- 5 places diesel
('VH-005', 5, 'essence'),    -- 5 places essence (pour tester règle 2b: diesel prioritaire)
('VH-006', 3, 'diesel'),     -- 3 places diesel
('VH-007', 7, 'diesel');     -- 7 places diesel (véhicule maximal pour grands groupes)

-- =========================================================================================
-- VÉRIFICATIONS POST-CRÉATION
-- =========================================================================================

-- 1. Vérifier que tous les véhicules ont été créés
SELECT 
    'Nombre de véhicules créés' as info,
    COUNT(*) as total 
FROM vehicule 
WHERE reference LIKE 'VH-%';

-- 2. Afficher les véhicules avec leurs caractéristiques
SELECT 
    id,
    reference,
    place,
    type_carburant,
    CASE 
        WHEN type_carburant = 'diesel' THEN '✓ Prioritaire'
        ELSE ''
    END as priorite
FROM vehicule 
WHERE reference LIKE 'VH-%'
ORDER BY reference;

-- 3. Statistiques par type de carburant
SELECT 
    type_carburant,
    COUNT(*) as nombre,
    SUM(place) as places_totales,
    AVG(place) as moyenne_places
FROM vehicule 
WHERE reference LIKE 'VH-%'
GROUP BY type_carburant;

-- 4. Afficher les véhicules groupés par nombre de places
SELECT 
    place as nombre_places,
    STRING_AGG(reference || ' (' || type_carburant || ')', ', ' ORDER BY type_carburant DESC) as vehicules
FROM vehicule 
WHERE reference LIKE 'VH-%'
GROUP BY place
ORDER BY place;

-- =========================================================================================
-- NOTES IMPORTANTES
-- =========================================================================================

-- Configuration des véhicules pour tester les règles:
--
-- RÈGLE 2a (Places minimales):
--   - 2 passagers -> VH-003 (2 places exactes)
--   - 3 passagers -> VH-006 (3 places exactes)
--   - 4 passagers -> VH-001 ou VH-002 (4 places exactes)
--   - 5 passagers -> VH-004 ou VH-005 (5 places exactes)
--   - 6 passagers -> VH-007 (7 places, plus proche disponible)
--
-- RÈGLE 2b (Priorité diesel):
--   - 4 places: VH-001 (diesel) prioritaire sur VH-002 (essence)
--   - 5 places: VH-004 (diesel) prioritaire sur VH-005 (essence)
--
-- RÈGLE 3 (Maximisation):
--   - VH-007 (7 places) idéal pour tester le remplissage optimal
--     Exemple: 4 + 2 + 1 = 7 passagers (véhicule plein)

-- =========================================================================================
-- FIN DU SCRIPT
-- =========================================================================================
