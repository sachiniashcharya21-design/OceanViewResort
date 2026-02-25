package com.oceanview.ui;

import com.oceanview.dao.*;
import com.oceanview.model.*;
import com.oceanview.model.Bill.PaymentMethod;
import com.oceanview.model.Bill.PaymentStatus;
import com.oceanview.model.Reservation.ReservationStatus;
import com.oceanview.model.Room.RoomStatus;
import com.oceanview.model.User.UserRole;
import com.oceanview.model.User.UserStatus;
import com.oceanview.util.ConsoleUtils;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;

/**
 * Admin Dashboard
 * Full access dashboard for administrators
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class AdminDashboard {
    
    private User currentUser;
    private UserDAO userDAO;
    private GuestDAO guestDAO;
    private RoomDAO roomDAO;
    private ReservationDAO reservationDAO;
    private BillDAO billDAO;
    
    /**
     * Constructor
     */
    public AdminDashboard(User user) {
        this.currentUser = user;
        try {
            this.userDAO = new UserDAO();
            this.guestDAO = new GuestDAO();
            this.roomDAO = new RoomDAO();
            this.reservationDAO = new ReservationDAO();
            this.billDAO = new BillDAO();
        } catch (SQLException e) {
            ConsoleUtils.printError("Failed to initialize dashboard: " + e.getMessage());
        }
    }
    
    /**
     * Show admin dashboard main menu
     */
    public void show() {
        boolean running = true;
        while (running) {
            displayMainMenu();
            int choice = ConsoleUtils.readInt("    Enter your choice: ", 0, 10);
            
            switch (choice) {
                case 1 -> showProfile();
                case 2 -> manageReservations();
                case 3 -> manageRooms();
                case 4 -> manageGuests();
                case 5 -> manageBilling();
                case 6 -> manageStaff();
                case 7 -> viewReports();
                case 8 -> showHelp();
                case 9 -> changePassword();
                case 0 -> {
                    if (confirmLogout()) {
                        running = false;
                    }
                }
                default -> ConsoleUtils.printError("Invalid option. Please try again.");
            }
        }
    }
    
    /**
     * Display main menu
     */
    private void displayMainMenu() {
        ConsoleUtils.clearScreen();
        System.out.println("\n");
        System.out.println("    ╔═══════════════════════════════════════════════════════════════════════╗");
        System.out.println("    ║                    ADMIN DASHBOARD - MAIN MENU                        ║");
        System.out.println("    ╠═══════════════════════════════════════════════════════════════════════╣");
        System.out.printf("    ║  Logged in as: %-57s ║%n", currentUser.getFullName() + " (" + currentUser.getRole() + ")");
        System.out.printf("    ║  Date: %-65s ║%n", LocalDate.now());
        System.out.println("    ╠═══════════════════════════════════════════════════════════════════════╣");
        System.out.println("    ║                                                                       ║");
        System.out.println("    ║    [1]  My Profile                                                    ║");
        System.out.println("    ║    [2]  Manage Reservations                                           ║");
        System.out.println("    ║    [3]  Manage Rooms                                                  ║");
        System.out.println("    ║    [4]  Manage Guests                                                 ║");
        System.out.println("    ║    [5]  Billing & Payments                                            ║");
        System.out.println("    ║    [6]  Manage Staff                                                  ║");
        System.out.println("    ║    [7]  View Reports                                                  ║");
        System.out.println("    ║    [8]  Help & Guidelines                                             ║");
        System.out.println("    ║    [9]  Change Password                                               ║");
        System.out.println("    ║    [0]  Logout                                                        ║");
        System.out.println("    ║                                                                       ║");
        System.out.println("    ╚═══════════════════════════════════════════════════════════════════════╝");
        System.out.println();
        
        // Display quick stats
        displayQuickStats();
    }
    
    /**
     * Display quick statistics
     */
    private void displayQuickStats() {
        try {
            int totalRooms = roomDAO.getTotalRoomCount();
            int availableRooms = roomDAO.getRoomCountByStatus(RoomStatus.AVAILABLE);
            int occupiedRooms = roomDAO.getRoomCountByStatus(RoomStatus.OCCUPIED);
            int todayCheckIns = reservationDAO.getTodayCheckIns().size();
            int todayCheckOuts = reservationDAO.getTodayCheckOuts().size();
            
            System.out.println("    ┌─────────────────────────────────────────────────────────────────────┐");
            System.out.println("    │  QUICK STATISTICS                                                   │");
            System.out.println("    ├─────────────────────────────────────────────────────────────────────┤");
            System.out.printf("    │  Total Rooms: %-5d │ Available: %-5d │ Occupied: %-5d            │%n",
                totalRooms, availableRooms, occupiedRooms);
            System.out.printf("    │  Today's Check-ins: %-5d          │ Today's Check-outs: %-5d    │%n",
                todayCheckIns, todayCheckOuts);
            System.out.println("    └─────────────────────────────────────────────────────────────────────┘");
        } catch (Exception e) {
            // Skip stats if error
        }
    }
    
    /**
     * Show user profile
     */
    private void showProfile() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("MY PROFILE");
        currentUser.displayProfile();
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Manage reservations submenu
     */
    private void manageReservations() {
        boolean back = false;
        while (!back) {
            ConsoleUtils.clearScreen();
            ConsoleUtils.printHeader("RESERVATION MANAGEMENT");
            System.out.println();
            ConsoleUtils.printMenuOption(1, "Add New Reservation");
            ConsoleUtils.printMenuOption(2, "View All Reservations");
            ConsoleUtils.printMenuOption(3, "Search Reservation");
            ConsoleUtils.printMenuOption(4, "Today's Check-ins");
            ConsoleUtils.printMenuOption(5, "Today's Check-outs");
            ConsoleUtils.printMenuOption(6, "Check-in Guest");
            ConsoleUtils.printMenuOption(7, "Check-out Guest");
            ConsoleUtils.printMenuOption(8, "Cancel Reservation");
            ConsoleUtils.printMenuOption(0, "Back to Main Menu");
            System.out.println();
            
            int choice = ConsoleUtils.readInt("    Enter your choice: ", 0, 8);
            
            switch (choice) {
                case 1 -> addNewReservation();
                case 2 -> viewAllReservations();
                case 3 -> searchReservation();
                case 4 -> viewTodayCheckIns();
                case 5 -> viewTodayCheckOuts();
                case 6 -> checkInGuest();
                case 7 -> checkOutGuest();
                case 8 -> cancelReservation();
                case 0 -> back = true;
            }
        }
    }
    
    /**
     * Add new reservation
     */
    private void addNewReservation() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("ADD NEW RESERVATION");
        System.out.println();
        
        // Guest Information
        ConsoleUtils.printSubHeader("Guest Information");
        String guestName = ConsoleUtils.readRequiredString("    Guest Name: ");
        String phone = ConsoleUtils.readPhoneNumber("    Contact Number: ");
        String address = ConsoleUtils.readRequiredString("    Address: ");
        String email = ConsoleUtils.readEmail("    Email (optional): ");
        String nicPassport = ConsoleUtils.readOptionalString("    NIC/Passport (optional): ");
        
        // Create or find guest
        Guest guest = guestDAO.getGuestByPhone(phone);
        if (guest == null) {
            guest = new Guest();
            guest.setFullName(guestName);
            guest.setPhone(phone);
            guest.setAddress(address);
            guest.setEmail(email);
            guest.setNicPassport(nicPassport);
            int guestId = guestDAO.addGuest(guest);
            if (guestId < 0) {
                ConsoleUtils.printError("Failed to register guest.");
                ConsoleUtils.pressEnterToContinue();
                return;
            }
        } else {
            ConsoleUtils.printInfo("Existing guest found: " + guest.getFullName());
        }
        
        // Booking Details
        ConsoleUtils.printSubHeader("Booking Details");
        Date checkInDate = ConsoleUtils.readFutureDate("    Check-in Date (YYYY-MM-DD): ");
        Date checkOutDate = ConsoleUtils.readDateAfter("    Check-out Date (YYYY-MM-DD): ", checkInDate);
        int numberOfGuests = ConsoleUtils.readInt("    Number of Guests: ", 1, 10);
        
        // Show available room types
        ConsoleUtils.printSubHeader("Available Room Types");
        List<RoomType> roomTypes = roomDAO.getAllRoomTypes();
        for (int i = 0; i < roomTypes.size(); i++) {
            System.out.printf("    [%d] ", i + 1);
            roomTypes.get(i).displayDetails();
        }
        
        int typeChoice = ConsoleUtils.readInt("    Select Room Type: ", 1, roomTypes.size());
        RoomType selectedType = roomTypes.get(typeChoice - 1);
        
        // Show available rooms of selected type
        List<Room> availableRooms = roomDAO.getAvailableRoomsByType(selectedType.getRoomTypeId());
        if (availableRooms.isEmpty()) {
            ConsoleUtils.printError("No rooms available for selected type.");
            ConsoleUtils.pressEnterToContinue();
            return;
        }
        
        ConsoleUtils.printSubHeader("Available Rooms");
        for (int i = 0; i < availableRooms.size(); i++) {
            System.out.printf("    [%d] Room %s - Floor %d%n", i + 1, 
                availableRooms.get(i).getRoomNumber(),
                availableRooms.get(i).getFloorNumber());
        }
        
        int roomChoice = ConsoleUtils.readInt("    Select Room: ", 1, availableRooms.size());
        Room selectedRoom = availableRooms.get(roomChoice - 1);
        
        // Special requests
        String specialRequests = ConsoleUtils.readOptionalString("    Special Requests (optional): ");
        
        // Create reservation
        Reservation reservation = new Reservation();
        reservation.setReservationNumber(reservationDAO.generateReservationNumber());
        reservation.setGuestId(guest.getGuestId());
        reservation.setRoomId(selectedRoom.getRoomId());
        reservation.setCheckInDate(checkInDate);
        reservation.setCheckOutDate(checkOutDate);
        reservation.setNumberOfGuests(numberOfGuests);
        reservation.setSpecialRequests(specialRequests);
        reservation.setCreatedBy(currentUser.getUserId());
        reservation.setStatus(ReservationStatus.CONFIRMED);
        
        // Confirm reservation
        System.out.println();
        ConsoleUtils.printDivider();
        System.out.println("    RESERVATION SUMMARY");
        ConsoleUtils.printDivider();
        System.out.printf("    Reservation No  : %s%n", reservation.getReservationNumber());
        System.out.printf("    Guest Name      : %s%n", guestName);
        System.out.printf("    Room            : %s (%s)%n", selectedRoom.getRoomNumber(), selectedType.getTypeName());
        System.out.printf("    Check-in        : %s%n", checkInDate);
        System.out.printf("    Check-out       : %s%n", checkOutDate);
        System.out.printf("    Rate per Night  : Rs. %,.2f%n", selectedType.getRatePerNight());
        System.out.printf("    Estimated Total : Rs. %,.2f%n", 
            selectedType.getRatePerNight().multiply(BigDecimal.valueOf(reservation.getNumberOfNights())));
        ConsoleUtils.printDivider();
        
        if (ConsoleUtils.readYesNo("    Confirm reservation?")) {
            if (reservationDAO.addReservation(reservation)) {
                ConsoleUtils.printSuccess("Reservation created successfully!");
                ConsoleUtils.printInfo("Reservation Number: " + reservation.getReservationNumber());
                userDAO.logActivity(currentUser.getUserId(), "CREATE_RESERVATION", 
                    "Created reservation " + reservation.getReservationNumber());
            } else {
                ConsoleUtils.printError("Failed to create reservation.");
            }
        } else {
            ConsoleUtils.printInfo("Reservation cancelled.");
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * View all reservations
     */
    private void viewAllReservations() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("ALL RESERVATIONS");
        
        List<Reservation> reservations = reservationDAO.getAllReservations();
        if (reservations.isEmpty()) {
            ConsoleUtils.printInfo("No reservations found.");
        } else {
            System.out.println();
            System.out.println("┌─────────────────┬──────────────────────┬───────┬────────────┬────────────┬──────────────┐");
            System.out.println("│ Reservation No  │ Guest Name           │ Room  │ Check-in   │ Check-out  │ Status       │");
            System.out.println("├─────────────────┼──────────────────────┼───────┼────────────┼────────────┼──────────────┤");
            for (Reservation r : reservations) {
                r.displayCompact();
            }
            System.out.println("└─────────────────┴──────────────────────┴───────┴────────────┴────────────┴──────────────┘");
            System.out.printf("    Total: %d reservations%n", reservations.size());
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Search reservation
     */
    private void searchReservation() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("SEARCH RESERVATION");
        System.out.println();
        ConsoleUtils.printMenuOption(1, "Search by Reservation Number");
        ConsoleUtils.printMenuOption(2, "Search by Guest Name");
        ConsoleUtils.printMenuOption(0, "Back");
        System.out.println();
        
        int choice = ConsoleUtils.readInt("    Enter your choice: ", 0, 2);
        
        if (choice == 1) {
            String resNumber = ConsoleUtils.readRequiredString("    Enter Reservation Number: ");
            Reservation reservation = reservationDAO.getReservationByNumber(resNumber.toUpperCase());
            if (reservation != null) {
                reservation.displayFullDetails();
            } else {
                ConsoleUtils.printError("Reservation not found.");
            }
        } else if (choice == 2) {
            String guestName = ConsoleUtils.readRequiredString("    Enter Guest Name: ");
            List<Reservation> reservations = reservationDAO.searchReservationsByGuestName(guestName);
            if (reservations.isEmpty()) {
                ConsoleUtils.printInfo("No reservations found for guest: " + guestName);
            } else {
                for (Reservation r : reservations) {
                    r.displayFullDetails();
                }
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * View today's check-ins
     */
    private void viewTodayCheckIns() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("TODAY'S CHECK-INS");
        
        List<Reservation> checkIns = reservationDAO.getTodayCheckIns();
        if (checkIns.isEmpty()) {
            ConsoleUtils.printInfo("No check-ins scheduled for today.");
        } else {
            System.out.println();
            for (Reservation r : checkIns) {
                System.out.printf("    [%s] %s - Room %s%n", 
                    r.getReservationNumber(),
                    r.getGuest() != null ? r.getGuest().getFullName() : "N/A",
                    r.getRoom() != null ? r.getRoom().getRoomNumber() : "N/A");
            }
            System.out.printf("%n    Total: %d guests expected%n", checkIns.size());
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * View today's check-outs
     */
    private void viewTodayCheckOuts() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("TODAY'S CHECK-OUTS");
        
        List<Reservation> checkOuts = reservationDAO.getTodayCheckOuts();
        if (checkOuts.isEmpty()) {
            ConsoleUtils.printInfo("No check-outs scheduled for today.");
        } else {
            System.out.println();
            for (Reservation r : checkOuts) {
                System.out.printf("    [%s] %s - Room %s%n", 
                    r.getReservationNumber(),
                    r.getGuest() != null ? r.getGuest().getFullName() : "N/A",
                    r.getRoom() != null ? r.getRoom().getRoomNumber() : "N/A");
            }
            System.out.printf("%n    Total: %d guests departing%n", checkOuts.size());
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Check-in guest
     */
    private void checkInGuest() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("GUEST CHECK-IN");
        
        String resNumber = ConsoleUtils.readRequiredString("    Enter Reservation Number: ");
        Reservation reservation = reservationDAO.getReservationByNumber(resNumber.toUpperCase());
        
        if (reservation == null) {
            ConsoleUtils.printError("Reservation not found.");
        } else if (reservation.getStatus() != ReservationStatus.CONFIRMED) {
            ConsoleUtils.printError("Cannot check-in. Reservation status is: " + reservation.getStatus());
        } else {
            reservation.displayFullDetails();
            
            if (ConsoleUtils.readYesNo("    Confirm check-in?")) {
                if (reservationDAO.checkIn(reservation.getReservationId())) {
                    ConsoleUtils.printSuccess("Guest checked in successfully!");
                    userDAO.logActivity(currentUser.getUserId(), "CHECK_IN", 
                        "Checked in reservation " + reservation.getReservationNumber());
                } else {
                    ConsoleUtils.printError("Failed to check-in guest.");
                }
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Check-out guest
     */
    private void checkOutGuest() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("GUEST CHECK-OUT");
        
        String resNumber = ConsoleUtils.readRequiredString("    Enter Reservation Number: ");
        Reservation reservation = reservationDAO.getReservationByNumber(resNumber.toUpperCase());
        
        if (reservation == null) {
            ConsoleUtils.printError("Reservation not found.");
        } else if (reservation.getStatus() != ReservationStatus.CHECKED_IN) {
            ConsoleUtils.printError("Cannot check-out. Reservation status is: " + reservation.getStatus());
        } else {
            reservation.displayFullDetails();
            
            // Generate bill
            Bill bill = billDAO.generateBill(reservation.getReservationId(), currentUser.getUserId());
            if (bill != null) {
                bill.printBill();
                
                if (ConsoleUtils.readYesNo("    Process payment and check-out?")) {
                    System.out.println();
                    ConsoleUtils.printMenuOption(1, "Cash");
                    ConsoleUtils.printMenuOption(2, "Card");
                    ConsoleUtils.printMenuOption(3, "Bank Transfer");
                    int paymentChoice = ConsoleUtils.readInt("    Select Payment Method: ", 1, 3);
                    
                    PaymentMethod method = switch (paymentChoice) {
                        case 2 -> PaymentMethod.CARD;
                        case 3 -> PaymentMethod.BANK_TRANSFER;
                        default -> PaymentMethod.CASH;
                    };
                    
                    billDAO.updatePaymentStatus(bill.getBillId(), PaymentStatus.PAID, method);
                    reservationDAO.checkOut(reservation.getReservationId());
                    
                    ConsoleUtils.printSuccess("Payment processed and guest checked out successfully!");
                    userDAO.logActivity(currentUser.getUserId(), "CHECK_OUT", 
                        "Checked out reservation " + reservation.getReservationNumber());
                }
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Cancel reservation
     */
    private void cancelReservation() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("CANCEL RESERVATION");
        
        String resNumber = ConsoleUtils.readRequiredString("    Enter Reservation Number: ");
        Reservation reservation = reservationDAO.getReservationByNumber(resNumber.toUpperCase());
        
        if (reservation == null) {
            ConsoleUtils.printError("Reservation not found.");
        } else if (reservation.getStatus() == ReservationStatus.CANCELLED || 
                   reservation.getStatus() == ReservationStatus.CHECKED_OUT) {
            ConsoleUtils.printError("Cannot cancel. Reservation status is: " + reservation.getStatus());
        } else {
            reservation.displayFullDetails();
            
            ConsoleUtils.printWarning("This action cannot be undone!");
            if (ConsoleUtils.readYesNo("    Are you sure you want to cancel this reservation?")) {
                if (reservationDAO.cancelReservation(reservation.getReservationId())) {
                    ConsoleUtils.printSuccess("Reservation cancelled successfully!");
                    userDAO.logActivity(currentUser.getUserId(), "CANCEL_RESERVATION", 
                        "Cancelled reservation " + reservation.getReservationNumber());
                } else {
                    ConsoleUtils.printError("Failed to cancel reservation.");
                }
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Manage rooms submenu
     */
    private void manageRooms() {
        boolean back = false;
        while (!back) {
            ConsoleUtils.clearScreen();
            ConsoleUtils.printHeader("ROOM MANAGEMENT");
            System.out.println();
            ConsoleUtils.printMenuOption(1, "View All Rooms");
            ConsoleUtils.printMenuOption(2, "View Available Rooms");
            ConsoleUtils.printMenuOption(3, "View Room Types & Rates");
            ConsoleUtils.printMenuOption(4, "Update Room Status");
            ConsoleUtils.printMenuOption(5, "Add New Room");
            ConsoleUtils.printMenuOption(6, "Update Room Rate");
            ConsoleUtils.printMenuOption(0, "Back to Main Menu");
            System.out.println();
            
            int choice = ConsoleUtils.readInt("    Enter your choice: ", 0, 6);
            
            switch (choice) {
                case 1 -> viewAllRooms();
                case 2 -> viewAvailableRooms();
                case 3 -> viewRoomTypes();
                case 4 -> updateRoomStatus();
                case 5 -> addNewRoom();
                case 6 -> updateRoomRate();
                case 0 -> back = true;
            }
        }
    }
    
    /**
     * View all rooms
     */
    private void viewAllRooms() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("ALL ROOMS");
        
        List<Room> rooms = roomDAO.getAllRooms();
        System.out.println();
        System.out.println("    ┌───────────┬───────┬──────────────┬───────────────────┐");
        System.out.println("    │ Room No.  │ Floor │ Status       │ Type              │");
        System.out.println("    ├───────────┼───────┼──────────────┼───────────────────┤");
        for (Room room : rooms) {
            System.out.printf("    │ %-9s │ %-5d │ %-12s │ %-17s │%n",
                room.getRoomNumber(),
                room.getFloorNumber(),
                room.getStatus(),
                room.getRoomType() != null ? room.getRoomType().getTypeName() : "N/A");
        }
        System.out.println("    └───────────┴───────┴──────────────┴───────────────────┘");
        System.out.printf("    Total: %d rooms%n", rooms.size());
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * View available rooms
     */
    private void viewAvailableRooms() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("AVAILABLE ROOMS");
        
        List<Room> rooms = roomDAO.getAvailableRooms();
        if (rooms.isEmpty()) {
            ConsoleUtils.printInfo("No rooms currently available.");
        } else {
            System.out.println();
            for (Room room : rooms) {
                System.out.printf("    Room %-5s │ %-12s │ Rs. %,.2f/night%n",
                    room.getRoomNumber(),
                    room.getRoomType() != null ? room.getRoomType().getTypeName() : "N/A",
                    room.getRoomType() != null ? room.getRoomType().getRatePerNight() : BigDecimal.ZERO);
            }
            System.out.printf("%n    Total: %d rooms available%n", rooms.size());
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * View room types
     */
    private void viewRoomTypes() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("ROOM TYPES & RATES");
        
        List<RoomType> roomTypes = roomDAO.getAllRoomTypes();
        System.out.println();
        for (RoomType rt : roomTypes) {
            System.out.println("    ┌───────────────────────────────────────────────────────────────────┐");
            System.out.printf("    │  %-65s │%n", rt.getTypeName());
            System.out.println("    ├───────────────────────────────────────────────────────────────────┤");
            System.out.printf("    │  Rate per Night : Rs. %,-39.2f │%n", rt.getRatePerNight());
            System.out.printf("    │  Max Occupancy  : %-47d │%n", rt.getMaxOccupancy());
            System.out.printf("    │  Amenities      : %-47s │%n", 
                rt.getAmenities() != null ? (rt.getAmenities().length() > 47 ? 
                    rt.getAmenities().substring(0, 44) + "..." : rt.getAmenities()) : "Basic");
            System.out.println("    └───────────────────────────────────────────────────────────────────┘");
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Update room status
     */
    private void updateRoomStatus() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("UPDATE ROOM STATUS");
        
        String roomNumber = ConsoleUtils.readRequiredString("    Enter Room Number: ");
        Room room = roomDAO.getRoomByNumber(roomNumber);
        
        if (room == null) {
            ConsoleUtils.printError("Room not found.");
        } else {
            System.out.printf("    Current Status: %s%n%n", room.getStatus());
            ConsoleUtils.printMenuOption(1, "AVAILABLE");
            ConsoleUtils.printMenuOption(2, "OCCUPIED");
            ConsoleUtils.printMenuOption(3, "MAINTENANCE");
            ConsoleUtils.printMenuOption(4, "RESERVED");
            System.out.println();
            
            int choice = ConsoleUtils.readInt("    Select new status: ", 1, 4);
            RoomStatus newStatus = switch (choice) {
                case 2 -> RoomStatus.OCCUPIED;
                case 3 -> RoomStatus.MAINTENANCE;
                case 4 -> RoomStatus.RESERVED;
                default -> RoomStatus.AVAILABLE;
            };
            
            if (roomDAO.updateRoomStatus(room.getRoomId(), newStatus)) {
                ConsoleUtils.printSuccess("Room status updated successfully!");
                userDAO.logActivity(currentUser.getUserId(), "UPDATE_ROOM", 
                    "Updated room " + roomNumber + " status to " + newStatus);
            } else {
                ConsoleUtils.printError("Failed to update room status.");
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Add new room
     */
    private void addNewRoom() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("ADD NEW ROOM");
        
        String roomNumber = ConsoleUtils.readRequiredString("    Room Number: ");
        
        // Check if room exists
        if (roomDAO.getRoomByNumber(roomNumber) != null) {
            ConsoleUtils.printError("Room number already exists.");
            ConsoleUtils.pressEnterToContinue();
            return;
        }
        
        int floorNumber = ConsoleUtils.readInt("    Floor Number: ", 1, 20);
        
        // Select room type
        List<RoomType> roomTypes = roomDAO.getAllRoomTypes();
        System.out.println();
        for (int i = 0; i < roomTypes.size(); i++) {
            System.out.printf("    [%d] %s - Rs. %,.2f%n", i + 1, 
                roomTypes.get(i).getTypeName(), 
                roomTypes.get(i).getRatePerNight());
        }
        
        int typeChoice = ConsoleUtils.readInt("    Select Room Type: ", 1, roomTypes.size());
        
        Room room = new Room();
        room.setRoomNumber(roomNumber);
        room.setFloorNumber(floorNumber);
        room.setRoomTypeId(roomTypes.get(typeChoice - 1).getRoomTypeId());
        room.setStatus(RoomStatus.AVAILABLE);
        
        if (roomDAO.addRoom(room)) {
            ConsoleUtils.printSuccess("Room added successfully!");
            userDAO.logActivity(currentUser.getUserId(), "ADD_ROOM", "Added room " + roomNumber);
        } else {
            ConsoleUtils.printError("Failed to add room.");
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Update room rate
     */
    private void updateRoomRate() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("UPDATE ROOM RATE");
        
        List<RoomType> roomTypes = roomDAO.getAllRoomTypes();
        System.out.println();
        for (int i = 0; i < roomTypes.size(); i++) {
            System.out.printf("    [%d] %s - Current Rate: Rs. %,.2f%n", i + 1, 
                roomTypes.get(i).getTypeName(), 
                roomTypes.get(i).getRatePerNight());
        }
        
        int typeChoice = ConsoleUtils.readInt("    Select Room Type to update: ", 1, roomTypes.size());
        RoomType selectedType = roomTypes.get(typeChoice - 1);
        
        System.out.printf("    Current rate for %s: Rs. %,.2f%n", 
            selectedType.getTypeName(), selectedType.getRatePerNight());
        
        double newRate = ConsoleUtils.readInt("    Enter new rate (Rs.): ", 1000, 500000);
        
        if (roomDAO.updateRoomTypeRate(selectedType.getRoomTypeId(), BigDecimal.valueOf(newRate))) {
            ConsoleUtils.printSuccess("Room rate updated successfully!");
            userDAO.logActivity(currentUser.getUserId(), "UPDATE_RATE", 
                "Updated " + selectedType.getTypeName() + " rate to Rs. " + newRate);
        } else {
            ConsoleUtils.printError("Failed to update room rate.");
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Manage guests submenu
     */
    private void manageGuests() {
        boolean back = false;
        while (!back) {
            ConsoleUtils.clearScreen();
            ConsoleUtils.printHeader("GUEST MANAGEMENT");
            System.out.println();
            ConsoleUtils.printMenuOption(1, "View All Guests");
            ConsoleUtils.printMenuOption(2, "Search Guest");
            ConsoleUtils.printMenuOption(3, "View Guest History");
            ConsoleUtils.printMenuOption(4, "Update Guest Info");
            ConsoleUtils.printMenuOption(0, "Back to Main Menu");
            System.out.println();
            
            int choice = ConsoleUtils.readInt("    Enter your choice: ", 0, 4);
            
            switch (choice) {
                case 1 -> viewAllGuests();
                case 2 -> searchGuest();
                case 3 -> viewGuestHistory();
                case 4 -> updateGuestInfo();
                case 0 -> back = true;
            }
        }
    }
    
    /**
     * View all guests
     */
    private void viewAllGuests() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("ALL GUESTS");
        
        List<Guest> guests = guestDAO.getAllGuests();
        System.out.println();
        System.out.println("    ┌─────┬────────────────────────┬─────────────────┬──────────────────┐");
        System.out.println("    │ ID  │ Name                   │ Phone           │ Nationality      │");
        System.out.println("    ├─────┼────────────────────────┼─────────────────┼──────────────────┤");
        for (Guest g : guests) {
            System.out.printf("    │ %-3d │ %-22s │ %-15s │ %-16s │%n",
                g.getGuestId(),
                g.getFullName().length() > 22 ? g.getFullName().substring(0, 19) + "..." : g.getFullName(),
                g.getPhone(),
                g.getNationality());
        }
        System.out.println("    └─────┴────────────────────────┴─────────────────┴──────────────────┘");
        System.out.printf("    Total: %d guests%n", guests.size());
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Search guest
     */
    private void searchGuest() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("SEARCH GUEST");
        
        String searchTerm = ConsoleUtils.readRequiredString("    Enter guest name: ");
        List<Guest> guests = guestDAO.searchGuestsByName(searchTerm);
        
        if (guests.isEmpty()) {
            ConsoleUtils.printInfo("No guests found matching: " + searchTerm);
        } else {
            for (Guest g : guests) {
                g.displayDetails();
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * View guest history
     */
    private void viewGuestHistory() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("GUEST HISTORY");
        
        int guestId = ConsoleUtils.readInt("    Enter Guest ID: ", 1, 99999);
        Guest guest = guestDAO.getGuestById(guestId);
        
        if (guest == null) {
            ConsoleUtils.printError("Guest not found.");
        } else {
            guest.displayDetails();
            
            List<Reservation> reservations = reservationDAO.getReservationsByGuest(guestId);
            if (reservations.isEmpty()) {
                ConsoleUtils.printInfo("No reservations found for this guest.");
            } else {
                ConsoleUtils.printSubHeader("Reservation History");
                for (Reservation r : reservations) {
                    System.out.printf("    %s | %s to %s | Room %s | %s%n",
                        r.getReservationNumber(),
                        r.getCheckInDate(),
                        r.getCheckOutDate(),
                        r.getRoom() != null ? r.getRoom().getRoomNumber() : "N/A",
                        r.getStatus());
                }
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Update guest info
     */
    private void updateGuestInfo() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("UPDATE GUEST INFO");
        
        int guestId = ConsoleUtils.readInt("    Enter Guest ID: ", 1, 99999);
        Guest guest = guestDAO.getGuestById(guestId);
        
        if (guest == null) {
            ConsoleUtils.printError("Guest not found.");
        } else {
            guest.displayDetails();
            
            System.out.println("    (Press Enter to keep current value)");
            
            String name = ConsoleUtils.readOptionalString("    New Name [" + guest.getFullName() + "]: ");
            if (!name.isEmpty()) guest.setFullName(name);
            
            String phone = ConsoleUtils.readOptionalString("    New Phone [" + guest.getPhone() + "]: ");
            if (!phone.isEmpty()) guest.setPhone(phone);
            
            String email = ConsoleUtils.readOptionalString("    New Email [" + 
                (guest.getEmail() != null ? guest.getEmail() : "N/A") + "]: ");
            if (!email.isEmpty()) guest.setEmail(email);
            
            String address = ConsoleUtils.readOptionalString("    New Address: ");
            if (!address.isEmpty()) guest.setAddress(address);
            
            if (guestDAO.updateGuest(guest)) {
                ConsoleUtils.printSuccess("Guest information updated successfully!");
                userDAO.logActivity(currentUser.getUserId(), "UPDATE_GUEST", 
                    "Updated guest " + guest.getFullName());
            } else {
                ConsoleUtils.printError("Failed to update guest information.");
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Manage billing submenu
     */
    private void manageBilling() {
        boolean back = false;
        while (!back) {
            ConsoleUtils.clearScreen();
            ConsoleUtils.printHeader("BILLING & PAYMENTS");
            System.out.println();
            ConsoleUtils.printMenuOption(1, "Generate Bill");
            ConsoleUtils.printMenuOption(2, "View All Bills");
            ConsoleUtils.printMenuOption(3, "View Pending Bills");
            ConsoleUtils.printMenuOption(4, "Search Bill");
            ConsoleUtils.printMenuOption(5, "Process Payment");
            ConsoleUtils.printMenuOption(6, "Apply Discount");
            ConsoleUtils.printMenuOption(0, "Back to Main Menu");
            System.out.println();
            
            int choice = ConsoleUtils.readInt("    Enter your choice: ", 0, 6);
            
            switch (choice) {
                case 1 -> generateBill();
                case 2 -> viewAllBills();
                case 3 -> viewPendingBills();
                case 4 -> searchBill();
                case 5 -> processPayment();
                case 6 -> applyDiscount();
                case 0 -> back = true;
            }
        }
    }
    
    /**
     * Generate bill
     */
    private void generateBill() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("GENERATE BILL");
        
        String resNumber = ConsoleUtils.readRequiredString("    Enter Reservation Number: ");
        Reservation reservation = reservationDAO.getReservationByNumber(resNumber.toUpperCase());
        
        if (reservation == null) {
            ConsoleUtils.printError("Reservation not found.");
        } else {
            Bill bill = billDAO.generateBill(reservation.getReservationId(), currentUser.getUserId());
            if (bill != null) {
                bill.printBill();
                userDAO.logActivity(currentUser.getUserId(), "GENERATE_BILL", 
                    "Generated bill " + bill.getBillNumber());
            } else {
                ConsoleUtils.printError("Failed to generate bill.");
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * View all bills
     */
    private void viewAllBills() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("ALL BILLS");
        
        List<Bill> bills = billDAO.getAllBills();
        System.out.println();
        System.out.println("    ┌────────────────┬────────────────┬────────────────┬──────────┐");
        System.out.println("    │ Bill Number    │ Reservation    │ Amount         │ Status   │");
        System.out.println("    ├────────────────┼────────────────┼────────────────┼──────────┤");
        for (Bill b : bills) {
            System.out.printf("    │ %-14s │ %-14s │ Rs. %,10.2f │ %-8s │%n",
                b.getBillNumber(),
                b.getReservation() != null ? b.getReservation().getReservationNumber() : "N/A",
                b.getTotalAmount(),
                b.getPaymentStatus());
        }
        System.out.println("    └────────────────┴────────────────┴────────────────┴──────────┘");
        System.out.printf("    Total: %d bills%n", bills.size());
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * View pending bills
     */
    private void viewPendingBills() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("PENDING BILLS");
        
        List<Bill> bills = billDAO.getBillsByPaymentStatus(PaymentStatus.PENDING);
        if (bills.isEmpty()) {
            ConsoleUtils.printInfo("No pending bills.");
        } else {
            System.out.println();
            for (Bill b : bills) {
                System.out.printf("    %s │ %s │ Rs. %,.2f%n",
                    b.getBillNumber(),
                    b.getReservation() != null ? b.getReservation().getReservationNumber() : "N/A",
                    b.getTotalAmount());
            }
            System.out.printf("%n    Total Pending: Rs. %,.2f%n", billDAO.getTotalPendingAmount());
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Search bill
     */
    private void searchBill() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("SEARCH BILL");
        
        String billNumber = ConsoleUtils.readRequiredString("    Enter Bill Number: ");
        Bill bill = billDAO.getBillByNumber(billNumber.toUpperCase());
        
        if (bill != null) {
            bill.printBill();
        } else {
            ConsoleUtils.printError("Bill not found.");
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Process payment
     */
    private void processPayment() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("PROCESS PAYMENT");
        
        String billNumber = ConsoleUtils.readRequiredString("    Enter Bill Number: ");
        Bill bill = billDAO.getBillByNumber(billNumber.toUpperCase());
        
        if (bill == null) {
            ConsoleUtils.printError("Bill not found.");
        } else if (bill.getPaymentStatus() == PaymentStatus.PAID) {
            ConsoleUtils.printInfo("This bill has already been paid.");
        } else {
            bill.printBill();
            
            System.out.println();
            ConsoleUtils.printMenuOption(1, "Cash");
            ConsoleUtils.printMenuOption(2, "Card");
            ConsoleUtils.printMenuOption(3, "Bank Transfer");
            int paymentChoice = ConsoleUtils.readInt("    Select Payment Method: ", 1, 3);
            
            PaymentMethod method = switch (paymentChoice) {
                case 2 -> PaymentMethod.CARD;
                case 3 -> PaymentMethod.BANK_TRANSFER;
                default -> PaymentMethod.CASH;
            };
            
            if (billDAO.updatePaymentStatus(bill.getBillId(), PaymentStatus.PAID, method)) {
                ConsoleUtils.printSuccess("Payment processed successfully!");
                userDAO.logActivity(currentUser.getUserId(), "PROCESS_PAYMENT", 
                    "Processed payment for bill " + bill.getBillNumber());
            } else {
                ConsoleUtils.printError("Failed to process payment.");
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Apply discount
     */
    private void applyDiscount() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("APPLY DISCOUNT");
        
        String billNumber = ConsoleUtils.readRequiredString("    Enter Bill Number: ");
        Bill bill = billDAO.getBillByNumber(billNumber.toUpperCase());
        
        if (bill == null) {
            ConsoleUtils.printError("Bill not found.");
        } else if (bill.getPaymentStatus() == PaymentStatus.PAID) {
            ConsoleUtils.printError("Cannot apply discount to a paid bill.");
        } else {
            bill.printBill();
            
            double discount = ConsoleUtils.readInt("    Enter Discount Amount (Rs.): ", 0, 
                bill.getTotalAmount().intValue());
            
            if (billDAO.applyDiscount(bill.getBillId(), BigDecimal.valueOf(discount))) {
                ConsoleUtils.printSuccess("Discount applied successfully!");
                Bill updatedBill = billDAO.getBillById(bill.getBillId());
                System.out.printf("    New Total: Rs. %,.2f%n", updatedBill.getTotalAmount());
                userDAO.logActivity(currentUser.getUserId(), "APPLY_DISCOUNT", 
                    "Applied Rs. " + discount + " discount to bill " + bill.getBillNumber());
            } else {
                ConsoleUtils.printError("Failed to apply discount.");
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Manage staff submenu (Admin only)
     */
    private void manageStaff() {
        boolean back = false;
        while (!back) {
            ConsoleUtils.clearScreen();
            ConsoleUtils.printHeader("STAFF MANAGEMENT");
            System.out.println();
            ConsoleUtils.printMenuOption(1, "View All Staff");
            ConsoleUtils.printMenuOption(2, "Add New Staff");
            ConsoleUtils.printMenuOption(3, "Update Staff Info");
            ConsoleUtils.printMenuOption(4, "Deactivate Staff");
            ConsoleUtils.printMenuOption(5, "Reset Staff Password");
            ConsoleUtils.printMenuOption(0, "Back to Main Menu");
            System.out.println();
            
            int choice = ConsoleUtils.readInt("    Enter your choice: ", 0, 5);
            
            switch (choice) {
                case 1 -> viewAllStaff();
                case 2 -> addNewStaff();
                case 3 -> updateStaffInfo();
                case 4 -> deactivateStaff();
                case 5 -> resetStaffPassword();
                case 0 -> back = true;
            }
        }
    }
    
    /**
     * View all staff
     */
    private void viewAllStaff() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("ALL STAFF MEMBERS");
        
        List<User> staff = userDAO.getAllStaff();
        System.out.println();
        System.out.println("    ┌─────┬──────────────┬────────────────────────┬─────────────────┬──────────┐");
        System.out.println("    │ ID  │ Username     │ Full Name              │ Phone           │ Status   │");
        System.out.println("    ├─────┼──────────────┼────────────────────────┼─────────────────┼──────────┤");
        for (User u : staff) {
            System.out.printf("    │ %-3d │ %-12s │ %-22s │ %-15s │ %-8s │%n",
                u.getUserId(),
                u.getUsername(),
                u.getFullName().length() > 22 ? u.getFullName().substring(0, 19) + "..." : u.getFullName(),
                u.getPhone() != null ? u.getPhone() : "N/A",
                u.getStatus());
        }
        System.out.println("    └─────┴──────────────┴────────────────────────┴─────────────────┴──────────┘");
        System.out.printf("    Total: %d staff members%n", staff.size());
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Add new staff
     */
    private void addNewStaff() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("ADD NEW STAFF");
        System.out.println();
        
        String username = ConsoleUtils.readRequiredString("    Username: ");
        
        // Check if username exists
        if (userDAO.usernameExists(username)) {
            ConsoleUtils.printError("Username already exists.");
            ConsoleUtils.pressEnterToContinue();
            return;
        }
        
        String password = ConsoleUtils.readRequiredString("    Password: ");
        String fullName = ConsoleUtils.readRequiredString("    Full Name: ");
        String email = ConsoleUtils.readEmail("    Email (optional): ");
        String phone = ConsoleUtils.readPhoneNumber("    Phone: ");
        String address = ConsoleUtils.readOptionalString("    Address (optional): ");
        
        User newUser = new User();
        newUser.setUsername(username);
        newUser.setPassword(password);
        newUser.setRole(UserRole.STAFF);
        newUser.setFullName(fullName);
        newUser.setEmail(email);
        newUser.setPhone(phone);
        newUser.setAddress(address);
        newUser.setHireDate(Date.valueOf(LocalDate.now()));
        newUser.setStatus(UserStatus.ACTIVE);
        
        if (userDAO.addUser(newUser)) {
            ConsoleUtils.printSuccess("Staff member added successfully!");
            ConsoleUtils.printInfo("Username: " + username);
            userDAO.logActivity(currentUser.getUserId(), "ADD_STAFF", 
                "Added new staff member: " + username);
        } else {
            ConsoleUtils.printError("Failed to add staff member.");
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Update staff info
     */
    private void updateStaffInfo() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("UPDATE STAFF INFO");
        
        int userId = ConsoleUtils.readInt("    Enter Staff ID: ", 1, 99999);
        User user = userDAO.getUserById(userId);
        
        if (user == null) {
            ConsoleUtils.printError("Staff member not found.");
        } else if (user.getRole() != UserRole.STAFF) {
            ConsoleUtils.printError("Can only update staff members from this menu.");
        } else {
            user.displayProfile();
            
            System.out.println("    (Press Enter to keep current value)");
            
            String name = ConsoleUtils.readOptionalString("    New Name [" + user.getFullName() + "]: ");
            if (!name.isEmpty()) user.setFullName(name);
            
            String phone = ConsoleUtils.readOptionalString("    New Phone [" + 
                (user.getPhone() != null ? user.getPhone() : "N/A") + "]: ");
            if (!phone.isEmpty()) user.setPhone(phone);
            
            String email = ConsoleUtils.readOptionalString("    New Email [" + 
                (user.getEmail() != null ? user.getEmail() : "N/A") + "]: ");
            if (!email.isEmpty()) user.setEmail(email);
            
            if (userDAO.updateUser(user)) {
                ConsoleUtils.printSuccess("Staff information updated successfully!");
                userDAO.logActivity(currentUser.getUserId(), "UPDATE_STAFF", 
                    "Updated staff member: " + user.getUsername());
            } else {
                ConsoleUtils.printError("Failed to update staff information.");
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Deactivate staff
     */
    private void deactivateStaff() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("DEACTIVATE STAFF");
        
        int userId = ConsoleUtils.readInt("    Enter Staff ID: ", 1, 99999);
        User user = userDAO.getUserById(userId);
        
        if (user == null) {
            ConsoleUtils.printError("Staff member not found.");
        } else if (user.getRole() != UserRole.STAFF) {
            ConsoleUtils.printError("Cannot deactivate admin users.");
        } else if (user.getStatus() == UserStatus.INACTIVE) {
            ConsoleUtils.printInfo("This staff member is already inactive.");
        } else {
            user.displayProfile();
            
            ConsoleUtils.printWarning("This will prevent the staff member from logging in!");
            if (ConsoleUtils.readYesNo("    Are you sure you want to deactivate this staff member?")) {
                if (userDAO.deleteUser(userId)) {
                    ConsoleUtils.printSuccess("Staff member deactivated successfully!");
                    userDAO.logActivity(currentUser.getUserId(), "DEACTIVATE_STAFF", 
                        "Deactivated staff member: " + user.getUsername());
                } else {
                    ConsoleUtils.printError("Failed to deactivate staff member.");
                }
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Reset staff password
     */
    private void resetStaffPassword() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("RESET STAFF PASSWORD");
        
        int userId = ConsoleUtils.readInt("    Enter Staff ID: ", 1, 99999);
        User user = userDAO.getUserById(userId);
        
        if (user == null) {
            ConsoleUtils.printError("Staff member not found.");
        } else if (user.getRole() != UserRole.STAFF) {
            ConsoleUtils.printError("Cannot reset admin passwords from this menu.");
        } else {
            System.out.printf("    Staff: %s (%s)%n", user.getFullName(), user.getUsername());
            String newPassword = ConsoleUtils.readRequiredString("    Enter New Password: ");
            String confirmPassword = ConsoleUtils.readRequiredString("    Confirm New Password: ");
            
            if (!newPassword.equals(confirmPassword)) {
                ConsoleUtils.printError("Passwords do not match.");
            } else if (userDAO.changePassword(userId, newPassword)) {
                ConsoleUtils.printSuccess("Password reset successfully!");
                userDAO.logActivity(currentUser.getUserId(), "RESET_PASSWORD", 
                    "Reset password for: " + user.getUsername());
            } else {
                ConsoleUtils.printError("Failed to reset password.");
            }
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * View reports
     */
    private void viewReports() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("REPORTS");
        System.out.println();
        
        // Room statistics
        int totalRooms = roomDAO.getTotalRoomCount();
        int availableRooms = roomDAO.getRoomCountByStatus(RoomStatus.AVAILABLE);
        int occupiedRooms = roomDAO.getRoomCountByStatus(RoomStatus.OCCUPIED);
        int maintenanceRooms = roomDAO.getRoomCountByStatus(RoomStatus.MAINTENANCE);
        
        // Reservation statistics
        int totalReservations = reservationDAO.getTotalReservationCount();
        int confirmedReservations = reservationDAO.getReservationCountByStatus(ReservationStatus.CONFIRMED);
        int checkedInReservations = reservationDAO.getReservationCountByStatus(ReservationStatus.CHECKED_IN);
        
        // Billing statistics
        BigDecimal pendingAmount = billDAO.getTotalPendingAmount();
        int pendingBills = billDAO.getBillCountByStatus(PaymentStatus.PENDING);
        int paidBills = billDAO.getBillCountByStatus(PaymentStatus.PAID);
        
        // Guest statistics
        int totalGuests = guestDAO.getTotalGuestCount();
        
        System.out.println("    ╔═══════════════════════════════════════════════════════════════════════╗");
        System.out.println("    ║                        SYSTEM STATISTICS                              ║");
        System.out.println("    ╠═══════════════════════════════════════════════════════════════════════╣");
        System.out.println("    ║  ROOM STATUS                                                          ║");
        System.out.printf("    ║    Total Rooms     : %-50d ║%n", totalRooms);
        System.out.printf("    ║    Available       : %-50d ║%n", availableRooms);
        System.out.printf("    ║    Occupied        : %-50d ║%n", occupiedRooms);
        System.out.printf("    ║    Maintenance     : %-50d ║%n", maintenanceRooms);
        System.out.printf("    ║    Occupancy Rate  : %-49.1f%% ║%n", 
            totalRooms > 0 ? (occupiedRooms * 100.0 / totalRooms) : 0);
        System.out.println("    ╠═══════════════════════════════════════════════════════════════════════╣");
        System.out.println("    ║  RESERVATIONS                                                         ║");
        System.out.printf("    ║    Total           : %-50d ║%n", totalReservations);
        System.out.printf("    ║    Confirmed       : %-50d ║%n", confirmedReservations);
        System.out.printf("    ║    Checked-in      : %-50d ║%n", checkedInReservations);
        System.out.println("    ╠═══════════════════════════════════════════════════════════════════════╣");
        System.out.println("    ║  BILLING                                                              ║");
        System.out.printf("    ║    Pending Bills   : %-50d ║%n", pendingBills);
        System.out.printf("    ║    Paid Bills      : %-50d ║%n", paidBills);
        System.out.printf("    ║    Pending Amount  : Rs. %-46s ║%n", String.format("%,.2f", pendingAmount));
        System.out.println("    ╠═══════════════════════════════════════════════════════════════════════╣");
        System.out.println("    ║  GUESTS                                                               ║");
        System.out.printf("    ║    Total Guests    : %-50d ║%n", totalGuests);
        System.out.println("    ╚═══════════════════════════════════════════════════════════════════════╝");
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Show help
     */
    private void showHelp() {
        HelpScreen.showAdminHelp();
    }
    
    /**
     * Change password
     */
    private void changePassword() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("CHANGE PASSWORD");
        System.out.println();
        
        String currentPassword = ConsoleUtils.readPassword("    Current Password: ");
        
        // Verify current password
        if (!currentPassword.equals(currentUser.getPassword())) {
            ConsoleUtils.printError("Current password is incorrect.");
            ConsoleUtils.pressEnterToContinue();
            return;
        }
        
        String newPassword = ConsoleUtils.readRequiredString("    New Password: ");
        String confirmPassword = ConsoleUtils.readRequiredString("    Confirm New Password: ");
        
        if (!newPassword.equals(confirmPassword)) {
            ConsoleUtils.printError("Passwords do not match.");
        } else if (newPassword.length() < 6) {
            ConsoleUtils.printError("Password must be at least 6 characters.");
        } else if (userDAO.changePassword(currentUser.getUserId(), newPassword)) {
            currentUser.setPassword(newPassword);
            ConsoleUtils.printSuccess("Password changed successfully!");
            userDAO.logActivity(currentUser.getUserId(), "CHANGE_PASSWORD", "Changed own password");
        } else {
            ConsoleUtils.printError("Failed to change password.");
        }
        
        ConsoleUtils.pressEnterToContinue();
    }
    
    /**
     * Confirm logout
     */
    private boolean confirmLogout() {
        if (ConsoleUtils.readYesNo("    Are you sure you want to logout?")) {
            userDAO.logActivity(currentUser.getUserId(), "LOGOUT", "User logged out");
            ConsoleUtils.printSuccess("Logged out successfully. Goodbye!");
            ConsoleUtils.pressEnterToContinue();
            return true;
        }
        return false;
    }
}
