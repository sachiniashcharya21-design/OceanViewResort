<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.util.*" %>
<%!
    private String escHtml(String str) {
        if (str == null) return "";
        return str.replace("&", "&amp;")
                  .replace("<", "&lt;")
                  .replace(">", "&gt;")
                  .replace("\"", "&quot;")
                  .replace("'", "&#39;");
    }

    private String resolveProfileImageUrl(String contextPath, String value) {
        if (value == null) return null;
        String cleaned = value.trim();
        if (cleaned.isEmpty()) return null;
        if (cleaned.startsWith("http://") || cleaned.startsWith("https://") || cleaned.startsWith("data:")) {
            return cleaned;
        }
        String normalized = cleaned.replace("\\", "/");
        String relative = normalized.startsWith("/") ? normalized.substring(1) : normalized;
        if (relative.isEmpty()) return null;
        if (!relative.toLowerCase().startsWith("uploads/")) {
            relative = "uploads/profiles/" + relative;
        }
        String prefix = contextPath != null ? contextPath : "";
        if ("/".equals(prefix)) prefix = "";
        else if (prefix.endsWith("/")) prefix = prefix.substring(0, prefix.length() - 1);
        return prefix + "/" + relative;
    }
%>
<%
    // Check if user is logged in as STAFF or ADMIN
    String userRole = (String) session.getAttribute("userRole");
    String username = (String) session.getAttribute("username");
    String fullName = (String) session.getAttribute("fullName");
    Integer userId = (Integer) session.getAttribute("userId");
    
    if (username == null || userRole == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?role=staff");
        return;
    }
    if (!"STAFF".equalsIgnoreCase(userRole) && !"ADMIN".equalsIgnoreCase(userRole)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }
    
    String profilePic = null;
    
    // Database connection
    Connection conn = null;
    String dbUrl = "jdbc:mysql://localhost:3306/ocean_view_resort";
    String dbUser = "root";
    String dbPass = "";
    String contextPath = request.getContextPath();
    String dbError = null;
    
    SimpleDateFormat sdf = new SimpleDateFormat("MMMM dd, yyyy");
    String today = sdf.format(new java.util.Date());
    
    List<Map<String, String>> staffList = new ArrayList<>();
    int totalStaff = 0;
    int activeStaff = 0;
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        // Get current user profile picture
        PreparedStatement psProfile = conn.prepareStatement("SELECT profile_picture FROM users WHERE user_id = ?");
        psProfile.setInt(1, userId);
        ResultSet rsProfile = psProfile.executeQuery();
        if (rsProfile.next()) {
            profilePic = rsProfile.getString("profile_picture");
        }
        rsProfile.close();
        psProfile.close();
        
        // Get all staff members
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(
            "SELECT user_id, username, full_name, email, phone, profile_picture, hire_date, status, address " +
            "FROM users WHERE role = 'STAFF' ORDER BY (status = 'ACTIVE') DESC, full_name ASC"
        );
        
        while (rs.next()) {
            Map<String, String> staff = new HashMap<>();
            staff.put("user_id", String.valueOf(rs.getInt("user_id")));
            staff.put("username", rs.getString("username") != null ? rs.getString("username") : "N/A");
            staff.put("full_name", rs.getString("full_name") != null ? rs.getString("full_name") : "Unknown");
            staff.put("email", rs.getString("email") != null ? rs.getString("email") : "N/A");
            staff.put("phone", rs.getString("phone") != null ? rs.getString("phone") : "N/A");
            staff.put("profile_picture", rs.getString("profile_picture"));
            staff.put("hire_date", rs.getDate("hire_date") != null ? sdf.format(rs.getDate("hire_date")) : "N/A");
            staff.put("status", rs.getString("status") != null ? rs.getString("status") : "ACTIVE");
            staff.put("address", rs.getString("address") != null ? rs.getString("address") : "N/A");
            staffList.add(staff);
            totalStaff++;
            if ("ACTIVE".equals(rs.getString("status"))) activeStaff++;
        }
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        dbError = e.getMessage();
        e.printStackTrace();
    } finally {
        if (conn != null) { try { conn.close(); } catch (SQLException e) {} }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Staff Directory - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        :root {
            --primary-dark: #004040;
            --primary: #008080;
            --primary-light: #00a0a0;
            --glow: #00C0C0;
            --white: #ffffff;
            --bg: #f0f5f5;
            --text-dark: #333;
            --text-light: #666;
            --success: #28a745;
            --warning: #ffc107;
            --danger: #dc3545;
            --info: #17a2b8;
            --sidebar-width: 280px;
        }
        
        body { font-family: 'Poppins', sans-serif; background: var(--bg); min-height: 100vh; display: flex; }
        
        /* Sidebar */
        .sidebar {
            width: var(--sidebar-width);
            background: linear-gradient(180deg, var(--primary-dark) 0%, var(--primary) 100%);
            min-height: 100vh;
            position: fixed;
            left: 0;
            top: 0;
            z-index: 100;
            padding: 20px 0;
            box-shadow: 5px 0 30px rgba(0,0,0,0.1);
        }
        
        .sidebar-header {
            text-align: center;
            padding: 20px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        
        .sidebar-header .logo {
            width: 60px;
            height: 60px;
            background: linear-gradient(135deg, var(--glow), var(--primary-light));
            border-radius: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 15px;
            box-shadow: 0 5px 20px rgba(0,192,192,0.3);
        }
        
        .sidebar-header .logo i { font-size: 28px; color: white; }
        .sidebar-header h2 { color: white; font-size: 18px; margin-bottom: 5px; }
        .sidebar-header p { color: rgba(255,255,255,0.6); font-size: 12px; }
        
        .staff-profile {
            text-align: center;
            padding: 25px 20px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        
        .staff-profile .avatar {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            margin: 0 auto 15px;
            border: 3px solid var(--glow);
            overflow: hidden;
            display: flex;
            align-items: center;
            justify-content: center;
            background: rgba(255,255,255,0.1);
        }
        
        .staff-profile .avatar img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        
        .staff-profile .avatar i { font-size: 35px; color: rgba(255,255,255,0.7); }
        .staff-profile h4 { color: white; font-size: 16px; margin-bottom: 5px; }
        .staff-profile span { color: var(--glow); font-size: 13px; }
        
        .nav-menu { padding: 20px 0; }
        .nav-menu h5 { color: rgba(255,255,255,0.5); font-size: 11px; text-transform: uppercase; padding: 10px 25px; letter-spacing: 1px; }
        
        .nav-item {
            display: flex;
            align-items: center;
            padding: 12px 25px;
            color: rgba(255,255,255,0.8);
            text-decoration: none;
            transition: all 0.3s ease;
            border-left: 3px solid transparent;
            margin: 2px 0;
        }
        
        .nav-item:hover { background: rgba(255,255,255,0.1); color: white; border-left-color: var(--glow); }
        .nav-item.active { background: rgba(0,192,192,0.2); color: var(--glow); border-left-color: var(--glow); }
        .nav-item i { width: 35px; font-size: 18px; }
        
        /* Main Content */
        .main-content {
            flex: 1;
            margin-left: var(--sidebar-width);
            padding: 30px;
            min-height: 100vh;
        }
        
        .top-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid rgba(0,128,128,0.1);
        }
        
        .top-bar h1 { font-size: 28px; color: var(--primary-dark); display: flex; align-items: center; gap: 15px; }
        .top-bar h1 i { color: var(--primary); }
        .top-bar .date { color: var(--text-light); font-size: 14px; margin-top: 5px; }
        
        .logout-btn {
            padding: 10px 25px;
            background: linear-gradient(135deg, #dc3545, #c82333);
            color: white;
            text-decoration: none;
            border-radius: 10px;
            display: flex;
            align-items: center;
            gap: 8px;
            font-weight: 500;
            transition: all 0.3s ease;
        }
        
        .logout-btn:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(220,53,69,0.3); }
        
        /* Stats Cards */
        .stats-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: var(--white);
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            display: flex;
            align-items: center;
            gap: 20px;
            transition: all 0.3s ease;
        }
        
        .stat-card:hover { transform: translateY(-5px); box-shadow: 0 10px 30px rgba(0,0,0,0.1); }
        
        .stat-icon {
            width: 60px;
            height: 60px;
            border-radius: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            color: white;
        }
        
        .stat-icon.total { background: linear-gradient(135deg, var(--primary), var(--glow)); }
        .stat-icon.active { background: linear-gradient(135deg, #28a745, #38f9d7); }
        .stat-icon.inactive { background: linear-gradient(135deg, #dc3545, #ff6b6b); }
        
        .stat-info h3 { font-size: 28px; color: var(--primary-dark); margin-bottom: 5px; }
        .stat-info p { color: var(--text-light); font-size: 14px; }
        
        /* Staff Grid */
        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
        }
        
        .section-header h2 {
            color: var(--primary-dark);
            font-size: 22px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .section-header h2 i { color: var(--primary); }
        
        .search-box {
            display: flex;
            align-items: center;
            gap: 10px;
            background: var(--white);
            padding: 10px 20px;
            border-radius: 25px;
            box-shadow: 0 3px 10px rgba(0,0,0,0.05);
        }
        
        .search-box input {
            border: none;
            outline: none;
            font-family: 'Poppins', sans-serif;
            font-size: 14px;
            width: 200px;
        }
        
        .search-box i { color: var(--primary); }
        
        .staff-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 25px;
        }
        
        .staff-card {
            background: var(--white);
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            text-align: center;
            transition: all 0.3s ease;
            border: 2px solid transparent;
            position: relative;
            overflow: hidden;
        }
        
        .staff-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 15px 40px rgba(0,128,128,0.15);
            border-color: var(--primary-light);
        }
        
        .staff-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            background: linear-gradient(90deg, var(--primary), var(--glow));
        }
        
        .staff-card.inactive::before {
            background: linear-gradient(90deg, #dc3545, #ff6b6b);
        }
        
        .staff-avatar {
            width: 120px;
            height: 120px;
            border-radius: 50%;
            margin: 0 auto 20px;
            overflow: hidden;
            border: 4px solid var(--primary);
            box-shadow: 0 5px 25px rgba(0,128,128,0.25);
            position: relative;
        }
        
        .staff-avatar img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        
        .staff-avatar .no-image {
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, var(--primary), var(--glow));
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 50px;
            color: white;
        }
        
        .status-indicator {
            position: absolute;
            bottom: 5px;
            right: 5px;
            width: 20px;
            height: 20px;
            border-radius: 50%;
            border: 3px solid white;
        }
        
        .status-indicator.active { background: #28a745; }
        .status-indicator.inactive { background: #dc3545; }
        
        .staff-card h4 {
            color: var(--primary-dark);
            font-size: 20px;
            margin-bottom: 5px;
        }
        
        .staff-card .username {
            color: var(--text-light);
            font-size: 13px;
            margin-bottom: 10px;
        }
        
        .staff-card .staff-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 20px;
        }
        
        .staff-badge.active-badge {
            background: rgba(40,167,69,0.15);
            color: #28a745;
        }
        
        .staff-badge.inactive-badge {
            background: rgba(220,53,69,0.15);
            color: #dc3545;
        }
        
        .staff-card .contact-info {
            border-top: 1px solid #eee;
            padding-top: 20px;
        }
        
        .contact-item {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            margin-bottom: 12px;
            color: var(--text-light);
            font-size: 14px;
        }
        
        .contact-item i {
            color: var(--primary);
            width: 20px;
            text-align: center;
        }
        
        .contact-item a {
            color: var(--text-dark);
            text-decoration: none;
            transition: color 0.3s ease;
        }
        
        .contact-item a:hover { color: var(--primary); }
        
        .hire-date {
            margin-top: 15px;
            padding-top: 15px;
            border-top: 1px dashed #eee;
            font-size: 12px;
            color: var(--text-light);
        }
        
        .hire-date i { color: var(--primary); margin-right: 8px; }
        
        /* No Results */
        .no-results {
            grid-column: 1 / -1;
            text-align: center;
            padding: 60px;
            background: var(--white);
            border-radius: 20px;
        }
        
        .no-results i {
            font-size: 60px;
            color: #ddd;
            margin-bottom: 20px;
        }
        
        .no-results h4 { color: #999; margin-bottom: 10px; }
        .no-results p { color: #aaa; }
        
        /* Filter Buttons */
        .filter-buttons {
            display: flex;
            gap: 10px;
            margin-bottom: 25px;
        }
        
        .filter-btn {
            padding: 10px 25px;
            border: 2px solid var(--primary);
            background: transparent;
            color: var(--primary);
            border-radius: 25px;
            cursor: pointer;
            font-family: 'Poppins', sans-serif;
            font-weight: 500;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .filter-btn:hover, .filter-btn.active {
            background: var(--primary);
            color: white;
        }
        
        .filter-btn .count {
            background: rgba(0,128,128,0.2);
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 12px;
        }
        
        .filter-btn.active .count, .filter-btn:hover .count {
            background: rgba(255,255,255,0.3);
        }
        
        /* Animation */
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .staff-card {
            animation: fadeIn 0.5s ease forwards;
        }
        
        .staff-card:nth-child(1) { animation-delay: 0.1s; }
        .staff-card:nth-child(2) { animation-delay: 0.2s; }
        .staff-card:nth-child(3) { animation-delay: 0.3s; }
        .staff-card:nth-child(4) { animation-delay: 0.4s; }
        .staff-card:nth-child(5) { animation-delay: 0.5s; }
        .staff-card:nth-child(6) { animation-delay: 0.6s; }
    </style>
</head>
<body>
    <!-- Sidebar -->
    <div class="sidebar">
        <div class="sidebar-header">
            <div class="logo"><i class="fas fa-umbrella-beach"></i></div>
            <h2>Ocean View Resort</h2>
            <p>Staff Portal</p>
        </div>
        
        <div class="staff-profile">
            <div class="avatar">
                <% if (profilePic != null && !profilePic.isEmpty()) { %>
                    <img src="<%= resolveProfileImageUrl(contextPath, profilePic) %>" alt="Profile">
                <% } else { %>
                    <i class="fas fa-user"></i>
                <% } %>
            </div>
            <h4><%= fullName != null ? fullName : username %></h4>
            <span><i class="fas fa-id-badge"></i> Staff Member</span>
        </div>
        
        <nav class="nav-menu">
            <h5>Main Menu</h5>
            <a href="<%= contextPath %>/staff/staff-dashboard.jsp" class="nav-item"><i class="fas fa-th-large"></i> Dashboard</a>
            <a href="<%= contextPath %>/staff/staff-reservations.jsp" class="nav-item"><i class="fas fa-calendar-alt"></i> Reservations</a>
            <a href="<%= contextPath %>/staff/staff-rooms.jsp" class="nav-item"><i class="fas fa-door-open"></i> Rooms</a>
            <a href="<%= contextPath %>/staff/staff-room-types.jsp" class="nav-item"><i class="fas fa-bed"></i> Room Types</a>
            
            <h5>Billing</h5>
            <a href="<%= contextPath %>/staff/staff-payments.jsp" class="nav-item"><i class="fas fa-credit-card"></i> Payments</a>
            <a href="<%= contextPath %>/staff/staff-invoices.jsp" class="nav-item"><i class="fas fa-file-invoice-dollar"></i> Invoices</a>
            
            <h5>Reports</h5>
            <a href="<%= contextPath %>/staff/staff-reports.jsp" class="nav-item"><i class="fas fa-chart-bar"></i> Reports</a>
            
            <h5>Team</h5>
            <a href="<%= contextPath %>/staff/staff-directory.jsp" class="nav-item active"><i class="fas fa-users"></i> Staff Directory</a>
            
            <h5>Settings</h5>
            <a href="<%= contextPath %>/staff/staff-profile.jsp" class="nav-item"><i class="fas fa-user-cog"></i> My Profile</a>
        </nav>
    </div>

    <!-- Main Content -->
    <div class="main-content">
        <div class="top-bar">
            <div>
                <h1><i class="fas fa-users"></i> Staff Directory</h1>
                <p class="date"><i class="fas fa-calendar-alt"></i> <%= today %></p>
            </div>
            <div class="top-bar-right">
                <a href="<%= request.getContextPath() %>/logout.jsp" class="logout-btn">
                    <i class="fas fa-sign-out-alt"></i> Logout
                </a>
            </div>
        </div>

        <% if (dbError != null) { %>
            <div style="background: #fff5f5; border: 1px solid #fed7d7; border-left: 5px solid #dc3545; color: #b91c1c; padding: 14px 18px; border-radius: 12px; margin-bottom: 18px;">
                <strong>Database error:</strong> <%= escHtml(dbError) %>
            </div>
        <% } %>

        <!-- Stats Row -->
        <div class="stats-row">
            <div class="stat-card">
                <div class="stat-icon total"><i class="fas fa-users"></i></div>
                <div class="stat-info">
                    <h3><%= totalStaff %></h3>
                    <p>Total Staff</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon active"><i class="fas fa-user-check"></i></div>
                <div class="stat-info">
                    <h3><%= activeStaff %></h3>
                    <p>Active Staff</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon inactive"><i class="fas fa-user-times"></i></div>
                <div class="stat-info">
                    <h3><%= totalStaff - activeStaff %></h3>
                    <p>Inactive Staff</p>
                </div>
            </div>
        </div>

        <!-- Section Header -->
        <div class="section-header">
            <h2><i class="fas fa-id-badge"></i> Team Members</h2>
            <div class="search-box">
                <i class="fas fa-search"></i>
                <input type="text" id="searchInput" placeholder="Search staff..." onkeyup="filterStaff()">
            </div>
        </div>

        <!-- Filter Buttons -->
        <div class="filter-buttons">
            <button class="filter-btn active" onclick="showAll(this)">
                <i class="fas fa-users"></i> All <span class="count"><%= totalStaff %></span>
            </button>
            <button class="filter-btn" onclick="showActive(this)">
                <i class="fas fa-user-check"></i> Active <span class="count"><%= activeStaff %></span>
            </button>
            <button class="filter-btn" onclick="showInactive(this)">
                <i class="fas fa-user-times"></i> Inactive <span class="count"><%= totalStaff - activeStaff %></span>
            </button>
        </div>

        <!-- Staff Grid -->
        <div class="staff-grid" id="staffGrid">
            <% if (staffList.isEmpty()) { %>
            <div class="no-results">
                <i class="fas fa-users"></i>
                <h4>No Staff Members Found</h4>
                <p>There are no staff members in the system.</p>
            </div>
            <% } else { 
                for (Map<String, String> staffMember : staffList) { 
                    String staffProfilePic = staffMember.get("profile_picture");
                    boolean isActive = "ACTIVE".equals(staffMember.get("status"));
            %>
            <div class="staff-card <%= isActive ? "" : "inactive" %>" data-status="<%= staffMember.get("status") %>" data-name="<%= staffMember.get("full_name").toLowerCase() %>">
                <div class="staff-avatar">
                    <% if (staffProfilePic != null && !staffProfilePic.isEmpty()) { %>
                        <img src="<%= resolveProfileImageUrl(contextPath, staffProfilePic) %>" alt="<%= escHtml(staffMember.get("full_name")) %>">
                    <% } else { %>
                        <div class="no-image">
                            <i class="fas fa-user"></i>
                        </div>
                    <% } %>
                    <div class="status-indicator <%= isActive ? "active" : "inactive" %>"></div>
                </div>
                
                <h4><%= staffMember.get("full_name") %></h4>
                <div class="username">@<%= staffMember.get("username") %></div>
                
                <span class="staff-badge <%= isActive ? "active-badge" : "inactive-badge" %>">
                    <i class="fas <%= isActive ? "fa-check-circle" : "fa-times-circle" %>"></i>
                    <%= staffMember.get("status") %>
                </span>
                
                <div class="contact-info">
                    <div class="contact-item">
                        <i class="fas fa-phone"></i>
                        <a href="tel:<%= staffMember.get("phone") %>"><%= staffMember.get("phone") %></a>
                    </div>
                    <div class="contact-item">
                        <i class="fas fa-envelope"></i>
                        <a href="mailto:<%= staffMember.get("email") %>"><%= staffMember.get("email") %></a>
                    </div>
                    <% if (!"N/A".equals(staffMember.get("address"))) { %>
                    <div class="contact-item">
                        <i class="fas fa-map-marker-alt"></i>
                        <span><%= staffMember.get("address") %></span>
                    </div>
                    <% } %>
                </div>
                
                <div class="hire-date">
                    <i class="fas fa-calendar-alt"></i> Joined: <%= staffMember.get("hire_date") %>
                </div>
            </div>
            <% } } %>
        </div>
    </div>
    
    <script>
        function filterStaff() {
            const searchValue = document.getElementById('searchInput').value.toLowerCase();
            const cards = document.querySelectorAll('.staff-card');
            
            cards.forEach(card => {
                const name = card.getAttribute('data-name');
                if (name.includes(searchValue)) {
                    card.style.display = 'block';
                } else {
                    card.style.display = 'none';
                }
            });
        }
        
        function showAll(btn) {
            setActiveButton(btn);
            const cards = document.querySelectorAll('.staff-card');
            cards.forEach(card => card.style.display = 'block');
        }
        
        function showActive(btn) {
            setActiveButton(btn);
            const cards = document.querySelectorAll('.staff-card');
            cards.forEach(card => {
                if (card.getAttribute('data-status') === 'ACTIVE') {
                    card.style.display = 'block';
                } else {
                    card.style.display = 'none';
                }
            });
        }
        
        function showInactive(btn) {
            setActiveButton(btn);
            const cards = document.querySelectorAll('.staff-card');
            cards.forEach(card => {
                if (card.getAttribute('data-status') !== 'ACTIVE') {
                    card.style.display = 'block';
                } else {
                    card.style.display = 'none';
                }
            });
        }
        
        function setActiveButton(activeBtn) {
            document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
            activeBtn.classList.add('active');
        }
    </script>
</body>
</html>
