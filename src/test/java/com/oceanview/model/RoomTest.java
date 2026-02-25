package com.oceanview.model;

import com.oceanview.model.Room.RoomStatus;
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

import java.math.BigDecimal;

/**
 * Test Class for Room Model
 * Tests room creation, status transitions, and availability checks
 * 
 * Test-Driven Development Approach:
 * Tests define expected room lifecycle behavior including status
 * transitions (AVAILABLE -> RESERVED -> OCCUPIED -> MAINTENANCE)
 * to prevent double-booking scenarios.
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
@DisplayName("Room Model Tests")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class RoomTest {

    private Room room;
    private RoomType roomType;

    @BeforeEach
    void setUp() {
        room = new Room(1, "101", 1, 1);
        roomType = new RoomType(1, "Deluxe", new BigDecimal("25000.00"));
        room.setRoomType(roomType);
    }

    // ============================================================
    // TC-R01: Test Default Constructor
    // ============================================================
    @Test
    @Order(1)
    @DisplayName("TC-R01: Default constructor sets status to AVAILABLE")
    void testDefaultConstructor() {
        Room defaultRoom = new Room();
        assertEquals(RoomStatus.AVAILABLE, defaultRoom.getStatus(),
                "Default status should be AVAILABLE");
    }

    // ============================================================
    // TC-R02: Test Parameterized Constructor
    // ============================================================
    @Test
    @Order(2)
    @DisplayName("TC-R02: Parameterized constructor sets all fields")
    void testParameterizedConstructor() {
        assertEquals(1, room.getRoomId());
        assertEquals("101", room.getRoomNumber());
        assertEquals(1, room.getRoomTypeId());
        assertEquals(1, room.getFloorNumber());
        assertEquals(RoomStatus.AVAILABLE, room.getStatus());
    }

    // ============================================================
    // TC-R03: Test Room is Available (Positive)
    // ============================================================
    @Test
    @Order(3)
    @DisplayName("TC-R03: isAvailable() returns true when status is AVAILABLE")
    void testRoomIsAvailable() {
        room.setStatus(RoomStatus.AVAILABLE);
        assertTrue(room.isAvailable(), "Room with AVAILABLE status should be available");
    }

    // ============================================================
    // TC-R04: Test Occupied Room Not Available
    // ============================================================
    @Test
    @Order(4)
    @DisplayName("TC-R04: isAvailable() returns false when status is OCCUPIED")
    void testOccupiedRoomNotAvailable() {
        room.setStatus(RoomStatus.OCCUPIED);
        assertFalse(room.isAvailable(), "Occupied room should NOT be available");
    }

    // ============================================================
    // TC-R05: Test Reserved Room Not Available
    // ============================================================
    @Test
    @Order(5)
    @DisplayName("TC-R05: isAvailable() returns false when status is RESERVED")
    void testReservedRoomNotAvailable() {
        room.setStatus(RoomStatus.RESERVED);
        assertFalse(room.isAvailable(), "Reserved room should NOT be available");
    }

    // ============================================================
    // TC-R06: Test Maintenance Room Not Available
    // ============================================================
    @Test
    @Order(6)
    @DisplayName("TC-R06: isAvailable() returns false when status is MAINTENANCE")
    void testMaintenanceRoomNotAvailable() {
        room.setStatus(RoomStatus.MAINTENANCE);
        assertFalse(room.isAvailable(), "Room under maintenance should NOT be available");
    }

    // ============================================================
    // TC-R07: Test Room Type Association
    // ============================================================
    @Test
    @Order(7)
    @DisplayName("TC-R07: Room has correct associated RoomType")
    void testRoomTypeAssociation() {
        assertNotNull(room.getRoomType(), "Room should have an associated RoomType");
        assertEquals("Deluxe", room.getRoomType().getTypeName());
        assertEquals(new BigDecimal("25000.00"), room.getRoomType().getRatePerNight());
    }

    // ============================================================
    // TC-R08: Test Status Transition to OCCUPIED
    // ============================================================
    @Test
    @Order(8)
    @DisplayName("TC-R08: Room status can change to OCCUPIED")
    void testStatusTransitionToOccupied() {
        room.setStatus(RoomStatus.OCCUPIED);
        assertEquals(RoomStatus.OCCUPIED, room.getStatus());
    }

    // ============================================================
    // TC-R09: Test toString Output
    // ============================================================
    @Test
    @Order(9)
    @DisplayName("TC-R09: toString() contains room number and floor")
    void testToStringOutput() {
        String result = room.toString();
        assertTrue(result.contains("101"), "Should contain room number");
    }

    // ============================================================
    // TC-R10: Test Room Notes
    // ============================================================
    @Test
    @Order(10)
    @DisplayName("TC-R10: Room notes can be set and retrieved")
    void testRoomNotes() {
        room.setNotes("Sea-facing room with balcony");
        assertEquals("Sea-facing room with balcony", room.getNotes());
    }

    @AfterEach
    void tearDown() {
        room = null;
        roomType = null;
    }
}
