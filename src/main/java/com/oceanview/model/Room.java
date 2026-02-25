package com.oceanview.model;

import java.sql.Timestamp;

/**
 * Room Model Class
 * Represents individual hotel rooms
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class Room {
    
    private int roomId;
    private String roomNumber;
    private int roomTypeId;
    private RoomType roomType; // Associated RoomType object
    private int floorNumber;
    private RoomStatus status;
    private String notes;
    private Timestamp createdAt;
    
    /**
     * Room Status Enum
     */
    public enum RoomStatus {
        AVAILABLE, OCCUPIED, MAINTENANCE, RESERVED
    }
    
    // Default Constructor
    public Room() {
        this.status = RoomStatus.AVAILABLE;
    }
    
    // Parameterized Constructor
    public Room(int roomId, String roomNumber, int roomTypeId, int floorNumber) {
        this.roomId = roomId;
        this.roomNumber = roomNumber;
        this.roomTypeId = roomTypeId;
        this.floorNumber = floorNumber;
        this.status = RoomStatus.AVAILABLE;
    }
    
    // Getters and Setters
    public int getRoomId() {
        return roomId;
    }
    
    public void setRoomId(int roomId) {
        this.roomId = roomId;
    }
    
    public String getRoomNumber() {
        return roomNumber;
    }
    
    public void setRoomNumber(String roomNumber) {
        this.roomNumber = roomNumber;
    }
    
    public int getRoomTypeId() {
        return roomTypeId;
    }
    
    public void setRoomTypeId(int roomTypeId) {
        this.roomTypeId = roomTypeId;
    }
    
    public RoomType getRoomType() {
        return roomType;
    }
    
    public void setRoomType(RoomType roomType) {
        this.roomType = roomType;
    }
    
    public int getFloorNumber() {
        return floorNumber;
    }
    
    public void setFloorNumber(int floorNumber) {
        this.floorNumber = floorNumber;
    }
    
    public RoomStatus getStatus() {
        return status;
    }
    
    public void setStatus(RoomStatus status) {
        this.status = status;
    }
    
    public String getNotes() {
        return notes;
    }
    
    public void setNotes(String notes) {
        this.notes = notes;
    }
    
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    
    /**
     * Check if room is available
     */
    public boolean isAvailable() {
        return this.status == RoomStatus.AVAILABLE;
    }
    
    @Override
    public String toString() {
        return String.format("Room %s - Floor %d - %s", roomNumber, floorNumber, status);
    }
    
    /**
     * Display room details
     */
    public void displayDetails() {
        System.out.printf("  Room %-5s | Floor %d | %-12s | %s%n", 
            roomNumber, floorNumber, status,
            roomType != null ? roomType.getTypeName() : "N/A");
    }
}
