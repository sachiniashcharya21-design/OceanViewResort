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
    
    // Daily stats
    double todayRevenue = 0;
    int todayBills = 0, todayCheckIns = 0, todayCheckOuts = 0;
    int availableRooms = 0, occupiedRooms = 0, totalRooms = 0;
    int dailyBookings = 0, dailyGuests = 0;
    
    // Weekly stats
    double weeklyRevenue = 0;
    int weeklyBills = 0, weeklyCheckIns = 0, weeklyCheckOuts = 0;
    int weeklyBookings = 0, weeklyGuests = 0;
    
    // Monthly stats
    double monthlyRevenue = 0;
    int monthlyBills = 0, monthlyCheckIns = 0, monthlyCheckOuts = 0;
    int monthlyBookings = 0, monthlyGuests = 0;
    
    // Search parameters
    String searchBillNo = request.getParameter("billNo");
    String searchGuest = request.getParameter("guestName");
    String searchDateFrom = request.getParameter("dateFrom");
    String searchDateTo = request.getParameter("dateTo");
    String searchStatus = request.getParameter("paymentStatus");
    boolean hasSearch = (searchBillNo != null && !searchBillNo.isEmpty()) ||
                        (searchGuest != null && !searchGuest.isEmpty()) ||
                        (searchDateFrom != null && !searchDateFrom.isEmpty()) ||
                        (searchDateTo != null && !searchDateTo.isEmpty()) ||
                        (searchStatus != null && !searchStatus.isEmpty());
    
    List<Map<String, String>> searchResults = new ArrayList<>();
    double searchTotalAmount = 0;
    int searchResultCount = 0;
    
    // Chart data arrays - declared outside try block
    double[] dailyRevenueData = new double[7];
    String[] dailyLabels = new String[7];
    int[] dailyBookingsData = new int[7];
    int[] checkInsData = new int[7];
    int[] checkOutsData = new int[7];
    int maintenanceRooms = 0, reservedRooms = 0;
    List<Map<String, String>> staffList = new ArrayList<>();
    
    // Initialize labels with defaults
    SimpleDateFormat dayFmt = new SimpleDateFormat("MMM dd");
    for (int i = 6; i >= 0; i--) {
        java.util.Calendar cal = java.util.Calendar.getInstance();
        cal.add(java.util.Calendar.DAY_OF_MONTH, -i);
        dailyLabels[6-i] = dayFmt.format(cal.getTime());
    }
    
    DecimalFormat df = new DecimalFormat("#,###.00");
    SimpleDateFormat sdf = new SimpleDateFormat("MMMM dd, yyyy");
    String today = sdf.format(new java.util.Date());
    String todayDate = new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        // Get user profile picture
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
        
        // ===== DAILY STATS =====
        rs = stmt.executeQuery("SELECT IFNULL(SUM(total_amount), 0) as total, COUNT(*) as cnt FROM bills WHERE DATE(generated_at) = CURDATE() AND payment_status = 'PAID'");
        if (rs.next()) { todayRevenue = rs.getDouble("total"); todayBills = rs.getInt("cnt"); }
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE check_in_date = CURDATE() AND status IN ('CONFIRMED', 'CHECKED_IN')");
        if (rs.next()) todayCheckIns = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE check_out_date = CURDATE()");
        if (rs.next()) todayCheckOuts = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE DATE(created_at) = CURDATE()");
        if (rs.next()) dailyBookings = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM guests WHERE DATE(created_at) = CURDATE()");
        if (rs.next()) dailyGuests = rs.getInt(1);
        rs.close();
        
        // ===== WEEKLY STATS =====
        rs = stmt.executeQuery("SELECT IFNULL(SUM(total_amount), 0) as total, COUNT(*) as cnt FROM bills WHERE YEARWEEK(generated_at) = YEARWEEK(CURDATE()) AND payment_status = 'PAID'");
        if (rs.next()) { weeklyRevenue = rs.getDouble("total"); weeklyBills = rs.getInt("cnt"); }
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE YEARWEEK(check_in_date) = YEARWEEK(CURDATE()) AND status IN ('CONFIRMED', 'CHECKED_IN', 'CHECKED_OUT')");
        if (rs.next()) weeklyCheckIns = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE YEARWEEK(check_out_date) = YEARWEEK(CURDATE()) AND status = 'CHECKED_OUT'");
        if (rs.next()) weeklyCheckOuts = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE YEARWEEK(created_at) = YEARWEEK(CURDATE())");
        if (rs.next()) weeklyBookings = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM guests WHERE YEARWEEK(created_at) = YEARWEEK(CURDATE())");
        if (rs.next()) weeklyGuests = rs.getInt(1);
        rs.close();
        
        // ===== MONTHLY STATS =====
        rs = stmt.executeQuery("SELECT IFNULL(SUM(total_amount), 0) as total, COUNT(*) as cnt FROM bills WHERE MONTH(generated_at) = MONTH(CURDATE()) AND YEAR(generated_at) = YEAR(CURDATE()) AND payment_status = 'PAID'");
        if (rs.next()) { monthlyRevenue = rs.getDouble("total"); monthlyBills = rs.getInt("cnt"); }
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE MONTH(check_in_date) = MONTH(CURDATE()) AND YEAR(check_in_date) = YEAR(CURDATE()) AND status IN ('CONFIRMED','CHECKED_IN','CHECKED_OUT')");
        if (rs.next()) monthlyCheckIns = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE MONTH(check_out_date) = MONTH(CURDATE()) AND YEAR(check_out_date) = YEAR(CURDATE()) AND status = 'CHECKED_OUT'");
        if (rs.next()) monthlyCheckOuts = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE())");
        if (rs.next()) monthlyBookings = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM guests WHERE MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE())");
        if (rs.next()) monthlyGuests = rs.getInt(1);
        rs.close();
        
        // ===== CHART DATA =====
        // Daily Revenue (last 7 days) - populate arrays
        rs = stmt.executeQuery(
            "SELECT DATE(paid_at) as pay_date, SUM(total_amount) as total " +
            "FROM bills WHERE paid_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) AND payment_status = 'PAID' " +
            "GROUP BY DATE(paid_at) ORDER BY pay_date"
        );
        while (rs.next()) {
            java.sql.Date payDate = rs.getDate("pay_date");
            String dateStr = dayFmt.format(payDate);
            for (int i = 0; i < 7; i++) {
                if (dailyLabels[i].equals(dateStr)) {
                    dailyRevenueData[i] = rs.getDouble("total");
                    break;
                }
            }
        }
        rs.close();
        
        // Daily Bookings (last 7 days)
        rs = stmt.executeQuery(
            "SELECT DATE(created_at) as book_date, COUNT(*) as cnt " +
            "FROM reservations WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) " +
            "GROUP BY DATE(created_at) ORDER BY book_date"
        );
        while (rs.next()) {
            java.sql.Date bookDate = rs.getDate("book_date");
            String dateStr = dayFmt.format(bookDate);
            for (int i = 0; i < 7; i++) {
                if (dailyLabels[i].equals(dateStr)) {
                    dailyBookingsData[i] = rs.getInt("cnt");
                    break;
                }
            }
        }
        rs.close();
        
        // Check-ins and Check-outs (last 7 days)
        rs = stmt.executeQuery(
            "SELECT DATE(check_in_date) as ci_date, COUNT(*) as cnt " +
            "FROM reservations WHERE check_in_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) " +
            "AND status IN ('CONFIRMED', 'CHECKED_IN', 'CHECKED_OUT') " +
            "GROUP BY DATE(check_in_date) ORDER BY ci_date"
        );
        while (rs.next()) {
            java.sql.Date ciDate = rs.getDate("ci_date");
            String dateStr = dayFmt.format(ciDate);
            for (int i = 0; i < 7; i++) {
                if (dailyLabels[i].equals(dateStr)) {
                    checkInsData[i] = rs.getInt("cnt");
                    break;
                }
            }
        }
        rs.close();
        
        rs = stmt.executeQuery(
            "SELECT DATE(check_out_date) as co_date, COUNT(*) as cnt " +
            "FROM reservations WHERE check_out_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) " +
            "AND status = 'CHECKED_OUT' " +
            "GROUP BY DATE(check_out_date) ORDER BY co_date"
        );
        while (rs.next()) {
            java.sql.Date coDate = rs.getDate("co_date");
            String dateStr = dayFmt.format(coDate);
            for (int i = 0; i < 7; i++) {
                if (dailyLabels[i].equals(dateStr)) {
                    checkOutsData[i] = rs.getInt("cnt");
                    break;
                }
            }
        }
        rs.close();
        
        // Room status for pie chart
        rs = stmt.executeQuery("SELECT COUNT(*) FROM rooms WHERE status = 'MAINTENANCE'");
        if (rs.next()) maintenanceRooms = rs.getInt(1);
        rs.close();
        rs = stmt.executeQuery("SELECT COUNT(*) FROM rooms WHERE status = 'RESERVED'");
        if (rs.next()) reservedRooms = rs.getInt(1);
        rs.close();
        
        // Staff members list - populate existing list
        rs = stmt.executeQuery(
            "SELECT user_id, username, full_name, email, phone, profile_picture, hire_date, status " +
            "FROM users WHERE role = 'STAFF' AND status = 'ACTIVE' ORDER BY full_name"
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
            staffList.add(staff);
        }
        rs.close();
        
        // Search functionality
        if (hasSearch) {
            StringBuilder sql = new StringBuilder(
                "SELECT b.bill_id, b.bill_number, b.total_amount, b.payment_status, b.payment_method, b.generated_at, " +
                "g.full_name, g.email, g.phone, rm.room_number, rt.type_name, r.check_in_date, r.check_out_date " +
                "FROM bills b " +
                "JOIN reservations r ON b.reservation_id = r.reservation_id " +
                "JOIN guests g ON r.guest_id = g.guest_id " +
                "JOIN rooms rm ON r.room_id = rm.room_id " +
                "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
                "WHERE 1=1 "
            );
            
            List<Object> params = new ArrayList<>();
            
            if (searchBillNo != null && !searchBillNo.isEmpty()) {
                sql.append("AND b.bill_number LIKE ? ");
                params.add("%" + searchBillNo + "%");
            }
            if (searchGuest != null && !searchGuest.isEmpty()) {
                sql.append("AND (g.full_name LIKE ? OR g.email LIKE ? OR g.phone LIKE ?) ");
                params.add("%" + searchGuest + "%");
                params.add("%" + searchGuest + "%");
                params.add("%" + searchGuest + "%");
            }
            if (searchDateFrom != null && !searchDateFrom.isEmpty()) {
                sql.append("AND DATE(b.generated_at) >= ? ");
                params.add(searchDateFrom);
            }
            if (searchDateTo != null && !searchDateTo.isEmpty()) {
                sql.append("AND DATE(b.generated_at) <= ? ");
                params.add(searchDateTo);
            }
            if (searchStatus != null && !searchStatus.isEmpty()) {
                sql.append("AND b.payment_status = ? ");
                params.add(searchStatus);
            }
            
            sql.append("ORDER BY b.generated_at DESC LIMIT 100");
            
            PreparedStatement psSearch = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                psSearch.setObject(i + 1, params.get(i));
            }
            
            ResultSet rsSearch = psSearch.executeQuery();
            while (rsSearch.next()) {
                Map<String, String> row = new HashMap<>();
                row.put("bill_id", String.valueOf(rsSearch.getInt("bill_id")));
                row.put("bill_number", rsSearch.getString("bill_number"));
                row.put("guest_name", rsSearch.getString("full_name"));
                row.put("email", rsSearch.getString("email"));
                row.put("phone", rsSearch.getString("phone") != null ? rsSearch.getString("phone") : "");
                row.put("room_number", rsSearch.getString("room_number"));
                row.put("room_type", rsSearch.getString("type_name"));
                row.put("total_amount", df.format(rsSearch.getDouble("total_amount")));
                row.put("payment_status", rsSearch.getString("payment_status"));
                row.put("payment_method", rsSearch.getString("payment_method") != null ? rsSearch.getString("payment_method") : "N/A");
                Timestamp genAt = rsSearch.getTimestamp("generated_at");
                row.put("date", genAt != null ? new SimpleDateFormat("yyyy-MM-dd HH:mm").format(genAt) : "");
                row.put("check_in", rsSearch.getString("check_in_date"));
                row.put("check_out", rsSearch.getString("check_out_date"));
                
                searchTotalAmount += rsSearch.getDouble("total_amount");
                searchResults.add(row);
                searchResultCount++;
            }
            rsSearch.close();
            psSearch.close();
        }
        
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
    <title>Reports - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
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
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
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
        
        .stat-icon { color: white; }
        .stat-icon.today { background: linear-gradient(135deg, #667eea, #764ba2); }
        .stat-icon.weekly { background: linear-gradient(135deg, #f093fb, #f5576c); }
        .stat-icon.monthly { background: linear-gradient(135deg, var(--primary), var(--glow)); }
        
        .stat-info h3 { font-size: 24px; color: var(--primary-dark); margin-bottom: 5px; }
        
        /* Action Buttons */
        .btn-action {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-family: 'Poppins', sans-serif;
            font-weight: 500;
            font-size: 14px;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
            text-decoration: none;
        }
        
        .btn-action.btn-primary {
            background: linear-gradient(135deg, var(--primary), var(--glow));
            color: white;
        }
        
        .btn-action.btn-primary:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(0,128,128,0.3); }
        
        .btn-action.btn-success {
            background: linear-gradient(135deg, #28a745, #38f9d7);
            color: white;
        }
        
        .btn-action.btn-success:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(40,167,69,0.3); }
        
        /* Staff Directory */
        .staff-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 25px;
            margin-top: 20px;
        }
        
        .staff-card {
            background: var(--white);
            border-radius: 20px;
            padding: 25px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            text-align: center;
            transition: all 0.3s ease;
            border: 2px solid transparent;
        }
        
        .staff-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 15px 40px rgba(0,128,128,0.15);
            border-color: var(--primary-light);
        }
        
        .staff-avatar {
            width: 100px;
            height: 100px;
            border-radius: 50%;
            margin: 0 auto 15px;
            overflow: hidden;
            border: 4px solid var(--primary);
            box-shadow: 0 5px 20px rgba(0,128,128,0.2);
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
            font-size: 40px;
            color: white;
        }
        
        .staff-card h4 {
            color: var(--primary-dark);
            font-size: 18px;
            margin-bottom: 5px;
        }
        
        .staff-card .staff-role {
            color: var(--primary);
            font-size: 13px;
            font-weight: 500;
            background: rgba(0,128,128,0.1);
            padding: 4px 12px;
            border-radius: 15px;
            display: inline-block;
            margin-bottom: 15px;
        }
        
        .staff-card .staff-info {
            margin-top: 15px;
            padding-top: 15px;
            border-top: 1px solid #eee;
        }
        
        .staff-card .staff-info p {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            margin-bottom: 10px;
            color: var(--text-light);
            font-size: 14px;
        }
        
        .staff-card .staff-info p i {
            color: var(--primary);
            width: 20px;
        }
        
        .staff-card .staff-info a {
            color: var(--text-light);
            text-decoration: none;
            transition: color 0.3s ease;
        }
        
        .staff-card .staff-info a:hover {
            color: var(--primary);
        }
        
        .staff-count-badge {
            background: linear-gradient(135deg, var(--primary), var(--glow));
            color: white;
            padding: 10px 25px;
            border-radius: 25px;
            display: inline-flex;
            align-items: center;
            gap: 10px;
            font-weight: 500;
            margin-bottom: 20px;
        }
        
        .staff-count-badge i { font-size: 18px; }
        
        /* Charts */
        .charts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
            margin: 25px 0;
        }
        
        .chart-card {
            background: var(--white);
            border-radius: 15px;
            padding: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
        }
        
        .chart-card h4 {
            color: var(--primary-dark);
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .chart-card h4 i { color: var(--primary); }
        
        /* Print Styles */
        @media print {
            .sidebar { display: none !important; }
            .main-content { margin-left: 0 !important; width: 100% !important; padding: 20px !important; }
            .report-tabs { display: none !important; }
            .top-bar .logout-btn { display: none !important; }
            .btn-action { display: none !important; }
            .report-content { display: block !important; page-break-after: always; }
            .report-content:not(.active) { display: none !important; }
            .card { box-shadow: none !important; border: 1px solid #ddd; }
            body { background: white !important; }
            .stat-card { box-shadow: none !important; border: 1px solid #ddd; }
        }
        .stat-info p { color: var(--text-light); font-size: 14px; }
        .stat-info small { color: var(--text-light); font-size: 12px; }
        
        /* Report Cards */
        .section-title {
            font-size: 20px;
            color: var(--primary-dark);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .section-title i { color: var(--primary); }
        
        .report-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 25px;
            margin-bottom: 30px;
        }
        
        .report-card {
            background: var(--white);
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.05);
            text-align: center;
            transition: all 0.3s ease;
            border: 2px solid transparent;
        }
        
        .report-card:hover {
            border-color: var(--primary);
            transform: translateY(-8px);
            box-shadow: 0 15px 40px rgba(0,128,128,0.15);
        }
        
        .report-card-icon {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            font-size: 35px;
        }
        
        .report-card-icon.daily { background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
        .report-card-icon.periodic { background: linear-gradient(135deg, #f093fb, #f5576c); color: white; }
        .report-card-icon.view { background: linear-gradient(135deg, var(--primary), var(--glow)); color: white; }
        
        .report-card h3 { color: var(--primary-dark); font-size: 18px; margin-bottom: 10px; }
        .report-card p { color: var(--text-light); font-size: 14px; margin-bottom: 20px; line-height: 1.6; }
        
        .report-btn {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 12px 30px;
            border-radius: 25px;
            text-decoration: none;
            font-weight: 500;
            transition: all 0.3s ease;
        }
        
        .report-btn.primary {
            background: linear-gradient(135deg, var(--primary), var(--glow));
            color: white;
        }
        
        .report-btn.secondary {
            background: var(--bg);
            color: var(--primary-dark);
            border: 2px solid var(--primary);
        }
        
        .report-btn:hover { transform: translateY(-3px); box-shadow: 0 8px 25px rgba(0,128,128,0.25); }
        
        /* Quick Period Buttons */
        .period-buttons {
            display: flex;
            gap: 15px;
            margin-bottom: 30px;
            flex-wrap: wrap;
        }
        
        .period-btn {
            padding: 12px 25px;
            background: var(--white);
            border: 2px solid var(--primary);
            border-radius: 25px;
            color: var(--primary);
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .period-btn:hover, .period-btn.active {
            background: linear-gradient(135deg, var(--primary), var(--glow));
            color: white;
            border-color: var(--primary);
        }
        
        /* Date Picker Card */
        .date-picker-card {
            background: var(--white);
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            margin-bottom: 30px;
        }
        
        .date-picker-card h3 { color: var(--primary-dark); margin-bottom: 15px; }
        
        .date-form {
            display: flex;
            gap: 15px;
            align-items: center;
            flex-wrap: wrap;
        }
        
        .date-form input[type="date"] {
            padding: 12px 20px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-family: 'Poppins', sans-serif;
            font-size: 14px;
            min-width: 200px;
        }
        
        .date-form input[type="date"]:focus { outline: none; border-color: var(--primary); }
        
        .btn-generate {
            padding: 12px 30px;
            background: linear-gradient(135deg, var(--primary), var(--glow));
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
        
        .btn-generate:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(0,128,128,0.3); }
        
        /* Search Section */
        .search-card {
            background: var(--white);
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            margin-bottom: 30px;
        }
        
        .search-card h3 {
            color: var(--primary-dark);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .search-form {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            color: var(--text-light);
            font-size: 13px;
            margin-bottom: 5px;
            font-weight: 500;
        }
        
        .form-group input, .form-group select {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-family: 'Poppins', sans-serif;
            font-size: 14px;
            transition: all 0.3s ease;
        }
        
        .form-group input:focus, .form-group select:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(0,128,128,0.1);
        }
        
        .search-buttons {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .btn-search {
            padding: 12px 30px;
            background: linear-gradient(135deg, var(--primary), var(--glow));
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
        
        .btn-search:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(0,128,128,0.3); }
        
        .btn-clear {
            padding: 12px 30px;
            background: #e0e0e0;
            color: var(--text-dark);
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
        
        .btn-clear:hover { background: #d0d0d0; }
        
        /* Results Table */
        .results-card {
            background: var(--white);
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            margin-bottom: 30px;
        }
        
        .results-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .results-header h3 {
            color: var(--primary-dark);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .results-summary {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
        }
        
        .results-summary span {
            padding: 8px 20px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: 500;
        }
        
        .results-summary .count { background: rgba(0,128,128,0.1); color: var(--primary-dark); }
        .results-summary .total { background: rgba(40,167,69,0.1); color: var(--success); }
        
        .results-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .results-table th {
            background: var(--primary-dark);
            color: white;
            padding: 15px 12px;
            text-align: left;
            font-weight: 500;
            font-size: 13px;
        }
        
        .results-table th:first-child { border-radius: 10px 0 0 0; }
        .results-table th:last-child { border-radius: 0 10px 0 0; }
        
        .results-table td {
            padding: 15px 12px;
            border-bottom: 1px solid #f0f0f0;
            font-size: 13px;
        }
        
        .results-table tr:hover { background: rgba(0,128,128,0.02); }
        
        .status-badge {
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .status-badge.paid { background: rgba(40,167,69,0.15); color: var(--success); }
        .status-badge.pending { background: rgba(255,193,7,0.15); color: #d39e00; }
        .status-badge.cancelled { background: rgba(220,53,69,0.15); color: var(--danger); }
        
        .no-results {
            text-align: center;
            padding: 50px 20px;
            color: var(--text-light);
        }
        
        .no-results i { font-size: 50px; margin-bottom: 15px; color: #ddd; }
        
        .table-responsive { overflow-x: auto; }
        
        .btn-view {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 35px;
            height: 35px;
            background: linear-gradient(135deg, var(--primary), var(--glow));
            color: white;
            border-radius: 8px;
            text-decoration: none;
            transition: all 0.3s ease;
        }
        
        .btn-view:hover {
            transform: scale(1.1);
            box-shadow: 0 5px 15px rgba(0,128,128,0.3);
        }
        
        /* Report Tabs */
        .report-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            flex-wrap: wrap;
            align-items: center;
        }
        
        .report-tab {
            padding: 12px 25px;
            border: none;
            background: #e0e0e0;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 500;
            font-family: 'Poppins', sans-serif;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .report-tab.active {
            background: var(--primary);
            color: white;
        }
        
        .report-tab:hover:not(.active) {
            background: #d0d0d0;
        }
        
        .report-content { display: none; }
        .report-content.active { display: block; animation: fadeIn 0.5s ease; }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .btn-action {
            padding: 12px 25px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 500;
            font-family: 'Poppins', sans-serif;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-primary { background: var(--primary); color: white; }
        .btn-success { background: var(--success); color: white; }
        .btn-action:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,0,0,0.2); }
        
        /* Card Styles */
        .card {
            background: var(--white);
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
            margin-bottom: 25px;
            overflow: hidden;
        }
        
        .card-header {
            background: linear-gradient(135deg, var(--primary-dark), var(--primary));
            color: white;
            padding: 15px 25px;
        }
        
        .card-header h3 {
            font-size: 16px;
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .card-body { padding: 25px; }
        
        /* Data Table */
        .data-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .data-table th {
            background: var(--bg);
            padding: 12px 15px;
            text-align: left;
            font-weight: 500;
            font-size: 13px;
            color: var(--text-dark);
            border-bottom: 2px solid #e0e0e0;
        }
        
        .data-table td {
            padding: 12px 15px;
            border-bottom: 1px solid #f0f0f0;
            font-size: 13px;
        }
        
        .data-table tr:hover { background: rgba(0,128,128,0.02); }
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
            <a href="<%= contextPath %>/staff/staff-reports.jsp" class="nav-item active"><i class="fas fa-chart-bar"></i> Reports</a>
            
            <h5>Team</h5>
            <a href="<%= contextPath %>/staff/staff-directory.jsp" class="nav-item"><i class="fas fa-users"></i> Staff Directory</a>
            
            <h5>Settings</h5>
            <a href="<%= contextPath %>/staff/staff-profile.jsp" class="nav-item"><i class="fas fa-user-cog"></i> My Profile</a>
        </nav>
    </div>

    <!-- Main Content -->
    <div class="main-content">
        <div class="top-bar">
            <div>
                <h1><i class="fas fa-chart-bar"></i> Reports</h1>
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

        <!-- Report Period Tabs -->
        <div class="report-tabs">
            <button class="report-tab active" id="tabDaily" onclick="showReportTab('daily')">
                <i class="fas fa-calendar-day"></i> Daily Report
            </button>
            <button class="report-tab" id="tabWeekly" onclick="showReportTab('weekly')">
                <i class="fas fa-calendar-week"></i> Weekly Report
            </button>
            <button class="report-tab" id="tabMonthly" onclick="showReportTab('monthly')">
                <i class="fas fa-calendar-alt"></i> Monthly Report
            </button>
            <button class="report-tab" id="tabSearch" onclick="showReportTab('search')">
                <i class="fas fa-search"></i> Search
            </button>
            <button class="report-tab" id="tabStaff" onclick="showReportTab('staff')">
                <i class="fas fa-users"></i> Staff Directory
            </button>
            <div style="flex: 1;"></div>
            <button class="btn-action btn-primary" id="downloadPdfBtn" onclick="downloadPDF()">
                <i class="fas fa-file-pdf"></i> Download PDF
            </button>
            <button class="btn-action btn-success" onclick="printReport()">
                <i class="fas fa-print"></i> Print
            </button>
        </div>

        <!-- Daily Report -->
        <div id="reportDaily" class="report-content active">
            <div class="card">
                <div class="card-header"><h3><i class="fas fa-calendar-day"></i> Daily Report - <%= today %></h3></div>
                <div class="card-body">
                    <div class="stats-grid">
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, var(--primary), var(--glow));"><i class="fas fa-rupee-sign"></i></div>
                            <div class="stat-info"><h3>Rs. <%= df.format(todayRevenue) %></h3><p>Today's Revenue</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #667eea, #764ba2);"><i class="fas fa-calendar-check"></i></div>
                            <div class="stat-info"><h3><%= dailyBookings %></h3><p>Today's Bookings</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #f093fb, #f5576c);"><i class="fas fa-user-plus"></i></div>
                            <div class="stat-info"><h3><%= dailyGuests %></h3><p>New Guests Today</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b, #38f9d7);"><i class="fas fa-door-open"></i></div>
                            <div class="stat-info"><h3><%= availableRooms %> / <%= totalRooms %></h3><p>Available Rooms</p></div>
                        </div>
                    </div>
                    
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
                    
                    <!-- Daily Charts -->
                    <div class="charts-grid">
                        <div class="chart-card">
                            <h4><i class="fas fa-chart-pie"></i> Room Status</h4>
                            <div style="height: 250px;"><canvas id="dailyRoomChart"></canvas></div>
                        </div>
                        <div class="chart-card">
                            <h4><i class="fas fa-chart-bar"></i> Today's Summary</h4>
                            <div style="height: 250px;"><canvas id="dailySummaryChart"></canvas></div>
                        </div>
                    </div>
                    
                    <!-- Today's Transactions -->
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
                                                "WHERE DATE(b.paid_at) = CURDATE() AND b.payment_status = 'PAID' ORDER BY b.paid_at DESC LIMIT 10"
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
                                        <td><%= tdRs.getTimestamp("paid_at") != null ? new SimpleDateFormat("hh:mm a").format(tdRs.getTimestamp("paid_at")) : "-" %></td>
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
                </div>
            </div>
        </div>

        <!-- Weekly Report -->
        <div id="reportWeekly" class="report-content">
            <div class="card">
                <div class="card-header"><h3><i class="fas fa-calendar-week"></i> Weekly Report</h3></div>
                <div class="card-body">
                    <div class="stats-grid">
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, var(--primary), var(--glow));"><i class="fas fa-rupee-sign"></i></div>
                            <div class="stat-info"><h3>Rs. <%= df.format(weeklyRevenue) %></h3><p>Weekly Revenue</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #667eea, #764ba2);"><i class="fas fa-calendar-check"></i></div>
                            <div class="stat-info"><h3><%= weeklyBookings %></h3><p>Weekly Bookings</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #f093fb, #f5576c);"><i class="fas fa-user-plus"></i></div>
                            <div class="stat-info"><h3><%= weeklyGuests %></h3><p>New Guests</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b, #38f9d7);"><i class="fas fa-file-invoice"></i></div>
                            <div class="stat-info"><h3><%= weeklyBills %></h3><p>Bills Processed</p></div>
                        </div>
                    </div>
                    
                    <div class="stats-grid" style="margin-top: 15px;">
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b, #38f9d7);"><i class="fas fa-sign-in-alt"></i></div>
                            <div class="stat-info"><h3><%= weeklyCheckIns %></h3><p>Weekly Check-ins</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #fa709a, #fee140);"><i class="fas fa-sign-out-alt"></i></div>
                            <div class="stat-info"><h3><%= weeklyCheckOuts %></h3><p>Weekly Check-outs</p></div>
                        </div>
                    </div>
                    
                    <!-- Weekly Charts -->
                    <div class="charts-grid">
                        <div class="chart-card">
                            <h4><i class="fas fa-chart-bar"></i> Daily Revenue (Last 7 Days)</h4>
                            <div style="height: 280px;"><canvas id="weeklyRevenueChart"></canvas></div>
                        </div>
                        <div class="chart-card">
                            <h4><i class="fas fa-chart-line"></i> Daily Bookings (Last 7 Days)</h4>
                            <div style="height: 280px;"><canvas id="weeklyBookingsChart"></canvas></div>
                        </div>
                    </div>
                    
                    <div class="charts-grid">
                        <div class="chart-card">
                            <h4><i class="fas fa-sign-in-alt"></i> Check-ins vs Check-outs (Last 7 Days)</h4>
                            <div style="height: 280px;"><canvas id="weeklyCheckInOutChart"></canvas></div>
                        </div>
                    </div>
                    
                    <!-- Weekly Transactions -->
                    <div style="margin-top: 25px;">
                        <h4 style="margin-bottom: 15px;"><i class="fas fa-list"></i> This Week's Transactions</h4>
                        <div style="overflow-x: auto;">
                            <table class="data-table">
                                <thead><tr><th>Bill #</th><th>Guest</th><th>Room</th><th>Amount</th><th>Method</th><th>Date</th></tr></thead>
                                <tbody>
                                    <%
                                        try {
                                            Statement wkStmt = conn.createStatement();
                                            ResultSet wkRs = wkStmt.executeQuery(
                                                "SELECT b.bill_number, g.full_name, ro.room_number, b.total_amount, b.payment_method, b.paid_at " +
                                                "FROM bills b JOIN reservations r ON b.reservation_id = r.reservation_id " +
                                                "JOIN guests g ON r.guest_id = g.guest_id JOIN rooms ro ON r.room_id = ro.room_id " +
                                                "WHERE YEARWEEK(b.paid_at) = YEARWEEK(CURDATE()) AND b.payment_status = 'PAID' ORDER BY b.paid_at DESC LIMIT 20"
                                            );
                                            boolean hasWk = false;
                                            while (wkRs.next()) {
                                                hasWk = true;
                                    %>
                                    <tr>
                                        <td><%= wkRs.getString("bill_number") %></td>
                                        <td><%= wkRs.getString("full_name") %></td>
                                        <td>Room <%= wkRs.getString("room_number") %></td>
                                        <td><strong>Rs. <%= df.format(wkRs.getDouble("total_amount")) %></strong></td>
                                        <td><%= wkRs.getString("payment_method") != null ? wkRs.getString("payment_method").replace("_", " ") : "N/A" %></td>
                                        <td><%= wkRs.getTimestamp("paid_at") != null ? new SimpleDateFormat("MMM dd, hh:mm a").format(wkRs.getTimestamp("paid_at")) : "-" %></td>
                                    </tr>
                                    <% }
                                            if (!hasWk) out.println("<tr><td colspan='6' style='text-align:center'>No transactions this week</td></tr>");
                                            wkRs.close(); wkStmt.close();
                                        } catch (Exception e) { out.println("<tr><td colspan='6'>Error loading data</td></tr>"); }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Monthly Report -->
        <div id="reportMonthly" class="report-content">
            <div class="card">
                <div class="card-header"><h3><i class="fas fa-calendar-alt"></i> Monthly Report</h3></div>
                <div class="card-body">
                    <div class="stats-grid">
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, var(--primary), var(--glow));"><i class="fas fa-rupee-sign"></i></div>
                            <div class="stat-info"><h3>Rs. <%= df.format(monthlyRevenue) %></h3><p>Monthly Revenue</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #667eea, #764ba2);"><i class="fas fa-calendar-check"></i></div>
                            <div class="stat-info"><h3><%= monthlyBookings %></h3><p>Monthly Bookings</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #f093fb, #f5576c);"><i class="fas fa-user-plus"></i></div>
                            <div class="stat-info"><h3><%= monthlyGuests %></h3><p>New Guests</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b, #38f9d7);"><i class="fas fa-file-invoice"></i></div>
                            <div class="stat-info"><h3><%= monthlyBills %></h3><p>Bills Processed</p></div>
                        </div>
                    </div>
                    
                    <div class="stats-grid" style="margin-top: 15px;">
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b, #38f9d7);"><i class="fas fa-sign-in-alt"></i></div>
                            <div class="stat-info"><h3><%= monthlyCheckIns %></h3><p>Monthly Check-ins</p></div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #fa709a, #fee140);"><i class="fas fa-sign-out-alt"></i></div>
                            <div class="stat-info"><h3><%= monthlyCheckOuts %></h3><p>Monthly Check-outs</p></div>
                        </div>
                    </div>
                    
                    <!-- Monthly Charts -->
                    <div class="charts-grid">
                        <div class="chart-card">
                            <h4><i class="fas fa-chart-line"></i> Revenue Trend (Last 7 Days)</h4>
                            <div style="height: 280px;"><canvas id="monthlyRevenueChart"></canvas></div>
                        </div>
                        <div class="chart-card">
                            <h4><i class="fas fa-chart-doughnut"></i> Monthly Summary</h4>
                            <div style="height: 280px;"><canvas id="monthlySummaryChart"></canvas></div>
                        </div>
                    </div>
                    
                    <!-- Monthly Transactions -->
                    <div style="margin-top: 25px;">
                        <h4 style="margin-bottom: 15px;"><i class="fas fa-list"></i> This Month's Transactions</h4>
                        <div style="overflow-x: auto;">
                            <table class="data-table">
                                <thead><tr><th>Bill #</th><th>Guest</th><th>Room</th><th>Amount</th><th>Method</th><th>Date</th></tr></thead>
                                <tbody>
                                    <%
                                        try {
                                            Statement mtStmt = conn.createStatement();
                                            ResultSet mtRs = mtStmt.executeQuery(
                                                "SELECT b.bill_number, g.full_name, ro.room_number, b.total_amount, b.payment_method, b.paid_at " +
                                                "FROM bills b JOIN reservations r ON b.reservation_id = r.reservation_id " +
                                                "JOIN guests g ON r.guest_id = g.guest_id JOIN rooms ro ON r.room_id = ro.room_id " +
                                                "WHERE MONTH(b.paid_at) = MONTH(CURDATE()) AND YEAR(b.paid_at) = YEAR(CURDATE()) AND b.payment_status = 'PAID' " +
                                                "ORDER BY b.paid_at DESC LIMIT 30"
                                            );
                                            boolean hasMt = false;
                                            while (mtRs.next()) {
                                                hasMt = true;
                                    %>
                                    <tr>
                                        <td><%= mtRs.getString("bill_number") %></td>
                                        <td><%= mtRs.getString("full_name") %></td>
                                        <td>Room <%= mtRs.getString("room_number") %></td>
                                        <td><strong>Rs. <%= df.format(mtRs.getDouble("total_amount")) %></strong></td>
                                        <td><%= mtRs.getString("payment_method") != null ? mtRs.getString("payment_method").replace("_", " ") : "N/A" %></td>
                                        <td><%= mtRs.getTimestamp("paid_at") != null ? new SimpleDateFormat("MMM dd, hh:mm a").format(mtRs.getTimestamp("paid_at")) : "-" %></td>
                                    </tr>
                                    <% }
                                            if (!hasMt) out.println("<tr><td colspan='6' style='text-align:center'>No transactions this month</td></tr>");
                                            mtRs.close(); mtStmt.close();
                                        } catch (Exception e) { out.println("<tr><td colspan='6'>Error loading data</td></tr>"); }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Search Tab -->
        <div id="reportSearch" class="report-content">
            <div class="card">
                <div class="card-header"><h3><i class="fas fa-search"></i> Search Bills & Invoices</h3></div>
                <div class="card-body">
                    <form method="get" action="<%= contextPath %>/staff/staff-reports.jsp">
                        <input type="hidden" name="tab" value="search">
                        <div class="search-form">
                            <div class="form-group">
                                <label>Bill Number</label>
                                <input type="text" name="billNo" placeholder="e.g., BILL-001" value="<%= searchBillNo != null ? searchBillNo : "" %>">
                            </div>
                            <div class="form-group">
                                <label>Guest Name / Email / Phone</label>
                                <input type="text" name="guestName" placeholder="Search guest..." value="<%= searchGuest != null ? searchGuest : "" %>">
                            </div>
                            <div class="form-group">
                                <label>Date From</label>
                                <input type="date" name="dateFrom" value="<%= searchDateFrom != null ? searchDateFrom : "" %>">
                            </div>
                            <div class="form-group">
                                <label>Date To</label>
                                <input type="date" name="dateTo" value="<%= searchDateTo != null ? searchDateTo : "" %>">
                            </div>
                            <div class="form-group">
                                <label>Payment Status</label>
                                <select name="paymentStatus">
                                    <option value="">All Status</option>
                                    <option value="PAID" <%= "PAID".equals(searchStatus) ? "selected" : "" %>>Paid</option>
                                    <option value="PENDING" <%= "PENDING".equals(searchStatus) ? "selected" : "" %>>Pending</option>
                                </select>
                            </div>
                        </div>
                        <div class="search-buttons" style="margin-top: 15px;">
                            <button type="submit" class="btn-search">
                                <i class="fas fa-search"></i> Search
                            </button>
                            <a href="<%= contextPath %>/staff/staff-reports.jsp" class="btn-clear">
                                <i class="fas fa-times"></i> Clear
                            </a>
                        </div>
                    </form>
                    
                    <% if (hasSearch) { %>
                    <div style="margin-top: 25px;">
                        <div class="results-header" style="margin-bottom: 15px;">
                            <h4><i class="fas fa-list"></i> Search Results</h4>
                            <div class="results-summary" style="margin-top: 10px;">
                                <span class="count"><i class="fas fa-file-invoice"></i> <%= searchResultCount %> records found</span>
                                <span class="total" style="margin-left: 15px;"><i class="fas fa-rupee-sign"></i> Total: Rs. <%= df.format(searchTotalAmount) %></span>
                            </div>
                        </div>
                        
                        <% if (searchResults.isEmpty()) { %>
                        <div class="no-results">
                            <i class="fas fa-search"></i>
                            <h4>No Results Found</h4>
                            <p>Try adjusting your search criteria</p>
                        </div>
                        <% } else { %>
                        <div class="table-responsive">
                            <table class="results-table">
                                <thead>
                                    <tr>
                                        <th>Bill #</th>
                                        <th>Guest</th>
                                        <th>Room</th>
                                        <th>Amount</th>
                                        <th>Status</th>
                                        <th>Method</th>
                                        <th>Date</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Map<String, String> row : searchResults) { %>
                                    <tr>
                                        <td><strong><%= row.get("bill_number") %></strong></td>
                                        <td>
                                            <div><%= row.get("guest_name") %></div>
                                            <small style="color: #666;"><%= row.get("email") %></small>
                                        </td>
                                        <td>
                                            <div>Room <%= row.get("room_number") %></div>
                                            <small style="color: #666;"><%= row.get("room_type") %></small>
                                        </td>
                                        <td><strong>Rs. <%= row.get("total_amount") %></strong></td>
                                        <td>
                                            <span class="status-badge <%= row.get("payment_status").toLowerCase() %>">
                                                <%= row.get("payment_status") %>
                                            </span>
                                        </td>
                                        <td><%= row.get("payment_method") %></td>
                                        <td><%= row.get("date") %></td>
                                        <td>
                                            <a href="<%= contextPath %>/staff/staff-invoice-view.jsp?billId=<%= row.get("bill_id") %>" class="btn-view" title="View Invoice">
                                                <i class="fas fa-eye"></i>
                                            </a>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                        <% } %>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>

        <!-- Staff Directory -->
        <div id="reportStaff" class="report-content">
            <div class="card">
                <div class="card-header"><h3><i class="fas fa-users"></i> Staff Directory</h3></div>
                <div class="card-body">
                    <div class="staff-count-badge">
                        <i class="fas fa-id-badge"></i>
                        <span><%= staffList.size() %> Active Staff Members</span>
                    </div>
                    
                    <div class="staff-grid">
                        <% for (Map<String, String> staffMember : staffList) { 
                            String staffProfilePic = staffMember.get("profile_picture");
                        %>
                        <div class="staff-card">
                            <div class="staff-avatar">
                            <% if (staffProfilePic != null && !staffProfilePic.isEmpty()) { %>
                                <img src="<%= resolveProfileImageUrl(contextPath, staffProfilePic) %>" alt="<%= staffMember.get("full_name") %>">
                                <% } else { %>
                                    <div class="no-image">
                                        <i class="fas fa-user"></i>
                                    </div>
                                <% } %>
                            </div>
                            <h4><%= staffMember.get("full_name") %></h4>
                            <span class="staff-role"><i class="fas fa-user-tie"></i> Staff Member</span>
                            
                            <div class="staff-info">
                                <p>
                                    <i class="fas fa-phone"></i>
                                    <a href="tel:<%= staffMember.get("phone") %>"><%= staffMember.get("phone") %></a>
                                </p>
                                <p>
                                    <i class="fas fa-envelope"></i>
                                    <a href="mailto:<%= staffMember.get("email") %>"><%= staffMember.get("email") %></a>
                                </p>
                                <p>
                                    <i class="fas fa-calendar"></i>
                                    <span>Joined: <%= staffMember.get("hire_date") %></span>
                                </p>
                            </div>
                        </div>
                        <% } %>
                        
                        <% if (staffList.isEmpty()) { %>
                        <div style="grid-column: 1 / -1; text-align: center; padding: 50px;">
                            <i class="fas fa-users" style="font-size: 60px; color: #ddd; margin-bottom: 20px;"></i>
                            <h4 style="color: #999;">No Staff Members Found</h4>
                            <p style="color: #aaa;">There are no active staff members in the system.</p>
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Tab data for download
        let currentTab = 'daily';
        
        function showReportTab(tabName) {
            currentTab = tabName;
            
            // Hide all report contents
            document.querySelectorAll('.report-content').forEach(el => el.classList.remove('active'));
            // Remove active class from all tabs
            document.querySelectorAll('.report-tab').forEach(el => el.classList.remove('active'));
            
            // Show selected report
            const reportEl = document.getElementById('report' + tabName.charAt(0).toUpperCase() + tabName.slice(1));
            if (reportEl) reportEl.classList.add('active');
            
            // Activate the clicked tab
            const tabEl = document.getElementById('tab' + tabName.charAt(0).toUpperCase() + tabName.slice(1));
            if (tabEl) tabEl.classList.add('active');
            
            // Update download button
            updateDownloadButton(tabName);
            
            // Initialize charts for the active tab
            initializeCharts(tabName);
        }
        
        function updateDownloadButton(tabName) {
            const downloadBtn = document.getElementById('downloadPdfBtn');
            if (downloadBtn) {
                if (tabName === 'search' || tabName === 'staff') {
                    downloadBtn.style.display = 'none';
                } else {
                    downloadBtn.style.display = 'inline-flex';
                    downloadBtn.setAttribute('data-period', tabName);
                }
            }
        }
        
        let currentPeriod = 'daily';
        
        async function downloadPDF() {
            const { jsPDF } = window.jspdf;
            const downloadBtn = document.getElementById('downloadPdfBtn');
            const period = downloadBtn.getAttribute('data-period') || 'daily';
            currentPeriod = period;
            
            // Show loading state
            const originalText = downloadBtn.innerHTML;
            downloadBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Generating...';
            downloadBtn.disabled = true;
            
            try {
                // Get the active report content
                const reportId = 'report' + period.charAt(0).toUpperCase() + period.slice(1);
                const reportContent = document.getElementById(reportId);
                
                if (!reportContent) {
                    alert('Report content not found');
                    return;
                }
                
                // Create PDF
                const pdf = new jsPDF('p', 'mm', 'a4');
                const pageWidth = pdf.internal.pageSize.getWidth();
                const pageHeight = pdf.internal.pageSize.getHeight();
                const margin = 15;
                let yPos = margin;
                
                // Header
                pdf.setFillColor(0, 64, 64);
                pdf.rect(0, 0, pageWidth, 35, 'F');
                
                pdf.setTextColor(255, 255, 255);
                pdf.setFontSize(20);
                pdf.setFont('helvetica', 'bold');
                pdf.text('Ocean View Resort', pageWidth / 2, 15, { align: 'center' });
                
                pdf.setFontSize(14);
                pdf.setFont('helvetica', 'normal');
                const periodTitle = period.charAt(0).toUpperCase() + period.slice(1) + ' Report';
                pdf.text(periodTitle, pageWidth / 2, 25, { align: 'center' });
                
                pdf.setFontSize(10);
                pdf.text('Generated: ' + new Date().toLocaleString(), pageWidth / 2, 32, { align: 'center' });
                
                yPos = 45;
                pdf.setTextColor(0, 0, 0);
                
                // Get stats from the report
                const statCards = reportContent.querySelectorAll('.stat-card');
                const stats = [];
                statCards.forEach(card => {
                    const h3 = card.querySelector('h3');
                    const p = card.querySelector('p');
                    if (h3 && p) {
                        stats.push({ value: h3.textContent.trim(), label: p.textContent.trim() });
                    }
                });
                
                // Draw stats section
                if (stats.length > 0) {
                    pdf.setFontSize(14);
                    pdf.setFont('helvetica', 'bold');
                    pdf.setTextColor(0, 64, 64);
                    pdf.text('Summary Statistics', margin, yPos);
                    yPos += 8;
                    
                    pdf.setDrawColor(0, 128, 128);
                    pdf.setLineWidth(0.5);
                    pdf.line(margin, yPos, pageWidth - margin, yPos);
                    yPos += 8;
                    
                    const colWidth = (pageWidth - margin * 2) / Math.min(stats.length, 4);
                    
                    stats.forEach((stat, index) => {
                        const col = index % 4;
                        const row = Math.floor(index / 4);
                        const x = margin + (col * colWidth) + (colWidth / 2);
                        const y = yPos + (row * 25);
                        
                        // Value
                        pdf.setFontSize(12);
                        pdf.setFont('helvetica', 'bold');
                        pdf.setTextColor(0, 128, 128);
                        pdf.text(stat.value, x, y, { align: 'center' });
                        
                        // Label
                        pdf.setFontSize(9);
                        pdf.setFont('helvetica', 'normal');
                        pdf.setTextColor(100, 100, 100);
                        pdf.text(stat.label, x, y + 5, { align: 'center' });
                    });
                    
                    yPos += Math.ceil(stats.length / 4) * 25 + 10;
                }
                
                // Get table data if exists
                const tables = reportContent.querySelectorAll('table');
                tables.forEach(table => {
                    const tableTitle = table.closest('.card')?.querySelector('.card-header h3')?.textContent || 'Data Table';
                    
                    if (yPos > pageHeight - 60) {
                        pdf.addPage();
                        yPos = margin;
                    }
                    
                    pdf.setFontSize(12);
                    pdf.setFont('helvetica', 'bold');
                    pdf.setTextColor(0, 64, 64);
                    pdf.text(tableTitle.trim(), margin, yPos);
                    yPos += 8;
                    
                    // Table headers
                    const headers = [];
                    const headerCells = table.querySelectorAll('thead th');
                    headerCells.forEach(th => headers.push(th.textContent.trim()));
                    
                    // Table data
                    const rows = [];
                    const bodyRows = table.querySelectorAll('tbody tr');
                    bodyRows.forEach(tr => {
                        const row = [];
                        tr.querySelectorAll('td').forEach(td => row.push(td.textContent.trim()));
                        if (row.length > 0) rows.push(row);
                    });
                    
                    if (headers.length > 0 && rows.length > 0) {
                        const cellWidth = (pageWidth - margin * 2) / headers.length;
                        const cellHeight = 8;
                        
                        // Header row
                        pdf.setFillColor(0, 128, 128);
                        pdf.rect(margin, yPos, pageWidth - margin * 2, cellHeight, 'F');
                        
                        pdf.setFontSize(8);
                        pdf.setFont('helvetica', 'bold');
                        pdf.setTextColor(255, 255, 255);
                        headers.forEach((header, i) => {
                            pdf.text(header.substring(0, 15), margin + (i * cellWidth) + 2, yPos + 5);
                        });
                        yPos += cellHeight;
                        
                        // Data rows
                        pdf.setTextColor(0, 0, 0);
                        pdf.setFont('helvetica', 'normal');
                        rows.slice(0, 10).forEach((row, rowIndex) => {
                            if (yPos > pageHeight - 20) {
                                pdf.addPage();
                                yPos = margin;
                            }
                            
                            if (rowIndex % 2 === 0) {
                                pdf.setFillColor(240, 245, 245);
                                pdf.rect(margin, yPos, pageWidth - margin * 2, cellHeight, 'F');
                            }
                            
                            row.forEach((cell, i) => {
                                pdf.text(cell.substring(0, 18), margin + (i * cellWidth) + 2, yPos + 5);
                            });
                            yPos += cellHeight;
                        });
                        
                        if (rows.length > 10) {
                            pdf.setFontSize(8);
                            pdf.setTextColor(100, 100, 100);
                            pdf.text('... and ' + (rows.length - 10) + ' more rows', margin, yPos + 5);
                            yPos += 10;
                        }
                        
                        yPos += 10;
                    }
                });
                
                // Footer
                const totalPages = pdf.getNumberOfPages();
                for (let i = 1; i <= totalPages; i++) {
                    pdf.setPage(i);
                    pdf.setFontSize(8);
                    pdf.setTextColor(150, 150, 150);
                    pdf.text('Ocean View Resort - ' + periodTitle + ' | Page ' + i + ' of ' + totalPages, pageWidth / 2, pageHeight - 10, { align: 'center' });
                }
                
                // Download
                const fileName = 'OceanView_' + period.charAt(0).toUpperCase() + period.slice(1) + '_Report_' + new Date().toISOString().split('T')[0] + '.pdf';
                pdf.save(fileName);
                
            } catch (error) {
                console.error('PDF generation error:', error);
                alert('Error generating PDF. Please try again.');
            } finally {
                // Restore button
                downloadBtn.innerHTML = originalText;
                downloadBtn.disabled = false;
            }
        }
        
        function printReport() {
            // Store current active section for printing
            window.print();
        }
        
        let chartsInitialized = {};
        
        function initializeCharts(tabName) {
            if (chartsInitialized[tabName]) return;
            
            // Chart data from server
            const dailyLabels = [<% for (int i = 0; i < 7; i++) { if (i > 0) out.print(","); out.print("'" + dailyLabels[i] + "'"); } %>];
            const dailyRevenueData = [<% for (int i = 0; i < 7; i++) { if (i > 0) out.print(","); out.print(dailyRevenueData[i]); } %>];
            const dailyBookingsData = [<% for (int i = 0; i < 7; i++) { if (i > 0) out.print(","); out.print(dailyBookingsData[i]); } %>];
            const checkInsData = [<% for (int i = 0; i < 7; i++) { if (i > 0) out.print(","); out.print(checkInsData[i]); } %>];
            const checkOutsData = [<% for (int i = 0; i < 7; i++) { if (i > 0) out.print(","); out.print(checkOutsData[i]); } %>];
            
            if (tabName === 'daily') {
                // Room Status Pie Chart
                const roomCtx = document.getElementById('dailyRoomChart')?.getContext('2d');
                if (roomCtx) {
                    new Chart(roomCtx, {
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
                
                // Daily Summary Bar Chart
                const summaryCtx = document.getElementById('dailySummaryChart')?.getContext('2d');
                if (summaryCtx) {
                    new Chart(summaryCtx, {
                        type: 'bar',
                        data: {
                            labels: ['Bookings', 'Check-ins', 'Check-outs', 'New Guests', 'Bills'],
                            datasets: [{
                                data: [<%= dailyBookings %>, <%= todayCheckIns %>, <%= todayCheckOuts %>, <%= dailyGuests %>, <%= todayBills %>],
                                backgroundColor: ['#667eea', '#28a745', '#dc3545', '#f093fb', '#008080'],
                                borderRadius: 8
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
                chartsInitialized.daily = true;
            }
            
            if (tabName === 'weekly') {
                // Weekly Revenue Bar Chart
                const revenueCtx = document.getElementById('weeklyRevenueChart')?.getContext('2d');
                if (revenueCtx) {
                    new Chart(revenueCtx, {
                        type: 'bar',
                        data: {
                            labels: dailyLabels,
                            datasets: [{
                                label: 'Revenue (Rs.)',
                                data: dailyRevenueData,
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
                            scales: { 
                                y: { 
                                    beginAtZero: true,
                                    ticks: { callback: function(value) { return 'Rs. ' + value.toLocaleString(); } }
                                }
                            }
                        }
                    });
                }
                
                // Weekly Bookings Line Chart
                const bookingsCtx = document.getElementById('weeklyBookingsChart')?.getContext('2d');
                if (bookingsCtx) {
                    new Chart(bookingsCtx, {
                        type: 'line',
                        data: {
                            labels: dailyLabels,
                            datasets: [{
                                label: 'Bookings',
                                data: dailyBookingsData,
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
                
                // Check-in vs Check-out Chart
                const cicoCtx = document.getElementById('weeklyCheckInOutChart')?.getContext('2d');
                if (cicoCtx) {
                    new Chart(cicoCtx, {
                        type: 'line',
                        data: {
                            labels: dailyLabels,
                            datasets: [
                                {
                                    label: 'Check-ins',
                                    data: checkInsData,
                                    borderColor: '#28a745',
                                    backgroundColor: 'rgba(40,167,69,0.1)',
                                    fill: true,
                                    tension: 0.4,
                                    pointRadius: 5,
                                    pointBackgroundColor: '#28a745'
                                },
                                {
                                    label: 'Check-outs',
                                    data: checkOutsData,
                                    borderColor: '#dc3545',
                                    backgroundColor: 'rgba(220,53,69,0.1)',
                                    fill: true,
                                    tension: 0.4,
                                    pointRadius: 5,
                                    pointBackgroundColor: '#dc3545'
                                }
                            ]
                        },
                        options: { 
                            responsive: true, 
                            maintainAspectRatio: false,
                            plugins: { legend: { position: 'top' } },
                            scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }
                        }
                    });
                }
                chartsInitialized.weekly = true;
            }
            
            if (tabName === 'monthly') {
                // Monthly Revenue Line Chart
                const mRevCtx = document.getElementById('monthlyRevenueChart')?.getContext('2d');
                if (mRevCtx) {
                    new Chart(mRevCtx, {
                        type: 'line',
                        data: {
                            labels: dailyLabels,
                            datasets: [{
                                label: 'Revenue (Rs.)',
                                data: dailyRevenueData,
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
                                y: { 
                                    beginAtZero: true, 
                                    ticks: { callback: function(value) { return 'Rs. ' + value.toLocaleString(); } }
                                }
                            }
                        }
                    });
                }
                
                // Monthly Summary Doughnut Chart
                const mSumCtx = document.getElementById('monthlySummaryChart')?.getContext('2d');
                if (mSumCtx) {
                    new Chart(mSumCtx, {
                        type: 'doughnut',
                        data: {
                            labels: ['Bookings', 'Check-ins', 'Check-outs', 'New Guests'],
                            datasets: [{
                                data: [<%= monthlyBookings %>, <%= monthlyCheckIns %>, <%= monthlyCheckOuts %>, <%= monthlyGuests %>],
                                backgroundColor: ['#667eea', '#28a745', '#dc3545', '#f093fb'],
                                borderWidth: 2,
                                borderColor: '#fff'
                            }]
                        },
                        options: { 
                            responsive: true, 
                            maintainAspectRatio: false,
                            plugins: { legend: { position: 'bottom', labels: { padding: 15 } } },
                            cutout: '55%'
                        }
                    });
                }
                chartsInitialized.monthly = true;
            }
        }
        
        // Initialize on load
        document.addEventListener('DOMContentLoaded', function() {
            // Set initial data-period
            const downloadBtn = document.getElementById('downloadPdfBtn');
            if (downloadBtn) {
                downloadBtn.setAttribute('data-period', 'daily');
            }
            
            // Initialize daily charts by default
            initializeCharts('daily');
            
            // Check if search tab should be active
            <% if (hasSearch) { %>
            showReportTab('search');
            <% } %>
        });
    </script>
    
    <% if (conn != null) { try { conn.close(); } catch (SQLException e) {} } %>
</body>
</html>
