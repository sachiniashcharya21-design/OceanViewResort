package com.oceanview.dao;

import com.oceanview.model.*;
import com.oceanview.model.Reservation.ReservationStatus;
import com.oceanview.model.Room.RoomStatus;
import com.oceanview.util.DatabaseConnection;

import java.sql.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Reservation Data Access Object
 * Handles all database operations related to reservations
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class ReservationDAO {
    
    private Connection connection;
    private GuestDAO guestDAO;
    private RoomDAO roomDAO;
    private UserDAO userDAO;
    
    /**
     * Constructor - initializes database connection
     */
    public ReservationDAO() throws SQLException {
        this.connection = DatabaseConnection.getInstance().getConnection();
        this.guestDAO = new GuestDAO();
        this.roomDAO = new RoomDAO();
        this.userDAO = new UserDAO();
    }
    
    /**
     * Generate unique reservation number
     * Format: RESYYYYMMnnnn (e.g., RES2026020001)
     */
    public String generateReservationNumber() {
        String prefix = "RES" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
        String sql = "SELECT MAX(reservation_number) FROM reservations WHERE reservation_number LIKE ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, prefix + "%");
            ResultSet rs = pstmt.executeQuery();
            if (rs.next() && rs.getString(1) != null) {
                String lastNumber = rs.getString(1);
                int sequence = Integer.parseInt(lastNumber.substring(9)) + 1;
                return prefix + String.format("%04d", sequence);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to generate reservation number: " + e.getMessage());
        }
        return prefix + "0001";
    }
    
    /**
     * Add new reservation
     */
    public boolean addReservation(Reservation reservation) {
        String sql = "INSERT INTO reservations (reservation_number, guest_id, room_id, check_in_date, " +
                     "check_out_date, number_of_guests, special_requests, status, created_by) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement pstmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setString(1, reservation.getReservationNumber());
            pstmt.setInt(2, reservation.getGuestId());
            pstmt.setInt(3, reservation.getRoomId());
            pstmt.setDate(4, reservation.getCheckInDate());
            pstmt.setDate(5, reservation.getCheckOutDate());
            pstmt.setInt(6, reservation.getNumberOfGuests());
            pstmt.setString(7, reservation.getSpecialRequests());
            pstmt.setString(8, reservation.getStatus().name());
            pstmt.setInt(9, reservation.getCreatedBy());
            
            int affectedRows = pstmt.executeUpdate();
            if (affectedRows > 0) {
                ResultSet generatedKeys = pstmt.getGeneratedKeys();
                if (generatedKeys.next()) {
                    reservation.setReservationId(generatedKeys.getInt(1));
                }
                // Update room status to RESERVED
                roomDAO.updateRoomStatus(reservation.getRoomId(), RoomStatus.RESERVED);
                return true;
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to add reservation: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Get reservation by ID with full details
     */
    public Reservation getReservationById(int reservationId) {
        String sql = "SELECT * FROM reservations WHERE reservation_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, reservationId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToReservationWithDetails(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get reservation: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * Get reservation by reservation number
     */
    public Reservation getReservationByNumber(String reservationNumber) {
        String sql = "SELECT * FROM reservations WHERE reservation_number = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, reservationNumber);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToReservationWithDetails(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get reservation: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * Get all reservations
     */
    public List<Reservation> getAllReservations() {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT * FROM reservations ORDER BY check_in_date DESC";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                reservations.add(mapResultSetToReservationWithDetails(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get reservations: " + e.getMessage());
        }
        return reservations;
    }
    
    /**
     * Get reservations by status
     */
    public List<Reservation> getReservationsByStatus(ReservationStatus status) {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT * FROM reservations WHERE status = ? ORDER BY check_in_date";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, status.name());
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                reservations.add(mapResultSetToReservationWithDetails(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get reservations: " + e.getMessage());
        }
        return reservations;
    }
    
    /**
     * Get today's check-ins
     */
    public List<Reservation> getTodayCheckIns() {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT * FROM reservations WHERE check_in_date = CURDATE() AND status = 'CONFIRMED' " +
                     "ORDER BY created_at";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                reservations.add(mapResultSetToReservationWithDetails(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get today's check-ins: " + e.getMessage());
        }
        return reservations;
    }
    
    /**
     * Get today's check-outs
     */
    public List<Reservation> getTodayCheckOuts() {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT * FROM reservations WHERE check_out_date = CURDATE() AND status = 'CHECKED_IN' " +
                     "ORDER BY created_at";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                reservations.add(mapResultSetToReservationWithDetails(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get today's check-outs: " + e.getMessage());
        }
        return reservations;
    }
    
    /**
     * Get reservations by guest
     */
    public List<Reservation> getReservationsByGuest(int guestId) {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT * FROM reservations WHERE guest_id = ? ORDER BY check_in_date DESC";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, guestId);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                reservations.add(mapResultSetToReservationWithDetails(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get reservations: " + e.getMessage());
        }
        return reservations;
    }
    
    /**
     * Alias for getReservationsByGuest
     */
    public List<Reservation> getReservationsByGuestId(int guestId) {
        return getReservationsByGuest(guestId);
    }
    
    /**
     * Search reservations by guest name
     */
    public List<Reservation> searchReservationsByGuestName(String guestName) {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.* FROM reservations r " +
                     "JOIN guests g ON r.guest_id = g.guest_id " +
                     "WHERE g.full_name LIKE ? " +
                     "ORDER BY r.check_in_date DESC";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, "%" + guestName + "%");
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                reservations.add(mapResultSetToReservationWithDetails(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to search reservations: " + e.getMessage());
        }
        return reservations;
    }
    
    /**
     * Update reservation status
     */
    public boolean updateReservationStatus(int reservationId, ReservationStatus status) {
        String sql = "UPDATE reservations SET status = ? WHERE reservation_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, status.name());
            pstmt.setInt(2, reservationId);
            
            if (pstmt.executeUpdate() > 0) {
                // Get reservation to update room status
                Reservation reservation = getReservationById(reservationId);
                if (reservation != null) {
                    if (status == ReservationStatus.CHECKED_IN) {
                        roomDAO.updateRoomStatus(reservation.getRoomId(), RoomStatus.OCCUPIED);
                    } else if (status == ReservationStatus.CHECKED_OUT || status == ReservationStatus.CANCELLED) {
                        roomDAO.updateRoomStatus(reservation.getRoomId(), RoomStatus.AVAILABLE);
                    }
                }
                return true;
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to update reservation status: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Check-in guest
     */
    public boolean checkIn(int reservationId) {
        return updateReservationStatus(reservationId, ReservationStatus.CHECKED_IN);
    }
    
    /**
     * Check-out guest
     */
    public boolean checkOut(int reservationId) {
        return updateReservationStatus(reservationId, ReservationStatus.CHECKED_OUT);
    }
    
    /**
     * Cancel reservation
     */
    public boolean cancelReservation(int reservationId) {
        return updateReservationStatus(reservationId, ReservationStatus.CANCELLED);
    }
    
    /**
     * Update reservation
     */
    public boolean updateReservation(Reservation reservation) {
        String sql = "UPDATE reservations SET room_id = ?, check_in_date = ?, check_out_date = ?, " +
                     "number_of_guests = ?, special_requests = ? WHERE reservation_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, reservation.getRoomId());
            pstmt.setDate(2, reservation.getCheckInDate());
            pstmt.setDate(3, reservation.getCheckOutDate());
            pstmt.setInt(4, reservation.getNumberOfGuests());
            pstmt.setString(5, reservation.getSpecialRequests());
            pstmt.setInt(6, reservation.getReservationId());
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to update reservation: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Delete reservation (only for CANCELLED)
     */
    public boolean deleteReservation(int reservationId) {
        String sql = "DELETE FROM reservations WHERE reservation_id = ? AND status = 'CANCELLED'";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, reservationId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to delete reservation: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Get reservation count by status
     */
    public int getReservationCountByStatus(ReservationStatus status) {
        String sql = "SELECT COUNT(*) FROM reservations WHERE status = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, status.name());
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get reservation count: " + e.getMessage());
        }
        return 0;
    }
    
    /**
     * Get total reservation count
     */
    public int getTotalReservationCount() {
        String sql = "SELECT COUNT(*) FROM reservations";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get reservation count: " + e.getMessage());
        }
        return 0;
    }
    
    /**
     * Check if room is available for dates
     */
    public boolean isRoomAvailable(int roomId, Date checkIn, Date checkOut) {
        String sql = "SELECT COUNT(*) FROM reservations " +
                     "WHERE room_id = ? AND status IN ('CONFIRMED', 'CHECKED_IN') " +
                     "AND NOT (check_out_date <= ? OR check_in_date >= ?)";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, roomId);
            pstmt.setDate(2, checkIn);
            pstmt.setDate(3, checkOut);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) == 0;
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to check room availability: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Map ResultSet to Reservation with all related details
     */
    private Reservation mapResultSetToReservationWithDetails(ResultSet rs) throws SQLException {
        Reservation reservation = new Reservation();
        reservation.setReservationId(rs.getInt("reservation_id"));
        reservation.setReservationNumber(rs.getString("reservation_number"));
        reservation.setGuestId(rs.getInt("guest_id"));
        reservation.setRoomId(rs.getInt("room_id"));
        reservation.setCheckInDate(rs.getDate("check_in_date"));
        reservation.setCheckOutDate(rs.getDate("check_out_date"));
        reservation.setNumberOfGuests(rs.getInt("number_of_guests"));
        reservation.setSpecialRequests(rs.getString("special_requests"));
        reservation.setStatus(ReservationStatus.valueOf(rs.getString("status")));
        reservation.setCreatedBy(rs.getInt("created_by"));
        reservation.setCreatedAt(rs.getTimestamp("created_at"));
        reservation.setUpdatedAt(rs.getTimestamp("updated_at"));
        
        // Load related objects
        reservation.setGuest(guestDAO.getGuestById(reservation.getGuestId()));
        reservation.setRoom(roomDAO.getRoomById(reservation.getRoomId()));
        if (reservation.getCreatedBy() > 0) {
            reservation.setCreatedByUser(userDAO.getUserById(reservation.getCreatedBy()));
        }
        
        return reservation;
    }
}
