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
%>
<%
    // Check if user is logged in as STAFF
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
    
    String profilePic = null;
    String period = request.getParameter("period");
    if (period == null) period = "monthly";
    
    String periodTitle = "Monthly";
    String dateCondition = "MONTH(generated_at) = MONTH(CURDATE()) AND YEAR(generated_at) = YEAR(CURDATE())";
    String startDate = "", endDate = "";
    
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    SimpleDateFormat displaySdf = new SimpleDateFormat("MMMM dd, yyyy");
    Calendar cal = Calendar.getInstance();
    
    if ("daily".equals(period)) {
        periodTitle = "Daily";
        dateCondition = "DATE(generated_at) = CURDATE()";
        startDate = endDate = displaySdf.format(new Date());
    } else if ("weekly".equals(period)) {
        periodTitle = "Weekly";
        dateCondition = "YEARWEEK(generated_at) = YEARWEEK(CURDATE())";
        cal.set(Calendar.DAY_OF_WEEK, cal.getFirstDayOfWeek());
        startDate = displaySdf.format(cal.getTime());
        cal.add(Calendar.DAY_OF_WEEK, 6);
        endDate = displaySdf.format(cal.getTime());
    } else {
        cal.set(Calendar.DAY_OF_MONTH, 1);
        startDate = displaySdf.format(cal.getTime());
        cal.set(Calendar.DAY_OF_MONTH, cal.getActualMaximum(Calendar.DAY_OF_MONTH));
        endDate = displaySdf.format(cal.getTime());
    }
    
    // Database connection
    Connection conn = null;
    String dbUrl = "jdbc:mysql://localhost:3306/ocean_view_resort";
    String dbUser = "root";
    String dbPass = "";
    String contextPath = request.getContextPath();
    String dbError = null;
    
    double totalRevenue = 0, roomRevenue = 0, additionalRevenue = 0, taxRevenue = 0, discountGiven = 0;
    int totalBookings = 0, confirmedBookings = 0, cancelledBookings = 0, checkedInBookings = 0, checkedOutBookings = 0;
    int newGuests = 0, totalBills = 0, paidBills = 0, pendingBills = 0;
    int cashPayments = 0, cardPayments = 0, bankPayments = 0;
    
    DecimalFormat df = new DecimalFormat("#,###.00");
    String today = displaySdf.format(new java.util.Date());
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        // Get profile picture
        PreparedStatement psProfile = conn.prepareStatement("SELECT profile_picture FROM users WHERE user_id = ?");
        psProfile.setInt(1, userId);
        ResultSet rsProfile = psProfile.executeQuery();
        if (rsProfile.next()) {
            profilePic = rsProfile.getString("profile_picture");
        }
        rsProfile.close();
        psProfile.close();
        
        Statement stmt = conn.createStatement();
        ResultSet rs;
        
        // Revenue
        rs = stmt.executeQuery("SELECT IFNULL(SUM(total_amount), 0) as total, IFNULL(SUM(room_total), 0) as room, IFNULL(SUM(additional_charges), 0) as additional, IFNULL(SUM(tax_amount), 0) as tax, IFNULL(SUM(discount_amount), 0) as discount FROM bills WHERE payment_status = 'PAID' AND " + dateCondition);
        if (rs.next()) {
            totalRevenue = rs.getDouble("total");
            roomRevenue = rs.getDouble("room");
            additionalRevenue = rs.getDouble("additional");
            taxRevenue = rs.getDouble("tax");
            discountGiven = rs.getDouble("discount");
        }
        rs.close();
        
        // Bookings
        String resDateCondition = dateCondition.replace("generated_at", "created_at");
        rs = stmt.executeQuery("SELECT COUNT(*) as total FROM reservations WHERE " + resDateCondition);
        if (rs.next()) totalBookings = rs.getInt("total");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM reservations WHERE status = 'CONFIRMED' AND " + resDateCondition);
        if (rs.next()) confirmedBookings = rs.getInt("cnt");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM reservations WHERE status = 'CANCELLED' AND " + resDateCondition);
        if (rs.next()) cancelledBookings = rs.getInt("cnt");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM reservations WHERE status = 'CHECKED_IN' AND " + resDateCondition);
        if (rs.next()) checkedInBookings = rs.getInt("cnt");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM reservations WHERE status = 'CHECKED_OUT' AND " + resDateCondition);
        if (rs.next()) checkedOutBookings = rs.getInt("cnt");
        rs.close();
        
        // Guests
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM guests WHERE " + dateCondition.replace("generated_at", "created_at"));
        if (rs.next()) newGuests = rs.getInt("cnt");
        rs.close();
        
        // Bills
        rs = stmt.executeQuery("SELECT COUNT(*) as total FROM bills WHERE " + dateCondition);
        if (rs.next()) totalBills = rs.getInt("total");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM bills WHERE payment_status = 'PAID' AND " + dateCondition);
        if (rs.next()) paidBills = rs.getInt("cnt");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM bills WHERE payment_status = 'PENDING' AND " + dateCondition);
        if (rs.next()) pendingBills = rs.getInt("cnt");
        rs.close();
        
        // Payment methods
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM bills WHERE payment_method = 'CASH' AND payment_status = 'PAID' AND " + dateCondition);
        if (rs.next()) cashPayments = rs.getInt("cnt");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM bills WHERE payment_method = 'CARD' AND payment_status = 'PAID' AND " + dateCondition);
        if (rs.next()) cardPayments = rs.getInt("cnt");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM bills WHERE payment_method = 'BANK_TRANSFER' AND payment_status = 'PAID' AND " + dateCondition);
        if (rs.next()) bankPayments = rs.getInt("cnt");
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
    <title><%= periodTitle %> Report View - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
        .top-bar-right { display: flex; align-items: center; gap: 15px; }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-family: 'Poppins', sans-serif;
            font-weight: 500;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-primary { background: linear-gradient(135deg, var(--primary), var(--glow)); color: white; }
        .btn-secondary { background: #e0e0e0; color: var(--text-dark); }
        .btn:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,0,0,0.15); }
        
        /* Period Tabs */
        .period-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 25px;
        }
        
        .period-tab {
            padding: 12px 25px;
            background: var(--white);
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            text-decoration: none;
            color: var(--text-dark);
            font-weight: 500;
            transition: all 0.3s ease;
        }
        
        .period-tab:hover { border-color: var(--primary); color: var(--primary); }
        .period-tab.active { background: var(--primary); border-color: var(--primary); color: white; }
        
        /* Stats Grid */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: var(--white);
            border-radius: 15px;
            padding: 25px;
            text-align: center;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
        }
        
        .stat-card.highlight { background: linear-gradient(135deg, var(--primary), var(--glow)); color: white; }
        .stat-card h3 { font-size: 28px; margin-bottom: 5px; }
        .stat-card p { font-size: 13px; opacity: 0.9; }
        
        /* Report Sections */
        .report-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 25px;
            margin-bottom: 30px;
        }
        
        .report-card {
            background: var(--white);
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
        }
        
        .report-card h3 {
            color: var(--primary-dark);
            font-size: 16px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .report-card h3 i { color: var(--primary); }
        
        .summary-item {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px dashed #eee;
        }
        
        .summary-item:last-child { border-bottom: none; }
        .summary-item .label { color: var(--text-light); }
        .summary-item .value { color: var(--text-dark); font-weight: 600; }
        .summary-item .value.success { color: var(--success); }
        .summary-item .value.danger { color: var(--danger); }
        .summary-item .value.warning { color: var(--warning); }
        
        .total-row {
            background: linear-gradient(135deg, var(--primary), var(--glow));
            color: white;
            padding: 15px 20px;
            border-radius: 12px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 15px;
        }
        
        .total-row .label { font-size: 16px; }
        .total-row .value { font-size: 24px; font-weight: 700; }
        
        /* Chart Container */
        .chart-card {
            background: var(--white);
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            margin-bottom: 30px;
        }
        
        .chart-card h3 {
            color: var(--primary-dark);
            font-size: 16px;
            margin-bottom: 20px;
        }
        
        .chart-container { height: 300px; }
        
        /* Transactions Table */
        .data-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .data-table th, .data-table td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        
        .data-table th {
            background: var(--bg);
            color: var(--primary-dark);
            font-weight: 600;
            font-size: 13px;
        }
        
        .data-table tr:hover { background: var(--bg); }
        
        .status-badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 500;
        }
        
        .status-badge.paid { background: rgba(40,167,69,0.1); color: var(--success); }
        .status-badge.pending { background: rgba(255,193,7,0.1); color: #d39e00; }
        
        @media (max-width: 1200px) { .stats-grid { grid-template-columns: repeat(2, 1fr); } }
        @media (max-width: 992px) { .report-grid { grid-template-columns: 1fr; } }
        @media (max-width: 768px) {
            .sidebar { transform: translateX(-100%); }
            .main-content { margin-left: 0; }
            .stats-grid { grid-template-columns: 1fr; }
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
                <% if (profilePic != null && !profilePic.isEmpty()) { %>
                    <img src="<%= contextPath + "/" + profilePic %>" alt="Profile">
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
            <a href="<%= contextPath %>/staff/staff-reports.jsp" class="nav-item active"><i class="fas fa-chart-bar"></i> Reports</a>
            
            <h5>Settings</h5>
            <a href="<%= contextPath %>/staff/staff-profile.jsp" class="nav-item"><i class="fas fa-user-cog"></i> My Profile</a>
        </nav>
    </div>

    <!-- Main Content -->
    <div class="main-content">
        <div class="top-bar">
            <div>
                <h1><i class="fas fa-eye"></i> <%= periodTitle %> Report View</h1>
                <p class="date"><%= startDate %> - <%= endDate %></p>
            </div>
            <div class="top-bar-right">
                <a href="<%= contextPath %>/staff/staff-reports.jsp" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back</a>
                <button onclick="window.print()" class="btn btn-primary"><i class="fas fa-print"></i> Print</button>
            </div>
        </div>

        <% if (dbError != null) { %>
            <div style="background: #fff5f5; border: 1px solid #fed7d7; border-left: 5px solid #dc3545; color: #b91c1c; padding: 14px 18px; border-radius: 12px; margin-bottom: 18px;">
                <strong>Database error:</strong> <%= escHtml(dbError) %>
            </div>
        <% } %>

        <!-- Period Tabs -->
        <div class="period-tabs">
            <a href="<%= contextPath %>/staff/staff-report-view.jsp?period=daily" class="period-tab <%= "daily".equals(period) ? "active" : "" %>">
                <i class="fas fa-calendar-day"></i> Daily
            </a>
            <a href="<%= contextPath %>/staff/staff-report-view.jsp?period=weekly" class="period-tab <%= "weekly".equals(period) ? "active" : "" %>">
                <i class="fas fa-calendar-week"></i> Weekly
            </a>
            <a href="<%= contextPath %>/staff/staff-report-view.jsp?period=monthly" class="period-tab <%= "monthly".equals(period) ? "active" : "" %>">
                <i class="fas fa-calendar-alt"></i> Monthly
            </a>
        </div>

        <!-- Stats Summary -->
        <div class="stats-grid">
            <div class="stat-card highlight">
                <h3>Rs. <%= df.format(totalRevenue) %></h3>
                <p>Total Revenue</p>
            </div>
            <div class="stat-card">
                <h3><%= totalBookings %></h3>
                <p>Reservations</p>
            </div>
            <div class="stat-card">
                <h3><%= newGuests %></h3>
                <p>New Guests</p>
            </div>
            <div class="stat-card">
                <h3><%= paidBills %></h3>
                <p>Paid Bills</p>
            </div>
        </div>

        <!-- Report Details -->
        <div class="report-grid">
            <div class="report-card">
                <h3><i class="fas fa-chart-pie"></i> Revenue Breakdown</h3>
                <div class="summary-item">
                    <span class="label">Room Revenue</span>
                    <span class="value">Rs. <%= df.format(roomRevenue) %></span>
                </div>
                <div class="summary-item">
                    <span class="label">Additional Services</span>
                    <span class="value">Rs. <%= df.format(additionalRevenue) %></span>
                </div>
                <div class="summary-item">
                    <span class="label">Tax Collected</span>
                    <span class="value">Rs. <%= df.format(taxRevenue) %></span>
                </div>
                <div class="summary-item">
                    <span class="label">Discounts Given</span>
                    <span class="value danger">- Rs. <%= df.format(discountGiven) %></span>
                </div>
                <div class="total-row">
                    <span class="label">Net Revenue</span>
                    <span class="value">Rs. <%= df.format(totalRevenue) %></span>
                </div>
            </div>
            
            <div class="report-card">
                <h3><i class="fas fa-calendar-check"></i> Booking Summary</h3>
                <div class="summary-item">
                    <span class="label">Total Reservations</span>
                    <span class="value"><%= totalBookings %></span>
                </div>
                <div class="summary-item">
                    <span class="label">Confirmed</span>
                    <span class="value success"><%= confirmedBookings %></span>
                </div>
                <div class="summary-item">
                    <span class="label">Checked In</span>
                    <span class="value"><%= checkedInBookings %></span>
                </div>
                <div class="summary-item">
                    <span class="label">Checked Out</span>
                    <span class="value"><%= checkedOutBookings %></span>
                </div>
                <div class="summary-item">
                    <span class="label">Cancelled</span>
                    <span class="value danger"><%= cancelledBookings %></span>
                </div>
            </div>
            
            <div class="report-card">
                <h3><i class="fas fa-file-invoice"></i> Payment Summary</h3>
                <div class="summary-item">
                    <span class="label">Total Bills Generated</span>
                    <span class="value"><%= totalBills %></span>
                </div>
                <div class="summary-item">
                    <span class="label">Paid Bills</span>
                    <span class="value success"><%= paidBills %></span>
                </div>
                <div class="summary-item">
                    <span class="label">Pending Bills</span>
                    <span class="value warning"><%= pendingBills %></span>
                </div>
            </div>
            
            <div class="report-card">
                <h3><i class="fas fa-credit-card"></i> Payment Methods</h3>
                <div class="summary-item">
                    <span class="label">Cash Payments</span>
                    <span class="value"><%= cashPayments %></span>
                </div>
                <div class="summary-item">
                    <span class="label">Card Payments</span>
                    <span class="value"><%= cardPayments %></span>
                </div>
                <div class="summary-item">
                    <span class="label">Bank Transfers</span>
                    <span class="value"><%= bankPayments %></span>
                </div>
            </div>
        </div>

        <!-- Revenue Chart -->
        <div class="chart-card">
            <h3><i class="fas fa-chart-bar"></i> Revenue Distribution</h3>
            <div class="chart-container">
                <canvas id="revenueChart"></canvas>
            </div>
        </div>

        <!-- Recent Transactions -->
        <div class="report-card">
            <h3><i class="fas fa-list"></i> Recent Transactions</h3>
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Bill #</th>
                        <th>Guest</th>
                        <th>Room</th>
                        <th>Amount</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        if (conn != null) {
                            try {
                                Statement transStmt = conn.createStatement();
                                ResultSet transRs = transStmt.executeQuery(
                                    "SELECT b.bill_number, b.total_amount, b.payment_status, g.full_name, rm.room_number " +
                                    "FROM bills b JOIN reservations r ON b.reservation_id = r.reservation_id " +
                                    "JOIN guests g ON r.guest_id = g.guest_id JOIN rooms rm ON r.room_id = rm.room_id " +
                                    "WHERE " + dateCondition + " ORDER BY b.generated_at DESC LIMIT 10"
                                );
                                int rowCount = 0;
                                while (transRs.next()) {
                                    rowCount++;
                                    String payStatus = transRs.getString("payment_status");
                    %>
                    <tr>
                        <td><strong><%= transRs.getString("bill_number") %></strong></td>
                        <td><%= transRs.getString("full_name") %></td>
                        <td>Room <%= transRs.getString("room_number") %></td>
                        <td>Rs. <%= df.format(transRs.getDouble("total_amount")) %></td>
                        <td><span class="status-badge <%= "PAID".equals(payStatus) ? "paid" : "pending" %>"><%= payStatus %></span></td>
                    </tr>
                    <%
                                }
                                if (rowCount == 0) {
                                    out.println("<tr><td colspan='5' style='text-align:center; color:#666;'>No transactions found for this period</td></tr>");
                                }
                                transRs.close();
                                transStmt.close();
                            } catch (Exception e) {
                                out.println("<tr><td colspan='5'>Error loading transactions</td></tr>");
                            }
                        }
                    %>
                </tbody>
            </table>
        </div>
    </div>

    <script>
        const ctx = document.getElementById('revenueChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: ['Room Revenue', 'Additional Services', 'Tax Collected', 'Discounts'],
                datasets: [{
                    label: 'Amount (Rs.)',
                    data: [<%= roomRevenue %>, <%= additionalRevenue %>, <%= taxRevenue %>, <%= discountGiven %>],
                    backgroundColor: ['#008080', '#667eea', '#43e97b', '#f5576c'],
                    borderRadius: 8
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    y: { beginAtZero: true, grid: { color: 'rgba(0,0,0,0.05)' } },
                    x: { grid: { display: false } }
                }
            }
        });
    </script>
    
    <% if (conn != null) { try { conn.close(); } catch (SQLException e) {} } %>
</body>
</html>
