<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%
    // Check if user is logged in and is staff
    String userRole = (String) session.getAttribute("userRole");
    String username = (String) session.getAttribute("username");
    String fullName = (String) session.getAttribute("fullName");
    Integer userId = (Integer) session.getAttribute("userId");
    String displayName = (fullName != null && !fullName.trim().isEmpty()) ? fullName : username;
    
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
    
    // Statistics
    int totalReservations = 0, confirmedCount = 0, checkedInCount = 0, checkedOutCount = 0, cancelledCount = 0;
    int myTotalReservations = 0, myConfirmedCount = 0, myCheckedInCount = 0;
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        // Resolve user ID if missing in session
        if (userId == null) {
            PreparedStatement psUser = conn.prepareStatement("SELECT user_id FROM users WHERE username = ?");
            psUser.setString(1, username);
            ResultSet rsUser = psUser.executeQuery();
            if (rsUser.next()) {
                userId = rsUser.getInt("user_id");
            }
            rsUser.close();
            psUser.close();
        }
        
        // Get overall statistics
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations");
        if (rs.next()) totalReservations = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE status = 'CONFIRMED'");
        if (rs.next()) confirmedCount = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE status = 'CHECKED_IN'");
        if (rs.next()) checkedInCount = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE status = 'CHECKED_OUT'");
        if (rs.next()) checkedOutCount = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE status = 'CANCELLED'");
        if (rs.next()) cancelledCount = rs.getInt(1);
        rs.close();
        
        // My reservations stats
        if (userId != null) {
            PreparedStatement psMyTotal = conn.prepareStatement("SELECT COUNT(*) FROM reservations WHERE created_by = ?");
            psMyTotal.setInt(1, userId);
            ResultSet rsMyTotal = psMyTotal.executeQuery();
            if (rsMyTotal.next()) myTotalReservations = rsMyTotal.getInt(1);
            rsMyTotal.close();
            psMyTotal.close();
            
            PreparedStatement psMyConfirmed = conn.prepareStatement("SELECT COUNT(*) FROM reservations WHERE created_by = ? AND status = 'CONFIRMED'");
            psMyConfirmed.setInt(1, userId);
            ResultSet rsMyConfirmed = psMyConfirmed.executeQuery();
            if (rsMyConfirmed.next()) myConfirmedCount = rsMyConfirmed.getInt(1);
            rsMyConfirmed.close();
            psMyConfirmed.close();
            
            PreparedStatement psMyCheckedIn = conn.prepareStatement("SELECT COUNT(*) FROM reservations WHERE created_by = ? AND status = 'CHECKED_IN'");
            psMyCheckedIn.setInt(1, userId);
            ResultSet rsMyCheckedIn = psMyCheckedIn.executeQuery();
            if (rsMyCheckedIn.next()) myCheckedInCount = rsMyCheckedIn.getInt(1);
            rsMyCheckedIn.close();
            psMyCheckedIn.close();
        }
        
        stmt.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
    
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    DecimalFormat df = new DecimalFormat("#,##0.00");
    
    // Current user ID for filtering
    int currentUserId = userId != null ? userId : 0;
