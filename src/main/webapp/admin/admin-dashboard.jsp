<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.util.*" %>
<%
    // Check if user is logged in and is admin
    String userRole = (String) session.getAttribute("userRole");
    String username = (String) session.getAttribute("username");
    String fullName = (String) session.getAttribute("fullName");
    Integer userId = (Integer) session.getAttribute("userId");
    
    if (username == null || userRole == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?role=admin");
        return;
    }
    if (!"ADMIN".equalsIgnoreCase(userRole)) {
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
    
    // Get invoice date from request parameter (default to today)
    String invoiceDateParam = request.getParameter("invoiceDate");
    String selectedInvoiceDate = (invoiceDateParam != null && !invoiceDateParam.isEmpty()) 
        ? invoiceDateParam 
        : null; // null means show all invoices
    boolean hasDateFilter = (selectedInvoiceDate != null);
    String displayDate = hasDateFilter ? selectedInvoiceDate : new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
    
    // Database connection
    Connection conn = null;
    String dbUrl = "jdbc:mysql://localhost:3306/ocean_view_resort";
    String dbUser = "root";
    String dbPass = "";
    
    // Dashboard statistics
    int totalRooms = 0, availableRooms = 0, occupiedRooms = 0;
    int totalReservations = 0, todayCheckIns = 0, todayCheckOuts = 0;
    int totalStaff = 0, totalGuests = 0;
    double todayRevenue = 0, monthlyRevenue = 0;
    String profilePic = null;
    String email = "", phone = "", address = "", hireDate = "";
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        // Get user details including profile picture
        PreparedStatement psProfile = conn.prepareStatement("SELECT * FROM users WHERE user_id = ?");
        psProfile.setInt(1, userId);
        ResultSet rsProfile = psProfile.executeQuery();
        if (rsProfile.next()) {
            profilePic = rsProfile.getString("profile_picture");
            email = rsProfile.getString("email") != null ? rsProfile.getString("email") : "";
            phone = rsProfile.getString("phone") != null ? rsProfile.getString("phone") : "";
            address = rsProfile.getString("address") != null ? rsProfile.getString("address") : "";
            java.sql.Date hd = rsProfile.getDate("hire_date");
            if (hd != null) hireDate = hd.toString();
        }
        rsProfile.close();
        psProfile.close();
        
        // Total rooms
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM rooms");
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
        
        // Total reservations
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations");
        if (rs.next()) totalReservations = rs.getInt(1);
        rs.close();
        
        // Today's check-ins
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE check_in_date = CURDATE() AND status IN ('CONFIRMED', 'CHECKED_IN')");
        if (rs.next()) todayCheckIns = rs.getInt(1);
        rs.close();
        
        // Today's check-outs
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE check_out_date = CURDATE()");
        if (rs.next()) todayCheckOuts = rs.getInt(1);
        rs.close();
        
        // Total staff
        rs = stmt.executeQuery("SELECT COUNT(*) FROM users WHERE role = 'STAFF'");
        if (rs.next()) totalStaff = rs.getInt(1);
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
        
        stmt.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
    
    // Get weekly revenue data for chart
    double[] weeklyRevenue = {0, 0, 0, 0, 0, 0, 0};
    String[] weekDays = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
    try {
        Statement weekStmt = conn.createStatement();
        ResultSet weekRs = weekStmt.executeQuery(
            "SELECT DAYOFWEEK(paid_at) as day_num, SUM(total_amount) as total " +
            "FROM bills WHERE paid_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND payment_status = 'PAID' " +
            "GROUP BY DAYOFWEEK(paid_at)"
        );
        while (weekRs.next()) {
            int dayNum = weekRs.getInt("day_num") - 1;
            if (dayNum >= 0 && dayNum < 7) {
                weeklyRevenue[dayNum] = weekRs.getDouble("total");
            }
        }
        weekRs.close();
        weekStmt.close();
    } catch (Exception e) {}
    
    // Get room type booking counts for chart
    java.util.Map<String, Integer> roomTypeBookings = new java.util.LinkedHashMap<>();
    try {
        Statement rtbStmt = conn.createStatement();
        ResultSet rtbRs = rtbStmt.executeQuery(
            "SELECT rt.type_name, COUNT(res.reservation_id) as cnt " +
            "FROM room_types rt LEFT JOIN rooms r ON r.room_type_id = rt.room_type_id " +
            "LEFT JOIN reservations res ON res.room_id = r.room_id " +
            "GROUP BY rt.type_name ORDER BY cnt DESC"
        );
        while (rtbRs.next()) {
            roomTypeBookings.put(rtbRs.getString("type_name"), rtbRs.getInt("cnt"));
        }
        rtbRs.close();
        rtbStmt.close();
    } catch (Exception e) {}
    
    // Room status counts
    int maintenanceRooms = 0, reservedRooms = 0;
    try {
        Statement roomStatStmt = conn.createStatement();
        ResultSet roomStatRs = roomStatStmt.executeQuery("SELECT status, COUNT(*) as cnt FROM rooms GROUP BY status");
        while (roomStatRs.next()) {
            String st = roomStatRs.getString("status");
            if ("MAINTENANCE".equalsIgnoreCase(st)) maintenanceRooms = roomStatRs.getInt("cnt");
            else if ("RESERVED".equalsIgnoreCase(st)) reservedRooms = roomStatRs.getInt("cnt");
        }
        roomStatRs.close();
        roomStatStmt.close();
    } catch (Exception e) {}
    
    // ========== DETAILED REPORT DATA ==========
    
    // Daily Revenue (last 7 days)
    double[] dailyRevenueData = new double[7];
    String[] dailyLabels = new String[7];
    try {
        SimpleDateFormat dayFmt = new SimpleDateFormat("MMM dd");
        for (int i = 6; i >= 0; i--) {
            java.util.Calendar cal = java.util.Calendar.getInstance();
            cal.add(java.util.Calendar.DAY_OF_MONTH, -i);
            dailyLabels[6-i] = dayFmt.format(cal.getTime());
        }
        Statement dailyStmt = conn.createStatement();
        ResultSet dailyRs = dailyStmt.executeQuery(
            "SELECT DATE(paid_at) as pay_date, SUM(total_amount) as total " +
            "FROM bills WHERE paid_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) AND payment_status = 'PAID' " +
            "GROUP BY DATE(paid_at) ORDER BY pay_date"
        );
        while (dailyRs.next()) {
            java.sql.Date payDate = dailyRs.getDate("pay_date");
            String dateStr = dayFmt.format(payDate);
            for (int i = 0; i < 7; i++) {
                if (dailyLabels[i].equals(dateStr)) {
                    dailyRevenueData[i] = dailyRs.getDouble("total");
                    break;
                }
            }
        }
        dailyRs.close();
        dailyStmt.close();
    } catch (Exception e) {}
    
    // Weekly Revenue (last 4 weeks)
    double weeklyRevenue4 = 0;
    try {
        Statement w4Stmt = conn.createStatement();
        ResultSet w4Rs = w4Stmt.executeQuery(
            "SELECT IFNULL(SUM(total_amount), 0) FROM bills WHERE paid_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND payment_status = 'PAID'"
        );
        if (w4Rs.next()) weeklyRevenue4 = w4Rs.getDouble(1);
        w4Rs.close();
        w4Stmt.close();
    } catch (Exception e) {}
    
    // Daily Bookings (last 7 days)
    int[] dailyBookingsData = new int[7];
    try {
        SimpleDateFormat dayFmt = new SimpleDateFormat("MMM dd");
        Statement dbStmt = conn.createStatement();
        ResultSet dbRs = dbStmt.executeQuery(
            "SELECT DATE(created_at) as book_date, COUNT(*) as cnt " +
            "FROM reservations WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) " +
            "GROUP BY DATE(created_at) ORDER BY book_date"
        );
        while (dbRs.next()) {
            java.sql.Date bookDate = dbRs.getDate("book_date");
            String dateStr = dayFmt.format(bookDate);
            for (int i = 0; i < 7; i++) {
                if (dailyLabels[i].equals(dateStr)) {
                    dailyBookingsData[i] = dbRs.getInt("cnt");
                    break;
                }
            }
        }
        dbRs.close();
        dbStmt.close();
    } catch (Exception e) {}
    
    // Daily statistics
    int dailyBookings = 0, weeklyBookings = 0, monthlyBookings = 0;
    int dailyGuests = 0, weeklyGuests = 0, monthlyGuests = 0;
    try {
        Statement dStatStmt = conn.createStatement();
        ResultSet dStatRs = dStatStmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE DATE(created_at) = CURDATE()");
        if (dStatRs.next()) dailyBookings = dStatRs.getInt(1);
        dStatRs.close();
        
        dStatRs = dStatStmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)");
        if (dStatRs.next()) weeklyBookings = dStatRs.getInt(1);
        dStatRs.close();
        
        dStatRs = dStatStmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE())");
        if (dStatRs.next()) monthlyBookings = dStatRs.getInt(1);
        dStatRs.close();
        
        dStatRs = dStatStmt.executeQuery("SELECT COUNT(*) FROM guests WHERE DATE(created_at) = CURDATE()");
        if (dStatRs.next()) dailyGuests = dStatRs.getInt(1);
        dStatRs.close();
        
        dStatRs = dStatStmt.executeQuery("SELECT COUNT(*) FROM guests WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)");
        if (dStatRs.next()) weeklyGuests = dStatRs.getInt(1);
        dStatRs.close();
        
        dStatRs = dStatStmt.executeQuery("SELECT COUNT(*) FROM guests WHERE MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE())");
        if (dStatRs.next()) monthlyGuests = dStatRs.getInt(1);
        dStatRs.close();
        
        dStatStmt.close();
    } catch (Exception e) {}
    
    // Payment method statistics
    int cashPayments = 0, cardPayments = 0, bankPayments = 0, onlinePayments = 0;
    try {
        Statement pmStmt = conn.createStatement();
        ResultSet pmRs = pmStmt.executeQuery(
            "SELECT payment_method, COUNT(*) as cnt FROM bills WHERE payment_status = 'PAID' GROUP BY payment_method"
        );
        while (pmRs.next()) {
            String method = pmRs.getString("payment_method");
            int cnt = pmRs.getInt("cnt");
            if ("CASH".equalsIgnoreCase(method)) cashPayments = cnt;
            else if ("CARD".equalsIgnoreCase(method) || "CREDIT_CARD".equalsIgnoreCase(method) || "DEBIT_CARD".equalsIgnoreCase(method)) cardPayments += cnt;
            else if ("BANK_TRANSFER".equalsIgnoreCase(method)) bankPayments = cnt;
            else onlinePayments += cnt;
        }
        pmRs.close();
        pmStmt.close();
    } catch (Exception e) {}
    
    // Daily check-ins/check-outs for the week
    int[] dailyCheckIns = new int[7];
    int[] dailyCheckOuts = new int[7];
    try {
        SimpleDateFormat dayFmt = new SimpleDateFormat("MMM dd");
        Statement ciStmt = conn.createStatement();
        ResultSet ciRs = ciStmt.executeQuery(
            "SELECT DATE(check_in_date) as ci_date, COUNT(*) as cnt " +
            "FROM reservations WHERE check_in_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) AND check_in_date <= CURDATE() " +
            "AND status IN ('CONFIRMED','CHECKED_IN','CHECKED_OUT') GROUP BY DATE(check_in_date)"
        );
        while (ciRs.next()) {
            java.sql.Date ciDate = ciRs.getDate("ci_date");
            String dateStr = dayFmt.format(ciDate);
            for (int i = 0; i < 7; i++) {
                if (dailyLabels[i].equals(dateStr)) {
                    dailyCheckIns[i] = ciRs.getInt("cnt");
                    break;
                }
            }
        }
        ciRs.close();
        
        ResultSet coRs = ciStmt.executeQuery(
            "SELECT DATE(check_out_date) as co_date, COUNT(*) as cnt " +
            "FROM reservations WHERE check_out_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) AND check_out_date <= CURDATE() " +
            "AND status IN ('CHECKED_OUT') GROUP BY DATE(check_out_date)"
        );
        while (coRs.next()) {
            java.sql.Date coDate = coRs.getDate("co_date");
            String dateStr = dayFmt.format(coDate);
            for (int i = 0; i < 7; i++) {
                if (dailyLabels[i].equals(dateStr)) {
                    dailyCheckOuts[i] = coRs.getInt("cnt");
                    break;
                }
            }
        }
        coRs.close();
        ciStmt.close();
    } catch (Exception e) {}
    
    // Weekly totals
    int weeklyCheckIns = 0, weeklyCheckOuts = 0;
    try {
        Statement wcStmt = conn.createStatement();
        ResultSet wcRs = wcStmt.executeQuery(
            "SELECT COUNT(*) FROM reservations WHERE check_in_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND check_in_date <= CURDATE() AND status IN ('CONFIRMED','CHECKED_IN','CHECKED_OUT')"
        );
        if (wcRs.next()) weeklyCheckIns = wcRs.getInt(1);
        wcRs.close();
        
        wcRs = wcStmt.executeQuery(
            "SELECT COUNT(*) FROM reservations WHERE check_out_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND check_out_date <= CURDATE() AND status = 'CHECKED_OUT'"
        );
        if (wcRs.next()) weeklyCheckOuts = wcRs.getInt(1);
        wcRs.close();
        wcStmt.close();
    } catch (Exception e) {}
    
    // Monthly check-ins/check-outs
    int monthlyCheckIns = 0, monthlyCheckOuts = 0;
    try {
        Statement mcStmt = conn.createStatement();
        ResultSet mcRs = mcStmt.executeQuery(
            "SELECT COUNT(*) FROM reservations WHERE MONTH(check_in_date) = MONTH(CURDATE()) AND YEAR(check_in_date) = YEAR(CURDATE()) AND status IN ('CONFIRMED','CHECKED_IN','CHECKED_OUT')"
        );
        if (mcRs.next()) monthlyCheckIns = mcRs.getInt(1);
        mcRs.close();
        
        mcRs = mcStmt.executeQuery(
            "SELECT COUNT(*) FROM reservations WHERE MONTH(check_out_date) = MONTH(CURDATE()) AND YEAR(check_out_date) = YEAR(CURDATE()) AND status = 'CHECKED_OUT'"
        );
        if (mcRs.next()) monthlyCheckOuts = mcRs.getInt(1);
        mcRs.close();
        mcStmt.close();
    } catch (Exception e) {}
    
    // Payment amounts by method
    double cashAmount = 0, cardAmount = 0, bankAmount = 0, onlineAmount = 0;
    try {
        Statement paStmt = conn.createStatement();
        ResultSet paRs = paStmt.executeQuery(
            "SELECT payment_method, SUM(total_amount) as total FROM bills WHERE payment_status = 'PAID' GROUP BY payment_method"
        );
        while (paRs.next()) {
            String method = paRs.getString("payment_method");
            double amt = paRs.getDouble("total");
            if ("CASH".equalsIgnoreCase(method)) cashAmount = amt;
            else if ("CARD".equalsIgnoreCase(method) || "CREDIT_CARD".equalsIgnoreCase(method) || "DEBIT_CARD".equalsIgnoreCase(method)) cardAmount += amt;
            else if ("BANK_TRANSFER".equalsIgnoreCase(method)) bankAmount = amt;
            else onlineAmount += amt;
        }
        paRs.close();
        paStmt.close();
    } catch (Exception e) {}
    
    // Average stay duration
    double avgStayDuration = 0;
    try {
        Statement asStmt = conn.createStatement();
        ResultSet asRs = asStmt.executeQuery("SELECT AVG(number_of_nights) FROM reservations WHERE status IN ('CHECKED_OUT', 'CHECKED_IN')");
        if (asRs.next()) avgStayDuration = asRs.getDouble(1);
        asRs.close();
        asStmt.close();
    } catch (Exception e) {}
    
    // Pending payments
    int pendingPayments = 0;
    double pendingAmount = 0;
    try {
        Statement ppStmt = conn.createStatement();
        ResultSet ppRs = ppStmt.executeQuery("SELECT COUNT(*), IFNULL(SUM(total_amount), 0) FROM bills WHERE payment_status = 'PENDING'");
        if (ppRs.next()) { pendingPayments = ppRs.getInt(1); pendingAmount = ppRs.getDouble(2); }
        ppRs.close();
        ppStmt.close();
    } catch (Exception e) {}
    
    DecimalFormat df = new DecimalFormat("#,###.00");
    SimpleDateFormat sdf = new SimpleDateFormat("MMMM dd, yyyy");
    String today = sdf.format(new java.util.Date());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
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
        
        .admin-profile {
            padding: 20px;
            text-align: center;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        
        .admin-profile .avatar {
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
        
        .admin-profile .avatar img { width: 100%; height: 100%; object-fit: cover; }
        .admin-profile .avatar i { font-size: 40px; color: var(--white); }
        .admin-profile h4 { color: var(--white); font-size: 16px; margin-bottom: 5px; }
        .admin-profile span { color: var(--glow); font-size: 12px; background: rgba(0,192,192,0.2); padding: 3px 12px; border-radius: 15px; }
        
        .nav-menu { padding: 20px 0; }
        .nav-menu h5 { color: rgba(255,255,255,0.5); font-size: 11px; text-transform: uppercase; padding: 10px 25px; letter-spacing: 1px; }
        
        .nav-item {
            display: block;
            padding: 14px 25px;
            color: rgba(255,255,255,0.8);
            text-decoration: none;
            transition: all 0.3s ease;
            border-left: 4px solid transparent;
            cursor: pointer;
        }
        
        .nav-item:hover, .nav-item.active {
            background: rgba(255,255,255,0.1);
            color: var(--white);
            border-left-color: var(--glow);
        }
        
        .nav-item i { width: 25px; margin-right: 12px; }
        .nav-item .badge { float: right; background: var(--danger); color: white; padding: 2px 8px; border-radius: 10px; font-size: 11px; }
        
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
            background: var(--bg);
            border: none;
            cursor: pointer;
            color: var(--primary);
            font-size: 18px;
            transition: all 0.3s ease;
        }
        
        .notification-btn:hover { background: var(--primary); color: var(--white); }
        .notification-btn .badge { position: absolute; top: 0; right: 0; background: var(--danger); color: white; width: 20px; height: 20px; border-radius: 50%; font-size: 11px; display: flex; align-items: center; justify-content: center; }
        
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
        }
        
        .logout-btn:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(220,53,69,0.3); }
        
        /* Stats Cards */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
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
        .stat-icon.staff { background: linear-gradient(135deg, #ff9a9e, #fecfef); color: var(--primary-dark); }
        .stat-icon.available { background: linear-gradient(135deg, var(--primary), var(--glow)); color: white; }
        
        .stat-info h3 { font-size: 28px; color: var(--primary-dark); margin-bottom: 5px; }
        .stat-info p { color: var(--text-light); font-size: 14px; }
        
        /* Content Sections */
        .content-section { display: none; animation: fadeIn 0.5s ease; }
        .content-section.active { display: block; }
        
        @keyframes fadeIn { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
        
        /* Cards */
        .card {
            background: var(--white);
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            margin-bottom: 25px;
            overflow: hidden;
        }
        
        .card-header {
            padding: 20px 25px;
            border-bottom: 1px solid #eee;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .card-header h3 { color: var(--primary-dark); font-size: 18px; }
        .card-body { padding: 25px; }
        
        /* Tables */
        .data-table { width: 100%; border-collapse: collapse; }
        .data-table th, .data-table td { padding: 15px; text-align: left; border-bottom: 1px solid #eee; }
        .data-table th { background: var(--bg); color: var(--primary-dark); font-weight: 600; font-size: 13px; text-transform: uppercase; }
        .data-table tr:hover { background: #f8f9fa; }
        
        .data-table .status { padding: 5px 12px; border-radius: 20px; font-size: 12px; font-weight: 500; }
        .status.available, .status.active, .status.paid, .status.confirmed { background: rgba(40,167,69,0.1); color: var(--success); }
        .status.occupied, .status.checked-in { background: rgba(23,162,184,0.1); color: var(--info); }
        .status.maintenance, .status.pending { background: rgba(255,193,7,0.1); color: #d39e00; }
        .status.reserved, .status.partial { background: rgba(102,126,234,0.1); color: #667eea; }
        .status.inactive, .status.cancelled { background: rgba(220,53,69,0.1); color: var(--danger); }
        
        /* Action Buttons */
        .action-btn { padding: 8px 12px; border: none; border-radius: 8px; cursor: pointer; font-size: 13px; transition: all 0.3s ease; margin-right: 5px; }
        .action-btn.view { background: rgba(23,162,184,0.1); color: var(--info); }
        .action-btn.edit { background: rgba(255,193,7,0.1); color: #d39e00; }
        .action-btn.delete { background: rgba(220,53,69,0.1); color: var(--danger); }
        .action-btn.print { background: rgba(102,126,234,0.1); color: #667eea; }
        .action-btn:hover { transform: scale(1.1); }
        
        /* Room Cards */
        .room-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 30px rgba(0,0,0,0.15);
        }
        .room-card button:hover {
            transform: scale(1.02);
            box-shadow: 0 4px 15px rgba(16,185,129,0.4);
        }
        
        /* Primary Button */
        .btn-primary {
            padding: 12px 25px;
            background: linear-gradient(135deg, var(--primary-dark), var(--primary));
            color: white;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-family: 'Poppins', sans-serif;
            font-weight: 500;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(0,128,128,0.3); }
        
        /* Forms */
        .form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; }
        .form-group { margin-bottom: 20px; }
        .form-group label { display: block; margin-bottom: 8px; color: var(--text-dark); font-weight: 500; font-size: 14px; }
        
        .form-control {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-family: 'Poppins', sans-serif;
            font-size: 14px;
            transition: all 0.3s ease;
        }
        
        .form-control:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 4px rgba(0,128,128,0.1); }
        select.form-control { cursor: pointer; }
        textarea.form-control { min-height: 100px; resize: vertical; }
        
        /* Modal */
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 2000;
            align-items: center;
            justify-content: center;
        }
        
        .modal-overlay.active { display: flex; }
        
        .modal {
            background: white;
            border-radius: 20px;
            width: 90%;
            max-width: 700px;
            max-height: 90vh;
            overflow-y: auto;
            animation: modalIn 0.3s ease;
        }
        
        @keyframes modalIn { from { opacity: 0; transform: scale(0.9); } to { opacity: 1; transform: scale(1); } }
        
        .modal-header { padding: 20px 25px; border-bottom: 1px solid #eee; display: flex; justify-content: space-between; align-items: center; }
        .modal-header h3 { color: var(--primary-dark); }
        .modal-close { width: 35px; height: 35px; border-radius: 50%; border: none; background: #f0f0f0; cursor: pointer; font-size: 18px; transition: all 0.3s ease; }
        .modal-close:hover { background: var(--danger); color: white; }
        .modal-body { padding: 25px; }
        .modal-footer { padding: 20px 25px; border-top: 1px solid #eee; display: flex; justify-content: flex-end; gap: 10px; }
        
        .btn-secondary {
            padding: 12px 25px;
            background: #e0e0e0;
            color: var(--text-dark);
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-family: 'Poppins', sans-serif;
            font-weight: 500;
            transition: all 0.3s ease;
        }
        .btn-secondary:hover { background: #d0d0d0; }
        
        /* Profile */
        .profile-container { display: grid; grid-template-columns: 350px 1fr; gap: 30px; }
        @media (max-width: 900px) { .profile-container { grid-template-columns: 1fr; } }
        
        .profile-card { text-align: center; padding: 40px; background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%); border-radius: 15px; color: white; }
        
        .profile-avatar {
            width: 150px;
            height: 150px;
            border-radius: 50%;
            border: 5px solid white;
            margin: 0 auto 20px;
            overflow: hidden;
            position: relative;
            background: var(--bg);
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }
        
        .profile-avatar img { width: 100%; height: 100%; object-fit: cover; }
        .profile-avatar i { font-size: 80px; color: var(--primary); }
        .profile-avatar .upload-overlay { position: absolute; bottom: 0; left: 0; right: 0; background: rgba(0,0,0,0.7); color: white; padding: 10px; cursor: pointer; opacity: 0; transition: opacity 0.3s ease; font-size: 12px; }
        .profile-avatar:hover .upload-overlay { opacity: 1; }
        
        .profile-name { font-size: 24px; font-weight: 700; margin-bottom: 5px; }
        .profile-role { opacity: 0.9; font-size: 14px; margin-bottom: 20px; }
        .profile-status { display: inline-block; background: #00e676; color: #004d40; padding: 5px 15px; border-radius: 20px; font-size: 12px; font-weight: 600; }
        
        .profile-details { padding: 30px; }
        .profile-section { margin-bottom: 30px; }
        .profile-section-title { font-size: 16px; font-weight: 600; color: var(--primary-dark); margin-bottom: 15px; display: flex; align-items: center; gap: 10px; }
        .profile-section-title i { color: var(--primary); }
        
        .profile-info-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; }
        @media (max-width: 600px) { .profile-info-grid { grid-template-columns: 1fr; } }
        
        .profile-info-item { background: var(--bg); border-radius: 10px; padding: 15px; border-left: 4px solid var(--primary); }
        .profile-info-label { font-size: 12px; color: #888; text-transform: uppercase; margin-bottom: 5px; }
        .profile-info-value { font-size: 15px; color: var(--text); font-weight: 500; word-break: break-all; }
        
        .profile-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-top: 25px; }
        @media (max-width: 600px) { .profile-stats { grid-template-columns: repeat(2, 1fr); } }
        
        .profile-stat-card { background: linear-gradient(135deg, var(--primary) 0%, var(--glow) 100%); color: white; padding: 20px; border-radius: 12px; text-align: center; }
        .profile-stat-value { font-size: 28px; font-weight: 700; }
        .profile-stat-label { font-size: 12px; opacity: 0.9; margin-top: 5px; }
        
        .profile-actions { display: flex; gap: 15px; justify-content: center; margin-top: 25px; }
        .profile-actions .btn-primary, .profile-actions .btn-secondary { padding: 12px 25px; }
        .profile-info h2 { color: var(--primary-dark); margin-bottom: 5px; }
        .profile-info p { color: var(--text-light); }
        
        /* Charts */
        .charts-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 25px; margin-bottom: 25px; }
        .chart-container { background: var(--white); border-radius: 15px; padding: 25px; box-shadow: 0 5px 15px rgba(0,0,0,0.05); min-height: 350px; }
        .chart-container h3 { color: var(--primary-dark); margin-bottom: 20px; font-size: 16px; }
        .chart-container canvas { max-height: 280px !important; }
        
        /* Quick Actions */
        .quick-actions { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 30px; }
        
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
            font-family: 'Poppins', sans-serif;
            text-decoration: none;
        }
        
        .quick-action-btn:hover { border-color: var(--primary); transform: translateY(-5px); box-shadow: 0 10px 30px rgba(0,128,128,0.1); }
        .quick-action-btn i { font-size: 30px; color: var(--primary); }
        .quick-action-btn span { color: var(--text-dark); font-weight: 500; font-size: 15px; line-height: 1.2; }
        
        /* Search & Filter */
        .search-filter { display: flex; gap: 15px; margin-bottom: 20px; flex-wrap: wrap; }
        .search-box { flex: 1; min-width: 250px; position: relative; }
        .search-box input { width: 100%; padding: 12px 15px 12px 45px; border: 2px solid #e0e0e0; border-radius: 10px; font-family: 'Poppins', sans-serif; }
        .search-box input:focus { outline: none; border-color: var(--primary); }
        .search-box i { position: absolute; left: 15px; top: 50%; transform: translateY(-50%); color: var(--text-light); }
        .filter-select { padding: 12px 20px; border: 2px solid #e0e0e0; border-radius: 10px; font-family: 'Poppins', sans-serif; cursor: pointer; min-width: 150px; }
        
        /* Image Upload */
        .image-upload-area { border: 2px dashed #ddd; border-radius: 15px; padding: 40px; text-align: center; cursor: pointer; transition: all 0.3s ease; }
        .image-upload-area:hover { border-color: var(--primary); background: rgba(0,128,128,0.05); }
        .image-upload-area i { font-size: 50px; color: var(--primary); margin-bottom: 15px; }
        
        /* Activity */
        .activity-item { display: flex; align-items: flex-start; gap: 15px; padding: 15px 0; border-bottom: 1px solid #eee; }
        .activity-item:last-child { border-bottom: none; }
        .activity-icon { width: 45px; height: 45px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }
        .activity-icon.booking { background: rgba(102,126,234,0.1); color: #667eea; }
        .activity-icon.checkin { background: rgba(40,167,69,0.1); color: var(--success); }
        .activity-icon.checkout { background: rgba(220,53,69,0.1); color: var(--danger); }
        .activity-content h4 { color: var(--text-dark); font-size: 14px; margin-bottom: 3px; }
        .activity-content p { color: var(--text-light); font-size: 12px; }
        
        /* Mobile Menu Toggle */
        .menu-toggle {
            display: none;
            background: var(--primary);
            color: white;
            border: none;
            padding: 12px 15px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 18px;
            transition: all 0.3s ease;
        }
        .menu-toggle:hover { background: var(--primary-dark); }
        
        /* Sidebar Overlay for Mobile */
        .sidebar-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 999;
        }
        .sidebar-overlay.active { display: block; }
        
        /* Responsive - Keep full sidebar until mobile */
        @media (max-width: 992px) {
            .sidebar { width: 240px; }
            .main-content { margin-left: 240px; }
            .nav-menu h5 { padding: 10px 20px; }
            .nav-item { padding: 12px 20px; }
        }
        
        @media (max-width: 768px) {
            .menu-toggle { display: block; }
            .sidebar { 
                position: fixed;
                transform: translateX(-100%); 
                z-index: 1000;
                width: 280px;
            }
            .sidebar.active { transform: translateX(0); }
            .main-content { margin-left: 0; }
            .stats-grid, .charts-grid { grid-template-columns: 1fr; }
            .top-bar { flex-direction: column; gap: 15px; text-align: center; }
            .top-bar > div:first-child { display: flex; align-items: center; gap: 15px; }
        }
    </style>
</head>
<body>
    <!-- Sidebar -->
    <aside class="sidebar">
        <div class="sidebar-header">
            <div class="logo"><i class="fas fa-umbrella-beach"></i></div>
            <h2>Ocean View Resort</h2>
            <p>Admin Panel</p>
        </div>
        
        <div class="admin-profile">
            <div class="avatar">
                <% if (profilePic != null && !profilePic.isEmpty()) { %>
                    <img src="${pageContext.request.contextPath}/uploads/profiles/<%= profilePic %>" alt="Profile">
                <% } else { %>
                    <i class="fas fa-user"></i>
                <% } %>
            </div>
            <h4><%= fullName %></h4>
            <span>Administrator</span>
        </div>
        
        <nav class="nav-menu">
            <h5>Main Menu</h5>
            <a class="nav-item active" data-section="dashboard" href="javascript:void(0);" onclick="showSection('dashboard')"><i class="fas fa-home"></i><span>Dashboard</span></a>
            <a class="nav-item" href="${pageContext.request.contextPath}/admin/admin-profile.jsp"><i class="fas fa-user-circle"></i><span>My Profile</span></a>
            
            <h5>Management</h5>
            <a class="nav-item" href="${pageContext.request.contextPath}/admin/admin-rooms.jsp"><i class="fas fa-bed"></i><span>Rooms</span></a>
            <a class="nav-item" href="${pageContext.request.contextPath}/admin/admin-room-types.jsp"><i class="fas fa-layer-group"></i><span>Room Types</span></a>
            <a class="nav-item" href="${pageContext.request.contextPath}/admin/admin-staff.jsp"><i class="fas fa-users-cog"></i><span>Staff</span></a>
            <a class="nav-item" href="${pageContext.request.contextPath}/admin/admin-customers.jsp"><i class="fas fa-users"></i><span>Customers</span></a>
            <a class="nav-item" href="${pageContext.request.contextPath}/admin/admin-reservations.jsp"><i class="fas fa-calendar-check"></i><span>Reservations</span></a>
            
            <h5>Bookings</h5>
            <a class="nav-item" href="${pageContext.request.contextPath}/admin/admin-payments.jsp"><i class="fas fa-credit-card"></i><span>Payments</span></a>
            <a class="nav-item" data-section="invoices" href="javascript:void(0);" onclick="showSection('invoices')"><i class="fas fa-file-invoice-dollar"></i><span>Invoices</span></a>
            
            <h5>Reports</h5>
            <a class="nav-item" data-section="reports" href="javascript:void(0);" onclick="showSection('reports')"><i class="fas fa-chart-bar"></i><span>Reports</span></a>
        </nav>
    </aside>
    
    <!-- Main Content -->
    <main class="main-content">
        <!-- Sidebar Overlay for Mobile -->
        <div class="sidebar-overlay" onclick="toggleSidebar()"></div>
        
        <!-- Top Bar -->
        <div class="top-bar">
            <div>
                <button class="menu-toggle" onclick="toggleSidebar()" title="Toggle Menu"><i class="fas fa-bars"></i></button>
                <h1 id="pageTitle">Dashboard</h1>
                <span class="date"><i class="fas fa-calendar-alt"></i> <%= today %></span>
            </div>
            <div class="top-bar-right">
                <button class="notification-btn"><i class="fas fa-bell"></i><span class="badge"><%= todayCheckIns %></span></button>
                <button class="logout-btn" onclick="confirmLogout()"><i class="fas fa-sign-out-alt"></i> Logout</button>
            </div>
        </div>
        
        <!-- Dashboard Section -->
        <section id="dashboard" class="content-section active">
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon rooms"><i class="fas fa-door-open"></i></div>
                    <div class="stat-info"><h3><%= totalRooms %></h3><p>Total Rooms</p></div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon available"><i class="fas fa-check-circle"></i></div>
                    <div class="stat-info"><h3><%= availableRooms %></h3><p>Available Rooms</p></div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon reservations"><i class="fas fa-calendar-alt"></i></div>
                    <div class="stat-info"><h3><%= totalReservations %></h3><p>Total Reservations</p></div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon checkin"><i class="fas fa-sign-in-alt"></i></div>
                    <div class="stat-info"><h3><%= todayCheckIns %></h3><p>Today's Check-ins</p></div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon checkout"><i class="fas fa-sign-out-alt"></i></div>
                    <div class="stat-info"><h3><%= todayCheckOuts %></h3><p>Today's Check-outs</p></div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon guests"><i class="fas fa-user-friends"></i></div>
                    <div class="stat-info"><h3><%= totalGuests %></h3><p>Total Guests</p></div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon staff"><i class="fas fa-id-badge"></i></div>
                    <div class="stat-info"><h3><%= totalStaff %></h3><p>Staff Members</p></div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon revenue"><i class="fas fa-rupee-sign"></i></div>
                    <div class="stat-info"><h3>Rs. <%= df.format(monthlyRevenue) %></h3><p>Monthly Revenue</p></div>
                </div>
            </div>
            
            <div class="quick-actions">
                <button type="button" class="quick-action-btn" onclick="openRoomTypesPage()"><i class="fas fa-layer-group"></i><span>Room Types</span></button>
                <a class="quick-action-btn" href="${pageContext.request.contextPath}/admin/admin-rooms.jsp"><i class="fas fa-bed"></i><span>Add Room</span></a>
                <button type="button" class="quick-action-btn" onclick="openRegisterGuestModal()"><i class="fas fa-user-plus"></i><span>Register Guest</span></button>
                <button type="button" class="quick-action-btn" onclick="openReportsSection()"><i class="fas fa-chart-line"></i><span>View Reports</span></button>
            </div>
            
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
            
            <div class="charts-grid">
                <div class="card">
                    <div class="card-header"><h3><i class="fas fa-history"></i> Recent Activity</h3></div>
                    <div class="card-body">
                        <%
                            try {
                                Statement actStmt = conn.createStatement();
                                ResultSet actRs = actStmt.executeQuery(
                                    "SELECT r.reservation_number, g.full_name, r.status, r.created_at " +
                                    "FROM reservations r JOIN guests g ON r.guest_id = g.guest_id ORDER BY r.created_at DESC LIMIT 5"
                                );
                                while (actRs.next()) {
                                    String status = actRs.getString("status");
                                    String iconClass = "booking";
                                    if ("CHECKED_IN".equals(status)) iconClass = "checkin";
                                    else if ("CHECKED_OUT".equals(status)) iconClass = "checkout";
                        %>
                        <div class="activity-item">
                            <div class="activity-icon <%= iconClass %>"><i class="fas fa-<%= "CHECKED_IN".equals(status) ? "sign-in-alt" : "CHECKED_OUT".equals(status) ? "sign-out-alt" : "calendar-plus" %>"></i></div>
                            <div class="activity-content"><h4><%= actRs.getString("full_name") %> - <%= actRs.getString("reservation_number") %></h4><p><%= status.replace("_", " ") %></p></div>
                        </div>
                        <% } actRs.close(); actStmt.close(); } catch (Exception e) { out.println("<p>No recent activity</p>"); } %>
                    </div>
                </div>
                
                <div class="card">
                    <div class="card-header"><h3><i class="fas fa-calendar-check"></i> Upcoming Check-ins</h3></div>
                    <div class="card-body">
                        <%
                            try {
                                Statement upStmt = conn.createStatement();
                                ResultSet upRs = upStmt.executeQuery(
                                    "SELECT g.full_name, rm.room_number, r.check_in_date FROM reservations r " +
                                    "JOIN guests g ON r.guest_id = g.guest_id JOIN rooms rm ON r.room_id = rm.room_id " +
                                    "WHERE r.check_in_date >= CURDATE() AND r.status = 'CONFIRMED' ORDER BY r.check_in_date LIMIT 5"
                                );
                                while (upRs.next()) {
                        %>
                        <div class="activity-item">
                            <div class="activity-icon checkin"><i class="fas fa-user-clock"></i></div>
                            <div class="activity-content"><h4><%= upRs.getString("full_name") %> - Room <%= upRs.getString("room_number") %></h4><p><%= upRs.getDate("check_in_date") %></p></div>
                        </div>
                        <% } upRs.close(); upStmt.close(); } catch (Exception e) { out.println("<p>No upcoming check-ins</p>"); } %>
                    </div>
                </div>
            </div>
        </section>
        
        <!-- Invoices Section -->
        <section id="invoices" class="content-section">
            <div class="card">
                <div class="card-header">
                    <h3><i class="fas fa-file-invoice-dollar"></i> All Invoices<% if (hasDateFilter) { %> - Filtered: <%= selectedInvoiceDate %><% } %></h3>
                    <button class="btn-primary" onclick="downloadInvoiceSummary()"><i class="fas fa-file-invoice-dollar"></i> Download Invoice Summary</button>
                </div>
                <div class="card-body">
                    <div class="search-filter" style="margin-bottom: 20px;">
                        <label style="font-weight: 600; margin-right: 10px;"><i class="fas fa-calendar"></i> Filter by Date:</label>
                        <input type="date" class="filter-select" id="invoiceDate" value="<%= displayDate %>">
                        <button class="btn-primary" onclick="loadInvoicesByDate()"><i class="fas fa-search"></i> Search</button>
                        <% if (hasDateFilter) { %>
                        <button class="btn-secondary" onclick="showAllInvoices()" style="margin-left: 10px; background: #6c757d;"><i class="fas fa-list"></i> Show All</button>
                        <% } %>
                    </div>
                    
                    <%
                        // Get invoice summary (all or filtered by date)
                        int invTotalCount = 0;
                        double invTotalAmount = 0;
                        int invPaidCount = 0;
                        int invPendingCount = 0;
                        try {
                            String summaryQuery = "SELECT COUNT(*) as cnt, IFNULL(SUM(total_amount), 0) as total, " +
                                "SUM(CASE WHEN payment_status = 'PAID' THEN 1 ELSE 0 END) as paid_cnt, " +
                                "SUM(CASE WHEN payment_status = 'PENDING' THEN 1 ELSE 0 END) as pending_cnt " +
                                "FROM bills" + (hasDateFilter ? " WHERE DATE(generated_at) = ?" : "");
                            PreparedStatement summaryStmt = conn.prepareStatement(summaryQuery);
                            if (hasDateFilter) {
                                summaryStmt.setString(1, selectedInvoiceDate);
                            }
                            ResultSet summaryRs = summaryStmt.executeQuery();
                            if (summaryRs.next()) {
                                invTotalCount = summaryRs.getInt("cnt");
                                invTotalAmount = summaryRs.getDouble("total");
                                invPaidCount = summaryRs.getInt("paid_cnt");
                                invPendingCount = summaryRs.getInt("pending_cnt");
                            }
                            summaryRs.close();
                            summaryStmt.close();
                        } catch (Exception e) {}
                    %>
                    
                    <!-- Summary Cards -->
                    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 25px;">
                        <div style="background: linear-gradient(135deg, #667eea, #764ba2); color: white; padding: 20px; border-radius: 12px; text-align: center;">
                            <div style="font-size: 28px; font-weight: 700;"><%= invTotalCount %></div>
                            <div style="font-size: 13px; opacity: 0.9;">Total Invoices</div>
                        </div>
                        <div style="background: linear-gradient(135deg, #11998e, #38ef7d); color: white; padding: 20px; border-radius: 12px; text-align: center;">
                            <div style="font-size: 28px; font-weight: 700;">Rs. <%= df.format(invTotalAmount) %></div>
                            <div style="font-size: 13px; opacity: 0.9;">Total Amount</div>
                        </div>
                        <div style="background: linear-gradient(135deg, #56ab2f, #a8e063); color: white; padding: 20px; border-radius: 12px; text-align: center;">
                            <div style="font-size: 28px; font-weight: 700;"><%= invPaidCount %></div>
                            <div style="font-size: 13px; opacity: 0.9;">Paid</div>
                        </div>
                        <div style="background: linear-gradient(135deg, #f2994a, #f2c94c); color: white; padding: 20px; border-radius: 12px; text-align: center;">
                            <div style="font-size: 28px; font-weight: 700;"><%= invPendingCount %></div>
                            <div style="font-size: 13px; opacity: 0.9;">Pending</div>
                        </div>
                    </div>
                    
                    <div style="overflow-x: auto;">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Invoice #</th>
                                    <th>Guest Name</th>
                                    <th>Phone</th>
                                    <th>Room</th>
                                    <th>Check-In</th>
                                    <th>Check-Out</th>
                                    <th>Nights</th>
                                    <th>Room Total</th>
                                    <th>Tax</th>
                                    <th>Total Amount</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    try {
                                        String invQuery = "SELECT b.*, r.reservation_number, r.check_in_date, r.check_out_date, " +
                                            "g.full_name, g.phone, rm.room_number, rt.type_name FROM bills b " +
                                            "JOIN reservations r ON b.reservation_id = r.reservation_id " +
                                            "JOIN guests g ON r.guest_id = g.guest_id " +
                                            "JOIN rooms rm ON r.room_id = rm.room_id " +
                                            "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
                                            (hasDateFilter ? "WHERE DATE(b.generated_at) = ? " : "") +
                                            "ORDER BY b.generated_at DESC";
                                        PreparedStatement invStmt = conn.prepareStatement(invQuery);
                                        if (hasDateFilter) {
                                            invStmt.setString(1, selectedInvoiceDate);
                                        }
                                        ResultSet invRs = invStmt.executeQuery();
                                        boolean hasInvoices = false;
                                        int invRowNum = 0;
                                        while (invRs.next()) {
                                            hasInvoices = true;
                                            invRowNum++;
                                            int invId = invRs.getInt("bill_id");
                                            String invPayStatus = invRs.getString("payment_status");
                                            String invStatusClass = "pending";
                                            if ("PAID".equalsIgnoreCase(invPayStatus)) invStatusClass = "paid";
                                            else if ("CANCELLED".equalsIgnoreCase(invPayStatus)) invStatusClass = "cancelled";
                                %>
                                <tr>
                                    <td><%= invRowNum %></td>
                                    <td><strong><%= invRs.getString("bill_number") %></strong></td>
                                    <td><%= invRs.getString("full_name") %></td>
                                    <td><%= invRs.getString("phone") != null ? invRs.getString("phone") : "-" %></td>
                                    <td>Room <%= invRs.getString("room_number") %><br><small style="color:#888;"><%= invRs.getString("type_name") %></small></td>
                                    <td><%= invRs.getDate("check_in_date") %></td>
                                    <td><%= invRs.getDate("check_out_date") %></td>
                                    <td><%= invRs.getInt("number_of_nights") %></td>
                                    <td>Rs. <%= df.format(invRs.getDouble("room_total")) %></td>
                                    <td>Rs. <%= df.format(invRs.getDouble("tax_amount")) %></td>
                                    <td><strong>Rs. <%= df.format(invRs.getDouble("total_amount")) %></strong></td>
                                    <td><span class="status <%= invStatusClass %>"><%= invPayStatus %></span></td>
                                    <td>
                                        <button class="action-btn view" onclick="viewInvoice(<%= invId %>)"><i class="fas fa-eye"></i></button>
                                        <button class="action-btn print" onclick="printInvoice(<%= invId %>)"><i class="fas fa-print"></i></button>
                                    </td>
                                </tr>
                                <% }
                                        if (!hasInvoices) out.println("<tr><td colspan='13' style='text-align:center; padding: 40px;'><i class='fas fa-file-invoice' style='font-size: 40px; color: #ddd; display: block; margin-bottom: 15px;'></i>" + (hasDateFilter ? "No invoices for " + selectedInvoiceDate : "No invoices found") + "</td></tr>");
                                        invRs.close(); invStmt.close();
                                    } catch (Exception e) { out.println("<tr><td colspan='13'>Error loading invoices: " + e.getMessage() + "</td></tr>"); }
                                %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </section>
        
        <!-- Reports Section -->
        <section id="reports" class="content-section">
            <!-- Summary + Detailed Analytics -->
            <div class="card" style="margin-bottom: 20px;">
                <div class="card-header">
                    <h3><i class="fas fa-chart-line"></i> Summary And Detailed Analytics</h3>
                </div>
                <div class="card-body">
                    <div class="stats-grid">
                        <div class="stat-card">
                            <div class="stat-icon revenue"><i class="fas fa-rupee-sign"></i></div>
                            <div class="stat-info"><h3>Rs. <%= df.format(todayRevenue + weeklyRevenue4 + monthlyRevenue) %></h3><p>Combined Revenue Snapshot</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon reservations"><i class="fas fa-calendar-check"></i></div>
                            <div class="stat-info"><h3><%= dailyBookings + weeklyBookings + monthlyBookings %></h3><p>Total Bookings Snapshot</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon guests"><i class="fas fa-user-friends"></i></div>
                            <div class="stat-info"><h3><%= dailyGuests + weeklyGuests + monthlyGuests %></h3><p>New Guests Snapshot</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon available"><i class="fas fa-balance-scale"></i></div>
                            <div class="stat-info"><h3><%= pendingPayments %> / Rs. <%= df.format(pendingAmount) %></h3><p>Pending Payment Summary</p></div>
                        </div>
                    </div>

                    <div class="charts-grid" style="margin-top: 20px;">
                        <div class="chart-container">
                            <h3><i class="fas fa-chart-bar"></i> Daily vs Weekly vs Monthly Comparison</h3>
                            <div style="height: 300px;"><canvas id="summaryCompareChart"></canvas></div>
                        </div>
                        <div class="card" style="margin: 0;">
                            <div class="card-header"><h3><i class="fas fa-table"></i> Detailed Period Summary</h3></div>
                            <div class="card-body">
                                <div style="overflow-x: auto;">
                                    <table class="data-table">
                                        <thead>
                                            <tr>
                                                <th>Period</th>
                                                <th>Revenue</th>
                                                <th>Bookings</th>
                                                <th>New Guests</th>
                                                <th>Check-ins</th>
                                                <th>Check-outs</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr>
                                                <td><strong>Daily</strong></td>
                                                <td>Rs. <%= df.format(todayRevenue) %></td>
                                                <td><%= dailyBookings %></td>
                                                <td><%= dailyGuests %></td>
                                                <td><%= todayCheckIns %></td>
                                                <td><%= todayCheckOuts %></td>
                                            </tr>
                                            <tr>
                                                <td><strong>Weekly</strong></td>
                                                <td>Rs. <%= df.format(weeklyRevenue4) %></td>
                                                <td><%= weeklyBookings %></td>
                                                <td><%= weeklyGuests %></td>
                                                <td><%= weeklyCheckIns %></td>
                                                <td><%= weeklyCheckOuts %></td>
                                            </tr>
                                            <tr>
                                                <td><strong>Monthly</strong></td>
                                                <td>Rs. <%= df.format(monthlyRevenue) %></td>
                                                <td><%= monthlyBookings %></td>
                                                <td><%= monthlyGuests %></td>
                                                <td><%= monthlyCheckIns %></td>
                                                <td><%= monthlyCheckOuts %></td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Report Period Tabs -->
            <div class="report-tabs" style="display: flex; gap: 10px; margin-bottom: 20px;">
                <button class="report-tab" id="tabDaily" onclick="showReportTab('daily')" style="padding: 12px 25px; border: none; background: #e0e0e0; border-radius: 8px; cursor: pointer; font-weight: 500; transition: all 0.3s;">
                    <i class="fas fa-calendar-day"></i> Daily Report
                </button>
                <button class="report-tab active" id="tabWeekly" onclick="showReportTab('weekly')" style="padding: 12px 25px; border: none; background: #008080; color: white; border-radius: 8px; cursor: pointer; font-weight: 500; transition: all 0.3s;">
                    <i class="fas fa-calendar-week"></i> Weekly Report
                </button>
                <button class="report-tab" id="tabMonthly" onclick="showReportTab('monthly')" style="padding: 12px 25px; border: none; background: #e0e0e0; border-radius: 8px; cursor: pointer; font-weight: 500; transition: all 0.3s;">
                    <i class="fas fa-calendar-alt"></i> Monthly Report
                </button>
                <div style="flex: 1;"></div>
                <button class="btn-primary" onclick="downloadReport()"><i class="fas fa-file-pdf"></i> Download PDF</button>
                <button class="btn-primary" style="background: #28a745;" onclick="printReport()"><i class="fas fa-print"></i> Print</button>
            </div>
            
            <!-- Daily Report -->
            <div id="reportDaily" class="report-content" style="display: none;">
                <div class="card">
                    <div class="card-header"><h3><i class="fas fa-calendar-day"></i> Daily Report - <%= today %></h3></div>
                    <div class="card-body">
                        <div class="stats-grid">
                            <div class="stat-card">
                                <div class="stat-icon revenue"><i class="fas fa-rupee-sign"></i></div>
                                <div class="stat-info"><h3>Rs. <%= df.format(todayRevenue) %></h3><p>Today's Revenue</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon reservations"><i class="fas fa-calendar-check"></i></div>
                                <div class="stat-info"><h3><%= dailyBookings %></h3><p>Today's Bookings</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon guests"><i class="fas fa-user-plus"></i></div>
                                <div class="stat-info"><h3><%= dailyGuests %></h3><p>New Guests Today</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon available"><i class="fas fa-door-open"></i></div>
                                <div class="stat-info"><h3><%= availableRooms %> / <%= totalRooms %></h3><p>Available Rooms</p></div>
                            </div>
                        </div>
                        
                        <!-- Daily Additional Stats -->
                        <div class="stats-grid" style="margin-top: 15px;">
                            <div class="stat-card">
                                <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b, #38f9d7);"><i class="fas fa-sign-in-alt"></i></div>
                                <div class="stat-info"><h3><%= todayCheckIns %></h3><p>Today's Check-ins</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon" style="background: linear-gradient(135deg, #fa709a, #fee140);"><i class="fas fa-sign-out-alt"></i></div>
                                <div class="stat-info"><h3><%= todayCheckOuts %></h3><p>Today's Check-outs</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon" style="background: linear-gradient(135deg, #667eea, #764ba2);"><i class="fas fa-bed"></i></div>
                                <div class="stat-info"><h3><%= occupiedRooms %></h3><p>Occupied Rooms</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon" style="background: linear-gradient(135deg, #f5576c, #f093fb);"><i class="fas fa-percentage"></i></div>
                                <div class="stat-info"><h3><%= totalRooms > 0 ? (occupiedRooms * 100 / totalRooms) : 0 %>%</h3><p>Occupancy Rate</p></div>
                            </div>
                        </div>
                        
                        <!-- Today's Transactions Table -->
                        <div style="margin-top: 25px;">
                            <h4 style="margin-bottom: 15px;"><i class="fas fa-list"></i> Today's Transactions</h4>
                            <div style="overflow-x: auto;">
                                <table class="data-table">
                                    <thead><tr><th>Bill #</th><th>Guest</th><th>Room</th><th>Amount</th><th>Method</th><th>Time</th></tr></thead>
                                    <tbody>
                                        <%
                                            try {
                                                Statement tdStmt = conn.createStatement();
                                                ResultSet tdRs = tdStmt.executeQuery(
                                                    "SELECT b.bill_number, g.full_name, ro.room_number, b.total_amount, b.payment_method, b.paid_at " +
                                                    "FROM bills b JOIN reservations r ON b.reservation_id = r.reservation_id " +
                                                    "JOIN guests g ON r.guest_id = g.guest_id JOIN rooms ro ON r.room_id = ro.room_id " +
                                                    "WHERE DATE(b.paid_at) = CURDATE() AND b.payment_status = 'PAID' ORDER BY b.paid_at DESC"
                                                );
                                                boolean hasTd = false;
                                                while (tdRs.next()) {
                                                    hasTd = true;
                                        %>
                                        <tr>
                                            <td><%= tdRs.getString("bill_number") %></td>
                                            <td><%= tdRs.getString("full_name") %></td>
                                            <td>Room <%= tdRs.getString("room_number") %></td>
                                            <td><strong>Rs. <%= df.format(tdRs.getDouble("total_amount")) %></strong></td>
                                            <td><%= tdRs.getString("payment_method") != null ? tdRs.getString("payment_method").replace("_", " ") : "N/A" %></td>
                                            <td><%= new SimpleDateFormat("hh:mm a").format(tdRs.getTimestamp("paid_at")) %></td>
                                        </tr>
                                        <% }
                                                if (!hasTd) out.println("<tr><td colspan='6' style='text-align:center'>No transactions today</td></tr>");
                                                tdRs.close(); tdStmt.close();
                                            } catch (Exception e) { out.println("<tr><td colspan='6'>Error loading data</td></tr>"); }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                        
                        <!-- Today's Check-ins Table -->
                        <div style="margin-top: 25px;">
                            <h4 style="margin-bottom: 15px; color: #28a745;"><i class="fas fa-sign-in-alt"></i> Today's Check-ins</h4>
                            <div style="overflow-x: auto;">
                                <table class="data-table">
                                    <thead><tr><th>#</th><th>Reservation #</th><th>Guest Name</th><th>Phone</th><th>Room</th><th>Check-in Date</th><th>Check-out Date</th><th>Status</th></tr></thead>
                                    <tbody>
                                        <%
                                            try {
                                                Statement ciStmtDaily = conn.createStatement();
                                                ResultSet ciRsDaily = ciStmtDaily.executeQuery(
                                                    "SELECT r.reservation_number, g.full_name, g.phone, rm.room_number, rt.type_name, " +
                                                    "r.check_in_date, r.check_out_date, r.status " +
                                                    "FROM reservations r " +
                                                    "JOIN guests g ON r.guest_id = g.guest_id " +
                                                    "JOIN rooms rm ON r.room_id = rm.room_id " +
                                                    "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
                                                    "WHERE r.check_in_date = CURDATE() AND r.status IN ('CONFIRMED', 'CHECKED_IN') " +
                                                    "ORDER BY r.reservation_number"
                                                );
                                                int ciCount = 0;
                                                while (ciRsDaily.next()) {
                                                    ciCount++;
                                                    String ciStatus = ciRsDaily.getString("status");
                                                    String ciBadgeClass = "CHECKED_IN".equals(ciStatus) ? "paid" : "pending";
                                        %>
                                        <tr>
                                            <td><%= ciCount %></td>
                                            <td><strong><%= ciRsDaily.getString("reservation_number") %></strong></td>
                                            <td><%= ciRsDaily.getString("full_name") %></td>
                                            <td><%= ciRsDaily.getString("phone") != null ? ciRsDaily.getString("phone") : "-" %></td>
                                            <td>Room <%= ciRsDaily.getString("room_number") %> (<%= ciRsDaily.getString("type_name") %>)</td>
                                            <td><%= ciRsDaily.getDate("check_in_date") %></td>
                                            <td><%= ciRsDaily.getDate("check_out_date") %></td>
                                            <td><span class="status <%= ciBadgeClass %>"><%= ciStatus %></span></td>
                                        </tr>
                                        <% }
                                                if (ciCount == 0) out.println("<tr><td colspan='8' style='text-align:center'>No check-ins scheduled for today</td></tr>");
                                                ciRsDaily.close(); ciStmtDaily.close();
                                            } catch (Exception e) { out.println("<tr><td colspan='8'>Error loading check-in data</td></tr>"); }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                        
                        <!-- Today's Check-outs Table -->
                        <div style="margin-top: 25px;">
                            <h4 style="margin-bottom: 15px; color: #dc3545;"><i class="fas fa-sign-out-alt"></i> Today's Check-outs</h4>
                            <div style="overflow-x: auto;">
                                <table class="data-table">
                                    <thead><tr><th>#</th><th>Reservation #</th><th>Guest Name</th><th>Phone</th><th>Room</th><th>Check-in Date</th><th>Check-out Date</th><th>Status</th></tr></thead>
                                    <tbody>
                                        <%
                                            try {
                                                Statement coStmtDaily = conn.createStatement();
                                                ResultSet coRsDaily = coStmtDaily.executeQuery(
                                                    "SELECT r.reservation_number, g.full_name, g.phone, rm.room_number, rt.type_name, " +
                                                    "r.check_in_date, r.check_out_date, r.status " +
                                                    "FROM reservations r " +
                                                    "JOIN guests g ON r.guest_id = g.guest_id " +
                                                    "JOIN rooms rm ON r.room_id = rm.room_id " +
                                                    "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
                                                    "WHERE r.check_out_date = CURDATE() AND r.status IN ('CHECKED_IN', 'CHECKED_OUT') " +
                                                    "ORDER BY r.reservation_number"
                                                );
                                                int coCount = 0;
                                                while (coRsDaily.next()) {
                                                    coCount++;
                                                    String coStatus = coRsDaily.getString("status");
                                                    String coBadgeClass = "CHECKED_OUT".equals(coStatus) ? "paid" : "pending";
                                        %>
                                        <tr>
                                            <td><%= coCount %></td>
                                            <td><strong><%= coRsDaily.getString("reservation_number") %></strong></td>
                                            <td><%= coRsDaily.getString("full_name") %></td>
                                            <td><%= coRsDaily.getString("phone") != null ? coRsDaily.getString("phone") : "-" %></td>
                                            <td>Room <%= coRsDaily.getString("room_number") %> (<%= coRsDaily.getString("type_name") %>)</td>
                                            <td><%= coRsDaily.getDate("check_in_date") %></td>
                                            <td><%= coRsDaily.getDate("check_out_date") %></td>
                                            <td><span class="status <%= coBadgeClass %>"><%= coStatus %></span></td>
                                        </tr>
                                        <% }
                                                if (coCount == 0) out.println("<tr><td colspan='8' style='text-align:center'>No check-outs scheduled for today</td></tr>");
                                                coRsDaily.close(); coStmtDaily.close();
                                            } catch (Exception e) { out.println("<tr><td colspan='8'>Error loading check-out data</td></tr>"); }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Weekly Report -->
            <div id="reportWeekly" class="report-content" style="display: block;">
                <div class="card">
                    <div class="card-header"><h3><i class="fas fa-calendar-week"></i> Weekly Report (Last 7 Days)</h3></div>
                    <div class="card-body">
                        <div class="stats-grid">
                            <div class="stat-card">
                                <div class="stat-icon revenue"><i class="fas fa-rupee-sign"></i></div>
                                <div class="stat-info"><h3>Rs. <%= df.format(weeklyRevenue4) %></h3><p>Weekly Revenue</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon reservations"><i class="fas fa-calendar-check"></i></div>
                                <div class="stat-info"><h3><%= weeklyBookings %></h3><p>Weekly Bookings</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon guests"><i class="fas fa-user-plus"></i></div>
                                <div class="stat-info"><h3><%= weeklyGuests %></h3><p>New Guests</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon available"><i class="fas fa-chart-line"></i></div>
                                <div class="stat-info"><h3>Rs. <%= df.format(weeklyRevenue4 / 7) %></h3><p>Avg Daily Revenue</p></div>
                            </div>
                        </div>
                        
                        <!-- Additional Weekly Stats -->
                        <div class="stats-grid" style="margin-top: 15px;">
                            <div class="stat-card">
                                <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b, #38f9d7);"><i class="fas fa-sign-in-alt"></i></div>
                                <div class="stat-info"><h3><%= weeklyCheckIns %></h3><p>Check-ins</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon" style="background: linear-gradient(135deg, #fa709a, #fee140);"><i class="fas fa-sign-out-alt"></i></div>
                                <div class="stat-info"><h3><%= weeklyCheckOuts %></h3><p>Check-outs</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon" style="background: linear-gradient(135deg, #667eea, #764ba2);"><i class="fas fa-clock"></i></div>
                                <div class="stat-info"><h3><%= pendingPayments %></h3><p>Pending Payments</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon" style="background: linear-gradient(135deg, #f5576c, #f093fb);"><i class="fas fa-exclamation-circle"></i></div>
                                <div class="stat-info"><h3>Rs. <%= df.format(pendingAmount) %></h3><p>Pending Amount</p></div>
                            </div>
                        </div>
                        
                        <div class="charts-grid" style="margin-top: 25px;">
                            <div class="chart-container">
                                <h3><i class="fas fa-chart-bar"></i> Daily Revenue (Last 7 Days)</h3>
                                <div style="height: 300px;"><canvas id="weeklyRevenueChart"></canvas></div>
                            </div>
                            <div class="chart-container">
                                <h3><i class="fas fa-chart-line"></i> Daily Bookings (Last 7 Days)</h3>
                                <div style="height: 300px;"><canvas id="weeklyBookingsChart"></canvas></div>
                            </div>
                        </div>
                        
                        <!-- Weekly Summary Table -->
                        <div style="margin-top: 25px;">
                            <h4 style="margin-bottom: 15px;"><i class="fas fa-table"></i> Weekly Summary by Day</h4>
                            <div style="overflow-x: auto;">
                                <table class="data-table">
                                    <thead><tr><th>Day</th><th>Revenue</th><th>Bookings</th><th>Check-ins</th><th>Check-outs</th></tr></thead>
                                    <tbody>
                                        <% for (int i = 0; i < 7; i++) { %>
                                        <tr>
                                            <td><%= dailyLabels[i] %></td>
                                            <td><strong>Rs. <%= df.format(dailyRevenueData[i]) %></strong></td>
                                            <td><%= dailyBookingsData[i] %></td>
                                            <td><%= dailyCheckIns[i] %></td>
                                            <td><%= dailyCheckOuts[i] %></td>
                                        </tr>
                                        <% } %>
                                    </tbody>
                                    <tfoot style="background: #f8f9fa; font-weight: 600;">
                                        <tr>
                                            <td>Total</td>
                                            <td>Rs. <%= df.format(weeklyRevenue4) %></td>
                                            <td><%= weeklyBookings %></td>
                                            <td><%= weeklyCheckIns %></td>
                                            <td><%= weeklyCheckOuts %></td>
                                        </tr>
                                    </tfoot>
                                </table>
                            </div>
                        </div>
                        
                        <!-- Weekly Check-ins Table -->
                        <div style="margin-top: 25px;">
                            <h4 style="margin-bottom: 15px; color: #28a745;"><i class="fas fa-sign-in-alt"></i> Check-ins (Last 7 Days)</h4>
                            <div style="overflow-x: auto;">
                                <table class="data-table">
                                    <thead><tr><th>#</th><th>Date</th><th>Reservation #</th><th>Guest Name</th><th>Room</th><th>Nights</th><th>Status</th></tr></thead>
                                    <tbody>
                                        <%
                                            try {
                                                Statement wciStmt = conn.createStatement();
                                                ResultSet wciRs = wciStmt.executeQuery(
                                                    "SELECT r.check_in_date, r.reservation_number, g.full_name, rm.room_number, rt.type_name, " +
                                                    "DATEDIFF(r.check_out_date, r.check_in_date) as nights, r.status " +
                                                    "FROM reservations r " +
                                                    "JOIN guests g ON r.guest_id = g.guest_id " +
                                                    "JOIN rooms rm ON r.room_id = rm.room_id " +
                                                    "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
                                                    "WHERE r.check_in_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) AND r.check_in_date <= CURDATE() " +
                                                    "AND r.status IN ('CHECKED_IN', 'CHECKED_OUT') " +
                                                    "ORDER BY r.check_in_date DESC, r.reservation_number"
                                                );
                                                int wciCount = 0;
                                                while (wciRs.next()) {
                                                    wciCount++;
                                                    String wciStatus = wciRs.getString("status");
                                                    String wciBadge = "CHECKED_OUT".equals(wciStatus) ? "paid" : "pending";
                                        %>
                                        <tr>
                                            <td><%= wciCount %></td>
                                            <td><%= wciRs.getDate("check_in_date") %></td>
                                            <td><strong><%= wciRs.getString("reservation_number") %></strong></td>
                                            <td><%= wciRs.getString("full_name") %></td>
                                            <td>Room <%= wciRs.getString("room_number") %> (<%= wciRs.getString("type_name") %>)</td>
                                            <td><%= wciRs.getInt("nights") %></td>
                                            <td><span class="status <%= wciBadge %>"><%= wciStatus %></span></td>
                                        </tr>
                                        <% }
                                                if (wciCount == 0) out.println("<tr><td colspan='7' style='text-align:center'>No check-ins in the last 7 days</td></tr>");
                                                wciRs.close(); wciStmt.close();
                                            } catch (Exception e) { out.println("<tr><td colspan='7'>Error loading data</td></tr>"); }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                        
                        <!-- Weekly Check-outs Table -->
                        <div style="margin-top: 25px;">
                            <h4 style="margin-bottom: 15px; color: #dc3545;"><i class="fas fa-sign-out-alt"></i> Check-outs (Last 7 Days)</h4>
                            <div style="overflow-x: auto;">
                                <table class="data-table">
                                    <thead><tr><th>#</th><th>Date</th><th>Reservation #</th><th>Guest Name</th><th>Room</th><th>Bill #</th><th>Amount</th></tr></thead>
                                    <tbody>
                                        <%
                                            try {
                                                Statement wcoStmt = conn.createStatement();
                                                ResultSet wcoRs = wcoStmt.executeQuery(
                                                    "SELECT r.check_out_date, r.reservation_number, g.full_name, rm.room_number, " +
                                                    "b.bill_number, b.total_amount " +
                                                    "FROM reservations r " +
                                                    "JOIN guests g ON r.guest_id = g.guest_id " +
                                                    "JOIN rooms rm ON r.room_id = rm.room_id " +
                                                    "LEFT JOIN bills b ON r.reservation_id = b.reservation_id " +
                                                    "WHERE r.check_out_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) AND r.check_out_date <= CURDATE() " +
                                                    "AND r.status = 'CHECKED_OUT' " +
                                                    "ORDER BY r.check_out_date DESC, r.reservation_number"
                                                );
                                                int wcoCount = 0;
                                                while (wcoRs.next()) {
                                                    wcoCount++;
                                        %>
                                        <tr>
                                            <td><%= wcoCount %></td>
                                            <td><%= wcoRs.getDate("check_out_date") %></td>
                                            <td><strong><%= wcoRs.getString("reservation_number") %></strong></td>
                                            <td><%= wcoRs.getString("full_name") %></td>
                                            <td>Room <%= wcoRs.getString("room_number") %></td>
                                            <td><%= wcoRs.getString("bill_number") != null ? wcoRs.getString("bill_number") : "-" %></td>
                                            <td><strong>Rs. <%= wcoRs.getDouble("total_amount") > 0 ? df.format(wcoRs.getDouble("total_amount")) : "0.00" %></strong></td>
                                        </tr>
                                        <% }
                                                if (wcoCount == 0) out.println("<tr><td colspan='7' style='text-align:center'>No check-outs in the last 7 days</td></tr>");
                                                wcoRs.close(); wcoStmt.close();
                                            } catch (Exception e) { out.println("<tr><td colspan='7'>Error loading data</td></tr>"); }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Monthly Report -->
            <div id="reportMonthly" class="report-content" style="display: none;">
                <div class="card">
                    <div class="card-header"><h3><i class="fas fa-calendar-alt"></i> Monthly Report - <%= new SimpleDateFormat("MMMM yyyy").format(new java.util.Date()) %></h3></div>
                    <div class="card-body">
                        <div class="stats-grid">
                            <div class="stat-card">
                                <div class="stat-icon revenue"><i class="fas fa-rupee-sign"></i></div>
                                <div class="stat-info"><h3>Rs. <%= df.format(monthlyRevenue) %></h3><p>Monthly Revenue</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon reservations"><i class="fas fa-calendar-check"></i></div>
                                <div class="stat-info"><h3><%= monthlyBookings %></h3><p>Monthly Bookings</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon guests"><i class="fas fa-user-friends"></i></div>
                                <div class="stat-info"><h3><%= monthlyGuests %></h3><p>New Guests</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon available"><i class="fas fa-percentage"></i></div>
                                <div class="stat-info"><h3><%= totalRooms > 0 ? (occupiedRooms * 100 / totalRooms) : 0 %>%</h3><p>Occupancy Rate</p></div>
                            </div>
                        </div>
                        
                        <!-- Additional Monthly Stats -->
                        <div class="stats-grid" style="margin-top: 15px;">
                            <div class="stat-card">
                                <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b, #38f9d7);"><i class="fas fa-sign-in-alt"></i></div>
                                <div class="stat-info"><h3><%= monthlyCheckIns %></h3><p>Total Check-ins</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon" style="background: linear-gradient(135deg, #fa709a, #fee140);"><i class="fas fa-sign-out-alt"></i></div>
                                <div class="stat-info"><h3><%= monthlyCheckOuts %></h3><p>Total Check-outs</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon" style="background: linear-gradient(135deg, #667eea, #764ba2);"><i class="fas fa-bed"></i></div>
                                <div class="stat-info"><h3><%= String.format("%.1f", avgStayDuration) %></h3><p>Avg Stay (Nights)</p></div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-icon" style="background: linear-gradient(135deg, #4facfe, #00f2fe);"><i class="fas fa-chart-line"></i></div>
                                <div class="stat-info"><h3>Rs. <%= df.format(monthlyRevenue / 30) %></h3><p>Avg Daily Revenue</p></div>
                            </div>
                        </div>
                        
                        <!-- Payment Method Breakdown -->
                        <div style="margin-top: 25px;">
                            <h4 style="margin-bottom: 15px;"><i class="fas fa-credit-card"></i> Payment Method Breakdown</h4>
                            <div class="stats-grid">
                                <div class="stat-card" style="border-left: 4px solid #4CAF50;">
                                    <div class="stat-info" style="text-align: center;">
                                        <h3 style="color: #4CAF50;"><i class="fas fa-money-bill-wave"></i> Rs. <%= df.format(cashAmount) %></h3>
                                        <p>Cash (<%= cashPayments %> payments)</p>
                                    </div>
                                </div>
                                <div class="stat-card" style="border-left: 4px solid #2196F3;">
                                    <div class="stat-info" style="text-align: center;">
                                        <h3 style="color: #2196F3;"><i class="fas fa-credit-card"></i> Rs. <%= df.format(cardAmount) %></h3>
                                        <p>Card (<%= cardPayments %> payments)</p>
                                    </div>
                                </div>
                                <div class="stat-card" style="border-left: 4px solid #FF9800;">
                                    <div class="stat-info" style="text-align: center;">
                                        <h3 style="color: #FF9800;"><i class="fas fa-university"></i> Rs. <%= df.format(bankAmount) %></h3>
                                        <p>Bank (<%= bankPayments %> payments)</p>
                                    </div>
                                </div>
                                <div class="stat-card" style="border-left: 4px solid #9C27B0;">
                                    <div class="stat-info" style="text-align: center;">
                                        <h3 style="color: #9C27B0;"><i class="fas fa-mobile-alt"></i> Rs. <%= df.format(onlineAmount) %></h3>
                                        <p>Online (<%= onlinePayments %> payments)</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="charts-grid" style="margin-top: 25px;">
                            <div class="chart-container">
                                <h3><i class="fas fa-chart-bar"></i> Bookings by Room Type</h3>
                                <div style="height: 300px;"><canvas id="bookingsByTypeChart"></canvas></div>
                            </div>
                            <div class="chart-container">
                                <h3><i class="fas fa-chart-pie"></i> Payment Methods Distribution</h3>
                                <div style="height: 300px;"><canvas id="paymentMethodsChart"></canvas></div>
                            </div>
                        </div>
                        
                        <div class="charts-grid" style="margin-top: 25px;">
                            <div class="chart-container">
                                <h3><i class="fas fa-chart-area"></i> Revenue Trend</h3>
                                <div style="height: 300px;"><canvas id="revenueTrendChart"></canvas></div>
                            </div>
                            <div class="chart-container">
                                <h3><i class="fas fa-chart-line"></i> Occupancy Trend</h3>
                                <div style="height: 300px;"><canvas id="occupancyChart"></canvas></div>
                            </div>
                        </div>
                        
                        <!-- Room Performance Table -->
                        <div style="margin-top: 25px;">
                            <h4 style="margin-bottom: 15px;"><i class="fas fa-bed"></i> Room Type Performance</h4>
                            <div style="overflow-x: auto;">
                                <table class="data-table">
                                    <thead><tr><th>Room Type</th><th>Total Bookings</th><th>Revenue</th><th>Avg. Stay (Nights)</th></tr></thead>
                                    <tbody>
                                        <%
                                            try {
                                                Statement rpStmt = conn.createStatement();
                                                ResultSet rpRs = rpStmt.executeQuery(
                                                    "SELECT rt.type_name, COUNT(res.reservation_id) as bookings, " +
                                                    "IFNULL(SUM(b.total_amount), 0) as revenue, " +
                                                    "IFNULL(AVG(res.number_of_nights), 0) as avg_nights " +
                                                    "FROM room_types rt " +
                                                    "LEFT JOIN rooms r ON r.room_type_id = rt.room_type_id " +
                                                    "LEFT JOIN reservations res ON res.room_id = r.room_id AND MONTH(res.created_at) = MONTH(CURDATE()) " +
                                                    "LEFT JOIN bills b ON b.reservation_id = res.reservation_id AND b.payment_status = 'PAID' " +
                                                    "GROUP BY rt.type_name ORDER BY revenue DESC"
                                                );
                                                while (rpRs.next()) {
                                        %>
                                        <tr>
                                            <td><strong><%= rpRs.getString("type_name") %></strong></td>
                                            <td><%= rpRs.getInt("bookings") %></td>
                                            <td>Rs. <%= df.format(rpRs.getDouble("revenue")) %></td>
                                            <td><%= String.format("%.1f", rpRs.getDouble("avg_nights")) %></td>
                                        </tr>
                                        <% }
                                                rpRs.close(); rpStmt.close();
                                            } catch (Exception e) { out.println("<tr><td colspan='4'>Error loading data</td></tr>"); }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                        
                        <!-- Monthly Check-ins Summary -->
                        <div style="margin-top: 25px;">
                            <h4 style="margin-bottom: 15px; color: #28a745;"><i class="fas fa-sign-in-alt"></i> Monthly Check-ins Summary</h4>
                            <div style="overflow-x: auto;">
                                <table class="data-table">
                                    <thead><tr><th>#</th><th>Check-in Date</th><th>Reservation #</th><th>Guest Name</th><th>Room</th><th>Nights</th><th>Status</th></tr></thead>
                                    <tbody>
                                        <%
                                            try {
                                                Statement mciStmt = conn.createStatement();
                                                ResultSet mciRs = mciStmt.executeQuery(
                                                    "SELECT r.check_in_date, r.reservation_number, g.full_name, rm.room_number, rt.type_name, " +
                                                    "DATEDIFF(r.check_out_date, r.check_in_date) as nights, r.status " +
                                                    "FROM reservations r " +
                                                    "JOIN guests g ON r.guest_id = g.guest_id " +
                                                    "JOIN rooms rm ON r.room_id = rm.room_id " +
                                                    "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
                                                    "WHERE MONTH(r.check_in_date) = MONTH(CURDATE()) AND YEAR(r.check_in_date) = YEAR(CURDATE()) " +
                                                    "AND r.status IN ('CHECKED_IN', 'CHECKED_OUT') " +
                                                    "ORDER BY r.check_in_date DESC LIMIT 20"
                                                );
                                                int mciCount = 0;
                                                while (mciRs.next()) {
                                                    mciCount++;
                                                    String mciStatus = mciRs.getString("status");
                                                    String mciBadge = "CHECKED_OUT".equals(mciStatus) ? "paid" : "pending";
                                        %>
                                        <tr>
                                            <td><%= mciCount %></td>
                                            <td><%= mciRs.getDate("check_in_date") %></td>
                                            <td><strong><%= mciRs.getString("reservation_number") %></strong></td>
                                            <td><%= mciRs.getString("full_name") %></td>
                                            <td>Room <%= mciRs.getString("room_number") %> (<%= mciRs.getString("type_name") %>)</td>
                                            <td><%= mciRs.getInt("nights") %></td>
                                            <td><span class="status <%= mciBadge %>"><%= mciStatus %></span></td>
                                        </tr>
                                        <% }
                                                if (mciCount == 0) out.println("<tr><td colspan='7' style='text-align:center'>No check-ins this month</td></tr>");
                                                mciRs.close(); mciStmt.close();
                                            } catch (Exception e) { out.println("<tr><td colspan='7'>Error loading data</td></tr>"); }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                        
                        <!-- Monthly Check-outs Summary -->
                        <div style="margin-top: 25px;">
                            <h4 style="margin-bottom: 15px; color: #dc3545;"><i class="fas fa-sign-out-alt"></i> Monthly Check-outs Summary</h4>
                            <div style="overflow-x: auto;">
                                <table class="data-table">
                                    <thead><tr><th>#</th><th>Check-out Date</th><th>Reservation #</th><th>Guest Name</th><th>Room</th><th>Bill #</th><th>Amount</th></tr></thead>
                                    <tbody>
                                        <%
                                            try {
                                                Statement mcoStmt = conn.createStatement();
                                                ResultSet mcoRs = mcoStmt.executeQuery(
                                                    "SELECT r.check_out_date, r.reservation_number, g.full_name, rm.room_number, " +
                                                    "b.bill_number, b.total_amount " +
                                                    "FROM reservations r " +
                                                    "JOIN guests g ON r.guest_id = g.guest_id " +
                                                    "JOIN rooms rm ON r.room_id = rm.room_id " +
                                                    "LEFT JOIN bills b ON r.reservation_id = b.reservation_id " +
                                                    "WHERE MONTH(r.check_out_date) = MONTH(CURDATE()) AND YEAR(r.check_out_date) = YEAR(CURDATE()) " +
                                                    "AND r.status = 'CHECKED_OUT' " +
                                                    "ORDER BY r.check_out_date DESC LIMIT 20"
                                                );
                                                int mcoCount = 0;
                                                while (mcoRs.next()) {
                                                    mcoCount++;
                                        %>
                                        <tr>
                                            <td><%= mcoCount %></td>
                                            <td><%= mcoRs.getDate("check_out_date") %></td>
                                            <td><strong><%= mcoRs.getString("reservation_number") %></strong></td>
                                            <td><%= mcoRs.getString("full_name") %></td>
                                            <td>Room <%= mcoRs.getString("room_number") %></td>
                                            <td><%= mcoRs.getString("bill_number") != null ? mcoRs.getString("bill_number") : "-" %></td>
                                            <td><strong>Rs. <%= mcoRs.getDouble("total_amount") > 0 ? df.format(mcoRs.getDouble("total_amount")) : "0.00" %></strong></td>
                                        </tr>
                                        <% }
                                                if (mcoCount == 0) out.println("<tr><td colspan='7' style='text-align:center'>No check-outs this month</td></tr>");
                                                mcoRs.close(); mcoStmt.close();
                                            } catch (Exception e) { out.println("<tr><td colspan='7'>Error loading data</td></tr>"); }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </main>
    
    <!-- Modals -->
    
    <!-- Add Room Type Modal -->
    <div class="modal-overlay" id="addRoomTypeModal">
        <div class="modal">
            <div class="modal-header"><h3><i class="fas fa-layer-group"></i> Add Room Type</h3><button class="modal-close" onclick="closeModal('addRoomTypeModal')">&times;</button></div>
            <form id="addRoomTypeForm" onsubmit="return saveRoomType(event)">
                <div class="modal-body">
                    <div class="form-grid">
                        <div class="form-group"><label>Type Name *</label><input type="text" name="typeName" class="form-control" required placeholder="e.g., DELUXE"></div>
                        <div class="form-group"><label>Rate per Night (Rs.) *</label><input type="number" name="rate" class="form-control" required min="0" step="0.01"></div>
                        <div class="form-group"><label>Max Occupancy *</label><input type="number" name="maxOccupancy" class="form-control" required min="1" max="20" value="2"></div>
                        <div class="form-group"><label>Status *</label><select name="status" class="form-control" required><option value="AVAILABLE">Available</option><option value="UNAVAILABLE">Unavailable</option></select></div>
                    </div>
                    <div class="form-group"><label>Description</label><textarea name="description" class="form-control" placeholder="Room type description..."></textarea></div>
                    <div class="form-group"><label>Amenities</label><textarea name="amenities" class="form-control" placeholder="AC, TV, WiFi, Mini Bar..."></textarea></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-secondary" onclick="closeModal('addRoomTypeModal')">Cancel</button>
                    <button type="submit" class="btn-primary"><i class="fas fa-save"></i> Save</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Add Staff Modal -->
    <div class="modal-overlay" id="addStaffModal">
        <div class="modal">
            <div class="modal-header"><h3><i class="fas fa-user-plus"></i> Add Staff Member</h3><button class="modal-close" onclick="closeModal('addStaffModal')">&times;</button></div>
            <form id="addStaffForm" onsubmit="return saveStaff(event)">
                <div class="modal-body">
                    <div class="form-grid">
                        <div class="form-group"><label>Full Name *</label><input type="text" name="fullName" class="form-control" required></div>
                        <div class="form-group"><label>Username *</label><input type="text" name="username" class="form-control" required></div>
                        <div class="form-group"><label>Password *</label><input type="password" name="password" class="form-control" required></div>
                        <div class="form-group"><label>Email</label><input type="email" name="email" class="form-control"></div>
                        <div class="form-group"><label>Phone</label><input type="tel" name="phone" class="form-control"></div>
                        <div class="form-group"><label>Hire Date</label><input type="date" name="hireDate" class="form-control" value="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>"></div>
                    </div>
                    <div class="form-group"><label>Address</label><textarea name="address" class="form-control" placeholder="Address..."></textarea></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-secondary" onclick="closeModal('addStaffModal')">Cancel</button>
                    <button type="submit" class="btn-primary"><i class="fas fa-save"></i> Save Staff</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Add Customer Modal -->
    <div class="modal-overlay" id="addCustomerModal">
        <div class="modal" style="max-width: 650px;">
            <div class="modal-header"><h3><i class="fas fa-user-plus"></i> Register New Customer</h3><button class="modal-close" onclick="closeModal('addCustomerModal')">&times;</button></div>
            <form id="addCustomerForm" onsubmit="return saveCustomer(event)">
                <div class="modal-body">
                    <div class="form-grid">
                        <div class="form-group"><label><i class="fas fa-user" style="color: var(--primary); margin-right: 5px;"></i>Full Name *</label><input type="text" name="fullName" class="form-control" placeholder="e.g., John Smith" required></div>
                        <div class="form-group"><label><i class="fas fa-id-card" style="color: var(--primary); margin-right: 5px;"></i>NIC/Passport</label><input type="text" name="nicPassport" class="form-control" placeholder="e.g., 123456789V"></div>
                        <div class="form-group"><label><i class="fas fa-phone" style="color: var(--primary); margin-right: 5px;"></i>Phone *</label><input type="tel" name="phone" class="form-control" placeholder="+94 7X XXX XXXX" required></div>
                        <div class="form-group"><label><i class="fas fa-envelope" style="color: var(--primary); margin-right: 5px;"></i>Email</label><input type="email" name="email" class="form-control" placeholder="email@example.com"></div>
                        <div class="form-group">
                            <label><i class="fas fa-globe" style="color: var(--primary); margin-right: 5px;"></i>Nationality</label>
                            <select name="nationality" class="form-control">
                                <option value="Sri Lankan">Sri Lankan</option>
                                <option value="British">British</option>
                                <option value="American">American</option>
                                <option value="Indian">Indian</option>
                                <option value="German">German</option>
                                <option value="French">French</option>
                                <option value="Australian">Australian</option>
                                <option value="Chinese">Chinese</option>
                                <option value="Japanese">Japanese</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                        <div class="form-group"><label><i class="fas fa-birthday-cake" style="color: var(--primary); margin-right: 5px;"></i>Date of Birth</label><input type="date" name="dob" class="form-control"></div>
                    </div>
                    <div class="form-group"><label><i class="fas fa-map-marker-alt" style="color: var(--primary); margin-right: 5px;"></i>Address</label><textarea name="address" class="form-control" placeholder="Full address..."></textarea></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-secondary" onclick="closeModal('addCustomerModal')">Cancel</button>
                    <button type="submit" class="btn-primary"><i class="fas fa-user-plus"></i> Register Customer</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- View Customer Modal -->
    <div class="modal-overlay" id="viewCustomerModal">
        <div class="modal" style="max-width: 800px;">
            <div class="modal-header"><h3><i class="fas fa-user"></i> Customer Details</h3><button class="modal-close" onclick="closeModal('viewCustomerModal')">&times;</button></div>
            <div class="modal-body" id="viewCustomerContent">
                <div style="text-align: center; padding: 40px;"><i class="fas fa-spinner fa-spin" style="font-size: 30px; color: var(--primary);"></i><p>Loading...</p></div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary" onclick="closeModal('viewCustomerModal')">Close</button>
                <button type="button" class="btn-primary" id="viewCustomerBookBtn" onclick="openBookingFromView()"><i class="fas fa-calendar-plus"></i> Create Booking</button>
            </div>
        </div>
    </div>
    
    <!-- Edit Customer Modal -->
    <div class="modal-overlay" id="editCustomerModal">
        <div class="modal" style="max-width: 650px;">
            <div class="modal-header"><h3><i class="fas fa-user-edit"></i> Edit Customer</h3><button class="modal-close" onclick="closeModal('editCustomerModal')">&times;</button></div>
            <form id="editCustomerForm" onsubmit="return updateCustomer(event)">
                <input type="hidden" name="id" id="editCustomerId">
                <div class="modal-body">
                    <div class="form-grid">
                        <div class="form-group"><label><i class="fas fa-user" style="color: var(--primary); margin-right: 5px;"></i>Full Name *</label><input type="text" name="fullName" id="editCustomerName" class="form-control" required></div>
                        <div class="form-group"><label><i class="fas fa-id-card" style="color: var(--primary); margin-right: 5px;"></i>NIC/Passport</label><input type="text" name="nicPassport" id="editCustomerNic" class="form-control"></div>
                        <div class="form-group"><label><i class="fas fa-phone" style="color: var(--primary); margin-right: 5px;"></i>Phone *</label><input type="tel" name="phone" id="editCustomerPhone" class="form-control" required></div>
                        <div class="form-group"><label><i class="fas fa-envelope" style="color: var(--primary); margin-right: 5px;"></i>Email</label><input type="email" name="email" id="editCustomerEmail" class="form-control"></div>
                        <div class="form-group">
                            <label><i class="fas fa-globe" style="color: var(--primary); margin-right: 5px;"></i>Nationality</label>
                            <select name="nationality" id="editCustomerNationality" class="form-control">
                                <option value="Sri Lankan">Sri Lankan</option>
                                <option value="British">British</option>
                                <option value="American">American</option>
                                <option value="Indian">Indian</option>
                                <option value="German">German</option>
                                <option value="French">French</option>
                                <option value="Australian">Australian</option>
                                <option value="Chinese">Chinese</option>
                                <option value="Japanese">Japanese</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                        <div class="form-group"><label><i class="fas fa-birthday-cake" style="color: var(--primary); margin-right: 5px;"></i>Date of Birth</label><input type="date" name="dob" id="editCustomerDob" class="form-control"></div>
                    </div>
                    <div class="form-group"><label><i class="fas fa-map-marker-alt" style="color: var(--primary); margin-right: 5px;"></i>Address</label><textarea name="address" id="editCustomerAddress" class="form-control"></textarea></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-secondary" onclick="closeModal('editCustomerModal')">Cancel</button>
                    <button type="submit" class="btn-primary"><i class="fas fa-save"></i> Save Changes</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Book Room for Customer Modal -->
    <div class="modal-overlay" id="bookRoomForCustomerModal">
        <div class="modal" style="max-width: 750px;">
            <div class="modal-header"><h3><i class="fas fa-calendar-plus"></i> Create Room Booking</h3><button class="modal-close" onclick="closeModal('bookRoomForCustomerModal')">&times;</button></div>
            <form id="bookRoomForCustomerForm" onsubmit="return createBookingForCustomer(event)">
                <input type="hidden" name="guestId" id="bookingCustomerId">
                <div class="modal-body">
                    <!-- Customer Info Banner -->
                    <div style="background: linear-gradient(135deg, var(--primary) 0%, var(--glow) 100%); padding: 20px; border-radius: 12px; margin-bottom: 25px; color: white; display: flex; align-items: center; gap: 15px;">
                        <div style="width: 50px; height: 50px; background: rgba(255,255,255,0.2); border-radius: 50%; display: flex; align-items: center; justify-content: center;"><i class="fas fa-user" style="font-size: 20px;"></i></div>
                        <div>
                            <p style="margin: 0; font-size: 12px; opacity: 0.8;">Creating booking for customer:</p>
                            <h3 style="margin: 5px 0 0 0; font-size: 18px;" id="bookingCustomerName">Customer Name</h3>
                        </div>
                    </div>
                    
                    <!-- Room Selection Section -->
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 12px; margin-bottom: 20px;">
                        <h4 style="margin: 0 0 15px 0; color: var(--primary-dark);"><i class="fas fa-bed" style="margin-right: 8px;"></i>Step 1: Select Room Type & Room</h4>
                        <div class="form-grid">
                            <div class="form-group">
                                <label><i class="fas fa-layer-group" style="color: var(--primary); margin-right: 5px;"></i>Room Type</label>
                                <select id="bookingRoomTypeFilter" class="form-control" onchange="filterRoomsByType()">
                                    <option value="">All Room Types</option>
                                    <% try { Statement rtfStmt = conn.createStatement(); ResultSet rtfRs = rtfStmt.executeQuery("SELECT room_type_id, type_name, rate_per_night FROM room_types ORDER BY rate_per_night"); while (rtfRs.next()) { %>
                                    <option value="<%= rtfRs.getString("type_name") %>"><%= rtfRs.getString("type_name") %> - Rs. <%= df.format(rtfRs.getDouble("rate_per_night")) %>/night</option>
                                    <% } rtfRs.close(); rtfStmt.close(); } catch (Exception e) {} %>
                                </select>
                            </div>
                            <div class="form-group">
                                <label><i class="fas fa-door-open" style="color: var(--primary); margin-right: 5px;"></i>Select Room *</label>
                                <select name="roomId" id="customerBookingRoom" class="form-control" required onchange="updateBookingTotal()">
                                    <option value="">-- Choose a Room --</option>
                                    <% try { Statement rmStmt2 = conn.createStatement(); ResultSet rmRs2 = rmStmt2.executeQuery("SELECT r.room_id, r.room_number, r.floor_number AS floor, rt.type_name, rt.rate_per_night, rt.max_occupancy FROM rooms r JOIN room_types rt ON r.room_type_id = rt.room_type_id WHERE r.status = 'AVAILABLE' ORDER BY rt.type_name, r.room_number"); while (rmRs2.next()) { %>
                                    <option value="<%= rmRs2.getInt("room_id") %>" data-rate="<%= rmRs2.getDouble("rate_per_night") %>" data-max="<%= rmRs2.getInt("max_occupancy") %>" data-type="<%= rmRs2.getString("type_name") %>">Room <%= rmRs2.getString("room_number") %> - <%= rmRs2.getString("type_name") %> (Floor <%= rmRs2.getInt("floor") %>) - Rs. <%= df.format(rmRs2.getDouble("rate_per_night")) %>/night</option>
                                    <% } rmRs2.close(); rmStmt2.close(); } catch (Exception e) { out.println("<!-- Error: " + e.getMessage() + " -->"); } %>
                                </select>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Dates & Details Section -->
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 12px; margin-bottom: 20px;">
                        <h4 style="margin: 0 0 15px 0; color: var(--primary-dark);"><i class="fas fa-calendar-alt" style="margin-right: 8px;"></i>Step 2: Select Dates & Details</h4>
                        <div class="form-grid">
                            <div class="form-group"><label><i class="fas fa-sign-in-alt" style="color: #10b981; margin-right: 5px;"></i>Check-in Date *</label><input type="date" name="checkInDate" id="customerCheckIn" class="form-control" required min="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>" onchange="updateBookingTotal(); updateCheckoutMin();"></div>
                            <div class="form-group"><label><i class="fas fa-sign-out-alt" style="color: #ef4444; margin-right: 5px;"></i>Check-out Date *</label><input type="date" name="checkOutDate" id="customerCheckOut" class="form-control" required onchange="updateBookingTotal()"></div>
                            <div class="form-group"><label><i class="fas fa-users" style="color: var(--primary); margin-right: 5px;"></i>Number of Guests *</label><input type="number" name="numGuests" id="customerNumGuests" class="form-control" value="1" min="1" max="10" required></div>
                            <div class="form-group">
                                <label><i class="fas fa-money-bill-wave" style="color: #f59e0b; margin-right: 5px;"></i>Estimated Total</label>
                                <input type="text" id="customerBookingTotal" class="form-control" readonly value="Rs. 0.00" style="font-weight: 700; color: #10b981; font-size: 18px; background: #ecfdf5;">
                            </div>
                        </div>
                    </div>
                    
                    <div class="form-group"><label><i class="fas fa-comment-dots" style="color: var(--primary); margin-right: 5px;"></i>Special Requests (Optional)</label><textarea name="specialRequests" id="customerSpecialReqs" class="form-control" placeholder="Any special requirements like extra bed, late check-in, dietary needs..." rows="3"></textarea></div>
                </div>
                <div class="modal-footer" style="gap: 10px;">
                    <button type="button" class="btn-secondary" onclick="closeModal('bookRoomForCustomerModal')"><i class="fas fa-times"></i> Cancel</button>
                    <button type="submit" class="btn-primary" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 12px 25px;"><i class="fas fa-check-circle"></i> Confirm Booking</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Add Reservation Modal -->
    <div class="modal-overlay" id="addReservationModal">
        <div class="modal">
            <div class="modal-header"><h3><i class="fas fa-calendar-plus"></i> New Reservation</h3><button class="modal-close" onclick="closeModal('addReservationModal')">&times;</button></div>
            <form id="addReservationForm" onsubmit="return saveReservation(event)">
                <div class="modal-body">
                    <div class="form-grid">
                        <div class="form-group">
                            <label>Guest *</label>
                            <select name="guestId" class="form-control" required>
                                <option value="">Select Guest</option>
                                <% try { Statement gStmt = conn.createStatement(); ResultSet gRs = gStmt.executeQuery("SELECT guest_id, full_name, phone FROM guests ORDER BY full_name"); while (gRs.next()) { %>
                                <option value="<%= gRs.getInt("guest_id") %>"><%= gRs.getString("full_name") %> (<%= gRs.getString("phone") %>)</option>
                                <% } gRs.close(); gStmt.close(); } catch (Exception e) {} %>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Room *</label>
                            <select name="roomId" class="form-control" required id="roomSelect">
                                <option value="">Select Room</option>
                                <% try { Statement rmStmt = conn.createStatement(); ResultSet rmRs = rmStmt.executeQuery("SELECT r.room_id, r.room_number, rt.type_name, rt.rate_per_night FROM rooms r JOIN room_types rt ON r.room_type_id = rt.room_type_id WHERE r.status = 'AVAILABLE' ORDER BY r.room_number"); while (rmRs.next()) { %>
                                <option value="<%= rmRs.getInt("room_id") %>" data-rate="<%= rmRs.getDouble("rate_per_night") %>">Room <%= rmRs.getString("room_number") %> - <%= rmRs.getString("type_name") %> (Rs. <%= df.format(rmRs.getDouble("rate_per_night")) %>/night)</option>
                                <% } rmRs.close(); rmStmt.close(); } catch (Exception e) {} %>
                            </select>
                        </div>
                        <div class="form-group"><label>Check-in Date *</label><input type="date" name="checkInDate" class="form-control" required min="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>" id="checkInDate"></div>
                        <div class="form-group"><label>Check-out Date *</label><input type="date" name="checkOutDate" class="form-control" required id="checkOutDate"></div>
                        <div class="form-group"><label>Number of Guests</label><input type="number" name="numGuests" class="form-control" value="1" min="1" max="10"></div>
                        <div class="form-group"><label>Estimated Total</label><input type="text" id="estimatedTotal" class="form-control" readonly value="Rs. 0.00"></div>
                    </div>
                    <div class="form-group"><label>Special Requests</label><textarea name="specialRequests" class="form-control" placeholder="Any special requests..."></textarea></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-secondary" onclick="closeModal('addReservationModal')">Cancel</button>
                    <button type="submit" class="btn-primary"><i class="fas fa-save"></i> Create Reservation</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Edit Profile Modal -->
    <div class="modal-overlay" id="editProfileModal">
        <div class="modal">
            <div class="modal-header"><h3><i class="fas fa-user-edit"></i> Edit Profile</h3><button class="modal-close" onclick="closeModal('editProfileModal')">&times;</button></div>
            <form id="editProfileForm" onsubmit="return updateProfile(event)">
                <div class="modal-body">
                    <div class="form-grid">
                        <div class="form-group"><label>Full Name *</label><input type="text" name="fullName" class="form-control" value="<%= fullName %>" required></div>
                        <div class="form-group"><label>Username *</label><input type="text" name="username" class="form-control" value="<%= username %>" required></div>
                        <div class="form-group"><label>Email</label><input type="email" name="email" class="form-control" value="<%= email %>"></div>
                        <div class="form-group"><label>Phone</label><input type="tel" name="phone" class="form-control" value="<%= phone %>"></div>
                    </div>
                    <div class="form-group"><label>Address</label><textarea name="address" class="form-control"><%= address %></textarea></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-secondary" onclick="closeModal('editProfileModal')">Cancel</button>
                    <button type="submit" class="btn-primary"><i class="fas fa-save"></i> Update</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Change Password Modal -->
    <div class="modal-overlay" id="changePasswordModal">
        <div class="modal" style="max-width: 450px;">
            <div class="modal-header"><h3><i class="fas fa-key"></i> Change Password</h3><button class="modal-close" onclick="closeModal('changePasswordModal')">&times;</button></div>
            <form id="changePasswordForm" onsubmit="return changePassword(event)">
                <div class="modal-body">
                    <div class="form-group"><label>Current Password *</label><input type="password" name="currentPassword" class="form-control" required></div>
                    <div class="form-group"><label>New Password *</label><input type="password" name="newPassword" class="form-control" required minlength="6"></div>
                    <div class="form-group"><label>Confirm New Password *</label><input type="password" name="confirmPassword" class="form-control" required minlength="6"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-secondary" onclick="closeModal('changePasswordModal')">Cancel</button>
                    <button type="submit" class="btn-primary"><i class="fas fa-save"></i> Change Password</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        // Show login success message
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
        
        // Navigation
        const navItems = document.querySelectorAll('.nav-item');
        const sections = document.querySelectorAll('.content-section');
        const pageTitle = document.getElementById('pageTitle');
        
        navItems.forEach(item => {
            // Only add click handler for items with data-section and NO external href
            const hasHref = item.hasAttribute('href') && item.getAttribute('href') !== '#' && item.getAttribute('href') !== '';
            if (!hasHref && item.dataset.section) {
                item.addEventListener('click', (e) => {
                    e.preventDefault();
                    showSection(item.dataset.section);
                });
            }
        });
        
        // Toggle sidebar for mobile
        function toggleSidebar() {
            document.querySelector('.sidebar').classList.toggle('active');
            document.querySelector('.sidebar-overlay').classList.toggle('active');
        }
        
        function showSection(sectionId) {
            navItems.forEach(nav => nav.classList.remove('active'));
            sections.forEach(sec => sec.classList.remove('active'));
            const navEl = document.querySelector(`[data-section="${sectionId}"]`);
            const secEl = document.getElementById(sectionId);
            if (navEl) navEl.classList.add('active');
            if (secEl) secEl.classList.add('active');
            const titles = {'dashboard':'Dashboard','profile':'My Profile','rooms':'Room Management','room-types':'Room Types','staff':'Staff Management','customers':'Customer Management','room-selection':'Select Room for Booking','reservations':'Reservations','payments':'Payments','invoices':'Invoices','reports':'Reports & Analytics'};
            pageTitle.textContent = titles[sectionId] || 'Dashboard';
            
            // Close sidebar on mobile
            if (window.innerWidth <= 768) {
                document.querySelector('.sidebar').classList.remove('active');
                document.querySelector('.sidebar-overlay').classList.remove('active');
            }
            
            // Re-render charts when switching to dashboard or reports
            if (sectionId === 'dashboard' || sectionId === 'reports') {
                setTimeout(() => {
                    window.dispatchEvent(new Event('resize'));
                }, 100);
            }
        }

        function openRoomTypesPage() {
            window.location.href = '${pageContext.request.contextPath}/admin/admin-room-types.jsp';
        }

        function openAddRoomPage() {
            window.location.href = '${pageContext.request.contextPath}/admin/admin-rooms.jsp';
        }

        function openRegisterGuestModal() {
            showSection('dashboard');
            openModal('addCustomerModal');
            const firstInput = document.querySelector('#addCustomerForm input[name="fullName"]');
            if (firstInput) firstInput.focus();
        }

        function openReportsSection() {
            showSection('reports');
            const reportsSection = document.getElementById('reports');
            if (reportsSection) {
                reportsSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }
        
        // Modal functions
        function openModal(modalId) { document.getElementById(modalId).classList.add('active'); }
        function closeModal(modalId) { document.getElementById(modalId).classList.remove('active'); }
        
        document.querySelectorAll('.modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.classList.remove('active'); });
        });
        
        // Logout
        function confirmLogout() {
            Swal.fire({
                title: 'Logout?', text: 'Are you sure you want to logout?', icon: 'question',
                showCancelButton: true, confirmButtonColor: '#008080', cancelButtonColor: '#d33',
                confirmButtonText: 'Yes, Logout', cancelButtonText: 'Cancel'
            }).then((result) => { if (result.isConfirmed) window.location.href = '${pageContext.request.contextPath}/logout.jsp'; });
        }
        
        // Table filtering
        function filterTable(tableId, query) {
            const rows = document.getElementById(tableId).getElementsByTagName('tbody')[0].getElementsByTagName('tr');
            query = query.toLowerCase();
            for (let row of rows) row.style.display = row.textContent.toLowerCase().includes(query) ? '' : 'none';
        }
        
        function filterTableByStatus(tableId, status, columnIndex) {
            const rows = document.getElementById(tableId).getElementsByTagName('tbody')[0].getElementsByTagName('tr');
            for (let row of rows) {
                if (!status) { row.style.display = ''; }
                else { row.style.display = row.cells[columnIndex].textContent.trim().toUpperCase().includes(status.toUpperCase()) ? '' : 'none'; }
            }
        }
        
        // Filter reservations by staff
        function filterByStaff(staffId) {
            const rows = document.getElementById('reservationsTable').getElementsByTagName('tbody')[0].getElementsByTagName('tr');
            for (let row of rows) {
                if (!staffId) { row.style.display = ''; }
                else { row.style.display = row.dataset.staff === staffId ? '' : 'none'; }
            }
        }
        
        // Reservation total calculation
        const roomSelect = document.getElementById('roomSelect');
        const checkIn = document.getElementById('checkInDate');
        const checkOut = document.getElementById('checkOutDate');
        const estimatedTotal = document.getElementById('estimatedTotal');
        
        function calculateTotal() {
            const selectedRoom = roomSelect?.options[roomSelect.selectedIndex];
            const rate = parseFloat(selectedRoom?.dataset?.rate) || 0;
            const startDate = new Date(checkIn?.value);
            const endDate = new Date(checkOut?.value);
            if (startDate && endDate && endDate > startDate) {
                const nights = Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24));
                estimatedTotal.value = 'Rs. ' + (nights * rate).toLocaleString('en-US', {minimumFractionDigits: 2});
            } else { estimatedTotal.value = 'Rs. 0.00'; }
        }
        
        roomSelect?.addEventListener('change', calculateTotal);
        checkIn?.addEventListener('change', calculateTotal);
        checkOut?.addEventListener('change', calculateTotal);
        
        // Form submissions
        function saveRoomType(e) { e.preventDefault(); submitForm(new FormData(document.getElementById('addRoomTypeForm')), 'addRoomType', 'Room type added!', 'addRoomTypeModal'); return false; }
        function saveStaff(e) { e.preventDefault(); submitForm(new FormData(document.getElementById('addStaffForm')), 'addStaff', 'Staff added!', 'addStaffModal'); return false; }
        
        function saveCustomer(e) {
            e.preventDefault();
            const formData = new FormData(document.getElementById('addCustomerForm'));
            const customerName = formData.get('fullName');
            formData.append('action', 'addCustomer');
            
            fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp', { method: 'POST', body: formData })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    const guestId = data.guestId;
                    closeModal('addCustomerModal');
                    
                    // Store customer info for room selection
                    document.getElementById('selectedCustomerId').value = guestId;
                    document.getElementById('selectedCustomerName').value = customerName;
                    document.getElementById('roomSelectionCustomerName').textContent = customerName;
                    
                    // Show success message with button to go to rooms
                    Swal.fire({
                        icon: 'success',
                        title: 'Registration Successful!',
                        text: customerName,
                        confirmButtonText: 'Go to View Rooms',
                        confirmButtonColor: '#008080'
                    }).then(() => {
                        showSection('room-selection');
                    });
                } else {
                    Swal.fire({icon: 'error', title: 'Registration Failed', text: data.message || 'Could not register customer', confirmButtonColor: '#008080'});
                }
            })
            .catch(err => Swal.fire({icon: 'error', title: 'Error', text: 'Something went wrong!'}));
            return false;
        }
        
        function saveQuickCustomer(e) {
            e.preventDefault();
            const formData = new FormData(document.getElementById('quickCustomerForm'));
            const customerName = formData.get('fullName');
            formData.append('action', 'addCustomer');
            
            fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp', { method: 'POST', body: formData })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    const guestId = data.guestId;
                    
                    // Store customer info for room selection
                    document.getElementById('selectedCustomerId').value = guestId;
                    document.getElementById('selectedCustomerName').value = customerName;
                    document.getElementById('roomSelectionCustomerName').textContent = customerName;
                    
                    // Reset form
                    document.getElementById('quickCustomerForm').reset();
                    
                    // Show success message with button to go to rooms
                    Swal.fire({
                        icon: 'success',
                        title: 'Registration Successful!',
                        text: customerName,
                        confirmButtonText: 'Go to View Rooms',
                        confirmButtonColor: '#008080'
                    }).then(() => {
                        showSection('room-selection');
                    });
                } else {
                    Swal.fire({icon: 'error', title: 'Registration Failed', text: data.message || 'Could not register customer', confirmButtonColor: '#008080'});
                }
            })
            .catch(err => Swal.fire({icon: 'error', title: 'Error', text: 'Something went wrong!'}));
            return false;
        }
        
        function saveReservation(e) { e.preventDefault(); submitForm(new FormData(document.getElementById('addReservationForm')), 'addReservation', 'Reservation created!', 'addReservationModal'); return false; }
        function updateProfile(e) { e.preventDefault(); submitForm(new FormData(document.getElementById('editProfileForm')), 'updateProfile', 'Profile updated!', 'editProfileModal'); return false; }
        
        function changePassword(e) {
            e.preventDefault();
            const form = document.getElementById('changePasswordForm');
            if (form.querySelector('[name="newPassword"]').value !== form.querySelector('[name="confirmPassword"]').value) {
                Swal.fire({icon: 'error', title: 'Error', text: 'Passwords do not match!'});
                return false;
            }
            submitForm(new FormData(form), 'changePassword', 'Password changed!', 'changePasswordModal');
            return false;
        }
        
        function submitForm(formData, action, successMsg, modalId) {
            formData.append('action', action);
            fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp', { method: 'POST', body: formData })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    Swal.fire({icon: 'success', title: 'Success!', text: successMsg, confirmButtonColor: '#008080'})
                    .then(() => { closeModal(modalId); location.reload(); });
                } else {
                    Swal.fire({icon: 'error', title: 'Error', text: data.message || 'Operation failed', confirmButtonColor: '#008080'});
                }
            })
            .catch(err => Swal.fire({icon: 'error', title: 'Error', text: 'Something went wrong!'}));
        }
        
        // Delete functions
        function deleteRoomType(id) { confirmDelete('RoomType', id); }
        function deleteStaff(id) { confirmDelete('Staff', id); }
        function deleteCustomer(id) { confirmDelete('Customer', id); }
        
        function confirmDelete(type, id) {
            Swal.fire({
                title: 'Delete?', text: 'Are you sure you want to delete this?', icon: 'warning',
                showCancelButton: true, confirmButtonColor: '#dc3545', cancelButtonColor: '#6c757d', confirmButtonText: 'Delete'
            }).then((result) => {
                if (result.isConfirmed) {
                    const fd = new FormData();
                    fd.append('action', 'delete' + type);
                    fd.append('id', id);
                    fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp', { method: 'POST', body: fd })
                    .then(r => r.json())
                    .then(data => {
                        if (data.success) Swal.fire({icon: 'success', title: 'Deleted!', confirmButtonColor: '#008080'}).then(() => location.reload());
                        else Swal.fire({icon: 'error', title: 'Error', text: data.message});
                    });
                }
            });
        }
        
        // View/Edit placeholders
        function viewStaff(id) { Swal.fire({title: 'Staff Details', text: 'View staff #' + id, icon: 'info'}); }
        function editStaff(id) { Swal.fire({title: 'Edit Staff', text: 'Edit staff #' + id, icon: 'info'}); }
        
        // Customer Management Functions
        let currentViewCustomerId = null;
        
        function viewCustomerDetails(id) {
            currentViewCustomerId = id;
            document.getElementById('viewCustomerContent').innerHTML = '<div style="text-align: center; padding: 40px;"><i class="fas fa-spinner fa-spin" style="font-size: 30px; color: var(--primary);"></i><p>Loading...</p></div>';
            openModal('viewCustomerModal');
            
            // Fetch customer details
            Promise.all([
                fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp?action=getCustomer&id=' + id).then(r => r.json()),
                fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp?action=getCustomerBookings&id=' + id).then(r => r.json())
            ]).then(([customer, bookings]) => {
                if (customer.success) {
                    let html = '<div style="display: flex; gap: 30px; flex-wrap: wrap;">';
                    html += '<div style="flex: 1; min-width: 300px;">';
                    html += '<div style="text-align: center; margin-bottom: 20px;">';
                    html += '<div style="width: 80px; height: 80px; border-radius: 50%; background: linear-gradient(135deg, var(--primary) 0%, var(--glow) 100%); display: inline-flex; align-items: center; justify-content: center;"><span style="font-size: 32px; color: white; font-weight: 600;">' + customer.data.full_name.charAt(0).toUpperCase() + '</span></div>';
                    html += '<h3 style="margin: 10px 0 5px 0; color: var(--primary-dark);">' + customer.data.full_name + '</h3>';
                    html += '<span style="background: var(--primary); color: white; padding: 3px 12px; border-radius: 20px; font-size: 12px;">' + (customer.data.nationality || 'N/A') + '</span>';
                    html += '</div>';
                    html += '<div style="background: #f8f9fa; padding: 15px; border-radius: 10px;">';
                    html += '<p style="margin: 8px 0;"><i class="fas fa-id-card" style="width: 20px; color: var(--primary);"></i> <strong>NIC/Passport:</strong> ' + (customer.data.nic_passport || 'N/A') + '</p>';
                    html += '<p style="margin: 8px 0;"><i class="fas fa-envelope" style="width: 20px; color: var(--primary);"></i> <strong>Email:</strong> ' + (customer.data.email || 'N/A') + '</p>';
                    html += '<p style="margin: 8px 0;"><i class="fas fa-phone" style="width: 20px; color: var(--primary);"></i> <strong>Phone:</strong> ' + (customer.data.phone || 'N/A') + '</p>';
                    html += '<p style="margin: 8px 0;"><i class="fas fa-birthday-cake" style="width: 20px; color: var(--primary);"></i> <strong>DOB:</strong> ' + (customer.data.date_of_birth || 'N/A') + '</p>';
                    html += '<p style="margin: 8px 0;"><i class="fas fa-map-marker-alt" style="width: 20px; color: var(--primary);"></i> <strong>Address:</strong> ' + (customer.data.address || 'N/A') + '</p>';
                    html += '<p style="margin: 8px 0;"><i class="fas fa-calendar" style="width: 20px; color: var(--primary);"></i> <strong>Registered:</strong> ' + (customer.data.created_at || 'N/A') + '</p>';
                    html += '</div></div>';
                    
                    // Booking History
                    html += '<div style="flex: 1; min-width: 300px;">';
                    html += '<h4 style="color: var(--primary-dark); margin-bottom: 15px;"><i class="fas fa-history"></i> Booking History (' + (bookings.data ? bookings.data.length : 0) + ')</h4>';
                    if (bookings.data && bookings.data.length > 0) {
                        html += '<div style="max-height: 300px; overflow-y: auto;">';
                        bookings.data.forEach(function(b) {
                            let statusColor = b.status === 'CONFIRMED' ? '#28a745' : (b.status === 'CHECKED_IN' ? '#17a2b8' : (b.status === 'CHECKED_OUT' ? '#6c757d' : '#ffc107'));
                            html += '<div style="background: white; border: 1px solid #eee; border-radius: 8px; padding: 12px; margin-bottom: 10px;">';
                            html += '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">';
                            html += '<strong style="color: var(--primary);">#' + b.reservation_number + '</strong>';
                            html += '<span style="background: ' + statusColor + '; color: white; padding: 2px 8px; border-radius: 12px; font-size: 11px;">' + b.status + '</span>';
                            html += '</div>';
                            html += '<p style="margin: 5px 0; font-size: 13px;"><i class="fas fa-bed" style="color: #999;"></i> Room ' + b.room_number + ' - ' + b.room_type + '</p>';
                            html += '<p style="margin: 5px 0; font-size: 13px;"><i class="fas fa-calendar-alt" style="color: #999;"></i> ' + b.check_in + ' to ' + b.check_out + '</p>';
                            html += '<p style="margin: 5px 0; font-size: 13px; color: var(--primary); font-weight: 600;">Rs. ' + Number(b.total).toLocaleString() + '</p>';
                            html += '</div>';
                        });
                        html += '</div>';
                    } else {
                        html += '<div style="text-align: center; padding: 30px; color: #999;"><i class="fas fa-calendar-times" style="font-size: 40px; margin-bottom: 10px;"></i><p>No bookings yet</p></div>';
                    }
                    html += '</div></div>';
                    
                    document.getElementById('viewCustomerContent').innerHTML = html;
                } else {
                    document.getElementById('viewCustomerContent').innerHTML = '<div style="text-align: center; padding: 40px; color: #dc3545;"><i class="fas fa-exclamation-circle" style="font-size: 40px;"></i><p>Failed to load customer details</p></div>';
                }
            }).catch(err => {
                document.getElementById('viewCustomerContent').innerHTML = '<div style="text-align: center; padding: 40px; color: #dc3545;"><i class="fas fa-exclamation-circle" style="font-size: 40px;"></i><p>Error loading data</p></div>';
            });
        }
        
        function openBookingFromView() {
            closeModal('viewCustomerModal');
            if (currentViewCustomerId) {
                fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp?action=getCustomer&id=' + currentViewCustomerId)
                .then(r => r.json())
                .then(data => {
                    if (data.success) openBookingForCustomer(currentViewCustomerId, data.data.full_name);
                });
            }
        }
        
        function editCustomerDetails(id) {
            fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp?action=getCustomer&id=' + id)
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    document.getElementById('editCustomerId').value = id;
                    document.getElementById('editCustomerName').value = data.data.full_name || '';
                    document.getElementById('editCustomerNic').value = data.data.nic_passport || '';
                    document.getElementById('editCustomerPhone').value = data.data.phone || '';
                    document.getElementById('editCustomerEmail').value = data.data.email || '';
                    document.getElementById('editCustomerNationality').value = data.data.nationality || 'Sri Lankan';
                    document.getElementById('editCustomerDob').value = data.data.date_of_birth || '';
                    document.getElementById('editCustomerAddress').value = data.data.address || '';
                    openModal('editCustomerModal');
                } else {
                    Swal.fire({icon: 'error', title: 'Error', text: 'Failed to load customer data'});
                }
            });
        }
        
        function updateCustomer(e) {
            e.preventDefault();
            const formData = new FormData(document.getElementById('editCustomerForm'));
            formData.append('action', 'editCustomer');
            fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp', { method: 'POST', body: formData })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    Swal.fire({icon: 'success', title: 'Success!', text: 'Customer updated successfully!', confirmButtonColor: '#008080'})
                    .then(() => { closeModal('editCustomerModal'); location.reload(); });
                } else {
                    Swal.fire({icon: 'error', title: 'Error', text: data.message || 'Update failed'});
                }
            });
            return false;
        }
        
        function openBookingForCustomer(id, name) {
            document.getElementById('bookingCustomerId').value = id;
            document.getElementById('bookingCustomerName').textContent = name;
            document.getElementById('bookingRoomTypeFilter').selectedIndex = 0;
            // Reset room filter to show all rooms
            const roomSelect = document.getElementById('customerBookingRoom');
            roomSelect.querySelectorAll('option').forEach(o => o.style.display = '');
            roomSelect.selectedIndex = 0;
            document.getElementById('customerCheckIn').value = '';
            document.getElementById('customerCheckOut').value = '';
            document.getElementById('customerNumGuests').value = 1;
            document.getElementById('customerBookingTotal').value = 'Rs. 0.00';
            document.getElementById('customerSpecialReqs').value = '';
            openModal('bookRoomForCustomerModal');
        }
        
        function updateBookingTotal() {
            const roomSelect = document.getElementById('customerBookingRoom');
            const checkIn = document.getElementById('customerCheckIn').value;
            const checkOut = document.getElementById('customerCheckOut').value;
            
            if (roomSelect.value && checkIn && checkOut) {
                const rate = parseFloat(roomSelect.options[roomSelect.selectedIndex].dataset.rate) || 0;
                const nights = Math.ceil((new Date(checkOut) - new Date(checkIn)) / (1000 * 60 * 60 * 24));
                if (nights > 0) {
                    const total = rate * nights;
                    document.getElementById('customerBookingTotal').value = 'Rs. ' + total.toLocaleString('en-US', {minimumFractionDigits: 2, maximumFractionDigits: 2});
                } else {
                    document.getElementById('customerBookingTotal').value = 'Rs. 0.00';
                }
            }
        }
        
        function createBookingForCustomer(e) {
            e.preventDefault();
            const formData = new FormData(document.getElementById('bookRoomForCustomerForm'));
            const customerName = document.getElementById('bookingCustomerName').textContent;
            const roomSelect = document.getElementById('customerBookingRoom');
            const selectedRoom = roomSelect.options[roomSelect.selectedIndex].text;
            const totalAmount = document.getElementById('customerBookingTotal').value;
            const checkIn = document.getElementById('customerCheckIn').value;
            const checkOut = document.getElementById('customerCheckOut').value;
            formData.append('action', 'addReservation');
            
            Swal.fire({
                title: '<i class="fas fa-calendar-check" style="color: #10b981;"></i> Confirm Booking?',
                html: '<div style="text-align: left; padding: 10px 0;">' +
                      '<p><strong>Customer:</strong> ' + customerName + '</p>' +
                      '<p><strong>Room:</strong> ' + selectedRoom.split(' - ')[0] + '</p>' +
                      '<p><strong>Check-in:</strong> ' + checkIn + '</p>' +
                      '<p><strong>Check-out:</strong> ' + checkOut + '</p>' +
                      '<p style="font-size: 18px; color: #10b981; margin-top: 10px;"><strong>Total: ' + totalAmount + '</strong></p>' +
                      '</div>',
                icon: 'question',
                showCancelButton: true,
                confirmButtonColor: '#10b981',
                cancelButtonColor: '#6c757d',
                confirmButtonText: '<i class="fas fa-check"></i> Yes, Create Booking',
                cancelButtonText: '<i class="fas fa-times"></i> Cancel'
            }).then((result) => {
                if (result.isConfirmed) {
                    fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp', { method: 'POST', body: formData })
                    .then(r => r.json())
                    .then(data => {
                        if (data.success) {
                            Swal.fire({
                                icon: 'success',
                                title: '<i class="fas fa-check-circle" style="color: #10b981;"></i> Booking Successful!',
                                html: '<div style="text-align: center;">' +
                                      '<p style="font-size: 18px; margin-bottom: 10px;">Booking created for:</p>' +
                                      '<h3 style="color: var(--primary); margin: 10px 0;">' + customerName + '</h3>' +
                                      '<p style="background: #ecfdf5; padding: 10px 15px; border-radius: 8px; display: inline-block; color: #10b981; font-weight: 600;">' + totalAmount + '</p>' +
                                      '<p style="color: #666; margin-top: 15px;">Would you like to proceed to payments?</p>' +
                                      '</div>',
                                showCancelButton: true,
                                showDenyButton: true,
                                confirmButtonText: '<i class="fas fa-credit-card"></i> Go to Payments',
                                denyButtonText: '<i class="fas fa-calendar"></i> View Reservations',
                                cancelButtonText: '<i class="fas fa-users"></i> Back to Customers',
                                confirmButtonColor: '#10b981',
                                denyButtonColor: '#3b82f6',
                                cancelButtonColor: '#6c757d'
                            }).then((result) => {
                                closeModal('bookRoomForCustomerModal');
                                if (result.isConfirmed) {
                                    showSection('payments');
                                    location.reload();
                                } else if (result.isDenied) {
                                    showSection('reservations');
                                    location.reload();
                                } else {
                                    location.reload();
                                }
                            });
                        } else {
                            Swal.fire({icon: 'error', title: 'Booking Failed', text: data.message || 'Could not create booking. Please try again.'});
                        }
                    })
                    .catch(err => Swal.fire({icon: 'error', title: 'Error', text: 'Something went wrong. Please try again.'}));
                }
            });
            return false;
        }
        
        // Filter rooms by type
        function filterRoomsByType() {
            const filter = document.getElementById('bookingRoomTypeFilter').value;
            const roomSelect = document.getElementById('customerBookingRoom');
            const options = roomSelect.querySelectorAll('option');
            
            options.forEach((option, index) => {
                if (index === 0) return; // Skip placeholder
                const roomType = option.getAttribute('data-type') || '';
                option.style.display = (!filter || roomType === filter) ? '' : 'none';
            });
            
            // Reset room selection
            roomSelect.selectedIndex = 0;
            document.getElementById('customerBookingTotal').value = 'Rs. 0.00';
        }
        
        // Update checkout min date
        function updateCheckoutMin() {
            const checkIn = document.getElementById('customerCheckIn').value;
            if (checkIn) {
                const nextDay = new Date(checkIn);
                nextDay.setDate(nextDay.getDate() + 1);
                document.getElementById('customerCheckOut').min = nextDay.toISOString().split('T')[0];
            }
        }
        
        // Filter room cards in room selection section
        function filterRoomCards() {
            const typeFilter = document.getElementById('roomTypeFilterSelect').value;
            const floorFilter = document.getElementById('floorFilterSelect').value;
            const cards = document.querySelectorAll('#roomCardsGrid .room-card');
            let visibleCount = 0;
            
            cards.forEach(card => {
                const cardType = card.getAttribute('data-type') || '';
                const cardFloor = card.getAttribute('data-floor') || '';
                const typeMatch = !typeFilter || cardType === typeFilter;
                const floorMatch = !floorFilter || cardFloor === floorFilter;
                
                if (typeMatch && floorMatch) {
                    card.style.display = '';
                    visibleCount++;
                } else {
                    card.style.display = 'none';
                }
            });
            
            // Update count display
            const countDisplay = document.getElementById('roomCountDisplay');
            if (visibleCount === 0) {
                countDisplay.textContent = 'No rooms match filters';
                document.getElementById('noRoomsMessage').style.display = 'block';
            } else {
                countDisplay.textContent = 'Showing ' + visibleCount + ' room' + (visibleCount !== 1 ? 's' : '');
                document.getElementById('noRoomsMessage').style.display = 'none';
            }
        }
        
        // Book room from room selection cards
        function bookRoomFromSelection(roomId, roomName, rate) {
            const customerId = document.getElementById('selectedCustomerId').value;
            const customerName = document.getElementById('selectedCustomerName').value;
            
            if (!customerId || !customerName) {
                Swal.fire({
                    icon: 'warning',
                    title: 'No Customer Selected',
                    text: 'Please register or select a customer first.',
                    confirmButtonColor: '#008080',
                    confirmButtonText: 'Go to Customers'
                }).then(() => {
                    showSection('customers');
                });
                return;
            }
            
            // Set customer info
            document.getElementById('bookingCustomerId').value = customerId;
            document.getElementById('bookingCustomerName').textContent = customerName;
            
            // Set room selection
            const roomSelect = document.getElementById('customerBookingRoom');
            for (let i = 0; i < roomSelect.options.length; i++) {
                if (roomSelect.options[i].value == roomId) {
                    roomSelect.selectedIndex = i;
                    break;
                }
            }
            
            // Reset dates and calculate
            document.getElementById('customerCheckIn').value = '';
            document.getElementById('customerCheckOut').value = '';
            document.getElementById('customerNumGuests').value = 1;
            document.getElementById('customerBookingTotal').value = 'Rs. 0.00';
            document.getElementById('customerSpecialReqs').value = '';
            
            // Open booking modal
            openModal('bookRoomForCustomerModal');
        }
        
        function filterCustomersByNationality() {
            const filter = document.getElementById('nationalityFilter').value.toLowerCase();
            const rows = document.querySelectorAll('#customers .data-table tbody tr');
            rows.forEach(row => {
                const nationality = row.getAttribute('data-nationality')?.toLowerCase() || '';
                row.style.display = (!filter || nationality === filter) ? '' : 'none';
            });
        }
        
        // Legacy aliases for backward compatibility
        function viewCustomer(id) { viewCustomerDetails(id); }
        function editCustomer(id) { editCustomerDetails(id); }
        
        function viewReservation(id) { 
            window.location.href = '${pageContext.request.contextPath}/admin/admin-payment.jsp?reservationId=' + id; 
        }
        function editReservation(id) { 
            Swal.fire({
                title: 'Edit Reservation Status',
                html: '<select id="newStatus" class="swal2-input" style="width:auto;padding:10px;"><option value="CONFIRMED">Confirmed</option><option value="CHECKED_IN">Checked In</option><option value="CHECKED_OUT">Checked Out</option><option value="CANCELLED">Cancelled</option></select>',
                showCancelButton: true,
                confirmButtonText: 'Update',
                confirmButtonColor: '#008080'
            }).then((result) => {
                if (result.isConfirmed) {
                    const newStatus = document.getElementById('newStatus').value;
                    fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp', {
                        method: 'POST',
                        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                        body: 'action=updateReservationStatus&reservationId=' + id + '&status=' + newStatus
                    }).then(r => r.json()).then(data => {
                        if (data.success) {
                            Swal.fire({icon: 'success', title: 'Updated!', text: 'Reservation status updated.', confirmButtonColor: '#008080'}).then(() => location.reload());
                        } else {
                            Swal.fire({icon: 'error', title: 'Error', text: data.message, confirmButtonColor: '#008080'});
                        }
                    });
                }
            });
        }
        function viewBill(id) { window.open('${pageContext.request.contextPath}/admin/admin-invoice.jsp?billId=' + id, '_blank'); }
        
        function editPayment(id, currentStatus, currentMethod) {
            var statusOptions = '';
            var statuses = ['PENDING', 'PAID', 'PARTIAL'];
            var statusLabels = ['Pending', 'Paid', 'Partial'];
            for (var i = 0; i < statuses.length; i++) {
                statusOptions += '<option value="' + statuses[i] + '"' + (currentStatus === statuses[i] ? ' selected' : '') + '>' + statusLabels[i] + '</option>';
            }
            
            var methodOptions = '<option value=""' + (!currentMethod ? ' selected' : '') + '>-- Select Method --</option>';
            var methods = ['CASH', 'CARD', 'BANK_TRANSFER', 'ONLINE'];
            var methodLabels = ['Cash', 'Card', 'Bank Transfer', 'Online'];
            for (var i = 0; i < methods.length; i++) {
                methodOptions += '<option value="' + methods[i] + '"' + (currentMethod === methods[i] ? ' selected' : '') + '>' + methodLabels[i] + '</option>';
            }
            
            Swal.fire({
                title: '<i class="fas fa-edit"></i> Edit Payment',
                html: '<div style="text-align: left; padding: 10px 0;">' +
                    '<label style="display: block; margin-bottom: 5px; font-weight: 500;">Payment Status:</label>' +
                    '<select id="paymentStatusEdit" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px; margin-bottom: 15px;">' + statusOptions + '</select>' +
                    '<label style="display: block; margin-bottom: 5px; font-weight: 500;">Payment Method:</label>' +
                    '<select id="paymentMethodEdit" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;">' + methodOptions + '</select>' +
                    '</div>',
                showCancelButton: true,
                confirmButtonColor: '#008080',
                cancelButtonColor: '#6c757d',
                confirmButtonText: '<i class="fas fa-save"></i> Update Payment',
                cancelButtonText: 'Cancel',
                preConfirm: () => {
                    return {
                        status: document.getElementById('paymentStatusEdit').value,
                        method: document.getElementById('paymentMethodEdit').value
                    };
                }
            }).then((result) => {
                if (result.isConfirmed) {
                    const formData = new FormData();
                    formData.append('action', 'updatePayment');
                    formData.append('billId', id);
                    formData.append('paymentStatus', result.value.status);
                    formData.append('paymentMethod', result.value.method);
                    
                    fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp', {
                        method: 'POST',
                        body: formData
                    })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            Swal.fire({
                                icon: 'success',
                                title: 'Payment Updated!',
                                text: 'Payment has been successfully updated.',
                                confirmButtonColor: '#008080'
                            }).then(() => location.reload());
                        } else {
                            Swal.fire('Error', data.message || 'Failed to update payment', 'error');
                        }
                    })
                    .catch(error => {
                        Swal.fire('Error', 'Failed to update payment', 'error');
                    });
                }
            });
        }
        
        function printBill(id) { window.open('${pageContext.request.contextPath}/admin/admin-invoice.jsp?billId=' + id, '_blank'); }
        function printInvoice(id) { window.open('${pageContext.request.contextPath}/admin/admin-invoice.jsp?reservationId=' + id, '_blank'); }
        function viewInvoice(id) { window.open('${pageContext.request.contextPath}/admin/admin-invoice.jsp?billId=' + id, '_blank'); }
        function downloadInvoiceSummary() {
            var selectedDateInput = document.getElementById('invoiceDate');
            var selectedDate = selectedDateInput ? selectedDateInput.value : '';
            var reportUrl = '${pageContext.request.contextPath}/admin/generate-daily-report.jsp';
            if (selectedDate) {
                reportUrl += '?date=' + encodeURIComponent(selectedDate);
            }
            window.location.href = reportUrl;
        }
        
        // Report tab switching
        function showReportTab(period) {
            // Hide all report contents
            document.querySelectorAll('.report-content').forEach(el => el.style.display = 'none');
            
            // Remove active class from all tabs
            document.querySelectorAll('.report-tab').forEach(el => {
                el.style.background = '#e0e0e0';
                el.style.color = '#333';
            });
            
            // Show selected report
            var reportId = 'reportDaily';
            var tabId = 'tabDaily';
            if (period === 'weekly') { reportId = 'reportWeekly'; tabId = 'tabWeekly'; }
            else if (period === 'monthly') { reportId = 'reportMonthly'; tabId = 'tabMonthly'; }
            
            document.getElementById(reportId).style.display = 'block';
            document.getElementById(tabId).style.background = '#008080';
            document.getElementById(tabId).style.color = 'white';
        }
        
        function downloadReport() {
            var activeTab = document.querySelector('.report-content[style*="display: block"], .report-content:not([style*="display: none"])');
            if (activeTab) {
                var period = 'weekly';
                if (activeTab.id === 'reportDaily') period = 'daily';
                else if (activeTab.id === 'reportMonthly') period = 'monthly';
                window.location.href = '${pageContext.request.contextPath}/admin/generate-report.jsp?period=' + period;
            } else {
                window.location.href = '${pageContext.request.contextPath}/admin/generate-report.jsp?period=weekly';
            }
        }
        
        function printReport() {
            var activeTab = document.querySelector('.report-content[style*="display: block"], .report-content:not([style*="display: none"])');
            if (activeTab) {
                var printContent = activeTab.innerHTML;
                var printWindow = window.open('', '_blank');
                printWindow.document.write('<html><head><title>Report - Ocean View Resort</title>');
                printWindow.document.write('<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">');
                printWindow.document.write('<style>body{font-family:Poppins,sans-serif;padding:20px;} .card{border:1px solid #ddd;border-radius:10px;margin-bottom:20px;} .card-header{background:#008080;color:white;padding:15px;border-radius:10px 10px 0 0;} .card-body{padding:20px;} .stats-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:15px;} .stat-card{background:#f8f9fa;padding:15px;border-radius:8px;text-align:center;} .data-table{width:100%;border-collapse:collapse;} .data-table th,.data-table td{padding:10px;border:1px solid #ddd;text-align:left;} .data-table th{background:#008080;color:white;} .charts-grid{display:none;}</style>');
                printWindow.document.write('</head><body>');
                printWindow.document.write('<h1 style="color:#008080;text-align:center;">Ocean View Resort</h1>');
                printWindow.document.write(printContent);
                printWindow.document.write('</body></html>');
                printWindow.document.close();
                printWindow.print();
            }
        }
        
        function loadInvoicesByDate() { 
            var selectedDate = document.getElementById('invoiceDate').value;
            location.href = '${pageContext.request.contextPath}/admin/admin-dashboard.jsp?invoiceDate=' + selectedDate + '#invoices';
        }
        
        function showAllInvoices() {
            location.href = '${pageContext.request.contextPath}/admin/admin-dashboard.jsp#invoices';
        }
        
        // Profile picture upload
        function uploadProfilePic(input) {
            if (input.files && input.files[0]) {
                const fd = new FormData();
                fd.append('action', 'uploadProfilePic');
                fd.append('profilePic', input.files[0]);
                fetch('${pageContext.request.contextPath}/admin/admin-actions.jsp', { method: 'POST', body: fd })
                .then(r => r.json())
                .then(data => { if (data.success) location.reload(); else Swal.fire({icon: 'error', title: 'Error', text: data.message}); });
            }
        }
        
        // Charts with real data
        const revenueCtx = document.getElementById('revenueChart')?.getContext('2d');
        if (revenueCtx) {
            new Chart(revenueCtx, {
                type: 'line',
                data: { 
                    labels: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'], 
                    datasets: [{ 
                        label: 'Revenue (Rs.)', 
                        data: [<%= weeklyRevenue[0] %>, <%= weeklyRevenue[1] %>, <%= weeklyRevenue[2] %>, <%= weeklyRevenue[3] %>, <%= weeklyRevenue[4] %>, <%= weeklyRevenue[5] %>, <%= weeklyRevenue[6] %>], 
                        borderColor: '#008080', 
                        backgroundColor: 'rgba(0,128,128,0.15)', 
                        fill: true, 
                        tension: 0.4,
                        pointRadius: 6,
                        pointBackgroundColor: '#008080',
                        pointBorderColor: '#fff',
                        pointBorderWidth: 2
                    }] 
                },
                options: { 
                    responsive: true, 
                    maintainAspectRatio: false,
                    plugins: { legend: { display: true, position: 'top' } },
                    scales: {
                        y: { beginAtZero: true, ticks: { callback: function(value) { return 'Rs. ' + value.toLocaleString(); } } }
                    }
                }
            });
        }
        
        const roomStatusCtx = document.getElementById('roomStatusChart')?.getContext('2d');
        if (roomStatusCtx) {
            new Chart(roomStatusCtx, {
                type: 'doughnut',
                data: { 
                    labels: ['Available', 'Occupied', 'Maintenance', 'Reserved'], 
                    datasets: [{ 
                        data: [<%= availableRooms %>, <%= occupiedRooms %>, <%= maintenanceRooms %>, <%= reservedRooms %>], 
                        backgroundColor: ['#28a745', '#17a2b8', '#ffc107', '#667eea'],
                        borderWidth: 2,
                        borderColor: '#fff'
                    }] 
                },
                options: { 
                    responsive: true, 
                    maintainAspectRatio: false,
                    plugins: { 
                        legend: { position: 'bottom', labels: { padding: 15, font: { size: 12 } } }
                    },
                    cutout: '60%'
                }
            });
        }

        const summaryCompareCtx = document.getElementById('summaryCompareChart')?.getContext('2d');
        if (summaryCompareCtx) {
            new Chart(summaryCompareCtx, {
                type: 'bar',
                data: {
                    labels: ['Daily', 'Weekly', 'Monthly'],
                    datasets: [{
                        type: 'bar',
                        label: 'Revenue (Rs.)',
                        data: [<%= todayRevenue %>, <%= weeklyRevenue4 %>, <%= monthlyRevenue %>],
                        backgroundColor: ['rgba(0,128,128,0.7)', 'rgba(102,126,234,0.7)', 'rgba(67,233,123,0.7)'],
                        borderRadius: 8,
                        yAxisID: 'yRevenue'
                    }, {
                        type: 'line',
                        label: 'Bookings',
                        data: [<%= dailyBookings %>, <%= weeklyBookings %>, <%= monthlyBookings %>],
                        borderColor: '#f5576c',
                        backgroundColor: 'rgba(245,87,108,0.1)',
                        fill: false,
                        tension: 0.35,
                        pointRadius: 5,
                        yAxisID: 'yCounts'
                    }, {
                        type: 'line',
                        label: 'New Guests',
                        data: [<%= dailyGuests %>, <%= weeklyGuests %>, <%= monthlyGuests %>],
                        borderColor: '#ff9800',
                        backgroundColor: 'rgba(255,152,0,0.1)',
                        fill: false,
                        tension: 0.35,
                        pointRadius: 5,
                        yAxisID: 'yCounts'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'top' }
                    },
                    scales: {
                        yRevenue: {
                            beginAtZero: true,
                            position: 'left',
                            ticks: {
                                callback: function(value) { return 'Rs. ' + Number(value).toLocaleString(); }
                            }
                        },
                        yCounts: {
                            beginAtZero: true,
                            position: 'right',
                            grid: { drawOnChartArea: false },
                            ticks: { stepSize: 1 }
                        }
                    }
                }
            });
        }
        
        // Weekly Report Charts
        const weeklyRevenueCtx = document.getElementById('weeklyRevenueChart')?.getContext('2d');
        if (weeklyRevenueCtx) {
            new Chart(weeklyRevenueCtx, {
                type: 'bar',
                data: { 
                    labels: [<% for (int i = 0; i < 7; i++) { if (i > 0) out.print(","); out.print("'" + dailyLabels[i] + "'"); } %>], 
                    datasets: [{ 
                        label: 'Revenue (Rs.)', 
                        data: [<% for (int i = 0; i < 7; i++) { if (i > 0) out.print(","); out.print(dailyRevenueData[i]); } %>], 
                        backgroundColor: 'rgba(0,128,128,0.7)',
                        borderColor: '#008080',
                        borderWidth: 2,
                        borderRadius: 8
                    }] 
                },
                options: { 
                    responsive: true, 
                    maintainAspectRatio: false, 
                    plugins: { legend: { display: false } },
                    scales: { y: { beginAtZero: true } }
                }
            });
        }
        
        const weeklyBookingsCtx = document.getElementById('weeklyBookingsChart')?.getContext('2d');
        if (weeklyBookingsCtx) {
            new Chart(weeklyBookingsCtx, {
                type: 'line',
                data: { 
                    labels: [<% for (int i = 0; i < 7; i++) { if (i > 0) out.print(","); out.print("'" + dailyLabels[i] + "'"); } %>], 
                    datasets: [{ 
                        label: 'Bookings', 
                        data: [<% for (int i = 0; i < 7; i++) { if (i > 0) out.print(","); out.print(dailyBookingsData[i]); } %>], 
                        borderColor: '#667eea',
                        backgroundColor: 'rgba(102,126,234,0.1)',
                        fill: true,
                        tension: 0.4,
                        pointRadius: 6,
                        pointBackgroundColor: '#667eea'
                    }] 
                },
                options: { 
                    responsive: true, 
                    maintainAspectRatio: false, 
                    plugins: { legend: { display: false } },
                    scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }
                }
            });
        }
        
        // Monthly Report Charts
        const revenueTrendCtx = document.getElementById('revenueTrendChart')?.getContext('2d');
        if (revenueTrendCtx) {
            new Chart(revenueTrendCtx, {
                type: 'bar',
                data: { 
                    labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'], 
                    datasets: [{ 
                        label: 'Revenue', 
                        data: [<%= monthlyRevenue * 0.2 %>, <%= monthlyRevenue * 0.25 %>, <%= monthlyRevenue * 0.3 %>, <%= monthlyRevenue * 0.25 %>], 
                        backgroundColor: ['rgba(0,128,128,0.7)', 'rgba(0,128,128,0.8)', 'rgba(0,128,128,0.9)', 'rgba(0,128,128,1)'],
                        borderRadius: 8 
                    }] 
                },
                options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }
            });
        }
        
        const bookingTypeCtx = document.getElementById('bookingsByTypeChart')?.getContext('2d');
        if (bookingTypeCtx) {
            new Chart(bookingTypeCtx, {
                type: 'bar',
                data: { 
                    labels: [<% int idx = 0; for (String typeName : roomTypeBookings.keySet()) { if (idx > 0) out.print(","); out.print("'" + typeName + "'"); idx++; } %>], 
                    datasets: [{ 
                        label: 'Bookings', 
                        data: [<% idx = 0; for (Integer cnt : roomTypeBookings.values()) { if (idx > 0) out.print(","); out.print(cnt); idx++; } %>], 
                        backgroundColor: ['#667eea', '#f5576c', '#43e97b', '#fa709a', '#4facfe', '#00c6fb', '#ff6b6b'],
                        borderRadius: 8
                    }] 
                },
                options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, indexAxis: 'y' }
            });
        }
        
        const occupancyCtx = document.getElementById('occupancyChart')?.getContext('2d');
        if (occupancyCtx) {
            const occupancyRate = <%= totalRooms > 0 ? (occupiedRooms * 100 / totalRooms) : 0 %>;
            new Chart(occupancyCtx, {
                type: 'line',
                data: { 
                    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'], 
                    datasets: [{ 
                        label: 'Occupancy %', 
                        data: [Math.max(occupancyRate - 15, 0), Math.max(occupancyRate - 10, 0), Math.max(occupancyRate - 5, 0), occupancyRate, Math.min(occupancyRate + 5, 100), Math.min(occupancyRate + 8, 100)], 
                        borderColor: '#f5576c', 
                        backgroundColor: 'rgba(245,87,108,0.1)', 
                        fill: true, 
                        tension: 0.4, 
                        pointRadius: 5 
                    }] 
                },
                options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { max: 100, min: 0 } } }
            });
        }
        
        const paymentCtx = document.getElementById('paymentMethodsChart')?.getContext('2d');
        if (paymentCtx) {
            new Chart(paymentCtx, {
                type: 'doughnut',
                data: { 
                    labels: ['Cash', 'Card', 'Bank Transfer', 'Online'], 
                    datasets: [{ 
                        data: [<%= cashPayments %>, <%= cardPayments %>, <%= bankPayments %>, <%= onlinePayments %>], 
                        backgroundColor: ['#28a745', '#667eea', '#ffc107', '#17a2b8'], 
                        borderWidth: 2, 
                        borderColor: '#fff' 
                    }] 
                },
                options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom' } } }
            });
        }
        
        // Auto-scroll to invoices section if invoiceDate parameter is present
        (function() {
            var urlParams = new URLSearchParams(window.location.search);
            if (urlParams.has('invoiceDate') || window.location.hash === '#invoices') {
                setTimeout(function() {
                    // Use the existing showSection function to properly display invoices
                    showSection('invoices');
                    // Scroll to invoices section
                    var invoicesSection = document.getElementById('invoices');
                    if (invoicesSection) {
                        invoicesSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
                    }
                }, 150);
            }
        })();
    </script>
    
    <% if (conn != null) { try { conn.close(); } catch (Exception e) {} } %>
</body>
</html>
