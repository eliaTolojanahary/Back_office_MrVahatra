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
            List<ReservationEnrichi> reservationsEnrichies = new ArrayList<>();
            List<Lieu> lieux = Planning.getAllLieux(conn);
            
            // Récupérer l'aéroport (lieu de départ)
            Lieu aeroport = lieux.stream()
                .filter(l -> l.getCode().equals("IVATO"))
                .findFirst()
                .orElse(null);
            
            if (aeroport == null) {
                mv.addData("error", "Erreur: Aéroport IVATO non trouvé");
                return mv;
            }
            
            // Enrichir les réservations avec les informations de distance
            for (Reservation r : reservations) {
                // Trouver le lieu de l'hôtel
                Lieu lieuHotel = lieux.stream()
                    .filter(l -> l.getLibelle().toLowerCase().contains(r.getHotel().toLowerCase()) 
                              || r.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                    .findFirst()
                    .orElse(null);
                
                if (lieuHotel != null) {
                    // Récupérer la distance aéroport -> hôtel
                    double distanceKm = Distance.getDistanceBetween(aeroport.getId(), lieuHotel.getId(), distances);
                    
                    if (distanceKm > 0) {
                        reservationsEnrichies.add(new ReservationEnrichi(r, lieuHotel, distanceKm));
                    }
                }
            }
            
            // ========== RÈGLES DE GESTION - ASSIGNATION DES VÉHICULES ==========
            // RÈGLE 1 : Traiter d'abord les réservations avec le PLUS de passagers
            // RÈGLE 2 : Remplir OPTIMALEMENT chaque véhicule avant de passer au suivant
            // 
            // Tri des réservations : toujours par nb passagers décroissant puis distance croissante
            reservationsEnrichies.sort((r1, r2) -> {
                // D'abord par nombre de passagers décroissant (priorité absolue) - RÈGLE 1
                int cmpPassagers = Integer.compare(r2.reservation.getNbPassager(), r1.reservation.getNbPassager());
                if (cmpPassagers != 0) return cmpPassagers;
                // Ensuite par distance croissante (proximité de l'aéroport)
                return Double.compare(r1.getDistanceFromAeroport(), r2.getDistanceFromAeroport());
            });
            
            List<VehiclePlanningDTO> plannings = new ArrayList<>();
            List<ReservationDTO> unassigned = new ArrayList<>();
            List<ReservationEnrichi> reservationsRestantes = new ArrayList<>(reservationsEnrichies);
            
            // ========== RÈGLES DE GESTION - ASSIGNATION PAR CRÉNEAU (NOUVEAU) ==========
            // 1. Grouper les réservations par intervalle (ex: 08:00 - 08:30)
            // 2. L'heure de départ de TOUS les véhicules dans ce créneau sera l'heure MAX des réservations du créneau
            
            int pasMinutes = config != null && config.getTempsAttente() > 0 ? config.getTempsAttente() : 30;
            Map<String, List<ReservationEnrichi>> reservationsParCreneau = new LinkedHashMap<>();
            List<VehiclePlanningDTO> planningsTousLesCreneaux = new ArrayList<>(); // Pour vérifier la disponibilité globale et le nb de courses
            
            for (ReservationEnrichi r : reservationsEnrichies) {
                java.time.LocalDateTime dateHeure = parserDateHeureReservation(r.reservation.getDateHeureDepart());
                String cleCreneau = "Inconnu";
                if (dateHeure != null) {
                    int totalMinutes = dateHeure.getHour() * 60 + dateHeure.getMinute();
                    int debutCreneauMinutes = (totalMinutes / pasMinutes) * pasMinutes;
                    int finCreneauMinutes = debutCreneauMinutes + pasMinutes;
                    cleCreneau = formaterCreneau(debutCreneauMinutes, finCreneauMinutes);
                }
                reservationsParCreneau.computeIfAbsent(cleCreneau, k -> new ArrayList<>()).add(r);
            }
            
            // Pour chaque créneau (ordre chronologique impératif)
            List<Map.Entry<String, List<ReservationEnrichi>>> creneauxOrdonnes = new ArrayList<>(reservationsParCreneau.entrySet());
            creneauxOrdonnes.sort((e1, e2) -> Integer.compare(extraireDebutCreneauMinutes(e1.getKey()), extraireDebutCreneauMinutes(e2.getKey())));

            for (Map.Entry<String, List<ReservationEnrichi>> entry : creneauxOrdonnes) {
                String creneau = entry.getKey();
                List<ReservationEnrichi> resDansCreneau = entry.getValue();
                
                // Créer un nouveau véhicule pour cette réservation
                Vehicule vehicule = trouverVehiculeOptimal(vehicules, plannings, r.reservation.getNbPassager());
                
                if (vehicule != null) {
                    VehiclePlanningDTO nouveauPlanning = new VehiclePlanningDTO(
                        vehicule.getId(), 
                        vehicule.getReference(), 
                        vehicule.getPlace()
                    );
                    ajouterClientAuVehicule(nouveauPlanning, r, config, aeroport, distances, lieux);
                    plannings.add(nouveauPlanning);
                    
                    // MAXIMISER ce véhicule : continuer à ajouter des réservations
                    // tant qu'il reste de la place ET qu'une réservation peut entrer
                    remplirPlacesRestantesOptimal(nouveauPlanning, reservationsRestantes, config, aeroport, distances, lieux, r);
                } else {
                    unassigned.add(new ReservationDTO(r.reservation));
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
    
    /**
     * Ajoute un client (réservation) à un véhicule
     */
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
        double distanceTotaleKm = 0.0;
        StringBuilder trajet = new StringBuilder();
        String codeAeroport = aeroport.getCode() != null ? aeroport.getCode() : "IVATO";
        trajet.append(codeAeroport);
        
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
                double vitesse = (config != null && config.getVitesseMoyenne() > 0) ? config.getVitesseMoyenne() : 40.0;
                double tempsTrajet = distance / vitesse; // en heures
                tempsTotal += tempsTrajet;
                distanceTotaleKm += distance;
                trajet.append(" -> ").append(lieuHotel.getCode() != null ? lieuHotel.getCode() : lieuHotel.getLibelle());
                
                // NOTE : Le temps d'attente n'est PLUS pris en compte dans les calculs
                
                lieuPrecedent = lieuHotel;
            }
        }
        
        // Ajouter le retour à l'aéroport
        double distanceRetour = Distance.getDistanceBetween(lieuPrecedent.getId(), aeroport.getId(), distances);
        double vitesse = (config != null && config.getVitesseMoyenne() > 0) ? config.getVitesseMoyenne() : 40.0;
        double tempsRetour = distanceRetour / vitesse;
        tempsTotal += tempsRetour;
        // Affichage: distance/trajet aller uniquement (sans retour)
        planning.setDistanceParcourueKm(distanceTotaleKm);
        planning.setTrajetResume(trajet.toString());
        
        // L'heure de départ du véhicule = heure d'arrivée du DERNIER client du groupe à l'aéroport.
        try {
            java.time.LocalDateTime heureDepartVehicule = null;

            for (ClientInfo client : clients) {
                String heureArrivee = client.getHeureArriveeHotel();
                String[] parts = heureArrivee.split(":");
                java.time.LocalDateTime heureClient = java.time.LocalDate.now()
                    .atTime(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]));

                if (heureDepartVehicule == null || heureClient.isAfter(heureDepartVehicule)) {
                    heureDepartVehicule = heureClient;
                }
            }

            if (heureDepartVehicule == null) {
                return;
            }
            
            // Ajouter le temps total pour obtenir l'heure de retour
            long heures = (long) tempsTotal;
            long minutes = (long) ((tempsTotal - heures) * 60);
            java.time.LocalDateTime heureRetourVehicule = heureDepartVehicule.plusHours(heures).plusMinutes(minutes);
            
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
            planning.setDateHeureDepart(formatter.format(heureDepartVehicule));
            planning.setDateHeureRetour(formatter.format(heureRetourVehicule));
            planning.setHeureRetourParsed(heureRetourVehicule);
        } catch (Exception e) {
            System.err.println("Erreur parsing heure de départ: " + e.getMessage());
        }
    }
    
    /**
     * Remplit OPTIMALEMENT les places restantes d'un véhicule
     * 
     * Algorithme de maximisation :
     * 1. Tant qu'il reste de la place dans le véhicule
    * 2. Chercher la PLUS GRANDE réservation qui peut encore entrer
    *    dans la fenêtre [heure référence, heure référence + temps_attente]
     * 3. L'ajouter au véhicule
     * 4. Retirer de la liste des réservations restantes
     * 5. Répéter jusqu'à ce qu'aucune réservation ne puisse plus entrer
     * 
     * Cette méthode garantit un remplissage maximal en priorisant toujours
     * les plus grandes réservations compatibles
     */
    private void remplirPlacesRestantesOptimal(VehiclePlanningDTO planning, 
                                                List<ReservationEnrichi> reservationsRestantes,
                                                PlanningConfig config, Lieu aeroport, 
                                                List<Distance> distances, List<Lieu> lieux,
                                                ReservationEnrichi reservationReferenceFenetre) {
        boolean peutAjouterDautres = true;
        
        // Continuer tant qu'on peut ajouter des réservations
        while (peutAjouterDautres && planning.getPlacesRestantes() > 0 && !reservationsRestantes.isEmpty()) {
            peutAjouterDautres = false;
            
            // Chercher la PLUS GRANDE réservation qui peut entrer dans les places restantes
            int indexMeilleurCandidat = -1;
            int maxPassagers = 0;
            
            for (int i = 0; i < reservationsRestantes.size(); i++) {
                ReservationEnrichi r = reservationsRestantes.get(i);
                int nbPassagers = r.reservation.getNbPassager();

                boolean compatibleFenetre = estCompatibleFenetreHoraire(
                    reservationReferenceFenetre.reservation,
                    r.reservation,
                    config
                );
                
                // Si cette réservation peut entrer, respecte la fenêtre
                // et a plus de passagers que le meilleur candidat actuel
                if (planning.peutAccueillir(nbPassagers) && compatibleFenetre && nbPassagers > maxPassagers) {
                    indexMeilleurCandidat = i;
                    maxPassagers = nbPassagers;
                }
            }
            
            // Si on a trouvé un candidat compatible
            if (indexMeilleurCandidat != -1) {
                ReservationEnrichi meilleurCandidat = reservationsRestantes.remove(indexMeilleurCandidat);
                ajouterClientAuVehicule(planning, meilleurCandidat, config, aeroport, distances, lieux);
                peutAjouterDautres = true; // On continue à chercher d'autres réservations
            }
        }
    }

    private boolean estCompatibleFenetreHoraire(Reservation reservationReference,
                                                Reservation reservationCandidate,
                                                PlanningConfig config) {
        if (reservationReference == null || reservationCandidate == null || config == null) {
            return true;
        }

        java.time.LocalDateTime heureReference = parserDateHeureReservation(reservationReference.getDateHeureDepart());
        java.time.LocalDateTime heureCandidate = parserDateHeureReservation(reservationCandidate.getDateHeureDepart());

        if (heureReference == null || heureCandidate == null) {
            return true;
        }

        int tempsAttenteMinutes = Math.max(0, config.getTempsAttente());
        java.time.LocalDateTime borneFin = heureReference.plusMinutes(tempsAttenteMinutes);

        return !heureCandidate.isBefore(heureReference) && !heureCandidate.isAfter(borneFin);
    }

    private java.time.LocalDateTime parserDateHeureReservation(String dateHeure) {
        if (dateHeure == null || dateHeure.trim().isEmpty()) {
            return null;
        }

        try {
            return java.time.LocalDateTime.parse(dateHeure.replace(" ", "T"));
        } catch (Exception e) {
            return null;
        }
    }

    private Lieu trouverLieuPourReservation(Reservation reservation, List<Lieu> lieux) {
        if (reservation == null || lieux == null || lieux.isEmpty()) {
            return null;
        }

        String nomHotel = reservation.getHotel();
        if (nomHotel == null || nomHotel.trim().isEmpty()) {
            // Fallback: anciennes données éventuelles où id_hotel contient un id de lieu.
            return lieux.stream()
                .filter(l -> l.getId() == reservation.getIdHotel())
                .findFirst()
                .orElse(null);
        }

        Lieu lieuParNom = lieux.stream()
            .filter(l -> l.getLibelle().toLowerCase().contains(nomHotel.toLowerCase())
                      || nomHotel.toLowerCase().contains(l.getLibelle().toLowerCase()))
            .findFirst()
            .orElse(null);

        if (lieuParNom != null) {
            return lieuParNom;
        }

        // Fallback si aucun match sur le nom.
        return lieux.stream()
            .filter(l -> l.getId() == reservation.getIdHotel())
            .findFirst()
            .orElse(null);
    }

    private Map<String, List<Reservation>> grouperReservationsParCreneau(List<Reservation> reservations,
                                                                          int intervalleMinutes) {
        Map<String, List<Reservation>> groupes = new LinkedHashMap<>();
        int pasMinutes = intervalleMinutes > 0 ? intervalleMinutes : 30;

        if (reservations == null || reservations.isEmpty()) {
            return groupes;
        }

        for (Reservation reservation : reservations) {
            java.time.LocalDateTime dateHeure = parserDateHeureReservation(reservation.getDateHeureDepart());
            String cleCreneau;

            if (dateHeure == null) {
                cleCreneau = "Horaire invalide";
            } else {
                int totalMinutes = dateHeure.getHour() * 60 + dateHeure.getMinute();
                int debutCreneauMinutes = (totalMinutes / pasMinutes) * pasMinutes;
                int finCreneauMinutes = debutCreneauMinutes + pasMinutes;
                cleCreneau = formaterCreneau(debutCreneauMinutes, finCreneauMinutes);
            }

            groupes.computeIfAbsent(cleCreneau, k -> new ArrayList<>()).add(reservation);
        }

        return groupes;
    }

    private String formaterCreneau(int debutMinutes, int finMinutes) {
        int debutHeure = (debutMinutes / 60) % 24;
        int debutMinute = debutMinutes % 60;
        int finHeure = (finMinutes / 60) % 24;
        int finMinute = finMinutes % 60;

        return String.format("%02d:%02d - %02d:%02d", debutHeure, debutMinute, finHeure, finMinute);
    }

    private int extraireDebutCreneauMinutes(String creneau) {
        if (creneau == null || !creneau.contains("-")) {
            return Integer.MAX_VALUE;
        }

        try {
            String debut = creneau.split("-")[0].trim();
            String[] hm = debut.split(":");
            int h = Integer.parseInt(hm[0].trim());
            int m = Integer.parseInt(hm[1].trim());
            return (h * 60) + m;
        } catch (Exception e) {
            return Integer.MAX_VALUE;
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
    
    /**
     * PAGE DÉTAILS VÉHICULE : Affiche les détails du planning d'un véhicule spécifique
     * Sprint 4 - Feature: Detail Vehicule
     */
    @MethodeAnnotation("/planning/vehicule-detail")
    @PostMapping
    public ModelView getVehiculePlanningInfo(int idVehicule, String datePlanning) {
        ModelView mv = new ModelView("/detailVehicule.jsp");
        
        try (Connection conn = DatabaseConnection.getConnection()) {
            // Récupérer toutes les données nécessaires
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
            
            // Récupérer le véhicule spécifique
            Vehicule vehicule = vehicules.stream()
                .filter(v -> v.getId() == idVehicule)
                .findFirst()
                .orElse(null);
            
            if (vehicule == null) {
                mv.addData("error", "Véhicule non trouvé");
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
            
            // Tri des réservations selon les mêmes règles que dans getPlanningResult
            reservationsEnrichies.sort((r1, r2) -> {
                int cmpPassagers = Integer.compare(r2.reservation.getNbPassager(), r1.reservation.getNbPassager());
                if (cmpPassagers != 0) return cmpPassagers;
                return Double.compare(r1.getDistanceFromAeroport(), r2.getDistanceFromAeroport());
            });
            
            // Recréer le planning pour retrouver les clients assignés à ce véhicule
            List<VehiclePlanningDTO> plannings = new ArrayList<>();
            List<ReservationEnrichi> reservationsRestantes = new ArrayList<>(reservationsEnrichies);
            
            // Assignation des réservations (même logique que getPlanningResult)
            while (!reservationsRestantes.isEmpty()) {
                ReservationEnrichi r = reservationsRestantes.remove(0);
                
                Vehicule v = trouverVehiculeOptimal(vehicules, plannings, r.reservation.getNbPassager());
                
                if (v != null) {
                    VehiclePlanningDTO nouveauPlanning = new VehiclePlanningDTO(v.getId(), v.getReference(), v.getPlace());
                    ajouterClientAuVehicule(nouveauPlanning, r, config, aeroport, distances, lieux);
                    plannings.add(nouveauPlanning);
                    
                    // MAXIMISER ce véhicule avec les réservations restantes
                    remplirPlacesRestantesOptimal(nouveauPlanning, reservationsRestantes, config, aeroport, distances, lieux, r);
                }
            }
            
            // Trouver le planning pour ce véhicule spécifique
            VehiclePlanningDTO planning = plannings.stream()
                .filter(p -> p.getIdVehicule() == idVehicule)
                .findFirst()
                .orElse(null);
            
            if (planning == null) {
                mv.addData("error", "Aucun client assigné à ce véhicule pour cette date");
                mv.addData("vehicule", vehicule);
                mv.addData("datePlanning", datePlanning);
                return mv;
            }
            
            // Calculer l'itinéraire détaillé avec les heures d'arrivée et distances
            List<EtapeItineraire> itineraire = calculerItineraireDetaille(planning, config, aeroport, distances, lieux);
            
            // Calculer la distance totale
            double distanceTotale = itineraire.stream()
                .mapToDouble(EtapeItineraire::getDistance)
                .sum();
            
            mv.addData("vehicule", vehicule);
            mv.addData("planning", planning);
            mv.addData("itineraire", itineraire);
            mv.addData("distanceTotale", distanceTotale);
            mv.addData("datePlanning", datePlanning);
            mv.addData("config", config);
            
        } catch (Exception e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement des détails: " + e.getMessage());
        }
        
        return mv;
    }
    
    /**
     * Calcule l'itinéraire détaillé avec les heures d'arrivée à chaque étape
     */
    private List<EtapeItineraire> calculerItineraireDetaille(VehiclePlanningDTO planning, PlanningConfig config,
                                                              Lieu aeroport, List<Distance> distances, List<Lieu> lieux) {
        List<EtapeItineraire> itineraire = new ArrayList<>();
        
        if (planning.getClients().isEmpty()) return itineraire;
        
        // Trier les clients par distance de l'aéroport (même ordre que le trajet)
        List<ClientInfo> clientsTries = new ArrayList<>(planning.getClients());
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
        
        // Heure de départ du véhicule
        String heureDepart = planning.getDateHeureDepart();
        java.time.LocalDateTime heureActuelle = null;
        
        try {
            String[] parts = heureDepart.split(":");
            heureActuelle = java.time.LocalDate.now()
                .atTime(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]));
        } catch (Exception e) {
            return itineraire;
        }
        
        Lieu lieuActuel = aeroport;
        
        // Pour chaque client, calculer l'heure d'arrivée à son hôtel
        for (int i = 0; i < clientsTries.size(); i++) {
            ClientInfo client = clientsTries.get(i);
            
            // Trouver le lieu de l'hôtel
            Lieu lieuHotel = lieux.stream()
                .filter(l -> l.getLibelle().toLowerCase().contains(client.getHotel().toLowerCase()) 
                          || client.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                .findFirst()
                .orElse(null);
            
            if (lieuHotel != null) {
                // Calculer la distance vers cet hôtel
                double distance = Distance.getDistanceBetween(lieuActuel.getId(), lieuHotel.getId(), distances);
                
                // Calculer le temps de trajet
                double tempsTrajetHeures = distance / config.getVitesseMoyenne();
                long heures = (long) tempsTrajetHeures;
                long minutes = (long) ((tempsTrajetHeures - heures) * 60);
                
                heureActuelle = heureActuelle.plusHours(heures).plusMinutes(minutes);
                
                java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
                String heureArrivee = formatter.format(heureActuelle);
                
                // Créer l'étape
                EtapeItineraire etape = new EtapeItineraire();
                etape.setOrdre(i + 1);
                etape.setLieuDepart(lieuActuel.getLibelle());
                etape.setLieuArrivee(lieuHotel.getLibelle());
                etape.setDistance(distance);
                etape.setHeureArrivee(heureArrivee);
                etape.setNomClient(client.getNomClient());
                etape.setNbPassager(client.getNbPassager());
                
                itineraire.add(etape);
                
                // Ajouter le temps d'attente
                if (config.getTempsAttente() > 0) {
                    heureActuelle = heureActuelle.plusMinutes(config.getTempsAttente());
                }
                
                lieuActuel = lieuHotel;
            }
        }
        
        // Ajouter le retour à l'aéroport
        double distanceRetour = Distance.getDistanceBetween(lieuActuel.getId(), aeroport.getId(), distances);
        double tempsRetourHeures = distanceRetour / config.getVitesseMoyenne();
        long heuresRetour = (long) tempsRetourHeures;
        long minutesRetour = (long) ((tempsRetourHeures - heuresRetour) * 60);
        
        heureActuelle = heureActuelle.plusHours(heuresRetour).plusMinutes(minutesRetour);
        
        java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
        String heureArriveeAeroport = formatter.format(heureActuelle);
        
        EtapeItineraire etapeRetour = new EtapeItineraire();
        etapeRetour.setOrdre(clientsTries.size() + 1);
        etapeRetour.setLieuDepart(lieuActuel.getLibelle());
        etapeRetour.setLieuArrivee(aeroport.getLibelle());
        etapeRetour.setDistance(distanceRetour);
        etapeRetour.setHeureArrivee(heureArriveeAeroport);
        etapeRetour.setNomClient("Retour aéroport");
        etapeRetour.setNbPassager(0);
        
        itineraire.add(etapeRetour);
        
        return itineraire;
    }
    
    /**
     * Classe interne pour représenter une étape de l'itinéraire
     */
    public static class EtapeItineraire {
        private int ordre;
        private String lieuDepart;
        private String lieuArrivee;
        private double distance;
        private String heureArrivee;
        private String nomClient;
        private int nbPassager;
        
        public int getOrdre() { return ordre; }
        public void setOrdre(int ordre) { this.ordre = ordre; }
        
        public String getLieuDepart() { return lieuDepart; }
        public void setLieuDepart(String lieuDepart) { this.lieuDepart = lieuDepart; }
        
        public String getLieuArrivee() { return lieuArrivee; }
        public void setLieuArrivee(String lieuArrivee) { this.lieuArrivee = lieuArrivee; }
        
        public double getDistance() { return distance; }
        public void setDistance(double distance) { this.distance = distance; }
        
        public String getHeureArrivee() { return heureArrivee; }
        public void setHeureArrivee(String heureArrivee) { this.heureArrivee = heureArrivee; }
        
        public String getNomClient() { return nomClient; }
        public void setNomClient(String nomClient) { this.nomClient = nomClient; }
        
        public int getNbPassager() { return nbPassager; }
        public void setNbPassager(int nbPassager) { this.nbPassager = nbPassager; }
    }
}
