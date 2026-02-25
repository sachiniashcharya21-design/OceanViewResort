<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ page import="java.sql.*" %>
        <%@ page import="java.io.*" %>
            <%@ page import="java.util.*" %>
                <%@ page import="java.security.MessageDigest" %>
                    <%@ page import="javax.servlet.http.Part" %>
                        <%! // Password hashing utility private String hashPassword(String password) { try {
                            MessageDigest md=MessageDigest.getInstance("SHA-256"); byte[]
                            hash=md.digest(password.getBytes("UTF-8")); StringBuilder hexString=new StringBuilder(); for
                            (byte b : hash) { String hex=Integer.toHexString(0xff & b); if (hex.length()==1)
                            hexString.append('0'); hexString.append(hex); } return hexString.toString(); } catch
                            (Exception e) { return password; } } // Generate unique number private String
                            generateNumber(String prefix) { return prefix + System.currentTimeMillis(); } %>
                            <% response.setContentType("application/json"); response.setCharacterEncoding("UTF-8"); //
                                Check session Integer userId=(Integer) session.getAttribute("userId"); String
                                userRole=(String) session.getAttribute("userRole"); if (userId==null ||
                                !"ADMIN".equalsIgnoreCase(userRole)) { out.print("{\"success\": false, \"message\":
                                \"Unauthorized access\"}"); return; } String action=request.getParameter("action");
                                Connection conn=null; String result="{\" success\": false, \"message\": \"Invalid
                                action\"}"; try { Class.forName("com.mysql.cj.jdbc.Driver");
                                conn=DriverManager.getConnection("jdbc:mysql://localhost:3306/ocean_view_resort", "root"
                                , "" ); if (action==null) { result="{\" success\": false, \"message\": \"No action
                                specified\"}"; } // ADD ROOM else if ("addRoom".equals(action)) { String
                                roomNumber=request.getParameter("roomNumber"); int
                                roomTypeId=Integer.parseInt(request.getParameter("roomTypeId")); int
                                floorNumber=Integer.parseInt(request.getParameter("floorNumber")); String
                                status=request.getParameter("status"); String notes=request.getParameter("notes");
                                PreparedStatement
                                ps=conn.prepareStatement( "INSERT INTO rooms (room_number, room_type_id, floor_number, status, notes) VALUES (?, ?, ?, ?, ?)"
                                ); ps.setString(1, roomNumber); ps.setInt(2, roomTypeId); ps.setInt(3, floorNumber);
                                ps.setString(4, status); ps.setString(5, notes); ps.executeUpdate(); ps.close();
                                result="{\" success\": true, \"message\": \"Room added successfully\"}"; } // DELETE
                                ROOM else if ("deleteRoom".equals(action)) { int
                                id=Integer.parseInt(request.getParameter("id")); PreparedStatement
                                ps=conn.prepareStatement("DELETE FROM rooms WHERE room_id=?"); ps.setInt(1, id); int
                                affected=ps.executeUpdate(); ps.close(); result=affected> 0 ? "{\"success\": true}" :
                                "{\"success\": false, \"message\": \"Room not found\"}";
                                }

                                // ADD ROOM TYPE
                                else if ("addRoomType".equals(action)) {
                                String typeName = request.getParameter("typeName").toUpperCase().replace(" ", "_");
                                double rate = Double.parseDouble(request.getParameter("rate"));
                                int maxOccupancy = Integer.parseInt(request.getParameter("maxOccupancy"));
                                String status = request.getParameter("status");
                                String description = request.getParameter("description");
                                String amenities = request.getParameter("amenities");

                                PreparedStatement ps = conn.prepareStatement(
                                "INSERT INTO room_types (type_name, description, rate_per_night, max_occupancy,
                                amenities, status) VALUES (?, ?, ?, ?, ?, ?)"
                                );
                                ps.setString(1, typeName);
                                ps.setString(2, description);
                                ps.setDouble(3, rate);
                                ps.setInt(4, maxOccupancy);
                                ps.setString(5, amenities);
                                ps.setString(6, status);
                                ps.executeUpdate();
                                ps.close();
                                result = "{\"success\": true, \"message\": \"Room type added successfully\"}";
                                }

                                // DELETE ROOM TYPE
                                else if ("deleteRoomType".equals(action)) {
                                int id = Integer.parseInt(request.getParameter("id"));
                                // Check if rooms using this type exist
                                PreparedStatement check = conn.prepareStatement("SELECT COUNT(*) FROM rooms WHERE
                                room_type_id = ?");
                                check.setInt(1, id);
                                ResultSet rs = check.executeQuery();
                                rs.next();
                                if (rs.getInt(1) > 0) {
                                result = "{\"success\": false, \"message\": \"Cannot delete: Rooms are using this
                                type\"}";
                                } else {
                                PreparedStatement ps = conn.prepareStatement("DELETE FROM room_types WHERE room_type_id
                                = ?");
                                ps.setInt(1, id);
                                ps.executeUpdate();
                                ps.close();
                                result = "{\"success\": true}";
                                }
                                rs.close();
                                check.close();
                                }

                                // ADD STAFF
                                else if ("addStaff".equals(action)) {
                                String fullName = request.getParameter("fullName");
                                String username = request.getParameter("username");
                                String password = hashPassword(request.getParameter("password"));
                                String email = request.getParameter("email");
                                String phone = request.getParameter("phone");
                                String hireDate = request.getParameter("hireDate");
                                String address = request.getParameter("address");

                                // Check username exists
                                PreparedStatement check = conn.prepareStatement("SELECT COUNT(*) FROM users WHERE
                                username = ?");
                                check.setString(1, username);
                                ResultSet rs = check.executeQuery();
                                rs.next();
                                if (rs.getInt(1) > 0) {
                                result = "{\"success\": false, \"message\": \"Username already exists\"}";
                                } else {
                                PreparedStatement ps = conn.prepareStatement(
                                "INSERT INTO users (username, password_hash, full_name, role, email, phone, address,
                                hire_date, status) VALUES (?, ?, ?, 'STAFF', ?, ?, ?, ?, 'ACTIVE')"
                                );
                                ps.setString(1, username);
                                ps.setString(2, password);
                                ps.setString(3, fullName);
                                ps.setString(4, email);
                                ps.setString(5, phone);
                                ps.setString(6, address);
                                ps.setString(7, hireDate);
                                ps.executeUpdate();
                                ps.close();
                                result = "{\"success\": true, \"message\": \"Staff added successfully\"}";
                                }
                                rs.close();
                                check.close();
                                }

                                // DELETE STAFF
                                else if ("deleteStaff".equals(action)) {
                                int id = Integer.parseInt(request.getParameter("id"));
                                PreparedStatement ps = conn.prepareStatement("UPDATE users SET status = 'INACTIVE' WHERE
                                user_id = ? AND role = 'STAFF'");
                                ps.setInt(1, id);
                                int affected = ps.executeUpdate();
                                ps.close();
                                result = affected > 0 ? "{\"success\": true}" : "{\"success\": false, \"message\":
                                \"Staff not found\"}";
                                }

                                // ADD CUSTOMER
                                else if ("addCustomer".equals(action)) {
                                String fullName = request.getParameter("fullName");
                                String nicPassport = request.getParameter("nicPassport");
                                String phone = request.getParameter("phone");
                                String email = request.getParameter("email");
                                String nationality = request.getParameter("nationality");
                                String dob = request.getParameter("dob");
                                String address = request.getParameter("address");

                                PreparedStatement ps = conn.prepareStatement(
                                "INSERT INTO guests (full_name, nic_passport, phone, email, nationality, date_of_birth,
                                address) VALUES (?, ?, ?, ?, ?, ?, ?)",
                                java.sql.Statement.RETURN_GENERATED_KEYS
                                );
                                ps.setString(1, fullName);
                                ps.setString(2, nicPassport);
                                ps.setString(3, phone);
                                ps.setString(4, email);
                                ps.setString(5, nationality);
                                if (dob != null && !dob.isEmpty()) {
                                ps.setDate(6, java.sql.Date.valueOf(dob));
                                } else {
                                ps.setNull(6, java.sql.Types.DATE);
                                }
                                ps.setString(7, address);
                                ps.executeUpdate();

                                // Get the generated guest ID
                                ResultSet keys = ps.getGeneratedKeys();
                                int newGuestId = 0;
                                if (keys.next()) {
                                newGuestId = keys.getInt(1);
                                }
                                keys.close();
                                ps.close();
                                result = "{\"success\": true, \"message\": \"Guest registered successfully\",
                                \"guestId\": " + newGuestId + "}";
                                }

                                // DELETE CUSTOMER
                                else if ("deleteCustomer".equals(action)) {
                                int id = Integer.parseInt(request.getParameter("id"));
                                // Check if guest has reservations
                                PreparedStatement check = conn.prepareStatement("SELECT COUNT(*) FROM reservations WHERE
                                guest_id = ?");
                                check.setInt(1, id);
                                ResultSet rs = check.executeQuery();
                                rs.next();
                                if (rs.getInt(1) > 0) {
                                result = "{\"success\": false, \"message\": \"Cannot delete: Guest has reservations\"}";
                                } else {
                                PreparedStatement ps = conn.prepareStatement("DELETE FROM guests WHERE guest_id = ?");
                                ps.setInt(1, id);
                                ps.executeUpdate();
                                ps.close();
                                result = "{\"success\": true}";
                                }
                                rs.close();
                                check.close();
                                }

                                // GET CUSTOMER DETAILS
                                else if ("getCustomer".equals(action)) {
                                int id = Integer.parseInt(request.getParameter("id"));
                                PreparedStatement ps = conn.prepareStatement(
                                "SELECT g.*, (SELECT COUNT(*) FROM reservations r WHERE r.guest_id = g.guest_id) as
                                booking_count FROM guests g WHERE g.guest_id = ?"
                                );
                                ps.setInt(1, id);
                                ResultSet rs = ps.executeQuery();
                                if (rs.next()) {
                                StringBuilder sb = new StringBuilder("{\"success\": true, \"data\": {");
                                sb.append("\"guest_id\":").append(rs.getInt("guest_id")).append(",");
                                sb.append("\"full_name\":\"").append(rs.getString("full_name").replace("\"",
                                "\\\"")).append("\",");
                                sb.append("\"nic_passport\":\"").append(rs.getString("nic_passport") != null ?
                                rs.getString("nic_passport") : "").append("\",");
                                sb.append("\"phone\":\"").append(rs.getString("phone") != null ? rs.getString("phone") :
                                "").append("\",");
                                sb.append("\"email\":\"").append(rs.getString("email") != null ? rs.getString("email") :
                                "").append("\",");
                                sb.append("\"nationality\":\"").append(rs.getString("nationality") != null ?
                                rs.getString("nationality") : "").append("\",");
                                sb.append("\"date_of_birth\":\"").append(rs.getDate("date_of_birth") != null ?
                                rs.getDate("date_of_birth").toString() : "").append("\",");
                                sb.append("\"address\":\"").append(rs.getString("address") != null ?
                                rs.getString("address").replace("\"", "\\\"").replace("\n", " ").replace("\r", "") :
                                "").append("\",");
                                sb.append("\"booking_count\":").append(rs.getInt("booking_count"));
                                sb.append("}}");
                                result = sb.toString();
                                } else {
                                result = "{\"success\": false, \"message\": \"Customer not found\"}";
                                }
                                rs.close();
                                ps.close();
                                }

                                // EDIT CUSTOMER
                                else if ("editCustomer".equals(action)) {
                                int id = Integer.parseInt(request.getParameter("id"));
                                String fullName = request.getParameter("fullName");
                                String nicPassport = request.getParameter("nicPassport");
                                String phone = request.getParameter("phone");
                                String email = request.getParameter("email");
                                String nationality = request.getParameter("nationality");
                                String dob = request.getParameter("dob");
                                String address = request.getParameter("address");

                                PreparedStatement ps = conn.prepareStatement(
                                "UPDATE guests SET full_name = ?, nic_passport = ?, phone = ?, email = ?, nationality =
                                ?, date_of_birth = ?, address = ? WHERE guest_id = ?"
                                );
                                ps.setString(1, fullName);
                                ps.setString(2, nicPassport);
                                ps.setString(3, phone);
                                ps.setString(4, email);
                                ps.setString(5, nationality);
                                if (dob != null && !dob.isEmpty()) {
                                ps.setDate(6, java.sql.Date.valueOf(dob));
                                } else {
                                ps.setNull(6, java.sql.Types.DATE);
                                }
                                ps.setString(7, address);
                                ps.setInt(8, id);
                                int affected = ps.executeUpdate();
                                ps.close();
                                result = affected > 0 ? "{\"success\": true, \"message\": \"Customer updated
                                successfully\"}" : "{\"success\": false, \"message\": \"Customer not found\"}";
                                }

                                // GET CUSTOMER BOOKINGS
                                else if ("getCustomerBookings".equals(action)) {
                                int id = Integer.parseInt(request.getParameter("id"));
                                PreparedStatement ps = conn.prepareStatement(
                                "SELECT r.*, rm.room_number, rt.type_name, rt.rate_per_night FROM reservations r " +
                                "JOIN rooms rm ON r.room_id = rm.room_id JOIN room_types rt ON rm.room_type_id =
                                rt.room_type_id " +
                                "WHERE r.guest_id = ? ORDER BY r.check_in_date DESC"
                                );
                                ps.setInt(1, id);
                                ResultSet rs = ps.executeQuery();
                                StringBuilder sb = new StringBuilder("{\"success\": true, \"bookings\": [");
                                boolean first = true;
                                while (rs.next()) {
                                if (!first) sb.append(",");
                                first = false;
                                sb.append("{");
                                sb.append("\"reservation_id\":").append(rs.getInt("reservation_id")).append(",");
                                sb.append("\"reservation_number\":\"").append(rs.getString("reservation_number")).append("\",");
                                sb.append("\"room_number\":\"").append(rs.getString("room_number")).append("\",");
                                sb.append("\"room_type\":\"").append(rs.getString("type_name")).append("\",");
                                sb.append("\"check_in\":\"").append(rs.getDate("check_in_date")).append("\",");
                                sb.append("\"check_out\":\"").append(rs.getDate("check_out_date")).append("\",");
                                sb.append("\"status\":\"").append(rs.getString("status")).append("\",");
                                sb.append("\"rate\":").append(rs.getDouble("rate_per_night"));
                                sb.append("}");
                                }
                                sb.append("]}");
                                result = sb.toString();
                                rs.close();
                                ps.close();
                                }

                                // ADD RESERVATION
                                else if ("addReservation".equals(action)) {
                                int guestId = Integer.parseInt(request.getParameter("guestId"));
                                int roomId = Integer.parseInt(request.getParameter("roomId"));
                                String checkInDate = request.getParameter("checkInDate");
                                String checkOutDate = request.getParameter("checkOutDate");
                                int numGuests = Integer.parseInt(request.getParameter("numGuests"));
                                String specialRequests = request.getParameter("specialRequests");
                                String reservationNumber = "RES" + System.currentTimeMillis();

                                // Check room availability
                                PreparedStatement check = conn.prepareStatement(
                                "SELECT COUNT(*) FROM reservations WHERE room_id = ? AND status IN ('CONFIRMED',
                                'CHECKED_IN') " +
                                "AND ((check_in_date BETWEEN ? AND ?) OR (check_out_date BETWEEN ? AND ?) OR
                                (check_in_date <= ? AND check_out_date>= ?))"
                                    );
                                    check.setInt(1, roomId);
                                    check.setString(2, checkInDate);
                                    check.setString(3, checkOutDate);
                                    check.setString(4, checkInDate);
                                    check.setString(5, checkOutDate);
                                    check.setString(6, checkInDate);
                                    check.setString(7, checkOutDate);
                                    ResultSet rs = check.executeQuery();
                                    rs.next();

                                    if (rs.getInt(1) > 0) {
                                    result = "{\"success\": false, \"message\": \"Room is not available for selected
                                    dates\"}";
                                    } else {
                                    PreparedStatement ps = conn.prepareStatement(
                                    "INSERT INTO reservations (reservation_number, guest_id, room_id, check_in_date,
                                    check_out_date, number_of_guests, special_requests, status, created_by) VALUES (?,
                                    ?, ?, ?, ?, ?, ?, 'CONFIRMED', ?)"
                                    );
                                    ps.setString(1, reservationNumber);
                                    ps.setInt(2, guestId);
                                    ps.setInt(3, roomId);
                                    ps.setDate(4, java.sql.Date.valueOf(checkInDate));
                                    ps.setDate(5, java.sql.Date.valueOf(checkOutDate));
                                    ps.setInt(6, numGuests);
                                    ps.setString(7, specialRequests);
                                    ps.setInt(8, userId);
                                    ps.executeUpdate();
                                    ps.close();

                                    // Update room status to reserved
                                    PreparedStatement updateRoom = conn.prepareStatement("UPDATE rooms SET status =
                                    'RESERVED' WHERE room_id = ?");
                                    updateRoom.setInt(1, roomId);
                                    updateRoom.executeUpdate();
                                    updateRoom.close();

                                    result = "{\"success\": true, \"message\": \"Reservation created: " +
                                    reservationNumber + "\"}";
                                    }
                                    rs.close();
                                    check.close();
                                    }

                                    // UPDATE RESERVATION STATUS
                                    else if ("updateReservationStatus".equals(action)) {
                                    int reservationId = Integer.parseInt(request.getParameter("reservationId"));
                                    String status = request.getParameter("status");

                                    PreparedStatement ps = conn.prepareStatement(
                                    "UPDATE reservations SET status = ? WHERE reservation_id = ?"
                                    );
                                    ps.setString(1, status);
                                    ps.setInt(2, reservationId);
                                    int updated = ps.executeUpdate();
                                    ps.close();

                                    if (updated > 0) {
                                    // If status is CHECKED_IN, update room status to OCCUPIED
                                    if ("CHECKED_IN".equals(status)) {
                                    PreparedStatement roomPs = conn.prepareStatement(
                                    "UPDATE rooms SET status = 'OCCUPIED' WHERE room_id = (SELECT room_id FROM
                                    reservations WHERE reservation_id = ?)"
                                    );
                                    roomPs.setInt(1, reservationId);
                                    roomPs.executeUpdate();
                                    roomPs.close();
                                    }
                                    // If status is CHECKED_OUT or CANCELLED, update room status to AVAILABLE
                                    else if ("CHECKED_OUT".equals(status) || "CANCELLED".equals(status)) {
                                    PreparedStatement roomPs = conn.prepareStatement(
                                    "UPDATE rooms SET status = 'AVAILABLE' WHERE room_id = (SELECT room_id FROM
                                    reservations WHERE reservation_id = ?)"
                                    );
                                    roomPs.setInt(1, reservationId);
                                    roomPs.executeUpdate();
                                    roomPs.close();
                                    }
                                    result = "{\"success\": true, \"message\": \"Reservation status updated\"}";
                                    } else {
                                    result = "{\"success\": false, \"message\": \"Reservation not found\"}";
                                    }
                                    }

                                    // UPDATE PROFILE
                                    else if ("updateProfile".equals(action)) {
                                    String fullName = request.getParameter("fullName");
                                    String username = request.getParameter("username");
                                    String email = request.getParameter("email");
                                    String phone = request.getParameter("phone");
                                    String address = request.getParameter("address");

                                    // Check if username is taken by someone else
                                    PreparedStatement check = conn.prepareStatement("SELECT COUNT(*) FROM users WHERE
                                    username = ? AND user_id != ?");
                                    check.setString(1, username);
                                    check.setInt(2, userId);
                                    ResultSet rs = check.executeQuery();
                                    rs.next();

                                    if (rs.getInt(1) > 0) {
                                    result = "{\"success\": false, \"message\": \"Username already taken\"}";
                                    } else {
                                    PreparedStatement ps = conn.prepareStatement(
                                    "UPDATE users SET full_name = ?, username = ?, email = ?, phone = ?, address = ?
                                    WHERE user_id = ?"
                                    );
                                    ps.setString(1, fullName);
                                    ps.setString(2, username);
                                    ps.setString(3, email);
                                    ps.setString(4, phone);
                                    ps.setString(5, address);
                                    ps.setInt(6, userId);
                                    ps.executeUpdate();
                                    ps.close();

                                    // Update session
                                    session.setAttribute("fullName", fullName);
                                    session.setAttribute("username", username);

                                    result = "{\"success\": true, \"message\": \"Profile updated successfully\"}";
                                    }
                                    rs.close();
                                    check.close();
                                    }

                                    // CHANGE PASSWORD
                                    else if ("changePassword".equals(action)) {
                                    String currentPassword = hashPassword(request.getParameter("currentPassword"));
                                    String newPassword = hashPassword(request.getParameter("newPassword"));

                                    // Verify current password
                                    PreparedStatement check = conn.prepareStatement("SELECT password_hash FROM users
                                    WHERE user_id = ?");
                                    check.setInt(1, userId);
                                    ResultSet rs = check.executeQuery();

                                    if (rs.next() && rs.getString("password_hash").equals(currentPassword)) {
                                    PreparedStatement ps = conn.prepareStatement("UPDATE users SET password_hash = ?
                                    WHERE user_id = ?");
                                    ps.setString(1, newPassword);
                                    ps.setInt(2, userId);
                                    ps.executeUpdate();
                                    ps.close();
                                    result = "{\"success\": true, \"message\": \"Password changed successfully\"}";
                                    } else {
                                    result = "{\"success\": false, \"message\": \"Current password is incorrect\"}";
                                    }
                                    rs.close();
                                    check.close();
                                    }

                                    // UPLOAD PROFILE PICTURE
                                    else if ("uploadProfilePic".equals(action)) {
                                    String imageData = request.getParameter("imageData");
                                    String fileName = request.getParameter("fileName");

                                    if (imageData == null || imageData.isEmpty()) {
                                    result = "{\"success\": false, \"message\": \"No image data provided\"}";
                                    } else {
                                    try {
                                    String extension = "jpg";
                                    if (fileName != null && fileName.lastIndexOf('.') > 0) {
                                    extension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
                                    if (!Arrays.asList("jpg","jpeg","png","gif","webp").contains(extension)) {
                                    extension = "jpg";
                                    }
                                    }

                                    String base64Data = imageData;
                                    int commaIndex = imageData.indexOf(',');
                                    if (commaIndex > -1) {
                                    base64Data = imageData.substring(commaIndex + 1);
                                    }

                                    byte[] decoded = Base64.getDecoder().decode(base64Data);
                                    if (decoded.length > (5 * 1024 * 1024)) {
                                    result = "{\"success\": false, \"message\": \"Image too large (max 5MB)\"}";
                                    } else {
                                    String newFileName = "profile_" + userId + "_" + System.currentTimeMillis() + "." + extension;
                                    String uploadDir = application.getRealPath("/uploads/profiles/");
                                    File dir = new File(uploadDir);
                                    if (!dir.exists()) {
                                    dir.mkdirs();
                                    }

                                    File outFile = new File(dir, newFileName);
                                    try (FileOutputStream fos = new FileOutputStream(outFile)) {
                                    fos.write(decoded);
                                    }

                                    PreparedStatement ps = conn.prepareStatement("UPDATE users SET profile_picture = ? WHERE user_id = ?");
                                    ps.setString(1, newFileName);
                                    ps.setInt(2, userId);
                                    ps.executeUpdate();
                                    ps.close();

                                    String imagePath = request.getContextPath() + "/uploads/profiles/" + newFileName;
                                    result = "{\"success\": true, \"imagePath\": \"" + imagePath + "\"}";
                                    }
                                    } catch (Exception ex) {
                                    result = "{\"success\": false, \"message\": \"" + ex.getMessage().replace("\"", "\\\"") + "\"}";
                                    }
                                    }
                                    }

                                    // GET DATA - for AJAX loading
                                    else if ("getRoomData".equals(action)) {
                                    int id = Integer.parseInt(request.getParameter("id"));
                                    PreparedStatement ps = conn.prepareStatement("SELECT * FROM rooms WHERE room_id =
                                    ?");
                                    ps.setInt(1, id);
                                    ResultSet rs = ps.executeQuery();
                                    if (rs.next()) {
                                    result = String.format("{\"success\": true, \"data\": {\"room_id\": %d,
                                    \"room_number\": \"%s\", \"room_type_id\": %d, \"floor_number\": %d, \"status\":
                                    \"%s\", \"notes\": \"%s\"}}",
                                    rs.getInt("room_id"), rs.getString("room_number"), rs.getInt("room_type_id"),
                                    rs.getInt("floor_number"), rs.getString("status"), rs.getString("notes") != null ?
                                    rs.getString("notes").replace("\"", "\\\"") : "");
                                    } else {
                                    result = "{\"success\": false, \"message\": \"Room not found\"}";
                                    }
                                    rs.close();
                                    ps.close();
                                    }

                                    else if ("getStaffData".equals(action)) {
                                    int id = Integer.parseInt(request.getParameter("id"));
                                    PreparedStatement ps = conn.prepareStatement("SELECT * FROM users WHERE user_id = ?
                                    AND role = 'STAFF'");
                                    ps.setInt(1, id);
                                    ResultSet rs = ps.executeQuery();
                                    if (rs.next()) {
                                    result = String.format("{\"success\": true, \"data\": {\"user_id\": %d,
                                    \"username\": \"%s\", \"full_name\": \"%s\", \"email\": \"%s\", \"phone\": \"%s\",
                                    \"status\": \"%s\"}}",
                                    rs.getInt("user_id"), rs.getString("username"), rs.getString("full_name"),
                                    rs.getString("email") != null ? rs.getString("email") : "",
                                    rs.getString("phone") != null ? rs.getString("phone") : "",
                                    rs.getString("status"));
                                    } else {
                                    result = "{\"success\": false, \"message\": \"Staff not found\"}";
                                    }
                                    rs.close();
                                    ps.close();
                                    }

                                    else if ("getCustomerData".equals(action)) {
                                    int id = Integer.parseInt(request.getParameter("id"));
                                    PreparedStatement ps = conn.prepareStatement("SELECT * FROM guests WHERE guest_id =
                                    ?");
                                    ps.setInt(1, id);
                                    ResultSet rs = ps.executeQuery();
                                    if (rs.next()) {
                                    result = String.format("{\"success\": true, \"data\": {\"guest_id\": %d,
                                    \"full_name\": \"%s\", \"nic_passport\": \"%s\", \"phone\": \"%s\", \"email\":
                                    \"%s\", \"nationality\": \"%s\"}}",
                                    rs.getInt("guest_id"), rs.getString("full_name"),
                                    rs.getString("nic_passport") != null ? rs.getString("nic_passport") : "",
                                    rs.getString("phone") != null ? rs.getString("phone") : "",
                                    rs.getString("email") != null ? rs.getString("email") : "",
                                    rs.getString("nationality") != null ? rs.getString("nationality") : "");
                                    } else {
                                    result = "{\"success\": false, \"message\": \"Guest not found\"}";
                                    }
                                    rs.close();
                                    ps.close();
                                    }

                                    else if ("getReservationData".equals(action)) {
                                    int id = Integer.parseInt(request.getParameter("id"));
                                    PreparedStatement ps = conn.prepareStatement(
                                    "SELECT r.*, g.full_name as guest_name, rm.room_number, rt.type_name,
                                    rt.rate_per_night " +
                                    "FROM reservations r JOIN guests g ON r.guest_id = g.guest_id " +
                                    "JOIN rooms rm ON r.room_id = rm.room_id JOIN room_types rt ON rm.room_type_id =
                                    rt.room_type_id " +
                                    "WHERE r.reservation_id = ?"
                                    );
                                    ps.setInt(1, id);
                                    ResultSet rs = ps.executeQuery();
                                    if (rs.next()) {
                                    result = String.format("{\"success\": true, \"data\": {\"reservation_id\": %d,
                                    \"reservation_number\": \"%s\", \"guest_name\": \"%s\", \"room_number\": \"%s\",
                                    \"type_name\": \"%s\", \"check_in_date\": \"%s\", \"check_out_date\": \"%s\",
                                    \"status\": \"%s\", \"rate_per_night\": %.2f}}",
                                    rs.getInt("reservation_id"), rs.getString("reservation_number"),
                                    rs.getString("guest_name"), rs.getString("room_number"),
                                    rs.getString("type_name"), rs.getDate("check_in_date"),
                                    rs.getDate("check_out_date"),
                                    rs.getString("status"), rs.getDouble("rate_per_night"));
                                    } else {
                                    result = "{\"success\": false, \"message\": \"Reservation not found\"}";
                                    }
                                    rs.close();
                                    ps.close();
                                    }

                                    // UPDATE RESERVATION STATUS
                                    else if ("updateReservationStatus".equals(action)) {
                                    int id = Integer.parseInt(request.getParameter("id"));
                                    String status = request.getParameter("status");

                                    PreparedStatement ps = conn.prepareStatement("UPDATE reservations SET status = ?
                                    WHERE reservation_id = ?");
                                    ps.setString(1, status);
                                    ps.setInt(2, id);
                                    ps.executeUpdate();
                                    ps.close();

                                    // Update room status based on reservation status
                                    PreparedStatement getRoomId = conn.prepareStatement("SELECT room_id FROM
                                    reservations WHERE reservation_id = ?");
                                    getRoomId.setInt(1, id);
                                    ResultSet rs = getRoomId.executeQuery();
                                    if (rs.next()) {
                                    int roomId = rs.getInt("room_id");
                                    String roomStatus = "AVAILABLE";
                                    if ("CHECKED_IN".equals(status)) roomStatus = "OCCUPIED";
                                    else if ("CONFIRMED".equals(status)) roomStatus = "RESERVED";

                                    PreparedStatement updateRoom = conn.prepareStatement("UPDATE rooms SET status = ?
                                    WHERE room_id = ?");
                                    updateRoom.setString(1, roomStatus);
                                    updateRoom.setInt(2, roomId);
                                    updateRoom.executeUpdate();
                                    updateRoom.close();
                                    }
                                    rs.close();
                                    getRoomId.close();

                                    result = "{\"success\": true, \"message\": \"Status updated\"}";
                                    }

                                    // UPDATE PAYMENT
                                    else if ("updatePayment".equals(action)) {
                                    int billId = Integer.parseInt(request.getParameter("billId"));
                                    String paymentStatus = request.getParameter("paymentStatus");
                                    String paymentMethod = request.getParameter("paymentMethod");

                                    String sql = "UPDATE bills SET payment_status = ?, payment_method = ?";
                                    if ("PAID".equals(paymentStatus)) {
                                    sql += ", paid_at = NOW()";
                                    }
                                    sql += " WHERE bill_id = ?";

                                    PreparedStatement ps = conn.prepareStatement(sql);
                                    ps.setString(1, paymentStatus);
                                    ps.setString(2, paymentMethod != null && !paymentMethod.isEmpty() ? paymentMethod :
                                    "CASH");
                                    ps.setInt(3, billId);

                                    int rows = ps.executeUpdate();
                                    ps.close();

                                    if (rows > 0) {
                                    result = "{\"success\": true, \"message\": \"Payment updated successfully\"}";
                                    } else {
                                    result = "{\"success\": false, \"message\": \"Bill not found\"}";
                                    }
                                    }

                                    // GET REPORT DATA
                                    else if ("getReportData".equals(action)) {
                                    String period = request.getParameter("period");
                                    String dateCondition = "";

                                    if ("daily".equals(period)) {
                                    dateCondition = "DATE(generated_at) = CURDATE()";
                                    } else if ("weekly".equals(period)) {
                                    dateCondition = "YEARWEEK(generated_at) = YEARWEEK(CURDATE())";
                                    } else {
                                    dateCondition = "MONTH(generated_at) = MONTH(CURDATE()) AND YEAR(generated_at) =
                                    YEAR(CURDATE())";
                                    }

                                    StringBuilder sb = new StringBuilder("{\"success\": true, \"data\": {");

                                    // Revenue
                                    Statement stmt = conn.createStatement();
                                    ResultSet rs = stmt.executeQuery("SELECT IFNULL(SUM(total_amount), 0) as revenue
                                    FROM bills WHERE payment_status = 'PAID' AND " + dateCondition);
                                    rs.next();
                                    sb.append("\"revenue\": ").append(rs.getDouble("revenue")).append(",");
                                    rs.close();

                                    // Bookings
                                    rs = stmt.executeQuery("SELECT COUNT(*) as bookings FROM reservations WHERE " +
                                    dateCondition.replace("generated_at", "created_at"));
                                    rs.next();
                                    sb.append("\"bookings\": ").append(rs.getInt("bookings")).append(",");
                                    rs.close();

                                    // New guests
                                    rs = stmt.executeQuery("SELECT COUNT(*) as guests FROM guests WHERE " +
                                    dateCondition.replace("generated_at", "created_at"));
                                    rs.next();
                                    sb.append("\"guests\": ").append(rs.getInt("guests"));
                                    rs.close();

                                    stmt.close();
                                    sb.append("}}");
                                    result = sb.toString();
                                    }

                                    } catch (Exception e) {
                                    result = "{\"success\": false, \"message\": \"" + e.getMessage().replace("\"",
                                    "\\\"") + "\"}";
                                    e.printStackTrace();
                                    } finally {
                                    if (conn != null) { try { conn.close(); } catch (Exception e) {} }
                                    }

                                    out.print(result);
                                    %>
