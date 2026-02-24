package com.example.models;

import annotation.RequestParam;
import java.sql.Timestamp;

public class PlanningConfig {
    private int id;
    private double vitesseMoyenne; // km/h
    private int tempsAttente;      // minutes
    private Timestamp dateCreation;
    private boolean isActive;
    
    public PlanningConfig() {
    }
    
    public PlanningConfig(
            @RequestParam("vitesseMoyenne") double vitesseMoyenne,
            @RequestParam("tempsAttente") int tempsAttente) {
        this.vitesseMoyenne = vitesseMoyenne;
        this.tempsAttente = tempsAttente;
        this.isActive = true;
    }
    
    public PlanningConfig(int id, double vitesseMoyenne, int tempsAttente, Timestamp dateCreation, boolean isActive) {
        this.id = id;
        this.vitesseMoyenne = vitesseMoyenne;
        this.tempsAttente = tempsAttente;
        this.dateCreation = dateCreation;
        this.isActive = isActive;
    }
    
    // Getters
    public int getId() {
        return id;
    }
    
    public double getVitesseMoyenne() {
        return vitesseMoyenne;
    }
    
    public int getTempsAttente() {
        return tempsAttente;
    }
    
    public Timestamp getDateCreation() {
        return dateCreation;
    }
    
    public boolean isActive() {
        return isActive;
    }
    
    // Setters
    public void setId(int id) {
        this.id = id;
    }
    
    public void setVitesseMoyenne(double vitesseMoyenne) {
        this.vitesseMoyenne = vitesseMoyenne;
    }
    
    public void setTempsAttente(int tempsAttente) {
        this.tempsAttente = tempsAttente;
    }
    
    public void setDateCreation(Timestamp dateCreation) {
        this.dateCreation = dateCreation;
    }
    
    public void setActive(boolean active) {
        isActive = active;
    }
    
    /**
     * Calcule le temps de trajet en minutes
     * @param distanceKm Distance en kilomètres
     * @return Temps de trajet en minutes
     */
    public double calculerTempsTrajet(double distanceKm) {
        if (vitesseMoyenne <= 0) return 0;
        return (distanceKm / vitesseMoyenne) * 60; // Convertir heures en minutes
    }
    
    @Override
    public String toString() {
        return "PlanningConfig{" +
                "id=" + id +
                ", vitesseMoyenne=" + vitesseMoyenne +
                ", tempsAttente=" + tempsAttente +
                ", dateCreation=" + dateCreation +
                ", isActive=" + isActive +
                '}';
    }
}
