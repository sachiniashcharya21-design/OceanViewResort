<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.util.*" %>
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
    
    // Check for login success
    Boolean loginSuccess = (Boolean) session.getAttribute("loginSuccess");
    String welcomeMessage = (String) session.getAttribute("welcomeMessage");
    if (loginSuccess != null && loginSuccess) {
        session.removeAttribute("loginSuccess");
        session.removeAttribute("welcomeMessage");
    }
    
    // Database connection
    Connection conn = null;
    String dbUrl = "jdbc:mysql://localhost:3306/ocean_view_resort";
    String dbUser = "root";
    String dbPass = "";
    
    // Dashboard statistics
    int totalRooms = 0, availableRooms = 0, occupiedRooms = 0, maintenanceRooms = 0;
    int totalReservations = 0, todayCheckIns = 0, todayCheckOuts = 0;
    int totalGuests = 0, confirmedReservations = 0, pendingReservations = 0;
    double todayRevenue = 0, monthlyRevenue = 0;
    String profilePic = null;
    String profilePicUrl = null;
    String displayName = (fullName != null && !fullName.trim().isEmpty()) ? fullName : username;
    String firstName = username;
    if (displayName != null && !displayName.trim().isEmpty()) {
        String[] nameParts = displayName.trim().split("\\s+");
        if (nameParts.length > 0 && !nameParts[0].isEmpty()) {
            firstName = nameParts[0];
        }
    }
    
    // Chart data
    double[] weeklyRevenue = new double[7];
    String[] weekDays = new String[7];
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        // Get user details including profile picture
        PreparedStatement psProfile;
        if (userId != null) {
            psProfile = conn.prepareStatement("SELECT * FROM users WHERE user_id = ?");
            psProfile.setInt(1, userId);
        } else {
            psProfile = conn.prepareStatement("SELECT * FROM users WHERE username = ?");
            psProfile.setString(1, username);
        }
        ResultSet rsProfile = psProfile.executeQuery();
        if (rsProfile.next()) {
            profilePic = rsProfile.getString("profile_picture");
            if (userId == null) {
                userId = rsProfile.getInt("user_id");
            }
        }
        rsProfile.close();
        psProfile.close();
        
        Statement stmt = conn.createStatement();
        ResultSet rs;
        
        // Total rooms
        rs = stmt.executeQuery("SELECT COUNT(*) FROM rooms");
        if (rs.next()) totalRooms = rs.getInt(1);
        rs.close();
        
        // Available rooms
        rs = stmt.executeQuery("SELECT COUNT(*) FROM rooms WHERE status = 'AVAILABLE'");
        if (rs.next()) availableRooms = rs.getInt(1);
        rs.close();
        
        // Occupied rooms
        rs = stmt.executeQuery("SELECT COUNT(*) FROM rooms WHERE status = 'OCCUPIED'");
        if (rs.next()) occupiedRooms = rs.getInt(1);
        rs.close();
        
        // Maintenance rooms
        rs = stmt.executeQuery("SELECT COUNT(*) FROM rooms WHERE status = 'MAINTENANCE'");
        if (rs.next()) maintenanceRooms = rs.getInt(1);
        rs.close();
        
        // Total reservations
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations");
        if (rs.next()) totalReservations = rs.getInt(1);
        rs.close();
        
        // Confirmed reservations
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE status = 'CONFIRMED'");
        if (rs.next()) confirmedReservations = rs.getInt(1);
        rs.close();
        
        // Pending reservations
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE status = 'PENDING'");
        if (rs.next()) pendingReservations = rs.getInt(1);
        rs.close();
        
        // Today's check-ins
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE check_in_date = CURDATE() AND status IN ('CONFIRMED', 'CHECKED_IN')");
        if (rs.next()) todayCheckIns = rs.getInt(1);
        rs.close();
        
        // Today's check-outs
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE check_out_date = CURDATE()");
        if (rs.next()) todayCheckOuts = rs.getInt(1);
        rs.close();
        
        // Total guests
        rs = stmt.executeQuery("SELECT COUNT(*) FROM guests");
        if (rs.next()) totalGuests = rs.getInt(1);
        rs.close();
        
        // Today's revenue
        rs = stmt.executeQuery("SELECT IFNULL(SUM(total_amount), 0) FROM bills WHERE DATE(paid_at) = CURDATE() AND payment_status = 'PAID'");
        if (rs.next()) todayRevenue = rs.getDouble(1);
        rs.close();
        
        // Monthly revenue
        rs = stmt.executeQuery("SELECT IFNULL(SUM(total_amount), 0) FROM bills WHERE MONTH(paid_at) = MONTH(CURDATE()) AND YEAR(paid_at) = YEAR(CURDATE()) AND payment_status = 'PAID'");
        if (rs.next()) monthlyRevenue = rs.getDouble(1);
        rs.close();
        
        // Weekly revenue data for chart
        SimpleDateFormat dayFormat = new SimpleDateFormat("EEE");
        Calendar cal = Calendar.getInstance();
        for (int i = 6; i >= 0; i--) {
            cal.setTime(new java.util.Date());
            cal.add(Calendar.DAY_OF_MONTH, -i);
            weekDays[6-i] = dayFormat.format(cal.getTime());
            
            String dateStr = new SimpleDateFormat("yyyy-MM-dd").format(cal.getTime());
            PreparedStatement psRev = conn.prepareStatement(
                "SELECT IFNULL(SUM(total_amount), 0) FROM bills WHERE DATE(paid_at) = ? AND payment_status = 'PAID'"
            );
            psRev.setString(1, dateStr);
            ResultSet rsRev = psRev.executeQuery();
            if (rsRev.next()) {
                weeklyRevenue[6-i] = rsRev.getDouble(1);
            }
            rsRev.close();
            psRev.close();
        }
        
        stmt.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
    
    if (profilePic != null && !profilePic.trim().isEmpty()) {
        String cleanPath = profilePic.trim();
        if (cleanPath.startsWith("http://") || cleanPath.startsWith("https://") || cleanPath.startsWith("data:image")) {
            profilePicUrl = cleanPath;
        } else {
            while (cleanPath.startsWith("/")) {
                cleanPath = cleanPath.substring(1);
            }
            if (!cleanPath.matches("(?i)^uploads[\\\\/].*")) {
                cleanPath = "uploads/profiles/" + cleanPath;
            }
            profilePicUrl = request.getContextPath() + "/" + cleanPath;
        }
    }

    DecimalFormat df = new DecimalFormat("#,###.00");
    SimpleDateFormat sdf = new SimpleDateFormat("MMMM dd, yyyy");
    String today = sdf.format(new java.util.Date());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Staff Dashboard - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
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
            z-index: 1000;
            overflow-y: auto;
        }
        
        .sidebar-header {
            padding: 25px 20px;
            text-align: center;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        
        .sidebar-header .logo {
            width: 70px;
            height: 70px;
            background: rgba(255,255,255,0.2);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 15px;
        }
        
        .sidebar-header .logo i { font-size: 30px; color: var(--white); }
        .sidebar-header h2 { color: var(--white); font-size: 18px; font-weight: 600; }
        .sidebar-header p { color: rgba(255,255,255,0.7); font-size: 12px; }
        
        .staff-profile {
            padding: 20px;
            text-align: center;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        
        .staff-profile .avatar {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            border: 3px solid var(--glow);
            margin: 0 auto 10px;
            overflow: hidden;
            background: rgba(255,255,255,0.2);
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            cursor: pointer;
        }
        
        .staff-profile .avatar-overlay {
            position: absolute;
            inset: 0;
            background: rgba(0, 0, 0, 0.45);
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
            opacity: 0;
            transition: opacity 0.25s ease;
            z-index: 1;
        }
        
        .staff-profile .avatar:hover .avatar-overlay {
            opacity: 1;
        }
        
        #dashboardProfileInput {
            display: none;
        }
        
        .staff-profile .avatar img { width: 100%; height: 100%; object-fit: cover; }
        .staff-profile .avatar i { font-size: 40px; color: var(--white); }
        .staff-profile h4 { color: var(--white); font-size: 16px; margin-bottom: 5px; }
        .staff-profile span { color: var(--glow); font-size: 12px; background: rgba(0,192,192,0.2); padding: 3px 12px; border-radius: 15px; }
        
        .nav-menu { padding: 20px 0; }
        .nav-menu h5 { color: rgba(255,255,255,0.5); font-size: 11px; text-transform: uppercase; padding: 10px 25px; letter-spacing: 1px; }
        
        .nav-item {
            display: block;
            padding: 14px 25px;
            color: rgba(255,255,255,0.8);
            text-decoration: none;
            transition: all 0.3s ease;
            border-left: 4px solid transparent;
        }
        
        .nav-item:hover, .nav-item.active {
            background: rgba(255,255,255,0.1);
            color: var(--white);
            border-left-color: var(--glow);
        }
        
        .nav-item i { width: 25px; margin-right: 12px; }
        
        /* Main Content */
        .main-content { margin-left: var(--sidebar-width); flex: 1; padding: 25px; min-height: 100vh; }
        
        .top-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
            background: var(--white);
            padding: 15px 25px;
            border-radius: 15px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }
        
        .top-bar h1 { font-size: 24px; color: var(--primary-dark); }
        .top-bar .date { color: var(--text-light); font-size: 14px; }
        .top-bar-right { display: flex; align-items: center; gap: 20px; }
        
        .notification-btn {
            position: relative;
            width: 45px;
            height: 45px;
            border-radius: 50%;
            border: none;
            background: var(--bg);
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .notification-btn:hover { background: var(--primary); color: white; }
        .notification-btn .badge {
            position: absolute;
            top: -5px;
            right: -5px;
            background: var(--danger);
            color: white;
            font-size: 11px;
            padding: 2px 6px;
            border-radius: 10px;
        }
        
        .logout-btn {
            padding: 10px 25px;
            background: linear-gradient(135deg, var(--danger), #c0392b);
            color: white;
            border: none;
            border-radius: 25px;
            cursor: pointer;
            font-family: 'Poppins', sans-serif;
            font-weight: 500;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .logout-btn:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(220,53,69,0.3); }
        
        /* Stats Cards */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
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
            width: 65px;
            height: 65px;
            border-radius: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 28px;
        }
        
        .stat-icon.rooms { background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
        .stat-icon.reservations { background: linear-gradient(135deg, #f093fb, #f5576c); color: white; }
        .stat-icon.guests { background: linear-gradient(135deg, #4facfe, #00f2fe); color: white; }
        .stat-icon.revenue { background: linear-gradient(135deg, #43e97b, #38f9d7); color: white; }
        .stat-icon.checkin { background: linear-gradient(135deg, #fa709a, #fee140); color: white; }
        .stat-icon.checkout { background: linear-gradient(135deg, #a8edea, #fed6e3); color: var(--primary-dark); }
        .stat-icon.available { background: linear-gradient(135deg, var(--primary), var(--glow)); color: white; }
        .stat-icon.occupied { background: linear-gradient(135deg, #ff9a9e, #fecfef); color: var(--primary-dark); }
        
        .stat-info h3 { font-size: 28px; color: var(--primary-dark); margin-bottom: 5px; }
        .stat-info p { color: var(--text-light); font-size: 14px; }
        
        /* Quick Actions */
        .quick-actions {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .quick-action-btn {
            padding: 20px;
            background: var(--white);
            border: 2px solid transparent;
            border-radius: 15px;
            cursor: pointer;
            text-align: center;
            transition: all 0.3s ease;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 10px;
            text-decoration: none;
        }
        
        .quick-action-btn:hover {
            border-color: var(--primary);
            transform: translateY(-5px);
            box-shadow: 0 10px 30px rgba(0,128,128,0.1);
        }
        
        .quick-action-btn i { font-size: 30px; color: var(--primary); }
        .quick-action-btn span { color: var(--text-dark); font-weight: 500; }
        
        /* Charts Grid */
        .charts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 25px;
            margin-bottom: 25px;
        }
        
        .chart-container {
            background: var(--white);
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            min-height: 350px;
        }
        
        .chart-container h3 {
            color: var(--primary-dark);
            margin-bottom: 20px;
            font-size: 16px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .chart-container h3 i { color: var(--primary); }
        .chart-container canvas { max-height: 280px !important; }
        
        /* Cards */
        .card {
            background: var(--white);
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            overflow: hidden;
        }
        
        .card-header {
            padding: 20px 25px;
            border-bottom: 1px solid #eee;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .card-header h3 {
            color: var(--primary-dark);
            font-size: 16px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .card-header h3 i { color: var(--primary); }
        .card-body { padding: 20px 25px; }
        
        /* Activity Items */
        .activity-item {
            display: flex;
            align-items: flex-start;
            gap: 15px;
            padding: 15px 0;
            border-bottom: 1px solid #eee;
        }
        
        .activity-item:last-child { border-bottom: none; }
        
        .activity-icon {
            width: 45px;
            height: 45px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
        }
        
        .activity-icon.booking { background: rgba(102,126,234,0.1); color: #667eea; }
        .activity-icon.checkin { background: rgba(40,167,69,0.1); color: var(--success); }
        .activity-icon.checkout { background: rgba(220,53,69,0.1); color: var(--danger); }
        .activity-icon.payment { background: rgba(0,128,128,0.1); color: var(--primary); }
        
        .activity-content h4 { color: var(--text-dark); font-size: 14px; margin-bottom: 3px; }
        .activity-content p { color: var(--text-light); font-size: 12px; }
        
        /* Responsive */
        @media (max-width: 768px) {
            .sidebar { transform: translateX(-100%); }
            .main-content { margin-left: 0; }
            .charts-grid { grid-template-columns: 1fr; }
            .top-bar { flex-direction: column; gap: 15px; }
        }
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
                <% if (profilePicUrl != null && !profilePicUrl.isEmpty()) { %>
                    <img src="<%= profilePicUrl %>" alt="Profile">
                <% } else { %>
                    <i class="fas fa-user"></i>
                <% } %>
                <div class="avatar-overlay" onclick="document.getElementById('dashboardProfileInput').click()">
                    <i class="fas fa-camera"></i>
                </div>
            </div>
            <input type="file" id="dashboardProfileInput" accept="image/*" onchange="uploadDashboardProfilePic(this)">
            <h4><%= displayName %></h4>
            <span><i class="fas fa-id-badge"></i> Staff Member</span>
        </div>
        
        <nav class="nav-menu">
            <h5>Main Menu</h5>
            <a href="<%= request.getContextPath() %>/staff/staff-dashboard.jsp" class="nav-item active"><i class="fas fa-th-large"></i> Dashboard</a>
            <a href="<%= request.getContextPath() %>/staff/staff-customers.jsp" class="nav-item"><i class="fas fa-user-friends"></i> Customers</a>
            <a href="<%= request.getContextPath() %>/staff/staff-reservations.jsp" class="nav-item"><i class="fas fa-calendar-alt"></i> Reservations</a>
            <a href="<%= request.getContextPath() %>/staff/staff-rooms.jsp" class="nav-item"><i class="fas fa-door-open"></i> Rooms</a>
            <a href="<%= request.getContextPath() %>/staff/staff-room-types.jsp" class="nav-item"><i class="fas fa-bed"></i> Room Types</a>
            
            <h5>Billing</h5>
            <a href="<%= request.getContextPath() %>/staff/staff-payments.jsp" class="nav-item"><i class="fas fa-credit-card"></i> Payments</a>
            <a href="<%= request.getContextPath() %>/staff/staff-invoices.jsp" class="nav-item"><i class="fas fa-file-invoice-dollar"></i> Invoices</a>
            
            <h5>Reports</h5>
            <a href="<%= request.getContextPath() %>/staff/staff-reports.jsp" class="nav-item"><i class="fas fa-chart-bar"></i> Reports</a>
            
            <h5>Team</h5>
            <a href="<%= request.getContextPath() %>/staff/staff-directory.jsp" class="nav-item"><i class="fas fa-users"></i> Staff Directory</a>
            
            <h5>Settings</h5>
            <a href="<%= request.getContextPath() %>/staff/staff-profile.jsp" class="nav-item"><i class="fas fa-user-cog"></i> My Profile</a>
        </nav>
    </div>

    <!-- Main Content -->
    <div class="main-content">
        <div class="top-bar">
            <div>
                <h1>Welcome, <%= firstName %>!</h1>
                <p class="date"><i class="fas fa-calendar-alt"></i> <%= today %></p>
            </div>
            <div class="top-bar-right">
                <button class="notification-btn" type="button" title="View today's arrivals"
                        onclick="window.location.href='<%= request.getContextPath() %>/staff/staff-reservations.jsp'">
                    <i class="fas fa-bell"></i><span class="badge"><%= todayCheckIns %></span>
                </button>
                <a href="<%= request.getContextPath() %>/logout.jsp" class="logout-btn">
                    <i class="fas fa-sign-out-alt"></i> Logout
                </a>
            </div>
        </div>

        <!-- Stats Grid -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon rooms"><i class="fas fa-door-open"></i></div>
                <div class="stat-info">
                    <h3><%= totalRooms %></h3>
                    <p>Total Rooms</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon available"><i class="fas fa-check-circle"></i></div>
                <div class="stat-info">
                    <h3><%= availableRooms %></h3>
                    <p>Available Rooms</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon occupied"><i class="fas fa-bed"></i></div>
                <div class="stat-info">
                    <h3><%= occupiedRooms %></h3>
                    <p>Occupied Rooms</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon reservations"><i class="fas fa-calendar-check"></i></div>
                <div class="stat-info">
                    <h3><%= totalReservations %></h3>
                    <p>Total Reservations</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon checkin"><i class="fas fa-sign-in-alt"></i></div>
                <div class="stat-info">
                    <h3><%= todayCheckIns %></h3>
                    <p>Today's Check-ins</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon checkout"><i class="fas fa-sign-out-alt"></i></div>
                <div class="stat-info">
                    <h3><%= todayCheckOuts %></h3>
                    <p>Today's Check-outs</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon guests"><i class="fas fa-users"></i></div>
                <div class="stat-info">
                    <h3><%= totalGuests %></h3>
                    <p>Total Guests</p>
                </div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon revenue"><i class="fas fa-dollar-sign"></i></div>
                <div class="stat-info">
                    <h3>Rs. <%= df.format(monthlyRevenue) %></h3>
                    <p>Monthly Revenue</p>
                </div>
            </div>
        </div>

        <!-- Quick Actions -->
        <div class="quick-actions">
            <a href="<%= request.getContextPath() %>/staff/staff-reservations.jsp" class="quick-action-btn">
                <i class="fas fa-calendar-plus"></i>
                <span>New Reservation</span>
            </a>
            <a href="<%= request.getContextPath() %>/staff/staff-rooms.jsp" class="quick-action-btn">
                <i class="fas fa-door-open"></i>
                <span>View Rooms</span>
            </a>
            <a href="<%= request.getContextPath() %>/staff/staff-payments.jsp" class="quick-action-btn">
                <i class="fas fa-credit-card"></i>
                <span>Process Payment</span>
            </a>
            <a href="<%= request.getContextPath() %>/staff/staff-reports.jsp" class="quick-action-btn">
                <i class="fas fa-chart-line"></i>
                <span>View Reports</span>
            </a>
        </div>

        <!-- Charts -->
        <div class="charts-grid">
            <div class="chart-container">
                <h3><i class="fas fa-chart-line"></i> Revenue Overview (Last 7 Days)</h3>
                <div style="height: 280px;"><canvas id="revenueChart"></canvas></div>
            </div>
            <div class="chart-container">
                <h3><i class="fas fa-chart-pie"></i> Room Status</h3>
                <div style="height: 280px;"><canvas id="roomStatusChart"></canvas></div>
            </div>
        </div>

        <!-- Activity Cards -->
        <div class="charts-grid">
            <div class="card">
                <div class="card-header">
                    <h3><i class="fas fa-history"></i> Recent Activity</h3>
                </div>
                <div class="card-body">
                    <%
                        try {
                            Statement actStmt = conn.createStatement();
                            ResultSet actRs = actStmt.executeQuery(
                                "SELECT r.reservation_number, g.full_name, r.status, r.created_at " +
                                "FROM reservations r JOIN guests g ON r.guest_id = g.guest_id ORDER BY r.created_at DESC LIMIT 5"
                            );
                            boolean hasActivity = false;
                            while (actRs.next()) {
                                hasActivity = true;
                                String status = actRs.getString("status");
                                String iconClass = "booking";
                                String icon = "calendar-plus";
                                if ("CHECKED_IN".equals(status)) { iconClass = "checkin"; icon = "sign-in-alt"; }
                                else if ("CHECKED_OUT".equals(status)) { iconClass = "checkout"; icon = "sign-out-alt"; }
                    %>
                    <div class="activity-item">
                        <div class="activity-icon <%= iconClass %>"><i class="fas fa-<%= icon %>"></i></div>
                        <div class="activity-content">
                            <h4><%= actRs.getString("full_name") %> - <%= actRs.getString("reservation_number") %></h4>
                            <p><%= status.replace("_", " ") %></p>
                        </div>
                    </div>
                    <%
                            }
                            if (!hasActivity) {
                                out.println("<p style='color: #666; text-align: center;'>No recent activity</p>");
                            }
                            actRs.close();
                            actStmt.close();
                        } catch (Exception e) {
                            out.println("<p style='color: #666; text-align: center;'>No recent activity</p>");
                        }
                    %>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <h3><i class="fas fa-calendar-check"></i> Upcoming Check-ins</h3>
                </div>
                <div class="card-body">
                    <%
                        try {
                            Statement upStmt = conn.createStatement();
                            ResultSet upRs = upStmt.executeQuery(
                                "SELECT g.full_name, rm.room_number, r.check_in_date FROM reservations r " +
                                "JOIN guests g ON r.guest_id = g.guest_id JOIN rooms rm ON r.room_id = rm.room_id " +
                                "WHERE r.check_in_date >= CURDATE() AND r.status = 'CONFIRMED' ORDER BY r.check_in_date LIMIT 5"
                            );
                            boolean hasUpcoming = false;
                            while (upRs.next()) {
                                hasUpcoming = true;
                    %>
                    <div class="activity-item">
                        <div class="activity-icon checkin"><i class="fas fa-user-clock"></i></div>
                        <div class="activity-content">
                            <h4><%= upRs.getString("full_name") %> - Room <%= upRs.getString("room_number") %></h4>
                            <p><%= upRs.getDate("check_in_date") %></p>
                        </div>
                    </div>
                    <%
                            }
                            if (!hasUpcoming) {
                                out.println("<p style='color: #666; text-align: center;'>No upcoming check-ins</p>");
                            }
                            upRs.close();
                            upStmt.close();
                        } catch (Exception e) {
                            out.println("<p style='color: #666; text-align: center;'>No upcoming check-ins</p>");
                        }
                    %>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Revenue Chart
        const revenueCtx = document.getElementById('revenueChart').getContext('2d');
        new Chart(revenueCtx, {
            type: 'line',
            data: {
                labels: [<% for(int i=0; i<7; i++) { out.print("'" + weekDays[i] + "'"); if(i<6) out.print(","); } %>],
                datasets: [{
                    label: 'Revenue (Rs.)',
                    data: [<% for(int i=0; i<7; i++) { out.print(weeklyRevenue[i]); if(i<6) out.print(","); } %>],
                    borderColor: '#008080',
                    backgroundColor: 'rgba(0, 128, 128, 0.1)',
                    fill: true,
                    tension: 0.4,
                    borderWidth: 3,
                    pointBackgroundColor: '#008080',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2,
                    pointRadius: 5
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { color: 'rgba(0,0,0,0.05)' }
                    },
                    x: {
                        grid: { display: false }
                    }
                }
            }
        });

        // Room Status Chart
        const roomCtx = document.getElementById('roomStatusChart').getContext('2d');
        new Chart(roomCtx, {
            type: 'doughnut',
            data: {
                labels: ['Available', 'Occupied', 'Maintenance'],
                datasets: [{
                    data: [<%= availableRooms %>, <%= occupiedRooms %>, <%= maintenanceRooms %>],
                    backgroundColor: ['#00C0C0', '#f093fb', '#ffc107'],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: { padding: 20, usePointStyle: true }
                    }
                },
                cutout: '65%'
            }
        });
        // Show login success message with SweetAlert
        <% if (loginSuccess != null && loginSuccess) { %>
        Swal.fire({
            icon: 'success',
            title: 'Login Successful!',
            html: '<strong><%= welcomeMessage != null ? welcomeMessage : "Welcome!" %></strong>',
            showConfirmButton: false,
            timer: 2500,
            timerProgressBar: true,
            background: '#fff',
            iconColor: '#008080'
        });
        <% } %>
    </script>
    <script>
        function uploadDashboardProfilePic(input) {
            if (!input || !input.files || input.files.length === 0) return;
            const file = input.files[0];

            if (!file.type.startsWith('image/')) {
                input.value = '';
                Swal.fire({
                    icon: 'error',
                    title: 'Invalid File',
                    text: 'Please select a valid image.',
                    confirmButtonColor: '#008080'
                });
                return;
            }

            if (file.size > 5 * 1024 * 1024) {
                input.value = '';
                Swal.fire({
                    icon: 'error',
                    title: 'File Too Large',
                    text: 'Please upload an image smaller than 5MB.',
                    confirmButtonColor: '#008080'
                });
                return;
            }

            const reader = new FileReader();
            reader.onload = function() {
                const params = new URLSearchParams();
                params.append('action', 'uploadProfilePic');
                params.append('imageData', reader.result);
                params.append('fileName', file.name);

                const xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === 4) {
                        input.value = '';
                        if (xhr.status === 200) {
                            try {
                                const result = JSON.parse(xhr.responseText);
                                const avatar = document.querySelector('.staff-profile .avatar');
                                const currentImg = avatar.querySelector('img');

                                if (result.success) {
                                    const imagePath = result.imagePath + '?t=' + Date.now();
                                    if (currentImg) {
                                        currentImg.src = imagePath;
                                    } else {
                                        const icon = avatar.querySelector('i');
                                        if (icon) icon.remove();
                                        const newImg = document.createElement('img');
                                        newImg.src = imagePath;
                                        newImg.alt = 'Profile';
                                        avatar.insertBefore(newImg, avatar.querySelector('.avatar-overlay'));
                                    }
                                    Swal.fire({
                                        icon: 'success',
                                        title: 'Profile Updated',
                                        text: 'Your dashboard avatar now reflects the new photo.',
                                        confirmButtonColor: '#008080'
                                    });
                                } else {
                                    Swal.fire({
                                        icon: 'error',
                                        title: 'Upload Failed',
                                        text: result.message || 'Could not update profile picture.',
                                        confirmButtonColor: '#008080'
                                    });
                                }
                            } catch (err) {
                                Swal.fire({
                                    icon: 'error',
                                    title: 'Error',
                                    text: 'Unexpected server response.',
                                    confirmButtonColor: '#008080'
                                });
                            }
                        } else {
                            Swal.fire({
                                icon: 'error',
                                title: 'Upload Failed',
                                text: 'Server error occurred.',
                                confirmButtonColor: '#008080'
                            });
                        }
                    }
                };

                xhr.open('POST', '<%= request.getContextPath() %>/staff/staff-profile.jsp', true);
                xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
                xhr.send(params.toString());
            };

            reader.onerror = function() {
                input.value = '';
                Swal.fire({
                    icon: 'error',
                    title: 'Upload Failed',
                    text: 'Failed to read the selected file.',
                    confirmButtonColor: '#008080'
                });
            };
            reader.readAsDataURL(file);
        }
    </script>
    
    <% if (conn != null) { try { conn.close(); } catch (SQLException e) {} } %>
</body>
</html>
