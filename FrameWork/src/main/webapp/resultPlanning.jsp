<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="models.ReservationDTO" %>
<%@ page import="models.Vehicule" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Résultat de la Planification / Vokatra Planification</title>
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; background-color: #f4f4f4; }
        .container { max-width: 1100px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1, h2 { color: #333; text-align: center; }
        .table-section { margin-bottom: 40px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #2196F3; color: white; font-weight: bold; }
        tr:hover { background-color: #f5f5f5; }
        .badge { display: inline-block; padding: 4px 8px; border-radius: 3px; font-size: 12px; font-weight: bold; }
        .badge-unassigned { background-color: #FFF3CD; color: #856404; }
        .badge-assigned { background-color: #C8E6C9; color: #2E7D32; }
        .malagasy { color: #1976D2; font-size: 14px; font-style: italic; }
        .francais { color: #555; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Résultat de la Planification / <span class="malagasy">Vokatra Planification</span></h1>
        <div class="table-section">
            <h2>Réservations assignées / <span class="malagasy">Fandaminana amin'ny fiara</span></h2>
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Client / <span class="malagasy">Mpandeha</span></th>
                        <th>Véhicule / <span class="malagasy">Fiara</span></th>
                        <th>Heure départ / <span class="malagasy">Ora fiaingana</span></th>
                        <th>Heure arrivée / <span class="malagasy">Ora fahatongavana</span></th>
                        <th>Lieu départ / <span class="malagasy">Toerana fiaingana</span></th>
                        <th>Lieu arrivée / <span class="malagasy">Toerana fahatongavana</span></th>
                        <th>Nb passagers / <span class="malagasy">Isan'ny mpandeha</span></th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <% List<ReservationDTO> assigned = (List<ReservationDTO>) request.getAttribute("assigned");
                       if (assigned != null && !assigned.isEmpty()) {
                           for (ReservationDTO r : assigned) { %>
                        <tr>
                            <td><%= r.getId() %></td>
                            <td><%= r.getClient() %></td>
                            <td><%= r.getVehicule() %></td>
                            <td><%= r.getHeureDepart() %></td>
                            <td><%= r.getHeureArrivee() %></td>
                            <td><%= r.getLieuDepart() %></td>
                            <td><%= r.getLieuArrivee() %></td>
                            <td><%= r.getNbPassager() %></td>
                            <td><span class="badge badge-assigned">Assignée / <span class="malagasy">Voatokana</span></span></td>
                        </tr>
                    <%   }
                       } else { %>
                        <tr><td colspan="9" style="text-align:center;">Aucune réservation assignée / <span class="malagasy">Tsy misy voatokana</span></td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <div class="table-section">
            <h2>Réservations non assignées / <span class="malagasy">Tsy voatokana</span></h2>
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Client / <span class="malagasy">Mpandeha</span></th>
                        <th>Nb passagers / <span class="malagasy">Isan'ny mpandeha</span></th>
                        <th>Date arrivée / <span class="malagasy">Daty fahatongavana</span></th>
                        <th>Hôtel / <span class="malagasy">Hotel</span></th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <% List<ReservationDTO> unassigned = (List<ReservationDTO>) request.getAttribute("unassigned");
                       if (unassigned != null && !unassigned.isEmpty()) {
                           for (ReservationDTO r : unassigned) { %>
                        <tr>
                            <td><%= r.getId() %></td>
                            <td><%= r.getClient() %></td>
                            <td><%= r.getNbPassager() %></td>
                            <td><%= r.getDateHeureArrivee() %></td>
                            <td><%= r.getHotel() %></td>
                            <td><span class="badge badge-unassigned">Non assignée / <span class="malagasy">Tsy voatokana</span></span></td>
                        </tr>
                    <%   }
                       } else { %>
                        <tr><td colspan="6" style="text-align:center;">Aucune réservation non assignée / <span class="malagasy">Tsy misy tsy voatokana</span></td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <div style="margin-top:30px;">
            <div class="francais">
                <strong>Règles de gestion :</strong><br>
                1. Les clients sont inséparables<br>
                2. On assigne les clients au véhicule ayant le nombre de places le plus proche du nombre de passagers<br>
                3. Si plusieurs véhicules ont le même nombre de places, priorité au diesel<br>
                4. Si égalité, on choisit au hasard<br>
                5. Les réservations avec le plus de personnes sont prioritaires<br>
                6. Le lieu le plus proche de l'aéroport est visité en premier<br>
            </div>
            <div class="malagasy">
                <strong>Fitsipika :</strong><br>
                1. Tsy azo sarahana ny mpanjifa<br>
                2. Ny fiara manana toerana akaiky indrindra amin'ny isan'ny mpandeha no omena<br>
                3. Raha mitovy ny toerana, diesel no omena laharana<br>
                4. Raha mitovy tanteraka, random no atao<br>
                5. Ny réservation misy olona maro no omena laharana<br>
                6. Ny toerana akaiky indrindra amin'ny aéroport no aleha voalohany<br>
            </div>
        </div>
    </div>
</body>
</html>
