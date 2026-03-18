package services;

import models.*;
import util.DatabaseConnection;

import java.sql.*;
import java.util.*;

public class PlanningService {

    public PlanningConfig getActiveConfig() throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            return Planning.getActiveConfig(conn);
        }
    }

    public boolean savePlanningConfig(PlanningConfig config) throws SQLException {
        boolean success = false;
        try (Connection conn = DatabaseConnection.getConnection()) {
            String sqlUpdate = "UPDATE planning_config SET is_active = false WHERE is_active = true";
            try (PreparedStatement stmtUpdate = conn.prepareStatement(sqlUpdate)) {
                stmtUpdate.executeUpdate();
            }
            
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
        }
        return success;
    }

    public List<Lieu> getAllLieux() throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            return Planning.getAllLieux(conn);
        }
    }

    public List<Distance> getAllDistances() throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            return Planning.getAllDistances(conn);
        }
    }

    public List<Reservation> getReservationsByDate(String datePlanningNormalisee) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            return Planning.getReservationsByDate(conn, datePlanningNormalisee);
        }
    }

    public Map<String, Object> getPlanningResultData(String datePlanning) throws Exception {
        Map<String, Object> result = new HashMap<>();
        String datePlanningNormalisee = normaliserDatePlanning(datePlanning);
        result.put("datePlanningNormalisee", datePlanningNormalisee);

        if (datePlanningNormalisee == null) {
            result.put("error", "Date invalide. Utiliser le format yyyy-MM-dd ou dd/MM/yyyy.");
            return result;
        }

        List<Reservation> reservations = getReservationsByDate(datePlanningNormalisee);
        List<Vehicule> vehicules = getAllVehicules();
        PlanningConfig config = getActiveConfig();
        List<Distance> distances = getAllDistances();
        List<Lieu> lieux = getAllLieux();

        Lieu aeroport = lieux.stream()
            .filter(l -> l.getCode().equals("IVATO"))
            .findFirst()
            .orElse(null);

        if (aeroport == null) {
            result.put("error", "Erreur: A�roport IVATO non trouv�");
            return result;
        }

        List<ReservationEnrichi> reservationsEnrichies = new ArrayList<>();
        for (Reservation r : reservations) {
            Lieu lieuHotel = trouverLieuPourReservation(r, lieux);
            if (lieuHotel != null) {
                double distanceKm = Distance.getDistanceBetween(aeroport.getId(), lieuHotel.getId(), distances);
                reservationsEnrichies.add(new ReservationEnrichi(r, lieuHotel, Math.max(0.0, distanceKm)));
            }
        }

        reservationsEnrichies.sort((r1, r2) -> {
            int cmpPassagers = Integer.compare(r2.reservation.getNbPassager(), r1.reservation.getNbPassager());
            if (cmpPassagers != 0) return cmpPassagers;
            return Double.compare(r1.getDistanceFromAeroport(), r2.getDistanceFromAeroport());
        });

        Map<String, List<VehiclePlanningDTO>> planningsParCreneauMap = new LinkedHashMap<>();
        Map<String, List<ReservationDTO>> unassignedParCreneauMap = new LinkedHashMap<>();

        int pasMinutes = config != null && config.getTempsAttente() > 0 ? config.getTempsAttente() : 30;
        Map<String, List<ReservationEnrichi>> reservationsParCreneau = new LinkedHashMap<>();
        List<VehiclePlanningDTO> planningsTousLesCreneaux = new ArrayList<>(); 

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

        List<Map.Entry<String, List<ReservationEnrichi>>> creneauxOrdonnes = new ArrayList<>(reservationsParCreneau.entrySet());
        creneauxOrdonnes.sort((e1, e2) -> Integer.compare(extraireDebutCreneauMinutes(e1.getKey()), extraireDebutCreneauMinutes(e2.getKey())));

        for (Map.Entry<String, List<ReservationEnrichi>> entry : creneauxOrdonnes) {
            String creneau = entry.getKey();
            List<ReservationEnrichi> resDansCreneau = entry.getValue();

            List<VehiclePlanningDTO> planningsCurrentCreneau = new ArrayList<>();
            List<ReservationDTO> unassignedCurrentCreneau = new ArrayList<>();

            java.time.LocalDateTime heureMaxCreneau = null;
            for(ReservationEnrichi r : resDansCreneau) {
                java.time.LocalDateTime dh = parserDateHeureReservation(r.reservation.getDateHeureDepart());
                if (dh != null && (heureMaxCreneau == null || dh.isAfter(heureMaxCreneau))) {
                    heureMaxCreneau = dh;
                }
            }

            resDansCreneau.sort((r1, r2) -> {
                int cmpPassagers = Integer.compare(r2.reservation.getNbPassager(), r1.reservation.getNbPassager());
                if (cmpPassagers != 0) return cmpPassagers;
                return Double.compare(r1.getDistanceFromAeroport(), r2.getDistanceFromAeroport());
            });

            while (!resDansCreneau.isEmpty()) {
                ReservationEnrichi r = resDansCreneau.remove(0);
                Vehicule vehicule = trouverVehiculeOptimal(vehicules, planningsTousLesCreneaux, r.reservation, heureMaxCreneau);

                if (vehicule != null) {
                    VehiclePlanningDTO nouveauPlanning = new VehiclePlanningDTO(
                        vehicule.getId(), 
                        vehicule.getReference(), 
                        vehicule.getPlace()
                    );
                    ajouterClientAuVehicule(nouveauPlanning, r, config, aeroport, distances, lieux, heureMaxCreneau);
                    planningsCurrentCreneau.add(nouveauPlanning);
                    planningsTousLesCreneaux.add(nouveauPlanning);

                    remplirPlacesRestantesOptimal(nouveauPlanning, resDansCreneau, config, aeroport, distances, lieux, r, heureMaxCreneau);
                } else {
                    unassignedCurrentCreneau.add(new ReservationDTO(r.reservation));
                }
            }

            planningsCurrentCreneau.sort((p1, p2) -> Integer.compare(p1.getIdVehicule(), p2.getIdVehicule()));
            planningsParCreneauMap.put(creneau, planningsCurrentCreneau);
            unassignedParCreneauMap.put(creneau, unassignedCurrentCreneau);
        }

        result.put("planningsParCreneauMap", planningsParCreneauMap);
        result.put("unassignedParCreneauMap", unassignedParCreneauMap);
        result.put("config", config);
        
        return result;
    }

    public Map<String, Object> getVehiculePlanningInfoData(int idVehicule, String datePlanning) throws Exception {
        Map<String, Object> result = new HashMap<>();

        List<Reservation> reservations = getReservationsByDate(datePlanning);
        List<Vehicule> vehicules = getAllVehicules();
        PlanningConfig config = getActiveConfig();
        List<Distance> distances = getAllDistances();
        List<Lieu> lieux = getAllLieux();

        Lieu aeroport = lieux.stream()
            .filter(l -> l.getCode().equals("IVATO"))
            .findFirst()
            .orElse(null);

        if (aeroport == null) {
            result.put("error", "Erreur: A�roport IVATO non trouv�");
            return result;
        }

        Vehicule vehicule = vehicules.stream()
            .filter(v -> v.getId() == idVehicule)
            .findFirst()
            .orElse(null);

        if (vehicule == null) {
            result.put("error", "V�hicule non trouv�");
            return result;
        }

        List<ReservationEnrichi> reservationsEnrichies = new ArrayList<>();
        for (Reservation r : reservations) {
            Lieu lieuHotel = trouverLieuPourReservation(r, lieux);
            if (lieuHotel != null) {
                double distanceFromAeroport = Distance.getDistanceBetween(aeroport.getId(), lieuHotel.getId(), distances);
                reservationsEnrichies.add(new ReservationEnrichi(r, lieuHotel, Math.max(0.0, distanceFromAeroport)));
            }
        }

        reservationsEnrichies.sort((r1, r2) -> {
            int cmpPassagers = Integer.compare(r2.reservation.getNbPassager(), r1.reservation.getNbPassager());
            if (cmpPassagers != 0) return cmpPassagers;
            return Double.compare(r1.getDistanceFromAeroport(), r2.getDistanceFromAeroport());
        });

        List<VehiclePlanningDTO> plannings = new ArrayList<>();

        int pasMinutes = config != null && config.getTempsAttente() > 0 ? config.getTempsAttente() : 30;
        Map<String, List<ReservationEnrichi>> reservationsParCreneau = new LinkedHashMap<>();

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

        for (Map.Entry<String, List<ReservationEnrichi>> entry : reservationsParCreneau.entrySet()) {
            List<ReservationEnrichi> resDansCreneau = entry.getValue();

            java.time.LocalDateTime heureMaxCreneau = null;
            for(ReservationEnrichi r : resDansCreneau) {
                java.time.LocalDateTime dh = parserDateHeureReservation(r.reservation.getDateHeureDepart());
                if (dh != null && (heureMaxCreneau == null || dh.isAfter(heureMaxCreneau))) {
                    heureMaxCreneau = dh;
                }
            }

            while (!resDansCreneau.isEmpty()) {
                ReservationEnrichi r = resDansCreneau.remove(0);
                Vehicule v = trouverVehiculeOptimal(vehicules, plannings, r.reservation, heureMaxCreneau);

                if (v != null) {
                    VehiclePlanningDTO nouveauPlanning = new VehiclePlanningDTO(v.getId(), v.getReference(), v.getPlace());
                    ajouterClientAuVehicule(nouveauPlanning, r, config, aeroport, distances, lieux, heureMaxCreneau);
                    plannings.add(nouveauPlanning);

                    remplirPlacesRestantesOptimal(nouveauPlanning, resDansCreneau, config, aeroport, distances, lieux, r, heureMaxCreneau);
                }
            }
        }

        VehiclePlanningDTO planning = plannings.stream()
            .filter(p -> p.getIdVehicule() == idVehicule)
            .findFirst()
            .orElse(null);

        if (planning == null) {
            result.put("error", "Aucun client assign� � ce v�hicule pour cette date");
            result.put("vehicule", vehicule);
            result.put("datePlanning", datePlanning);
            return result;
        }

        List<EtapeItineraire> itineraire = calculerItineraireDetaille(planning, config, aeroport, distances, lieux);

        double distanceTotale = itineraire.stream()
            .mapToDouble(EtapeItineraire::getDistance)
            .sum();

        result.put("vehicule", vehicule);
        result.put("planning", planning);
        result.put("itineraire", itineraire);
        result.put("distanceTotale", distanceTotale);
        result.put("datePlanning", datePlanning);
        result.put("config", config);

        return result;
    }

    public Map<String, List<Reservation>> grouperReservationsParCreneau(List<Reservation> reservations, int intervalleMinutes) {
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

    public String normaliserDatePlanning(String datePlanning) {
        if (datePlanning == null) {
            return null;
        }

        String valeur = datePlanning.trim();
        if (valeur.isEmpty()) {
            return null;
        }

        try {
            java.time.LocalDate d = java.time.LocalDate.parse(valeur);
            return d.toString();
        } catch (Exception ignored) {
        }

        try {
            java.time.format.DateTimeFormatter f = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy");
            java.time.LocalDate d = java.time.LocalDate.parse(valeur, f);
            return d.toString();
        } catch (Exception ignored) {
        }

        return null;
    }

    public void ajouterClientAuVehicule(VehiclePlanningDTO planning, ReservationEnrichi r, 
                                         PlanningConfig config, Lieu aeroport, 
                                         List<Distance> distances, List<Lieu> lieux, java.time.LocalDateTime heureDepartForcee) {
        try {
            java.time.LocalDateTime dateHeureArriveeClient = java.time.LocalDateTime.parse(
                r.reservation.getDateHeureDepart().replace(" ", "T")
            );
            
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
            String heureArriveeStr = formatter.format(dateHeureArriveeClient);
            
            planning.ajouterClient(
                r.reservation.getClient(),
                r.reservation.getNbPassager(),
                r.lieuHotel != null ? r.lieuHotel.getLibelle() : r.reservation.getHotel(),
                heureArriveeStr,
                r.reservation.getId()
            );
            
            recalculerHorairesVehicule(planning, config, aeroport, distances, lieux, heureDepartForcee);
            
        } catch (java.time.format.DateTimeParseException e) {
            System.err.println("Erreur de parsing de la date: " + e.getMessage());
        }
    }

    public void recalculerHorairesVehicule(VehiclePlanningDTO planning, PlanningConfig config,
                                            Lieu aeroport, List<Distance> distances, List<Lieu> lieux, java.time.LocalDateTime heureDepartForcee) {
        if (planning.getClients().isEmpty()) return;
        
        List<ClientInfo> clients = planning.getClients();
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
        
        Lieu lieuPrecedent = aeroport;
        double tempsTotal = 0; 
        double distanceTotaleKm = 0.0;
        StringBuilder trajet = new StringBuilder();
        String codeAeroport = aeroport.getCode() != null ? aeroport.getCode() : "IVATO";
        trajet.append(codeAeroport);
        
        for (ClientInfo client : clientsTries) {
            Lieu lieuHotel = lieux.stream()
                .filter(l -> l.getLibelle().toLowerCase().contains(client.getHotel().toLowerCase()) 
                          || client.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                .findFirst()
                .orElse(null);
            
            if (lieuHotel != null) {
                double distance = Distance.getDistanceBetween(lieuPrecedent.getId(), lieuHotel.getId(), distances);
                double vitesse = (config != null && config.getVitesseMoyenne() > 0) ? config.getVitesseMoyenne() : 40.0;
                double tempsTrajet = distance / vitesse; 
                tempsTotal += tempsTrajet;
                distanceTotaleKm += distance;
                trajet.append(" -> ").append(lieuHotel.getCode() != null ? lieuHotel.getCode() : lieuHotel.getLibelle());
                lieuPrecedent = lieuHotel;
            }
        }
        
        double distanceRetour = Distance.getDistanceBetween(lieuPrecedent.getId(), aeroport.getId(), distances);
        double vitesse = (config != null && config.getVitesseMoyenne() > 0) ? config.getVitesseMoyenne() : 40.0;
        double tempsRetour = distanceRetour / vitesse;
        tempsTotal += tempsRetour;
        planning.setDistanceParcourueKm(distanceTotaleKm);
        planning.setTrajetResume(trajet.toString());
        
        try {
            java.time.LocalDateTime heureDepartVehicule = heureDepartForcee;

            if (heureDepartVehicule == null) {
                for (ClientInfo client : clients) {
                    String heureArrivee = client.getHeureArriveeHotel();
                    String[] parts = heureArrivee.split(":");
                    java.time.LocalDateTime heureClient = java.time.LocalDate.now()
                        .atTime(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]));

                    if (heureDepartVehicule == null || heureClient.isAfter(heureDepartVehicule)) {
                        heureDepartVehicule = heureClient;
                    }
                }
            }

            if (heureDepartVehicule == null) {
                return;
            }
            
            long heures = (long) tempsTotal;
            long minutes = (long) ((tempsTotal - heures) * 60);
            java.time.LocalDateTime heureRetourVehicule = heureDepartVehicule.plusHours(heures).plusMinutes(minutes);
            
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
            planning.setDateHeureDepart(formatter.format(heureDepartVehicule));
            planning.setDateHeureRetour(formatter.format(heureRetourVehicule));
            planning.setHeureRetourParsed(heureRetourVehicule);
        } catch (Exception e) {
            System.err.println("Erreur parsing heure de d�part: " + e.getMessage());
        }
    }

    public void remplirPlacesRestantesOptimal(VehiclePlanningDTO planning, 
                                                List<ReservationEnrichi> reservationsRestantes,
                                                PlanningConfig config, Lieu aeroport, 
                                                List<Distance> distances, List<Lieu> lieux,
                                                ReservationEnrichi reservationReferenceFenetre,
                                                java.time.LocalDateTime heureDepartForcee) {
        boolean peutAjouterDautres = true;
        
        while (peutAjouterDautres && planning.getPlacesRestantes() > 0 && !reservationsRestantes.isEmpty()) {
            peutAjouterDautres = false;
            
            int indexMeilleurCandidat = -1;
            int maxPassagers = 0;
            
            for (int i = 0; i < reservationsRestantes.size(); i++) {
                ReservationEnrichi r = reservationsRestantes.get(i);
                int nbPassagers = r.reservation.getNbPassager();

                if (planning.peutAccueillir(nbPassagers) && nbPassagers > maxPassagers) {
                    indexMeilleurCandidat = i;
                    maxPassagers = nbPassagers;
                }
            }
            
            if (indexMeilleurCandidat != -1) {
                ReservationEnrichi meilleurCandidat = reservationsRestantes.remove(indexMeilleurCandidat);
                ajouterClientAuVehicule(planning, meilleurCandidat, config, aeroport, distances, lieux, heureDepartForcee);
                peutAjouterDautres = true; 
            }
        }
    }

    public boolean estCompatibleFenetreHoraire(Reservation reservationReference,
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

    public java.time.LocalDateTime parserDateHeureReservation(String dateHeure) {
        if (dateHeure == null || dateHeure.trim().isEmpty()) {
            return null;
        }

        try {
            return java.time.LocalDateTime.parse(dateHeure.replace(" ", "T"));
        } catch (Exception e) {
            return null;
        }
    }

    public Lieu trouverLieuPourReservation(Reservation reservation, List<Lieu> lieux) {
        if (reservation == null || lieux == null || lieux.isEmpty()) {
            return null;
        }

        String nomHotel = reservation.getHotel();
        if (nomHotel == null || nomHotel.trim().isEmpty()) {
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

        return lieux.stream()
            .filter(l -> l.getId() == reservation.getIdHotel())
            .findFirst()
            .orElse(null);
    }

    public String formaterCreneau(int debutMinutes, int finMinutes) {
        int debutHeure = (debutMinutes / 60) % 24;
        int debutMinute = debutMinutes % 60;
        int finHeure = (finMinutes / 60) % 24;
        int finMinute = finMinutes % 60;

        return String.format("%02d:%02d - %02d:%02d", debutHeure, debutMinute, finHeure, finMinute);
    }

    public int extraireDebutCreneauMinutes(String creneau) {
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

    public Vehicule trouverVehiculeOptimal(List<Vehicule> tousVehicules,
                                            List<VehiclePlanningDTO> planningsExistants,
                                            Reservation reservationCandidate,
                                            java.time.LocalDateTime heureDepartPrevue) {
        int nbPassagers = reservationCandidate != null ? reservationCandidate.getNbPassager() : 0;

        List<Vehicule> vehiculesDisponibles = tousVehicules.stream()
            .filter(v -> estVehiculeDisponiblePourReservation(v.getId(), planningsExistants, heureDepartPrevue))
            .collect(java.util.stream.Collectors.toList());

        return trouverVehiculeOptimal(vehiculesDisponibles, nbPassagers, planningsExistants);
    }

    public boolean estVehiculeDisponiblePourReservation(int idVehicule,
                                                         List<VehiclePlanningDTO> planningsExistants,
                                                         java.time.LocalDateTime dateHeureReservation) {
        if (planningsExistants == null || planningsExistants.isEmpty()) {
            return true;
        }

        List<VehiclePlanningDTO> planningsVehicule = planningsExistants.stream()
            .filter(p -> p.getIdVehicule() == idVehicule)
            .collect(java.util.stream.Collectors.toList());

        if (planningsVehicule.isEmpty()) {
            return true;
        }

        if (dateHeureReservation == null) {
            return true;
        }

        java.time.LocalDateTime dernierRetour = planningsVehicule.stream()
            .map(this::extraireHeureRetourPlanning)
            .filter(h -> h != null)
            .max(java.time.LocalDateTime::compareTo)
            .orElse(null);

        if (dernierRetour == null) {
            return false;
        }

        return !dernierRetour.isAfter(dateHeureReservation);
    }

    public java.time.LocalDateTime extraireHeureRetourPlanning(VehiclePlanningDTO planning) {
        if (planning == null) {
            return null;
        }

        if (planning.getHeureRetourParsed() != null) {
            return planning.getHeureRetourParsed();
        }

        String heureRetour = planning.getDateHeureRetour();
        if (heureRetour == null || heureRetour.trim().isEmpty()) {
            return null;
        }

        try {
            java.time.LocalTime h = java.time.LocalTime.parse(heureRetour);
            return java.time.LocalDate.now().atTime(h);
        } catch (Exception e) {
            return null;
        }
    }

    public Vehicule trouverVehiculeOptimal(List<Vehicule> vehiculesDisponibles, int nbPassagers, List<VehiclePlanningDTO> planningsExistants) {
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

        java.util.Map<Integer, Long> compteurCourses = new java.util.HashMap<>();
        if (planningsExistants != null) {
            for (VehiclePlanningDTO p : planningsExistants) {
                compteurCourses.put(p.getIdVehicule(), compteurCourses.getOrDefault(p.getIdVehicule(), 0L) + 1L);
            }
        }

        long minCourses = candidats.stream()
            .mapToLong(v -> compteurCourses.getOrDefault(v.getId(), 0L))
            .min()
            .orElse(0L);

        candidats = candidats.stream()
            .filter(v -> compteurCourses.getOrDefault(v.getId(), 0L) == minCourses)
            .collect(java.util.stream.Collectors.toList());

        if (candidats.size() == 1) {
            return candidats.get(0);
        }
        
        List<Vehicule> diesels = candidats.stream()
            .filter(v -> "diesel".equalsIgnoreCase(v.getTypeCarburant()))
            .collect(java.util.stream.Collectors.toList());
        
        if (!diesels.isEmpty()) {
            return diesels.get(new java.util.Random().nextInt(diesels.size()));
        }
        
        return candidats.get(new java.util.Random().nextInt(candidats.size()));
    }

    public List<EtapeItineraire> calculerItineraireDetaille(VehiclePlanningDTO planning, PlanningConfig config,
                                                              Lieu aeroport, List<Distance> distances, List<Lieu> lieux) {
        List<EtapeItineraire> itineraire = new ArrayList<>();
        
        if (planning.getClients().isEmpty()) return itineraire;
        
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
        
        for (int i = 0; i < clientsTries.size(); i++) {
            ClientInfo client = clientsTries.get(i);
            
            Lieu lieuHotel = lieux.stream()
                .filter(l -> l.getLibelle().toLowerCase().contains(client.getHotel().toLowerCase()) 
                          || client.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                .findFirst()
                .orElse(null);
            
            if (lieuHotel != null) {
                double distance = Distance.getDistanceBetween(lieuActuel.getId(), lieuHotel.getId(), distances);
                
                double tempsTrajetHeures = distance / config.getVitesseMoyenne();
                long heures = (long) tempsTrajetHeures;
                long minutes = (long) ((tempsTrajetHeures - heures) * 60);
                
                heureActuelle = heureActuelle.plusHours(heures).plusMinutes(minutes);
                
                java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
                String heureArrivee = formatter.format(heureActuelle);
                
                EtapeItineraire etape = new EtapeItineraire();
                etape.setOrdre(i + 1);
                etape.setLieuDepart(lieuActuel.getLibelle());
                etape.setLieuArrivee(lieuHotel.getLibelle());
                etape.setDistance(distance);
                etape.setHeureArrivee(heureArrivee);
                etape.setNomClient(client.getNomClient());
                etape.setNbPassager(client.getNbPassager());
                
                itineraire.add(etape);
                
                if (config.getTempsAttente() > 0) {
                    heureActuelle = heureActuelle.plusMinutes(config.getTempsAttente());
                }
                
                lieuActuel = lieuHotel;
            }
        }
        
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
        etapeRetour.setNomClient("Retour a�roport");
        etapeRetour.setNbPassager(0);
        
        itineraire.add(etapeRetour);
        
        return itineraire;
    }

    public List<Vehicule> getAllVehicules() throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            return Planning.getAllVehicules(conn);
        }
    }

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
