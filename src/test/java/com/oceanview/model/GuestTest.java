package com.oceanview.model;

import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Test Class for Guest Model
 * Tests guest creation, data validation, and attribute management
 * 
 * Test-Driven Development Approach:
 * Tests define expected guest registration behavior including
 * mandatory fields (name, phone, address) and optional fields.
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
@DisplayName("Guest Model Tests")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class GuestTest {

    private Guest guest;

    @BeforeEach
    void setUp() {
        guest = new Guest(1, "Kamal Perera", "200012345678",
                "kamal@gmail.com", "0771234567",
                "456 Temple Road, Colombo", "Sri Lankan");
    }

    // ============================================================
    // TC-G01: Test Default Constructor
    // ============================================================
    @Test
    @Order(1)
    @DisplayName("TC-G01: Default constructor sets nationality to Sri Lankan")
    void testDefaultConstructor() {
        Guest defaultGuest = new Guest();
        assertEquals("Sri Lankan", defaultGuest.getNationality(),
                "Default nationality should be 'Sri Lankan'");
    }

    // ============================================================
    // TC-G02: Test Simple Parameterized Constructor
    // ============================================================
    @Test
    @Order(2)
    @DisplayName("TC-G02: Simple constructor sets name, phone, address")
    void testSimpleConstructor() {
        Guest simpleGuest = new Guest("Nimal Fernando", "0712345678",
                "789 Main St, Galle");
        assertEquals("Nimal Fernando", simpleGuest.getFullName());
        assertEquals("0712345678", simpleGuest.getPhone());
        assertEquals("789 Main St, Galle", simpleGuest.getAddress());
        assertEquals("Sri Lankan", simpleGuest.getNationality());
    }

    // ============================================================
    // TC-G03: Test Full Parameterized Constructor
    // ============================================================
    @Test
    @Order(3)
    @DisplayName("TC-G03: Full constructor sets all fields correctly")
    void testFullConstructor() {
        assertEquals(1, guest.getGuestId());
        assertEquals("Kamal Perera", guest.getFullName());
        assertEquals("200012345678", guest.getNicPassport());
        assertEquals("kamal@gmail.com", guest.getEmail());
        assertEquals("0771234567", guest.getPhone());
        assertEquals("456 Temple Road, Colombo", guest.getAddress());
        assertEquals("Sri Lankan", guest.getNationality());
    }

    // ============================================================
    // TC-G04: Test Guest Name Update
    // ============================================================
    @Test
    @Order(4)
    @DisplayName("TC-G04: Guest name can be updated")
    void testGuestNameUpdate() {
        guest.setFullName("Kamal Perera Jr.");
        assertEquals("Kamal Perera Jr.", guest.getFullName());
    }

    // ============================================================
    // TC-G05: Test NIC/Passport Setting
    // ============================================================
    @Test
    @Order(5)
    @DisplayName("TC-G05: NIC/Passport number can be set")
    void testNicPassportSetting() {
        guest.setNicPassport("N1234567X");
        assertEquals("N1234567X", guest.getNicPassport());
    }

    // ============================================================
    // TC-G06: Test Email Setting
    // ============================================================
    @Test
    @Order(6)
    @DisplayName("TC-G06: Guest email can be set and retrieved")
    void testEmailSetting() {
        guest.setEmail("newemail@test.com");
        assertEquals("newemail@test.com", guest.getEmail());
    }

    // ============================================================
    // TC-G07: Test Phone Number Update
    // ============================================================
    @Test
    @Order(7)
    @DisplayName("TC-G07: Phone number can be updated")
    void testPhoneNumberUpdate() {
        guest.setPhone("0769876543");
        assertEquals("0769876543", guest.getPhone());
    }

    // ============================================================
    // TC-G08: Test Address Update
    // ============================================================
    @Test
    @Order(8)
    @DisplayName("TC-G08: Address can be updated")
    void testAddressUpdate() {
        guest.setAddress("New Beach Road, Unawatuna");
        assertEquals("New Beach Road, Unawatuna", guest.getAddress());
    }

    // ============================================================
    // TC-G09: Test Foreign Guest Nationality
    // ============================================================
    @Test
    @Order(9)
    @DisplayName("TC-G09: Foreign guest nationality can be set")
    void testForeignGuestNationality() {
        guest.setNationality("British");
        assertEquals("British", guest.getNationality());
    }

    // ============================================================
    // TC-G10: Test toString Output
    // ============================================================
    @Test
    @Order(10)
    @DisplayName("TC-G10: toString() contains guest name and phone")
    void testToStringOutput() {
        String result = guest.toString();
        assertTrue(result.contains("Kamal Perera"), "Should contain guest name");
        assertTrue(result.contains("0771234567"), "Should contain phone number");
    }

    @AfterEach
    void tearDown() {
        guest = null;
    }
}
