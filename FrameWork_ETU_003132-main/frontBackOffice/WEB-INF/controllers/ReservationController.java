package com.example.controllers;

import annotation.MethodeAnnotation;
import annotation.GetMapping;
import annotation.PostMapping;
import annotation.ClasseAnnotation;
import annotation.Api;
import modelview.ModelView;
import com.example.models.Reservation;
import com.example.models.Hotel;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
@ClasseAnnotation("/reservation")
public class ReservationController {
    
    private Connection getConnection() throws SQLException {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("PostgreSQL Driver not found", e);
        }
        return DriverManager.getConnection("jdbc:postgresql://localhost:5432/reservation", "postgres", "NouveauMotDePasse");
    }
    
  
    @MethodeAnnotation("/reservation/form")
    @GetMapping
    public ModelView getFormReservation() {
        ModelView mv = new ModelView("/WEB-INF/formReservation.jsp");
        try (Connection conn = getConnection()) {
            List<Hotel> hotels = new ArrayList<>();
            String sql = "SELECT id, nom, adresse FROM hotel ORDER BY nom";
            try (PreparedStatement stmt = conn.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Hotel h = new Hotel();
                    h.setId(rs.getInt("id"));
                    h.setNom(rs.getString("nom"));
                    h.setAdresse(rs.getString("adresse"));
                    hotels.add(h);
                }
            }
            mv.addData("hotels", hotels);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement des hôtels: " + e.getMessage());
        }
        return mv;
    }
    
   
    @MethodeAnnotation("/reservation/save")
    @PostMapping
    public ModelView saveReservation(Reservation reservation) {
        ModelView mv = new ModelView("/WEB-INF/resultReservation.jsp");
        boolean success = false;
        
        try (Connection conn = getConnection()) {
            String sql = "INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES (?, ?, ?, ?::timestamp)";
            try (PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                stmt.setString(1, reservation.getClient());
                stmt.setInt(2, reservation.getIdHotel());
                stmt.setInt(3, reservation.getNbPassager());
                stmt.setString(4, reservation.getDateHeureDepart());
                
                int rowsAffected = stmt.executeUpdate();
                if (rowsAffected > 0) {
                    success = true;
                    try (ResultSet rs = stmt.getGeneratedKeys()) {
                        if (rs.next()) {
                            reservation.setId(rs.getInt(1));
                        }
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors de l'enregistrement: " + e.getMessage());
        }
        
        mv.addData("success", success);
        mv.addData("reservation", reservation);
        return mv;
    }

    @MethodeAnnotation("/reservation/list")
    @GetMapping
    @Api
    public List<Reservation> getAll(Map<String, Object> params) {
        List<Reservation> reservations = new ArrayList<>();
        String datetime = null;
        if (params != null && params.containsKey("datetime")) {
            Object raw = params.get("datetime");
            if (raw instanceof String) {
                datetime = (String) raw;
            } else if (raw instanceof String[] && ((String[]) raw).length > 0) {
                datetime = ((String[]) raw)[0];
            }
        }

        String sqlAll = "SELECT r.id, r.client, r.id_hotel, h.nom AS hotel, r.nb_passager, r.date_heure_depart " +
            "FROM reservation r JOIN hotel h ON r.id_hotel = h.id " +
            "ORDER BY r.date_heure_depart";
        String sqlFilter = "SELECT r.id, r.client, r.id_hotel, h.nom AS hotel, r.nb_passager, r.date_heure_depart " +
            "FROM reservation r JOIN hotel h ON r.id_hotel = h.id " +
            "WHERE r.date_heure_depart = ?::timestamp ORDER BY r.date_heure_depart";

        try (Connection conn = getConnection()) {
            PreparedStatement stmt;
            if (datetime == null || datetime.trim().isEmpty()) {
                stmt = conn.prepareStatement(sqlAll);
            } else {
                stmt = conn.prepareStatement(sqlFilter);
                stmt.setString(1, datetime);
            }

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Reservation r = new Reservation();
                    r.setId(rs.getInt("id"));
                    r.setClient(rs.getString("client"));
                    r.setIdHotel(rs.getInt("id_hotel"));
                    r.setHotel(rs.getString("hotel"));
                    r.setNbPassager(rs.getInt("nb_passager"));
                    r.setDateHeureDepart(String.valueOf(rs.getTimestamp("date_heure_depart")));
                    reservations.add(r);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Erreur lors du chargement des reservations", e);
        }

        return reservations;
    }
}
