package com.oceanview.model;

import java.sql.Date;
import java.sql.Timestamp;
import java.time.temporal.ChronoUnit;

/**
 * Reservation Model Class
 * Represents hotel room reservations/bookings
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class Reservation {
    
    private int reservationId;
    private String reservationNumber;
    private int guestId;
    private Guest guest; // Associated Guest object
    private int roomId;
    private Room room; // Associated Room object
    private Date checkInDate;
    private Date checkOutDate;
    private int numberOfGuests;
    private String specialRequests;
    private ReservationStatus status;
    private int createdBy;
    private User createdByUser; // Associated User object
    private Timestamp createdAt;
    private Timestamp updatedAt;
    
    /**
     * Reservation Status Enum
     */
    public enum ReservationStatus {
        CONFIRMED, CHECKED_IN, CHECKED_OUT, CANCELLED
    }
    
    // Default Constructor
    public Reservation() {
        this.status = ReservationStatus.CONFIRMED;
        this.numberOfGuests = 1;
    }
    
    // Parameterized Constructor
    public Reservation(String reservationNumber, int guestId, int roomId, 
                       Date checkInDate, Date checkOutDate) {
        this.reservationNumber = reservationNumber;
        this.guestId = guestId;
        this.roomId = roomId;
        this.checkInDate = checkInDate;
        this.checkOutDate = checkOutDate;
        this.status = ReservationStatus.CONFIRMED;
        this.numberOfGuests = 1;
    }
    
    // Getters and Setters
    public int getReservationId() {
        return reservationId;
    }
    
    public void setReservationId(int reservationId) {
        this.reservationId = reservationId;
    }
    
    public String getReservationNumber() {
        return reservationNumber;
    }
    
    public void setReservationNumber(String reservationNumber) {
        this.reservationNumber = reservationNumber;
    }
    
    public int getGuestId() {
        return guestId;
    }
    
    public void setGuestId(int guestId) {
        this.guestId = guestId;
    }
    
    public Guest getGuest() {
        return guest;
    }
    
    public void setGuest(Guest guest) {
        this.guest = guest;
    }
    
    public int getRoomId() {
        return roomId;
    }
    
    public void setRoomId(int roomId) {
        this.roomId = roomId;
    }
    
    public Room getRoom() {
        return room;
    }
    
    public void setRoom(Room room) {
        this.room = room;
    }
    
    public Date getCheckInDate() {
        return checkInDate;
    }
    
    public void setCheckInDate(Date checkInDate) {
        this.checkInDate = checkInDate;
    }
    
    public Date getCheckOutDate() {
        return checkOutDate;
    }
    
    public void setCheckOutDate(Date checkOutDate) {
        this.checkOutDate = checkOutDate;
    }
    
    public int getNumberOfGuests() {
        return numberOfGuests;
    }
    
    public void setNumberOfGuests(int numberOfGuests) {
        this.numberOfGuests = numberOfGuests;
    }
    
    public String getSpecialRequests() {
        return specialRequests;
    }
    
    public void setSpecialRequests(String specialRequests) {
        this.specialRequests = specialRequests;
    }
    
    public ReservationStatus getStatus() {
        return status;
    }
    
    public void setStatus(ReservationStatus status) {
        this.status = status;
    }
    
    public int getCreatedBy() {
        return createdBy;
    }
    
    public void setCreatedBy(int createdBy) {
        this.createdBy = createdBy;
    }
    
    public User getCreatedByUser() {
        return createdByUser;
    }
    
    public void setCreatedByUser(User createdByUser) {
        this.createdByUser = createdByUser;
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
    
    /**
     * Calculate number of nights
     */
    public int getNumberOfNights() {
        if (checkInDate != null && checkOutDate != null) {
            return (int) ChronoUnit.DAYS.between(
                checkInDate.toLocalDate(), 
                checkOutDate.toLocalDate()
            );
        }
        return 0;
    }
    
    @Override
    public String toString() {
        return String.format("Reservation %s - %s to %s - %s", 
            reservationNumber, checkInDate, checkOutDate, status);
    }
    
    /**
     * Display full reservation details
     */
    public void displayFullDetails() {
        System.out.println("\n╔═══════════════════════════════════════════════════════════════════════════╗");
        System.out.println("║                         RESERVATION DETAILS                               ║");
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.printf("║  Reservation No   : %-53s ║%n", reservationNumber);
        System.out.printf("║  Status           : %-53s ║%n", status);
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.println("║                            GUEST INFORMATION                              ║");
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        if (guest != null) {
            System.out.printf("║  Guest Name       : %-53s ║%n", guest.getFullName());
            System.out.printf("║  Contact Number   : %-53s ║%n", guest.getPhone());
            System.out.printf("║  Email            : %-53s ║%n", guest.getEmail() != null ? guest.getEmail() : "N/A");
            System.out.printf("║  Address          : %-53s ║%n", 
                guest.getAddress() != null ? (guest.getAddress().length() > 53 ? 
                    guest.getAddress().substring(0, 50) + "..." : guest.getAddress()) : "N/A");
            System.out.printf("║  NIC/Passport     : %-53s ║%n", guest.getNicPassport() != null ? guest.getNicPassport() : "N/A");
        }
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.println("║                            ROOM INFORMATION                               ║");
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        if (room != null) {
            System.out.printf("║  Room Number      : %-53s ║%n", room.getRoomNumber());
            System.out.printf("║  Room Type        : %-53s ║%n", 
                room.getRoomType() != null ? room.getRoomType().getTypeName() : "N/A");
            System.out.printf("║  Rate Per Night   : Rs. %-49s ║%n", 
                room.getRoomType() != null ? String.format("%,.2f", room.getRoomType().getRatePerNight()) : "N/A");
            System.out.printf("║  Floor            : %-53d ║%n", room.getFloorNumber());
        }
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.println("║                           BOOKING DETAILS                                 ║");
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.printf("║  Check-in Date    : %-53s ║%n", checkInDate);
        System.out.printf("║  Check-out Date   : %-53s ║%n", checkOutDate);
        System.out.printf("║  Number of Nights : %-53d ║%n", getNumberOfNights());
        System.out.printf("║  Number of Guests : %-53d ║%n", numberOfGuests);
        System.out.printf("║  Special Requests : %-53s ║%n", 
            specialRequests != null ? (specialRequests.length() > 53 ? 
                specialRequests.substring(0, 50) + "..." : specialRequests) : "None");
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.printf("║  Created By       : %-53s ║%n", 
            createdByUser != null ? createdByUser.getFullName() : "System");
        System.out.printf("║  Created At       : %-53s ║%n", createdAt != null ? createdAt.toString() : "N/A");
        System.out.println("╚═══════════════════════════════════════════════════════════════════════════╝");
    }
    
    /**
     * Display reservation in compact format for listing
     */
    public void displayCompact() {
        System.out.printf("│ %-15s │ %-20s │ %-5s │ %-10s │ %-10s │ %-12s │%n",
            reservationNumber,
            guest != null ? (guest.getFullName().length() > 20 ? 
                guest.getFullName().substring(0, 17) + "..." : guest.getFullName()) : "N/A",
            room != null ? room.getRoomNumber() : "N/A",
            checkInDate,
            checkOutDate,
            status);
    }
}
