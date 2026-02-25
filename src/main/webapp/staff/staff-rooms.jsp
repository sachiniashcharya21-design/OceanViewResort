<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.net.*" %>
<%!
    private String safe(String value) { return value == null ? "" : value.trim(); }
    private String decodeMeta(String value) { try { return URLDecoder.decode(safe(value), "UTF-8"); } catch (Exception e) { return ""; } }
    private String extractMeta(String notes, String key) {
        if (notes == null || notes.isEmpty()) return "";
        String token = "__OVR__" + key + "=";
        String[] lines = notes.split("\\n");
        for (String line : lines) {
            if (line.startsWith(token)) return decodeMeta(line.substring(token.length()));
        }
        return "";
    }
    private String roomDescription(String notes, String fallbackDescription) {
        String metaDescription = extractMeta(notes, "DESC");
        if (!metaDescription.isEmpty()) return metaDescription;
        if (notes != null && !notes.startsWith("__OVR__")) return safe(notes);
        return safe(fallbackDescription);
    }
    private String escapeJs(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\").replace("'", "\\'").replace("\r", " ").replace("\n", " ");
    }
%>
<%
    // Check if user is logged in and is staff
    String userRole = (String) session.getAttribute("userRole");
    String username = (String) session.getAttribute("username");
    String fullName = (String) session.getAttribute("fullName");
    Integer userId = (Integer) session.getAttribute("userId");
    
    if (username == null || userRole == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?role=staff");
        return;
    }
    if (!"STAFF".equalsIgnoreCase(userRole)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }
    
    // Database connection
    Connection conn = null;
    String dbUrl = "jdbc:mysql://localhost:3306/ocean_view_resort";
    String dbUser = "root";
    String dbPass = "";
    String contextPath = request.getContextPath();
    
    // Statistics
    int totalRooms = 0, availableRooms = 0, occupiedRooms = 0, maintenanceRooms = 0;
    String dbError = null;
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
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
        dbError = e.getMessage();
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rooms - Ocean View Resort Staff</title>
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
            --warning: #ffc107;
            --info: #17a2b8;
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
        
        .header-left {
            display: flex;
            align-items: center;
            gap: 20px;
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
        
        .stat-icon.total { background: linear-gradient(135deg, var(--primary-dark), var(--primary)); color: white; }
        .stat-icon.available { background: linear-gradient(135deg, #1e7e34, var(--success)); color: white; }
        .stat-icon.occupied { background: linear-gradient(135deg, #0062cc, var(--info)); color: white; }
        .stat-icon.maintenance { background: linear-gradient(135deg, #d39e00, var(--warning)); color: #333; }
        
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
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
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
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            transition: all 0.3s ease;
        }
        
        .room-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 15px 40px rgba(0,0,0,0.15);
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
            color: rgba(255,255,255,0.7);
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
        
        .room-status-badge.available { background: var(--success); color: white; }
        .room-status-badge.occupied { background: var(--info); color: white; }
        .room-status-badge.maintenance { background: var(--warning); color: #333; }
        
        .room-number-badge {
            position: absolute;
            top: 15px;
            left: 15px;
            background: rgba(0,0,0,0.7);
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
        
        .btn-view { background: var(--primary); color: white; }
        .btn-view:hover { background: var(--primary-dark); }
        
        .btn-book { background: var(--success); color: white; }
        .btn-book:hover { background: #1e7e34; }
        
        /* Table View */
        .rooms-table {
            display: none;
            background: var(--card-bg);
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
        }
        
        .rooms-table.active { display: block; }
        .rooms-grid.hidden { display: none; }
        
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
        
        .status-badge.available { background: #d4edda; color: #155724; }
        .status-badge.occupied { background: #cce5ff; color: #004085; }
        .status-badge.maintenance { background: #fff3cd; color: #856404; }
        
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
        
        .action-btn.view { background: var(--primary); color: white; }
        .action-btn.book { background: var(--success); color: white; }
        
        .action-btn:hover { transform: scale(1.1); }
        
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
        
        .modal-overlay.active { display: flex; }
        
        .modal {
            background: var(--card-bg);
            border-radius: 20px;
            width: 100%;
            max-width: 600px;
            max-height: 90vh;
            overflow: hidden;
            animation: modalSlideIn 0.3s ease;
        }
        
        @keyframes modalSlideIn {
            from { opacity: 0; transform: translateY(-30px); }
            to { opacity: 1; transform: translateY(0); }
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
            background: rgba(255,255,255,0.2);
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
            background: rgba(255,255,255,0.3);
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
        
        /* View Room */
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
            color: rgba(255,255,255,0.7);
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
    </style>
</head>
<body>
    <!-- Header -->
    <div class="header">
        <div class="header-left">
            <h1><i class="fas fa-bed"></i> Room Management</h1>
        </div>
        <div class="header-actions">
            <a href="<%= request.getContextPath() %>/staff/staff-dashboard.jsp" class="btn btn-back">
                <i class="fas fa-arrow-left"></i> Back to Dashboard
            </a>
        </div>
    </div>
    
    <!-- Main Content -->
    <div class="main-content">
        <% if (dbError != null) { %>
            <script>
                Swal.fire({
                    icon: 'error',
                    title: 'Database Error',
                    text: '<%= escapeJs(dbError) %>',
                    confirmButtonColor: '#008080'
                });
            </script>
        <% } %>
        <!-- Stats Cards -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon total"><i class="fas fa-bed"></i></div>
                <div class="stat-info">
                    <h3><%= totalRooms %></h3>
                    <p>Total Rooms</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon available"><i class="fas fa-check-circle"></i></div>
                <div class="stat-info">
                    <h3><%= availableRooms %></h3>
                    <p>Available</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon occupied"><i class="fas fa-user-check"></i></div>
                <div class="stat-info">
                    <h3><%= occupiedRooms %></h3>
                    <p>Occupied</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon maintenance"><i class="fas fa-tools"></i></div>
                <div class="stat-info">
                    <h3><%= maintenanceRooms %></h3>
                    <p>Maintenance</p>
                </div>
            </div>
        </div>
        
        <!-- Filters -->
        <div class="filters-section">
            <div class="search-box">
                <i class="fas fa-search"></i>
                <input type="text" id="searchInput" placeholder="Search rooms by number, type..." onkeyup="filterRooms()">
            </div>
            <select class="filter-select" id="statusFilter" onchange="filterRooms()">
                <option value="">All Status</option>
                <option value="AVAILABLE">Available</option>
                <option value="OCCUPIED">Occupied</option>
                <option value="MAINTENANCE">Maintenance</option>
            </select>
            <select class="filter-select" id="typeFilter" onchange="filterRooms()">
                <option value="">All Types</option>
                <%
                    try {
                        Statement rtStmt = conn.createStatement();
                        ResultSet rtRs = rtStmt.executeQuery("SELECT room_type_id, type_name FROM room_types ORDER BY type_name");
                        while (rtRs.next()) {
                %>
                <option value="<%= rtRs.getString("type_name") %>"><%= rtRs.getString("type_name") %></option>
                <%
                        }
                        rtRs.close();
                        rtStmt.close();
                    } catch (Exception e) {}
                %>
            </select>
            <div class="view-toggle">
                <button class="view-btn active" id="gridViewBtn" onclick="switchView('grid')"><i class="fas fa-th-large"></i></button>
                <button class="view-btn" id="tableViewBtn" onclick="switchView('table')"><i class="fas fa-list"></i></button>
            </div>
        </div>
        
        <!-- Room Cards Grid View -->
        <div class="rooms-grid" id="roomsGrid">
            <%
                try {
                    Statement roomStmt = conn.createStatement();
                    ResultSet roomRs = roomStmt.executeQuery(
                        "SELECT r.room_id, r.room_number, r.room_type_id, r.floor_number AS floor, r.status, r.notes, " +
                        "rt.type_name, rt.rate_per_night, rt.max_occupancy, rt.description AS type_description, rt.amenities AS type_amenities " +
                        "FROM rooms r JOIN room_types rt ON r.room_type_id = rt.room_type_id " +
                        "ORDER BY r.room_number"
                    );
                    boolean hasRooms = false;
                    while (roomRs.next()) {
                        hasRooms = true;
                        int roomId = roomRs.getInt("room_id");
                        String roomNumber = roomRs.getString("room_number");
                        String typeName = roomRs.getString("type_name");
                        int floor = roomRs.getInt("floor");
                        double rate = roomRs.getDouble("rate_per_night");
                        String status = roomRs.getString("status");
                        String notes = roomRs.getString("notes");
                        String description = roomDescription(notes, roomRs.getString("type_description"));
                        String facilities = extractMeta(notes, "FAC");
                        if (facilities.isEmpty()) facilities = safe(roomRs.getString("type_amenities"));
                        String imageUrl = extractMeta(notes, "IMG");
                        String imageSrc = imageUrl;
                        if (imageSrc != null) {
                            imageSrc = imageSrc.trim();
                            if (!imageSrc.isEmpty() && !imageSrc.startsWith("http://") && !imageSrc.startsWith("https://") && !imageSrc.startsWith("data:")) {
                                if (imageSrc.startsWith("/")) {
                                    if (!imageSrc.startsWith(contextPath + "/")) imageSrc = contextPath + imageSrc;
                                } else {
                                    imageSrc = contextPath + "/" + imageSrc;
                                }
                            }
                        }
                        int maxOccupancy = roomRs.getInt("max_occupancy");
                        
                        String statusClass = status.toLowerCase().replace("_", "-");
                        DecimalFormat df = new DecimalFormat("#,###.00");
            %>
            <div class="room-card" data-room-number="<%= roomNumber %>" data-type="<%= typeName %>" data-status="<%= status %>">
                <div class="room-image">
                    <% if (imageSrc != null && !imageSrc.isEmpty()) { %>
                        <img src="<%= imageSrc %>" alt="<%= roomNumber %>">
                    <% } else { %>
                        <div class="no-image">
                            <i class="fas fa-bed"></i>
                            <span>No Image</span>
                        </div>
                    <% } %>
                    <span class="room-number-badge">Room <%= roomNumber %></span>
                    <span class="room-status-badge <%= statusClass %>"><%= status %></span>
                </div>
                <div class="room-details">
                    <div class="room-type"><%= typeName %></div>
                    <div class="room-floor"><i class="fas fa-layer-group"></i> Floor <%= floor %> | <i class="fas fa-users"></i> Max <%= maxOccupancy %> guests</div>
                    <div class="room-price">LKR <%= df.format(rate) %> <span>/ night</span></div>
                    
                    <% if (facilities != null && !facilities.isEmpty()) { %>
                    <div class="room-facilities">
                        <% 
                            String[] facilityList = facilities.split(",");
                            int count = 0;
                            for (String f : facilityList) {
                                if (count < 4) {
                        %>
                        <span class="facility-tag"><i class="fas fa-check"></i> <%= f.trim() %></span>
                        <% 
                                    count++;
                                }
                            }
                            if (facilityList.length > 4) {
                        %>
                        <span class="facility-tag">+<%= facilityList.length - 4 %> more</span>
                        <% } %>
                    </div>
                    <% } %>
                    
                    <% if (description != null && !description.isEmpty()) { %>
                    <div class="room-description"><%= description %></div>
                    <% } %>
                    
                    <div class="room-actions">
                        <button class="btn btn-view" onclick="viewRoom(<%= roomId %>, '<%= escapeJs(roomNumber) %>', '<%= escapeJs(typeName) %>', <%= floor %>, '<%= escapeJs(status) %>', '<%= escapeJs(df.format(rate)) %>', '<%= escapeJs(description) %>', '<%= escapeJs(facilities) %>', '<%= escapeJs(imageSrc) %>', <%= maxOccupancy %>)">
                            <i class="fas fa-eye"></i> View Details
                        </button>
                        <% if ("AVAILABLE".equals(status)) { %>
                        <a class="btn btn-book" href="<%= request.getContextPath() %>/staff/staff-customers.jsp?roomId=<%= roomId %>">
                            <i class="fas fa-calendar-plus"></i> Book (Select Guest)
                        </a>
                        <% } %>
                    </div>
                </div>
            </div>
            <%
                    }
                    if (!hasRooms) {
            %>
            <div class="empty-state" style="grid-column: 1 / -1;">
                <i class="fas fa-bed"></i>
                <h3>No Rooms Found</h3>
                <p>No rooms are available in the system.</p>
            </div>
            <%
                    }
                    roomRs.close();
                    roomStmt.close();
                } catch (Exception e) {
                    out.println("<div class='alert alert-danger'>Error loading rooms: " + e.getMessage() + "</div>");
                }
            %>
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
                    <%
                        try {
                            Statement roomStmt2 = conn.createStatement();
                            ResultSet roomRs2 = roomStmt2.executeQuery(
                                "SELECT r.room_id, r.room_number, r.room_type_id, r.floor_number AS floor, r.status, r.notes, " +
                                "rt.type_name, rt.rate_per_night, rt.max_occupancy, rt.description AS type_description, rt.amenities AS type_amenities " +
                                "FROM rooms r JOIN room_types rt ON r.room_type_id = rt.room_type_id " +
                                "ORDER BY r.room_number"
                            );
                            while (roomRs2.next()) {
                                int roomId = roomRs2.getInt("room_id");
                                String roomNumber = roomRs2.getString("room_number");
                                String typeName = roomRs2.getString("type_name");
                                int floor = roomRs2.getInt("floor");
                                double rate = roomRs2.getDouble("rate_per_night");
                                String status = roomRs2.getString("status");
                                String notes = roomRs2.getString("notes");
                                String description = roomDescription(notes, roomRs2.getString("type_description"));
                                String facilities = extractMeta(notes, "FAC");
                                if (facilities.isEmpty()) facilities = safe(roomRs2.getString("type_amenities"));
                                String imageUrl = extractMeta(notes, "IMG");
                                String imageSrc = imageUrl;
                                if (imageSrc != null) {
                                    imageSrc = imageSrc.trim();
                                    if (!imageSrc.isEmpty() && !imageSrc.startsWith("http://") && !imageSrc.startsWith("https://") && !imageSrc.startsWith("data:")) {
                                        if (imageSrc.startsWith("/")) {
                                            if (!imageSrc.startsWith(contextPath + "/")) imageSrc = contextPath + imageSrc;
                                        } else {
                                            imageSrc = contextPath + "/" + imageSrc;
                                        }
                                    }
                                }
                                int maxOccupancy = roomRs2.getInt("max_occupancy");
                                
                                String statusClass = status.toLowerCase().replace("_", "-");
                                DecimalFormat df = new DecimalFormat("#,###.00");
                    %>
                    <tr data-room-number="<%= roomNumber %>" data-type="<%= typeName %>" data-status="<%= status %>">
                        <td>
                            <% if (imageSrc != null && !imageSrc.isEmpty()) { %>
                                <img src="<%= imageSrc %>" class="table-room-img" alt="<%= roomNumber %>">
                            <% } else { %>
                                <div class="table-room-no-img"><i class="fas fa-bed"></i></div>
                            <% } %>
                        </td>
                        <td><strong><%= roomNumber %></strong></td>
                        <td><%= typeName %></td>
                        <td>Floor <%= floor %></td>
                        <td>LKR <%= df.format(rate) %></td>
                        <td><span class="status-badge <%= statusClass %>"><%= status %></span></td>
                        <td>
                            <div class="action-btns">
                                <button class="action-btn view" onclick="viewRoom(<%= roomId %>, '<%= escapeJs(roomNumber) %>', '<%= escapeJs(typeName) %>', <%= floor %>, '<%= escapeJs(status) %>', '<%= escapeJs(df.format(rate)) %>', '<%= escapeJs(description) %>', '<%= escapeJs(facilities) %>', '<%= escapeJs(imageSrc) %>', <%= maxOccupancy %>)"><i class="fas fa-eye"></i></button>
                                <% if ("AVAILABLE".equals(status)) { %>
                                <a class="action-btn book" href="<%= request.getContextPath() %>/staff/staff-customers.jsp?roomId=<%= roomId %>" title="Book (select guest first)"><i class="fas fa-calendar-plus"></i></a>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                    <%
                            }
                            roomRs2.close();
                            roomStmt2.close();
                        } catch (Exception e) {}
                    %>
                </tbody>
            </table>
        </div>
    </div>
    
    <!-- View Room Modal -->
    <div class="modal-overlay" id="viewRoomModal">
        <div class="modal">
            <div class="modal-header">
                <h3><i class="fas fa-door-open"></i> Room Details</h3>
                <button class="modal-close" onclick="closeModal('viewRoomModal')">&times;</button>
            </div>
            <div class="modal-body">
                <div class="view-room-image" id="viewRoomImage">
                    <div class="no-image">
                        <i class="fas fa-bed"></i>
                        <span>No Image</span>
                    </div>
                </div>
                
                <div class="view-info-grid">
                    <div class="view-info-item">
                        <div class="view-info-label">Room Number</div>
                        <div class="view-info-value" id="viewRoomNumber">-</div>
                    </div>
                    <div class="view-info-item">
                        <div class="view-info-label">Room Type</div>
                        <div class="view-info-value" id="viewRoomType">-</div>
                    </div>
                    <div class="view-info-item">
                        <div class="view-info-label">Floor</div>
                        <div class="view-info-value" id="viewRoomFloor">-</div>
                    </div>
                    <div class="view-info-item">
                        <div class="view-info-label">Status</div>
                        <div class="view-info-value" id="viewRoomStatus">-</div>
                    </div>
                    <div class="view-info-item">
                        <div class="view-info-label">Rate Per Night</div>
                        <div class="view-info-value" id="viewRoomRate">-</div>
                    </div>
                    <div class="view-info-item">
                        <div class="view-info-label">Max Occupancy</div>
                        <div class="view-info-value" id="viewRoomOccupancy">-</div>
                    </div>
                </div>
                
                <div class="view-description" id="viewDescriptionSection">
                    <h4><i class="fas fa-align-left"></i> Description</h4>
                    <p id="viewRoomDescription">No description available.</p>
                </div>
                
                <div class="view-facilities" id="viewFacilitiesSection">
                    <h4><i class="fas fa-concierge-bell"></i> Facilities</h4>
                    <div class="room-facilities" id="viewRoomFacilities"></div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" onclick="closeModal('viewRoomModal')">Close</button>
                <a href="#" id="bookRoomLink" class="btn btn-primary" style="display:none;"><i class="fas fa-calendar-plus"></i> Book This Room</a>
            </div>
        </div>
    </div>
    
    <script>
        // Switch between grid and table view
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
                
                card.style.display = (matchSearch && matchStatus && matchType) ? '' : 'none';
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
        
        // View room details
        function viewRoom(id, number, type, floor, status, rate, description, facilities, imageUrl, maxOccupancy) {
            document.getElementById('viewRoomNumber').textContent = 'Room ' + number;
            document.getElementById('viewRoomType').textContent = type;
            document.getElementById('viewRoomFloor').textContent = 'Floor ' + floor;
            document.getElementById('viewRoomStatus').innerHTML = '<span class="status-badge ' + status.toLowerCase() + '">' + status + '</span>';
            document.getElementById('viewRoomRate').textContent = 'LKR ' + rate;
            document.getElementById('viewRoomOccupancy').textContent = maxOccupancy + ' guests';
            
            // Image
            const imageDiv = document.getElementById('viewRoomImage');
            if (imageUrl) {
                imageDiv.innerHTML = '<img src="' + imageUrl + '" alt="Room ' + number + '">';
            } else {
                imageDiv.innerHTML = '<div class="no-image"><i class="fas fa-bed"></i><span>No Image</span></div>';
            }
            
            // Description
            const descSection = document.getElementById('viewDescriptionSection');
            if (description) {
                document.getElementById('viewRoomDescription').textContent = description;
                descSection.style.display = 'block';
            } else {
                descSection.style.display = 'none';
            }
            
            // Facilities
            const facilityDiv = document.getElementById('viewRoomFacilities');
            const facilitySection = document.getElementById('viewFacilitiesSection');
            if (facilities) {
                const facilityList = facilities.split(',');
                let html = '';
                facilityList.forEach(f => {
                    html += '<span class="facility-tag"><i class="fas fa-check"></i> ' + f.trim() + '</span>';
                });
                facilityDiv.innerHTML = html;
                facilitySection.style.display = 'block';
            } else {
                facilitySection.style.display = 'none';
            }
            
            // Book button
            const bookLink = document.getElementById('bookRoomLink');
            if (status === 'AVAILABLE') {
                bookLink.href = '<%= request.getContextPath() %>/staff/staff-customers.jsp?roomId=' + id;
                bookLink.style.display = 'inline-flex';
            } else {
                bookLink.style.display = 'none';
            }
            
            openModal('viewRoomModal');
        }
        
        // Modal functions
        function openModal(modalId) {
            document.getElementById(modalId).classList.add('active');
            document.body.style.overflow = 'hidden';
        }
        
        function closeModal(modalId) {
            document.getElementById(modalId).classList.remove('active');
            document.body.style.overflow = '';
        }
        
        // Close modal on outside click
        document.querySelectorAll('.modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', function(e) {
                if (e.target === this) {
                    closeModal(this.id);
                }
            });
        });
        
        // Close modal on escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                document.querySelectorAll('.modal-overlay.active').forEach(modal => {
                    closeModal(modal.id);
                });
            }
        });

        // Apply filters from URL params (e.g., from staff-room-types.jsp "View Rooms")
        document.addEventListener('DOMContentLoaded', function() {
            const params = new URLSearchParams(window.location.search);
            const typeParam = params.get('type');
            if (typeParam) {
                const typeFilter = document.getElementById('typeFilter');
                if (typeFilter) {
                    typeFilter.value = typeParam;
                    if (typeFilter.value !== typeParam) {
                        const normalized = typeParam.replace(/\s+/g, '_');
                        typeFilter.value = normalized;
                    }
                }
                filterRooms();
            }
        });
    </script>
</body>
</html>
<%
    // Close connection
    if (conn != null) {
        try { conn.close(); } catch (Exception e) {}
    }
%>
