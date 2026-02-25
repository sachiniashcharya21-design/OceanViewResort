package com.oceanview.model;

import java.sql.Timestamp;

/**
 * User Model Class
 * Represents Admin and Staff users in the system
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class User {
    
    private int userId;
    private String username;
    private String password;
    private UserRole role;
    private String fullName;
    private String email;
    private String phone;
    private String address;
    private java.sql.Date hireDate;
    private UserStatus status;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    
    /**
     * User Role Enum
     */
    public enum UserRole {
        ADMIN, STAFF
    }
    
    /**
     * User Status Enum
     */
    public enum UserStatus {
        ACTIVE, INACTIVE
    }
    
    // Default Constructor
    public User() {}
    
    // Parameterized Constructor
    public User(int userId, String username, String password, UserRole role, String fullName, 
                String email, String phone, String address) {
        this.userId = userId;
        this.username = username;
        this.password = password;
        this.role = role;
        this.fullName = fullName;
        this.email = email;
        this.phone = phone;
        this.address = address;
        this.status = UserStatus.ACTIVE;
    }
    
    // Getters and Setters
    public int getUserId() {
        return userId;
    }
    
    public void setUserId(int userId) {
        this.userId = userId;
    }
    
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getPassword() {
        return password;
    }
    
    public void setPassword(String password) {
        this.password = password;
    }
    
    public UserRole getRole() {
        return role;
    }
    
    public void setRole(UserRole role) {
        this.role = role;
    }
    
    public String getFullName() {
        return fullName;
    }
    
    public void setFullName(String fullName) {
        this.fullName = fullName;
    }
    
    public String getEmail() {
        return email;
    }
    
    public void setEmail(String email) {
        this.email = email;
    }
    
    public String getPhone() {
        return phone;
    }
    
    public void setPhone(String phone) {
        this.phone = phone;
    }
    
    public String getAddress() {
        return address;
    }
    
    public void setAddress(String address) {
        this.address = address;
    }
    
    public java.sql.Date getHireDate() {
        return hireDate;
    }
    
    public void setHireDate(java.sql.Date hireDate) {
        this.hireDate = hireDate;
    }
    
    public UserStatus getStatus() {
        return status;
    }
    
    public void setStatus(UserStatus status) {
        this.status = status;
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
     * Check if user is admin
     */
    public boolean isAdmin() {
        return this.role == UserRole.ADMIN;
    }
    
    /**
     * Check if user is staff
     */
    public boolean isStaff() {
        return this.role == UserRole.STAFF;
    }
    
    @Override
    public String toString() {
        return "User{" +
                "userId=" + userId +
                ", username='" + username + '\'' +
                ", role=" + role +
                ", fullName='" + fullName + '\'' +
                ", email='" + email + '\'' +
                ", phone='" + phone + '\'' +
                ", status=" + status +
                '}';
    }
    
    /**
     * Display user profile in formatted manner
     */
    public void displayProfile() {
        System.out.println("\n╔═══════════════════════════════════════════════════════════════╗");
        System.out.println("║                        USER PROFILE                           ║");
        System.out.println("╠═══════════════════════════════════════════════════════════════╣");
        System.out.printf("║  User ID      : %-45d ║%n", userId);
        System.out.printf("║  Username     : %-45s ║%n", username);
        System.out.printf("║  Full Name    : %-45s ║%n", fullName);
        System.out.printf("║  Role         : %-45s ║%n", role);
        System.out.printf("║  Email        : %-45s ║%n", email != null ? email : "N/A");
        System.out.printf("║  Phone        : %-45s ║%n", phone != null ? phone : "N/A");
        System.out.printf("║  Address      : %-45s ║%n", address != null ? (address.length() > 45 ? address.substring(0, 42) + "..." : address) : "N/A");
        System.out.printf("║  Hire Date    : %-45s ║%n", hireDate != null ? hireDate.toString() : "N/A");
        System.out.printf("║  Status       : %-45s ║%n", status);
        System.out.println("╚═══════════════════════════════════════════════════════════════╝");
    }
}
