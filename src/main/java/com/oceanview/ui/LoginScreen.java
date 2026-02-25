package com.oceanview.ui;

import com.oceanview.dao.UserDAO;
import com.oceanview.model.User;
import com.oceanview.util.ConsoleUtils;
import com.oceanview.util.DatabaseConnection;

import java.sql.SQLException;

/**
 * Login Screen Handler
 * Manages user authentication and login UI
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class LoginScreen {
    
    private UserDAO userDAO;
    private int loginAttempts = 0;
    private static final int MAX_LOGIN_ATTEMPTS = 3;
    
    /**
     * Constructor
     */
    public LoginScreen() {
        try {
            this.userDAO = new UserDAO();
        } catch (SQLException e) {
            System.err.println("[CRITICAL] Failed to initialize UserDAO: " + e.getMessage());
        }
    }
    
    /**
     * Display login screen and authenticate user
     * @return Authenticated User object, or null if authentication fails
     */
    public User showLoginScreen() {
        displayWelcomeBanner();
        
        // Test database connection
        if (!DatabaseConnection.getInstance().testConnection()) {
            ConsoleUtils.printError("Cannot connect to database. Please ensure MySQL is running.");
            ConsoleUtils.printInfo("Start XAMPP and ensure MySQL service is active.");
            ConsoleUtils.printInfo("Import the database using: database/ocean_view_resort_db.sql");
            ConsoleUtils.pressEnterToContinue();
            return null;
        }
        
        while (loginAttempts < MAX_LOGIN_ATTEMPTS) {
            displayLoginForm();
            
            String username = ConsoleUtils.readString("    Username: ");
            String password = ConsoleUtils.readPassword("    Password: ");
            
            if (username.isEmpty() || password.isEmpty()) {
                ConsoleUtils.printError("Username and password are required.");
                loginAttempts++;
                continue;
            }
            
            User user = authenticate(username, password);
            if (user != null) {
                displayLoginSuccess(user);
                return user;
            } else {
                loginAttempts++;
                int remaining = MAX_LOGIN_ATTEMPTS - loginAttempts;
                if (remaining > 0) {
                    ConsoleUtils.printError("Invalid username or password. " + remaining + " attempt(s) remaining.");
                } else {
                    ConsoleUtils.printError("Maximum login attempts exceeded. System locked.");
                    ConsoleUtils.printInfo("Please contact the system administrator.");
                }
            }
        }
        
        return null;
    }
    
    /**
     * Authenticate user credentials
     */
    private User authenticate(String username, String password) {
        if (userDAO == null) {
            return null;
        }
        
        User user = userDAO.authenticate(username, password);
        if (user != null) {
            // Log successful login
            userDAO.logActivity(user.getUserId(), "LOGIN", "User logged in successfully");
        }
        return user;
    }
    
    /**
     * Display welcome banner
     */
    private void displayWelcomeBanner() {
        ConsoleUtils.clearScreen();
        System.out.println("\n");
        System.out.println("    ╔═══════════════════════════════════════════════════════════════════════╗");
        System.out.println("    ║                                                                       ║");
        System.out.println("    ║      ██████╗  ██████╗███████╗ █████╗ ███╗   ██╗                       ║");
        System.out.println("    ║     ██╔═══██╗██╔════╝██╔════╝██╔══██╗████╗  ██║                       ║");
        System.out.println("    ║     ██║   ██║██║     █████╗  ███████║██╔██╗ ██║                       ║");
        System.out.println("    ║     ██║   ██║██║     ██╔══╝  ██╔══██║██║╚██╗██║                       ║");
        System.out.println("    ║     ╚██████╔╝╚██████╗███████╗██║  ██║██║ ╚████║                       ║");
        System.out.println("    ║      ╚═════╝  ╚═════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝                       ║");
        System.out.println("    ║                                                                       ║");
        System.out.println("    ║     ██╗   ██╗██╗███████╗██╗    ██╗                                    ║");
        System.out.println("    ║     ██║   ██║██║██╔════╝██║    ██║                                    ║");
        System.out.println("    ║     ██║   ██║██║█████╗  ██║ █╗ ██║                                    ║");
        System.out.println("    ║     ╚██╗ ██╔╝██║██╔══╝  ██║███╗██║                                    ║");
        System.out.println("    ║      ╚████╔╝ ██║███████╗╚███╔███╔╝                                    ║");
        System.out.println("    ║       ╚═══╝  ╚═╝╚══════╝ ╚══╝╚══╝                                     ║");
        System.out.println("    ║                                                                       ║");
        System.out.println("    ║     ██████╗ ███████╗███████╗ ██████╗ ██████╗ ████████╗                ║");
        System.out.println("    ║     ██╔══██╗██╔════╝██╔════╝██╔═══██╗██╔══██╗╚══██╔══╝                ║");
        System.out.println("    ║     ██████╔╝█████╗  ███████╗██║   ██║██████╔╝   ██║                   ║");
        System.out.println("    ║     ██╔══██╗██╔══╝  ╚════██║██║   ██║██╔══██╗   ██║                   ║");
        System.out.println("    ║     ██║  ██║███████╗███████║╚██████╔╝██║  ██║   ██║                   ║");
        System.out.println("    ║     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝                   ║");
        System.out.println("    ║                                                                       ║");
        System.out.println("    ║                   G A L L E ,  S R I  L A N K A                       ║");
        System.out.println("    ║                                                                       ║");
        System.out.println("    ╠═══════════════════════════════════════════════════════════════════════╣");
        System.out.println("    ║           H O T E L   R E S E R V A T I O N   S Y S T E M            ║");
        System.out.println("    ║                         Version 1.0                                   ║");
        System.out.println("    ╚═══════════════════════════════════════════════════════════════════════╝");
        System.out.println();
    }
    
    /**
     * Display login form header
     */
    private void displayLoginForm() {
        System.out.println();
        System.out.println("    ┌───────────────────────────────────────────────────────────────────────┐");
        System.out.println("    │                      USER AUTHENTICATION                              │");
        System.out.println("    │             Please enter your credentials to continue                 │");
        System.out.println("    └───────────────────────────────────────────────────────────────────────┘");
        System.out.println();
    }
    
    /**
     * Display login success message
     */
    private void displayLoginSuccess(User user) {
        System.out.println();
        System.out.println("    ╔═══════════════════════════════════════════════════════════════════════╗");
        System.out.println("    ║                     LOGIN SUCCESSFUL                                  ║");
        System.out.println("    ╠═══════════════════════════════════════════════════════════════════════╣");
        System.out.printf("    ║  Welcome, %-62s ║%n", user.getFullName());
        System.out.printf("    ║  Role: %-65s ║%n", user.getRole());
        System.out.printf("    ║  Login Time: %-59s ║%n", java.time.LocalDateTime.now().format(
            java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        System.out.println("    ╚═══════════════════════════════════════════════════════════════════════╝");
        
        try {
            Thread.sleep(1500); // Brief pause to show welcome message
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
