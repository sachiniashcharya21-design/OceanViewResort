package com.oceanview.ui;

import com.oceanview.dao.*;
import com.oceanview.model.*;
import com.oceanview.model.Bill.PaymentMethod;
import com.oceanview.model.Bill.PaymentStatus;
import com.oceanview.model.Reservation.ReservationStatus;
import com.oceanview.model.Room.RoomStatus;
import com.oceanview.util.ConsoleUtils;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;

/**
 * Staff Dashboard
 * Limited access dashboard for staff members
 * Staff can: Add reservations, check-in/out, view reservations, generate bills
 * Staff cannot: Manage staff, manage rooms, update rates, view reports
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class StaffDashboard {
    
    private User currentUser;
    private UserDAO userDAO;
    private GuestDAO guestDAO;
    private RoomDAO roomDAO;
    private ReservationDAO reservationDAO;
    private BillDAO billDAO;
    
    /**
     * Constructor
     */
    public StaffDashboard(User user) {
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
     * Show staff dashboard main menu
     */
    public void show() {
        boolean running = true;
        while (running) {
            displayMainMenu();
            int choice = ConsoleUtils.readInt("    Enter your choice: ", 0, 7);
            
            switch (choice) {
                case 1 -> showProfile();
                case 2 -> manageReservations();
                case 3 -> viewRooms();
                case 4 -> viewGuests();
                case 5 -> manageBilling();
                case 6 -> showHelp();
                case 7 -> changePassword();
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
        System.out.println("    ║                    STAFF DASHBOARD - MAIN MENU                        ║");
        System.out.println("    ╠═══════════════════════════════════════════════════════════════════════╣");
        System.out.printf("    ║  Logged in as: %-57s ║%n", currentUser.getFullName() + " (STAFF)");
        System.out.printf("    ║  Date: %-65s ║%n", LocalDate.now());
        System.out.println("    ╠═══════════════════════════════════════════════════════════════════════╣");
        System.out.println("    ║                                                                       ║");
        System.out.println("    ║    [1]  My Profile                                                    ║");
        System.out.println("    ║    [2]  Reservations                                                  ║");
        System.out.println("    ║    [3]  View Rooms                                                    ║");
        System.out.println("    ║    [4]  View Guests                                                   ║");
        System.out.println("    ║    [5]  Billing                                                       ║");
        System.out.println("    ║    [6]  Help & Guidelines                                             ║");
        System.out.println("    ║    [7]  Change Password                                               ║");
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
            int availableRooms = roomDAO.getRoomCountByStatus(RoomStatus.AVAILABLE);
            int todayCheckIns = reservationDAO.getTodayCheckIns().size();
            int todayCheckOuts = reservationDAO.getTodayCheckOuts().size();
            
            System.out.println("    ┌─────────────────────────────────────────────────────────────────────┐");
            System.out.println("    │  TODAY'S OVERVIEW                                                   │");
            System.out.println("    ├─────────────────────────────────────────────────────────────────────┤");
            System.out.printf("    │  Available Rooms: %-5d │ Check-ins: %-5d │ Check-outs: %-5d       │%n",
                availableRooms, todayCheckIns, todayCheckOuts);
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
            ConsoleUtils.printHeader("RESERVATIONS");
            System.out.println();
            ConsoleUtils.printMenuOption(1, "Add New Reservation");
            ConsoleUtils.printMenuOption(2, "View All Reservations");
            ConsoleUtils.printMenuOption(3, "Search Reservation");
            ConsoleUtils.printMenuOption(4, "Today's Check-ins");
            ConsoleUtils.printMenuOption(5, "Today's Check-outs");
            ConsoleUtils.printMenuOption(6, "Check-in Guest");
            ConsoleUtils.printMenuOption(7, "Check-out Guest");
            ConsoleUtils.printMenuOption(0, "Back to Main Menu");
            System.out.println();
            
            int choice = ConsoleUtils.readInt("    Enter your choice: ", 0, 7);
            
            switch (choice) {
                case 1 -> addNewReservation();
                case 2 -> viewAllReservations();
                case 3 -> searchReservation();
                case 4 -> viewTodayCheckIns();
                case 5 -> viewTodayCheckOuts();
                case 6 -> checkInGuest();
                case 7 -> checkOutGuest();
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
     * View rooms (read-only for staff)
     */
    private void viewRooms() {
        boolean back = false;
        while (!back) {
            ConsoleUtils.clearScreen();
            ConsoleUtils.printHeader("VIEW ROOMS");
            System.out.println();
            ConsoleUtils.printMenuOption(1, "View All Rooms");
            ConsoleUtils.printMenuOption(2, "View Available Rooms");
            ConsoleUtils.printMenuOption(3, "View Room Types & Rates");
            ConsoleUtils.printMenuOption(0, "Back to Main Menu");
            System.out.println();
            
            int choice = ConsoleUtils.readInt("    Enter your choice: ", 0, 3);
            
            switch (choice) {
                case 1 -> viewAllRooms();
                case 2 -> viewAvailableRooms();
                case 3 -> viewRoomTypes();
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
     * View guests (read-only for staff)
     */
    private void viewGuests() {
        boolean back = false;
        while (!back) {
            ConsoleUtils.clearScreen();
            ConsoleUtils.printHeader("VIEW GUESTS");
            System.out.println();
            ConsoleUtils.printMenuOption(1, "View All Guests");
            ConsoleUtils.printMenuOption(2, "Search Guest");
            ConsoleUtils.printMenuOption(0, "Back to Main Menu");
            System.out.println();
            
            int choice = ConsoleUtils.readInt("    Enter your choice: ", 0, 2);
            
            switch (choice) {
                case 1 -> viewAllGuests();
                case 2 -> searchGuest();
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
     * Manage billing (limited for staff - no discount)
     */
    private void manageBilling() {
        boolean back = false;
        while (!back) {
            ConsoleUtils.clearScreen();
            ConsoleUtils.printHeader("BILLING");
            System.out.println();
            ConsoleUtils.printMenuOption(1, "Generate Bill");
            ConsoleUtils.printMenuOption(2, "View Bill");
            ConsoleUtils.printMenuOption(3, "Process Payment");
            ConsoleUtils.printMenuOption(0, "Back to Main Menu");
            System.out.println();
            
            int choice = ConsoleUtils.readInt("    Enter your choice: ", 0, 3);
            
            switch (choice) {
                case 1 -> generateBill();
                case 2 -> searchBill();
                case 3 -> processPayment();
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
     * Search and view bill
     */
    private void searchBill() {
        ConsoleUtils.clearScreen();
        ConsoleUtils.printHeader("VIEW BILL");
        
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
     * Show help
     */
    private void showHelp() {
        HelpScreen.showStaffHelp();
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
