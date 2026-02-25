<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ page import="java.sql.*" %>
        <%@ page import="java.text.*" %>
            <%@ page import="java.io.*" %>
                <%@ page import="java.util.*" %>
                    <%@ page import="java.net.*" %>
                        <%! private String safe(String value) { return value==null ? "" : value.trim(); } private String
                            encodeMeta(String value) { try { return URLEncoder.encode(safe(value), "UTF-8" ); } catch
                            (Exception e) { return "" ; } } private String decodeMeta(String value) { try { return
                            URLDecoder.decode(safe(value), "UTF-8" ); } catch (Exception e) { return "" ; } } private
                            String buildRoomNotes(String description, String facilities, String imageUrl) {
                            return "__OVR__DESC=" + encodeMeta(description) + "\n" + "__OVR__FAC=" +
                            encodeMeta(facilities) + "\n" + "__OVR__IMG=" + encodeMeta(imageUrl); } private String
                            extractMeta(String notes, String key) { if (notes==null || notes.isEmpty()) return "" ;
                            String token="__OVR__" + key + "=" ; String[] lines=notes.split("\\n"); for (String line :
                            lines) { if (line.startsWith(token)) { return decodeMeta(line.substring(token.length())); }
                            } return "" ; } private String roomDescription(String notes, String fallbackDescription) {
                            String metaDescription=extractMeta(notes, "DESC" ); if (!metaDescription.isEmpty()) return
                            metaDescription; if (notes !=null && !notes.startsWith("__OVR__")) return notes; return
                            safe(fallbackDescription); } private String escapeJs(String value) { if (value==null)
                            return "" ; return value .replace("\\", "\\\\" ) .replace("'", "\\'" ) .replace("\r", " " )
                            .replace("\n", " " ); } private String jsonEscape(String value) { if (value==null) return ""
                            ; return value.replace("\\", "\\\\" ).replace("\"", "\\\"");
    }
