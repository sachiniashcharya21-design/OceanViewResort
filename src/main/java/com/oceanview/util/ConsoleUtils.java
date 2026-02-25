package com.oceanview.util;

import java.sql.Date;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Scanner;

/**
 * Console Input Utility Class
 * Handles user input validation and formatting
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class ConsoleUtils {
    
    private static final Scanner scanner = new Scanner(System.in);
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    
    /**
     * Read integer input with validation
     */
    public static int readInt(String prompt) {
        while (true) {
            try {
                System.out.print(prompt);
                int value = Integer.parseInt(scanner.nextLine().trim());
                return value;
            } catch (NumberFormatException e) {
                System.out.println("    [!] Invalid input. Please enter a valid number.");
            }
        }
    }
    
    /**
     * Read integer within range
     */
    public static int readInt(String prompt, int min, int max) {
        while (true) {
            int value = readInt(prompt);
            if (value >= min && value <= max) {
                return value;
            }
            System.out.printf("    [!] Please enter a number between %d and %d.%n", min, max);
        }
    }
    
    /**
     * Read string input
     */
    public static String readString(String prompt) {
        System.out.print(prompt);
        return scanner.nextLine().trim();
    }
    
    /**
     * Read non-empty string
     */
    public static String readRequiredString(String prompt) {
        while (true) {
            String value = readString(prompt);
            if (!value.isEmpty()) {
                return value;
            }
            System.out.println("    [!] This field is required. Please enter a value.");
        }
    }
    
    /**
     * Read optional string (can be empty)
     */
    public static String readOptionalString(String prompt) {
        return readString(prompt);
    }
    
    /**
     * Read phone number with validation
     */
    public static String readPhoneNumber(String prompt) {
        while (true) {
            String phone = readString(prompt);
            // Remove spaces and dashes
            phone = phone.replaceAll("[\\s-]", "");
            // Validate phone format (allow + at start, then 9-15 digits)
            if (phone.matches("\\+?\\d{9,15}")) {
                return phone;
            }
            System.out.println("    [!] Invalid phone number. Use format: +94771234567 or 0771234567");
        }
    }
    
    /**
     * Read email with validation (optional)
     */
    public static String readEmail(String prompt) {
        while (true) {
            String email = readString(prompt);
            if (email.isEmpty()) {
                return null;
            }
            if (email.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")) {
                return email;
            }
            System.out.println("    [!] Invalid email format. Leave blank to skip or enter valid email.");
        }
    }
    
    /**
     * Read date with validation
     */
    public static Date readDate(String prompt) {
        while (true) {
            String dateStr = readString(prompt);
            try {
                LocalDate date = LocalDate.parse(dateStr, DATE_FORMAT);
                return Date.valueOf(date);
            } catch (DateTimeParseException e) {
                System.out.println("    [!] Invalid date format. Use YYYY-MM-DD (e.g., 2026-02-15)");
            }
        }
    }
    
    /**
     * Read future date with validation
     */
    public static Date readFutureDate(String prompt) {
        while (true) {
            Date date = readDate(prompt);
            if (!date.toLocalDate().isBefore(LocalDate.now())) {
                return date;
            }
            System.out.println("    [!] Date must be today or in the future.");
        }
    }
    
    /**
     * Read date after another date
     */
    public static Date readDateAfter(String prompt, Date afterDate) {
        while (true) {
            Date date = readDate(prompt);
            if (date.toLocalDate().isAfter(afterDate.toLocalDate())) {
                return date;
            }
            System.out.println("    [!] Date must be after " + afterDate);
        }
    }
    
    /**
     * Read yes/no confirmation
     */
    public static boolean readYesNo(String prompt) {
        while (true) {
            String input = readString(prompt + " (Y/N): ").toUpperCase();
            if (input.equals("Y") || input.equals("YES")) {
                return true;
            } else if (input.equals("N") || input.equals("NO")) {
                return false;
            }
            System.out.println("    [!] Please enter Y for Yes or N for No.");
        }
    }
    
    /**
     * Press enter to continue
     */
    public static void pressEnterToContinue() {
        System.out.print("\n    Press ENTER to continue...");
        scanner.nextLine();
    }
    
    /**
     * Clear console (simulated with new lines)
     */
    public static void clearScreen() {
        System.out.println("\n".repeat(50));
    }
    
    /**
     * Print header
     */
    public static void printHeader(String title) {
        System.out.println();
        System.out.println("╔═══════════════════════════════════════════════════════════════════════════╗");
        System.out.printf("║  %-73s ║%n", title);
        System.out.println("╚═══════════════════════════════════════════════════════════════════════════╝");
    }
    
    /**
     * Print sub-header
     */
    public static void printSubHeader(String title) {
        System.out.println();
        System.out.println("┌───────────────────────────────────────────────────────────────────────────┐");
        System.out.printf("│  %-73s │%n", title);
        System.out.println("└───────────────────────────────────────────────────────────────────────────┘");
    }
    
    /**
     * Print success message
     */
    public static void printSuccess(String message) {
        System.out.println("\n    [✓] SUCCESS: " + message);
    }
    
    /**
     * Print error message
     */
    public static void printError(String message) {
        System.out.println("\n    [✗] ERROR: " + message);
    }
    
    /**
     * Print warning message
     */
    public static void printWarning(String message) {
        System.out.println("\n    [!] WARNING: " + message);
    }
    
    /**
     * Print info message
     */
    public static void printInfo(String message) {
        System.out.println("\n    [i] " + message);
    }
    
    /**
     * Print divider line
     */
    public static void printDivider() {
        System.out.println("    ─────────────────────────────────────────────────────────────────────");
    }
    
    /**
     * Print menu option
     */
    public static void printMenuOption(int number, String option) {
        System.out.printf("    [%d] %s%n", number, option);
    }
    
    /**
     * Print table header
     */
    public static void printTableHeader(String... columns) {
        System.out.println();
        StringBuilder header = new StringBuilder("│");
        StringBuilder divider = new StringBuilder("├");
        for (String col : columns) {
            header.append(String.format(" %-15s │", col));
            divider.append("─────────────────┼");
        }
        // Fix last character
        String div = divider.toString();
        div = div.substring(0, div.length() - 1) + "┤";
        System.out.println("┌" + "─".repeat(header.length() - 2) + "┐");
        System.out.println(header);
        System.out.println(div);
    }
    
    /**
     * Format currency
     */
    public static String formatCurrency(java.math.BigDecimal amount) {
        return String.format("Rs. %,.2f", amount);
    }
    
    /**
     * Mask password input (shows asterisks)
     */
    public static String readPassword(String prompt) {
        System.out.print(prompt);
        // Note: In console, we can't hide input without Console class
        // For simplicity, we'll read normally but with note
        return scanner.nextLine().trim();
    }
}
