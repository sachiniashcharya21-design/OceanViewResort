package com.oceanview.model;

import com.oceanview.model.RoomType.RoomTypeStatus;
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

import java.math.BigDecimal;

/**
 * Test Class for RoomType Model
 * Tests room type creation, pricing, and occupancy management
 * 
 * Test-Driven Development Approach:
 * Tests were designed to validate pricing logic and room categorization
 * BEFORE implementation, ensuring accurate rate calculations.
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
@DisplayName("RoomType Model Tests")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class RoomTypeTest {

    private RoomType standardType;
    private RoomType deluxeType;
    private RoomType suiteType;

    @BeforeEach
    void setUp() {
        standardType = new RoomType(1, "Standard", new BigDecimal("15000.00"));
        deluxeType = new RoomType(2, "Deluxe", new BigDecimal("25000.00"));
        suiteType = new RoomType(3, "Suite", new BigDecimal("45000.00"));
    }

    // ============================================================
    // TC-RT01: Test Standard Room Type Creation
    // ============================================================
    @Test
    @Order(1)
    @DisplayName("TC-RT01: Standard room type created with correct rate")
    void testStandardRoomType() {
        assertEquals(1, standardType.getRoomTypeId());
        assertEquals("Standard", standardType.getTypeName());
        assertEquals(new BigDecimal("15000.00"), standardType.getRatePerNight());
    }

    // ============================================================
    // TC-RT02: Test Deluxe Room Type Rate
    // ============================================================
    @Test
    @Order(2)
    @DisplayName("TC-RT02: Deluxe room type has higher rate than Standard")
    void testDeluxeRoomTypeRate() {
        assertTrue(deluxeType.getRatePerNight().compareTo(standardType.getRatePerNight()) > 0,
                "Deluxe rate should be higher than Standard");
    }

    // ============================================================
    // TC-RT03: Test Suite Room Type Rate
    // ============================================================
    @Test
    @Order(3)
    @DisplayName("TC-RT03: Suite room type has highest rate")
    void testSuiteRoomTypeRate() {
        assertTrue(suiteType.getRatePerNight().compareTo(deluxeType.getRatePerNight()) > 0,
                "Suite rate should be higher than Deluxe");
    }

    // ============================================================
    // TC-RT04: Test Max Occupancy Setting
    // ============================================================
    @Test
    @Order(4)
    @DisplayName("TC-RT04: Max occupancy can be set and retrieved")
    void testMaxOccupancy() {
        standardType.setMaxOccupancy(2);
        deluxeType.setMaxOccupancy(3);
        suiteType.setMaxOccupancy(4);
        assertEquals(2, standardType.getMaxOccupancy());
        assertEquals(3, deluxeType.getMaxOccupancy());
        assertEquals(4, suiteType.getMaxOccupancy());
    }

    // ============================================================
    // TC-RT05: Test Room Type Description
    // ============================================================
    @Test
    @Order(5)
    @DisplayName("TC-RT05: Room type description can be set")
    void testRoomTypeDescription() {
        standardType.setDescription("Basic room with sea view");
        assertEquals("Basic room with sea view", standardType.getDescription());
    }

    // ============================================================
    // TC-RT06: Test Amenities Setting
    // ============================================================
    @Test
    @Order(6)
    @DisplayName("TC-RT06: Amenities can be set and retrieved")
    void testAmenitiesSetting() {
        deluxeType.setAmenities("WiFi, Mini-bar, Jacuzzi, Balcony");
        assertEquals("WiFi, Mini-bar, Jacuzzi, Balcony", deluxeType.getAmenities());
    }

    // ============================================================
    // TC-RT07: Test Rate Update
    // ============================================================
    @Test
    @Order(7)
    @DisplayName("TC-RT07: Room rate can be updated")
    void testRateUpdate() {
        standardType.setRatePerNight(new BigDecimal("18000.00"));
        assertEquals(new BigDecimal("18000.00"), standardType.getRatePerNight());
    }

    // ============================================================
    // TC-RT08: Test Room Type Status Default
    // ============================================================
    @Test
    @Order(8)
    @DisplayName("TC-RT08: Default room type status is AVAILABLE")
    void testDefaultRoomTypeStatus() {
        RoomType newType = new RoomType();
        assertEquals(RoomTypeStatus.AVAILABLE, newType.getStatus(),
                "Default status should be AVAILABLE");
    }

    // ============================================================
    // TC-RT09: Test Room Type Status Change
    // ============================================================
    @Test
    @Order(9)
    @DisplayName("TC-RT09: Room type can be set to UNAVAILABLE")
    void testRoomTypeStatusChange() {
        standardType.setStatus(RoomTypeStatus.UNAVAILABLE);
        assertEquals(RoomTypeStatus.UNAVAILABLE, standardType.getStatus());
    }

    // ============================================================
    // TC-RT10: Test toString Output
    // ============================================================
    @Test
    @Order(10)
    @DisplayName("TC-RT10: toString() contains type name and rate")
    void testToStringOutput() {
        String result = standardType.toString();
        assertTrue(result.contains("Standard"), "Should contain type name");
        assertTrue(result.contains("15000"), "Should contain rate");
    }

    @AfterEach
    void tearDown() {
        standardType = null;
        deluxeType = null;
        suiteType = null;
    }
}
