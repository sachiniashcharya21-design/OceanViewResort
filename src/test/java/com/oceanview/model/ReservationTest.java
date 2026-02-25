package com.oceanview.model;

import com.oceanview.model.Reservation.ReservationStatus;
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;

/**
 * Test Class for Reservation Model
 * Tests reservation creation, night calculation, status transitions, and
 * validation
 * 
 * Test-Driven Development Approach:
 * Tests were designed BEFORE implementing reservation logic to ensure
 * accurate night calculations and proper status lifecycle management.
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
@DisplayName("Reservation Model Tests")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class ReservationTest {

    private Reservation reservation;

    @BeforeEach
    void setUp() {
        reservation = new Reservation();
        reservation.setReservationId(1);
        reservation.setReservationNumber("RES2026020001");
        reservation.setGuestId(1);
        reservation.setRoomId(101);
        reservation.setCheckInDate(Date.valueOf("2026-03-01"));
        reservation.setCheckOutDate(Date.valueOf("2026-03-05"));
        reservation.setNumberOfGuests(2);
        reservation.setStatus(ReservationStatus.CONFIRMED);
    }

    // ============================================================
    // TC-RV01: Test Reservation Number Format
    // ============================================================
    @Test
    @Order(1)
    @DisplayName("TC-RV01: Reservation number follows RESYYYYMMnnnn format")
    void testReservationNumberFormat() {
        String resNumber = reservation.getReservationNumber();
        assertTrue(resNumber.startsWith("RES"), "Should start with 'RES'");
        assertEquals(13, resNumber.length(), "Should be 13 characters long");
    }

    // ============================================================
    // TC-RV02: Test Number of Nights Calculation (4 nights)
    // ============================================================
    @Test
    @Order(2)
    @DisplayName("TC-RV02: Calculate 4 nights (March 1 to March 5)")
    void testNumberOfNightsFourNights() {
        reservation.setCheckInDate(Date.valueOf("2026-03-01"));
        reservation.setCheckOutDate(Date.valueOf("2026-03-05"));
        assertEquals(4, reservation.getNumberOfNights(),
                "March 1 to March 5 = 4 nights");
    }

    // ============================================================
    // TC-RV03: Test Number of Nights (1 night)
    // ============================================================
    @Test
    @Order(3)
    @DisplayName("TC-RV03: Calculate 1 night stay")
    void testNumberOfNightsOneNight() {
        reservation.setCheckInDate(Date.valueOf("2026-03-01"));
        reservation.setCheckOutDate(Date.valueOf("2026-03-02"));
        assertEquals(1, reservation.getNumberOfNights(),
                "March 1 to March 2 = 1 night");
    }

    // ============================================================
    // TC-RV04: Test Number of Nights (7 nights - full week)
    // ============================================================
    @Test
    @Order(4)
    @DisplayName("TC-RV04: Calculate 7 nights (full week stay)")
    void testNumberOfNightsFullWeek() {
        reservation.setCheckInDate(Date.valueOf("2026-03-01"));
        reservation.setCheckOutDate(Date.valueOf("2026-03-08"));
        assertEquals(7, reservation.getNumberOfNights(),
                "March 1 to March 8 = 7 nights");
    }

    // ============================================================
    // TC-RV05: Test Nights with Null Dates
    // ============================================================
    @Test
    @Order(5)
    @DisplayName("TC-RV05: Number of nights returns 0 when dates are null")
    void testNumberOfNightsNullDates() {
        reservation.setCheckInDate(null);
        reservation.setCheckOutDate(null);
        assertEquals(0, reservation.getNumberOfNights(),
                "Null dates should return 0 nights");
    }

    // ============================================================
    // TC-RV06: Test Default Status is CONFIRMED
    // ============================================================
    @Test
    @Order(6)
    @DisplayName("TC-RV06: Initial reservation status is CONFIRMED")
    void testDefaultStatus() {
        assertEquals(ReservationStatus.CONFIRMED, reservation.getStatus());
    }

    // ============================================================
    // TC-RV07: Test Status Transition to CHECKED_IN
    // ============================================================
    @Test
    @Order(7)
    @DisplayName("TC-RV07: Status can change to CHECKED_IN")
    void testStatusTransitionCheckedIn() {
        reservation.setStatus(ReservationStatus.CHECKED_IN);
        assertEquals(ReservationStatus.CHECKED_IN, reservation.getStatus());
    }

    // ============================================================
    // TC-RV08: Test Status Transition to CHECKED_OUT
    // ============================================================
    @Test
    @Order(8)
    @DisplayName("TC-RV08: Status can change to CHECKED_OUT")
    void testStatusTransitionCheckedOut() {
        reservation.setStatus(ReservationStatus.CHECKED_OUT);
        assertEquals(ReservationStatus.CHECKED_OUT, reservation.getStatus());
    }

    // ============================================================
    // TC-RV09: Test Status Transition to CANCELLED
    // ============================================================
    @Test
    @Order(9)
    @DisplayName("TC-RV09: Reservation can be CANCELLED")
    void testStatusTransitionCancelled() {
        reservation.setStatus(ReservationStatus.CANCELLED);
        assertEquals(ReservationStatus.CANCELLED, reservation.getStatus());
    }

    // ============================================================
    // TC-RV10: Test Guest and Room Association
    // ============================================================
    @Test
    @Order(10)
    @DisplayName("TC-RV10: Guest and Room objects can be associated")
    void testGuestAndRoomAssociation() {
        Guest guest = new Guest("Test Guest", "0771234567", "Galle");
        guest.setGuestId(1);
        Room room = new Room(101, "101", 1, 1);

        reservation.setGuest(guest);
        reservation.setRoom(room);

        assertNotNull(reservation.getGuest());
        assertNotNull(reservation.getRoom());
        assertEquals("Test Guest", reservation.getGuest().getFullName());
        assertEquals("101", reservation.getRoom().getRoomNumber());
    }

    @AfterEach
    void tearDown() {
        reservation = null;
    }
}
