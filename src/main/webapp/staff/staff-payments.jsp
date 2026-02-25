<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
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
    int totalPayments = 0, paidCount = 0, pendingCount = 0, partialCount = 0;
    double totalRevenue = 0, paidAmount = 0, pendingAmount = 0;
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        // Get statistics
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM bills");
        if (rs.next()) totalPayments = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*), COALESCE(SUM(total_amount), 0) FROM bills WHERE payment_status = 'PAID'");
        if (rs.next()) { paidCount = rs.getInt(1); paidAmount = rs.getDouble(2); }
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*), COALESCE(SUM(total_amount), 0) FROM bills WHERE payment_status = 'PENDING'");
        if (rs.next()) { pendingCount = rs.getInt(1); pendingAmount = rs.getDouble(2); }
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM bills WHERE payment_status = 'PARTIAL'");
        if (rs.next()) partialCount = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COALESCE(SUM(total_amount), 0) FROM bills");
        if (rs.next()) totalRevenue = rs.getDouble(1);
        rs.close();
        
        stmt.close();
    } catch (Exception e) {
        dbError = e.getMessage();
        e.printStackTrace();
    }
    
    DecimalFormat df = new DecimalFormat("#,##0.00");
%>
<%!
    // Helper method to escape HTML attribute values
    public String escHtml(String str) {
        if (str == null) return "";
        return str.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }

    public String escJs(String str) {
        if (str == null) return "";
        return str.replace("\\", "\\\\").replace("'", "\\'").replace("\r", " ").replace("\n", " ");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payments - Ocean View Resort Staff</title>
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
            --warning: #ffc107;
            --danger: #dc3545;
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
        
        .header-left h1 { font-size: 24px; font-weight: 600; }
        .header-left h1 i { margin-right: 10px; }
        .header-left p { font-size: 13px; opacity: 0.9; margin-top: 5px; }
        .header-actions { display: flex; gap: 15px; }
        
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
        
        .btn-back:hover { background: rgba(255,255,255,0.3); transform: translateY(-2px); }
        
        /* Main Content */
        .main-content {
            max-width: 1600px;
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
        
        @media (max-width: 1200px) { .stats-grid { grid-template-columns: repeat(2, 1fr); } }
        @media (max-width: 600px) { .stats-grid { grid-template-columns: 1fr; } }
        
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
        
        .stat-card:hover { transform: translateY(-5px); }
        
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
        .stat-icon.paid { background: linear-gradient(135deg, #10b981 0%, #34d399 100%); color: white; }
        .stat-icon.pending { background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%); color: white; }
        .stat-icon.partial { background: linear-gradient(135deg, #3b82f6 0%, #60a5fa 100%); color: white; }
        
        .stat-info h3 { font-size: 26px; font-weight: 700; color: var(--text); }
        .stat-info p { font-size: 13px; color: var(--text-light); }
        .stat-info .amount { font-size: 14px; color: var(--primary); font-weight: 600; }
        
        /* Filter Section */
        .filter-card {
            background: var(--card-bg);
            border-radius: 15px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            margin-bottom: 30px;
            padding: 20px 25px;
        }
        
        .filter-row {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            align-items: center;
        }
        
        .filter-group { display: flex; flex-direction: column; gap: 5px; }
        .filter-group label { font-size: 12px; font-weight: 600; color: var(--text-light); text-transform: uppercase; }
        
        .filter-control {
            padding: 10px 15px;
            border: 2px solid var(--border);
            border-radius: 10px;
            font-size: 14px;
            font-family: 'Poppins', sans-serif;
            min-width: 180px;
            transition: all 0.3s ease;
        }
        
        .filter-control:focus { border-color: var(--primary); outline: none; }
        
        .search-box {
            display: flex;
            align-items: center;
            background: var(--bg);
            border: 2px solid var(--border);
            border-radius: 10px;
            padding: 8px 15px;
            min-width: 300px;
            transition: all 0.3s ease;
        }
        
        .search-box:focus-within { border-color: var(--primary); }
        .search-box i { color: var(--text-light); margin-right: 10px; }
        .search-box input { border: none; background: none; outline: none; font-family: 'Poppins', sans-serif; font-size: 14px; width: 100%; }
        
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
            background: linear-gradient(135deg, var(--primary) 0%, var(--glow) 100%);
            color: white;
        }
        
        .table-header h3 { font-size: 18px; font-weight: 600; display: flex; align-items: center; gap: 10px; }
        
        .table-wrapper { overflow-x: auto; }
        
        .data-table { width: 100%; border-collapse: collapse; }
        .data-table th { background: var(--bg); padding: 15px; text-align: left; font-size: 12px; font-weight: 600; color: var(--text-light); text-transform: uppercase; white-space: nowrap; }
        .data-table td { padding: 15px; border-bottom: 1px solid var(--border); vertical-align: middle; }
        .data-table tr:hover { background: #f8f9fa; }
        
        .bill-number { font-weight: 700; color: var(--primary-dark); font-size: 14px; }
        
        .status-badge {
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            display: inline-block;
        }
        
        .status-badge.paid { background: #d1fae5; color: #059669; }
        .status-badge.pending { background: #fef3c7; color: #d97706; }
        .status-badge.partial { background: #dbeafe; color: #2563eb; }
        
        .amount { font-weight: 700; color: var(--primary-dark); }
        
        .action-btn {
            padding: 8px 15px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            font-size: 13px;
            font-family: 'Poppins', sans-serif;
            margin-right: 5px;
            margin-bottom: 5px;
        }
        
        .action-btn.view { background: #e3f2fd; color: #1976d2; }
        .action-btn.print { background: #e8f5e9; color: #388e3c; }
        .action-btn:hover { transform: scale(1.05); }
        
        /* Modal */
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
        
        .modal-overlay.active { opacity: 1; visibility: visible; }
        
        .modal {
            background: white;
            border-radius: 20px;
            width: 100%;
            max-width: 750px;
            max-height: 90vh;
            overflow: hidden;
            transform: scale(0.9);
            transition: transform 0.3s ease;
        }
        
        .modal-overlay.active .modal { transform: scale(1); }
        
        .modal-header {
            padding: 25px 30px;
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
            color: white;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-header h3 { font-size: 20px; font-weight: 600; display: flex; align-items: center; gap: 10px; }
        
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
        
        .modal-close:hover { background: rgba(255,255,255,0.3); transform: rotate(90deg); }
        
        .modal-body { padding: 30px; max-height: 60vh; overflow-y: auto; }
        .modal-footer { padding: 20px 30px; background: #f8f9fa; display: flex; justify-content: flex-end; gap: 15px; }
        
        .btn-primary {
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
            color: white;
        }
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(0, 128, 128, 0.3); }
        
        .btn-secondary { background: #e0e0e0; color: var(--text); }
        
        .empty-state { text-align: center; padding: 60px 20px; }
        .empty-state i { font-size: 60px; color: var(--primary); opacity: 0.3; margin-bottom: 15px; }
        .empty-state h3 { color: var(--text); margin-bottom: 8px; }
        .empty-state p { color: var(--text-light); }
        
        /* Invoice Preview Styles */
        .invoice-preview { padding: 10px; }
        .invoice-header-preview {
            display: flex;
            justify-content: space-between;
            padding-bottom: 15px;
            margin-bottom: 20px;
            border-bottom: 3px solid var(--primary);
        }
        .hotel-info-preview h3 { color: var(--primary-dark); font-size: 18px; margin-bottom: 3px; }
        .invoice-meta-preview { text-align: right; }
        .invoice-meta-preview h4 { font-size: 22px; margin-bottom: 5px; }
        .guest-room-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }
        .detail-box-preview {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 10px;
        }
        .detail-box-preview h5 {
            color: var(--primary-dark);
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
            padding-bottom: 5px;
            border-bottom: 1px solid var(--border);
        }
        .detail-box-preview p {
            font-size: 13px;
            margin-bottom: 5px;
            color: var(--text);
        }
        .detail-box-preview p strong { color: #666; font-weight: 500; }
        .amount-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
            font-size: 13px;
        }
        .amount-table td {
            padding: 10px;
            border-bottom: 1px solid #eee;
        }
        .amount-table .total-row {
            background: #f8f9fa;
            border-top: 2px solid var(--primary);
        }
        .amount-table .total-row td {
            font-size: 15px;
            color: var(--primary-dark);
            padding: 12px 10px;
        }
        .payment-info-box {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 10px;
        }
        .payment-info-box h5 {
            color: var(--primary-dark);
            font-size: 13px;
            text-transform: uppercase;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .payment-grid { display: flex; gap: 20px; flex-wrap: wrap; }
        .payment-grid p { font-size: 13px; }
        
        @media (max-width: 768px) {
            .header { padding: 15px 20px; flex-direction: column; gap: 15px; }
            .filter-row { flex-direction: column; align-items: stretch; }
            .search-box { min-width: 100%; }
            .guest-room-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="header-left">
            <h1><i class="fas fa-credit-card"></i> Payments</h1>
            <p><i class="fas fa-user"></i> Staff: <%= fullName %></p>
        </div>
        <div class="header-actions">
            <a href="<%= contextPath %>/staff/staff-dashboard.jsp" class="btn btn-back"><i class="fas fa-arrow-left"></i> Back to Dashboard</a>
        </div>
    </header>
    
    <!-- Main Content -->
    <main class="main-content">
        <% if (dbError != null) { %>
            <script>
                Swal.fire({
                    icon: 'error',
                    title: 'Database Error',
                    text: '<%= escJs(dbError) %>',
                    confirmButtonColor: '#008080'
                });
            </script>
        <% } %>
        <!-- Stats Cards -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon total"><i class="fas fa-file-invoice-dollar"></i></div>
                <div class="stat-info">
                    <h3><%= totalPayments %></h3>
                    <p>Total Payments</p>
                    <span class="amount">Rs. <%= df.format(totalRevenue) %></span>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon paid"><i class="fas fa-check-circle"></i></div>
                <div class="stat-info">
                    <h3><%= paidCount %></h3>
                    <p>Paid</p>
                    <span class="amount">Rs. <%= df.format(paidAmount) %></span>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon pending"><i class="fas fa-clock"></i></div>
                <div class="stat-info">
                    <h3><%= pendingCount %></h3>
                    <p>Pending</p>
                    <span class="amount">Rs. <%= df.format(pendingAmount) %></span>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon partial"><i class="fas fa-adjust"></i></div>
                <div class="stat-info">
                    <h3><%= partialCount %></h3>
                    <p>Partial</p>
                </div>
            </div>
        </div>
        
        <!-- Pending Charges Section -->
        <% if (pendingCount > 0) { %>
        <div class="table-card" style="border-left: 4px solid #ffc107; margin-bottom: 25px;">
            <div class="table-header" style="background: linear-gradient(135deg, #fff3cd, #ffeeba);">
                <h3 style="color: #856404;"><i class="fas fa-exclamation-triangle"></i> Pending Charges - Customers Awaiting Payment</h3>
            </div>
            <div class="table-wrapper">
                <table class="data-table" id="pendingTable">
                    <thead>
                        <tr>
                            <th>Bill #</th>
                            <th>Guest Name</th>
                            <th>Phone</th>
                            <th>Room</th>
                            <th>Check-In</th>
                            <th>Check-Out</th>
                            <th>Total Amount</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                String pendingSql = "SELECT b.bill_id, b.bill_number, b.total_amount, b.reservation_id, " +
                                    "r.reservation_number, r.check_in_date, r.check_out_date, " +
                                    "g.full_name as guest_name, g.phone as guest_phone, " +
                                    "rm.room_number, rt.type_name " +
                                    "FROM bills b " +
                                    "JOIN reservations r ON b.reservation_id = r.reservation_id " +
                                    "JOIN guests g ON r.guest_id = g.guest_id " +
                                    "JOIN rooms rm ON r.room_id = rm.room_id " +
                                    "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
                                    "WHERE b.payment_status = 'PENDING' " +
                                    "ORDER BY r.check_out_date ASC";
                                Statement pendingStmt = conn.createStatement();
                                ResultSet pendingRs = pendingStmt.executeQuery(pendingSql);
                                SimpleDateFormat pendingDateFormat = new SimpleDateFormat("MMM dd, yyyy");
                                
                                while (pendingRs.next()) {
                                    String pBillNumber = pendingRs.getString("bill_number");
                                    String pGuestName = pendingRs.getString("guest_name");
                                    String pGuestPhone = pendingRs.getString("guest_phone") != null ? pendingRs.getString("guest_phone") : "-";
                                    String pRoomNumber = pendingRs.getString("room_number");
                                    String pRoomType = pendingRs.getString("type_name");
                                    java.sql.Date pCheckIn = pendingRs.getDate("check_in_date");
                                    java.sql.Date pCheckOut = pendingRs.getDate("check_out_date");
                                    double pTotalAmount = pendingRs.getDouble("total_amount");
                                    int pReservationId = pendingRs.getInt("reservation_id");
                        %>
                        <tr>
                            <td><span class="bill-number"><%= pBillNumber %></span></td>
                            <td><strong><%= pGuestName %></strong></td>
                            <td><i class="fas fa-phone" style="color: var(--primary); margin-right: 5px;"></i><%= pGuestPhone %></td>
                            <td><%= pRoomNumber %> (<%= pRoomType %>)</td>
                            <td><%= pCheckIn != null ? pendingDateFormat.format(pCheckIn) : "-" %></td>
                            <td><%= pCheckOut != null ? pendingDateFormat.format(pCheckOut) : "-" %></td>
                            <td><span class="amount" style="color: #dc3545; font-weight: 600;">Rs. <%= df.format(pTotalAmount) %></span></td>
                            <td>
                                <a href="<%= contextPath %>/staff/staff-payment.jsp?reservationId=<%= pReservationId %>" 
                                   class="action-btn" style="background: linear-gradient(135deg, var(--primary), var(--glow)); color: white; padding: 8px 15px; border-radius: 8px; text-decoration: none; display: inline-flex; align-items: center; gap: 5px;">
                                    <i class="fas fa-credit-card"></i> Process Payment
                                </a>
                            </td>
                        </tr>
                        <% } pendingRs.close(); pendingStmt.close(); } catch (Exception e) { e.printStackTrace(); } %>
                    </tbody>
                </table>
            </div>
        </div>
        <% } %>
        
        <!-- Filter Section -->
        <div class="filter-card">
            <div class="filter-row">
                <div class="search-box">
                    <i class="fas fa-search"></i>
                    <input type="text" id="searchInput" placeholder="Search by bill #, reservation #..." onkeyup="filterPayments()">
                </div>
                <div class="filter-group">
                    <label>Status</label>
                    <select class="filter-control" id="statusFilter" onchange="filterPayments()">
                        <option value="">All Status</option>
                        <option value="PAID">Paid</option>
                        <option value="PENDING">Pending</option>
                        <option value="PARTIAL">Partial</option>
                    </select>
                </div>
                <div class="filter-group">
                    <label>Payment Method</label>
                    <select class="filter-control" id="methodFilter" onchange="filterPayments()">
                        <option value="">All Methods</option>
                        <option value="CASH">Cash</option>
                        <option value="CARD">Card</option>
                        <option value="BANK_TRANSFER">Bank Transfer</option>
                        <option value="ONLINE">Online</option>
                        <option value="MOBILE_PAYMENT">Mobile Payment</option>
                    </select>
                </div>
                <div class="filter-group" style="align-self: flex-end;">
                    <button type="button" class="btn" onclick="clearFilters()" style="background: #e74c3c; color: white; padding: 10px 20px;">
                        <i class="fas fa-times"></i> Clear Filters
                    </button>
                </div>
            </div>
        </div>
        
        <!-- Payments Table -->
        <div class="table-card">
            <div class="table-header">
                <h3><i class="fas fa-list"></i> All Payments</h3>
            </div>
            <div class="table-wrapper">
                <table class="data-table" id="paymentsTable">
                    <thead>
                        <tr>
                            <th>Bill #</th>
                            <th>Reservation</th>
                            <th>Guest</th>
                            <th>Room Total</th>
                            <th>Tax</th>
                            <th>Total Amount</th>
                            <th>Status</th>
                            <th>Method</th>
                            <th>Generated At</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            if (conn == null) {
                                out.println("<tr><td colspan='10' style='text-align:center; color:red;'>Database connection failed.</td></tr>");
                            } else {
                            int rowCount = 0;
                            try {
                                String sql = "SELECT b.*, r.reservation_number, r.check_in_date, r.check_out_date, " +
                                    "g.full_name as guest_name, g.phone as guest_phone, g.email as guest_email, g.address as guest_address, " +
                                    "rm.room_number, rt.type_name, rt.rate_per_night " +
                                    "FROM bills b " +
                                    "JOIN reservations r ON b.reservation_id = r.reservation_id " +
                                    "JOIN guests g ON r.guest_id = g.guest_id " +
                                    "JOIN rooms rm ON r.room_id = rm.room_id " +
                                    "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
                                    "ORDER BY b.generated_at DESC";
                                Statement payStmt = conn.createStatement();
                                ResultSet payRs = payStmt.executeQuery(sql);
                                
                                SimpleDateFormat dateTimeFormat = new SimpleDateFormat("MMM dd, yyyy HH:mm");
                                SimpleDateFormat dateFormat = new SimpleDateFormat("MMM dd, yyyy");
                                
                                while (payRs.next()) {
                                    rowCount++;
                                    int billId = payRs.getInt("bill_id");
                                    String billNumber = payRs.getString("bill_number");
                                    String resNumber = payRs.getString("reservation_number");
                                    String guestName = payRs.getString("guest_name");
                                    String guestPhone = payRs.getString("guest_phone") != null ? payRs.getString("guest_phone") : "-";
                                    String guestEmail = payRs.getString("guest_email") != null ? payRs.getString("guest_email") : "-";
                                    String guestAddress = payRs.getString("guest_address") != null ? payRs.getString("guest_address") : "-";
                                    String roomNumber = payRs.getString("room_number");
                                    String roomType = payRs.getString("type_name");
                                    double roomRate = payRs.getDouble("rate_per_night");
                                    java.sql.Date checkInDate = payRs.getDate("check_in_date");
                                    java.sql.Date checkOutDate = payRs.getDate("check_out_date");
                                    int nights = payRs.getInt("number_of_nights");
                                    double roomTotal = payRs.getDouble("room_total");
                                    double taxAmount = payRs.getDouble("tax_amount");
                                    double totalAmount = payRs.getDouble("total_amount");
                                    String payStatus = payRs.getString("payment_status");
                                    String payMethod = payRs.getString("payment_method");
                                    Timestamp generatedAt = payRs.getTimestamp("generated_at");
                                    String statusClass = payStatus != null ? payStatus.toLowerCase() : "pending";
                                    double serviceCharge = payRs.getDouble("service_charge");
                                    double discount = payRs.getDouble("discount");
                                    int reservationId = payRs.getInt("reservation_id");
                                    Timestamp paidAt = payRs.getTimestamp("paid_at");
                        %>
                        <tr data-id="<%= billId %>" 
                            data-status="<%= payStatus %>" 
                            data-method="<%= payMethod != null ? payMethod : "" %>"
                            data-search="<%= escHtml(billNumber.toLowerCase() + " " + resNumber.toLowerCase() + " " + guestName.toLowerCase()) %>"
                            data-bill-number="<%= escHtml(billNumber) %>"
                            data-res-number="<%= escHtml(resNumber) %>"
                            data-guest-name="<%= escHtml(guestName) %>"
                            data-guest-phone="<%= escHtml(guestPhone) %>"
                            data-guest-email="<%= escHtml(guestEmail) %>"
                            data-guest-address="<%= escHtml(guestAddress) %>"
                            data-room-number="<%= escHtml(roomNumber) %>"
                            data-room-type="<%= escHtml(roomType) %>"
                            data-room-rate="<%= df.format(roomRate) %>"
                            data-check-in="<%= checkInDate != null ? dateFormat.format(checkInDate) : "-" %>"
                            data-check-out="<%= checkOutDate != null ? dateFormat.format(checkOutDate) : "-" %>"
                            data-nights="<%= nights %>"
                            data-room-total="<%= df.format(roomTotal) %>"
                            data-tax-amount="<%= df.format(taxAmount) %>"
                            data-total-amount="<%= df.format(totalAmount) %>"
                            data-service-charge="<%= df.format(serviceCharge) %>"
                            data-discount="<%= df.format(discount) %>"
                            data-generated-at="<%= generatedAt != null ? dateTimeFormat.format(generatedAt) : "-" %>"
                            data-paid-at="<%= paidAt != null ? dateTimeFormat.format(paidAt) : "-" %>"
                            data-reservation-id="<%= reservationId %>">
                            <td><span class="bill-number"><%= escHtml(billNumber) %></span></td>
                            <td><%= escHtml(resNumber) %></td>
                            <td><%= escHtml(guestName) %></td>
                            <td>Rs. <%= df.format(roomTotal) %></td>
                            <td>Rs. <%= df.format(taxAmount) %></td>
                            <td><span class="amount">Rs. <%= df.format(totalAmount) %></span></td>
                            <td><span class="status-badge <%= statusClass %>"><%= payStatus %></span></td>
                            <td><%= payMethod != null ? payMethod : "-" %></td>
                            <td><%= generatedAt != null ? dateTimeFormat.format(generatedAt) : "-" %></td>
                            <td>
                                <button class="action-btn view" onclick="viewPaymentFromRow(this)">
                                    <i class="fas fa-eye"></i> View
                                </button>
                                <% if ("PENDING".equals(payStatus)) { %>
                                <a class="action-btn" href="<%= contextPath %>/staff/staff-payment.jsp?reservationId=<%= reservationId %>" style="background:var(--primary);color:white;">
                                    <i class="fas fa-credit-card"></i> Pay
                                </a>
                                <% } %>
                                <a class="action-btn print" href="staff-invoice.jsp?billId=<%= billId %>" target="_blank">
                                    <i class="fas fa-print"></i> Print
                                </a>
                            </td>
                        </tr>
                        <% } 
                        if (rowCount == 0) {
                            out.println("<tr><td colspan='10' style='text-align:center; padding:40px; color:var(--text-light);'><i class='fas fa-file-invoice' style='font-size:40px; opacity:0.3; display:block; margin-bottom:15px;'></i>No payments found</td></tr>");
                        }
                        payRs.close(); payStmt.close(); } catch (Exception e) { out.println("<tr><td colspan='10' style='color:red;'>Error: " + e.getMessage() + "</td></tr>"); } } %>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
    
    <!-- View Payment Modal -->
    <div class="modal-overlay" id="viewModal">
        <div class="modal">
            <div class="modal-header">
                <h3><i class="fas fa-file-invoice-dollar"></i> Payment Details</h3>
                <button class="modal-close" onclick="closeModal('viewModal')">&times;</button>
            </div>
            <div class="modal-body" id="viewModalBody">
                <!-- Content populated by JavaScript -->
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" onclick="closeModal('viewModal')">Close</button>
                <a class="btn btn-primary" id="printFromModal" href="#" target="_blank"><i class="fas fa-print"></i> Print Invoice</a>
            </div>
        </div>
    </div>
    
    <script>
        var currentBillId = null;
        const contextPath = '<%= contextPath %>';
        
        // Filter payments
        function filterPayments() {
            const searchText = document.getElementById('searchInput').value.toLowerCase();
            const statusFilter = document.getElementById('statusFilter').value;
            const methodFilter = document.getElementById('methodFilter').value;
            
            const rows = document.querySelectorAll('#paymentsTable tbody tr');
            
            rows.forEach(row => {
                const searchData = row.getAttribute('data-search');
                const rowStatus = row.getAttribute('data-status');
                const rowMethod = row.getAttribute('data-method');
                
                let showRow = true;
                
                // Search filter
                if (searchText && searchData && !searchData.includes(searchText)) {
                    showRow = false;
                }
                
                // Status filter
                if (statusFilter && rowStatus !== statusFilter) {
                    showRow = false;
                }
                
                // Method filter
                if (methodFilter && rowMethod !== methodFilter) {
                    showRow = false;
                }
                
                row.style.display = showRow ? '' : 'none';
            });
        }
        
        // Clear all filters
        function clearFilters() {
            document.getElementById('searchInput').value = '';
            document.getElementById('statusFilter').value = '';
            document.getElementById('methodFilter').value = '';
            filterPayments();
        }
        
        // View payment details from row
        function viewPaymentFromRow(button) {
            try {
                var row = button.closest('tr');
                currentBillId = row.getAttribute('data-id');
                
                var billNumber = row.getAttribute('data-bill-number') || '-';
                var resNumber = row.getAttribute('data-res-number') || '-';
                var guestName = row.getAttribute('data-guest-name') || '-';
                var guestPhone = row.getAttribute('data-guest-phone') || '-';
                var guestEmail = row.getAttribute('data-guest-email') || '-';
                var guestAddress = row.getAttribute('data-guest-address') || '-';
                var roomNumber = row.getAttribute('data-room-number') || '-';
                var roomType = row.getAttribute('data-room-type') || '-';
                var roomRate = row.getAttribute('data-room-rate') || '0.00';
                var checkIn = row.getAttribute('data-check-in') || '-';
                var checkOut = row.getAttribute('data-check-out') || '-';
                var nights = row.getAttribute('data-nights') || '0';
                var roomTotal = row.getAttribute('data-room-total') || '0.00';
                var taxAmount = row.getAttribute('data-tax-amount') || '0.00';
                var totalAmount = row.getAttribute('data-total-amount') || '0.00';
                var serviceCharge = row.getAttribute('data-service-charge') || '0.00';
                var discount = row.getAttribute('data-discount') || '0.00';
                var paymentStatus = row.getAttribute('data-status') || '-';
                var paymentMethod = row.getAttribute('data-method') || '-';
                var generatedAt = row.getAttribute('data-generated-at') || '-';
                var paidAt = row.getAttribute('data-paid-at') || '-';
                
                var statusClass = paymentStatus ? paymentStatus.toLowerCase() : 'pending';
                
                var html = '<div class="invoice-preview">' +
                    '<div class="invoice-header-preview">' +
                    '<div class="hotel-info-preview">' +
                    '<img src="' + contextPath + '/images/logo.png" alt="Ocean View Resort" style="height: 50px; margin-bottom: 8px;" onerror="this.style.display=\'none\'">' +
                    '<h3>Ocean View Resort</h3>' +
                    '<p style="font-size: 12px; color: #666;">No. 123, Beach Road, Unawatuna, Galle</p>' +
                    '</div>' +
                    '<div class="invoice-meta-preview">' +
                    '<h4 style="color: var(--primary);">INVOICE</h4>' +
                    '<p style="font-weight: 600;">' + billNumber + '</p>' +
                    '<p style="font-size: 12px;">Reservation: ' + resNumber + '</p>' +
                    '<p style="font-size: 12px;">Date: ' + generatedAt + '</p>' +
                    '<span class="status-badge ' + statusClass + '">' + paymentStatus + '</span>' +
                    '</div></div>' +
                    '<div class="guest-room-grid">' +
                    '<div class="detail-box-preview"><h5>Bill To</h5>' +
                    '<p><strong>Name:</strong> ' + guestName + '</p>' +
                    '<p><strong>Phone:</strong> ' + guestPhone + '</p>' +
                    '<p><strong>Email:</strong> ' + guestEmail + '</p>' +
                    '<p><strong>Address:</strong> ' + guestAddress + '</p></div>' +
                    '<div class="detail-box-preview"><h5>Stay Details</h5>' +
                    '<p><strong>Room:</strong> ' + roomNumber + ' (' + roomType + ')</p>' +
                    '<p><strong>Check-in:</strong> ' + checkIn + '</p>' +
                    '<p><strong>Check-out:</strong> ' + checkOut + '</p>' +
                    '<p><strong>Duration:</strong> ' + nights + ' Night(s)</p></div></div>' +
                    '<table class="amount-table">' +
                    '<tr><td>Room Rate</td><td>Rs. ' + roomRate + ' x ' + nights + ' nights</td><td style="text-align:right;">Rs. ' + roomTotal + '</td></tr>' +
                    '<tr><td>Service Charge</td><td></td><td style="text-align:right;">Rs. ' + serviceCharge + '</td></tr>' +
                    '<tr><td>Discount</td><td></td><td style="text-align:right; color: #28a745;">- Rs. ' + discount + '</td></tr>' +
                    '<tr><td>Tax (VAT)</td><td></td><td style="text-align:right;">Rs. ' + taxAmount + '</td></tr>' +
                    '<tr class="total-row"><td colspan="2"><strong>Grand Total</strong></td><td style="text-align:right;"><strong>Rs. ' + totalAmount + '</strong></td></tr>' +
                    '</table>' +
                    '<div class="payment-info-box">' +
                    '<h5><i class="fas fa-credit-card"></i> Payment Information</h5>' +
                    '<div class="payment-grid">' +
                    '<p><strong>Method:</strong> ' + (paymentMethod || '-') + '</p>' +
                    '<p><strong>Status:</strong> <span class="status-badge ' + statusClass + '">' + paymentStatus + '</span></p>' +
                    '<p><strong>Paid At:</strong> ' + paidAt + '</p>' +
                    '</div></div></div>';
                
                document.getElementById('viewModalBody').innerHTML = html;
                document.getElementById('printFromModal').href = contextPath + '/staff/staff-invoice.jsp?billId=' + currentBillId;
                document.getElementById('viewModal').classList.add('active');
            } catch (error) {
                console.error('Error in viewPaymentFromRow:', error);
                Swal.fire({ icon: 'error', title: 'Error', text: 'Failed to open payment details.', confirmButtonColor: '#008080' });
            }
        }
        
        // Close modal
        function closeModal(modalId) {
            document.getElementById(modalId).classList.remove('active');
        }
        
        // Close modal on outside click
        document.querySelectorAll('.modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', function(e) {
                if (e.target === this) {
                    this.classList.remove('active');
                }
            });
        });
        
        // Close modal on Escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                document.querySelectorAll('.modal-overlay.active').forEach(modal => {
                    modal.classList.remove('active');
                });
            }
        });
    </script>
    
<%
    // Close database connection
    if (conn != null) {
        try { conn.close(); } catch (Exception e) {}
    }
%>
</body>
</html>
