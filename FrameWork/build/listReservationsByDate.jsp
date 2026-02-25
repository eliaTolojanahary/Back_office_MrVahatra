<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="models.Reservation" %>
<%@ page import="models.PlanningConfig" %>
<!DOCTYPE html>
<html>
<head>
        <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <meta charset="UTF-8">
    <title>Réservations - <%= request.getAttribute("datePlanning") %></title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 50px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 10px;
        }
        .subtitle {
            text-align: center;
            color: #666;
            margin-bottom: 30px;
            font-size: 18px;
        }
        .info-box {
            background-color: #e3f2fd;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .info-item {
            flex: 1;
            text-align: center;
        }
        .info-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
        }
        .info-value {
            font-size: 24px;
            font-weight: bold;
            color: #1976D2;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #2196F3;
            color: white;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .no-data {
            text-align: center;
            padding: 40px;
            color: #999;
            font-size: 18px;
        }
        .btn {
            display: inline-block;
            padding: 12px 24px;
            margin: 5px;
            border-radius: 4px;
            text-decoration: none;
            text-align: center;
            cursor: pointer;
            font-size: 16px;
            border: none;
            font-family: Arial, sans-serif;
        }
        .btn-primary {
            background-color: #4CAF50;
            color: white;
        }
        .btn-primary:hover {
            background-color: #45a049;
        }
        .btn-secondary {
            background-color: #2196F3;
            color: white;
        }
        .btn-secondary:hover {
            background-color: #1976D2;
        }
        .button-group {
            text-align: center;
            margin-top: 30px;
        }
        .error {
            color: red;
            padding: 15px;
            background-color: #fee;
            border-radius: 4px;
            margin-bottom: 20px;
            text-align: center;
        }
        .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: bold;
        }
        .badge-pending {
            background-color: #FFF3CD;
            color: #856404;
        }
    </style>
</head>
<body>
    <div class="container">
        <% 
            List<Reservation> reservations = (List<Reservation>) request.getAttribute("reservations");
            Integer count = (Integer) request.getAttribute("count");
            PlanningConfig planning_config = (PlanningConfig) request.getAttribute("config");
            String error = (String) request.getAttribute("error");
            String datePlanning = (String) request.getAttribute("datePlanning");
        %>
        
        <h1><span style="font-size:1.2em;vertical-align:middle;" class="material-icons">assignment</span> Réservations du <%= datePlanning %></h1>
        
        <% if (error != null) { %>
            <div class="error">
                <%= error %>
            </div>
        <% } else { %>
            <div class="info-box">
                <div class="info-item">
                    <div class="info-label">Nombre de réservations</div>
                    <div class="info-value"><%= count != null ? count : 0 %></div>
                </div>
                <% if (planning_config != null) { %>
                <div class="info-item">
                    <div class="info-label">Vitesse Moyenne</div>
                    <div class="info-value"><%= planning_config.getVitesseMoyenne() %> km/h</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Temps d'Attente</div>
                    <div class="info-value"><%= planning_config.getTempsAttente() %> min</div>
                </div>
                <% } %>
            </div>
            
            <% if (reservations != null && !reservations.isEmpty()) { %>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Client</th>
                            <th>Hôtel</th>
                            <th>Passagers</th>
                            <th>Date/Heure Arrivée</th>
                            <th>Statut</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Reservation r : reservations) { %>
                            <tr>
                                <td>#<%= r.getId() %></td>
                                <td><strong><%= r.getClient() %></strong></td>
                                <td><%= r.getHotel() %></td>
                                <td><%= r.getNbPassager() %> personne(s)</td>
                                <td><%= r.getDateHeureDepart() %></td>
                                <td><span class="badge badge-pending">En attente</span></td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            <% } else { %>
                <div class="no-data">
                    <span class="material-icons" style="font-size:1.2em;vertical-align:middle;">mail</span> Aucune réservation trouvée pour cette date
                </div>
            <% } %>
        <% } %>
        
        <div class="button-group">
            <% if (reservations != null && !reservations.isEmpty()) { %>
                <form action="<%= request.getContextPath() %>/planning/result" method="POST" style="display:inline;">
                    <input type="hidden" name="datePlanning" value="<%= datePlanning %>">
                    <button type="submit" class="btn btn-primary">
                        <span class="material-icons" style="font-size:1.2em;vertical-align:middle;">event_available</span> Calculer la Planification
                    </button>
                </form>
            <% } %>
            <a href="<%= request.getContextPath() %>/planning/selection-date" 
               class="btn btn-secondary">
                <span class="material-icons" style="font-size:1.2em;vertical-align:middle;">arrow_back</span> Changer de Date
            </a>
        </div>
    </div>
</body>
</html>
