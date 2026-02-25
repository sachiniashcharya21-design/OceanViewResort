package com.oceanview.dao;

import com.oceanview.model.*;
import com.oceanview.model.Bill.PaymentMethod;
import com.oceanview.model.Bill.PaymentStatus;
import com.oceanview.util.DatabaseConnection;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Bill Data Access Object
 * Handles all database operations related to billing
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class BillDAO {
    
    private Connection connection;
    private ReservationDAO reservationDAO;
    private UserDAO userDAO;
    
    /**
     * Constructor - initializes database connection
     */
    public BillDAO() throws SQLException {
        this.connection = DatabaseConnection.getInstance().getConnection();
        this.reservationDAO = new ReservationDAO();
        this.userDAO = new UserDAO();
    }
    
    /**
     * Generate unique bill number
     * Format: BILLYYYYMMnnnn (e.g., BILL2026020001)
     */
    public String generateBillNumber() {
        String prefix = "BILL" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
        String sql = "SELECT MAX(bill_number) FROM bills WHERE bill_number LIKE ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, prefix + "%");
            ResultSet rs = pstmt.executeQuery();
            if (rs.next() && rs.getString(1) != null) {
                String lastNumber = rs.getString(1);
                int sequence = Integer.parseInt(lastNumber.substring(10)) + 1;
                return prefix + String.format("%04d", sequence);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to generate bill number: " + e.getMessage());
        }
        return prefix + "0001";
    }
    
    /**
     * Generate bill for reservation
     */
    public Bill generateBill(int reservationId, int generatedBy) {
        Reservation reservation = reservationDAO.getReservationById(reservationId);
        if (reservation == null) {
            System.err.println("[ERROR] Reservation not found");
            return null;
        }
        
        // Check if bill already exists
        Bill existingBill = getBillByReservationId(reservationId);
        if (existingBill != null) {
            return existingBill;
        }
        
        // Create new bill
        Bill bill = new Bill();
        bill.setBillNumber(generateBillNumber());
        bill.setReservationId(reservationId);
        bill.setReservation(reservation);
        bill.setNumberOfNights(reservation.getNumberOfNights());
        
        if (reservation.getRoom() != null && reservation.getRoom().getRoomType() != null) {
            bill.setRoomRate(reservation.getRoom().getRoomType().getRatePerNight());
        } else {
            bill.setRoomRate(BigDecimal.ZERO);
        }
        
        bill.setDiscount(BigDecimal.ZERO);
        bill.calculateTotals();
        bill.setGeneratedBy(generatedBy);
        bill.setPaymentStatus(PaymentStatus.PENDING);
        bill.setPaymentMethod(PaymentMethod.CASH);
        
        // Save to database
        if (saveBill(bill)) {
            return bill;
        }
        return null;
    }
    
    /**
     * Save bill to database
     */
    public boolean saveBill(Bill bill) {
        String sql = "INSERT INTO bills (bill_number, reservation_id, number_of_nights, room_rate, " +
                     "room_total, service_charge, tax_amount, discount, total_amount, " +
                     "payment_status, payment_method, generated_by) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement pstmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setString(1, bill.getBillNumber());
            pstmt.setInt(2, bill.getReservationId());
            pstmt.setInt(3, bill.getNumberOfNights());
            pstmt.setBigDecimal(4, bill.getRoomRate());
            pstmt.setBigDecimal(5, bill.getRoomTotal());
            pstmt.setBigDecimal(6, bill.getServiceCharge());
            pstmt.setBigDecimal(7, bill.getTaxAmount());
            pstmt.setBigDecimal(8, bill.getDiscount());
            pstmt.setBigDecimal(9, bill.getTotalAmount());
            pstmt.setString(10, bill.getPaymentStatus().name());
            pstmt.setString(11, bill.getPaymentMethod().name());
            pstmt.setInt(12, bill.getGeneratedBy());
            
            int affectedRows = pstmt.executeUpdate();
            if (affectedRows > 0) {
                ResultSet generatedKeys = pstmt.getGeneratedKeys();
                if (generatedKeys.next()) {
                    bill.setBillId(generatedKeys.getInt(1));
                }
                // Get generated timestamp
                bill.setGeneratedAt(new Timestamp(System.currentTimeMillis()));
                return true;
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to save bill: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Get bill by ID
     */
    public Bill getBillById(int billId) {
        String sql = "SELECT * FROM bills WHERE bill_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, billId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToBillWithDetails(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get bill: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * Get bill by bill number
     */
    public Bill getBillByNumber(String billNumber) {
        String sql = "SELECT * FROM bills WHERE bill_number = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, billNumber);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToBillWithDetails(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get bill: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * Get bill by reservation ID
     */
    public Bill getBillByReservationId(int reservationId) {
        String sql = "SELECT * FROM bills WHERE reservation_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setInt(1, reservationId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToBillWithDetails(rs);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get bill: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * Get all bills
     */
    public List<Bill> getAllBills() {
        List<Bill> bills = new ArrayList<>();
        String sql = "SELECT * FROM bills ORDER BY generated_at DESC";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                bills.add(mapResultSetToBillWithDetails(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get bills: " + e.getMessage());
        }
        return bills;
    }
    
    /**
     * Get bills by payment status
     */
    public List<Bill> getBillsByPaymentStatus(PaymentStatus status) {
        List<Bill> bills = new ArrayList<>();
        String sql = "SELECT * FROM bills WHERE payment_status = ? ORDER BY generated_at DESC";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, status.name());
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                bills.add(mapResultSetToBillWithDetails(rs));
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get bills: " + e.getMessage());
        }
        return bills;
    }
    
    /**
     * Update payment status
     */
    public boolean updatePaymentStatus(int billId, PaymentStatus status, PaymentMethod method) {
        String sql = "UPDATE bills SET payment_status = ?, payment_method = ?, " +
                     "paid_at = CASE WHEN ? = 'PAID' THEN NOW() ELSE paid_at END " +
                     "WHERE bill_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, status.name());
            pstmt.setString(2, method.name());
            pstmt.setString(3, status.name());
            pstmt.setInt(4, billId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to update payment status: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Apply discount to bill
     */
    public boolean applyDiscount(int billId, BigDecimal discountAmount) {
        // First get the bill to recalculate
        Bill bill = getBillById(billId);
        if (bill == null) return false;
        
        bill.setDiscount(discountAmount);
        bill.calculateTotals();
        
        String sql = "UPDATE bills SET discount = ?, total_amount = ? WHERE bill_id = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setBigDecimal(1, discountAmount);
            pstmt.setBigDecimal(2, bill.getTotalAmount());
            pstmt.setInt(3, billId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to apply discount: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Get total revenue for a date range
     */
    public BigDecimal getTotalRevenue(Date startDate, Date endDate) {
        String sql = "SELECT COALESCE(SUM(total_amount), 0) FROM bills " +
                     "WHERE payment_status = 'PAID' AND paid_at BETWEEN ? AND ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setDate(1, startDate);
            pstmt.setDate(2, endDate);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getBigDecimal(1);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get revenue: " + e.getMessage());
        }
        return BigDecimal.ZERO;
    }
    
    /**
     * Get total pending amount
     */
    public BigDecimal getTotalPendingAmount() {
        String sql = "SELECT COALESCE(SUM(total_amount), 0) FROM bills WHERE payment_status = 'PENDING'";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                return rs.getBigDecimal(1);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get pending amount: " + e.getMessage());
        }
        return BigDecimal.ZERO;
    }
    
    /**
     * Get bill count by status
     */
    public int getBillCountByStatus(PaymentStatus status) {
        String sql = "SELECT COUNT(*) FROM bills WHERE payment_status = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setString(1, status.name());
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            System.err.println("[ERROR] Failed to get bill count: " + e.getMessage());
        }
        return 0;
    }
    
    /**
     * Get pending bills
     */
    public List<Bill> getPendingBills() {
        return getBillsByPaymentStatus(PaymentStatus.PENDING);
    }
    
    /**
     * Map ResultSet to Bill with all related details
     */
    private Bill mapResultSetToBillWithDetails(ResultSet rs) throws SQLException {
        Bill bill = new Bill();
        bill.setBillId(rs.getInt("bill_id"));
        bill.setBillNumber(rs.getString("bill_number"));
        bill.setReservationId(rs.getInt("reservation_id"));
        bill.setNumberOfNights(rs.getInt("number_of_nights"));
        bill.setRoomRate(rs.getBigDecimal("room_rate"));
        bill.setRoomTotal(rs.getBigDecimal("room_total"));
        bill.setServiceCharge(rs.getBigDecimal("service_charge"));
        bill.setTaxAmount(rs.getBigDecimal("tax_amount"));
        bill.setDiscount(rs.getBigDecimal("discount"));
        bill.setTotalAmount(rs.getBigDecimal("total_amount"));
        bill.setPaymentStatus(PaymentStatus.valueOf(rs.getString("payment_status")));
        bill.setPaymentMethod(PaymentMethod.valueOf(rs.getString("payment_method")));
        bill.setGeneratedBy(rs.getInt("generated_by"));
        bill.setGeneratedAt(rs.getTimestamp("generated_at"));
        bill.setPaidAt(rs.getTimestamp("paid_at"));
        
        // Load related objects
        bill.setReservation(reservationDAO.getReservationById(bill.getReservationId()));
        if (bill.getGeneratedBy() > 0) {
            bill.setGeneratedByUser(userDAO.getUserById(bill.getGeneratedBy()));
        }
        
        return bill;
    }
}
