package com.oceanview.ui;

/**
 * Help Screen - Displays help information for console UI
 * @author Ocean View Resort Development Team
 */
public class HelpScreen {
    
    /**
     * Display admin help information
     */
    public static void showAdminHelp() {
        System.out.println("\n" + "=".repeat(60));
        System.out.println("                    ADMIN HELP GUIDE");
        System.out.println("=".repeat(60));
        System.out.println();
        System.out.println("DASHBOARD:");
        System.out.println("  - View summary of hotel operations");
        System.out.println("  - Monitor room availability and occupancy");
        System.out.println();
        System.out.println("RESERVATIONS:");
        System.out.println("  1. New Reservation - Create booking for guest");
        System.out.println("  2. View/Search - Find existing reservations");
        System.out.println("  3. Check-In - Process guest arrival");
        System.out.println("  4. Check-Out - Process guest departure");
        System.out.println("  5. Cancel - Cancel a reservation");
        System.out.println();
        System.out.println("ROOMS:");
        System.out.println("  1. View All Rooms - See all room status");
        System.out.println("  2. Add Room - Add new room to system");
        System.out.println("  3. Update Status - Change room status");
        System.out.println("  4. Room Types - Manage room categories");
        System.out.println();
        System.out.println("GUESTS:");
        System.out.println("  1. View Guests - List all registered guests");
        System.out.println("  2. Search Guest - Find guest by name/phone");
        System.out.println("  3. Guest History - View booking history");
        System.out.println();
        System.out.println("BILLING:");
        System.out.println("  1. Generate Bill - Create bill for checkout");
        System.out.println("  2. View Bills - List all bills");
        System.out.println("  3. Process Payment - Record payment");
        System.out.println();
        System.out.println("STAFF MANAGEMENT:");
        System.out.println("  1. View Staff - List all staff members");
        System.out.println("  2. Add Staff - Register new staff");
        System.out.println("  3. Edit Staff - Update staff details");
        System.out.println("  4. Deactivate - Disable staff account");
        System.out.println();
        System.out.println("=".repeat(60));
        System.out.println("Press Enter to continue...");
    }
    
    /**
     * Display staff help information
     */
    public static void showStaffHelp() {
        System.out.println("\n" + "=".repeat(60));
        System.out.println("                    STAFF HELP GUIDE");
        System.out.println("=".repeat(60));
        System.out.println();
        System.out.println("DASHBOARD:");
        System.out.println("  - View today's arrivals and departures");
        System.out.println("  - Quick access to common tasks");
        System.out.println();
        System.out.println("RESERVATIONS:");
        System.out.println("  1. New Reservation - Create booking for guest");
        System.out.println("  2. View/Search - Find existing reservations");
        System.out.println("  3. Check-In - Process guest arrival");
        System.out.println("  4. Check-Out - Process guest departure");
        System.out.println();
        System.out.println("ROOMS:");
        System.out.println("  1. View Available - See available rooms");
        System.out.println("  2. Check Status - View room occupancy");
        System.out.println();
        System.out.println("GUESTS:");
        System.out.println("  1. Register Guest - Add new guest");
        System.out.println("  2. Search Guest - Find by name/phone");
        System.out.println("  3. Update Info - Edit guest details");
        System.out.println();
        System.out.println("BILLING:");
        System.out.println("  1. Generate Bill - Create checkout bill");
        System.out.println("  2. Process Payment - Record payment");
        System.out.println();
        System.out.println("=".repeat(60));
        System.out.println("Press Enter to continue...");
    }
}
