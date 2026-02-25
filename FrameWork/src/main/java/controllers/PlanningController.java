package controllers;

import annotation.MethodeAnnotation;
import annotation.GetMapping;
import annotation.PostMapping;
import annotation.ClasseAnnotation;
import modelview.ModelView;
import models.*;
import util.DatabaseConnection;
import java.sql.*;
import java.util.List;
import java.util.ArrayList;

@ClasseAnnotation("/planning")
public class PlanningController {
    
    /**
     * PAGE 1 : Affiche le formulaire de configuration des paramètres système
     */
    @MethodeAnnotation("/planning/config/form")
    @GetMapping
    public ModelView getFormPlanningConfig() {
        ModelView mv = new ModelView("/formPlanningConfig.jsp");
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            PlanningConfig config = Planning.getActiveConfig(conn);
            mv.addData("config", config);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement de la configuration: " + e.getMessage());
        }
        
        return mv;
    }
    
    /**
     * Enregistre la configuration du planning
     */
    @MethodeAnnotation("/planning/config/save")
    @PostMapping
    public ModelView savePlanningConfig(PlanningConfig config) {
        ModelView mv = new ModelView("/resultPlanningConfig.jsp");
        boolean success = false;
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            // Désactiver les anciennes configs
            String sqlUpdate = "UPDATE planning_config SET is_active = false WHERE is_active = true";
            try (PreparedStatement stmtUpdate = conn.prepareStatement(sqlUpdate)) {
                stmtUpdate.executeUpdate();
            }
            
            // Insérer la nouvelle configuration
            String sql = "INSERT INTO planning_config (vitesse_moyenne, temps_attente, is_active) VALUES (?, ?, true)";
            try (PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                stmt.setDouble(1, config.getVitesseMoyenne());
                stmt.setInt(2, config.getTempsAttente());
                
                int rowsAffected = stmt.executeUpdate();
                if (rowsAffected > 0) {
                    success = true;
                    try (ResultSet rs = stmt.getGeneratedKeys()) {
                        if (rs.next()) {
                            config.setId(rs.getInt(1));
                        }
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors de l'enregistrement: " + e.getMessage());
        }
        
        mv.addData("success", success);
        mv.addData("config", config);
        return mv;
    }
    
    /**
     * PAGE 1 : Affiche le formulaire de sélection de date de planification
     */
    @MethodeAnnotation("/planning/selection-date")
    @GetMapping
    public ModelView getFormSelectionDate() {
        ModelView mv = new ModelView("/formSelectionDatePlanning.jsp");
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            PlanningConfig config = Planning.getActiveConfig(conn);
            mv.addData("config", config);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement de la configuration: " + e.getMessage());
        }
        
        return mv;
    }
    
    /**
     * PAGE 1 : Liste les réservations pour une date donnée (pour vérification)
     */
    @MethodeAnnotation("/planning/reservations-by-date")
    @PostMapping
    public ModelView getReservationsByDate(String datePlanning) {
        ModelView mv = new ModelView("/listReservationsByDate.jsp");
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            List<Reservation> reservations = Planning.getReservationsByDate(conn, datePlanning);
            PlanningConfig config = Planning.getActiveConfig(conn);
            
            mv.addData("reservations", reservations);
            mv.addData("datePlanning", datePlanning);
            mv.addData("config", config);
            mv.addData("count", reservations.size());
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement des réservations: " + e.getMessage());
        }
        
        return mv;
    }
    
    /**
     * PAGE 2 : Calcule l'affectation des réservations et affiche le résultat
     */
    @MethodeAnnotation("/planning/result")
    @PostMapping
    public ModelView getPlanningResult(String datePlanning) {
        ModelView mv = new ModelView("/resultPlanning.jsp");
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            // Récupération des données de base
            List<Reservation> reservations = Planning.getReservationsByDate(conn, datePlanning);
            List<Vehicule> vehicules = Planning.getAllVehicules(conn);
            PlanningConfig config = Planning.getActiveConfig(conn);
            List<Distance> distances = Planning.getAllDistances(conn);
            List<Lieu> lieux = Planning.getAllLieux(conn);
            
            // Tri des réservations par nombre de passagers décroissant (priorité)
            reservations.sort((r1, r2) -> Integer.compare(r2.getNbPassager(), r1.getNbPassager()));
            
            List<ReservationDTO> assigned = new ArrayList<>();
            List<ReservationDTO> unassigned = new ArrayList<>();
            List<Vehicule> vehiculesDisponibles = new ArrayList<>(vehicules);
            
            // Récupérer l'aéroport (lieu de départ)
            Lieu aeroport = lieux.stream()
                .filter(l -> l.getCode().equals("IVATO"))
                .findFirst()
                .orElse(null);
            
            if (aeroport == null) {
                mv.addData("error", "Erreur: Aéroport IVATO non trouvé");
                return mv;
            }
            
            // Pour chaque réservation
            for (Reservation r : reservations) {
                // Trouver le lieu de l'hôtel
                Lieu lieuHotel = lieux.stream()
                    .filter(l -> l.getLibelle().toLowerCase().contains(r.getHotel().toLowerCase()) 
                              || r.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                    .findFirst()
                    .orElse(null);
                
                if (lieuHotel == null) {
                    unassigned.add(new ReservationDTO(r));
                    continue;
                }
                
                // Récupérer la distance aéroport -> hôtel
                double distanceKm = Distance.getDistanceBetween(aeroport.getId(), lieuHotel.getId(), distances);
                
                if (distanceKm <= 0) {
                    unassigned.add(new ReservationDTO(r));
                    continue;
                }
                
                // Trouver le véhicule optimal selon les règles métier
                Vehicule vehiculeOptimal = trouverVehiculeOptimal(vehiculesDisponibles, r.getNbPassager());
                
                if (vehiculeOptimal != null) {
                    // Calculer les temps
                    double tempsTrajetHeures = distanceKm / config.getVitesseMoyenne();
                    double tempsAttenteHeures = config.getTempsAttente() / 60.0;
                    double tempsTotalHeures = tempsTrajetHeures + tempsAttenteHeures;
                    
                    // Parse la date heure de départ du client
                    java.time.LocalDateTime dateHeureArriveeClient = java.time.LocalDateTime.parse(
                        r.getDateHeureDepart().replace(" ", "T")
                    );
                    
                    // Calculer l'heure de départ de l'aéroport (avant l'arrivée du client)
                    java.time.LocalDateTime heureDepartCalc = dateHeureArriveeClient.minusHours((long) tempsTotalHeures)
                                                                                .minusMinutes((long)((tempsTotalHeures % 1) * 60));
                    
                    // Heure d'arrivée à l'hôtel = heure d'arrivée du client
                    java.time.LocalDateTime heureArriveeCalc = dateHeureArriveeClient;
                    
                    // Formater les heures
                    java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
                    String heureDepartStr = formatter.format(heureDepartCalc);
                    String heureArriveeStr = formatter.format(heureArriveeCalc);
                    
                    // Créer le DTO avec toutes les infos
                    ReservationDTO dto = new ReservationDTO(
                        r, 
                        vehiculeOptimal, 
                        heureDepartStr, 
                        heureArriveeStr,
                        aeroport.getLibelle(),
                        lieuHotel.getLibelle(),
                        heureArriveeCalc
                    );
                    
                    assigned.add(dto);
                    vehiculesDisponibles.remove(vehiculeOptimal); // Le véhicule est pris pour la journée
                } else {
                    unassigned.add(new ReservationDTO(r));
                }
            }
            
            // Trier les assignées par heure d'arrivée croissante
            assigned.sort((d1, d2) -> d1.getHeureArriveeParsed().compareTo(d2.getHeureArriveeParsed()));
            
            mv.addData("assigned", assigned);
            mv.addData("unassigned", unassigned);
            mv.addData("datePlanning", datePlanning);
            mv.addData("config", config);
        } catch (Exception e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du calcul de la planification: " + e.getMessage());
        }
        
        return mv;
    }
    
    /**
     * Trouve le véhicule optimal selon les règles métier :
     * 1. Places minimales mais >= nb_passagers
     * 2. Si plusieurs véhicules : priorité diesel > essence
     * 3. Si égalité totale : random
     */
    private Vehicule trouverVehiculeOptimal(List<Vehicule> vehiculesDisponibles, int nbPassagers) {
        List<Vehicule> candidats = new ArrayList<>();
        
        // Filtrer les véhicules avec assez de places
        for (Vehicule v : vehiculesDisponibles) {
            if (v.getPlace() >= nbPassagers) {
                candidats.add(v);
            }
        }
        
        if (candidats.isEmpty()) {
            return null;
        }
        
        // Trouver le nombre de places minimal parmi les candidats
        int placesMin = candidats.stream()
            .mapToInt(Vehicule::getPlace)
            .min()
            .orElse(Integer.MAX_VALUE);
        
        // Filtrer pour garder uniquement ceux avec le nombre de places minimal
        candidats = candidats.stream()
            .filter(v -> v.getPlace() == placesMin)
            .collect(java.util.stream.Collectors.toList());
        
        // Si un seul candidat, le retourner
        if (candidats.size() == 1) {
            return candidats.get(0);
        }
        
        // Priorité diesel
        List<Vehicule> diesels = candidats.stream()
            .filter(v -> v.getTypeCarburant().equalsIgnoreCase("diesel"))
            .collect(java.util.stream.Collectors.toList());
        
        if (!diesels.isEmpty()) {
            // Si plusieurs diesels, prendre random
            return diesels.get(new java.util.Random().nextInt(diesels.size()));
        }
        
        // Sinon prendre random parmi les essences
        return candidats.get(new java.util.Random().nextInt(candidats.size()));
    }
    
    /**
     * Récupère tous les lieux (pour debug/admin)
     */
    @MethodeAnnotation("/planning/lieux")
    @GetMapping
    public ModelView getAllLieux() {
        ModelView mv = new ModelView("/listLieux.jsp");
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            List<Lieu> lieux = Planning.getAllLieux(conn);
            mv.addData("lieux", lieux);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement des lieux: " + e.getMessage());
        }
        
        return mv;
    }
    
    /**
     * Récupère toutes les distances (pour debug/admin)
     */
    @MethodeAnnotation("/planning/distances")
    @GetMapping
    public ModelView getAllDistances() {
        ModelView mv = new ModelView("/listDistances.jsp");
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            List<Distance> distances = Planning.getAllDistances(conn);
            mv.addData("distances", distances);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement des distances: " + e.getMessage());
        }
        
        return mv;
    }
}
