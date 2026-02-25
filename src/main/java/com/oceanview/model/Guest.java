package com.oceanview.model;

import java.sql.Timestamp;

/**
 * Guest Model Class
 * Represents hotel guests
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class Guest {
    
    private int guestId;
    private String fullName;
    private String nicPassport;
    private String email;
    private String phone;
    private String address;
    private String nationality;
    private java.sql.Date dateOfBirth;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    
    // Default Constructor
    public Guest() {
        this.nationality = "Sri Lankan";
    }
    
    // Parameterized Constructor
    public Guest(String fullName, String phone, String address) {
        this.fullName = fullName;
        this.phone = phone;
        this.address = address;
        this.nationality = "Sri Lankan";
    }
    
    // Full Parameterized Constructor
    public Guest(int guestId, String fullName, String nicPassport, String email, 
                 String phone, String address, String nationality) {
        this.guestId = guestId;
        this.fullName = fullName;
        this.nicPassport = nicPassport;
        this.email = email;
        this.phone = phone;
        this.address = address;
        this.nationality = nationality;
    }
    
    // Getters and Setters
    public int getGuestId() {
        return guestId;
    }
    
    public void setGuestId(int guestId) {
        this.guestId = guestId;
    }
    
    public String getFullName() {
        return fullName;
    }
    
    public void setFullName(String fullName) {
        this.fullName = fullName;
    }
    
    public String getNicPassport() {
        return nicPassport;
    }
    
    public void setNicPassport(String nicPassport) {
        this.nicPassport = nicPassport;
    }
    
    public String getEmail() {
        return email;
    }
    
    public void setEmail(String email) {
        this.email = email;
    }
    
    public String getPhone() {
        return phone;
    }
    
    public void setPhone(String phone) {
        this.phone = phone;
    }
    
    public String getAddress() {
        return address;
    }
    
    public void setAddress(String address) {
        this.address = address;
    }
    
    public String getNationality() {
        return nationality;
    }
    
    public void setNationality(String nationality) {
        this.nationality = nationality;
    }
    
    public java.sql.Date getDateOfBirth() {
        return dateOfBirth;
    }
    
    public void setDateOfBirth(java.sql.Date dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }
    
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    
    public Timestamp getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    @Override
    public String toString() {
        return "Guest{" +
                "guestId=" + guestId +
                ", fullName='" + fullName + '\'' +
                ", phone='" + phone + '\'' +
                ", nationality='" + nationality + '\'' +
                '}';
    }
    
    /**
     * Display guest details in formatted manner
     */
    public void displayDetails() {
        System.out.println("\n┌───────────────────────────────────────────────────────────────┐");
        System.out.println("│                       GUEST DETAILS                           │");
        System.out.println("├───────────────────────────────────────────────────────────────┤");
        System.out.printf("│  Guest ID     : %-45d │%n", guestId);
        System.out.printf("│  Full Name    : %-45s │%n", fullName);
        System.out.printf("│  NIC/Passport : %-45s │%n", nicPassport != null ? nicPassport : "N/A");
        System.out.printf("│  Email        : %-45s │%n", email != null ? email : "N/A");
        System.out.printf("│  Phone        : %-45s │%n", phone);
        System.out.printf("│  Address      : %-45s │%n", address != null ? (address.length() > 45 ? address.substring(0, 42) + "..." : address) : "N/A");
        System.out.printf("│  Nationality  : %-45s │%n", nationality);
        System.out.println("└───────────────────────────────────────────────────────────────┘");
    }
}
