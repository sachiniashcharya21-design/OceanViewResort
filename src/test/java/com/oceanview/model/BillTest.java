package com.oceanview.model;

import com.oceanview.model.Bill.PaymentStatus;
import com.oceanview.model.Bill.PaymentMethod;
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Test Class for Bill Model
 * Tests billing calculations, payment management, and discount application
 * 
 * Test-Driven Development Approach:
 * Tests for billing calculations were written FIRST to define the exact
 * expected values for room total, service charge (10%), tax (5%), and
 * discounts. This ensures financial accuracy before implementation.
 * 
 * Billing Formula:
 * Room Total = Rate Per Night × Number of Nights
 * Service Charge = 10% of Room Total
 * Tax Amount = 5% of (Room Total + Service Charge)
 * Grand Total = Room Total + Service Charge + Tax − Discount
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
@DisplayName("Bill Model Tests - Financial Calculations")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class BillTest {

    private Bill bill;

    @BeforeEach
    void setUp() {
        bill = new Bill();
        bill.setBillId(1);
        bill.setBillNumber("BILL2026020001");
        bill.setReservationId(1);
        bill.setNumberOfNights(3);
        bill.setRoomRate(new BigDecimal("25000.00"));
        bill.setDiscount(BigDecimal.ZERO);
        bill.setPaymentStatus(PaymentStatus.PENDING);
    }

    // ============================================================
    // TC-B01: Test Bill Number Format
    // ============================================================
    @Test
    @Order(1)
    @DisplayName("TC-B01: Bill number follows BILLYYYYMMnnnn format")
    void testBillNumberFormat() {
        String billNumber = bill.getBillNumber();
        assertTrue(billNumber.startsWith("BILL"), "Should start with 'BILL'");
        assertEquals(14, billNumber.length(), "Should be 14 characters long");
    }

    // ============================================================
    // TC-B02: Test Room Total Calculation (3 nights × LKR 25,000)
    // ============================================================
    @Test
    @Order(2)
    @DisplayName("TC-B02: Room total = 3 nights × LKR 25,000 = LKR 75,000")
    void testRoomTotalCalculation() {
        bill.calculateTotals();
        BigDecimal expectedRoomTotal = new BigDecimal("75000.00");
        assertEquals(0, expectedRoomTotal.compareTo(bill.getRoomTotal()),
                "Room total should be 75,000.00 (3 × 25,000)");
    }

    // ============================================================
    // TC-B03: Test Service Charge (10% of Room Total)
    // ============================================================
    @Test
    @Order(3)
    @DisplayName("TC-B03: Service charge = 10% of LKR 75,000 = LKR 7,500")
    void testServiceChargeCalculation() {
        bill.calculateTotals();
        BigDecimal expectedServiceCharge = new BigDecimal("7500.00");
        assertEquals(0, expectedServiceCharge.compareTo(bill.getServiceCharge()),
                "Service charge should be 7,500.00 (10% of 75,000)");
    }

    // ============================================================
    // TC-B04: Test Tax Amount (5% of Room Total + Service Charge)
    // ============================================================
    @Test
    @Order(4)
    @DisplayName("TC-B04: Tax = 5% of (75,000 + 7,500) = LKR 4,125")
    void testTaxCalculation() {
        bill.calculateTotals();
        // Subtotal = 75,000 + 7,500 = 82,500
        // Tax = 5% of 82,500 = 4,125
        BigDecimal expectedTax = new BigDecimal("4125.00");
        assertEquals(0, expectedTax.compareTo(bill.getTaxAmount()),
                "Tax should be 4,125.00 (5% of 82,500)");
    }

    // ============================================================
    // TC-B05: Test Grand Total Without Discount
    // ============================================================
    @Test
    @Order(5)
    @DisplayName("TC-B05: Grand total = 75,000 + 7,500 + 4,125 = LKR 86,625")
    void testGrandTotalWithoutDiscount() {
        bill.calculateTotals();
        // Grand Total = 75,000 + 7,500 + 4,125 - 0 = 86,625
        BigDecimal expectedTotal = new BigDecimal("86625.00");
        assertEquals(0, expectedTotal.compareTo(bill.getTotalAmount()),
                "Grand total should be 86,625.00");
    }

    // ============================================================
    // TC-B06: Test Grand Total With Discount (LKR 5,000)
    // ============================================================
    @Test
    @Order(6)
    @DisplayName("TC-B06: Grand total with LKR 5,000 discount = LKR 81,625")
    void testGrandTotalWithDiscount() {
        bill.setDiscount(new BigDecimal("5000.00"));
        bill.calculateTotals();
        // Grand Total = 75,000 + 7,500 + 4,125 - 5,000 = 81,625
        BigDecimal expectedTotal = new BigDecimal("81625.00");
        assertEquals(0, expectedTotal.compareTo(bill.getTotalAmount()),
                "Grand total with discount should be 81,625.00");
    }

    // ============================================================
    // TC-B07: Test Single Night Bill (1 night × LKR 15,000 Standard)
    // ============================================================
    @Test
    @Order(7)
    @DisplayName("TC-B07: Single night Standard = LKR 17,325 total")
    void testSingleNightBill() {
        bill.setNumberOfNights(1);
        bill.setRoomRate(new BigDecimal("15000.00"));
        bill.setDiscount(BigDecimal.ZERO);
        bill.calculateTotals();
        // Room total = 15,000
        // Service = 1,500
        // Tax = 5% of 16,500 = 825
        // Total = 15,000 + 1,500 + 825 = 17,325
        assertEquals(0, new BigDecimal("15000.00").compareTo(bill.getRoomTotal()));
        assertEquals(0, new BigDecimal("1500.00").compareTo(bill.getServiceCharge()));
        assertEquals(0, new BigDecimal("825.00").compareTo(bill.getTaxAmount()));
        assertEquals(0, new BigDecimal("17325.00").compareTo(bill.getTotalAmount()));
    }

    // ============================================================
    // TC-B08: Test Suite Room Bill (5 nights × LKR 45,000)
    // ============================================================
    @Test
    @Order(8)
    @DisplayName("TC-B08: Suite 5 nights = LKR 259,875 total")
    void testSuiteRoomBill() {
        bill.setNumberOfNights(5);
        bill.setRoomRate(new BigDecimal("45000.00"));
        bill.setDiscount(BigDecimal.ZERO);
        bill.calculateTotals();
        // Room total = 225,000
        // Service = 22,500
        // Tax = 5% of 247,500 = 12,375
        // Total = 225,000 + 22,500 + 12,375 = 259,875
        assertEquals(0, new BigDecimal("225000.00").compareTo(bill.getRoomTotal()));
        assertEquals(0, new BigDecimal("22500.00").compareTo(bill.getServiceCharge()));
        assertEquals(0, new BigDecimal("12375.00").compareTo(bill.getTaxAmount()));
        assertEquals(0, new BigDecimal("259875.00").compareTo(bill.getTotalAmount()));
    }

    // ============================================================
    // TC-B09: Test Payment Status Default (PENDING)
    // ============================================================
    @Test
    @Order(9)
    @DisplayName("TC-B09: Default payment status is PENDING")
    void testDefaultPaymentStatus() {
        assertEquals(PaymentStatus.PENDING, bill.getPaymentStatus());
    }

    // ============================================================
    // TC-B10: Test Payment Status Change to PAID
    // ============================================================
    @Test
    @Order(10)
    @DisplayName("TC-B10: Payment status can change to PAID")
    void testPaymentStatusToPaid() {
        bill.setPaymentStatus(PaymentStatus.PAID);
        assertEquals(PaymentStatus.PAID, bill.getPaymentStatus());
    }

    // ============================================================
    // TC-B11: Test Payment Method Setting
    // ============================================================
    @Test
    @Order(11)
    @DisplayName("TC-B11: Payment method can be set to CASH")
    void testPaymentMethodCash() {
        bill.setPaymentMethod(PaymentMethod.CASH);
        assertEquals(PaymentMethod.CASH, bill.getPaymentMethod());
    }

    // ============================================================
    // TC-B12: Test Payment Method CARD
    // ============================================================
    @Test
    @Order(12)
    @DisplayName("TC-B12: Payment method can be set to CARD")
    void testPaymentMethodCard() {
        bill.setPaymentMethod(PaymentMethod.CARD);
        assertEquals(PaymentMethod.CARD, bill.getPaymentMethod());
    }

    // ============================================================
    // TC-B13: Test Apply Discount Method
    // ============================================================
    @Test
    @Order(13)
    @DisplayName("TC-B13: Apply discount of LKR 10,000 recalculates total")
    void testApplyDiscount() {
        bill.calculateTotals();
        BigDecimal totalBefore = bill.getTotalAmount();
        bill.applyDiscount(new BigDecimal("10000.00"));
        // After applying discount, recalculate
        BigDecimal expectedNewTotal = totalBefore.subtract(new BigDecimal("10000.00"));
        assertEquals(0, expectedNewTotal.compareTo(bill.getTotalAmount()),
                "Total should decrease by discount amount");
    }

    // ============================================================
    // TC-B14: Test Zero Night Edge Case
    // ============================================================
    @Test
    @Order(14)
    @DisplayName("TC-B14: Zero nights results in zero total")
    void testZeroNights() {
        bill.setNumberOfNights(0);
        bill.setDiscount(BigDecimal.ZERO);
        bill.calculateTotals();
        assertEquals(0, BigDecimal.ZERO.compareTo(bill.getRoomTotal()),
                "Zero nights should produce zero room total");
        assertEquals(0, BigDecimal.ZERO.compareTo(bill.getTotalAmount()),
                "Zero nights should produce zero total");
    }

    // ============================================================
    // TC-B15: Test Reservation Association
    // ============================================================
    @Test
    @Order(15)
    @DisplayName("TC-B15: Bill is correctly associated with Reservation")
    void testReservationAssociation() {
        Reservation reservation = new Reservation();
        reservation.setReservationId(1);
        reservation.setReservationNumber("RES2026020001");
        bill.setReservation(reservation);

        assertNotNull(bill.getReservation());
        assertEquals("RES2026020001", bill.getReservation().getReservationNumber());
    }

    @AfterEach
    void tearDown() {
        bill = null;
    }
}
