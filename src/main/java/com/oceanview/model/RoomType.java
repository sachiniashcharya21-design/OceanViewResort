package com.oceanview.model;

import java.math.BigDecimal;
import java.sql.Timestamp;

/**
 * RoomType Model Class
 * Represents different room categories
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class RoomType {
    
    private int roomTypeId;
    private String typeName;
    private String description;
    private BigDecimal ratePerNight;
    private int maxOccupancy;
    private String amenities;
    private RoomTypeStatus status;
    private Timestamp createdAt;
    
    /**
     * Room Type Status Enum
     */
    public enum RoomTypeStatus {
        AVAILABLE, UNAVAILABLE
    }
    
    // Default Constructor
    public RoomType() {
        this.status = RoomTypeStatus.AVAILABLE;
    }
    
    // Parameterized Constructor
    public RoomType(int roomTypeId, String typeName, BigDecimal ratePerNight) {
        this.roomTypeId = roomTypeId;
        this.typeName = typeName;
        this.ratePerNight = ratePerNight;
        this.status = RoomTypeStatus.AVAILABLE;
    }
    
    // Getters and Setters
    public int getRoomTypeId() {
        return roomTypeId;
    }
    
    public void setRoomTypeId(int roomTypeId) {
        this.roomTypeId = roomTypeId;
    }
    
    public String getTypeName() {
        return typeName;
    }
    
    public void setTypeName(String typeName) {
        this.typeName = typeName;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public BigDecimal getRatePerNight() {
        return ratePerNight;
    }
    
    public void setRatePerNight(BigDecimal ratePerNight) {
        this.ratePerNight = ratePerNight;
    }
    
    public int getMaxOccupancy() {
        return maxOccupancy;
    }
    
    public void setMaxOccupancy(int maxOccupancy) {
        this.maxOccupancy = maxOccupancy;
    }
    
    public String getAmenities() {
        return amenities;
    }
    
    public void setAmenities(String amenities) {
        this.amenities = amenities;
    }
    
    public RoomTypeStatus getStatus() {
        return status;
    }
    
    public void setStatus(RoomTypeStatus status) {
        this.status = status;
    }
    
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    
    @Override
    public String toString() {
        return String.format("%s - Rs. %,.2f per night", typeName, ratePerNight);
    }
    
    /**
     * Display room type details
     */
    public void displayDetails() {
        System.out.printf("  %-15s | Rs. %,10.2f/night | Max: %d guests | %s%n", 
            typeName, ratePerNight, maxOccupancy, 
            amenities != null ? amenities : "Basic amenities");
    }
}
