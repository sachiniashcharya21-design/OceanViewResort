package com.oceanview.model;

import java.math.BigDecimal;
import java.sql.Timestamp;

/**
 * Bill Model Class
 * Represents billing information for reservations
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
public class Bill {
    
    private int billId;
    private String billNumber;
    private int reservationId;
    private Reservation reservation; // Associated Reservation object
    private int numberOfNights;
    private BigDecimal roomRate;
    private BigDecimal roomTotal;
    private BigDecimal serviceCharge;
    private BigDecimal taxAmount;
    private BigDecimal discount;
    private BigDecimal totalAmount;
    private PaymentStatus paymentStatus;
    private PaymentMethod paymentMethod;
    private int generatedBy;
    private User generatedByUser; // Associated User object
    private Timestamp generatedAt;
    private Timestamp paidAt;
    
    /**
     * Payment Status Enum
     */
    public enum PaymentStatus {
        PENDING, PAID, PARTIAL
    }
    
    /**
     * Payment Method Enum
     */
    public enum PaymentMethod {
        CASH, CARD, BANK_TRANSFER, ONLINE
    }
    
    // Default Constructor
    public Bill() {
        this.serviceCharge = BigDecimal.ZERO;
        this.taxAmount = BigDecimal.ZERO;
        this.discount = BigDecimal.ZERO;
        this.paymentStatus = PaymentStatus.PENDING;
        this.paymentMethod = PaymentMethod.CASH;
    }
    
    // Parameterized Constructor
    public Bill(String billNumber, int reservationId, int numberOfNights, BigDecimal roomRate) {
        this();
        this.billNumber = billNumber;
        this.reservationId = reservationId;
        this.numberOfNights = numberOfNights;
        this.roomRate = roomRate;
        calculateTotals();
    }
    
    // Getters and Setters
    public int getBillId() {
        return billId;
    }
    
    public void setBillId(int billId) {
        this.billId = billId;
    }
    
    public String getBillNumber() {
        return billNumber;
    }
    
    public void setBillNumber(String billNumber) {
        this.billNumber = billNumber;
    }
    
    public int getReservationId() {
        return reservationId;
    }
    
    public void setReservationId(int reservationId) {
        this.reservationId = reservationId;
    }
    
    public Reservation getReservation() {
        return reservation;
    }
    
    public void setReservation(Reservation reservation) {
        this.reservation = reservation;
    }
    
    public int getNumberOfNights() {
        return numberOfNights;
    }
    
    public void setNumberOfNights(int numberOfNights) {
        this.numberOfNights = numberOfNights;
    }
    
    public BigDecimal getRoomRate() {
        return roomRate;
    }
    
    public void setRoomRate(BigDecimal roomRate) {
        this.roomRate = roomRate;
    }
    
    public BigDecimal getRoomTotal() {
        return roomTotal;
    }
    
    public void setRoomTotal(BigDecimal roomTotal) {
        this.roomTotal = roomTotal;
    }
    
    public BigDecimal getServiceCharge() {
        return serviceCharge;
    }
    
    public void setServiceCharge(BigDecimal serviceCharge) {
        this.serviceCharge = serviceCharge;
    }
    
    public BigDecimal getTaxAmount() {
        return taxAmount;
    }
    
    public void setTaxAmount(BigDecimal taxAmount) {
        this.taxAmount = taxAmount;
    }
    
    public BigDecimal getDiscount() {
        return discount;
    }
    
    public void setDiscount(BigDecimal discount) {
        this.discount = discount;
    }
    
    public BigDecimal getTotalAmount() {
        return totalAmount;
    }
    
    public void setTotalAmount(BigDecimal totalAmount) {
        this.totalAmount = totalAmount;
    }
    
    public PaymentStatus getPaymentStatus() {
        return paymentStatus;
    }
    
    public void setPaymentStatus(PaymentStatus paymentStatus) {
        this.paymentStatus = paymentStatus;
    }
    
    public PaymentMethod getPaymentMethod() {
        return paymentMethod;
    }
    
    public void setPaymentMethod(PaymentMethod paymentMethod) {
        this.paymentMethod = paymentMethod;
    }
    
    public int getGeneratedBy() {
        return generatedBy;
    }
    
    public void setGeneratedBy(int generatedBy) {
        this.generatedBy = generatedBy;
    }
    
    public User getGeneratedByUser() {
        return generatedByUser;
    }
    
    public void setGeneratedByUser(User generatedByUser) {
        this.generatedByUser = generatedByUser;
    }
    
    public Timestamp getGeneratedAt() {
        return generatedAt;
    }
    
    public void setGeneratedAt(Timestamp generatedAt) {
        this.generatedAt = generatedAt;
    }
    
    public Timestamp getPaidAt() {
        return paidAt;
    }
    
    public void setPaidAt(Timestamp paidAt) {
        this.paidAt = paidAt;
    }
    
    /**
     * Calculate totals with service charge (10%) and tax (5%)
     */
    public void calculateTotals() {
        // Room total = rate per night * number of nights
        this.roomTotal = roomRate.multiply(BigDecimal.valueOf(numberOfNights));
        
        // Service charge = 10% of room total
        this.serviceCharge = roomTotal.multiply(BigDecimal.valueOf(0.10));
        
        // Tax = 5% of (room total + service charge)
        BigDecimal subtotal = roomTotal.add(serviceCharge);
        this.taxAmount = subtotal.multiply(BigDecimal.valueOf(0.05));
        
        // Total = room total + service charge + tax - discount
        this.totalAmount = subtotal.add(taxAmount).subtract(discount != null ? discount : BigDecimal.ZERO);
    }
    
    /**
     * Apply discount
     */
    public void applyDiscount(BigDecimal discountAmount) {
        this.discount = discountAmount;
        calculateTotals();
    }
    
    @Override
    public String toString() {
        return String.format("Bill %s - Rs. %,.2f - %s", billNumber, totalAmount, paymentStatus);
    }
    
    /**
     * Print the bill in formatted manner
     */
    public void printBill() {
        System.out.println("\n");
        System.out.println("╔═══════════════════════════════════════════════════════════════════════════╗");
        System.out.println("║                                                                           ║");
        System.out.println("║                   ██████╗  ██████╗███████╗ █████╗ ███╗   ██╗              ║");
        System.out.println("║                  ██╔═══██╗██╔════╝██╔════╝██╔══██╗████╗  ██║              ║");
        System.out.println("║                  ██║   ██║██║     █████╗  ███████║██╔██╗ ██║              ║");
        System.out.println("║                  ██║   ██║██║     ██╔══╝  ██╔══██║██║╚██╗██║              ║");
        System.out.println("║                  ╚██████╔╝╚██████╗███████╗██║  ██║██║ ╚████║              ║");
        System.out.println("║                   ╚═════╝  ╚═════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝              ║");
        System.out.println("║                                                                           ║");
        System.out.println("║                  ██╗   ██╗██╗███████╗██╗    ██╗                            ║");
        System.out.println("║                  ██║   ██║██║██╔════╝██║    ██║                            ║");
        System.out.println("║                  ██║   ██║██║█████╗  ██║ █╗ ██║                            ║");
        System.out.println("║                  ╚██╗ ██╔╝██║██╔══╝  ██║███╗██║                            ║");
        System.out.println("║                   ╚████╔╝ ██║███████╗╚███╔███╔╝                            ║");
        System.out.println("║                    ╚═══╝  ╚═╝╚══════╝ ╚══╝╚══╝                             ║");
        System.out.println("║                                                                           ║");
        System.out.println("║                  R E S O R T   -   G A L L E                              ║");
        System.out.println("║                                                                           ║");
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.println("║                            TAX INVOICE / BILL                             ║");
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.printf("║  Bill Number      : %-53s ║%n", billNumber);
        System.out.printf("║  Date             : %-53s ║%n", generatedAt != null ? generatedAt.toString().substring(0, 19) : "N/A");
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        
        if (reservation != null) {
            System.out.printf("║  Reservation No   : %-53s ║%n", reservation.getReservationNumber());
            if (reservation.getGuest() != null) {
                System.out.printf("║  Guest Name       : %-53s ║%n", reservation.getGuest().getFullName());
                System.out.printf("║  Contact          : %-53s ║%n", reservation.getGuest().getPhone());
            }
            if (reservation.getRoom() != null) {
                System.out.printf("║  Room Number      : %-53s ║%n", reservation.getRoom().getRoomNumber());
                if (reservation.getRoom().getRoomType() != null) {
                    System.out.printf("║  Room Type        : %-53s ║%n", reservation.getRoom().getRoomType().getTypeName());
                }
            }
            System.out.printf("║  Check-in         : %-53s ║%n", reservation.getCheckInDate());
            System.out.printf("║  Check-out        : %-53s ║%n", reservation.getCheckOutDate());
        }
        
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.println("║                             CHARGE DETAILS                                ║");
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.printf("║  Room Rate (per night)              : Rs. %,26.2f     ║%n", roomRate);
        System.out.printf("║  Number of Nights                   : %,30d     ║%n", numberOfNights);
        System.out.println("║  ─────────────────────────────────────────────────────────────────────── ║");
        System.out.printf("║  Room Total                         : Rs. %,26.2f     ║%n", roomTotal);
        System.out.printf("║  Service Charge (10%%)               : Rs. %,26.2f     ║%n", serviceCharge);
        System.out.printf("║  Tax (5%%)                           : Rs. %,26.2f     ║%n", taxAmount);
        if (discount != null && discount.compareTo(BigDecimal.ZERO) > 0) {
            System.out.printf("║  Discount                           : Rs. %,26.2f -   ║%n", discount);
        }
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.printf("║  TOTAL AMOUNT                       : Rs. %,26.2f     ║%n", totalAmount);
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.printf("║  Payment Status   : %-53s ║%n", paymentStatus);
        System.out.printf("║  Payment Method   : %-53s ║%n", paymentMethod);
        System.out.println("╠═══════════════════════════════════════════════════════════════════════════╣");
        System.out.println("║                                                                           ║");
        System.out.println("║            Thank you for staying at Ocean View Resort!                    ║");
        System.out.println("║                   We hope to see you again soon.                          ║");
        System.out.println("║                                                                           ║");
        System.out.println("║          Ocean View Resort, Beach Road, Galle, Sri Lanka                  ║");
        System.out.println("║          Tel: +94 91 234 5678 | Email: info@oceanviewresort.lk            ║");
        System.out.println("║                                                                           ║");
        System.out.println("╚═══════════════════════════════════════════════════════════════════════════╝");
    }
}
