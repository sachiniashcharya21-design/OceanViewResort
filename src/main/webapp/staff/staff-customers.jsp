<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%
    // Check if user is logged in and is staff
    String userRole = (String) session.getAttribute("userRole");
    String username = (String) session.getAttribute("username");
    
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

    int selectedRoomId = 0;
    try { selectedRoomId = Integer.parseInt(request.getParameter("roomId")); } catch (Exception ignore) {}
    
    String successMessage = null, errorMessage = null;
    
    // Statistics
    int totalCustomers = 0, withBookings = 0, newThisMonth = 0;
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        // Handle form submissions
        String action = request.getParameter("action");
        
        // Add Customer
        if ("addCustomer".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            String fullName = request.getParameter("fullName");
            String nicPassport = request.getParameter("nicPassport");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String nationality = request.getParameter("nationality");
            String address = request.getParameter("address");

            fullName = fullName != null ? fullName.trim() : "";
            nicPassport = nicPassport != null ? nicPassport.trim() : "";

            if (fullName.isEmpty() || nicPassport.isEmpty()) {
                errorMessage = "Full name and NIC/Passport are required.";
            } else {
                // Check if NIC/Passport exists
                PreparedStatement checkPs = conn.prepareStatement("SELECT guest_id FROM guests WHERE nic_passport = ?");
                checkPs.setString(1, nicPassport);
                ResultSet checkRs = checkPs.executeQuery();

                if (checkRs.next()) {
                    errorMessage = "NIC/Passport '" + nicPassport + "' already exists.";
                } else {
                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO guests (full_name, nic_passport, email, phone, nationality, address) VALUES (?, ?, ?, ?, ?, ?)"
                    );
                    ps.setString(1, fullName);
                    ps.setString(2, nicPassport);
                    ps.setString(3, email);
                    ps.setString(4, phone);
                    ps.setString(5, nationality);
                    ps.setString(6, address);
                    ps.executeUpdate();
                    ps.close();
                    successMessage = "Customer '" + fullName + "' registered successfully!";
                }
                checkRs.close();
                checkPs.close();
            }
        }
        
        // Edit Customer
        if ("editCustomer".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            int guestId = Integer.parseInt(request.getParameter("guestId"));
            String fullName = request.getParameter("fullName");
            String nicPassport = request.getParameter("nicPassport");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String nationality = request.getParameter("nationality");
            String address = request.getParameter("address");
            
            fullName = fullName != null ? fullName.trim() : "";
            nicPassport = nicPassport != null ? nicPassport.trim() : "";

            if (fullName.isEmpty() || nicPassport.isEmpty()) {
                errorMessage = "Full name and NIC/Passport are required.";
            } else {
                PreparedStatement checkPs = conn.prepareStatement(
                    "SELECT guest_id FROM guests WHERE nic_passport = ? AND guest_id <> ?"
                );
                checkPs.setString(1, nicPassport);
                checkPs.setInt(2, guestId);
                ResultSet checkRs = checkPs.executeQuery();

                if (checkRs.next()) {
                    errorMessage = "NIC/Passport '" + nicPassport + "' already exists for another customer.";
                } else {
                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE guests SET full_name = ?, nic_passport = ?, email = ?, phone = ?, nationality = ?, address = ? WHERE guest_id = ?"
                    );
                    ps.setString(1, fullName);
                    ps.setString(2, nicPassport);
                    ps.setString(3, email);
                    ps.setString(4, phone);
                    ps.setString(5, nationality);
                    ps.setString(6, address);
                    ps.setInt(7, guestId);
                    ps.executeUpdate();
                    ps.close();
                    successMessage = "Customer updated successfully!";
                }
                checkRs.close();
                checkPs.close();
            }
        }
        
        // Delete Customer
        if ("deleteCustomer".equals(action)) {
            int guestId = Integer.parseInt(request.getParameter("guestId"));
            
            // Check for existing reservations
            PreparedStatement checkPs = conn.prepareStatement("SELECT COUNT(*) FROM reservations WHERE guest_id = ?");
            checkPs.setInt(1, guestId);
            ResultSet checkRs = checkPs.executeQuery();
            checkRs.next();
            int reservationCount = checkRs.getInt(1);
            checkRs.close();
            checkPs.close();
            
            if (reservationCount > 0) {
                errorMessage = "Cannot delete customer with existing reservations.";
            } else {
                PreparedStatement ps = conn.prepareStatement("DELETE FROM guests WHERE guest_id = ?");
                ps.setInt(1, guestId);
                ps.executeUpdate();
                ps.close();
                successMessage = "Customer deleted successfully!";
            }
        }
        
        // Get statistics
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM guests");
        if (rs.next()) totalCustomers = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(DISTINCT guest_id) FROM reservations");
        if (rs.next()) withBookings = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM guests WHERE MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE())");
        if (rs.next()) newThisMonth = rs.getInt(1);
        rs.close();
        
        stmt.close();
    } catch (Exception e) {
        errorMessage = "Error: " + e.getMessage();
        e.printStackTrace();
    }
    
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
%>
<%!
    public String escHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    public String escJs(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\")
                .replace("'", "\\'")
                .replace("\r", " ")
                .replace("\n", " ");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Customer Management - Ocean View Resort Staff</title>
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
        
        .header-left h1 { font-size: 24px; font-weight: 600; }
        .header-left h1 i { margin-right: 10px; }
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
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        /* Stats Cards */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        
        @media (max-width: 768px) { .stats-grid { grid-template-columns: 1fr; } }
        
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
        .stat-icon.bookings { background: linear-gradient(135deg, #10b981 0%, #34d399 100%); color: white; }
        .stat-icon.new { background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%); color: white; }
        
        .stat-info h3 { font-size: 26px; font-weight: 700; color: var(--text); }
        .stat-info p { font-size: 13px; color: var(--text-light); }
        
        /* Registration Card */
        .register-card {
            background: var(--card-bg);
            border-radius: 15px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            margin-bottom: 30px;
            overflow: hidden;
        }
        
        .register-header {
            padding: 20px 25px;
            background: linear-gradient(135deg, var(--primary) 0%, var(--glow) 100%);
            color: white;
        }
        
        .register-header h3 { font-size: 18px; display: flex; align-items: center; gap: 10px; }
        
        .register-body { padding: 25px; }
        
        .form-row {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
        }
        
        @media (max-width: 900px) { .form-row { grid-template-columns: repeat(2, 1fr); } }
        @media (max-width: 500px) { .form-row { grid-template-columns: 1fr; } }
        
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; font-weight: 500; color: var(--text); font-size: 14px; margin-bottom: 8px; }
        .form-group label i { color: var(--primary); margin-right: 6px; }
        
        .form-control {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid var(--border);
            border-radius: 10px;
            font-size: 14px;
            font-family: 'Poppins', sans-serif;
            transition: all 0.3s ease;
        }
        
        .form-control:focus { border-color: var(--primary); outline: none; box-shadow: 0 0 0 3px rgba(0, 128, 128, 0.1); }
        
        .register-footer {
            padding: 20px 25px;
            background: #f8f9fa;
            text-align: center;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
            color: white;
            padding: 14px 40px;
            font-size: 15px;
        }
        
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(0, 128, 128, 0.3); }
        
        .btn-secondary { background: #e0e0e0; color: var(--text); }
        .btn-secondary:hover { background: #d0d0d0; }
        
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
        
        .table-header h3 { font-size: 18px; font-weight: 600; color: var(--text); display: flex; align-items: center; gap: 10px; }
        
        .search-box {
            display: flex;
            align-items: center;
            background: var(--bg);
            border-radius: 10px;
            padding: 8px 15px;
            min-width: 250px;
        }
        
        .search-box i { color: var(--text-light); margin-right: 10px; }
        .search-box input { border: none; background: none; outline: none; font-family: 'Poppins', sans-serif; font-size: 14px; width: 100%; }
        
        .table-wrapper { overflow-x: auto; }
        
        .data-table { width: 100%; border-collapse: collapse; }
        .data-table th { background: var(--bg); padding: 15px; text-align: left; font-size: 13px; font-weight: 600; color: var(--text-light); text-transform: uppercase; }
        .data-table td { padding: 15px; border-bottom: 1px solid var(--border); vertical-align: middle; }
        .data-table tr:hover { background: #f8f9fa; }
        
        .customer-info { display: flex; align-items: center; gap: 12px; }
        
        .customer-avatar {
            width: 45px;
            height: 45px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--primary) 0%, var(--glow) 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 16px;
        }
        
        .customer-details h4 { font-size: 14px; font-weight: 600; color: var(--text); }
        .customer-details p { font-size: 12px; color: var(--text-light); }
        
        .badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 500;
        }
        
        .badge-nationality { background: #e8f5f5; color: var(--primary-dark); }
        .badge-bookings { background: var(--primary); color: white; }
        .badge-zero { background: #e0e0e0; color: #666; }
        
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
        }
        
        .action-btn.view { background: #e3f2fd; color: #1976d2; }
        .action-btn.edit { background: #fff3e0; color: #f57c00; }
        .action-btn.delete { background: #ffebee; color: #e53935; }
        .action-btn.book { background: #e0f2f1; color: #00796b; }
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
            max-width: 600px;
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
        
        /* View Modal */
        .view-header {
            display: flex;
            align-items: center;
            gap: 20px;
            padding-bottom: 20px;
            margin-bottom: 20px;
            border-bottom: 2px solid var(--border);
        }
        
        .view-avatar {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--primary) 0%, var(--glow) 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 700;
            font-size: 28px;
        }
        
        .view-title h2 { font-size: 24px; color: var(--primary-dark); margin-bottom: 5px; }
        .view-title p { font-size: 14px; color: var(--text-light); }
        
        .view-detail { display: flex; padding: 12px 0; border-bottom: 1px solid var(--border); }
        .view-detail:last-child { border-bottom: none; }
        .view-detail label { width: 140px; font-weight: 500; color: var(--text-light); font-size: 14px; }
        .view-detail span { flex: 1; color: var(--text); font-size: 14px; }
        
        .empty-state { text-align: center; padding: 60px 20px; }
        .empty-state i { font-size: 60px; color: var(--primary); opacity: 0.3; margin-bottom: 15px; }
        .empty-state h3 { color: var(--text); margin-bottom: 8px; }
        .empty-state p { color: var(--text-light); }
        
        @media (max-width: 768px) {
            .header { padding: 15px 20px; flex-direction: column; gap: 15px; }
            .table-header { flex-direction: column; align-items: flex-start; }
            .search-box { width: 100%; }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="header-left">
            <h1><i class="fas fa-users"></i> Customer Management</h1>
        </div>
        <div class="header-actions">
            <a href="<%= request.getContextPath() %>/staff/staff-dashboard.jsp" class="btn btn-back"><i class="fas fa-arrow-left"></i> Back to Dashboard</a>
        </div>
    </header>
    
    <!-- Main Content -->
    <main class="main-content">
        <!-- Stats Cards -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon total"><i class="fas fa-users"></i></div>
                <div class="stat-info">
                    <h3><%= totalCustomers %></h3>
                    <p>Total Customers</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon bookings"><i class="fas fa-calendar-check"></i></div>
                <div class="stat-info">
                    <h3><%= withBookings %></h3>
                    <p>With Bookings</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon new"><i class="fas fa-user-plus"></i></div>
                <div class="stat-info">
                    <h3><%= newThisMonth %></h3>
                    <p>New This Month</p>
                </div>
            </div>
        </div>
        
        <!-- Registration Form -->
        <div class="register-card">
            <div class="register-header">
                <h3><i class="fas fa-user-plus"></i> Register New Customer</h3>
            </div>
            <form method="POST" action="<%= contextPath %>/staff/staff-customers.jsp?action=addCustomer" id="registerForm">
                <div class="register-body">
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-user"></i> Full Name *</label>
                            <input type="text" name="fullName" class="form-control" required placeholder="Enter full name">
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-id-card"></i> NIC / Passport *</label>
                            <input type="text" name="nicPassport" class="form-control" required placeholder="Enter NIC or Passport">
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-phone"></i> Phone</label>
                            <input type="text" name="phone" class="form-control" placeholder="Phone number">
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-envelope"></i> Email</label>
                            <input type="email" name="email" class="form-control" placeholder="Email address">
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-globe"></i> Nationality</label>
                            <select name="nationality" class="form-control">
                                <option value="Sri Lankan">Sri Lankan</option>
                                <option value="British">British</option>
                                <option value="American">American</option>
                                <option value="Indian">Indian</option>
                                <option value="German">German</option>
                                <option value="Australian">Australian</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-map-marker-alt"></i> Address</label>
                            <input type="text" name="address" class="form-control" placeholder="Address">
                        </div>
                    </div>
                </div>
                <div class="register-footer">
                    <button type="submit" class="btn btn-primary"><i class="fas fa-user-plus"></i> Register Customer</button>
                </div>
            </form>
        </div>
        
        <!-- Customers Table -->
        <div class="table-card">
            <div class="table-header">
                <h3><i class="fas fa-list"></i> Registered Customers</h3>
                <div class="search-box">
                    <i class="fas fa-search"></i>
                    <input type="text" id="searchInput" placeholder="Search customers..." onkeyup="filterTable()">
                </div>
            </div>
            <div class="table-wrapper">
                <table class="data-table" id="customerTable">
                    <thead>
                        <tr>
                            <th>Customer</th>
                            <th>NIC/Passport</th>
                            <th>Phone</th>
                            <th>Nationality</th>
                            <th>Bookings</th>
                            <th>Registered</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                Statement custStmt = conn.createStatement();
                                ResultSet custRs = custStmt.executeQuery(
                                    "SELECT g.*, (SELECT COUNT(*) FROM reservations r WHERE r.guest_id = g.guest_id) as booking_count " +
                                    "FROM guests g ORDER BY g.created_at DESC"
                                );
                                boolean hasCustomers = false;
                                while (custRs.next()) {
                                    hasCustomers = true;
                                    int guestId = custRs.getInt("guest_id");
                                    String fullName = custRs.getString("full_name");
                                    if (fullName == null || fullName.trim().isEmpty()) fullName = "Guest";
                                    String nicPassport = custRs.getString("nic_passport");
                                    String email = custRs.getString("email");
                                    String phone = custRs.getString("phone");
                                    String nationality = custRs.getString("nationality");
                                    if (nationality == null || nationality.trim().isEmpty()) nationality = "N/A";
                                    String address = custRs.getString("address");
                                    int bookingCount = custRs.getInt("booking_count");
                                    java.sql.Date createdAt = custRs.getDate("created_at");
                                    
                                    String[] nameParts = fullName.split(" ");
                                    String initials = nameParts.length > 1 ? "" + nameParts[0].charAt(0) + nameParts[nameParts.length-1].charAt(0) : "" + fullName.charAt(0);
                        %>
                        <tr>
                            <td>
                                <div class="customer-info">
                                    <div class="customer-avatar"><%= initials.toUpperCase() %></div>
                                    <div class="customer-details">
                                        <h4><%= escHtml(fullName) %></h4>
                                        <p><%= email != null && !email.isEmpty() ? escHtml(email) : "-" %></p>
                                    </div>
                                </div>
                            </td>
                            <td><%= nicPassport != null ? escHtml(nicPassport) : "-" %></td>
                            <td><i class="fas fa-phone" style="color: var(--primary); margin-right: 5px;"></i><%= phone != null && !phone.isEmpty() ? escHtml(phone) : "-" %></td>
                            <td><span class="badge badge-nationality"><%= escHtml(nationality) %></span></td>
                            <td><span class="badge <%= bookingCount > 0 ? "badge-bookings" : "badge-zero" %>"><%= bookingCount %></span></td>
                            <td><%= createdAt != null ? sdf.format(createdAt) : "-" %></td>
                            <td>
                                <button class="action-btn view" title="View Details" 
                                    data-id="<%= guestId %>" 
                                    data-name="<%= escHtml(fullName) %>" 
                                    data-nic="<%= escHtml(nicPassport != null ? nicPassport : "") %>" 
                                    data-email="<%= escHtml(email != null ? email : "") %>" 
                                    data-phone="<%= escHtml(phone != null ? phone : "") %>" 
                                    data-nationality="<%= escHtml(nationality != null ? nationality : "") %>" 
                                    data-address="<%= escHtml(address != null ? address : "") %>" 
                                    data-date="<%= createdAt != null ? sdf.format(createdAt) : "" %>"
                                    onclick="viewCustomerData(this)"><i class="fas fa-eye"></i> View</button>
                                <button class="action-btn edit" title="Edit Customer" 
                                    data-id="<%= guestId %>" 
                                    data-name="<%= escHtml(fullName) %>" 
                                    data-nic="<%= escHtml(nicPassport != null ? nicPassport : "") %>" 
                                    data-email="<%= escHtml(email != null ? email : "") %>" 
                                    data-phone="<%= escHtml(phone != null ? phone : "") %>" 
                                    data-nationality="<%= escHtml(nationality != null ? nationality : "") %>" 
                                    data-address="<%= escHtml(address != null ? address : "") %>"
                                    onclick="editCustomerData(this)"><i class="fas fa-edit"></i> Edit</button>
                                <button class="action-btn delete" title="Delete Customer" data-id="<%= guestId %>" data-name="<%= escHtml(fullName) %>" onclick="deleteCustomerData(this)"><i class="fas fa-trash"></i> Delete</button>
                                <a href="<%= contextPath %>/staff/staff-book-room.jsp?guestId=<%= guestId %>&guestName=<%= java.net.URLEncoder.encode(fullName, "UTF-8") %><%= selectedRoomId > 0 ? "&roomId=" + selectedRoomId : "" %>" class="action-btn book" title="Book Room"><i class="fas fa-calendar-plus"></i> Book</a>
                            </td>
                        </tr>
                        <%
                                }
                                if (!hasCustomers) {
                        %>
                        <tr>
                            <td colspan="7">
                                <div class="empty-state">
                                    <i class="fas fa-users"></i>
                                    <h3>No customers registered yet</h3>
                                    <p>Register your first customer using the form above</p>
                                </div>
                            </td>
                        </tr>
                        <%
                                }
                                custRs.close();
                                custStmt.close();
                            } catch (Exception e) {
                                out.println("<tr><td colspan='7'>Error loading customers: " + e.getMessage() + "</td></tr>");
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
    
    <!-- View Customer Modal -->
    <div class="modal-overlay" id="viewModal">
        <div class="modal">
            <div class="modal-header">
                <h3><i class="fas fa-user"></i> Customer Details</h3>
                <button class="modal-close" onclick="closeModal('viewModal')">&times;</button>
            </div>
            <div class="modal-body">
                <div class="view-header">
                    <div class="view-avatar" id="viewInitials">JD</div>
                    <div class="view-title">
                        <h2 id="viewName">John Doe</h2>
                        <p><i class="fas fa-calendar-alt"></i> Registered: <span id="viewDate">2024-01-15</span></p>
                    </div>
                </div>
                <div class="view-detail">
                    <label><i class="fas fa-id-card"></i> NIC/Passport:</label>
                    <span id="viewNic">-</span>
                </div>
                <div class="view-detail">
                    <label><i class="fas fa-envelope"></i> Email:</label>
                    <span id="viewEmail">-</span>
                </div>
                <div class="view-detail">
                    <label><i class="fas fa-phone"></i> Phone:</label>
                    <span id="viewPhone">-</span>
                </div>
                <div class="view-detail">
                    <label><i class="fas fa-globe"></i> Nationality:</label>
                    <span id="viewNationality">-</span>
                </div>
                <div class="view-detail">
                    <label><i class="fas fa-map-marker-alt"></i> Address:</label>
                    <span id="viewAddress">-</span>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" onclick="closeModal('viewModal')">Close</button>
            </div>
        </div>
    </div>
    
    <!-- Edit Customer Modal -->
    <div class="modal-overlay" id="editModal">
        <div class="modal">
            <div class="modal-header">
                <h3><i class="fas fa-edit"></i> Edit Customer</h3>
                <button class="modal-close" onclick="closeModal('editModal')">&times;</button>
            </div>
            <form method="POST" action="<%= contextPath %>/staff/staff-customers.jsp?action=editCustomer">
                <div class="modal-body">
                    <input type="hidden" name="guestId" id="editGuestId">
                    <div class="form-group">
                        <label><i class="fas fa-user"></i> Full Name *</label>
                        <input type="text" name="fullName" id="editFullName" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-id-card"></i> NIC / Passport *</label>
                        <input type="text" name="nicPassport" id="editNicPassport" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-envelope"></i> Email</label>
                        <input type="email" name="email" id="editEmail" class="form-control">
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-phone"></i> Phone</label>
                        <input type="text" name="phone" id="editPhone" class="form-control">
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-globe"></i> Nationality</label>
                        <select name="nationality" id="editNationality" class="form-control">
                            <option value="Sri Lankan">Sri Lankan</option>
                            <option value="British">British</option>
                            <option value="American">American</option>
                            <option value="Indian">Indian</option>
                            <option value="German">German</option>
                            <option value="Australian">Australian</option>
                            <option value="Other">Other</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-map-marker-alt"></i> Address</label>
                        <input type="text" name="address" id="editAddress" class="form-control">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('editModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Save Changes</button>
                </div>
            </form>
        </div>
    </div>
    
    <script>
        // Show success/error messages
        <% if (successMessage != null) { %>
            Swal.fire({
                icon: 'success',
                title: 'Success!',
                text: '<%= escJs(successMessage) %>',
                confirmButtonColor: '#008080'
            });
        <% } %>
        
        <% if (errorMessage != null) { %>
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: '<%= escJs(errorMessage) %>',
                confirmButtonColor: '#008080'
            });
        <% } %>
        
        // Filter table
        function filterTable() {
            const searchValue = document.getElementById('searchInput').value.toLowerCase();
            const rows = document.querySelectorAll('#customerTable tbody tr');
            
            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(searchValue) ? '' : 'none';
            });
        }
        
        // Data attribute handlers
        function viewCustomerData(btn) {
            const id = btn.getAttribute('data-id');
            const name = btn.getAttribute('data-name');
            const nic = btn.getAttribute('data-nic');
            const email = btn.getAttribute('data-email');
            const phone = btn.getAttribute('data-phone');
            const nationality = btn.getAttribute('data-nationality');
            const address = btn.getAttribute('data-address');
            const date = btn.getAttribute('data-date');
            viewCustomer(id, name, nic, email, phone, nationality, address, date);
        }
        
        function editCustomerData(btn) {
            const id = btn.getAttribute('data-id');
            const name = btn.getAttribute('data-name');
            const nic = btn.getAttribute('data-nic');
            const email = btn.getAttribute('data-email');
            const phone = btn.getAttribute('data-phone');
            const nationality = btn.getAttribute('data-nationality');
            const address = btn.getAttribute('data-address');
            editCustomer(id, name, nic, email, phone, nationality, address);
        }
        
        function deleteCustomerData(btn) {
            const id = btn.getAttribute('data-id');
            const name = btn.getAttribute('data-name');
            deleteCustomer(id, name);
        }
        
        // View Customer
        function viewCustomer(id, name, nic, email, phone, nationality, address, date) {
            const nameParts = name.split(' ');
            const initials = nameParts.length > 1 ? nameParts[0].charAt(0) + nameParts[nameParts.length-1].charAt(0) : name.charAt(0);
            
            document.getElementById('viewInitials').textContent = initials.toUpperCase();
            document.getElementById('viewName').textContent = name;
            document.getElementById('viewNic').textContent = nic || '-';
            document.getElementById('viewEmail').textContent = email || '-';
            document.getElementById('viewPhone').textContent = phone || '-';
            document.getElementById('viewNationality').textContent = nationality || '-';
            document.getElementById('viewAddress').textContent = address || '-';
            document.getElementById('viewDate').textContent = date || '-';
            
            openModal('viewModal');
        }
        
        // Edit Customer
        function editCustomer(id, name, nic, email, phone, nationality, address) {
            document.getElementById('editGuestId').value = id;
            document.getElementById('editFullName').value = name;
            document.getElementById('editNicPassport').value = nic;
            document.getElementById('editEmail').value = email;
            document.getElementById('editPhone').value = phone;
            document.getElementById('editNationality').value = nationality;
            document.getElementById('editAddress').value = address;
            
            openModal('editModal');
        }
        
        // Delete Customer
        function deleteCustomer(id, name) {
            Swal.fire({
                title: 'Delete Customer?',
                text: 'Are you sure you want to delete "' + name + '"?',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#dc3545',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, delete',
                cancelButtonText: 'Cancel'
            }).then((result) => {
                if (result.isConfirmed) {
                    window.location.href = '<%= contextPath %>/staff/staff-customers.jsp?action=deleteCustomer&guestId=' + id;
                }
            });
        }
        
        // Open Modal
        function openModal(modalId) {
            document.getElementById(modalId).classList.add('active');
        }
        
        // Close Modal
        function closeModal(modalId) {
            document.getElementById(modalId).classList.remove('active');
        }
        
        // Close modal on outside click
        document.querySelectorAll('.modal-overlay').forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    modal.classList.remove('active');
                }
            });
        });
    </script>
    
<%
    // Close database connection
    if (conn != null) {
        try { conn.close(); } catch (SQLException e) { }
    }
%>
</body>
</html>