%>
<%!
    // Helper method to escape HTML attribute values
    public String escHtml(String str) {
        if (str == null) return "";
        return str.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reservations - Ocean View Resort Staff</title>
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
        
        .btn-primary {
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
            color: white;
        }
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(0, 128, 128, 0.3); }
        
        .btn-secondary { background: #e0e0e0; color: var(--text); }
        .btn-secondary:hover { background: #d0d0d0; }
        
        .btn-success {
            background: linear-gradient(135deg, var(--primary) 0%, var(--glow) 100%);
            color: white;
            border: 1px solid rgba(255,255,255,0.25);
        }
        .btn-success:hover {
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
            box-shadow: 0 5px 20px rgba(0, 128, 128, 0.3);
            transform: translateY(-2px);
        }
        
        /* Main Content */
        .main-content {
            max-width: 1600px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        /* Tab Navigation */
        .tab-nav {
            display: flex;
            gap: 10px;
            margin-bottom: 25px;
            background: var(--card-bg);
            padding: 10px;
            border-radius: 15px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
        }
        
        .tab-btn {
            padding: 15px 30px;
            border: none;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            font-family: 'Poppins', sans-serif;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 10px;
            background: transparent;
            color: var(--text-light);
        }
        
        .tab-btn:hover { background: var(--bg); color: var(--primary); }
        
        .tab-btn.active {
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
            color: white;
        }
        
        .tab-btn .badge {
            background: rgba(255,255,255,0.2);
            padding: 4px 10px;
            border-radius: 15px;
            font-size: 12px;
        }
        
        .tab-btn.active .badge { background: rgba(255,255,255,0.3); }
        .tab-btn:not(.active) .badge { background: var(--bg); color: var(--primary); }
        
        /* Stats Cards */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        
        @media (max-width: 1200px) { .stats-grid { grid-template-columns: repeat(3, 1fr); } }
        @media (max-width: 768px) { .stats-grid { grid-template-columns: repeat(2, 1fr); } }
        @media (max-width: 500px) { .stats-grid { grid-template-columns: 1fr; } }
        
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
        .stat-icon.confirmed { background: linear-gradient(135deg, #10b981 0%, #34d399 100%); color: white; }
        .stat-icon.checked-in { background: linear-gradient(135deg, #3b82f6 0%, #60a5fa 100%); color: white; }
        .stat-icon.checked-out { background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%); color: white; }
        .stat-icon.cancelled { background: linear-gradient(135deg, #ef4444 0%, #f87171 100%); color: white; }
        .stat-icon.my-total { background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%); color: white; }
        
        .stat-info h3 { font-size: 26px; font-weight: 700; color: var(--text); }
        .stat-info p { font-size: 13px; color: var(--text-light); }
        
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
        
        .btn-clear {
            background: #e74c3c;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-family: 'Poppins', sans-serif;
            font-weight: 500;
            transition: all 0.3s ease;
        }
        
        .btn-clear:hover { background: #c0392b; }
        
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
        
        .reservation-number { font-weight: 700; color: var(--primary-dark); font-size: 14px; }
        
        .guest-info { display: flex; align-items: center; gap: 12px; }
        
        .guest-avatar {
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
        
        .guest-details h4 { font-size: 14px; font-weight: 600; color: var(--text); }
        .guest-details p { font-size: 12px; color: var(--text-light); }
        
        .room-info {
            background: #e8f5f5;
            padding: 8px 12px;
            border-radius: 8px;
            display: inline-block;
        }
        
        .room-info .room-number { font-weight: 700; color: var(--primary-dark); }
        .room-info .room-type { font-size: 12px; color: var(--text-light); display: block; }
        
        .dates-info .date { font-weight: 600; color: var(--text); }
        .dates-info .nights { font-size: 12px; color: var(--text-light); }
        
        .status-badge {
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            display: inline-block;
        }
        
        .status-badge.confirmed { background: #d1fae5; color: #059669; }
        .status-badge.checked_in, .status-badge.checked-in { background: #dbeafe; color: #2563eb; }
        .status-badge.checked_out, .status-badge.checked-out { background: #fef3c7; color: #d97706; }
        .status-badge.cancelled { background: #fee2e2; color: #dc2626; }
        .status-badge.pending { background: #e0e7ff; color: #4f46e5; }
        
        .staff-info { display: flex; align-items: center; gap: 10px; }
        
        .staff-avatar {
            width: 35px;
            height: 35px;
            border-radius: 50%;
            background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 12px;
        }
        
        .staff-avatar.mine { background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%); }
        
        .staff-details .name { font-size: 13px; font-weight: 600; color: var(--text); }
        .staff-details .role { font-size: 11px; color: var(--text-light); text-transform: capitalize; }
        
        .my-badge {
            background: var(--primary);
            color: white;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 10px;
            font-weight: 600;
            margin-left: 5px;
        }
        
        .amount-info { text-align: right; }
        .amount-info .total { font-size: 16px; font-weight: 700; color: var(--primary-dark); }
        .amount-info .breakdown { font-size: 11px; color: var(--text-light); }
        
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
            max-width: 800px;
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
        
        /* View Modal Details */
        .detail-section {
            margin-bottom: 25px;
            padding-bottom: 25px;
            border-bottom: 2px solid var(--border);
        }
        
        .detail-section:last-child { border-bottom: none; margin-bottom: 0; padding-bottom: 0; }
        
        .detail-section h4 {
            font-size: 14px;
            font-weight: 600;
            color: var(--primary);
            text-transform: uppercase;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .detail-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 15px;
        }
        
        @media (max-width: 600px) { .detail-grid { grid-template-columns: 1fr; } }
        
        .detail-item label {
            display: block;
            font-size: 12px;
            font-weight: 500;
            color: var(--text-light);
            margin-bottom: 5px;
        }
        
        .detail-item span {
            display: block;
            font-size: 14px;
            font-weight: 600;
            color: var(--text);
        }
        
        .empty-state { text-align: center; padding: 60px 20px; }
        .empty-state i { font-size: 60px; color: var(--primary); opacity: 0.3; margin-bottom: 15px; }
        .empty-state h3 { color: var(--text); margin-bottom: 8px; }
        .empty-state p { color: var(--text-light); }
        
        @media (max-width: 768px) {
            .header { padding: 15px 20px; flex-direction: column; gap: 15px; }
            .filter-row { flex-direction: column; align-items: stretch; }
            .search-box { min-width: 100%; }
            .tab-nav { flex-direction: column; }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="header-left">
            <h1><i class="fas fa-calendar-check"></i> Reservations</h1>
            <p><i class="fas fa-user"></i> Staff: <%= displayName %></p>
        </div>
        <div class="header-actions">
            <a href="<%= request.getContextPath() %>/staff/staff-customers.jsp" class="btn btn-success" title="Select a guest first, then book room">
                <i class="fas fa-plus"></i> New Booking
            </a>
            <a href="<%= request.getContextPath() %>/staff/staff-dashboard.jsp" class="btn btn-back"><i class="fas fa-arrow-left"></i> Back to Dashboard</a>
        </div>
    </header>
    
    <!-- Main Content -->
    <main class="main-content">
        <!-- Tab Navigation -->
        <div class="tab-nav">
            <button class="tab-btn active" onclick="switchTab('all')" id="tabAll">
                <i class="fas fa-list"></i> All Reservations
                <span class="badge"><%= totalReservations %></span>
            </button>
            <button class="tab-btn" onclick="switchTab('mine')" id="tabMine">
                <i class="fas fa-user-check"></i> My Reservations
                <span class="badge"><%= myTotalReservations %></span>
            </button>
        </div>
        
        <!-- Stats Cards -->
        <div class="stats-grid" id="statsAll">
            <div class="stat-card">
                <div class="stat-icon total"><i class="fas fa-calendar-alt"></i></div>
                <div class="stat-info">
                    <h3><%= totalReservations %></h3>
                    <p>Total Reservations</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon confirmed"><i class="fas fa-check-circle"></i></div>
                <div class="stat-info">
                    <h3><%= confirmedCount %></h3>
                    <p>Confirmed</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon checked-in"><i class="fas fa-sign-in-alt"></i></div>
                <div class="stat-info">
                    <h3><%= checkedInCount %></h3>
                    <p>Checked In</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon checked-out"><i class="fas fa-sign-out-alt"></i></div>
                <div class="stat-info">
                    <h3><%= checkedOutCount %></h3>
                    <p>Checked Out</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon cancelled"><i class="fas fa-times-circle"></i></div>
                <div class="stat-info">
                    <h3><%= cancelledCount %></h3>
                    <p>Cancelled</p>
                </div>
            </div>
        </div>
        
        <div class="stats-grid" id="statsMine" style="display: none;">
            <div class="stat-card">
                <div class="stat-icon my-total"><i class="fas fa-calendar-check"></i></div>
                <div class="stat-info">
                    <h3><%= myTotalReservations %></h3>
                    <p>My Total Reservations</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon confirmed"><i class="fas fa-check-circle"></i></div>
                <div class="stat-info">
                    <h3><%= myConfirmedCount %></h3>
                    <p>My Confirmed</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon checked-in"><i class="fas fa-sign-in-alt"></i></div>
                <div class="stat-info">
                    <h3><%= myCheckedInCount %></h3>
                    <p>My Checked In</p>
                </div>
            </div>
        </div>
        
        <!-- Filter Section -->
        <div class="filter-card">
            <div class="filter-row">
                <div class="search-box">
                    <i class="fas fa-search"></i>
                    <input type="text" id="searchInput" placeholder="Search by reservation #, guest name, room..." onkeyup="filterReservations()">
                </div>
                <div class="filter-group">
                    <label>Check-in Date</label>
                    <input type="date" class="filter-control" id="dateFilter" onchange="filterReservations()">
                </div>
                <div class="filter-group">
                    <label>Status</label>
                    <select class="filter-control" id="statusFilter" onchange="filterReservations()">
                        <option value="">All Status</option>
                        <option value="CONFIRMED">Confirmed</option>
                        <option value="CHECKED_IN">Checked In</option>
                        <option value="CHECKED_OUT">Checked Out</option>
                        <option value="CANCELLED">Cancelled</option>
                    </select>
                </div>
                <div class="filter-group" style="align-self: flex-end;">
                    <button type="button" class="btn-clear" onclick="clearFilters()">
                        <i class="fas fa-times"></i> Clear Filters
                    </button>
                </div>
            </div>
        </div>
        
        <!-- Reservations Table -->
        <div class="table-card">
            <div class="table-header">
                <h3><i class="fas fa-list"></i> <span id="tableTitle">All Reservations</span></h3>
            </div>
            <div class="table-wrapper">
                <table class="data-table" id="reservationsTable">
                    <thead>
                        <tr>
                            <th>Reservation #</th>
                            <th>Guest Details</th>
                            <th>Room</th>
                            <th>Check-in</th>
                            <th>Check-out</th>
                            <th>Status</th>
                            <th>Created By</th>
                            <th>Amount</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            if (conn == null) {
                                out.println("<tr><td colspan='9' style='text-align:center; color:red;'>Database connection failed.</td></tr>");
                            } else {
                            int rowCount = 0;
                            try {
                                String sql = "SELECT r.*, " +
                                    "g.full_name as guest_name, g.nic_passport, g.phone as guest_phone, g.email as guest_email, g.nationality, " +
                                    "rm.room_number, rt.type_name as room_type, rt.rate_per_night, " +
                                    "u.full_name as staff_name, u.role as staff_role, u.username as staff_username, " +
                                    "b.total_amount, b.payment_status " +
                                    "FROM reservations r " +
                                    "JOIN guests g ON r.guest_id = g.guest_id " +
                                    "JOIN rooms rm ON r.room_id = rm.room_id " +
                                    "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
                                    "LEFT JOIN users u ON r.created_by = u.user_id " +
                                    "LEFT JOIN bills b ON r.reservation_id = b.reservation_id " +
                                    "ORDER BY r.created_at DESC";
                                Statement resStmt = conn.createStatement();
                                ResultSet resRs = resStmt.executeQuery(sql);
                                
                                SimpleDateFormat dateFormat = new SimpleDateFormat("MMM dd, yyyy");
                                SimpleDateFormat dateTimeFormat = new SimpleDateFormat("MMM dd, yyyy HH:mm");
                                SimpleDateFormat rawDateFormat = new SimpleDateFormat("yyyy-MM-dd");
                                
                                while (resRs.next()) {
                                    rowCount++;
                                    int resId = resRs.getInt("reservation_id");
                                    String resNumber = resRs.getString("reservation_number");
                                    String guestName = resRs.getString("guest_name");
                                    if (guestName == null || guestName.trim().isEmpty()) guestName = "Guest";
                                    String guestNic = resRs.getString("nic_passport");
                                    if (guestNic == null) guestNic = "";
                                    String guestPhone = resRs.getString("guest_phone");
                                    String guestEmail = resRs.getString("guest_email");
                                    String nationality = resRs.getString("nationality");
                                    String roomNumber = resRs.getString("room_number");
                                    if (roomNumber == null) roomNumber = "";
                                    String roomType = resRs.getString("room_type");
                                    if (roomType == null) roomType = "";
                                    java.sql.Date checkIn = resRs.getDate("check_in_date");
                                    java.sql.Date checkOut = resRs.getDate("check_out_date");
                                    String status = resRs.getString("status");
                                    if (status == null || status.trim().isEmpty()) status = "UNKNOWN";
                                    String statusClass = status.toLowerCase().replace("_", "-");
                                    String staffName = resRs.getString("staff_name");
                                    String staffRole = resRs.getString("staff_role");
                                    Timestamp createdAt = resRs.getTimestamp("created_at");
                                    double totalAmount = resRs.getDouble("total_amount");
                                    String paymentStatus = resRs.getString("payment_status");
                                    int staffId = resRs.getInt("created_by");
                                    if (resRs.wasNull()) staffId = -1;
                                    
                                    // Check if this is user's reservation
                                    boolean isMyReservation = (currentUserId > 0 && staffId == currentUserId);
                                    
                                    // Calculate nights
                                    int nights = 0;
                                    if (checkIn != null && checkOut != null) {
                                        long diff = checkOut.getTime() - checkIn.getTime();
                                        nights = (int) (diff / (1000 * 60 * 60 * 24));
                                        if (nights < 1) nights = 1;
                                    }
                                    
                                    // Get initials
                                    String guestInitials = "G";
                                    String[] guestParts = guestName.split(" ");
                                    if (guestParts.length >= 2) {
                                        guestInitials = ("" + guestParts[0].charAt(0) + guestParts[guestParts.length - 1].charAt(0)).toUpperCase();
                                    } else if (guestParts.length == 1) {
                                        guestInitials = guestParts[0].substring(0, Math.min(2, guestParts[0].length())).toUpperCase();
                                    }
                                    
                                    String staffInitials = "";
                                    if (staffName != null) {
                                        String[] staffParts = staffName.split(" ");
                                        if (staffParts.length >= 2) {
                                            staffInitials = ("" + staffParts[0].charAt(0) + staffParts[staffParts.length - 1].charAt(0)).toUpperCase();
                                        } else if (staffParts.length == 1) {
                                            staffInitials = staffParts[0].substring(0, Math.min(2, staffParts[0].length())).toUpperCase();
                                        }
                                    }
                        %>
                        <tr data-id="<%= resId %>" data-status="<%= status %>" data-staff="<%= staffId %>" data-is-mine="<%= isMyReservation %>"
                            data-search="<%= escHtml(resNumber.toLowerCase() + " " + guestName.toLowerCase() + " " + roomNumber.toLowerCase() + " " + roomType.toLowerCase()) %>"
                            data-check-in-raw="<%= checkIn != null ? rawDateFormat.format(checkIn) : "" %>"
                            data-res-number="<%= escHtml(resNumber) %>"
                            data-guest-name="<%= escHtml(guestName) %>"
                            data-guest-nic="<%= escHtml(guestNic) %>"
                            data-guest-phone="<%= escHtml(guestPhone != null ? guestPhone : "") %>"
                            data-guest-email="<%= escHtml(guestEmail != null ? guestEmail : "") %>"
                            data-nationality="<%= escHtml(nationality != null ? nationality : "") %>"
                            data-room-number="<%= escHtml(roomNumber) %>"
                            data-room-type="<%= escHtml(roomType) %>"
                            data-check-in="<%= checkIn != null ? dateFormat.format(checkIn) : "N/A" %>"
                            data-check-out="<%= checkOut != null ? dateFormat.format(checkOut) : "N/A" %>"
                            data-nights="<%= nights %>"
                            data-staff-name="<%= escHtml(staffName != null ? staffName : "") %>"
                            data-staff-role="<%= escHtml(staffRole != null ? staffRole : "") %>"
                            data-created-at="<%= createdAt != null ? dateTimeFormat.format(createdAt) : "" %>"
                            data-amount="<%= totalAmount %>"
                            data-payment-status="<%= escHtml(paymentStatus != null ? paymentStatus : "") %>">
                            <td>
                                <span class="reservation-number"><%= escHtml(resNumber) %></span>
                            </td>
                            <td>
                                <div class="guest-info">
                                    <div class="guest-avatar"><%= escHtml(guestInitials) %></div>
                                    <div class="guest-details">
                                        <h4><%= escHtml(guestName) %></h4>
                                        <p><%= escHtml(guestNic) %></p>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div class="room-info">
                                    <span class="room-number">Room <%= escHtml(roomNumber) %></span>
                                    <span class="room-type"><%= escHtml(roomType) %></span>
                                </div>
                            </td>
                            <td>
                                <div class="dates-info">
                                    <span class="date"><%= checkIn != null ? dateFormat.format(checkIn) : "N/A" %></span>
                                </div>
                            </td>
                            <td>
                                <div class="dates-info">
                                    <span class="date"><%= checkOut != null ? dateFormat.format(checkOut) : "N/A" %></span>
                                    <span class="nights"><%= nights %> night<%= nights > 1 ? "s" : "" %></span>
                                </div>
                            </td>
                            <td>
                                <span class="status-badge <%= statusClass %>"><%= escHtml(status.replace("_", " ")) %></span>
                            </td>
                            <td>
                                <% if (staffName != null) { %>
                                <div class="staff-info">
                                    <div class="staff-avatar <%= isMyReservation ? "mine" : "" %>"><%= escHtml(staffInitials) %></div>
                                    <div class="staff-details">
                                        <span class="name"><%= escHtml(staffName) %><% if (isMyReservation) { %><span class="my-badge">ME</span><% } %></span>
                                        <span class="role"><%= staffRole != null ? escHtml(staffRole.toLowerCase()) : "" %></span>
                                    </div>
                                </div>
                                <% } else { %>
                                <span style="color: var(--text-light);">-</span>
                                <% } %>
                            </td>
                            <td>
                                <div class="amount-info">
                                    <span class="total">Rs. <%= df.format(totalAmount) %></span>
                                    <span class="breakdown"><%= paymentStatus != null ? paymentStatus : "N/A" %></span>
                                </div>
                            </td>
                            <td>
                                <button class="action-btn view" onclick="viewReservationFromRow(this)">
                                    <i class="fas fa-eye"></i> View
                                </button>
                            </td>
                        </tr>
                        <% } 
                        if (rowCount == 0) {
                            out.println("<tr><td colspan='9' style='text-align:center; padding:40px; color:var(--text-light);'><i class='fas fa-calendar-times' style='font-size:40px; opacity:0.3; display:block; margin-bottom:15px;'></i>No reservations found</td></tr>");
                        }
                        resRs.close(); resStmt.close(); } catch (Exception e) { out.println("<tr><td colspan='9' style='color:red;'>Error: " + e.getMessage() + "</td></tr>"); e.printStackTrace(); } } %>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
    
    <!-- View Reservation Modal -->
    <div class="modal-overlay" id="viewModal">
        <div class="modal">
            <div class="modal-header">
                <h3><i class="fas fa-calendar-check"></i> Reservation Details</h3>
                <button class="modal-close" onclick="closeModal('viewModal')">&times;</button>
            </div>
            <div class="modal-body" id="viewModalBody">
                <!-- Content populated by JavaScript -->
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" onclick="closeModal('viewModal')">Close</button>
            </div>
        </div>
    </div>
    
    <script>
        // Current user ID
        const currentUserId = <%= currentUserId %>;
        let currentTab = 'all';
        
        // Tab switching
        function switchTab(tab) {
            currentTab = tab;
            
            // Update tab buttons
            document.getElementById('tabAll').classList.toggle('active', tab === 'all');
            document.getElementById('tabMine').classList.toggle('active', tab === 'mine');
            
            // Update stats
            document.getElementById('statsAll').style.display = tab === 'all' ? 'grid' : 'none';
            document.getElementById('statsMine').style.display = tab === 'mine' ? 'grid' : 'none';
            
            // Update table title
            document.getElementById('tableTitle').textContent = tab === 'all' ? 'All Reservations' : 'My Reservations';
            
            // Filter rows
            filterReservations();
        }
        
        // Filter reservations
        function filterReservations() {
            const searchText = document.getElementById('searchInput').value.toLowerCase();
            const statusFilter = document.getElementById('statusFilter').value;
            const dateFilter = document.getElementById('dateFilter').value;
            
            const rows = document.querySelectorAll('#reservationsTable tbody tr');
            
            rows.forEach(row => {
                const searchData = row.getAttribute('data-search');
                const rowStatus = row.getAttribute('data-status');
                const rowDate = row.getAttribute('data-check-in-raw');
                const isMine = row.getAttribute('data-is-mine') === 'true';
                
                let showRow = true;
                
                // Tab filter
                if (currentTab === 'mine' && !isMine) {
                    showRow = false;
                }
                
                // Search filter
                if (showRow && searchText && searchData && !searchData.includes(searchText)) {
                    showRow = false;
                }
                
                // Status filter
                if (showRow && statusFilter && rowStatus !== statusFilter) {
                    showRow = false;
                }
                
                // Date filter
                if (showRow && dateFilter && rowDate !== dateFilter) {
                    showRow = false;
                }
                
                row.style.display = showRow ? '' : 'none';
            });
        }
        
        // Clear all filters
        function clearFilters() {
            document.getElementById('searchInput').value = '';
            document.getElementById('statusFilter').value = '';
            document.getElementById('dateFilter').value = '';
            filterReservations();
        }
        
        // Helper function to decode HTML entities
        function decodeHtml(html) {
            if (!html) return '';
            const txt = document.createElement('textarea');
            txt.innerHTML = html;
            return txt.value;
        }
        
        // View reservation details
        function viewReservationFromRow(btn) {
            try {
                const row = btn.closest('tr');
                if (!row) return;
                
                const resNumber = decodeHtml(row.getAttribute('data-res-number')) || '-';
                const guestName = decodeHtml(row.getAttribute('data-guest-name')) || '-';
                const guestNic = decodeHtml(row.getAttribute('data-guest-nic')) || '-';
                const guestPhone = decodeHtml(row.getAttribute('data-guest-phone')) || '-';
                const guestEmail = decodeHtml(row.getAttribute('data-guest-email')) || '-';
                const nationality = decodeHtml(row.getAttribute('data-nationality')) || '-';
                const roomNumber = decodeHtml(row.getAttribute('data-room-number')) || '-';
                const roomType = decodeHtml(row.getAttribute('data-room-type')) || '-';
                const checkIn = decodeHtml(row.getAttribute('data-check-in')) || '-';
                const checkOut = decodeHtml(row.getAttribute('data-check-out')) || '-';
                const nights = parseInt(row.getAttribute('data-nights')) || 0;
                const status = row.getAttribute('data-status') || 'UNKNOWN';
                const staffName = decodeHtml(row.getAttribute('data-staff-name')) || '-';
                const staffRole = decodeHtml(row.getAttribute('data-staff-role')) || '-';
                const createdAt = decodeHtml(row.getAttribute('data-created-at')) || '-';
                const amount = parseFloat(row.getAttribute('data-amount')) || 0;
                const paymentStatus = decodeHtml(row.getAttribute('data-payment-status')) || 'N/A';
                
                const statusClass = status.toLowerCase().replace(/_/g, '-');
                const statusDisplay = status.replace(/_/g, ' ');
                const nightsText = nights + ' night' + (nights > 1 ? 's' : '');
                const amountText = 'Rs. ' + amount.toLocaleString('en-US', {minimumFractionDigits: 2});
                
                var html = '<div class="detail-section">' +
                    '<h4><i class="fas fa-bookmark"></i> Reservation Info</h4>' +
                    '<div class="detail-grid">' +
                    '<div class="detail-item"><label>Reservation Number</label><span>' + resNumber + '</span></div>' +
                    '<div class="detail-item"><label>Status</label><span class="status-badge ' + statusClass + '">' + statusDisplay + '</span></div>' +
                    '<div class="detail-item"><label>Check-in Date</label><span>' + checkIn + '</span></div>' +
                    '<div class="detail-item"><label>Check-out Date</label><span>' + checkOut + '</span></div>' +
                    '<div class="detail-item"><label>Number of Nights</label><span>' + nightsText + '</span></div>' +
                    '<div class="detail-item"><label>Total Amount</label><span style="font-weight: 700; color: var(--primary-dark);">' + amountText + '</span></div>' +
                    '</div></div>' +
                    
                    '<div class="detail-section">' +
                    '<h4><i class="fas fa-user"></i> Guest Information</h4>' +
                    '<div class="detail-grid">' +
                    '<div class="detail-item"><label>Full Name</label><span>' + guestName + '</span></div>' +
                    '<div class="detail-item"><label>NIC / Passport</label><span>' + guestNic + '</span></div>' +
                    '<div class="detail-item"><label>Phone</label><span>' + (guestPhone || '-') + '</span></div>' +
                    '<div class="detail-item"><label>Email</label><span>' + (guestEmail || '-') + '</span></div>' +
                    '<div class="detail-item"><label>Nationality</label><span>' + (nationality || '-') + '</span></div>' +
                    '</div></div>' +
                    
                    '<div class="detail-section">' +
                    '<h4><i class="fas fa-bed"></i> Room Information</h4>' +
                    '<div class="detail-grid">' +
                    '<div class="detail-item"><label>Room Number</label><span>Room ' + roomNumber + '</span></div>' +
                    '<div class="detail-item"><label>Room Type</label><span>' + roomType + '</span></div>' +
                    '</div></div>' +
                    
                    '<div class="detail-section">' +
                    '<h4><i class="fas fa-user-tie"></i> Created By</h4>' +
                    '<div class="detail-grid">' +
                    '<div class="detail-item"><label>Staff Name</label><span>' + (staffName || '-') + '</span></div>' +
                    '<div class="detail-item"><label>Role</label><span style="text-transform: capitalize;">' + (staffRole ? staffRole.toLowerCase() : '-') + '</span></div>' +
                    '<div class="detail-item"><label>Created At</label><span>' + (createdAt || '-') + '</span></div>' +
                    '<div class="detail-item"><label>Payment Status</label><span>' + (paymentStatus || 'N/A') + '</span></div>' +
                    '</div></div>';
                
                document.getElementById('viewModalBody').innerHTML = html;
                document.getElementById('viewModal').classList.add('active');
            } catch (error) {
                console.error('Error:', error);
                alert('Error: ' + error.message);
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
