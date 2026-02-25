package com.oceanview.dao;

import com.oceanview.model.User;
import com.oceanview.model.User.UserRole;
import com.oceanview.model.User.UserStatus;
import com.oceanview.util.DatabaseConnection;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * User Data Access Object
 * Handles all database operations related to users
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class UserDAO {

    private Connection connection;

    /**
     * Constructor - initializes database connection
     */
    public UserDAO() throws SQLException {
        this.connection = DatabaseConnection.getInstance().getConnection();
    }

    /**
     * Authenticate user login
     * 
     * @param username The username
     * @param password The password
     * @return User object if authenticated, null otherwise
     */
    public User authenticate(String username, String password) {
        String sql = "SELECT * FROM users WHERE username = ? AND password = ? AND status = 'ACTIVE'";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, username);
            pstmt.setString(2, password);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToUser(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Authentication failed: " + e.getMessage());
        }
        return null;
    }

    /**
     * Get user by ID
     */
    public User getUserById(int userId) {
        String sql = "SELECT * FROM users WHERE user_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToUser(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get user: " + e.getMessage());
        }
        return null;
    }

    /**
     * Get user by username
     */
    public User getUserByUsername(String username) {
        String sql = "SELECT * FROM users WHERE username = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToUser(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get user: " + e.getMessage());
        }
        return null;
    }

    /**
     * Get all users
     */
    public List<User> getAllUsers() {
        List<User> users = new ArrayList<>();
        String sql = "SELECT * FROM users ORDER BY role, full_name";
        try (Statement stmt = connection.createStatement();
                ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                users.add(mapResultSetToUser(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get users: " + e.getMessage());
        }
        return users;
    }

    /**
     * Get all staff users
     */
    public List<User> getAllStaff() {
        List<User> staff = new ArrayList<>();
        String sql = "SELECT * FROM users WHERE role = 'STAFF' ORDER BY full_name";
        try (Statement stmt = connection.createStatement();
                ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                staff.add(mapResultSetToUser(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get staff: " + e.getMessage());
        }
        return staff;
    }

    /**
     * Add new user
     */
    public boolean addUser(User user) {
        String sql = "INSERT INTO users (username, password, password_hash, role, full_name, email, phone, address, hire_date, status) "
                +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement pstmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setString(1, user.getUsername());
            pstmt.setString(2, user.getPassword());
            pstmt.setString(3, sha256(user.getPassword()));
            pstmt.setString(4, user.getRole().name());
            pstmt.setString(5, user.getFullName());
            pstmt.setString(6, user.getEmail());
            pstmt.setString(7, user.getPhone());
            pstmt.setString(8, user.getAddress());
            pstmt.setDate(9, user.getHireDate());
            pstmt.setString(10, user.getStatus().name());

            int affectedRows = pstmt.executeUpdate();
            if (affectedRows > 0) {
                ResultSet generatedKeys = pstmt.getGeneratedKeys();
                if (generatedKeys.next()) {
                    user.setUserId(generatedKeys.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to add user: " + e.getMessage());
        }
        return false;
    }

    /**
     * Update user
     */
    public boolean updateUser(User user) {
        String sql = "UPDATE users SET full_name = ?, email = ?, phone = ?, address = ?, status = ? " +
                "WHERE user_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, user.getFullName());
            pstmt.setString(2, user.getEmail());
            pstmt.setString(3, user.getPhone());
            pstmt.setString(4, user.getAddress());
            pstmt.setString(5, user.getStatus().name());
            pstmt.setInt(6, user.getUserId());

            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to update user: " + e.getMessage());
        }
        return false;
    }

    /**
     * Change user password
     */
    public boolean changePassword(int userId, String newPassword) {
        String sql = "UPDATE users SET password = ?, password_hash = ? WHERE user_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, newPassword);
            pstmt.setString(2, sha256(newPassword));
            pstmt.setInt(3, userId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to change password: " + e.getMessage());
        }
        return false;
    }

    /**
     * Compute SHA-256 hash of a string
     */
    private String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            return value;
        }
    }

    /**
     * Delete user (soft delete - set status to INACTIVE)
     */
    public boolean deleteUser(int userId) {
        String sql = "UPDATE users SET status = 'INACTIVE' WHERE user_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to delete user: " + e.getMessage());
        }
        return false;
    }

    /**
     * Deactivate user
     */
    public boolean deactivateUser(int userId) {
        return deleteUser(userId); // Same as soft delete
    }

    /**
     * Activate user
     */
    public boolean activateUser(int userId) {
        String sql = "UPDATE users SET status = 'ACTIVE' WHERE user_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to activate user: " + e.getMessage());
        }
        return false;
    }

    /**
     * Check if username exists
     */
    public boolean usernameExists(String username) {
        String sql = "SELECT COUNT(*) FROM users WHERE username = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to check username: " + e.getMessage());
        }
        return false;
    }

    /**
     * Log user activity
     */
    public void logActivity(int userId, String action, String description) {
        String sql = "INSERT INTO activity_log (user_id, action, description) VALUES (?, ?, ?)";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            pstmt.setString(2, action);
            pstmt.setString(3, description);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to log activity: " + e.getMessage());
        }
    }

    /**
     * Map ResultSet to User object
     */
    private User mapResultSetToUser(ResultSet rs) throws SQLException {
        User user = new User();
        user.setUserId(rs.getInt("user_id"));
        user.setUsername(rs.getString("username"));
        String password = rs.getString("password");
        if (password == null || password.isEmpty()) {
            try {
                password = rs.getString("password_hash");
            } catch (SQLException ignored) {
                // Keep fallback for schemas without password_hash
            }
        }
        user.setPassword(password);
        user.setRole(UserRole.valueOf(rs.getString("role")));
        user.setFullName(rs.getString("full_name"));
        user.setEmail(rs.getString("email"));
        user.setPhone(rs.getString("phone"));
        user.setAddress(rs.getString("address"));
        user.setHireDate(rs.getDate("hire_date"));
        user.setStatus(UserStatus.valueOf(rs.getString("status")));
        user.setCreatedAt(rs.getTimestamp("created_at"));
        user.setUpdatedAt(rs.getTimestamp("updated_at"));
        return user;
    }
}
