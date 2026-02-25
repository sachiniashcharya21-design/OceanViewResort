package com.oceanview.dao;

import com.oceanview.model.Guest;
import com.oceanview.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Guest Data Access Object
 * Handles all database operations related to guests
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class GuestDAO {
    
    private Connection connection;
    
    /**
     * Constructor - initializes database connection
     */
    public GuestDAO() throws SQLException {
        this.connection = DatabaseConnection.getInstance().getConnection();
    }
    
    /**
     * Get guest by ID
     */
    public Guest getGuestById(int guestId) {
        String sql = "SELECT * FROM guests WHERE guest_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, guestId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToGuest(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get guest: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * Get guest by phone number
     */
    public Guest getGuestByPhone(String phone) {
        String sql = "SELECT * FROM guests WHERE phone = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, phone);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToGuest(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get guest: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * Get guest by NIC/Passport
     */
    public Guest getGuestByNicPassport(String nicPassport) {
        String sql = "SELECT * FROM guests WHERE nic_passport = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, nicPassport);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToGuest(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get guest: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * Get all guests
     */
    public List<Guest> getAllGuests() {
        List<Guest> guests = new ArrayList<>();
        String sql = "SELECT * FROM guests ORDER BY full_name";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                guests.add(mapResultSetToGuest(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get guests: " + e.getMessage());
        }
        return guests;
    }
    
    /**
     * Search guests by name
     */
    public List<Guest> searchGuestsByName(String name) {
        List<Guest> guests = new ArrayList<>();
        String sql = "SELECT * FROM guests WHERE full_name LIKE ? ORDER BY full_name";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, "%" + name + "%");
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                guests.add(mapResultSetToGuest(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to search guests: " + e.getMessage());
        }
        return guests;
    }
    
    /**
     * Add new guest
     */
    public int addGuest(Guest guest) {
        String sql = "INSERT INTO guests (full_name, nic_passport, email, phone, address, nationality, date_of_birth) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement pstmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setString(1, guest.getFullName());
            pstmt.setString(2, guest.getNicPassport());
            pstmt.setString(3, guest.getEmail());
            pstmt.setString(4, guest.getPhone());
            pstmt.setString(5, guest.getAddress());
            pstmt.setString(6, guest.getNationality());
            pstmt.setDate(7, guest.getDateOfBirth());
            
            int affectedRows = pstmt.executeUpdate();
            if (affectedRows > 0) {
                ResultSet generatedKeys = pstmt.getGeneratedKeys();
                if (generatedKeys.next()) {
                    int guestId = generatedKeys.getInt(1);
                    guest.setGuestId(guestId);
                    return guestId;
                }
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to add guest: " + e.getMessage());
        }
        return -1;
    }
    
    /**
     * Update guest
     */
    public boolean updateGuest(Guest guest) {
        String sql = "UPDATE guests SET full_name = ?, nic_passport = ?, email = ?, phone = ?, " +
                     "address = ?, nationality = ?, date_of_birth = ? WHERE guest_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, guest.getFullName());
            pstmt.setString(2, guest.getNicPassport());
            pstmt.setString(3, guest.getEmail());
            pstmt.setString(4, guest.getPhone());
            pstmt.setString(5, guest.getAddress());
            pstmt.setString(6, guest.getNationality());
            pstmt.setDate(7, guest.getDateOfBirth());
            pstmt.setInt(8, guest.getGuestId());
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to update guest: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Delete guest
     */
    public boolean deleteGuest(int guestId) {
        String sql = "DELETE FROM guests WHERE guest_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, guestId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to delete guest: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Get total guest count
     */
    public int getTotalGuestCount() {
        String sql = "SELECT COUNT(*) FROM guests";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get guest count: " + e.getMessage());
        }
        return 0;
    }
    
    /**
     * Map ResultSet to Guest object
     */
    private Guest mapResultSetToGuest(ResultSet rs) throws SQLException {
        Guest guest = new Guest();
        guest.setGuestId(rs.getInt("guest_id"));
        guest.setFullName(rs.getString("full_name"));
        guest.setNicPassport(rs.getString("nic_passport"));
        guest.setEmail(rs.getString("email"));
        guest.setPhone(rs.getString("phone"));
        guest.setAddress(rs.getString("address"));
        guest.setNationality(rs.getString("nationality"));
        guest.setDateOfBirth(rs.getDate("date_of_birth"));
        guest.setCreatedAt(rs.getTimestamp("created_at"));
        guest.setUpdatedAt(rs.getTimestamp("updated_at"));
        return guest;
    }
}
