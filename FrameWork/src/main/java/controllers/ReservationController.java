package controllers;

import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import models.Hotel;
import models.Reservation;
import modelview.ModelView;
import util.DatabaseConnection;

@ClasseAnnotation("/reservation")
public class ReservationController {
    
  
    @MethodeAnnotation("/reservation/form")
    @GetMapping
    public ModelView getFormReservation() {
        ModelView mv = new ModelView("/formReservation.jsp");
        try (Connection conn = DatabaseConnection.getConnection()) {
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
        ModelView mv = new ModelView("/resultReservation.jsp");
        boolean success = false;
        
        try (Connection conn = DatabaseConnection.getConnection()) {
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
    public ModelView getAllReservations() {
        ModelView mv = new ModelView("/listReservationsByDate.jsp");
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.id, r.client, r.id_hotel, h.nom AS hotel, r.nb_passager, r.date_heure_depart " +
            "FROM reservation r JOIN hotel h ON r.id_hotel = h.id " +
            "ORDER BY r.date_heure_depart";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
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
        } catch (SQLException e) {
            System.err.println("==== ERREUR SQL dans getAllReservations ====");
            e.printStackTrace();
            mv.addData("error", "Erreur SQL: " + e.getMessage() + " | Cause: " + e.getCause());
        } catch (Exception e) {
            System.err.println("==== ERREUR GENERALE dans getAllReservations ====");
            e.printStackTrace();
            mv.addData("error", "Erreur: " + e.getClass().getName() + " - " + e.getMessage());
        }
        mv.addData("reservations", reservations);
        mv.addData("count", reservations.size());
        return mv;
    }
}