%>
<%
    // Check if user is logged in and is admin
    String userRole = (String) session.getAttribute("userRole");
    String username = (String) session.getAttribute("username");
    Integer sessionUserId = (Integer) session.getAttribute("userId");

    if (username == null || userRole == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?role=admin");
        return;
    }
    if (!"ADMIN".equalsIgnoreCase(userRole)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    // Database connection
    Connection conn = null;
    String dbUrl = "jdbc:mysql://localhost:3306/ocean_view_resort";
    String dbUser = "root";
    String dbPass = "";

    String successMessage = (String) session.getAttribute("roomsSuccessMessage");
    String errorMessage = (String) session.getAttribute("roomsErrorMessage");
    if (successMessage != null) session.removeAttribute("roomsSuccessMessage");
    if (errorMessage != null) session.removeAttribute("roomsErrorMessage");

    // Statistics
    int totalRooms = 0, availableRooms = 0, occupiedRooms = 0, maintenanceRooms = 0;

    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        // Handle form submissions
        String action = request.getParameter("action");

        if ("uploadRoomImage".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");

            String imageData = request.getParameter("imageData");
            String fileName = request.getParameter("fileName");
            if (imageData == null || imageData.trim().isEmpty()) {
                out.print("{\"success\": false, \"message\": \"No image data provided\"}");
                if (conn != null) { try { conn.close(); } catch (Exception ignore) {} }
                return;
            }

            try {
                String extension = "jpg";
                if (fileName != null && fileName.lastIndexOf('.') > 0) {
                    extension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
                    if (!Arrays.asList("jpg", "jpeg", "png", "gif", "webp").contains(extension)) {
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
                    out.print("{\"success\": false, \"message\": \"Image too large (max 5MB)\"}");
                    if (conn != null) { try { conn.close(); } catch (Exception ignore) {} }
                    return;
                }

                String newFileName = "room_" + System.currentTimeMillis() + "_" + (int)(Math.random() * 10000) + "." + extension;
                String uploadDir = application.getRealPath("/uploads/rooms/");
                if (uploadDir == null || uploadDir.trim().isEmpty()) {
                    String contextName = request.getContextPath().replace("/", "");
                    uploadDir = System.getProperty("catalina.base") + File.separator + "webapps" + File.separator + contextName + File.separator + "uploads" + File.separator + "rooms";
                }

                File dir = new File(uploadDir);
                if (!dir.exists()) {
                    dir.mkdirs();
                }

                File outFile = new File(dir, newFileName);
                try (FileOutputStream fos = new FileOutputStream(outFile)) {
                    fos.write(decoded);
                }

                String imageUrl = request.getContextPath() + "/uploads/rooms/" + newFileName;
                out.print("{\"success\": true, \"imageUrl\": \"" + jsonEscape(imageUrl) + "\"}");
            } catch (Exception ex) {
                out.print("{\"success\": false, \"message\": \"" + jsonEscape(ex.getMessage()) + "\"}");
            }
            if (conn != null) { try { conn.close(); } catch (Exception ignore) {} }
            return;
        }

        // Add Room
        if ("addRoom".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            String roomNumber = request.getParameter("roomNumber");
            int roomTypeId = Integer.parseInt(request.getParameter("roomTypeId"));
            int floor = Integer.parseInt(request.getParameter("floor"));
            String status = request.getParameter("status");
            String description = request.getParameter("description");
            String facilities = request.getParameter("facilities");
            String imageUrl = request.getParameter("imageUrl");
            String notes = buildRoomNotes(description, facilities, imageUrl);

            PreparedStatement checkPs = conn.prepareStatement("SELECT room_id FROM rooms WHERE room_number = ?");
            checkPs.setString(1, roomNumber);
            ResultSet checkRs = checkPs.executeQuery();

            if (checkRs.next()) {
                errorMessage = "Room number '" + roomNumber + "' already exists.";
            } else {
                PreparedStatement ps = conn.prepareStatement("INSERT INTO rooms (room_number, room_type_id, floor_number, status, notes) VALUES (?, ?, ?, ?, ?)");
                ps.setString(1, roomNumber);
                ps.setInt(2, roomTypeId);
                ps.setInt(3, floor);
                ps.setString(4, status);
                ps.setString(5, notes);
                ps.executeUpdate();
                ps.close();
                successMessage = "Room '" + roomNumber + "' added successfully!";
            }
            checkRs.close();
            checkPs.close();
        }

        // Edit Room
        if ("editRoom".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            int roomId = Integer.parseInt(request.getParameter("roomId"));
            String roomNumber = request.getParameter("roomNumber");
            int roomTypeId = Integer.parseInt(request.getParameter("roomTypeId"));
            int floor = Integer.parseInt(request.getParameter("floor"));
            String status = request.getParameter("status");
            String description = request.getParameter("description");
            String facilities = request.getParameter("facilities");
            String imageUrl = request.getParameter("imageUrl");
            String notes = buildRoomNotes(description, facilities, imageUrl);

            PreparedStatement checkPs = conn.prepareStatement("SELECT room_id FROM rooms WHERE room_number = ? AND room_id != ?");
            checkPs.setString(1, roomNumber);
            checkPs.setInt(2, roomId);
            ResultSet checkRs = checkPs.executeQuery();

            if (checkRs.next()) {
                errorMessage = "Room number '" + roomNumber + "' already exists.";
            } else {
                PreparedStatement ps = conn.prepareStatement("UPDATE rooms SET room_number = ?, room_type_id = ?, floor_number = ?, status = ?, notes = ? WHERE room_id = ?");
                ps.setString(1, roomNumber);
                ps.setInt(2, roomTypeId);
                ps.setInt(3, floor);
                ps.setString(4, status);
                ps.setString(5, notes);
                ps.setInt(6, roomId);
                ps.executeUpdate();
                ps.close();
                successMessage = "Room '" + roomNumber + "' updated successfully!";
            }
            checkRs.close();
            checkPs.close();
        }

        // Delete Room
        if ("deleteRoom".equals(action)) {
            int roomId = Integer.parseInt(request.getParameter("roomId"));

            PreparedStatement checkPs = conn.prepareStatement("SELECT COUNT(*) FROM reservations WHERE room_id = ? AND status IN ('CONFIRMED', 'CHECKED_IN')");
            checkPs.setInt(1, roomId);
            ResultSet checkRs = checkPs.executeQuery();
            checkRs.next();
            int activeReservations = checkRs.getInt(1);
            checkRs.close();
            checkPs.close();

            if (activeReservations > 0) {
                errorMessage = "Cannot delete room with active reservations.";
            } else {
                PreparedStatement ps = conn.prepareStatement("DELETE FROM rooms WHERE room_id = ?");
                ps.setInt(1, roomId);
                ps.executeUpdate();
                ps.close();
                successMessage = "Room deleted successfully!";
            }
        }

        boolean redirectAfterAction =
            ("addRoom".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) ||
            ("editRoom".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) ||
            "deleteRoom".equals(action);
        if (redirectAfterAction) {
            if (successMessage != null) session.setAttribute("roomsSuccessMessage", successMessage);
            if (errorMessage != null) session.setAttribute("roomsErrorMessage", errorMessage);
            if (conn != null) { try { conn.close(); } catch (Exception ignore) {} }
            response.sendRedirect(request.getContextPath() + "/admin/admin-rooms.jsp");
            return;
        }

        // Get statistics
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM rooms");
        if (rs.next()) totalRooms = rs.getInt(1);
        rs.close();

        rs = stmt.executeQuery("SELECT COUNT(*) FROM rooms WHERE status = 'AVAILABLE'");
        if (rs.next()) availableRooms = rs.getInt(1);
        rs.close();

        rs = stmt.executeQuery("SELECT COUNT(*) FROM rooms WHERE status = 'OCCUPIED'");
        if (rs.next()) occupiedRooms = rs.getInt(1);
        rs.close();

        rs = stmt.executeQuery("SELECT COUNT(*) FROM rooms WHERE status = 'MAINTENANCE'");
        if (rs.next()) maintenanceRooms = rs.getInt(1);
        rs.close();
        stmt.close();
    } catch (Exception e) {
        errorMessage = "Error: " + e.getMessage();
        e.printStackTrace();
    }
%>
                            <!DOCTYPE html>
                            <html lang="en">

                            <head>
                                <meta charset="UTF-8">
                                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                                <title>Room Management - Ocean View Resort Admin</title>
                                <link rel="preconnect" href="https://fonts.googleapis.com">
                                <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
                                <link
                                    href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap"
                                    rel="stylesheet">
                                <link rel="stylesheet"
                                    href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
                                <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
                                <style>
                                    :root {
                                        --primary: #008080;
                                        --primary-dark: #004040;
                                        --glow: #00C0C0;
                                        --bg: #f5f7fa;
                                        --card-bg: #ffffff;
                                        --text: #333333;
                                        --text-light: #666666;
                                        --border: #e0e0e0;
                                        --success: #28a745;
                                        --danger: #dc3545;
                                        --warning: #ffc107;
                                        --info: #17a2b8;
                                    }

                                    * {
                                        margin: 0;
                                        padding: 0;
                                        box-sizing: border-box;
                                    }

                                    body {
                                        font-family: 'Poppins', sans-serif;
                                        background: var(--bg);
                                        min-height: 100vh;
                                        color: var(--text);
                                    }

                                    /* Header */
                                    .header {
                                        background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
                                        color: white;
                                        padding: 20px 40px;
                                        display: flex;
                                        justify-content: space-between;
                                        align-items: center;
                                        box-shadow: 0 4px 20px rgba(0, 64, 64, 0.3);
                                        position: sticky;
                                        top: 0;
                                        z-index: 100;
                                    }

                                    .header-left {
                                        display: flex;
                                        align-items: center;
                                        gap: 20px;
                                    }

                                    .header-left h1 {
                                        font-size: 24px;
                                        font-weight: 600;
                                    }

                                    .header-left h1 i {
                                        margin-right: 10px;
                                    }

                                    .header-actions {
                                        display: flex;
                                        gap: 15px;
                                    }

                                    .btn {
                                        padding: 12px 25px;
                                        border: none;
                                        border-radius: 10px;
                                        font-size: 14px;
                                        font-weight: 600;
                                        cursor: pointer;
                                        font-family: 'Poppins', sans-serif;
                                        transition: all 0.3s ease;
                                        display: inline-flex;
                                        align-items: center;
                                        gap: 8px;
                                        text-decoration: none;
                                    }

                                    .btn-back {
                                        background: rgba(255, 255, 255, 0.2);
                                        color: white;
                                        border: 1px solid rgba(255, 255, 255, 0.3);
                                    }

                                    .btn-back:hover {
                                        background: rgba(255, 255, 255, 0.3);
                                        transform: translateY(-2px);
                                    }

                                    .btn-add {
                                        background: var(--glow);
                                        color: var(--primary-dark);
                                    }

                                    .btn-add:hover {
                                        background: #00e6e6;
                                        transform: translateY(-2px);
                                        box-shadow: 0 8px 25px rgba(0, 192, 192, 0.4);
                                    }

                                    /* Main Content */
                                    .main-content {
                                        max-width: 1400px;
                                        margin: 30px auto;
                                        padding: 0 20px;
                                    }

                                    /* Stats Cards */
                                    .stats-grid {
                                        display: grid;
                                        grid-template-columns: repeat(4, 1fr);
                                        gap: 20px;
                                        margin-bottom: 30px;
                                    }

                                    @media (max-width: 900px) {
                                        .stats-grid {
                                            grid-template-columns: repeat(2, 1fr);
                                        }
                                    }

                                    @media (max-width: 500px) {
                                        .stats-grid {
                                            grid-template-columns: 1fr;
                                        }
                                    }

                                    .stat-card {
                                        background: var(--card-bg);
                                        border-radius: 15px;
                                        padding: 25px;
                                        box-shadow: 0 5px 20px rgba(0, 0, 0, 0.08);
                                        display: flex;
                                        align-items: center;
                                        gap: 20px;
                                        transition: transform 0.3s ease;
                                    }

                                    .stat-card:hover {
                                        transform: translateY(-5px);
                                    }

                                    .stat-icon {
                                        width: 60px;
                                        height: 60px;
                                        border-radius: 15px;
                                        display: flex;
                                        align-items: center;
                                        justify-content: center;
                                        font-size: 24px;
                                    }

                                    .stat-icon.total {
                                        background: linear-gradient(135deg, var(--primary-dark), var(--primary));
                                        color: white;
                                    }

                                    .stat-icon.available {
                                        background: linear-gradient(135deg, #1e7e34, var(--success));
                                        color: white;
                                    }

                                    .stat-icon.occupied {
                                        background: linear-gradient(135deg, #0062cc, var(--info));
                                        color: white;
                                    }

                                    .stat-icon.maintenance {
                                        background: linear-gradient(135deg, #d39e00, var(--warning));
                                        color: #333;
                                    }

                                    .stat-info h3 {
                                        font-size: 28px;
                                        font-weight: 700;
                                        color: var(--text);
                                    }

                                    .stat-info p {
                                        font-size: 14px;
                                        color: var(--text-light);
                                    }

                                    /* Filters */
                                    .filters-section {
                                        background: var(--card-bg);
                                        border-radius: 15px;
                                        padding: 20px 25px;
                                        margin-bottom: 25px;
                                        box-shadow: 0 5px 20px rgba(0, 0, 0, 0.08);
                                        display: flex;
                                        flex-wrap: wrap;
                                        gap: 15px;
                                        align-items: center;
                                    }

                                    .search-box {
                                        flex: 1;
                                        min-width: 250px;
                                        position: relative;
                                    }

                                    .search-box i {
                                        position: absolute;
                                        left: 15px;
                                        top: 50%;
                                        transform: translateY(-50%);
                                        color: var(--primary);
                                    }

                                    .search-box input {
                                        width: 100%;
                                        padding: 12px 15px 12px 45px;
                                        border: 2px solid var(--border);
                                        border-radius: 10px;
                                        font-size: 14px;
                                        font-family: 'Poppins', sans-serif;
                                        transition: all 0.3s ease;
                                    }

                                    .search-box input:focus {
                                        outline: none;
                                        border-color: var(--primary);
                                        box-shadow: 0 0 0 4px rgba(0, 128, 128, 0.1);
                                    }

                                    .filter-select {
                                        padding: 12px 20px;
                                        border: 2px solid var(--border);
                                        border-radius: 10px;
                                        font-size: 14px;
                                        font-family: 'Poppins', sans-serif;
                                        cursor: pointer;
                                        min-width: 150px;
                                    }

                                    .filter-select:focus {
                                        outline: none;
                                        border-color: var(--primary);
                                    }

                                    .view-toggle {
                                        display: flex;
                                        background: var(--bg);
                                        border-radius: 10px;
                                        padding: 5px;
                                    }

                                    .view-btn {
                                        padding: 10px 15px;
                                        border: none;
                                        background: transparent;
                                        cursor: pointer;
                                        border-radius: 8px;
                                        color: var(--text-light);
                                        transition: all 0.3s ease;
                                    }

                                    .view-btn.active {
                                        background: var(--primary);
                                        color: white;
                                    }

                                    /* Room Cards Grid */
                                    .rooms-grid {
                                        display: grid;
                                        grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
                                        gap: 25px;
                                    }

                                    .room-card {
                                        background: var(--card-bg);
                                        border-radius: 15px;
                                        overflow: hidden;
                                        box-shadow: 0 5px 20px rgba(0, 0, 0, 0.08);
                                        transition: all 0.3s ease;
                                    }

                                    .room-card:hover {
                                        transform: translateY(-8px);
                                        box-shadow: 0 15px 40px rgba(0, 0, 0, 0.15);
                                    }

                                    .room-image {
                                        height: 200px;
                                        background: linear-gradient(135deg, var(--primary-dark), var(--primary));
                                        position: relative;
                                        overflow: hidden;
                                    }

                                    .room-image img {
                                        width: 100%;
                                        height: 100%;
                                        object-fit: cover;
                                    }

                                    .room-image .no-image {
                                        display: flex;
                                        flex-direction: column;
                                        align-items: center;
                                        justify-content: center;
                                        height: 100%;
                                        color: rgba(255, 255, 255, 0.7);
                                    }

                                    .room-image .no-image i {
                                        font-size: 50px;
                                        margin-bottom: 10px;
                                    }

                                    .room-status-badge {
                                        position: absolute;
                                        top: 15px;
                                        right: 15px;
                                        padding: 6px 15px;
                                        border-radius: 20px;
                                        font-size: 12px;
                                        font-weight: 600;
                                        text-transform: uppercase;
                                    }

                                    .room-status-badge.available {
                                        background: var(--success);
                                        color: white;
                                    }

                                    .room-status-badge.occupied {
                                        background: var(--info);
                                        color: white;
                                    }

                                    .room-status-badge.maintenance {
                                        background: var(--warning);
                                        color: #333;
                                    }

                                    .room-number-badge {
                                        position: absolute;
                                        top: 15px;
                                        left: 15px;
                                        background: rgba(0, 0, 0, 0.7);
                                        color: white;
                                        padding: 8px 15px;
                                        border-radius: 10px;
                                        font-weight: 600;
                                    }

                                    .room-details {
                                        padding: 20px;
                                    }

                                    .room-type {
                                        font-size: 18px;
                                        font-weight: 600;
                                        color: var(--text);
                                        margin-bottom: 5px;
                                    }

                                    .room-floor {
                                        font-size: 13px;
                                        color: var(--text-light);
                                        margin-bottom: 15px;
                                    }

                                    .room-price {
                                        font-size: 22px;
                                        font-weight: 700;
                                        color: var(--primary);
                                        margin-bottom: 15px;
                                    }

                                    .room-price span {
                                        font-size: 14px;
                                        font-weight: 400;
                                        color: var(--text-light);
                                    }

                                    .room-facilities {
                                        display: flex;
                                        flex-wrap: wrap;
                                        gap: 8px;
                                        margin-bottom: 15px;
                                    }

                                    .facility-tag {
                                        background: var(--bg);
                                        padding: 5px 12px;
                                        border-radius: 15px;
                                        font-size: 12px;
                                        color: var(--text-light);
                                        display: flex;
                                        align-items: center;
                                        gap: 5px;
                                    }

                                    .facility-tag i {
                                        color: var(--primary);
                                        font-size: 11px;
                                    }

                                    .room-description {
                                        font-size: 13px;
                                        color: var(--text-light);
                                        line-height: 1.6;
                                        margin-bottom: 15px;
                                        display: -webkit-box;
                                        -webkit-line-clamp: 2;
                                        -webkit-box-orient: vertical;
                                        overflow: hidden;
                                    }

                                    .room-actions {
                                        display: flex;
                                        gap: 10px;
                                        padding-top: 15px;
                                        border-top: 1px solid var(--border);
                                    }

                                    .room-actions .btn {
                                        flex: 1;
                                        justify-content: center;
                                        padding: 10px;
                                        font-size: 13px;
                                    }

                                    .btn-view {
                                        background: var(--bg);
                                        color: var(--text);
                                    }

                                    .btn-view:hover {
                                        background: #e0e0e0;
                                    }

                                    .btn-edit {
                                        background: var(--primary);
                                        color: white;
                                    }

                                    .btn-edit:hover {
                                        background: var(--primary-dark);
                                    }

                                    .btn-delete {
                                        background: var(--danger);
                                        color: white;
                                    }

                                    .btn-delete:hover {
                                        background: #c82333;
                                    }

                                    /* Table View */
                                    .rooms-table {
                                        display: none;
                                        background: var(--card-bg);
                                        border-radius: 15px;
                                        overflow: hidden;
                                        box-shadow: 0 5px 20px rgba(0, 0, 0, 0.08);
                                    }

                                    .rooms-table.active {
                                        display: block;
                                    }

                                    .rooms-grid.hidden {
                                        display: none;
                                    }

                                    .data-table {
                                        width: 100%;
                                        border-collapse: collapse;
                                    }

                                    .data-table th {
                                        background: linear-gradient(135deg, var(--primary-dark), var(--primary));
                                        color: white;
                                        padding: 15px 20px;
                                        text-align: left;
                                        font-weight: 600;
                                        font-size: 14px;
                                    }

                                    .data-table td {
                                        padding: 15px 20px;
                                        border-bottom: 1px solid var(--border);
                                        font-size: 14px;
                                    }

                                    .data-table tr:hover {
                                        background: var(--bg);
                                    }

                                    .table-room-img {
                                        width: 60px;
                                        height: 45px;
                                        border-radius: 8px;
                                        object-fit: cover;
                                    }

                                    .table-room-no-img {
                                        width: 60px;
                                        height: 45px;
                                        border-radius: 8px;
                                        background: var(--bg);
                                        display: flex;
                                        align-items: center;
                                        justify-content: center;
                                        color: var(--text-light);
                                    }

                                    .status-badge {
                                        padding: 5px 12px;
                                        border-radius: 15px;
                                        font-size: 12px;
                                        font-weight: 600;
                                    }

                                    .status-badge.available {
                                        background: #d4edda;
                                        color: #155724;
                                    }

                                    .status-badge.occupied {
                                        background: #cce5ff;
                                        color: #004085;
                                    }

                                    .status-badge.maintenance {
                                        background: #fff3cd;
                                        color: #856404;
                                    }

                                    .action-btns {
                                        display: flex;
                                        gap: 8px;
                                    }

                                    .action-btn {
                                        width: 35px;
                                        height: 35px;
                                        border: none;
                                        border-radius: 8px;
                                        cursor: pointer;
                                        display: flex;
                                        align-items: center;
                                        justify-content: center;
                                        transition: all 0.3s ease;
                                    }

                                    .action-btn.view {
                                        background: var(--bg);
                                        color: var(--text);
                                    }

                                    .action-btn.edit {
                                        background: var(--primary);
                                        color: white;
                                    }

                                    .action-btn.delete {
                                        background: var(--danger);
                                        color: white;
                                    }

                                    .action-btn:hover {
                                        transform: scale(1.1);
                                    }

                                    /* Modal */
                                    .modal-overlay {
                                        display: none;
                                        position: fixed;
                                        top: 0;
                                        left: 0;
                                        right: 0;
                                        bottom: 0;
                                        background: rgba(0, 0, 0, 0.6);
                                        z-index: 1000;
                                        align-items: center;
                                        justify-content: center;
                                        padding: 20px;
                                    }

                                    .modal-overlay.active {
                                        display: flex;
                                    }

                                    .modal {
                                        background: var(--card-bg);
                                        border-radius: 20px;
                                        width: 100%;
                                        max-width: 700px;
                                        max-height: 90vh;
                                        overflow: hidden;
                                        animation: modalSlideIn 0.3s ease;
                                    }

                                    @keyframes modalSlideIn {
                                        from {
                                            opacity: 0;
                                            transform: translateY(-30px);
                                        }

                                        to {
                                            opacity: 1;
                                            transform: translateY(0);
                                        }
                                    }

                                    .modal-header {
                                        background: linear-gradient(135deg, var(--primary-dark), var(--primary));
                                        color: white;
                                        padding: 20px 25px;
                                        display: flex;
                                        justify-content: space-between;
                                        align-items: center;
                                    }

                                    .modal-header h3 {
                                        font-size: 20px;
                                        display: flex;
                                        align-items: center;
                                        gap: 10px;
                                    }

                                    .modal-close {
                                        width: 35px;
                                        height: 35px;
                                        border: none;
                                        background: rgba(255, 255, 255, 0.2);
                                        color: white;
                                        border-radius: 50%;
                                        cursor: pointer;
                                        font-size: 20px;
                                        display: flex;
                                        align-items: center;
                                        justify-content: center;
                                        transition: all 0.3s ease;
                                    }

                                    .modal-close:hover {
                                        background: rgba(255, 255, 255, 0.3);
                                        transform: rotate(90deg);
                                    }

                                    .modal-body {
                                        padding: 25px;
                                        max-height: 60vh;
                                        overflow-y: auto;
                                    }

                                    .modal-footer {
                                        padding: 20px 25px;
                                        border-top: 1px solid var(--border);
                                        display: flex;
                                        justify-content: flex-end;
                                        gap: 15px;
                                    }

                                    /* Form Styles */
                                    .form-grid {
                                        display: grid;
                                        grid-template-columns: repeat(2, 1fr);
                                        gap: 20px;
                                    }

                                    @media (max-width: 600px) {
                                        .form-grid {
                                            grid-template-columns: 1fr;
                                        }
                                    }

                                    .form-group {
                                        margin-bottom: 0;
                                    }

                                    .form-group.full-width {
                                        grid-column: 1 / -1;
                                    }

                                    .form-group label {
                                        display: block;
                                        margin-bottom: 8px;
                                        font-weight: 500;
                                        color: var(--text);
                                        font-size: 14px;
                                    }

                                    .form-group label i {
                                        margin-right: 8px;
                                        color: var(--primary);
                                    }

                                    .form-control {
                                        width: 100%;
                                        padding: 12px 15px;
                                        border: 2px solid var(--border);
                                        border-radius: 10px;
                                        font-size: 14px;
                                        font-family: 'Poppins', sans-serif;
                                        transition: all 0.3s ease;
                                        background: #fafafa;
                                    }

                                    .form-control:focus {
                                        outline: none;
                                        border-color: var(--primary);
                                        background: white;
                                        box-shadow: 0 0 0 4px rgba(0, 128, 128, 0.1);
                                    }

                                    textarea.form-control {
                                        min-height: 100px;
                                        resize: vertical;
                                    }

                                    .btn-primary {
                                        background: linear-gradient(135deg, var(--primary-dark), var(--primary));
                                        color: white;
                                    }

                                    .btn-primary:hover {
                                        box-shadow: 0 8px 25px rgba(0, 128, 128, 0.4);
                                        transform: translateY(-2px);
                                    }

                                    .btn-secondary {
                                        background: #e0e0e0;
                                        color: var(--text);
                                    }

                                    .btn-secondary:hover {
                                        background: #d0d0d0;
                                    }

                                    /* Image Upload Area */
                                    .image-upload-container {
                                        width: 100%;
                                    }

                                    .image-upload-tabs {
                                        display: flex;
                                        gap: 0;
                                        margin-bottom: 15px;
                                    }

                                    .image-upload-tab {
                                        flex: 1;
                                        padding: 12px 15px;
                                        background: #f0f0f0;
                                        border: none;
                                        cursor: pointer;
                                        font-family: 'Poppins', sans-serif;
                                        font-size: 13px;
                                        font-weight: 500;
                                        display: flex;
                                        align-items: center;
                                        justify-content: center;
                                        gap: 8px;
                                        transition: all 0.3s ease;
                                    }

                                    .image-upload-tab:first-child {
                                        border-radius: 8px 0 0 8px;
                                    }

                                    .image-upload-tab:last-child {
                                        border-radius: 0 8px 8px 0;
                                    }

                                    .image-upload-tab.active {
                                        background: var(--primary);
                                        color: white;
                                    }

                                    .image-upload-tab:hover:not(.active) {
                                        background: #e0e0e0;
                                    }

                                    .upload-panel {
                                        display: none;
                                    }

                                    .upload-panel.active {
                                        display: block;
                                    }

                                    .image-dropzone {
                                        width: 100%;
                                        height: 180px;
                                        border: 2px dashed var(--border);
                                        border-radius: 12px;
                                        display: flex;
                                        flex-direction: column;
                                        align-items: center;
                                        justify-content: center;
                                        background: linear-gradient(135deg, #fafafa 0%, #f0f8f8 100%);
                                        cursor: pointer;
                                        transition: all 0.3s ease;
                                        position: relative;
                                        overflow: hidden;
                                    }

                                    .image-dropzone:hover,
                                    .image-dropzone.dragover {
                                        border-color: var(--primary);
                                        background: linear-gradient(135deg, #e8f5f5 0%, #d0f0f0 100%);
                                        transform: scale(1.01);
                                    }

                                    .image-dropzone.dragover {
                                        border-style: solid;
                                        box-shadow: 0 0 20px rgba(0, 128, 128, 0.3);
                                    }

                                    .image-dropzone input[type="file"] {
                                        position: absolute;
                                        width: 100%;
                                        height: 100%;
                                        opacity: 0;
                                        cursor: pointer;
                                    }

                                    .dropzone-content {
                                        text-align: center;
                                        z-index: 1;
                                        pointer-events: none;
                                    }

                                    .dropzone-content i {
                                        font-size: 48px;
                                        color: var(--primary);
                                        margin-bottom: 10px;
                                    }

                                    .dropzone-content h4 {
                                        color: var(--text);
                                        margin-bottom: 5px;
                                        font-weight: 500;
                                    }

                                    .dropzone-content p {
                                        color: var(--text-light);
                                        font-size: 13px;
                                    }

                                    .dropzone-content .upload-btn {
                                        display: inline-block;
                                        margin-top: 10px;
                                        padding: 8px 20px;
                                        background: var(--primary);
                                        color: white;
                                        border-radius: 20px;
                                        font-size: 13px;
                                        font-weight: 500;
                                    }

                                    /* Image Preview */
                                    .image-preview {
                                        width: 100%;
                                        height: 180px;
                                        border: 2px solid var(--border);
                                        border-radius: 12px;
                                        display: flex;
                                        flex-direction: column;
                                        align-items: center;
                                        justify-content: center;
                                        background: #fafafa;
                                        cursor: pointer;
                                        transition: all 0.3s ease;
                                        overflow: hidden;
                                        position: relative;
                                    }

                                    .image-preview:hover {
                                        border-color: var(--primary);
                                    }

                                    .image-preview img {
                                        width: 100%;
                                        height: 100%;
                                        object-fit: cover;
                                    }

                                    .image-preview .placeholder {
                                        text-align: center;
                                        color: var(--text-light);
                                    }

                                    .image-preview .placeholder i {
                                        font-size: 48px;
                                        margin-bottom: 10px;
                                        color: var(--primary);
                                        opacity: 0.5;
                                    }

                                    .image-preview-overlay {
                                        position: absolute;
                                        top: 0;
                                        left: 0;
                                        right: 0;
                                        bottom: 0;
                                        background: rgba(0, 64, 64, 0.8);
                                        display: flex;
                                        align-items: center;
                                        justify-content: center;
                                        gap: 10px;
                                        opacity: 0;
                                        transition: opacity 0.3s ease;
                                    }

                                    .image-preview:hover .image-preview-overlay {
                                        opacity: 1;
                                    }

                                    .preview-action-btn {
                                        width: 40px;
                                        height: 40px;
                                        border-radius: 50%;
                                        border: none;
                                        cursor: pointer;
                                        display: flex;
                                        align-items: center;
                                        justify-content: center;
                                        font-size: 16px;
                                        transition: transform 0.3s ease;
                                    }

                                    .preview-action-btn:hover {
                                        transform: scale(1.1);
                                    }

                                    .preview-action-btn.view {
                                        background: white;
                                        color: var(--primary);
                                    }

                                    .preview-action-btn.delete {
                                        background: #dc3545;
                                        color: white;
                                    }

                                    .upload-progress {
                                        width: 100%;
                                        height: 6px;
                                        background: #e0e0e0;
                                        border-radius: 3px;
                                        margin-top: 15px;
                                        overflow: hidden;
                                        display: none;
                                    }

                                    .upload-progress.active {
                                        display: block;
                                    }

                                    .upload-progress-bar {
                                        height: 100%;
                                        background: linear-gradient(90deg, var(--primary) 0%, var(--glow) 100%);
                                        border-radius: 3px;
                                        width: 0%;
                                        transition: width 0.3s ease;
                                    }

                                    .upload-status {
                                        font-size: 12px;
                                        color: var(--text-light);
                                        margin-top: 8px;
                                        display: flex;
                                        align-items: center;
                                        gap: 5px;
                                    }

                                    .upload-status.success {
                                        color: var(--success);
                                    }

                                    .upload-status.error {
                                        color: var(--danger);
                                    }

                                    /* Facilities Checkboxes */
                                    .facilities-grid {
                                        display: grid;
                                        grid-template-columns: repeat(3, 1fr);
                                        gap: 10px;
                                    }

                                    @media (max-width: 600px) {
                                        .facilities-grid {
                                            grid-template-columns: repeat(2, 1fr);
                                        }
                                    }

                                    .facility-checkbox {
                                        display: flex;
                                        align-items: center;
                                        gap: 8px;
                                        padding: 10px;
                                        background: #fafafa;
                                        border-radius: 8px;
                                        cursor: pointer;
                                        transition: all 0.3s ease;
                                    }

                                    .facility-checkbox:hover {
                                        background: #f0f8f8;
                                    }

                                    .facility-checkbox input {
                                        width: 18px;
                                        height: 18px;
                                        accent-color: var(--primary);
                                    }

                                    .facility-checkbox span {
                                        font-size: 13px;
                                        color: var(--text);
                                    }

                                    /* View Modal */
                                    .view-room-image {
                                        width: 100%;
                                        height: 250px;
                                        border-radius: 12px;
                                        overflow: hidden;
                                        margin-bottom: 20px;
                                    }

                                    .view-room-image img {
                                        width: 100%;
                                        height: 100%;
                                        object-fit: cover;
                                    }

                                    .view-room-image .no-image {
                                        width: 100%;
                                        height: 100%;
                                        background: linear-gradient(135deg, var(--primary-dark), var(--primary));
                                        display: flex;
                                        flex-direction: column;
                                        align-items: center;
                                        justify-content: center;
                                        color: rgba(255, 255, 255, 0.7);
                                    }

                                    .view-room-image .no-image i {
                                        font-size: 60px;
                                        margin-bottom: 10px;
                                    }

                                    .view-info-grid {
                                        display: grid;
                                        grid-template-columns: repeat(2, 1fr);
                                        gap: 15px;
                                    }

                                    .view-info-item {
                                        background: var(--bg);
                                        padding: 15px;
                                        border-radius: 10px;
                                        border-left: 4px solid var(--primary);
                                    }

                                    .view-info-label {
                                        font-size: 12px;
                                        color: var(--text-light);
                                        text-transform: uppercase;
                                        margin-bottom: 5px;
                                    }

                                    .view-info-value {
                                        font-size: 15px;
                                        font-weight: 500;
                                        color: var(--text);
                                    }

                                    .view-description {
                                        background: var(--bg);
                                        padding: 15px;
                                        border-radius: 10px;
                                        margin-top: 15px;
                                    }

                                    .view-description h4 {
                                        font-size: 14px;
                                        color: var(--primary-dark);
                                        margin-bottom: 10px;
                                    }

                                    .view-description p {
                                        font-size: 14px;
                                        color: var(--text-light);
                                        line-height: 1.6;
                                    }

                                    .view-facilities {
                                        margin-top: 15px;
                                    }

                                    .view-facilities h4 {
                                        font-size: 14px;
                                        color: var(--primary-dark);
                                        margin-bottom: 10px;
                                    }

                                    /* Alert */
                                    .alert {
                                        padding: 15px 20px;
                                        border-radius: 10px;
                                        margin-bottom: 20px;
                                        display: flex;
                                        align-items: center;
                                        gap: 12px;
                                    }

                                    .alert-success {
                                        background: #d4edda;
                                        color: #155724;
                                        border: 1px solid #c3e6cb;
                                    }

                                    .alert-danger {
                                        background: #f8d7da;
                                        color: #721c24;
                                        border: 1px solid #f5c6cb;
                                    }

                                    /* Empty State */
                                    .empty-state {
                                        text-align: center;
                                        padding: 60px 20px;
                                        color: var(--text-light);
                                    }

                                    .empty-state i {
                                        font-size: 80px;
                                        color: var(--border);
                                        margin-bottom: 20px;
                                    }

                                    .empty-state h3 {
                                        font-size: 24px;
                                        color: var(--text);
                                        margin-bottom: 10px;
                                    }

                                    .empty-state p {
                                        margin-bottom: 25px;
                                    }
                                </style>
                            </head>

                            <body>
                                <!-- Header -->
                                <div class="header">
                                    <div class="header-left">
                                        <h1><i class="fas fa-bed"></i> Room Management</h1>
                                    </div>
                                    <div class="header-actions">
                                        <button class="btn btn-add" onclick="openAddModal()">
                                            <i class="fas fa-plus"></i> Add New Room
                                        </button>
                                        <a href="<%= request.getContextPath() %>/admin/admin-dashboard.jsp"
                                            class="btn btn-back">
                                            <i class="fas fa-arrow-left"></i> Back to Dashboard
                                        </a>
                                    </div>
                                </div>

                                <!-- Main Content -->
                                <div class="main-content">
                                    <% if (successMessage !=null) { %>
                                        <div class="alert alert-success">
                                            <i class="fas fa-check-circle"></i>
                                            <%= successMessage %>
                                        </div>
                                        <% } %>

                                            <% if (errorMessage !=null) { %>
                                                <div class="alert alert-danger">
                                                    <i class="fas fa-exclamation-circle"></i>
                                                    <%= errorMessage %>
                                                </div>
                                                <% } %>

                                                    <!-- Stats Cards -->
                                                    <div class="stats-grid">
                                                        <div class="stat-card">
                                                            <div class="stat-icon total"><i class="fas fa-bed"></i>
                                                            </div>
                                                            <div class="stat-info">
                                                                <h3>
                                                                    <%= totalRooms %>
                                                                </h3>
                                                                <p>Total Rooms</p>
                                                            </div>
                                                        </div>
                                                        <div class="stat-card">
                                                            <div class="stat-icon available"><i
                                                                    class="fas fa-check-circle"></i></div>
                                                            <div class="stat-info">
                                                                <h3>
                                                                    <%= availableRooms %>
                                                                </h3>
                                                                <p>Available</p>
                                                            </div>
                                                        </div>
                                                        <div class="stat-card">
                                                            <div class="stat-icon occupied"><i
                                                                    class="fas fa-user-check"></i></div>
                                                            <div class="stat-info">
                                                                <h3>
                                                                    <%= occupiedRooms %>
                                                                </h3>
                                                                <p>Occupied</p>
                                                            </div>
                                                        </div>
                                                        <div class="stat-card">
                                                            <div class="stat-icon maintenance"><i
                                                                    class="fas fa-tools"></i></div>
                                                            <div class="stat-info">
                                                                <h3>
                                                                    <%= maintenanceRooms %>
                                                                </h3>
                                                                <p>Maintenance</p>
                                                            </div>
                                                        </div>
                                                    </div>

                                                    <!-- Filters -->
                                                    <div class="filters-section">
                                                        <div class="search-box">
                                                            <i class="fas fa-search"></i>
                                                            <input type="text" id="searchInput"
                                                                placeholder="Search rooms by number, type..."
                                                                onkeyup="filterRooms()">
                                                        </div>
                                                        <select class="filter-select" id="statusFilter"
                                                            onchange="filterRooms()">
                                                            <option value="">All Status</option>
                                                            <option value="AVAILABLE">Available</option>
                                                            <option value="OCCUPIED">Occupied</option>
                                                            <option value="MAINTENANCE">Maintenance</option>
                                                        </select>
                                                        <select class="filter-select" id="typeFilter"
                                                            onchange="filterRooms()">
                                                            <option value="">All Types</option>
                                                            <% try { Statement rtStmt=conn.createStatement(); ResultSet rtRs=rtStmt.executeQuery("SELECT room_type_id, type_name FROM room_types ORDER BY type_name"); while (rtRs.next()) { %>
                                                                <option value="<%= rtRs.getString("type_name") %>"><%=
                                                                        rtRs.getString("type_name") %>
                                                                </option>
                                                                <% } rtRs.close(); rtStmt.close(); } catch (Exception e)
                                                                    {} %>
                                                        </select>
                                                        <div class="view-toggle">
                                                            <button class="view-btn active" id="gridViewBtn"
                                                                onclick="switchView('grid')"><i
                                                                    class="fas fa-th-large"></i></button>
                                                            <button class="view-btn" id="tableViewBtn"
                                                                onclick="switchView('table')"><i
                                                                    class="fas fa-list"></i></button>
                                                        </div>
                                                    </div>

                                                    <!-- Room Cards Grid View -->
                                                    <div class="rooms-grid" id="roomsGrid">
                                                        <% try { Statement roomStmt=conn.createStatement(); ResultSet
                                                            roomRs=roomStmt.executeQuery( "SELECT r.room_id, r.room_number, r.room_type_id, r.floor_number AS floor, r.status, r.notes, "
                                                            + "rt.type_name, rt.rate_per_night, rt.max_occupancy, rt.description AS type_description, rt.amenities AS type_amenities "
                                                            + "FROM rooms r JOIN room_types rt ON r.room_type_id = rt.room_type_id "
                                                            + "ORDER BY r.room_number" ); boolean hasRooms=false; while
                                                            (roomRs.next()) { hasRooms=true; int
                                                            roomId=roomRs.getInt("room_id"); String
                                                            roomNumber=roomRs.getString("room_number"); String
                                                            typeName=roomRs.getString("type_name"); int
                                                            floor=roomRs.getInt("floor"); double
                                                            rate=roomRs.getDouble("rate_per_night"); String
                                                            status=roomRs.getString("status"); String
                                                            notes=roomRs.getString("notes"); String
                                                            description=roomDescription(notes,
                                                            roomRs.getString("type_description")); String
                                                            facilities=extractMeta(notes, "FAC" ); if
                                                            (facilities.isEmpty()) {
                                                            facilities=safe(roomRs.getString("type_amenities")); }
                                                            String imageUrl=extractMeta(notes, "IMG" ); int
                                                            maxOccupancy=roomRs.getInt("max_occupancy"); int
                                                            roomTypeId=roomRs.getInt("room_type_id"); String
                                                            statusClass=status.toLowerCase().replace("_", "-" );
                                                            DecimalFormat df=new DecimalFormat("#,###.00"); %>
                                                            <div class="room-card" data-room-number="<%= roomNumber %>"
                                                                data-type="<%= typeName %>" data-status="<%= status %>">
                                                                <div class="room-image">
                                                                    <% if (imageUrl !=null && !imageUrl.isEmpty()) { %>
                                                                        <img src="<%= imageUrl %>"
                                                                            alt="<%= roomNumber %>">
                                                                        <% } else { %>
                                                                            <div class="no-image">
                                                                                <i class="fas fa-bed"></i>
                                                                                <span>No Image</span>
                                                                            </div>
                                                                            <% } %>
                                                                                <span class="room-number-badge">Room <%=
                                                                                        roomNumber %></span>
                                                                                <span
                                                                                    class="room-status-badge <%= statusClass %>">
                                                                                    <%= status %>
                                                                                </span>
                                                                </div>
                                                                <div class="room-details">
                                                                    <div class="room-type">
                                                                        <%= typeName %>
                                                                    </div>
                                                                    <div class="room-floor"><i
                                                                            class="fas fa-layer-group"></i> Floor <%=
                                                                            floor %> | <i class="fas fa-users"></i> Max
                                                                            <%= maxOccupancy %> guests</div>
                                                                    <div class="room-price">LKR <%= df.format(rate) %>
                                                                            <span>/ night</span></div>

                                                                    <% if (facilities !=null && !facilities.isEmpty()) {
                                                                        %>
                                                                        <div class="room-facilities">
                                                                            <% String[]
                                                                                facilityList=facilities.split(","); int
                                                                                count=0; for (String f : facilityList) {
                                                                                if (count < 4) { %>
                                                                                <span class="facility-tag"><i
                                                                                        class="fas fa-check"></i>
                                                                                    <%= f.trim() %>
                                                                                </span>
                                                                                <% count++; } } if (facilityList.length>
                                                                                    4) {
                                                                                    %>
                                                                                    <span class="facility-tag">+<%=
                                                                                            facilityList.length - 4 %>
                                                                                            more</span>
                                                                                    <% } %>
                                                                        </div>
                                                                        <% } %>

                                                                            <% if (description !=null &&
                                                                                !description.isEmpty()) { %>
                                                                                <div class="room-description">
                                                                                    <%= description %>
                                                                                </div>
                                                                                <% } %>

                                                                                    <div class="room-actions">
                                                                                        <button class="btn btn-view"
                                                                                            onclick="viewRoom(<%= roomId %>, '<%= escapeJs(roomNumber) %>', '<%= escapeJs(typeName) %>', <%= floor %>, '<%= status %>', '<%= df.format(rate) %>', '<%= escapeJs(description) %>', '<%= escapeJs(facilities) %>', '<%= escapeJs(imageUrl) %>', <%= maxOccupancy %>)">
                                                                                            <i class="fas fa-eye"></i>
                                                                                            View
                                                                                        </button>
                                                                                        <button class="btn btn-edit"
                                                                                            onclick="editRoom(<%= roomId %>, '<%= escapeJs(roomNumber) %>', <%= roomTypeId %>, <%= floor %>, '<%= status %>', '<%= escapeJs(description) %>', '<%= escapeJs(facilities) %>', '<%= escapeJs(imageUrl) %>')">
                                                                                            <i class="fas fa-edit"></i>
                                                                                            Edit
                                                                                        </button>
                                                                                        <button class="btn btn-delete"
                                                                                            onclick="deleteRoom(<%= roomId %>, '<%= roomNumber %>')">
                                                                                            <i class="fas fa-trash"></i>
                                                                                        </button>
                                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <% } if (!hasRooms) { %>
                                                                <div class="empty-state" style="grid-column: 1 / -1;">
                                                                    <i class="fas fa-bed"></i>
                                                                    <h3>No Rooms Found</h3>
                                                                    <p>Start by adding your first room.</p>
                                                                    <button class="btn btn-primary"
                                                                        onclick="openAddModal()"><i
                                                                            class="fas fa-plus"></i> Add Room</button>
                                                                </div>
                                                                <% } roomRs.close(); roomStmt.close(); } catch (Exception e) { out.println("<div class='alert alert-danger'>Error loading rooms: " + e.getMessage() + "</div>"); } %>
                                </div>

                                <!-- Table View -->
                                <div class="rooms-table" id="roomsTable">
                                    <table class="data-table">
                                        <thead>
                                            <tr>
                                                <th>Image</th>
                                                <th>Room No</th>
                                                <th>Type</th>
                                                <th>Floor</th>
                                                <th>Rate/Night</th>
                                                <th>Status</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% try { Statement roomStmt2=conn.createStatement(); ResultSet
                                                roomRs2=roomStmt2.executeQuery( "SELECT r.room_id, r.room_number, r.room_type_id, r.floor_number AS floor, r.status, r.notes, "
                                                + "rt.type_name, rt.rate_per_night, rt.max_occupancy, rt.description AS type_description, rt.amenities AS type_amenities "
                                                + "FROM rooms r JOIN room_types rt ON r.room_type_id = rt.room_type_id "
                                                + "ORDER BY r.room_number" ); while (roomRs2.next()) { int
                                                roomId=roomRs2.getInt("room_id"); String
                                                roomNumber=roomRs2.getString("room_number"); String
                                                typeName=roomRs2.getString("type_name"); int
                                                floor=roomRs2.getInt("floor"); double
                                                rate=roomRs2.getDouble("rate_per_night"); String
                                                status=roomRs2.getString("status"); String
                                                notes=roomRs2.getString("notes"); String
                                                description=roomDescription(notes,
                                                roomRs2.getString("type_description")); String
                                                facilities=extractMeta(notes, "FAC" ); if (facilities.isEmpty()) {
                                                facilities=safe(roomRs2.getString("type_amenities")); } String
                                                imageUrl=extractMeta(notes, "IMG" ); int
                                                maxOccupancy=roomRs2.getInt("max_occupancy"); int
                                                roomTypeId=roomRs2.getInt("room_type_id"); String
                                                statusClass=status.toLowerCase().replace("_", "-" ); DecimalFormat
                                                df=new DecimalFormat("#,###.00"); %>
                                                <tr data-room-number="<%= roomNumber %>" data-type="<%= typeName %>"
                                                    data-status="<%= status %>">
                                                    <td>
                                                        <% if (imageUrl !=null && !imageUrl.isEmpty()) { %>
                                                            <img src="<%= imageUrl %>" class="table-room-img"
                                                                alt="<%= roomNumber %>">
                                                            <% } else { %>
                                                                <div class="table-room-no-img"><i
                                                                        class="fas fa-bed"></i></div>
                                                                <% } %>
                                                    </td>
                                                    <td><strong>
                                                            <%= roomNumber %>
                                                        </strong></td>
                                                    <td>
                                                        <%= typeName %>
                                                    </td>
                                                    <td>Floor <%= floor %>
                                                    </td>
                                                    <td>LKR <%= df.format(rate) %>
                                                    </td>
                                                    <td><span class="status-badge <%= statusClass %>">
                                                            <%= status %>
                                                        </span></td>
                                                    <td>
                                                        <div class="action-btns">
                                                            <button class="action-btn view"
                                                                onclick="viewRoom(<%= roomId %>, '<%= escapeJs(roomNumber) %>', '<%= escapeJs(typeName) %>', <%= floor %>, '<%= status %>', '<%= df.format(rate) %>', '<%= escapeJs(description) %>', '<%= escapeJs(facilities) %>', '<%= escapeJs(imageUrl) %>', <%= maxOccupancy %>)"><i
                                                                    class="fas fa-eye"></i></button>
                                                            <button class="action-btn edit"
                                                                onclick="editRoom(<%= roomId %>, '<%= escapeJs(roomNumber) %>', <%= roomTypeId %>, <%= floor %>, '<%= status %>', '<%= escapeJs(description) %>', '<%= escapeJs(facilities) %>', '<%= escapeJs(imageUrl) %>')"><i
                                                                    class="fas fa-edit"></i></button>
                                                            <button class="action-btn delete"
                                                                onclick="deleteRoom(<%= roomId %>, '<%= roomNumber %>')"><i
                                                                    class="fas fa-trash"></i></button>
                                                        </div>
                                                    </td>
                                                </tr>
                                                <% } roomRs2.close(); roomStmt2.close(); } catch (Exception e) {} %>
                                        </tbody>
                                    </table>
                                </div>
                                </div>

                                <!-- Add Room Modal -->
                                <div class="modal-overlay" id="addRoomModal">
                                    <div class="modal">
                                        <div class="modal-header">
                                            <h3><i class="fas fa-plus-circle"></i> Add New Room</h3>
                                            <button class="modal-close"
                                                onclick="closeModal('addRoomModal')">&times;</button>
                                        </div>
                                        <form method="POST"
                                            action="<%= request.getContextPath() %>/admin/admin-rooms.jsp">
                                            <input type="hidden" name="action" value="addRoom">
                                            <div class="modal-body">
                                                <div class="form-grid">
                                                    <div class="form-group">
                                                        <label><i class="fas fa-door-open"></i> Room Number *</label>
                                                        <input type="text" name="roomNumber" class="form-control"
                                                            placeholder="e.g., 101, A-201" required>
                                                    </div>
                                                    <div class="form-group">
                                                        <label><i class="fas fa-layer-group"></i> Room Type *</label>
                                                        <select name="roomTypeId" class="form-control" required>
                                                            <option value="">Select Type</option>
                                                            <% try { Statement rtStmt2=conn.createStatement(); ResultSet rtRs2=rtStmt2.executeQuery("SELECT room_type_id, type_name, rate_per_night FROM room_types ORDER BY type_name"); while (rtRs2.next()) { %>
                                                                <option value="<%= rtRs2.getInt("room_type_id") %>"><%= rtRs2.getString("type_name") %> - LKR <%= new DecimalFormat("#,###.00").format(rtRs2.getDouble("rate_per_night")) %>/night</option>
                                                                <% } rtRs2.close(); rtStmt2.close(); } catch (Exception e) {} %>
                                                        </select>
                                                    </div>
                                                    <div class="form-group">
                                                        <label><i class="fas fa-building"></i> Floor *</label>
                                                        <input type="number" name="floor" class="form-control" min="1"
                                                            max="50" placeholder="e.g., 1, 2, 3" required>
                                                    </div>
                                                    <div class="form-group">
                                                        <label><i class="fas fa-toggle-on"></i> Status *</label>
                                                        <select name="status" class="form-control" required>
                                                            <option value="AVAILABLE">Available</option>
                                                            <option value="OCCUPIED">Occupied</option>
                                                            <option value="MAINTENANCE">Maintenance</option>
                                                        </select>
                                                    </div>
                                                    <div class="form-group full-width">
                                                        <label><i class="fas fa-image"></i> Room Image</label>
                                                        <input type="hidden" name="imageUrl" id="addImageUrl">

                                                        <div class="image-upload-container">
                                                            <div class="image-upload-tabs">
                                                                <button type="button" class="image-upload-tab active"
                                                                    onclick="switchUploadTab('add', 'upload')">
                                                                    <i class="fas fa-cloud-upload-alt"></i> Upload Image
                                                                </button>
                                                                <button type="button" class="image-upload-tab"
                                                                    onclick="switchUploadTab('add', 'url')">
                                                                    <i class="fas fa-link"></i> Image URL
                                                                </button>
                                                            </div>

                                                            <!-- Upload Panel -->
                                                            <div class="upload-panel active" id="addUploadPanel">
                                                                <div class="image-dropzone" id="addDropzone"
                                                                    onclick="document.getElementById('addFileInput').click()">
                                                                    <input type="file" id="addFileInput"
                                                                        accept="image/*"
                                                                        onchange="uploadRoomImage('add', this)">
                                                                    <div class="dropzone-content">
                                                                        <i class="fas fa-cloud-upload-alt"></i>
                                                                        <h4>Drag & Drop Image Here</h4>
                                                                        <p>or click to browse files</p>
                                                                        <span class="upload-btn">Select Image</span>
                                                                    </div>
                                                                </div>
                                                                <div class="upload-progress" id="addUploadProgress">
                                                                    <div class="upload-progress-bar"
                                                                        id="addProgressBar"></div>
                                                                </div>
                                                                <div class="upload-status" id="addUploadStatus"></div>
                                                            </div>

                                                            <!-- URL Panel -->
                                                            <div class="upload-panel" id="addUrlPanel">
                                                                <input type="url" id="addImageUrlInput"
                                                                    class="form-control"
                                                                    placeholder="https://example.com/room-image.jpg"
                                                                    onchange="setImageFromUrl('add')">
                                                                <p
                                                                    style="font-size: 12px; color: #666; margin-top: 5px;">
                                                                    <i class="fas fa-info-circle"></i> Enter a valid
                                                                    image URL from the web</p>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div class="form-group full-width">
                                                        <label>Image Preview</label>
                                                        <div class="image-preview" id="addImagePreview">
                                                            <div class="placeholder">
                                                                <i class="fas fa-image"></i>
                                                                <p>Upload or enter URL to preview</p>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div class="form-group full-width">
                                                        <label><i class="fas fa-concierge-bell"></i> Facilities (comma
                                                            separated)</label>
                                                        <input type="text" name="facilities" class="form-control"
                                                            placeholder="WiFi, AC, TV, Mini Bar, Sea View, Balcony">
                                                    </div>
                                                    <div class="form-group full-width">
                                                        <label><i class="fas fa-align-left"></i> Description</label>
                                                        <textarea name="description" class="form-control"
                                                            placeholder="Room description and special features..."></textarea>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-secondary"
                                                    onclick="closeModal('addRoomModal')">Cancel</button>
                                                <button type="submit" class="btn btn-primary"><i
                                                        class="fas fa-save"></i> Add Room</button>
                                            </div>
                                        </form>
                                    </div>
                                </div>

                                <!-- Edit Room Modal -->
                                <div class="modal-overlay" id="editRoomModal">
                                    <div class="modal">
                                        <div class="modal-header">
                                            <h3><i class="fas fa-edit"></i> Edit Room</h3>
                                            <button class="modal-close"
                                                onclick="closeModal('editRoomModal')">&times;</button>
                                        </div>
                                        <form method="POST"
                                            action="<%= request.getContextPath() %>/admin/admin-rooms.jsp">
                                            <input type="hidden" name="action" value="editRoom">
                                            <input type="hidden" name="roomId" id="editRoomId">
                                            <div class="modal-body">
                                                <div class="form-grid">
                                                    <div class="form-group">
                                                        <label><i class="fas fa-door-open"></i> Room Number *</label>
                                                        <input type="text" name="roomNumber" id="editRoomNumber"
                                                            class="form-control" required>
                                                    </div>
                                                    <div class="form-group">
                                                        <label><i class="fas fa-layer-group"></i> Room Type *</label>
                                                        <select name="roomTypeId" id="editRoomTypeId"
                                                            class="form-control" required>
                                                            <option value="">Select Type</option>
                                                            <% try { Statement rtStmt3=conn.createStatement(); ResultSet rtRs3=rtStmt3.executeQuery("SELECT room_type_id, type_name, rate_per_night FROM room_types ORDER BY type_name"); while (rtRs3.next()) { %>
                                                                <option value="<%= rtRs3.getInt("room_type_id") %>"><%= rtRs3.getString("type_name") %> - LKR <%= new DecimalFormat("#,###.00").format(rtRs3.getDouble("rate_per_night")) %>/night</option>
                                                                <% } rtRs3.close(); rtStmt3.close(); } catch (Exception e) {} %>
                                                        </select>
                                                    </div>
                                                    <div class="form-group">
                                                        <label><i class="fas fa-building"></i> Floor *</label>
                                                        <input type="number" name="floor" id="editFloor"
                                                            class="form-control" min="1" max="50" required>
                                                    </div>
                                                    <div class="form-group">
                                                        <label><i class="fas fa-toggle-on"></i> Status *</label>
                                                        <select name="status" id="editStatus" class="form-control"
                                                            required>
                                                            <option value="AVAILABLE">Available</option>
                                                            <option value="OCCUPIED">Occupied</option>
                                                            <option value="MAINTENANCE">Maintenance</option>
                                                        </select>
                                                    </div>
                                                    <div class="form-group full-width">
                                                        <label><i class="fas fa-image"></i> Room Image</label>
                                                        <input type="hidden" name="imageUrl" id="editImageUrl">

                                                        <div class="image-upload-container">
                                                            <div class="image-upload-tabs">
                                                                <button type="button" class="image-upload-tab active"
                                                                    onclick="switchUploadTab('edit', 'upload')">
                                                                    <i class="fas fa-cloud-upload-alt"></i> Upload Image
                                                                </button>
                                                                <button type="button" class="image-upload-tab"
                                                                    onclick="switchUploadTab('edit', 'url')">
                                                                    <i class="fas fa-link"></i> Image URL
                                                                </button>
                                                            </div>

                                                            <!-- Upload Panel -->
                                                            <div class="upload-panel active" id="editUploadPanel">
                                                                <div class="image-dropzone" id="editDropzone"
                                                                    onclick="document.getElementById('editFileInput').click()">
                                                                    <input type="file" id="editFileInput"
                                                                        accept="image/*"
                                                                        onchange="uploadRoomImage('edit', this)">
                                                                    <div class="dropzone-content">
                                                                        <i class="fas fa-cloud-upload-alt"></i>
                                                                        <h4>Drag & Drop Image Here</h4>
                                                                        <p>or click to browse files</p>
                                                                        <span class="upload-btn">Select Image</span>
                                                                    </div>
                                                                </div>
                                                                <div class="upload-progress" id="editUploadProgress">
                                                                    <div class="upload-progress-bar"
                                                                        id="editProgressBar"></div>
                                                                </div>
                                                                <div class="upload-status" id="editUploadStatus"></div>
                                                            </div>

                                                            <!-- URL Panel -->
                                                            <div class="upload-panel" id="editUrlPanel">
                                                                <input type="url" id="editImageUrlInput"
                                                                    class="form-control"
                                                                    placeholder="https://example.com/room-image.jpg"
                                                                    onchange="setImageFromUrl('edit')">
                                                                <p
                                                                    style="font-size: 12px; color: #666; margin-top: 5px;">
                                                                    <i class="fas fa-info-circle"></i> Enter a valid
                                                                    image URL from the web</p>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div class="form-group full-width">
                                                        <label>Image Preview</label>
                                                        <div class="image-preview" id="editImagePreview">
                                                            <div class="placeholder">
                                                                <i class="fas fa-image"></i>
                                                                <p>Upload or enter URL to preview</p>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div class="form-group full-width">
                                                        <label><i class="fas fa-concierge-bell"></i> Facilities (comma
                                                            separated)</label>
                                                        <input type="text" name="facilities" id="editFacilities"
                                                            class="form-control"
                                                            placeholder="WiFi, AC, TV, Mini Bar, Sea View, Balcony">
                                                    </div>
                                                    <div class="form-group full-width">
                                                        <label><i class="fas fa-align-left"></i> Description</label>
                                                        <textarea name="description" id="editDescription"
                                                            class="form-control"
                                                            placeholder="Room description..."></textarea>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-secondary"
                                                    onclick="closeModal('editRoomModal')">Cancel</button>
                                                <button type="submit" class="btn btn-primary"><i
                                                        class="fas fa-save"></i> Save Changes</button>
                                            </div>
                                        </form>
                                    </div>
                                </div>

                                <!-- View Room Modal -->
                                <div class="modal-overlay" id="viewRoomModal">
                                    <div class="modal">
                                        <div class="modal-header">
                                            <h3><i class="fas fa-eye"></i> Room Details</h3>
                                            <button class="modal-close"
                                                onclick="closeModal('viewRoomModal')">&times;</button>
                                        </div>
                                        <div class="modal-body">
                                            <div class="view-room-image" id="viewRoomImage"></div>
                                            <div class="view-info-grid">
                                                <div class="view-info-item">
                                                    <div class="view-info-label">Room Number</div>
                                                    <div class="view-info-value" id="viewRoomNumber"></div>
                                                </div>
                                                <div class="view-info-item">
                                                    <div class="view-info-label">Room Type</div>
                                                    <div class="view-info-value" id="viewRoomType"></div>
                                                </div>
                                                <div class="view-info-item">
                                                    <div class="view-info-label">Floor</div>
                                                    <div class="view-info-value" id="viewFloor"></div>
                                                </div>
                                                <div class="view-info-item">
                                                    <div class="view-info-label">Status</div>
                                                    <div class="view-info-value" id="viewStatus"></div>
                                                </div>
                                                <div class="view-info-item">
                                                    <div class="view-info-label">Rate per Night</div>
                                                    <div class="view-info-value" id="viewRate"></div>
                                                </div>
                                                <div class="view-info-item">
                                                    <div class="view-info-label">Max Occupancy</div>
                                                    <div class="view-info-value" id="viewOccupancy"></div>
                                                </div>
                                            </div>
                                            <div class="view-description" id="viewDescriptionSection">
                                                <h4><i class="fas fa-align-left"></i> Description</h4>
                                                <p id="viewDescription"></p>
                                            </div>
                                            <div class="view-facilities" id="viewFacilitiesSection">
                                                <h4><i class="fas fa-concierge-bell"></i> Facilities</h4>
                                                <div class="room-facilities" id="viewFacilities"></div>
                                            </div>
                                        </div>
                                        <div class="modal-footer">
                                            <button type="button" class="btn btn-secondary"
                                                onclick="closeModal('viewRoomModal')">Close</button>
                                        </div>
                                    </div>
                                </div>

                                <script>
                                    // Filter rooms
                                    function filterRooms() {
                                        const search = document.getElementById('searchInput').value.toLowerCase();
                                        const status = document.getElementById('statusFilter').value;
                                        const type = document.getElementById('typeFilter').value;

                                        // Filter grid cards
                                        document.querySelectorAll('.room-card').forEach(card => {
                                            const roomNumber = card.dataset.roomNumber.toLowerCase();
                                            const roomType = card.dataset.type;
                                            const roomStatus = card.dataset.status;

                                            const matchSearch = roomNumber.includes(search) || roomType.toLowerCase().includes(search);
                                            const matchStatus = !status || roomStatus === status;
                                            const matchType = !type || roomType === type;

                                            card.style.display = (matchSearch && matchStatus && matchType) ? 'block' : 'none';
                                        });

                                        // Filter table rows
                                        document.querySelectorAll('.data-table tbody tr').forEach(row => {
                                            const roomNumber = row.dataset.roomNumber.toLowerCase();
                                            const roomType = row.dataset.type;
                                            const roomStatus = row.dataset.status;

                                            const matchSearch = roomNumber.includes(search) || roomType.toLowerCase().includes(search);
                                            const matchStatus = !status || roomStatus === status;
                                            const matchType = !type || roomType === type;

                                            row.style.display = (matchSearch && matchStatus && matchType) ? '' : 'none';
                                        });
                                    }

                                    // Switch view
                                    function switchView(view) {
                                        const grid = document.getElementById('roomsGrid');
                                        const table = document.getElementById('roomsTable');
                                        const gridBtn = document.getElementById('gridViewBtn');
                                        const tableBtn = document.getElementById('tableViewBtn');

                                        if (view === 'grid') {
                                            grid.classList.remove('hidden');
                                            table.classList.remove('active');
                                            gridBtn.classList.add('active');
                                            tableBtn.classList.remove('active');
                                        } else {
                                            grid.classList.add('hidden');
                                            table.classList.add('active');
                                            gridBtn.classList.remove('active');
                                            tableBtn.classList.add('active');
                                        }
                                    }

                                    // Modal functions
                                    function openModal(id) {
                                        document.getElementById(id).classList.add('active');
                                    }

                                    function closeModal(id) {
                                        document.getElementById(id).classList.remove('active');
                                    }

                                    function openAddModal() {
                                        // Reset form
                                        document.querySelector('#addRoomModal form').reset();
                                        document.getElementById('addImageUrl').value = '';
                                        document.getElementById('addImagePreview').innerHTML = '<div class="placeholder"><i class="fas fa-image"></i><p>Upload or enter URL to preview</p></div>';
                                        document.getElementById('addUploadStatus').innerHTML = '';
                                        document.getElementById('addUploadProgress').classList.remove('active');
                                        switchUploadTab('add', 'upload');
                                        openModal('addRoomModal');
                                    }

                                    // Switch Upload Tab
                                    function switchUploadTab(prefix, tab) {
                                        const uploadTab = document.querySelector('#' + prefix + 'RoomModal .image-upload-tab:first-child');
                                        const urlTab = document.querySelector('#' + prefix + 'RoomModal .image-upload-tab:last-child');
                                        const uploadPanel = document.getElementById(prefix + 'UploadPanel');
                                        const urlPanel = document.getElementById(prefix + 'UrlPanel');

                                        if (tab === 'upload') {
                                            uploadTab.classList.add('active');
                                            urlTab.classList.remove('active');
                                            uploadPanel.classList.add('active');
                                            urlPanel.classList.remove('active');
                                        } else {
                                            uploadTab.classList.remove('active');
                                            urlTab.classList.add('active');
                                            uploadPanel.classList.remove('active');
                                            urlPanel.classList.add('active');
                                        }
                                    }

                                    // Upload room image
                                    function uploadRoomImage(prefix, input) {
                                        const file = input.files[0];
                                        if (!file) return;

                                        // Validate file type
                                        if (!file.type.startsWith('image/')) {
                                            Swal.fire({ icon: 'error', title: 'Invalid File', text: 'Please select an image file (JPG, PNG, GIF)', confirmButtonColor: '#008080' });
                                            return;
                                        }

                                        // Validate file size (max 5MB)
                                        if (file.size > 5 * 1024 * 1024) {
                                            Swal.fire({ icon: 'error', title: 'File Too Large', text: 'Maximum file size is 5MB', confirmButtonColor: '#008080' });
                                            return;
                                        }

                                        const progressEl = document.getElementById(prefix + 'UploadProgress');
                                        const progressBar = document.getElementById(prefix + 'ProgressBar');
                                        const statusEl = document.getElementById(prefix + 'UploadStatus');

                                        progressEl.classList.add('active');
                                        progressBar.style.width = '0%';
                                        statusEl.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Uploading...';
                                        statusEl.className = 'upload-status';

                                        prepareRoomImageData(file).then(function (imageData) {
                                            const payload =
                                                'action=' + encodeURIComponent('uploadRoomImage') +
                                                '&imageData=' + encodeURIComponent(imageData) +
                                                '&fileName=' + encodeURIComponent(file.name || 'room.jpg');

                                            const xhr = new XMLHttpRequest();
                                            progressBar.style.width = '40%';
                                            xhr.open('POST', '<%= request.getContextPath() %>/admin/admin-rooms.jsp', true);
                                            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');

                                            xhr.onload = function () {
                                                progressBar.style.width = '100%';
                                                if (xhr.status === 200) {
                                                    try {
                                                        const response = JSON.parse(xhr.responseText);
                                                        if (response.success) {
                                                            document.getElementById(prefix + 'ImageUrl').value = response.imageUrl;
                                                            document.getElementById(prefix + 'ImagePreview').innerHTML = '<img src="' + response.imageUrl + '"><div class="image-preview-overlay"><button type="button" class="preview-action-btn view" onclick="viewFullImage(\'' + response.imageUrl + '\')"><i class="fas fa-expand"></i></button><button type="button" class="preview-action-btn delete" onclick="removeImage(\'' + prefix + '\')"><i class="fas fa-trash"></i></button></div>';
                                                            statusEl.innerHTML = '<i class="fas fa-check-circle"></i> Image uploaded successfully!';
                                                            statusEl.className = 'upload-status success';
                                                        } else {
                                                            statusEl.innerHTML = '<i class="fas fa-times-circle"></i> ' + (response.message || 'Upload failed');
                                                            statusEl.className = 'upload-status error';
                                                        }
                                                    } catch (e) {
                                                        statusEl.innerHTML = '<i class="fas fa-times-circle"></i> Upload failed';
                                                        statusEl.className = 'upload-status error';
                                                    }
                                                } else {
                                                    statusEl.innerHTML = '<i class="fas fa-times-circle"></i> Upload failed';
                                                    statusEl.className = 'upload-status error';
                                                }
                                                progressEl.classList.remove('active');
                                            };

                                            xhr.onerror = function () {
                                                statusEl.innerHTML = '<i class="fas fa-times-circle"></i> Upload failed';
                                                statusEl.className = 'upload-status error';
                                                progressEl.classList.remove('active');
                                            };

                                            xhr.send(payload);
                                        }).catch(function () {
                                            statusEl.innerHTML = '<i class="fas fa-times-circle"></i> Invalid image file';
                                            statusEl.className = 'upload-status error';
                                            progressEl.classList.remove('active');
                                        });
                                    }

                                    function prepareRoomImageData(file) {
                                        return new Promise(function (resolve, reject) {
                                            const reader = new FileReader();
                                            reader.onload = function (e) {
                                                const src = e.target.result;
                                                const img = new Image();
                                                img.onload = function () {
                                                    const maxEdge = 1600;
                                                    let w = img.width;
                                                    let h = img.height;
                                                    if (w > h && w > maxEdge) {
                                                        h = Math.round((h * maxEdge) / w);
                                                        w = maxEdge;
                                                    } else if (h >= w && h > maxEdge) {
                                                        w = Math.round((w * maxEdge) / h);
                                                        h = maxEdge;
                                                    }
                                                    const canvas = document.createElement('canvas');
                                                    canvas.width = w;
                                                    canvas.height = h;
                                                    const ctx = canvas.getContext('2d');
                                                    if (!ctx) {
                                                        resolve(src);
                                                        return;
                                                    }
                                                    ctx.drawImage(img, 0, 0, w, h);
                                                    let quality = 0.9;
                                                    let out = canvas.toDataURL('image/jpeg', quality);
                                                    while (out.length > 1800000 && quality > 0.55) {
                                                        quality -= 0.1;
                                                        out = canvas.toDataURL('image/jpeg', quality);
                                                    }
                                                    resolve(out);
                                                };
                                                img.onerror = function () { reject(new Error('invalid-image')); };
                                                img.src = src;
                                            };
                                            reader.onerror = function () { reject(new Error('read-error')); };
                                            reader.readAsDataURL(file);
                                        });
                                    }

                                    // Set image from URL
                                    function setImageFromUrl(prefix) {
                                        const url = document.getElementById(prefix + 'ImageUrlInput').value;
                                        if (url) {
                                            document.getElementById(prefix + 'ImageUrl').value = url;
                                            document.getElementById(prefix + 'ImagePreview').innerHTML = '<img src="' + url + '" onerror="this.onerror=null; this.parentElement.innerHTML=\'<div class=placeholder><i class=fas fa-exclamation-triangle></i><p>Invalid image URL</p></div>\';"><div class="image-preview-overlay"><button type="button" class="preview-action-btn view" onclick="viewFullImage(\'' + url + '\')"><i class="fas fa-expand"></i></button><button type="button" class="preview-action-btn delete" onclick="removeImage(\'' + prefix + '\')"><i class="fas fa-trash"></i></button></div>';
                                        }
                                    }

                                    // Remove Image
                                    function removeImage(prefix) {
                                        document.getElementById(prefix + 'ImageUrl').value = '';
                                        document.getElementById(prefix + 'ImagePreview').innerHTML = '<div class="placeholder"><i class="fas fa-image"></i><p>Upload or enter URL to preview</p></div>';
                                        document.getElementById(prefix + 'FileInput').value = '';
                                        if (document.getElementById(prefix + 'ImageUrlInput')) {
                                            document.getElementById(prefix + 'ImageUrlInput').value = '';
                                        }
                                    }

                                    // View Full Image
                                    function viewFullImage(url) {
                                        Swal.fire({
                                            imageUrl: url,
                                            imageAlt: 'Room Image',
                                            showConfirmButton: false,
                                            showCloseButton: true,
                                            width: 'auto',
                                            background: 'transparent',
                                            backdrop: 'rgba(0,0,0,0.9)'
                                        });
                                    }

                                    // Setup drag and drop
                                    ['add', 'edit'].forEach(prefix => {
                                        const dropzone = document.getElementById(prefix + 'Dropzone');
                                        if (dropzone) {
                                            dropzone.addEventListener('dragover', function (e) {
                                                e.preventDefault();
                                                this.classList.add('dragover');
                                            });

                                            dropzone.addEventListener('dragleave', function (e) {
                                                e.preventDefault();
                                                this.classList.remove('dragover');
                                            });

                                            dropzone.addEventListener('drop', function (e) {
                                                e.preventDefault();
                                                this.classList.remove('dragover');

                                                const files = e.dataTransfer.files;
                                                if (files.length > 0) {
                                                    const input = document.getElementById(prefix + 'FileInput');
                                                    input.files = files;
                                                    uploadRoomImage(prefix, input);
                                                }
                                            });
                                        }
                                    });

                                    // Image preview (for backward compatibility)
                                    function previewImage(inputId, previewId) {
                                        const url = document.getElementById(inputId).value;
                                        const preview = document.getElementById(previewId);

                                        if (url) {
                                            preview.innerHTML = '<img src="' + url + '" onerror="this.onerror=null; this.parentElement.innerHTML=\'<div class=placeholder><i class=fas fa-exclamation-triangle></i><p>Invalid image URL</p></div>\';">';
                                        } else {
                                            preview.innerHTML = '<div class="placeholder"><i class="fas fa-image"></i><p>Upload or enter URL to preview</p></div>';
                                        }
                                    }

                                    // Edit room
                                    function editRoom(id, number, typeId, floor, status, description, facilities, imageUrl) {
                                        document.getElementById('editRoomId').value = id;
                                        document.getElementById('editRoomNumber').value = number;
                                        document.getElementById('editRoomTypeId').value = typeId;
                                        document.getElementById('editFloor').value = floor;
                                        document.getElementById('editStatus').value = status;
                                        document.getElementById('editDescription').value = description;
                                        document.getElementById('editFacilities').value = facilities;
                                        document.getElementById('editImageUrl').value = imageUrl;
                                        document.getElementById('editUploadStatus').innerHTML = '';
                                        document.getElementById('editUploadProgress').classList.remove('active');
                                        switchUploadTab('edit', 'upload');

                                        // Preview image
                                        if (imageUrl) {
                                            document.getElementById('editImagePreview').innerHTML = '<img src="' + imageUrl + '"><div class="image-preview-overlay"><button type="button" class="preview-action-btn view" onclick="viewFullImage(\'' + imageUrl + '\')"><i class="fas fa-expand"></i></button><button type="button" class="preview-action-btn delete" onclick="removeImage(\'edit\')"><i class="fas fa-trash"></i></button></div>';
                                        } else {
                                            document.getElementById('editImagePreview').innerHTML = '<div class="placeholder"><i class="fas fa-image"></i><p>Upload or enter URL to preview</p></div>';
                                        }

                                        openModal('editRoomModal');
                                    }

                                    // View room
                                    function viewRoom(id, number, type, floor, status, rate, description, facilities, imageUrl, maxOccupancy) {
                                        document.getElementById('viewRoomNumber').textContent = number;
                                        document.getElementById('viewRoomType').textContent = type;
                                        document.getElementById('viewFloor').textContent = 'Floor ' + floor;
                                        document.getElementById('viewStatus').innerHTML = '<span class="status-badge ' + status.toLowerCase() + '">' + status + '</span>';
                                        document.getElementById('viewRate').textContent = 'LKR ' + rate;
                                        document.getElementById('viewOccupancy').textContent = maxOccupancy + ' guests';

                                        // Image
                                        if (imageUrl) {
                                            document.getElementById('viewRoomImage').innerHTML = '<img src="' + imageUrl + '">';
                                        } else {
                                            document.getElementById('viewRoomImage').innerHTML = '<div class="no-image"><i class="fas fa-bed"></i><span>No Image Available</span></div>';
                                        }

                                        // Description
                                        if (description) {
                                            document.getElementById('viewDescriptionSection').style.display = 'block';
                                            document.getElementById('viewDescription').textContent = description;
                                        } else {
                                            document.getElementById('viewDescriptionSection').style.display = 'none';
                                        }

                                        // Facilities
                                        if (facilities) {
                                            document.getElementById('viewFacilitiesSection').style.display = 'block';
                                            const facilityList = facilities.split(',');
                                            let html = '';
                                            facilityList.forEach(f => {
                                                html += '<span class="facility-tag"><i class="fas fa-check"></i> ' + f.trim() + '</span>';
                                            });
                                            document.getElementById('viewFacilities').innerHTML = html;
                                        } else {
                                            document.getElementById('viewFacilitiesSection').style.display = 'none';
                                        }

                                        openModal('viewRoomModal');
                                    }

                                    // Delete room
                                    function deleteRoom(id, number) {
                                        Swal.fire({
                                            title: 'Delete Room ' + number + '?',
                                            text: 'This action cannot be undone!',
                                            icon: 'warning',
                                            showCancelButton: true,
                                            confirmButtonColor: '#dc3545',
                                            cancelButtonColor: '#6c757d',
                                            confirmButtonText: 'Yes, delete it!'
                                        }).then((result) => {
                                            if (result.isConfirmed) {
                                                window.location.href = '<%= request.getContextPath() %>/admin/admin-rooms.jsp?action=deleteRoom&roomId=' + id;
                                            }
                                        });
                                    }

                                    // Close modal on outside click
                                    document.querySelectorAll('.modal-overlay').forEach(overlay => {
                                        overlay.addEventListener('click', function (e) {
                                            if (e.target === this) {
                                                this.classList.remove('active');
                                            }
                                        });
                                    });

        // Success/Error alerts
        <% if (successMessage != null) { %>
                                        Swal.fire({
                                            icon: 'success',
                                            title: 'Success!',
                                            text: '<%= escapeJs(successMessage) %>',
                                            confirmButtonColor: '#008080'
                                        });
        <% } %>
        
        <% if (errorMessage != null) { %>
                                        Swal.fire({
                                            icon: 'error',
                                            title: 'Error',
                                            text: '<%= escapeJs(errorMessage) %>',
                                            confirmButtonColor: '#008080'
                                        });
        <% } %>
                                </script>
                            </body>

                            </html>
                            <% if (conn != null) { try { conn.close(); } catch (Exception e) {} } %>
