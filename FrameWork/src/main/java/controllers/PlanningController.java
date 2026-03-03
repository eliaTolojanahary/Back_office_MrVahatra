package controllers;

import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import models.*;
import modelview.ModelView;
import util.DatabaseConnection;

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
    
   
    @MethodeAnnotation("/planning/result")
    @PostMapping
    public ModelView getPlanningResult(String datePlanning) {
        ModelView mv = new ModelView("/resultPlanning.jsp");
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            List<Reservation> reservations = Planning.getReservationsByDate(conn, datePlanning);
            List<Vehicule> vehicules = Planning.getAllVehicules(conn);
            PlanningConfig config = Planning.getActiveConfig(conn);
            List<Distance> distances = Planning.getAllDistances(conn);
            List<Lieu> lieux = Planning.getAllLieux(conn);
            
            Lieu aeroport = lieux.stream()
                .filter(l -> l.getCode().equals("IVATO"))
                .findFirst()
                .orElse(null);
            
            if (aeroport == null) {
                mv.addData("error", "Erreur: Aéroport IVATO non trouvé");
                return mv;
            }
            
            // Enrichir les réservations avec les informations de distance
            List<ReservationEnrichi> reservationsEnrichies = new ArrayList<>();
            for (Reservation r : reservations) {
                Lieu lieuHotel = lieux.stream()
                    .filter(l -> l.getLibelle().toLowerCase().contains(r.getHotel().toLowerCase()) 
                              || r.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                    .findFirst()
                    .orElse(null);
                
                if (lieuHotel != null) {
                    double distanceFromAeroport = Distance.getDistanceBetween(aeroport.getId(), lieuHotel.getId(), distances);
                    if (distanceFromAeroport > 0) {
                        reservationsEnrichies.add(new ReservationEnrichi(r, lieuHotel, distanceFromAeroport));
                    }
                }
            }
            
            // Tri des réservations : toujours par nb passagers décroissant puis distance croissante
            reservationsEnrichies.sort((r1, r2) -> {
                // D'abord par nombre de passagers décroissant (priorité absolue)
                int cmpPassagers = Integer.compare(r2.reservation.getNbPassager(), r1.reservation.getNbPassager());
                if (cmpPassagers != 0) return cmpPassagers;
                // Ensuite par distance croissante (proximité de l'aéroport)
                return Double.compare(r1.getDistanceFromAeroport(), r2.getDistanceFromAeroport());
            });
            
            List<VehiclePlanningDTO> plannings = new ArrayList<>();
            List<ReservationDTO> unassigned = new ArrayList<>();
            List<ReservationEnrichi> reservationsRestantes = new ArrayList<>(reservationsEnrichies);
            
            // Assignation des réservations
            if (config.getTempsAttente() == 0) {
                // Mode groupement strict par heure : on ne peut grouper QUE les clients à la même heure
                while (!reservationsRestantes.isEmpty()) {
                    ReservationEnrichi r = reservationsRestantes.remove(0);
                    String dateHeureClient = r.reservation.getDateHeureDepart();
                    
                    // Créer un nouveau véhicule pour ce client
                    Vehicule vehicule = trouverVehiculeOptimal(vehicules, plannings, r.reservation.getNbPassager());
                    
                    if (vehicule != null) {
                        VehiclePlanningDTO nouveauPlanning = new VehiclePlanningDTO(
                            vehicule.getId(), 
                            vehicule.getReference(), 
                            vehicule.getPlace()
                        );
                        ajouterClientAuVehicule(nouveauPlanning, r, config, aeroport, distances, lieux);
                        plannings.add(nouveauPlanning);
                        
                        // Remplir places restantes UNIQUEMENT avec clients ayant la même date_heure
                        List<ReservationEnrichi> candidatsMemeHeure = new ArrayList<>();
                        for (int i = reservationsRestantes.size() - 1; i >= 0; i--) {
                            if (reservationsRestantes.get(i).reservation.getDateHeureDepart().equals(dateHeureClient)) {
                                candidatsMemeHeure.add(reservationsRestantes.remove(i));
                            }
                        }
                        remplirPlacesRestantes(nouveauPlanning, candidatsMemeHeure, config, aeroport, distances, lieux);
                    } else {
                        unassigned.add(new ReservationDTO(r.reservation));
                    }
                }
            } else {
                // Mode normal : assignation avec remplissage opportuniste (tous clients compatibles)
                while (!reservationsRestantes.isEmpty()) {
                    ReservationEnrichi r = reservationsRestantes.remove(0);
                    
                    // Trouver un véhicule qui peut accueillir ce client
                    VehiclePlanningDTO planningExistant = trouverVehiculePourClient(plannings, r.reservation.getNbPassager());
                    
                    if (planningExistant != null) {
                        // Ajouter le client au véhicule existant
                        ajouterClientAuVehicule(planningExistant, r, config, aeroport, distances, lieux);
                    } else {
                        // Créer un nouveau planning avec un nouveau véhicule
                        Vehicule vehicule = trouverVehiculeOptimal(vehicules, plannings, r.reservation.getNbPassager());
                        
                        if (vehicule != null) {
                            VehiclePlanningDTO nouveauPlanning = new VehiclePlanningDTO(
                                vehicule.getId(), 
                                vehicule.getReference(), 
                                vehicule.getPlace()
                            );
                            ajouterClientAuVehicule(nouveauPlanning, r, config, aeroport, distances, lieux);
                            plannings.add(nouveauPlanning);
                            
                            // Essayer de remplir les places restantes avec d'autres clients
                            remplirPlacesRestantes(nouveauPlanning, reservationsRestantes, config, aeroport, distances, lieux);
                        } else {
                            unassigned.add(new ReservationDTO(r.reservation));
                        }
                    }
                }
            }
            
            // Trier les plannings par ID véhicule croissant
            plannings.sort((p1, p2) -> Integer.compare(p1.getIdVehicule(), p2.getIdVehicule()));
            
            mv.addData("plannings", plannings);
            mv.addData("unassigned", unassigned);
            mv.addData("datePlanning", datePlanning);
            mv.addData("config", config);
        } catch (Exception e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du calcul de la planification: " + e.getMessage());
        }
        
        return mv;
    }
    
    
    private VehiclePlanningDTO trouverVehiculePourClient(List<VehiclePlanningDTO> plannings, int nbPassagers) {
        for (VehiclePlanningDTO planning : plannings) {
            if (planning.peutAccueillir(nbPassagers)) {
                return planning;
            }
        }
        return null;
    }
    
    /**
     * Assigne un groupe de clients arrivant à la même heure aux véhicules
     * (utilisé quand temps_attente = 0)
     */
    private void assignerGroupeAuxVehicules(List<ReservationEnrichi> groupe,
                                           List<VehiclePlanningDTO> plannings,
                                           List<Vehicule> vehicules,
                                           List<ReservationDTO> unassigned,
                                           PlanningConfig config, Lieu aeroport,
                                           List<Distance> distances, List<Lieu> lieux) {
        // Le groupe est déjà trié par nombre de passagers décroissant et distance croissante
        List<ReservationEnrichi> reservationsRestantes = new ArrayList<>(groupe);
        
        while (!reservationsRestantes.isEmpty()) {
            ReservationEnrichi r = reservationsRestantes.remove(0);
            
            // Créer un nouveau véhicule pour ce client/groupe
            Vehicule vehicule = trouverVehiculeOptimal(vehicules, plannings, r.reservation.getNbPassager());
            
            if (vehicule != null) {
                VehiclePlanningDTO nouveauPlanning = new VehiclePlanningDTO(
                    vehicule.getId(),
                    vehicule.getReference(),
                    vehicule.getPlace()
                );
                ajouterClientAuVehicule(nouveauPlanning, r, config, aeroport, distances, lieux);
                plannings.add(nouveauPlanning);
                
                // Remplir les places restantes avec d'autres clients du même groupe
                remplirPlacesRestantes(nouveauPlanning, reservationsRestantes, config, aeroport, distances, lieux);
            } else {
                unassigned.add(new ReservationDTO(r.reservation));
            }
        }
    }
    

    private void ajouterClientAuVehicule(VehiclePlanningDTO planning, ReservationEnrichi r, 
                                         PlanningConfig config, Lieu aeroport, 
                                         List<Distance> distances, List<Lieu> lieux) {
        try {
            // Parse la date heure d'arrivée du client
            java.time.LocalDateTime dateHeureArriveeClient = java.time.LocalDateTime.parse(
                r.reservation.getDateHeureDepart().replace(" ", "T")
            );
            
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
            String heureArriveeStr = formatter.format(dateHeureArriveeClient);
            
            // Ajouter le client (utilise lieuHotel de ReservationEnrichi)
            planning.ajouterClient(
                r.reservation.getClient(),
                r.reservation.getNbPassager(),
                r.lieuHotel != null ? r.lieuHotel.getLibelle() : r.reservation.getHotel(),
                heureArriveeStr,
                r.reservation.getId()
            );
            
            // Recalculer les horaires du véhicule en fonction de tous les clients
            recalculerHorairesVehicule(planning, config, aeroport, distances, lieux);
            
        } catch (java.time.format.DateTimeParseException e) {
            System.err.println("Erreur de parsing de la date: " + e.getMessage());
        }
    }
    
    /**
     * Recalcule les horaires de départ et retour du véhicule en fonction de tous ses clients
     * 
     * Logique:
     * - heureArriveeHotel du ClientInfo = heure d'arrivée du client à l'aéroport (= heure départ véhicule)
     * - Calcul itinéraire: aéroport -> hotel1 + temps_attente -> hotel2 + temps_attente -> ... -> retour aéroport
     * - Heure retour = heure départ + temps total
     */
    private void recalculerHorairesVehicule(VehiclePlanningDTO planning, PlanningConfig config,
                                            Lieu aeroport, List<Distance> distances, List<Lieu> lieux) {
        if (planning.getClients().isEmpty()) return;
        
        List<ClientInfo> clients = planning.getClients();
        
        // Trier les clients par distance de l'aéroport (plus proche d'abord) pour optimiser l'itinéraire
        List<ClientInfo> clientsTries = new ArrayList<>(clients);
        clientsTries.sort((c1, c2) -> {
            Lieu h1 = lieux.stream()
                .filter(l -> l.getLibelle().toLowerCase().contains(c1.getHotel().toLowerCase()) 
                          || c1.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                .findFirst().orElse(null);
            Lieu h2 = lieux.stream()
                .filter(l -> l.getLibelle().toLowerCase().contains(c2.getHotel().toLowerCase()) 
                          || c2.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                .findFirst().orElse(null);
            
            if (h1 == null || h2 == null) return 0;
            double dist1 = Distance.getDistanceBetween(aeroport.getId(), h1.getId(), distances);
            double dist2 = Distance.getDistanceBetween(aeroport.getId(), h2.getId(), distances);
            return Double.compare(dist1, dist2);
        });
        
        // Calculer le temps total de trajet
        // Itinéraire: aéroport -> hotel_plus_proche -> hotel2 -> ... -> hotel_plus_loin -> retour aéroport
        Lieu lieuPrecedent = aeroport;
        double tempsTotal = 0; // en heures
        
        for (ClientInfo client : clientsTries) {
            // Trouver le lieu de l'hôtel
            Lieu lieuHotel = lieux.stream()
                .filter(l -> l.getLibelle().toLowerCase().contains(client.getHotel().toLowerCase()) 
                          || client.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                .findFirst()
                .orElse(null);
            
            if (lieuHotel != null) {
                // Ajouter temps de trajet vers cet hôtel
                double distance = Distance.getDistanceBetween(lieuPrecedent.getId(), lieuHotel.getId(), distances);
                double tempsTrajet = distance / config.getVitesseMoyenne(); // en heures
                tempsTotal += tempsTrajet;
                
                // Ajouter temps d'attente (sauf si c'est déjà compris dans le calcul)
                if (config.getTempsAttente() > 0) {
                    tempsTotal += config.getTempsAttente() / 60.0; // convertir minutes en heures
                }
                
                lieuPrecedent = lieuHotel;
            }
        }
        
        // Ajouter le retour à l'aéroport
        double distanceRetour = Distance.getDistanceBetween(lieuPrecedent.getId(), aeroport.getId(), distances);
        double tempsRetour = distanceRetour / config.getVitesseMoyenne();
        tempsTotal += tempsRetour;
        
        // L'heure de départ du véhicule = heure d'arrivée du premier client à l'aéroport
        // (stockée dans heureArriveeHotel du premier client)
        try {
            String heureDepart = clients.get(0).getHeureArriveeHotel(); // HH:mm
            
            // Parser l'heure et créer un LocalDateTime pour aujourd'hui
            String[] parts = heureDepart.split(":");
            java.time.LocalDateTime heureDepotVehicule = java.time.LocalDate.now()
                .atTime(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]));
            
            // Ajouter le temps total pour obtenir l'heure de retour
            long heures = (long) tempsTotal;
            long minutes = (long) ((tempsTotal - heures) * 60);
            java.time.LocalDateTime heureRetourVehicule = heureDepotVehicule.plusHours(heures).plusMinutes(minutes);
            
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
            planning.setDateHeureDepart(formatter.format(heureDepotVehicule));
            planning.setDateHeureRetour(formatter.format(heureRetourVehicule));
            planning.setHeureRetourParsed(heureRetourVehicule);
        } catch (Exception e) {
            System.err.println("Erreur parsing heure de départ: " + e.getMessage());
        }
    }
    
    /**
     * Remplit les places restantes d'un véhicule avec d'autres clients compatibles
     */
    private void remplirPlacesRestantes(VehiclePlanningDTO planning, List<ReservationEnrichi> reservationsRestantes,
                                        PlanningConfig config, Lieu aeroport, 
                                        List<Distance> distances, List<Lieu> lieux) {
        boolean remplissageContinue = true;
        
        while (remplissageContinue && planning.getPlacesRestantes() > 0) {
            remplissageContinue = false;
            
            // Chercher un client compatible
            for (int i = 0; i < reservationsRestantes.size(); i++) {
                ReservationEnrichi r = reservationsRestantes.get(i);
                
                if (planning.peutAccueillir(r.reservation.getNbPassager())) {
                    ajouterClientAuVehicule(planning, r, config, aeroport, distances, lieux);
                    reservationsRestantes.remove(i);
                    remplissageContinue = true;
                    break;
                }
            }
        }
    }
    
    /**
     * Trouve le véhicule optimal parmi les véhicules disponibles (non encore utilisés)
     */
    private Vehicule trouverVehiculeOptimal(List<Vehicule> tousVehicules, 
                                            List<VehiclePlanningDTO> planningsExistants, 
                                            int nbPassagers) {
        // Filtrer les véhicules déjà utilisés
        List<Integer> idsUtilises = planningsExistants.stream()
            .map(VehiclePlanningDTO::getIdVehicule)
            .collect(java.util.stream.Collectors.toList());
        
        List<Vehicule> vehiculesDisponibles = tousVehicules.stream()
            .filter(v -> !idsUtilises.contains(v.getId()))
            .collect(java.util.stream.Collectors.toList());
        
        return trouverVehiculeOptimal(vehiculesDisponibles, nbPassagers);
    }
    
    
    private Vehicule trouverVehiculeOptimal(List<Vehicule> vehiculesDisponibles, int nbPassagers) {
        List<Vehicule> candidats = new ArrayList<>();
        
        
        for (Vehicule v : vehiculesDisponibles) {
            if (v.getPlace() >= nbPassagers) {
                candidats.add(v);
            }
        }
        
        if (candidats.isEmpty()) {
            return null;
        }
        
        int placesMin = candidats.stream()
            .mapToInt(Vehicule::getPlace)
            .min()
            .orElse(Integer.MAX_VALUE);
        
      
        candidats = candidats.stream()
            .filter(v -> v.getPlace() == placesMin)
            .collect(java.util.stream.Collectors.toList());
        
        if (candidats.size() == 1) {
            return candidats.get(0);
        }
        
        List<Vehicule> diesels = candidats.stream()
            .filter(v -> v.getTypeCarburant().equalsIgnoreCase("diesel"))
            .collect(java.util.stream.Collectors.toList());
        
        if (!diesels.isEmpty()) {
            
            return diesels.get(new java.util.Random().nextInt(diesels.size()));
        }
        return candidats.get(new java.util.Random().nextInt(candidats.size()));
    }
    
   
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
