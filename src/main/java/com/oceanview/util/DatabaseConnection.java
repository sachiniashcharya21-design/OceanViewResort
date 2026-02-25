package com.oceanview.util;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Database Connection Utility Class
 * Manages database connections using singleton pattern
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class DatabaseConnection {
    
    private static DatabaseConnection instance;
    private Connection connection;
    private String url;
    private String username;
    private String password;
    
    /**
     * Private constructor - loads database configuration
     */
    private DatabaseConnection() {
        loadConfiguration();
    }
    
    /**
     * Load database configuration from properties file
     */
    private void loadConfiguration() {
        Properties properties = new Properties();
        try (InputStream input = getClass().getClassLoader().getResourceAsStream("config.properties")) {
            if (input == null) {
                // Default configuration for XAMPP
                this.url = "jdbc:mysql://localhost:3306/ocean_view_resort";
                this.username = "root";
                this.password = "";
                System.out.println("[INFO] Using default database configuration");
                return;
            }
            properties.load(input);
            this.url = properties.getProperty("db.url");
            this.username = properties.getProperty("db.username");
            this.password = properties.getProperty("db.password");
        } catch (IOException e) {
            System.err.println("[ERROR] Failed to load configuration: " + e.getMessage());
            // Use defaults
            this.url = "jdbc:mysql://localhost:3306/ocean_view_resort";
            this.username = "root";
            this.password = "";
        }
    }
    
    /**
     * Get singleton instance
     */
    public static synchronized DatabaseConnection getInstance() {
        if (instance == null) {
            instance = new DatabaseConnection();
        }
        return instance;
    }
    
    /**
     * Get database connection
     * Creates new connection if not exists or closed
     */
    public Connection getConnection() throws SQLException {
        try {
            if (connection == null || connection.isClosed()) {
                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                } catch (ClassNotFoundException e) {
                    // Support environments that still provide the legacy MySQL driver class
                    Class.forName("com.mysql.jdbc.Driver");
                }
                connection = DriverManager.getConnection(url, username, password);
            }
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL JDBC driver not found. Add mysql-connector-j to runtime classpath. Details: " + e.getMessage());
        }
        return connection;
    }
    
    /**
     * Close database connection
     */
    public void closeConnection() {
        if (connection != null) {
            try {
                connection.close();
                System.out.println("[INFO] Database connection closed");
            } catch (SQLException e) {
                System.err.println("[ERROR] Failed to close connection: " + e.getMessage());
            }
        }
    }
    
    /**
     * Test database connection
     */
    public boolean testConnection() {
        try {
            Connection conn = getConnection();
            if (conn != null && !conn.isClosed()) {
                System.out.println("[SUCCESS] Database connection established!");
                return true;
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Database connection failed: " + e.getMessage());
        }
        return false;
    }
}
