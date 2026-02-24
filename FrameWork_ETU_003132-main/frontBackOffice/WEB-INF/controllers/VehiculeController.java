package com.example.controllers;

import annotation.MethodeAnnotation;
import annotation.GetMapping;
import annotation.PostMapping;
import annotation.ClasseAnnotation;
import annotation.RequestParam;
import modelview.ModelView;
import com.example.models.Vehicule;
import com.example.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@ClasseAnnotation("/vehicule")
public class VehiculeController {
   
    @MethodeAnnotation("/vehicule/form")
    @GetMapping
    public ModelView getFormVehicule() {
        ModelView mv = new ModelView("/WEB-INF/formVehicule.jsp");
        return mv;
    }
 
    @MethodeAnnotation("/vehicule/save")
    @PostMapping
    public ModelView saveVehicule(Vehicule vehicule) {
        ModelView mv = new ModelView("/WEB-INF/resultVehicule.jsp");
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
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors de l'enregistrement: " + e.getMessage());
        }
        
        mv.addData("success", success);
        mv.addData("vehicule", vehicule);
        return mv;
    }
    

    @MethodeAnnotation("/vehicule/list")
    @GetMapping
    public ModelView listVehicules() {
        ModelView mv = new ModelView("/WEB-INF/listVehicule.jsp");
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
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors de la récupération des véhicules: " + e.getMessage());
        }
        
        mv.addData("vehicules", vehicules);
        return mv;
    }

    @MethodeAnnotation("/vehicule/edit")
    @GetMapping
    public ModelView editFormVehicule(@RequestParam("id") String idStr) {
        ModelView mv = new ModelView("/WEB-INF/editVehicule.jsp");
        
        try {
            int id = Integer.parseInt(idStr);
            Vehicule vehicule = getVehiculeById(id);
            
            if (vehicule != null) {
                mv.addData("vehicule", vehicule);
            } else {
                mv.addData("error", "Véhicule non trouvé");
            }
        } catch (NumberFormatException e) {
            mv.addData("error", "ID invalide");
        }
        
        return mv;
    }
    

    @MethodeAnnotation("/vehicule/update")
    @PostMapping
    public ModelView updateVehicule(@RequestParam("id") String idStr, Vehicule vehicule) {
        ModelView mv = new ModelView("/WEB-INF/resultVehicule.jsp");
        boolean success = false;
        
        try {
            int id = Integer.parseInt(idStr);
            vehicule.setId(id);

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
        } catch (NumberFormatException e) {
            mv.addData("error", "ID invalide");
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors de la mise à jour: " + e.getMessage());
        }
        
        mv.addData("success", success);
        mv.addData("vehicule", vehicule);
        mv.addData("action", "update");
        return mv;
    }
    
    @MethodeAnnotation("/vehicule/delete")
    @GetMapping
    public ModelView deleteVehicule(@RequestParam("id") String idStr) {
        ModelView mv = new ModelView("/WEB-INF/resultVehicule.jsp");
        boolean success = false;
        
        try {
            int id = Integer.parseInt(idStr);
            
            try (Connection conn = DatabaseConnection.getConnection()) {
                String sql = "DELETE FROM vehicule WHERE id = ?";
                try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                    stmt.setInt(1, id);
                    
                    int rowsAffected = stmt.executeUpdate();
                    if (rowsAffected > 0) {
                        success = true;
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
                mv.addData("error", "Erreur lors de la suppression: " + e.getMessage());
            }
        } catch (NumberFormatException e) {
            mv.addData("error", "ID invalide");
        }
        
        mv.addData("success", success);
        mv.addData("action", "delete");
        return mv;
    }
    
    private Vehicule getVehiculeById(int id) {
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
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return vehicule;
    }
}
