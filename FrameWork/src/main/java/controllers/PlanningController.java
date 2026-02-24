package com.example.controllers;

import annotation.MethodeAnnotation;
import annotation.GetMapping;
import annotation.PostMapping;
import annotation.ClasseAnnotation;
import modelview.ModelView;
import com.example.models.*;
import com.example.util.DatabaseConnection;
import java.sql.*;
import java.util.List;

@ClasseAnnotation("/planning")
public class PlanningController {
    
    /**
     * PAGE 1 : Affiche le formulaire de configuration des paramètres système
     */
    @MethodeAnnotation("/planning/config/form")
    @GetMapping
    public ModelView getFormPlanningConfig() {
        ModelView mv = new ModelView("/WEB-INF/formPlanningConfig.jsp");
        
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
        ModelView mv = new ModelView("/WEB-INF/resultPlanningConfig.jsp");
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
        ModelView mv = new ModelView("/WEB-INF/formSelectionDatePlanning.jsp");
        
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
        ModelView mv = new ModelView("/WEB-INF/listReservationsByDate.jsp");
        
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
     * Récupère tous les lieux (pour debug/admin)
     */
    @MethodeAnnotation("/planning/lieux")
    @GetMapping
    public ModelView getAllLieux() {
        ModelView mv = new ModelView("/WEB-INF/listLieux.jsp");
        
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
        ModelView mv = new ModelView("/WEB-INF/listDistances.jsp");
        
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
