package com.oceanview.dao;

import com.oceanview.model.Room;
import com.oceanview.model.Room.RoomStatus;
import com.oceanview.model.RoomType;
import com.oceanview.model.RoomType.RoomTypeStatus;
import com.oceanview.util.DatabaseConnection;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Room Data Access Object
 * Handles all database operations related to rooms and room types
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class RoomDAO {
    
    private Connection connection;
    
    /**
     * Constructor - initializes database connection
     */
    public RoomDAO() throws SQLException {
        this.connection = DatabaseConnection.getInstance().getConnection();
    }
    
    // ==================== ROOM TYPE OPERATIONS ====================
    
    /**
     * Get all room types
     */
    public List<RoomType> getAllRoomTypes() {
        List<RoomType> roomTypes = new ArrayList<>();
        String sql = "SELECT * FROM room_types WHERE status = 'AVAILABLE' ORDER BY rate_per_night";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                roomTypes.add(mapResultSetToRoomType(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get room types: " + e.getMessage());
        }
        return roomTypes;
    }
    
    /**
     * Get room type by ID
     */
    public RoomType getRoomTypeById(int roomTypeId) {
        String sql = "SELECT * FROM room_types WHERE room_type_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, roomTypeId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToRoomType(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get room type: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * Get room type by name
     */
    public RoomType getRoomTypeByName(String typeName) {
        String sql = "SELECT * FROM room_types WHERE type_name = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, typeName);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToRoomType(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get room type: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * Add new room type
     */
    public boolean addRoomType(RoomType roomType) {
        String sql = "INSERT INTO room_types (type_name, description, rate_per_night, max_occupancy, amenities) " +
                     "VALUES (?, ?, ?, ?, ?)";
        try (PreparedStatement pstmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setString(1, roomType.getTypeName());
            pstmt.setString(2, roomType.getDescription());
            pstmt.setBigDecimal(3, roomType.getRatePerNight());
            pstmt.setInt(4, roomType.getMaxOccupancy());
            pstmt.setString(5, roomType.getAmenities());
            
            int affectedRows = pstmt.executeUpdate();
            if (affectedRows > 0) {
                ResultSet generatedKeys = pstmt.getGeneratedKeys();
                if (generatedKeys.next()) {
                    roomType.setRoomTypeId(generatedKeys.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to add room type: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Update room type rate
     */
    public boolean updateRoomTypeRate(int roomTypeId, BigDecimal newRate) {
        String sql = "UPDATE room_types SET rate_per_night = ? WHERE room_type_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setBigDecimal(1, newRate);
            pstmt.setInt(2, roomTypeId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to update room type rate: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Update room type
     */
    public boolean updateRoomType(RoomType roomType) {
        String sql = "UPDATE room_types SET type_name = ?, description = ?, rate_per_night = ?, " +
                     "max_occupancy = ?, amenities = ? WHERE room_type_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, roomType.getTypeName());
            pstmt.setString(2, roomType.getDescription());
            pstmt.setBigDecimal(3, roomType.getRatePerNight());
            pstmt.setInt(4, roomType.getMaxOccupancy());
            pstmt.setString(5, roomType.getAmenities());
            pstmt.setInt(6, roomType.getRoomTypeId());
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to update room type: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Delete room type (soft delete by setting status to DISCONTINUED)
     */
    public boolean deleteRoomType(int roomTypeId) {
        // Check if any rooms are using this type
        String checkSql = "SELECT COUNT(*) FROM rooms WHERE room_type_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(checkSql)) {
            pstmt.setInt(1, roomTypeId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next() && rs.getInt(1) > 0) {
                return false; // Cannot delete, rooms exist
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to check rooms: " + e.getMessage());
            return false;
        }
        
        String sql = "UPDATE room_types SET status = 'DISCONTINUED' WHERE room_type_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, roomTypeId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to delete room type: " + e.getMessage());
        }
        return false;
    }
    
    // ==================== ROOM OPERATIONS ====================
    
    /**
     * Get room by ID
     */
    public Room getRoomById(int roomId) {
        String sql = "SELECT r.*, rt.type_name, rt.description, rt.rate_per_night, rt.max_occupancy, rt.amenities " +
                     "FROM rooms r JOIN room_types rt ON r.room_type_id = rt.room_type_id " +
                     "WHERE r.room_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, roomId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToRoomWithType(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get room: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * Get room by room number
     */
    public Room getRoomByNumber(String roomNumber) {
        String sql = "SELECT r.*, rt.type_name, rt.description, rt.rate_per_night, rt.max_occupancy, rt.amenities " +
                     "FROM rooms r JOIN room_types rt ON r.room_type_id = rt.room_type_id " +
                     "WHERE r.room_number = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, roomNumber);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToRoomWithType(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get room: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * Get all rooms
     */
    public List<Room> getAllRooms() {
        List<Room> rooms = new ArrayList<>();
        String sql = "SELECT r.*, rt.type_name, rt.description, rt.rate_per_night, rt.max_occupancy, rt.amenities " +
                     "FROM rooms r JOIN room_types rt ON r.room_type_id = rt.room_type_id " +
                     "ORDER BY r.room_number";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                rooms.add(mapResultSetToRoomWithType(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get rooms: " + e.getMessage());
        }
        return rooms;
    }
    
    /**
     * Get available rooms
     */
    public List<Room> getAvailableRooms() {
        List<Room> rooms = new ArrayList<>();
        String sql = "SELECT r.*, rt.type_name, rt.description, rt.rate_per_night, rt.max_occupancy, rt.amenities " +
                     "FROM rooms r JOIN room_types rt ON r.room_type_id = rt.room_type_id " +
                     "WHERE r.status = 'AVAILABLE' ORDER BY r.room_number";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                rooms.add(mapResultSetToRoomWithType(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get available rooms: " + e.getMessage());
        }
        return rooms;
    }
    
    /**
     * Get available rooms by type
     */
    public List<Room> getAvailableRoomsByType(int roomTypeId) {
        List<Room> rooms = new ArrayList<>();
        String sql = "SELECT r.*, rt.type_name, rt.description, rt.rate_per_night, rt.max_occupancy, rt.amenities " +
                     "FROM rooms r JOIN room_types rt ON r.room_type_id = rt.room_type_id " +
                     "WHERE r.status = 'AVAILABLE' AND r.room_type_id = ? ORDER BY r.room_number";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, roomTypeId);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                rooms.add(mapResultSetToRoomWithType(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get available rooms: " + e.getMessage());
        }
        return rooms;
    }
    
    /**
     * Get available rooms for date range
     */
    public List<Room> getAvailableRoomsForDates(Date checkIn, Date checkOut) {
        List<Room> rooms = new ArrayList<>();
        String sql = "SELECT r.*, rt.type_name, rt.description, rt.rate_per_night, rt.max_occupancy, rt.amenities " +
                     "FROM rooms r JOIN room_types rt ON r.room_type_id = rt.room_type_id " +
                     "WHERE r.status = 'AVAILABLE' AND r.room_id NOT IN (" +
                     "  SELECT room_id FROM reservations " +
                     "  WHERE status IN ('CONFIRMED', 'CHECKED_IN') " +
                     "  AND NOT (check_out_date <= ? OR check_in_date >= ?)" +
                     ") ORDER BY r.room_number";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setDate(1, checkIn);
            pstmt.setDate(2, checkOut);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                rooms.add(mapResultSetToRoomWithType(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get available rooms: " + e.getMessage());
        }
        return rooms;
    }
    
    /**
     * Update room status
     */
    public boolean updateRoomStatus(int roomId, RoomStatus status) {
        String sql = "UPDATE rooms SET status = ? WHERE room_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, status.name());
            pstmt.setInt(2, roomId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to update room status: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Add new room
     */
    public boolean addRoom(Room room) {
        String sql = "INSERT INTO rooms (room_number, room_type_id, floor_number, status, notes) " +
                     "VALUES (?, ?, ?, ?, ?)";
        try (PreparedStatement pstmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setString(1, room.getRoomNumber());
            pstmt.setInt(2, room.getRoomTypeId());
            pstmt.setInt(3, room.getFloorNumber());
            pstmt.setString(4, room.getStatus().name());
            pstmt.setString(5, room.getNotes());
            
            int affectedRows = pstmt.executeUpdate();
            if (affectedRows > 0) {
                ResultSet generatedKeys = pstmt.getGeneratedKeys();
                if (generatedKeys.next()) {
                    room.setRoomId(generatedKeys.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to add room: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Delete room (only if no active reservations)
     */
    public boolean deleteRoom(int roomId) {
        // Check if any active reservations exist for this room
        String checkSql = "SELECT COUNT(*) FROM reservations WHERE room_id = ? AND status IN ('CONFIRMED', 'CHECKED_IN')";
        try (PreparedStatement pstmt = connection.prepareStatement(checkSql)) {
            pstmt.setInt(1, roomId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next() && rs.getInt(1) > 0) {
                return false; // Cannot delete, active reservations exist
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to check reservations: " + e.getMessage());
            return false;
        }
        
        String sql = "DELETE FROM rooms WHERE room_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, roomId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to delete room: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Get room count by status
     */
    public int getRoomCountByStatus(RoomStatus status) {
        String sql = "SELECT COUNT(*) FROM rooms WHERE status = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, status.name());
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get room count: " + e.getMessage());
        }
        return 0;
    }
    
    /**
     * Get total room count
     */
    public int getTotalRoomCount() {
        String sql = "SELECT COUNT(*) FROM rooms";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get room count: " + e.getMessage());
        }
        return 0;
    }
    
    // ==================== MAPPING METHODS ====================
    
    /**
     * Map ResultSet to RoomType object
     */
    private RoomType mapResultSetToRoomType(ResultSet rs) throws SQLException {
        RoomType roomType = new RoomType();
        roomType.setRoomTypeId(rs.getInt("room_type_id"));
        roomType.setTypeName(rs.getString("type_name"));
        roomType.setDescription(rs.getString("description"));
        roomType.setRatePerNight(rs.getBigDecimal("rate_per_night"));
        roomType.setMaxOccupancy(rs.getInt("max_occupancy"));
        roomType.setAmenities(rs.getString("amenities"));
        roomType.setStatus(RoomTypeStatus.valueOf(rs.getString("status")));
        roomType.setCreatedAt(rs.getTimestamp("created_at"));
        return roomType;
    }
    
    /**
     * Map ResultSet to Room object with RoomType
     */
    private Room mapResultSetToRoomWithType(ResultSet rs) throws SQLException {
        Room room = new Room();
        room.setRoomId(rs.getInt("room_id"));
        room.setRoomNumber(rs.getString("room_number"));
        room.setRoomTypeId(rs.getInt("room_type_id"));
        room.setFloorNumber(rs.getInt("floor_number"));
        room.setStatus(RoomStatus.valueOf(rs.getString("status")));
        room.setNotes(rs.getString("notes"));
        room.setCreatedAt(rs.getTimestamp("created_at"));
        
        // Set RoomType
        RoomType roomType = new RoomType();
        roomType.setRoomTypeId(rs.getInt("room_type_id"));
        roomType.setTypeName(rs.getString("type_name"));
        roomType.setDescription(rs.getString("description"));
        roomType.setRatePerNight(rs.getBigDecimal("rate_per_night"));
        roomType.setMaxOccupancy(rs.getInt("max_occupancy"));
        roomType.setAmenities(rs.getString("amenities"));
        room.setRoomType(roomType);
        
        return room;
    }
}
