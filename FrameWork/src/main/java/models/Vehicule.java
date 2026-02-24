package com.example.models;

import annotation.RequestParam;

public class Vehicule {
    private int id;
    private String reference;
    private int place;
    private String typeCarburant;
    
    public Vehicule() {
    }

    public Vehicule(
            @RequestParam("reference") String reference,
            @RequestParam("place") int place,
            @RequestParam("typeCarburant") String typeCarburant) {
        this.reference = reference;
        this.place = place;
        this.typeCarburant = typeCarburant;
    }

    Vehicule(int id, String reference, int place, String typeCarburant) {
        this.id = id;
        this.reference = reference;
        this.place = place;
        this.typeCarburant = typeCarburant;
    }
    
    // Getters
    public int getId() {
        return id;
    }
    
    public String getReference() {
        return reference;
    }
    
    public int getPlace() {
        return place;
    }
    
    public String getTypeCarburant() {
        return typeCarburant;
    }
    
    // Setters
    public void setId(int id) {
        this.id = id;
    }
    
    public void setReference(String reference) {
        this.reference = reference;
    }
    
    public void setPlace(int place) {
        this.place = place;
    }
    
    public void setTypeCarburant(String typeCarburant) {
        this.typeCarburant = typeCarburant;
    }
    
    @Override
    public String toString() {
        return "Vehicule{" +
                "id=" + id +
                ", reference='" + reference + '\'' +
                ", place=" + place +
                ", typeCarburant='" + typeCarburant + '\'' +
                '}';
    }
}
