package services;

import models.Vehicule;
import util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class VehiculeService {

    public boolean saveVehicule(Vehicule vehicule) throws SQLException {
        boolean success = false;
        try (Connection conn = DatabaseConnection.getConnection()) {
            String sql = "INSERT INTO vehicule (reference, place, type_carburant) VALUES (?, ?, ?)";
            try (PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                stmt.setString(1, vehicule.getReference());
                stmt.setInt(2, vehicule.getPlace());
                stmt.setString(3, vehicule.getTypeCarburant());
                
                int rowsAffected = stmt.executeUpdate();
                if (rowsAffected > 0) {
                    success = true;
                    try (ResultSet rs = stmt.getGeneratedKeys()) {
                        if (rs.next()) {
                            vehicule.setId(rs.getInt(1));
                        }
                    }
                }
            }
        }
        return success;
    }

    public List<Vehicule> getAllVehicules() throws SQLException {
        List<Vehicule> vehicules = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection()) {
            String sql = "SELECT id, reference, place, type_carburant FROM vehicule ORDER BY id";
            try (PreparedStatement stmt = conn.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {
                
                while (rs.next()) {
                    Vehicule v = new Vehicule();
                    v.setId(rs.getInt("id"));
                    v.setReference(rs.getString("reference"));
                    v.setPlace(rs.getInt("place"));
                    v.setTypeCarburant(rs.getString("type_carburant"));
                    vehicules.add(v);
                }
            }
        }
        return vehicules;
    }

    public Vehicule getVehiculeById(int id) throws SQLException {
        Vehicule vehicule = null;
        try (Connection conn = DatabaseConnection.getConnection()) {
            String sql = "SELECT id, reference, place, type_carburant FROM vehicule WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, id);
                
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        vehicule = new Vehicule();
                        vehicule.setId(rs.getInt("id"));
                        vehicule.setReference(rs.getString("reference"));
                        vehicule.setPlace(rs.getInt("place"));
                        vehicule.setTypeCarburant(rs.getString("type_carburant"));
                    }
                }
            }
        }
        return vehicule;
    }

    public boolean updateVehicule(Vehicule vehicule) throws SQLException {
        boolean success = false;
        try (Connection conn = DatabaseConnection.getConnection()) {
            String sql = "UPDATE vehicule SET reference = ?, place = ?, type_carburant = ? WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, vehicule.getReference());
                stmt.setInt(2, vehicule.getPlace());
                stmt.setString(3, vehicule.getTypeCarburant());
                stmt.setInt(4, vehicule.getId());
                
                int rowsAffected = stmt.executeUpdate();
                if (rowsAffected > 0) {
                    success = true;
                }
            }
        }
        return success;
    }

    public boolean deleteVehicule(int id) throws SQLException {
        boolean success = false;
        try (Connection conn = DatabaseConnection.getConnection()) {
            String sql = "DELETE FROM vehicule WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, id);
                
                int rowsAffected = stmt.executeUpdate();
                if (rowsAffected > 0) {
                    success = true;
                }
            }
        }
        return success;
    }
}