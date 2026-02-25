package com.oceanview.model;

import com.oceanview.model.User.UserRole;
import com.oceanview.model.User.UserStatus;
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Test Class for User Model
 * Tests user creation, role assignment, status management, and validation
 * 
 * Test-Driven Development Approach:
 * Tests were written BEFORE implementing the User model to define
 * expected behavior for authentication and role-based access control.
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0
 */
@DisplayName("User Model Tests")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class UserTest {

    private User user;

    @BeforeEach
    void setUp() {
        // Arrange: Create a test user with known data before each test
        user = new User(1, "admin", "admin123", UserRole.ADMIN,
                "John Silva", "john@oceanview.lk", "0771234567",
                "123 Beach Road, Galle");
    }

    // ============================================================
    // TC-U01: Test Default Constructor
    // ============================================================
    @Test
    @Order(1)
    @DisplayName("TC-U01: Default constructor creates user with null fields")
    void testDefaultConstructor() {
        User defaultUser = new User();
        assertNull(defaultUser.getUsername(), "Username should be null");
        assertNull(defaultUser.getPassword(), "Password should be null");
        assertNull(defaultUser.getRole(), "Role should be null");
        assertEquals(0, defaultUser.getUserId(), "User ID should be 0");
    }

    // ============================================================
    // TC-U02: Test Parameterized Constructor
    // ============================================================
    @Test
    @Order(2)
    @DisplayName("TC-U02: Parameterized constructor sets all fields correctly")
    void testParameterizedConstructor() {
        assertEquals(1, user.getUserId());
        assertEquals("admin", user.getUsername());
        assertEquals("admin123", user.getPassword());
        assertEquals(UserRole.ADMIN, user.getRole());
        assertEquals("John Silva", user.getFullName());
        assertEquals("john@oceanview.lk", user.getEmail());
        assertEquals("0771234567", user.getPhone());
        assertEquals("123 Beach Road, Galle", user.getAddress());
        assertEquals(UserStatus.ACTIVE, user.getStatus(),
                "Default status should be ACTIVE");
    }

    // ============================================================
    // TC-U03: Test Admin Role Check
    // ============================================================
    @Test
    @Order(3)
    @DisplayName("TC-U03: isAdmin() returns true for ADMIN role")
    void testIsAdminReturnsTrue() {
        user.setRole(UserRole.ADMIN);
        assertTrue(user.isAdmin(), "User with ADMIN role should return true for isAdmin()");
    }

    // ============================================================
    // TC-U04: Test Staff Role Check
    // ============================================================
    @Test
    @Order(4)
    @DisplayName("TC-U04: isStaff() returns true for STAFF role")
    void testIsStaffReturnsTrue() {
        user.setRole(UserRole.STAFF);
        assertTrue(user.isStaff(), "User with STAFF role should return true for isStaff()");
    }

    // ============================================================
    // TC-U05: Test Admin is not Staff
    // ============================================================
    @Test
    @Order(5)
    @DisplayName("TC-U05: Admin user is NOT identified as Staff")
    void testAdminIsNotStaff() {
        user.setRole(UserRole.ADMIN);
        assertFalse(user.isStaff(), "Admin should NOT be identified as Staff");
    }

    // ============================================================
    // TC-U06: Test Staff is not Admin
    // ============================================================
    @Test
    @Order(6)
    @DisplayName("TC-U06: Staff user is NOT identified as Admin")
    void testStaffIsNotAdmin() {
        user.setRole(UserRole.STAFF);
        assertFalse(user.isAdmin(), "Staff should NOT be identified as Admin");
    }

    // ============================================================
    // TC-U07: Test Username Setter/Getter
    // ============================================================
    @Test
    @Order(7)
    @DisplayName("TC-U07: Username can be set and retrieved")
    void testUsernameSetterGetter() {
        user.setUsername("newadmin");
        assertEquals("newadmin", user.getUsername());
    }

    // ============================================================
    // TC-U08: Test Password Setter/Getter
    // ============================================================
    @Test
    @Order(8)
    @DisplayName("TC-U08: Password can be set and retrieved")
    void testPasswordSetterGetter() {
        user.setPassword("newpass456");
        assertEquals("newpass456", user.getPassword());
    }

    // ============================================================
    // TC-U09: Test User Status Management
    // ============================================================
    @Test
    @Order(9)
    @DisplayName("TC-U09: User status can be changed to INACTIVE")
    void testUserStatusChange() {
        user.setStatus(UserStatus.INACTIVE);
        assertEquals(UserStatus.INACTIVE, user.getStatus());
    }

    // ============================================================
    // TC-U10: Test toString Output
    // ============================================================
    @Test
    @Order(10)
    @DisplayName("TC-U10: toString() contains username and role")
    void testToStringContainsKeyInfo() {
        String result = user.toString();
        assertTrue(result.contains("admin"), "toString should contain username");
        assertTrue(result.contains("ADMIN"), "toString should contain role");
        assertTrue(result.contains("John Silva"), "toString should contain full name");
    }

    @AfterEach
    void tearDown() {
        user = null;
    }
}
