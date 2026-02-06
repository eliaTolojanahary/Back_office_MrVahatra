package com.example.models;

public class Reservation {
    private int id;
    private String client;
    private int idHotel;
    private int nbPassager;
    private String dateHeureDepart;
    
    public Reservation() {
    }
    
    public Reservation(int id, String client, int idHotel, int nbPassager, String dateHeureDepart) {
        this.id = id;
        this.client = client;
        this.idHotel = idHotel;
        this.nbPassager = nbPassager;
        this.dateHeureDepart = dateHeureDepart;
    }
    
    // Getters
    public int getId() {
        return id;
    }
    
    public String getClient() {
        return client;
    }
    
    public int getIdHotel() {
        return idHotel;
    }
    
    public int getNbPassager() {
        return nbPassager;
    }
    
    public String getDateHeureDepart() {
        return dateHeureDepart;
    }
    
    // Setters
    public void setId(int id) {
        this.id = id;
    }
    
    public void setClient(String client) {
        this.client = client;
    }
    
    public void setIdHotel(int idHotel) {
        this.idHotel = idHotel;
    }
    
    public void setNbPassager(int nbPassager) {
        this.nbPassager = nbPassager;
    }
    
    public void setDateHeureDepart(String dateHeureDepart) {
        this.dateHeureDepart = dateHeureDepart;
    }
    
    @Override
    public String toString() {
        return "Reservation{" +
                "id=" + id +
                ", client='" + client + '\'' +
                ", idHotel=" + idHotel +
                ", nbPassager=" + nbPassager +
                ", dateHeureDepart='" + dateHeureDepart + '\'' +
                '}';
    }
}
