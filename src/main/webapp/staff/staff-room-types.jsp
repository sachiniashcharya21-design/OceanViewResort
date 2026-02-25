<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.net.*" %>
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
    // Check if user is logged in and is staff
    String userRole = (String) session.getAttribute("userRole");
    String username = (String) session.getAttribute("username");
    String fullName = (String) session.getAttribute("fullName");
    
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
    String dbError = null;
    
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
        
        // Get statistics
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM room_types");
        if (rs.next()) totalTypes = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM room_types WHERE status = 'AVAILABLE'");
        if (rs.next()) availableTypes = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM room_types WHERE status IN ('UNAVAILABLE','DISCONTINUED')");
        if (rs.next()) unavailableTypes = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT AVG(rate_per_night) FROM room_types");
        if (rs.next()) avgRate = rs.getDouble(1);
        rs.close();
        
        stmt.close();
    } catch (Exception e) {
        dbError = e.getMessage();
        e.printStackTrace();
    }
    
    DecimalFormat df = new DecimalFormat("#,###.00");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Room Types - Ocean View Resort Staff</title>
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
        
        /* Room Types Grid */
        .types-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 25px;
        }
        
        .type-card {
            background: var(--card-bg);
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            transition: all 0.3s ease;
        }
        
        .type-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 15px 40px rgba(0,0,0,0.15);
        }
        
        .type-header {
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
            color: white;
            padding: 20px 25px;
            position: relative;
        }
        
        .type-name {
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 5px;
        }
        
        .type-rate {
            font-size: 24px;
            font-weight: 700;
        }
        
        .type-rate span {
            font-size: 14px;
            font-weight: 400;
            opacity: 0.8;
        }
        
        .type-status {
            position: absolute;
            top: 15px;
            right: 15px;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .type-status.available {
            background: rgba(16, 185, 129, 0.2);
            color: #34d399;
        }
        
        .type-status.unavailable {
            background: rgba(239, 68, 68, 0.2);
            color: #f87171;
        }

        .type-status.discontinued {
            background: rgba(107, 114, 128, 0.2);
            color: #9ca3af;
        }
        
        .type-body {
            padding: 25px;
        }
        
        .type-info {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .info-item {
            background: var(--bg);
            padding: 12px 15px;
            border-radius: 10px;
            border-left: 4px solid var(--primary);
        }
        
        .info-item .label {
            font-size: 11px;
            color: var(--text-light);
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 4px;
        }
        
        .info-item .value {
            font-size: 15px;
            font-weight: 600;
            color: var(--text);
        }
        
        .type-description {
            font-size: 14px;
            color: var(--text-light);
            line-height: 1.6;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 1px solid var(--border);
        }
        
        .amenities-section h4 {
            font-size: 13px;
            color: var(--text);
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .amenities-section h4 i {
            color: var(--primary);
        }
        
        .amenities-list {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }
        
        .amenity-tag {
            background: #e8f5f5;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 12px;
            color: var(--primary-dark);
            display: flex;
            align-items: center;
            gap: 6px;
        }
        
        .amenity-tag i {
            color: var(--primary);
            font-size: 11px;
        }
        
        .type-footer {
            padding: 15px 25px;
            background: var(--bg);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .room-count {
            font-size: 13px;
            color: var(--text-light);
        }
        
        .room-count strong {
            color: var(--primary);
        }
        
        .btn-view-rooms {
            background: var(--primary);
            color: white;
            padding: 10px 20px;
            border-radius: 8px;
            font-size: 13px;
            text-decoration: none;
            transition: all 0.3s ease;
        }
        
        .btn-view-rooms:hover {
            background: var(--primary-dark);
            transform: translateY(-2px);
        }
        
        /* Search Box */
        .search-section {
            background: var(--card-bg);
            border-radius: 15px;
            padding: 20px 25px;
            margin-bottom: 25px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            display: flex;
            gap: 15px;
            align-items: center;
        }
        
        .search-box {
            flex: 1;
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
        
        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            background: var(--card-bg);
            border-radius: 15px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
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
    </style>
</head>
<body>
    <!-- Header -->
    <div class="header">
        <div class="header-left">
            <h1><i class="fas fa-layer-group"></i> Room Types</h1>
        </div>
        <a href="<%= contextPath %>/staff/staff-dashboard.jsp" class="btn btn-back">
            <i class="fas fa-arrow-left"></i> Back to Dashboard
        </a>
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
                <div class="stat-icon total"><i class="fas fa-layer-group"></i></div>
                <div class="stat-info">
                    <h3><%= totalTypes %></h3>
                    <p>Total Room Types</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon available"><i class="fas fa-check-circle"></i></div>
                <div class="stat-info">
                    <h3><%= availableTypes %></h3>
                    <p>Available Types</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon unavailable"><i class="fas fa-times-circle"></i></div>
                <div class="stat-info">
                    <h3><%= unavailableTypes %></h3>
                    <p>Not Available</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon rate"><i class="fas fa-money-bill-wave"></i></div>
                <div class="stat-info">
                    <h3>LKR <%= df.format(avgRate) %></h3>
                    <p>Average Rate/Night</p>
                </div>
            </div>
        </div>
        
        <!-- Search Section -->
        <div class="search-section">
            <div class="search-box">
                <i class="fas fa-search"></i>
                <input type="text" id="searchInput" placeholder="Search room types..." onkeyup="filterTypes()">
            </div>
            <select class="filter-select" id="statusFilter" onchange="filterTypes()">
                <option value="">All Status</option>
                <option value="AVAILABLE">Available</option>
                <option value="UNAVAILABLE">Unavailable</option>
                <option value="DISCONTINUED">Discontinued</option>
            </select>
        </div>
        
        <!-- Room Types Grid -->
        <div class="types-grid" id="typesGrid">
            <%
                try {
                    Statement typeStmt = conn.createStatement();
                    ResultSet typeRs = typeStmt.executeQuery(
                        "SELECT rt.*, (SELECT COUNT(*) FROM rooms r WHERE r.room_type_id = rt.room_type_id) as room_count " +
                        "FROM room_types rt ORDER BY rt.type_name"
                    );
                    boolean hasTypes = false;
                    while (typeRs.next()) {
                        hasTypes = true;
                        int typeId = typeRs.getInt("room_type_id");
                        String typeName = typeRs.getString("type_name");
                        String description = typeRs.getString("description");
                        double ratePerNight = typeRs.getDouble("rate_per_night");
                        int maxOccupancy = typeRs.getInt("max_occupancy");
                        String amenities = typeRs.getString("amenities");
                        String status = typeRs.getString("status");
                        int roomCount = typeRs.getInt("room_count");
                        
                        String statusClass = status != null ? status.toLowerCase() : "available";
            %>
            <div class="type-card" data-name="<%= typeName.replace("_", " ").toLowerCase() %>" data-status="<%= status %>">
                <div class="type-header">
                    <div class="type-name"><%= typeName.replace("_", " ") %></div>
                    <div class="type-rate">LKR <%= df.format(ratePerNight) %> <span>/ night</span></div>
                    <span class="type-status <%= statusClass %>"><%= status %></span>
                </div>
                <div class="type-body">
                    <div class="type-info">
                        <div class="info-item">
                            <div class="label">Max Occupancy</div>
                            <div class="value"><i class="fas fa-users"></i> <%= maxOccupancy %> Guests</div>
                        </div>
                        <div class="info-item">
                            <div class="label">Total Rooms</div>
                            <div class="value"><i class="fas fa-door-open"></i> <%= roomCount %> Rooms</div>
                        </div>
                    </div>
                    
                    <% if (description != null && !description.isEmpty()) { %>
                    <div class="type-description">
                        <%= description %>
                    </div>
                    <% } %>
                    
                    <% if (amenities != null && !amenities.isEmpty()) { %>
                    <div class="amenities-section">
                        <h4><i class="fas fa-concierge-bell"></i> Amenities</h4>
                        <div class="amenities-list">
                            <% 
                                String[] amenityList = amenities.split(",");
                                for (String amenity : amenityList) {
                            %>
                            <span class="amenity-tag"><i class="fas fa-check"></i> <%= amenity.trim() %></span>
                            <% } %>
                        </div>
                    </div>
                    <% } %>
                </div>
                <div class="type-footer">
                    <span class="room-count"><strong><%= roomCount %></strong> rooms of this type</span>
                    <a href="<%= contextPath %>/staff/staff-rooms.jsp?type=<%= URLEncoder.encode(typeName, "UTF-8") %>" class="btn-view-rooms">
                        <i class="fas fa-eye"></i> View Rooms
                    </a>
                </div>
            </div>
            <%
                    }
                    if (!hasTypes) {
            %>
            <div class="empty-state" style="grid-column: 1 / -1;">
                <i class="fas fa-layer-group"></i>
                <h3>No Room Types Found</h3>
                <p>No room types are available in the system.</p>
            </div>
            <%
                    }
                    typeRs.close();
                    typeStmt.close();
                } catch (Exception e) {
                    out.println("<div class='empty-state' style='grid-column: 1 / -1;'><i class='fas fa-exclamation-triangle'></i><h3>Error Loading Data</h3><p>" + e.getMessage() + "</p></div>");
                }
            %>
        </div>
    </div>
    
    <script>
        function filterTypes() {
            const search = document.getElementById('searchInput').value.toLowerCase();
            const status = document.getElementById('statusFilter').value;
            
            document.querySelectorAll('.type-card').forEach(card => {
                const name = card.dataset.name;
                const cardStatus = card.dataset.status;
                
                const matchSearch = name.includes(search);
                const matchStatus = !status || cardStatus === status;
                
                card.style.display = (matchSearch && matchStatus) ? '' : 'none';
            });
        }
    </script>
</body>
</html>
<%
    // Close connection
    if (conn != null) {
        try { conn.close(); } catch (Exception e) {}
    }
%>
