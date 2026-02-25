<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%!
    private String escapeJs(String value) {
        if (value == null) return "";
        return value
            .replace("\\", "\\\\")
            .replace("'", "\\'")
            .replace("\r", " ")
            .replace("\n", " ");
    }
%>
<%
    // Check if user is logged in and is admin
    String userRole = (String) session.getAttribute("userRole");
    String username = (String) session.getAttribute("username");
    
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
    
    String successMessage = (String) session.getAttribute("roomTypesSuccessMessage");
    String errorMessage = (String) session.getAttribute("roomTypesErrorMessage");
    if (successMessage != null) session.removeAttribute("roomTypesSuccessMessage");
    if (errorMessage != null) session.removeAttribute("roomTypesErrorMessage");
    
    // Statistics
    int totalTypes = 0, availableTypes = 0, unavailableTypes = 0;
    double avgRate = 0;
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        // Handle form submissions
        String action = request.getParameter("action");
        
        // Add Room Type
        if ("addRoomType".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            String typeName = request.getParameter("typeName").toUpperCase().replace(" ", "_");
            String description = request.getParameter("description");
            double ratePerNight = Double.parseDouble(request.getParameter("ratePerNight"));
            int maxOccupancy = Integer.parseInt(request.getParameter("maxOccupancy"));
            String amenities = request.getParameter("amenities");
            String status = request.getParameter("status");
            
            // Check if type name exists
            PreparedStatement checkPs = conn.prepareStatement("SELECT room_type_id FROM room_types WHERE type_name = ?");
            checkPs.setString(1, typeName);
            ResultSet checkRs = checkPs.executeQuery();
            
            if (checkRs.next()) {
                errorMessage = "Room type '" + typeName + "' already exists.";
            } else {
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO room_types (type_name, description, rate_per_night, max_occupancy, amenities, status) VALUES (?, ?, ?, ?, ?, ?)"
                );
                ps.setString(1, typeName);
                ps.setString(2, description);
                ps.setDouble(3, ratePerNight);
                ps.setInt(4, maxOccupancy);
                ps.setString(5, amenities);
                ps.setString(6, status);
                ps.executeUpdate();
                ps.close();
                successMessage = "Room type '" + typeName + "' added successfully!";
            }
            checkRs.close();
            checkPs.close();
        }
        
        // Edit Room Type
        if ("editRoomType".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            int typeId = Integer.parseInt(request.getParameter("typeId"));
            String typeName = request.getParameter("typeName").toUpperCase().replace(" ", "_");
            String description = request.getParameter("description");
            double ratePerNight = Double.parseDouble(request.getParameter("ratePerNight"));
            int maxOccupancy = Integer.parseInt(request.getParameter("maxOccupancy"));
            String amenities = request.getParameter("amenities");
            String status = request.getParameter("status");
            
            // Check if type name exists for other types
            PreparedStatement checkPs = conn.prepareStatement("SELECT room_type_id FROM room_types WHERE type_name = ? AND room_type_id != ?");
            checkPs.setString(1, typeName);
            checkPs.setInt(2, typeId);
            ResultSet checkRs = checkPs.executeQuery();
            
            if (checkRs.next()) {
                errorMessage = "Room type '" + typeName + "' already exists.";
            } else {
                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE room_types SET type_name = ?, description = ?, rate_per_night = ?, max_occupancy = ?, amenities = ?, status = ? WHERE room_type_id = ?"
                );
                ps.setString(1, typeName);
                ps.setString(2, description);
                ps.setDouble(3, ratePerNight);
                ps.setInt(4, maxOccupancy);
                ps.setString(5, amenities);
                ps.setString(6, status);
                ps.setInt(7, typeId);
                ps.executeUpdate();
                ps.close();
                successMessage = "Room type '" + typeName + "' updated successfully!";
            }
            checkRs.close();
            checkPs.close();
        }
        
        // Delete Room Type
        if ("deleteRoomType".equals(action)) {
            int typeId = Integer.parseInt(request.getParameter("typeId"));
            
            // Check if rooms use this type
            PreparedStatement checkPs = conn.prepareStatement("SELECT COUNT(*) FROM rooms WHERE room_type_id = ?");
            checkPs.setInt(1, typeId);
            ResultSet checkRs = checkPs.executeQuery();
            checkRs.next();
            int roomCount = checkRs.getInt(1);
            checkRs.close();
            checkPs.close();
            
            if (roomCount > 0) {
                errorMessage = "Cannot delete room type with " + roomCount + " room(s) assigned.";
            } else {
                PreparedStatement ps = conn.prepareStatement("DELETE FROM room_types WHERE room_type_id = ?");
                ps.setInt(1, typeId);
                ps.executeUpdate();
                ps.close();
                successMessage = "Room type deleted successfully!";
            }
        }
        
        // Get statistics
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM room_types");
        if (rs.next()) totalTypes = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM room_types WHERE status = 'AVAILABLE'");
        if (rs.next()) availableTypes = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM room_types WHERE status IN ('UNAVAILABLE', 'DISCONTINUED')");
        if (rs.next()) unavailableTypes = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT AVG(rate_per_night) FROM room_types");
        if (rs.next()) avgRate = rs.getDouble(1);
        rs.close();

        boolean redirectAfterAction =
            ("addRoomType".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) ||
            ("editRoomType".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) ||
            "deleteRoomType".equals(action);
        if (redirectAfterAction) {
            if (successMessage != null) session.setAttribute("roomTypesSuccessMessage", successMessage);
            if (errorMessage != null) session.setAttribute("roomTypesErrorMessage", errorMessage);
            if (conn != null) { try { conn.close(); } catch (Exception ignore) {} }
            response.sendRedirect(request.getContextPath() + "/admin/admin-room-types.jsp");
            return;
        }
        
        stmt.close();
    } catch (Exception e) {
        errorMessage = "Error: " + e.getMessage();
        e.printStackTrace();
    }
    
    DecimalFormat df = new DecimalFormat("#,###.00");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Room Types - Ocean View Resort Admin</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
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
        }
        
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
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
        
        .header-left h1 {
            font-size: 24px;
            font-weight: 600;
        }
        
        .header-left h1 i { margin-right: 10px; }
        
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
            background: rgba(255,255,255,0.2);
            color: white;
            border: 1px solid rgba(255,255,255,0.3);
        }
        
        .btn-back:hover {
            background: rgba(255,255,255,0.3);
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
            max-width: 1200px;
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
            .stats-grid { grid-template-columns: repeat(2, 1fr); }
        }
        
        @media (max-width: 500px) {
            .stats-grid { grid-template-columns: 1fr; }
        }
        
        .stat-card {
            background: var(--card-bg);
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
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
        
        .stat-icon.total { background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%); color: white; }
        .stat-icon.available { background: linear-gradient(135deg, #10b981 0%, #34d399 100%); color: white; }
        .stat-icon.unavailable { background: linear-gradient(135deg, #ef4444 0%, #f87171 100%); color: white; }
        .stat-icon.rate { background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%); color: white; }
        
        .stat-info h3 {
            font-size: 26px;
            font-weight: 700;
            color: var(--text);
        }
        
        .stat-info p {
            font-size: 13px;
            color: var(--text-light);
        }
        
        /* Table Card */
        .table-card {
            background: var(--card-bg);
            border-radius: 15px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            overflow: hidden;
        }
        
        .table-header {
            padding: 20px 25px;
            border-bottom: 1px solid var(--border);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .table-header h3 {
            font-size: 18px;
            font-weight: 600;
            color: var(--text);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .table-header h3 i { color: var(--primary); }
        
        .search-box {
            position: relative;
            width: 280px;
        }
        
        .search-box input {
            width: 100%;
            padding: 10px 15px 10px 40px;
            border: 2px solid var(--border);
            border-radius: 8px;
            font-size: 14px;
            font-family: 'Poppins', sans-serif;
            transition: all 0.3s ease;
        }
        
        .search-box input:focus {
            border-color: var(--primary);
            outline: none;
        }
        
        .search-box i {
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-light);
        }
        
        .data-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .data-table th, .data-table td {
            padding: 15px 20px;
            text-align: left;
            border-bottom: 1px solid var(--border);
        }
        
        .data-table th {
            background: #f8f9fa;
            font-weight: 600;
            color: var(--text);
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .data-table tbody tr {
            transition: background 0.2s ease;
        }
        
        .data-table tbody tr:hover {
            background: #f8f9fa;
        }
        
        .type-name {
            font-weight: 600;
            color: var(--primary-dark);
        }
        
        .rate-value {
            font-weight: 600;
            color: var(--primary);
        }
        
        .status-badge {
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .status-badge.available {
            background: #d4edda;
            color: #155724;
        }
        
        .status-badge.unavailable {
            background: #f8d7da;
            color: #721c24;
        }

        .status-badge.discontinued {
            background: #fff3cd;
            color: #856404;
        }
        
        .amenities-cell {
            max-width: 200px;
        }
        
        .amenity-tag {
            display: inline-block;
            background: #e8f5f5;
            padding: 4px 10px;
            border-radius: 15px;
            font-size: 11px;
            color: var(--primary-dark);
            margin: 2px;
        }
        
        .action-btn {
            width: 36px;
            height: 36px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-right: 5px;
        }
        
        .action-btn.edit { background: #fff3e0; color: #f57c00; }
        .action-btn.delete { background: #ffebee; color: #e53935; }
        
        .action-btn:hover { transform: scale(1.1); }
        
        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
        }
        
        .empty-state i {
            font-size: 60px;
            color: var(--primary);
            opacity: 0.3;
            margin-bottom: 15px;
        }
        
        .empty-state h3 {
            color: var(--text);
            margin-bottom: 8px;
        }
        
        .empty-state p {
            color: var(--text-light);
        }
        
        /* Modal Styles */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.6);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
            opacity: 0;
            visibility: hidden;
            transition: all 0.3s ease;
            padding: 20px;
        }
        
        .modal-overlay.active {
            opacity: 1;
            visibility: visible;
        }
        
        .modal {
            background: white;
            border-radius: 20px;
            width: 100%;
            max-width: 550px;
            max-height: 90vh;
            overflow: hidden;
            transform: scale(0.9);
            transition: transform 0.3s ease;
        }
        
        .modal-overlay.active .modal {
            transform: scale(1);
        }
        
        .modal-header {
            padding: 25px 30px;
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
            color: white;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-header h3 {
            font-size: 20px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .modal-close {
            width: 35px;
            height: 35px;
            border-radius: 50%;
            border: none;
            background: rgba(255,255,255,0.2);
            color: white;
            font-size: 20px;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .modal-close:hover {
            background: rgba(255,255,255,0.3);
            transform: rotate(90deg);
        }
        
        .modal-body {
            padding: 30px;
            max-height: 60vh;
            overflow-y: auto;
        }
        
        .modal-footer {
            padding: 20px 30px;
            background: #f8f9fa;
            display: flex;
            justify-content: flex-end;
            gap: 15px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        
        @media (max-width: 500px) {
            .form-row { grid-template-columns: 1fr; }
        }
        
        .form-group label {
            display: block;
            font-weight: 500;
            color: var(--text);
            font-size: 14px;
            margin-bottom: 8px;
        }
        
        .form-group label i {
            color: var(--primary);
            margin-right: 6px;
        }
        
        .form-control {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid var(--border);
            border-radius: 10px;
            font-size: 14px;
            font-family: 'Poppins', sans-serif;
            transition: all 0.3s ease;
        }
        
        .form-control:focus {
            border-color: var(--primary);
            outline: none;
            box-shadow: 0 0 0 3px rgba(0, 128, 128, 0.1);
        }
        
        textarea.form-control {
            min-height: 80px;
            resize: vertical;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
            color: white;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(0, 128, 128, 0.3);
        }
        
        .btn-secondary {
            background: #e0e0e0;
            color: var(--text);
        }
        
        .btn-secondary:hover {
            background: #d0d0d0;
        }
        
        /* Responsive */
        @media (max-width: 768px) {
            .header {
                padding: 15px 20px;
                flex-direction: column;
                gap: 15px;
            }
            
            .table-header {
                flex-direction: column;
                align-items: flex-start;
            }
            
            .search-box {
                width: 100%;
            }
            
            .data-table {
                display: block;
                overflow-x: auto;
            }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="header-left">
            <h1><i class="fas fa-layer-group"></i> Room Types Management</h1>
        </div>
        <div class="header-actions">
            <a href="<%= request.getContextPath() %>/admin/admin-dashboard.jsp" class="btn btn-back"><i class="fas fa-arrow-left"></i> Back to Dashboard</a>
            <button class="btn btn-add" onclick="openAddModal()"><i class="fas fa-plus"></i> Add Room Type</button>
        </div>
    </header>
    
    <!-- Main Content -->
    <main class="main-content">
        <!-- Stats Cards -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon total"><i class="fas fa-layer-group"></i></div>
                <div class="stat-info">
                    <h3><%= totalTypes %></h3>
                    <p>Total Types</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon available"><i class="fas fa-check-circle"></i></div>
                <div class="stat-info">
                    <h3><%= availableTypes %></h3>
                    <p>Available</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon unavailable"><i class="fas fa-times-circle"></i></div>
                <div class="stat-info">
                    <h3><%= unavailableTypes %></h3>
                    <p>Unavailable</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon rate"><i class="fas fa-tags"></i></div>
                <div class="stat-info">
                    <h3>LKR <%= df.format(avgRate) %></h3>
                    <p>Avg Rate/Night</p>
                </div>
            </div>
        </div>
        
        <!-- Room Types Table -->
        <div class="table-card">
            <div class="table-header">
                <h3><i class="fas fa-list"></i> All Room Types</h3>
                <div class="search-box">
                    <i class="fas fa-search"></i>
                    <input type="text" id="searchInput" placeholder="Search room types..." onkeyup="filterTable()">
                </div>
            </div>
            <table class="data-table" id="typesTable">
                <thead>
                    <tr>
                        <th>Type Name</th>
                        <th>Rate/Night</th>
                        <th>Max Occupancy</th>
                        <th>Amenities</th>
                        <th>Rooms</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        try {
                            Statement typeStmt = conn.createStatement();
                            ResultSet typeRs = typeStmt.executeQuery(
                                "SELECT rt.*, COUNT(r.room_id) as room_count " +
                                "FROM room_types rt LEFT JOIN rooms r ON rt.room_type_id = r.room_type_id " +
                                "GROUP BY rt.room_type_id ORDER BY rt.rate_per_night"
                            );
                            boolean hasTypes = false;
                            while (typeRs.next()) {
                                hasTypes = true;
                                int typeId = typeRs.getInt("room_type_id");
                                String typeName = typeRs.getString("type_name");
                                String description = typeRs.getString("description");
                                double rate = typeRs.getDouble("rate_per_night");
                                int maxOccupancy = typeRs.getInt("max_occupancy");
                                String amenities = typeRs.getString("amenities");
                                String status = typeRs.getString("status");
                                int roomCount = typeRs.getInt("room_count");
                                
                                String statusClass = status.toLowerCase();
                    %>
                    <tr>
                        <td class="type-name"><%= typeName.replace("_", " ") %></td>
                        <td class="rate-value">LKR <%= df.format(rate) %></td>
                        <td><i class="fas fa-users" style="color: var(--primary); margin-right: 5px;"></i> <%= maxOccupancy %> persons</td>
                        <td class="amenities-cell">
                            <% if (amenities != null && !amenities.isEmpty()) {
                                String[] amenityList = amenities.split(",");
                                int showCount = Math.min(amenityList.length, 3);
                                for (int i = 0; i < showCount; i++) { %>
                                <span class="amenity-tag"><%= amenityList[i].trim() %></span>
                            <% }
                                if (amenityList.length > 3) { %>
                                <span class="amenity-tag">+<%= amenityList.length - 3 %></span>
                            <% }
                            } else { %>
                                <span style="color: #999;">-</span>
                            <% } %>
                        </td>
                        <td><%= roomCount %></td>
                        <td><span class="status-badge <%= statusClass %>"><%= status %></span></td>
                        <td>
                            <button class="action-btn edit" title="Edit" onclick="editType(<%= typeId %>, '<%= escapeJs(typeName) %>', '<%= escapeJs(description) %>', <%= rate %>, <%= maxOccupancy %>, '<%= escapeJs(amenities) %>', '<%= escapeJs(status) %>')"><i class="fas fa-edit"></i></button>
                            <button class="action-btn delete" title="Delete" onclick="deleteType(<%= typeId %>, '<%= escapeJs(typeName) %>', <%= roomCount %>)"><i class="fas fa-trash"></i></button>
                        </td>
                    </tr>
                    <%
                            }
                            if (!hasTypes) {
                    %>
                    <tr>
                        <td colspan="7">
                            <div class="empty-state">
                                <i class="fas fa-layer-group"></i>
                                <h3>No Room Types Found</h3>
                                <p>Click "Add Room Type" to create your first room type.</p>
                            </div>
                        </td>
                    </tr>
                    <%
                            }
                            typeRs.close();
                            typeStmt.close();
                        } catch (Exception e) {
                            out.println("<tr><td colspan='7'>Error loading room types: " + e.getMessage() + "</td></tr>");
                        }
                    %>
                </tbody>
            </table>
        </div>
    </main>
    
    <!-- Add Room Type Modal -->
    <div class="modal-overlay" id="addTypeModal">
        <div class="modal">
            <div class="modal-header">
                <h3><i class="fas fa-plus-circle"></i> Add Room Type</h3>
                <button class="modal-close" onclick="closeModal('addTypeModal')">&times;</button>
            </div>
            <form method="POST" action="<%= request.getContextPath() %>/admin/admin-room-types.jsp">
                <input type="hidden" name="action" value="addRoomType">
                <div class="modal-body">
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-tag"></i> Type Name *</label>
                            <input type="text" name="typeName" class="form-control" placeholder="e.g., DELUXE" required>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-money-bill-wave"></i> Rate/Night (LKR) *</label>
                            <input type="number" name="ratePerNight" class="form-control" min="0" step="100" placeholder="25000" required>
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-users"></i> Max Occupancy *</label>
                            <input type="number" name="maxOccupancy" class="form-control" min="1" max="20" value="2" required>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-toggle-on"></i> Status *</label>
                            <select name="status" class="form-control" required>
                                <option value="AVAILABLE">Available</option>
                                <option value="UNAVAILABLE">Unavailable</option>
                                <option value="DISCONTINUED">Discontinued</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-concierge-bell"></i> Amenities</label>
                        <input type="text" name="amenities" class="form-control" placeholder="WiFi, AC, TV, Mini Bar (comma separated)">
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-align-left"></i> Description</label>
                        <textarea name="description" class="form-control" placeholder="Brief description of this room type..."></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('addTypeModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Add Type</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Edit Room Type Modal -->
    <div class="modal-overlay" id="editTypeModal">
        <div class="modal">
            <div class="modal-header">
                <h3><i class="fas fa-edit"></i> Edit Room Type</h3>
                <button class="modal-close" onclick="closeModal('editTypeModal')">&times;</button>
            </div>
            <form method="POST" action="<%= request.getContextPath() %>/admin/admin-room-types.jsp">
                <input type="hidden" name="action" value="editRoomType">
                <input type="hidden" name="typeId" id="editTypeId">
                <div class="modal-body">
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-tag"></i> Type Name *</label>
                            <input type="text" name="typeName" id="editTypeName" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-money-bill-wave"></i> Rate/Night (LKR) *</label>
                            <input type="number" name="ratePerNight" id="editRate" class="form-control" min="0" step="100" required>
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-users"></i> Max Occupancy *</label>
                            <input type="number" name="maxOccupancy" id="editMaxOccupancy" class="form-control" min="1" max="20" required>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-toggle-on"></i> Status *</label>
                            <select name="status" id="editStatus" class="form-control" required>
                                <option value="AVAILABLE">Available</option>
                                <option value="UNAVAILABLE">Unavailable</option>
                                <option value="DISCONTINUED">Discontinued</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-concierge-bell"></i> Amenities</label>
                        <input type="text" name="amenities" id="editAmenities" class="form-control" placeholder="WiFi, AC, TV, Mini Bar (comma separated)">
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-align-left"></i> Description</label>
                        <textarea name="description" id="editDescription" class="form-control" placeholder="Brief description..."></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('editTypeModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Save Changes</button>
                </div>
            </form>
        </div>
    </div>
    
    <script>
        // Filter table
        function filterTable() {
            const search = document.getElementById('searchInput').value.toLowerCase();
            const rows = document.querySelectorAll('#typesTable tbody tr');
            
            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(search) ? '' : 'none';
            });
        }
        
        // Modal functions
        function openModal(id) {
            document.getElementById(id).classList.add('active');
        }
        
        function closeModal(id) {
            document.getElementById(id).classList.remove('active');
        }
        
        function openAddModal() {
            document.querySelector('#addTypeModal form').reset();
            openModal('addTypeModal');
        }
        
        // Edit type
        function editType(id, name, description, rate, maxOccupancy, amenities, status) {
            document.getElementById('editTypeId').value = id;
            document.getElementById('editTypeName').value = name;
            document.getElementById('editRate').value = rate;
            document.getElementById('editMaxOccupancy').value = maxOccupancy;
            document.getElementById('editAmenities').value = amenities;
            document.getElementById('editStatus').value = status;
            document.getElementById('editDescription').value = description;
            openModal('editTypeModal');
        }
        
        // Delete type
        function deleteType(id, name, roomCount) {
            if (roomCount > 0) {
                Swal.fire({
                    icon: 'warning',
                    title: 'Cannot Delete',
                    text: 'This room type has ' + roomCount + ' room(s) assigned. Remove rooms first.',
                    confirmButtonColor: '#008080'
                });
                return;
            }
            
            Swal.fire({
                title: 'Delete ' + name.replace(/_/g, ' ') + '?',
                text: 'This action cannot be undone!',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#dc3545',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, delete!'
            }).then((result) => {
                if (result.isConfirmed) {
                    window.location.href = '<%= request.getContextPath() %>/admin/admin-room-types.jsp?action=deleteRoomType&typeId=' + id;
                }
            });
        }
        
        // Close modal on outside click
        document.querySelectorAll('.modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', function(e) {
                if (e.target === this) this.classList.remove('active');
            });
        });
        
        // Show alerts
        <% if (successMessage != null) { %>
        Swal.fire({icon: 'success', title: 'Success!', text: '<%= escapeJs(successMessage) %>', confirmButtonColor: '#008080'});
        <% } %>
        <% if (errorMessage != null) { %>
        Swal.fire({icon: 'error', title: 'Error', text: '<%= escapeJs(errorMessage) %>', confirmButtonColor: '#008080'});
        <% } %>
    </script>
</body>
</html>
<%
    if (conn != null) {
        try { conn.close(); } catch (Exception e) {}
    }
%>
