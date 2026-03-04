<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="models.VehiclePlanningDTO" %>
<%@ page import="models.ClientInfo" %>
<%@ page import="models.ReservationDTO" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Résultat de la Planification / Vokatra Planification</title>
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; background-color: #f4f4f4; }
        .container { max-width: 1200px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1, h2 { color: #333; text-align: center; }
        .table-section { margin-bottom: 40px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; vertical-align: top; }
        th { background-color: #2196F3; color: white; font-weight: bold; }
        tr:hover { background-color: #f5f5f5; }
        .badge { display: inline-block; padding: 4px 8px; border-radius: 3px; font-size: 12px; font-weight: bold; }
        .badge-unassigned { background-color: #FFF3CD; color: #856404; }
        .badge-assigned { background-color: #C8E6C9; color: #2E7D32; }
        .malagasy { color: #1976D2; font-size: 13px; font-style: italic; }
        .francais { color: #555; font-size: 14px; }
        .client-list { list-style-type: none; padding: 0; margin: 0; }
        .client-list li { padding: 5px 0; border-bottom: 1px dotted #ccc; }
        .client-list li:last-child { border-bottom: none; }
        .client-name { font-weight: bold; color: #333; }
        .client-details { font-size: 12px; color: #666; }
        .vehicle-id { font-weight: bold; color: #2196F3; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Résultat de la Planification / <span class="malagasy">Vokatra Planification</span></h1>
        <div class="table-section">
            <h2>Planification des véhicules / <span class="malagasy">Fandaminana ny fiara</span></h2>
            <table>
                <thead>
                    <tr>
                        <th>ID Véhicule<br/><span class="malagasy">ID Fiara</span></th>
                        <th>Référence<br/><span class="malagasy">Référence</span></th>
                        <th>Clients<br/><span class="malagasy">Mpanjifa</span></th>
                        <th>Heure départ<br/><span class="malagasy">Ora fiaingana</span></th>
                        <th>Heure retour<br/><span class="malagasy">Ora fiverenana</span></th>
                        <th>Places<br/><span class="malagasy">Toerana</span></th>
                    </tr>
                </thead>
                <tbody>
                    <% List<VehiclePlanningDTO> plannings = (List<VehiclePlanningDTO>) request.getAttribute("plannings");
                       if (plannings != null && !plannings.isEmpty()) {
                           for (VehiclePlanningDTO planning : plannings) { %>
                        <tr>
                            <td class="vehicle-id"><%= planning.getIdVehicule() %></td>
                            <td><%= planning.getReferenceVehicule() %></td>
                            <td>
                                <ul class="client-list">
                                    <% for (models.ClientInfo client : planning.getClients()) { %>
                                        <li>
                                            <span class="client-name"><%= client.getNomClient() %></span><br/>
                                            <span class="client-details">
                                                <%= client.getNbPassager() %> passager(s) - 
                                                <%= client.getHotel() %><br/>
                                                Arrivée: <%= client.getHeureArriveeHotel() %>
                                            </span>
                                        </li>
                                    <% } %>
                                </ul>
                            </td>
                            <td><%= planning.getDateHeureDepart() %></td>
                            <td><%= planning.getDateHeureRetour() %></td>
                            <td><%= planning.getPlacesOccupees() %> / <%= planning.getPlacesTotales() %></td>
                        </tr>
                    <%   }
                       } else { %>
                        <tr><td colspan="6" style="text-align:center;">Aucune planification / <span class="malagasy">Tsy misy fandaminana</span></td></tr>
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
                <strong>Nouvelles règles de gestion :</strong><br>
                1. Un véhicule peut avoir plusieurs clients à la fois si le nombre de places est suffisant<br>
                2. Les clients avec le plus de passagers sont traités en premier<br>
                3. Après avoir assigné un client, on cherche à remplir les places restantes avec d'autres clients compatibles<br>
                4. Les clients les plus proches de l'aéroport sont prioritaires<br>
                5. Si plusieurs véhicules ont le même nombre de places, priorité au diesel<br>
                6. Chaque véhicule effectue un trajet : aéroport → hôtels des clients → retour aéroport<br>
            </div>
            <div class="malagasy">
                <strong>Fitsipika vaovao :</strong><br>
                1. Ny fiara iray dia afaka mitondra mpanjifa maro raha ampy ny toerana<br>
                2. Ny mpanjifa manana mpandeha be no omena laharana<br>
                3. Rehefa voatokana ny mpanjifa iray, dia tadiavina ny hafa hameno ny toerana sisa<br>
                4. Ny mpanjifa akaiky amin'ny aéroport no omena laharana<br>
                5. Raha mitovy ny toerana, diesel no omena laharana<br>
                6. Ny fiara tsirairay dia manao dia iray: aéroport → hotely mpanjifa → miverina aéroport<br>
            </div>
        </div>
    </div>
</body>
</html>
