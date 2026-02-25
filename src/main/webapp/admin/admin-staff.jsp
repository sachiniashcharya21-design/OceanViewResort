<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
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
    // Check if user is logged in and is admin
    String userRole = (String) session.getAttribute("userRole");
    String username = (String) session.getAttribute("username");
    
    if (username == null || userRole == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?role=admin");
        return;
    }
    if (!"ADMIN".equalsIgnoreCase(userRole)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }
    
    // Database connection
    Connection conn = null;
    String dbUrl = "jdbc:mysql://localhost:3306/ocean_view_resort";
    String dbUser = "root";
    String dbPass = "";
    
    String successMessage = (String) session.getAttribute("staffSuccessMessage");
    String errorMessage = (String) session.getAttribute("staffErrorMessage");
    if (successMessage != null) session.removeAttribute("staffSuccessMessage");
    if (errorMessage != null) session.removeAttribute("staffErrorMessage");
    
    // Statistics
    int totalStaff = 0, activeStaff = 0, onLeaveStaff = 0, inactiveStaff = 0;
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        // Handle form submissions
        String action = request.getParameter("action");
        
        // Add Staff
        if ("addStaff".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            String firstName = request.getParameter("firstName");
            String lastName = request.getParameter("lastName");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String position = request.getParameter("position");
            String department = request.getParameter("department");
            String salaryStr = request.getParameter("salary");
            double salary = (salaryStr != null && !salaryStr.isEmpty()) ? Double.parseDouble(salaryStr) : 0;
            String hireDate = request.getParameter("hireDate");
            String status = request.getParameter("status");
            String address = request.getParameter("address");
            String loginUsername = request.getParameter("loginUsername");
            String loginPassword = request.getParameter("loginPassword");
            String confirmLoginPassword = request.getParameter("confirmLoginPassword");

            if (loginUsername != null) loginUsername = loginUsername.trim();

            if (loginUsername == null || loginUsername.isEmpty() || loginPassword == null || loginPassword.isEmpty()) {
                errorMessage = "Username and password are required for staff dashboard login.";
            } else if (loginPassword.length() < 6) {
                errorMessage = "Password must be at least 6 characters.";
            } else if (!loginPassword.equals(confirmLoginPassword)) {
                errorMessage = "Password confirmation does not match.";
            }

            PreparedStatement checkPs = conn.prepareStatement("SELECT staff_id FROM staff WHERE email = ?");
            checkPs.setString(1, email);
            ResultSet checkRs = checkPs.executeQuery();

            if (errorMessage != null) {
                // Validation error already set.
            } else if (checkRs.next()) {
                errorMessage = "Email '" + email + "' already exists.";
            } else {
                PreparedStatement userCheckPs = conn.prepareStatement("SELECT user_id FROM users WHERE username = ?");
                userCheckPs.setString(1, loginUsername);
                ResultSet userCheckRs = userCheckPs.executeQuery();

                if (userCheckRs.next()) {
                    errorMessage = "Username '" + loginUsername + "' already exists.";
                } else {
                    boolean originalAutoCommit = conn.getAutoCommit();
                    conn.setAutoCommit(false);
                    try {
                        PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO staff (first_name, last_name, email, phone, position, department, salary, hire_date, status, address) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
                        );
                        ps.setString(1, firstName);
                        ps.setString(2, lastName);
                        ps.setString(3, email);
                        ps.setString(4, phone);
                        ps.setString(5, position);
                        ps.setString(6, department);
                        ps.setDouble(7, salary);
                        if (hireDate != null && !hireDate.trim().isEmpty()) {
                            ps.setDate(8, java.sql.Date.valueOf(hireDate));
                        } else {
                            ps.setNull(8, java.sql.Types.DATE);
                        }
                        ps.setString(9, status);
                        ps.setString(10, address);
                        ps.executeUpdate();
                        ps.close();

                        PreparedStatement userInsertPs = conn.prepareStatement(
                            "INSERT INTO users (username, password, password_hash, role, full_name, email, phone, address, hire_date, status) VALUES (?, ?, SHA2(?, 256), 'STAFF', ?, ?, ?, ?, ?, ?)"
                        );
                        userInsertPs.setString(1, loginUsername);
                        userInsertPs.setString(2, loginPassword);
                        userInsertPs.setString(3, loginPassword);
                        userInsertPs.setString(4, (firstName != null ? firstName : "") + " " + (lastName != null ? lastName : ""));
                        userInsertPs.setString(5, email);
                        userInsertPs.setString(6, phone);
                        userInsertPs.setString(7, address);
                        if (hireDate != null && !hireDate.trim().isEmpty()) {
                            userInsertPs.setDate(8, java.sql.Date.valueOf(hireDate));
                        } else {
                            userInsertPs.setNull(8, java.sql.Types.DATE);
                        }
                        userInsertPs.setString(9, "ACTIVE".equalsIgnoreCase(status) ? "ACTIVE" : "INACTIVE");
                        userInsertPs.executeUpdate();
                        userInsertPs.close();

                        conn.commit();
                        successMessage = "Staff member '" + firstName + " " + lastName + "' added with dashboard login successfully!";
                    } catch (Exception txEx) {
                        conn.rollback();
                        throw txEx;
                    } finally {
                        conn.setAutoCommit(originalAutoCommit);
                    }
                }

                userCheckRs.close();
                userCheckPs.close();
            }

            checkRs.close();
            checkPs.close();
        }
        
        // Edit Staff
        if ("editStaff".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            int staffId = Integer.parseInt(request.getParameter("staffId"));
            String firstName = request.getParameter("firstName");
            String lastName = request.getParameter("lastName");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String position = request.getParameter("position");
            String department = request.getParameter("department");
            String salaryStr = request.getParameter("salary");
            double salary = (salaryStr != null && !salaryStr.isEmpty()) ? Double.parseDouble(salaryStr) : 0;
            String hireDate = request.getParameter("hireDate");
            String status = request.getParameter("status");
            String address = request.getParameter("address");
            
            // Check if email exists for other staff
            PreparedStatement checkPs = conn.prepareStatement("SELECT staff_id FROM staff WHERE email = ? AND staff_id != ?");
            checkPs.setString(1, email);
            checkPs.setInt(2, staffId);
            ResultSet checkRs = checkPs.executeQuery();
            
            if (checkRs.next()) {
                errorMessage = "Email '" + email + "' already exists.";
            } else {
                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE staff SET first_name = ?, last_name = ?, email = ?, phone = ?, position = ?, department = ?, salary = ?, hire_date = ?, status = ?, address = ? WHERE staff_id = ?"
                );
                ps.setString(1, firstName);
                ps.setString(2, lastName);
                ps.setString(3, email);
                ps.setString(4, phone);
                ps.setString(5, position);
                ps.setString(6, department);
                ps.setDouble(7, salary);
                if (hireDate != null && !hireDate.trim().isEmpty()) {
                    ps.setDate(8, java.sql.Date.valueOf(hireDate));
                } else {
                    ps.setNull(8, java.sql.Types.DATE);
                }
                ps.setString(9, status);
                ps.setString(10, address);
                ps.setInt(11, staffId);
                ps.executeUpdate();
                ps.close();
                successMessage = "Staff member updated successfully!";
            }
            checkRs.close();
            checkPs.close();
        }
        
        // Delete Staff
        if ("deleteStaff".equals(action)) {
            int staffId = Integer.parseInt(request.getParameter("staffId"));
            PreparedStatement ps = conn.prepareStatement("DELETE FROM staff WHERE staff_id = ?");
            ps.setInt(1, staffId);
            ps.executeUpdate();
            ps.close();
            successMessage = "Staff member deleted successfully!";
        }
        
        // Get statistics
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM staff");
        if (rs.next()) totalStaff = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM staff WHERE status = 'ACTIVE'");
        if (rs.next()) activeStaff = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM staff WHERE status = 'ON_LEAVE'");
        if (rs.next()) onLeaveStaff = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM staff WHERE status = 'INACTIVE'");
        if (rs.next()) inactiveStaff = rs.getInt(1);
        rs.close();

        boolean redirectAfterAction =
            ("addStaff".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) ||
            ("editStaff".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) ||
            "deleteStaff".equals(action);
        if (redirectAfterAction) {
            if (successMessage != null) session.setAttribute("staffSuccessMessage", successMessage);
            if (errorMessage != null) session.setAttribute("staffErrorMessage", errorMessage);
            if (conn != null) { try { conn.close(); } catch (Exception ignore) {} }
            response.sendRedirect(request.getContextPath() + "/admin/admin-staff.jsp");
            return;
        }
        
        stmt.close();
    } catch (Exception e) {
        errorMessage = "Error: " + e.getMessage();
        e.printStackTrace();
    }
    
    DecimalFormat df = new DecimalFormat("#,###.00");
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Staff Management - Ocean View Resort Admin</title>
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
        
        .btn-add {
            background: var(--glow);
            color: var(--primary-dark);
        }
        
        .btn-add:hover {
            background: #00e6e6;
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0, 192, 192, 0.4);
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
        
        .stat-icon.total { background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%); color: white; }
        .stat-icon.active { background: linear-gradient(135deg, #10b981 0%, #34d399 100%); color: white; }
        .stat-icon.leave { background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%); color: white; }
        .stat-icon.inactive { background: linear-gradient(135deg, #ef4444 0%, #f87171 100%); color: white; }
        
        .stat-info h3 {
            font-size: 26px;
            font-weight: 700;
            color: var(--text);
        }
        
        .stat-info p {
            font-size: 13px;
            color: var(--text-light);
        }
        
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
        
        .table-header h3 {
            font-size: 18px;
            font-weight: 600;
            color: var(--text);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .table-header h3 i { color: var(--primary); }
        
        .filters {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .search-box {
            position: relative;
            width: 250px;
        }
        
        .search-box input {
            width: 100%;
            padding: 10px 15px 10px 40px;
            border: 2px solid var(--border);
            border-radius: 8px;
            font-size: 14px;
            font-family: 'Poppins', sans-serif;
            transition: all 0.3s ease;
        }
        
        .search-box input:focus {
            border-color: var(--primary);
            outline: none;
        }
        
        .search-box i {
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-light);
        }
        
        .filter-select {
            padding: 10px 15px;
            border: 2px solid var(--border);
            border-radius: 8px;
            font-size: 14px;
            font-family: 'Poppins', sans-serif;
            background: white;
            cursor: pointer;
        }
        
        .filter-select:focus {
            border-color: var(--primary);
            outline: none;
        }
        
        .table-wrapper {
            overflow-x: auto;
        }
        
        .data-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .data-table th, .data-table td {
            padding: 15px 20px;
            text-align: left;
            border-bottom: 1px solid var(--border);
        }
        
        .data-table th {
            background: #f8f9fa;
            font-weight: 600;
            color: var(--text);
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            white-space: nowrap;
        }
        
        .data-table tbody tr {
            transition: background 0.2s ease;
        }
        
        .data-table tbody tr:hover {
            background: #f8f9fa;
        }
        
        .staff-name {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .staff-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--primary) 0%, var(--glow) 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 14px;
        }
        
        .staff-details h4 {
            font-weight: 600;
            color: var(--text);
            font-size: 14px;
        }
        
        .staff-details p {
            font-size: 12px;
            color: var(--text-light);
        }
        
        .position-badge {
            background: #e8f5f5;
            padding: 6px 12px;
            border-radius: 15px;
            font-size: 12px;
            color: var(--primary-dark);
            font-weight: 500;
        }
        
        .department-badge {
            background: #f0f0f0;
            padding: 4px 10px;
            border-radius: 10px;
            font-size: 11px;
            color: var(--text);
        }
        
        .status-badge {
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .status-badge.active {
            background: #d4edda;
            color: #155724;
        }
        
        .status-badge.on_leave {
            background: #fff3cd;
            color: #856404;
        }
        
        .status-badge.inactive {
            background: #f8d7da;
            color: #721c24;
        }
        
        .salary-value {
            font-weight: 600;
            color: var(--primary);
        }
        
        .action-btn {
            width: 36px;
            height: 36px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-right: 5px;
        }
        
        .action-btn.view { background: #e3f2fd; color: #1976d2; }
        .action-btn.edit { background: #fff3e0; color: #f57c00; }
        .action-btn.delete { background: #ffebee; color: #e53935; }
        
        .action-btn:hover { transform: scale(1.1); }
        
        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
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
        
        /* Modal Styles */
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
        
        .modal-overlay.active {
            opacity: 1;
            visibility: visible;
        }
        
        .modal {
            background: white;
            border-radius: 20px;
            width: 100%;
            max-width: 650px;
            max-height: 90vh;
            overflow: hidden;
            transform: scale(0.9);
            transition: transform 0.3s ease;
        }
        
        .modal-overlay.active .modal {
            transform: scale(1);
        }
        
        .modal-header {
            padding: 25px 30px;
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
            color: white;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-header h3 {
            font-size: 20px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
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
        
        .modal-close:hover {
            background: rgba(255,255,255,0.3);
            transform: rotate(90deg);
        }
        
        .modal-body {
            padding: 30px;
            max-height: 60vh;
            overflow-y: auto;
        }
        
        .modal-footer {
            padding: 20px 30px;
            background: #f8f9fa;
            display: flex;
            justify-content: flex-end;
            gap: 15px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }

        .form-section-title {
            margin: 10px 0 15px;
            padding-bottom: 8px;
            border-bottom: 1px solid var(--border);
            font-size: 14px;
            font-weight: 600;
            color: var(--primary-dark);
            letter-spacing: 0.3px;
            text-transform: uppercase;
        }

        .form-help-text {
            margin-top: -8px;
            margin-bottom: 15px;
            color: var(--text-light);
            font-size: 12px;
        }
        
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        
        @media (max-width: 500px) {
            .form-row { grid-template-columns: 1fr; }
        }
        
        .form-group label {
            display: block;
            font-weight: 500;
            color: var(--text);
            font-size: 14px;
            margin-bottom: 8px;
        }
        
        .form-group label i {
            color: var(--primary);
            margin-right: 6px;
        }
        
        .form-control {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid var(--border);
            border-radius: 10px;
            font-size: 14px;
            font-family: 'Poppins', sans-serif;
            transition: all 0.3s ease;
        }
        
        .form-control:focus {
            border-color: var(--primary);
            outline: none;
            box-shadow: 0 0 0 3px rgba(0, 128, 128, 0.1);
        }
        
        textarea.form-control {
            min-height: 80px;
            resize: vertical;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
            color: white;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(0, 128, 128, 0.3);
        }
        
        .btn-secondary {
            background: #e0e0e0;
            color: var(--text);
        }
        
        .btn-secondary:hover {
            background: #d0d0d0;
        }
        
        /* View Modal */
        .view-detail {
            display: flex;
            padding: 12px 0;
            border-bottom: 1px solid var(--border);
        }
        
        .view-detail:last-child {
            border-bottom: none;
        }
        
        .view-detail label {
            width: 140px;
            font-weight: 500;
            color: var(--text-light);
            font-size: 14px;
        }
        
        .view-detail span {
            flex: 1;
            color: var(--text);
            font-size: 14px;
        }
        
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
        
        .view-title h2 {
            font-size: 24px;
            color: var(--primary-dark);
            margin-bottom: 5px;
        }
        
        .view-title p {
            font-size: 14px;
            color: var(--text-light);
        }
        
        /* Responsive */
        @media (max-width: 768px) {
            .header {
                padding: 15px 20px;
                flex-direction: column;
                gap: 15px;
            }
            
            .table-header {
                flex-direction: column;
                align-items: flex-start;
            }
            
            .filters {
                width: 100%;
            }
            
            .search-box {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="header-left">
            <h1><i class="fas fa-users-cog"></i> Staff Management</h1>
        </div>
        <div class="header-actions">
            <a href="<%= request.getContextPath() %>/admin/admin-dashboard.jsp" class="btn btn-back"><i class="fas fa-arrow-left"></i> Back to Dashboard</a>
            <button class="btn btn-add" onclick="openAddModal()"><i class="fas fa-plus"></i> Add Staff</button>
        </div>
    </header>
    
    <!-- Main Content -->
    <main class="main-content">
        <!-- Stats Cards -->
        <div class="stats-grid">
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
                    <p>Active</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon leave"><i class="fas fa-user-clock"></i></div>
                <div class="stat-info">
                    <h3><%= onLeaveStaff %></h3>
                    <p>On Leave</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon inactive"><i class="fas fa-user-times"></i></div>
                <div class="stat-info">
                    <h3><%= inactiveStaff %></h3>
                    <p>Inactive</p>
                </div>
            </div>
        </div>
        
        <!-- Staff Table -->
        <div class="table-card">
            <div class="table-header">
                <h3><i class="fas fa-list"></i> All Staff Members</h3>
                <div class="filters">
                    <div class="search-box">
                        <i class="fas fa-search"></i>
                        <input type="text" id="searchInput" placeholder="Search staff..." onkeyup="filterTable()">
                    </div>
                    <select class="filter-select" id="statusFilter" onchange="filterTable()">
                        <option value="">All Status</option>
                        <option value="ACTIVE">Active</option>
                        <option value="ON_LEAVE">On Leave</option>
                        <option value="INACTIVE">Inactive</option>
                    </select>
                    <select class="filter-select" id="deptFilter" onchange="filterTable()">
                        <option value="">All Departments</option>
                        <option value="Front Office">Front Office</option>
                        <option value="Kitchen">Kitchen</option>
                        <option value="Housekeeping">Housekeeping</option>
                        <option value="Finance">Finance</option>
                        <option value="Security">Security</option>
                        <option value="Wellness">Wellness</option>
                        <option value="Maintenance">Maintenance</option>
                    </select>
                </div>
            </div>
            <div class="table-wrapper">
                <table class="data-table" id="staffTable">
                    <thead>
                        <tr>
                            <th>Staff Member</th>
                            <th>Username</th>
                            <th>Password</th>
                            <th>Position</th>
                            <th>Department</th>
                            <th>Phone</th>
                            <th>Salary</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                Statement staffStmt = conn.createStatement();
                                ResultSet staffRs = staffStmt.executeQuery("SELECT s.*, u.username, u.password AS login_password FROM staff s LEFT JOIN users u ON u.email = s.email AND u.role = 'STAFF' ORDER BY s.first_name");
                                boolean hasStaff = false;
                                while (staffRs.next()) {
                                    hasStaff = true;
                                    int staffId = staffRs.getInt("staff_id");
                                    String firstName = staffRs.getString("first_name");
                                    String lastName = staffRs.getString("last_name");
                                    String email = staffRs.getString("email");
                                    String phone = staffRs.getString("phone");
                                    String position = staffRs.getString("position");
                                    String department = staffRs.getString("department");
                                    double salary = staffRs.getDouble("salary");
                                    Date hireDate = staffRs.getDate("hire_date");
                                    String status = staffRs.getString("status");
                                    String address = staffRs.getString("address");
                                    String loginUsername = staffRs.getString("username");
                                    String loginPassword = staffRs.getString("login_password");
                                    
                                    String initials = "" + firstName.charAt(0) + lastName.charAt(0);
                                    String statusClass = status.toLowerCase();
                                    String hireDateStr = hireDate != null ? sdf.format(hireDate) : "";
                        %>
                        <tr data-status="<%= status %>" data-dept="<%= department != null ? department : "" %>">
                            <td>
                                <div class="staff-name">
                                    <div class="staff-avatar"><%= initials %></div>
                                    <div class="staff-details">
                                        <h4><%= firstName %> <%= lastName %></h4>
                                        <p><%= email %></p>
                                    </div>
                                </div>
                            </td>
                            <td><%= (loginUsername != null && !loginUsername.trim().isEmpty()) ? loginUsername : "-" %></td>
                            <td><%= (loginPassword != null && !loginPassword.trim().isEmpty()) ? "********" : "-" %></td>
                            <td><span class="position-badge"><%= position %></span></td>
                            <td><span class="department-badge"><%= department != null ? department : "-" %></span></td>
                            <td><%= phone != null ? phone : "-" %></td>
                            <td class="salary-value">LKR <%= df.format(salary) %></td>
                            <td><span class="status-badge <%= statusClass %>"><%= status.replace("_", " ") %></span></td>
                            <td>
                                <button class="action-btn view" title="View" onclick="viewStaff('<%= escapeJs(firstName) %>', '<%= escapeJs(lastName) %>', '<%= escapeJs(email) %>', '<%= escapeJs(phone != null ? phone : "") %>', '<%= escapeJs(position) %>', '<%= escapeJs(department != null ? department : "") %>', <%= salary %>, '<%= escapeJs(hireDateStr) %>', '<%= escapeJs(status) %>', '<%= escapeJs(address != null ? address : "") %>')"><i class="fas fa-eye"></i></button>
                                <button class="action-btn edit" title="Edit" onclick="editStaff(<%= staffId %>, '<%= escapeJs(firstName) %>', '<%= escapeJs(lastName) %>', '<%= escapeJs(email) %>', '<%= escapeJs(phone != null ? phone : "") %>', '<%= escapeJs(position) %>', '<%= escapeJs(department != null ? department : "") %>', <%= salary %>, '<%= escapeJs(hireDateStr) %>', '<%= escapeJs(status) %>', '<%= escapeJs(address != null ? address : "") %>')"><i class="fas fa-edit"></i></button>
                                <button class="action-btn delete" title="Delete" onclick="deleteStaff(<%= staffId %>, '<%= escapeJs(firstName + " " + lastName) %>')"><i class="fas fa-trash"></i></button>
                            </td>
                        </tr>
                        <%
                                }
                                if (!hasStaff) {
                        %>
                        <tr>
                            <td colspan="9">
                                <div class="empty-state">
                                    <i class="fas fa-users"></i>
                                    <h3>No Staff Members Found</h3>
                                    <p>Click "Add Staff" to add your first staff member.</p>
                                </div>
                            </td>
                        </tr>
                        <%
                                }
                                staffRs.close();
                                staffStmt.close();
                            } catch (Exception e) {
                                out.println("<tr><td colspan='9'>Error loading staff: " + e.getMessage() + "</td></tr>");
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
    
    <!-- Add Staff Modal -->
    <div class="modal-overlay" id="addStaffModal">
        <div class="modal">
            <div class="modal-header">
                <h3><i class="fas fa-user-plus"></i> Add Staff Member</h3>
                <button class="modal-close" onclick="closeModal('addStaffModal')">&times;</button>
            </div>
            <form method="POST" action="<%= request.getContextPath() %>/admin/admin-staff.jsp">
                <input type="hidden" name="action" value="addStaff">
                <div class="modal-body">
                    <div class="form-section-title">Personal Information</div>
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-user"></i> First Name *</label>
                            <input type="text" name="firstName" class="form-control" placeholder="e.g., Kamal" required>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-user"></i> Last Name *</label>
                            <input type="text" name="lastName" class="form-control" placeholder="e.g., Perera" required>
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-envelope"></i> Email *</label>
                            <input type="email" name="email" class="form-control" placeholder="email@oceanview.lk" required>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-phone"></i> Phone</label>
                            <input type="tel" name="phone" class="form-control" placeholder="07X XXXXXXX">
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-briefcase"></i> Position *</label>
                            <input type="text" name="position" class="form-control" placeholder="e.g., Receptionist" required>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-building"></i> Department</label>
                            <select name="department" class="form-control">
                                <option value="">Select Department</option>
                                <option value="Front Office">Front Office</option>
                                <option value="Kitchen">Kitchen</option>
                                <option value="Housekeeping">Housekeeping</option>
                                <option value="Finance">Finance</option>
                                <option value="Security">Security</option>
                                <option value="Wellness">Wellness</option>
                                <option value="Maintenance">Maintenance</option>
                                <option value="Management">Management</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-money-bill-wave"></i> Salary (LKR)</label>
                            <input type="number" name="salary" class="form-control" min="0" step="1000" placeholder="50000">
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-calendar"></i> Hire Date</label>
                            <input type="date" name="hireDate" class="form-control">
                        </div>
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-toggle-on"></i> Status *</label>
                        <select name="status" class="form-control" required>
                            <option value="ACTIVE">Active</option>
                            <option value="ON_LEAVE">On Leave</option>
                            <option value="INACTIVE">Inactive</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-map-marker-alt"></i> Address</label>
                        <textarea name="address" class="form-control" placeholder="Full address..."></textarea>
                    </div>

                    <div class="form-section-title">Dashboard Login Credentials</div>
                    <p class="form-help-text">These credentials will be used by the staff member to log in to the staff dashboard.</p>
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-user-circle"></i> Username *</label>
                            <input type="text" name="loginUsername" class="form-control" placeholder="e.g., kamal.perera" required>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-key"></i> Password *</label>
                            <input type="password" name="loginPassword" class="form-control" minlength="6" placeholder="Minimum 6 characters" required>
                        </div>
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-key"></i> Confirm Password *</label>
                        <input type="password" name="confirmLoginPassword" class="form-control" minlength="6" placeholder="Re-enter password" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('addStaffModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Add Staff</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Edit Staff Modal -->
    <div class="modal-overlay" id="editStaffModal">
        <div class="modal">
            <div class="modal-header">
                <h3><i class="fas fa-user-edit"></i> Edit Staff Member</h3>
                <button class="modal-close" onclick="closeModal('editStaffModal')">&times;</button>
            </div>
            <form method="POST" action="<%= request.getContextPath() %>/admin/admin-staff.jsp">
                <input type="hidden" name="action" value="editStaff">
                <input type="hidden" name="staffId" id="editStaffId">
                <div class="modal-body">
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-user"></i> First Name *</label>
                            <input type="text" name="firstName" id="editFirstName" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-user"></i> Last Name *</label>
                            <input type="text" name="lastName" id="editLastName" class="form-control" required>
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-envelope"></i> Email *</label>
                            <input type="email" name="email" id="editEmail" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-phone"></i> Phone</label>
                            <input type="tel" name="phone" id="editPhone" class="form-control">
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-briefcase"></i> Position *</label>
                            <input type="text" name="position" id="editPosition" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-building"></i> Department</label>
                            <select name="department" id="editDepartment" class="form-control">
                                <option value="">Select Department</option>
                                <option value="Front Office">Front Office</option>
                                <option value="Kitchen">Kitchen</option>
                                <option value="Housekeeping">Housekeeping</option>
                                <option value="Finance">Finance</option>
                                <option value="Security">Security</option>
                                <option value="Wellness">Wellness</option>
                                <option value="Maintenance">Maintenance</option>
                                <option value="Management">Management</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label><i class="fas fa-money-bill-wave"></i> Salary (LKR)</label>
                            <input type="number" name="salary" id="editSalary" class="form-control" min="0" step="1000">
                        </div>
                        <div class="form-group">
                            <label><i class="fas fa-calendar"></i> Hire Date</label>
                            <input type="date" name="hireDate" id="editHireDate" class="form-control">
                        </div>
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-toggle-on"></i> Status *</label>
                        <select name="status" id="editStatus" class="form-control" required>
                            <option value="ACTIVE">Active</option>
                            <option value="ON_LEAVE">On Leave</option>
                            <option value="INACTIVE">Inactive</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label><i class="fas fa-map-marker-alt"></i> Address</label>
                        <textarea name="address" id="editAddress" class="form-control"></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('editStaffModal')">Cancel</button>
                    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Save Changes</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- View Staff Modal -->
    <div class="modal-overlay" id="viewStaffModal">
        <div class="modal">
            <div class="modal-header">
                <h3><i class="fas fa-user"></i> Staff Details</h3>
                <button class="modal-close" onclick="closeModal('viewStaffModal')">&times;</button>
            </div>
            <div class="modal-body">
                <div class="view-header">
                    <div class="view-avatar" id="viewAvatar"></div>
                    <div class="view-title">
                        <h2 id="viewName"></h2>
                        <p id="viewPosition"></p>
                    </div>
                </div>
                <div class="view-detail"><label>Email</label><span id="viewEmail"></span></div>
                <div class="view-detail"><label>Phone</label><span id="viewPhone"></span></div>
                <div class="view-detail"><label>Department</label><span id="viewDepartment"></span></div>
                <div class="view-detail"><label>Salary</label><span id="viewSalary"></span></div>
                <div class="view-detail"><label>Hire Date</label><span id="viewHireDate"></span></div>
                <div class="view-detail"><label>Status</label><span id="viewStatus"></span></div>
                <div class="view-detail"><label>Address</label><span id="viewAddress"></span></div>
            </div>
        </div>
    </div>
    
    <script>
        // Filter table
        function filterTable() {
            const search = document.getElementById('searchInput').value.toLowerCase();
            const statusFilter = document.getElementById('statusFilter').value;
            const deptFilter = document.getElementById('deptFilter').value;
            const rows = document.querySelectorAll('#staffTable tbody tr');
            
            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                const status = row.dataset.status;
                const dept = row.dataset.dept;
                
                const matchSearch = text.includes(search);
                const matchStatus = !statusFilter || status === statusFilter;
                const matchDept = !deptFilter || dept === deptFilter;
                
                row.style.display = (matchSearch && matchStatus && matchDept) ? '' : 'none';
            });
        }
        
        // Modal functions
        function openModal(id) {
            document.getElementById(id).classList.add('active');
        }
        
        function closeModal(id) {
            document.getElementById(id).classList.remove('active');
        }
        
        function openAddModal() {
            document.querySelector('#addStaffModal form').reset();
            openModal('addStaffModal');
        }
        
        // View staff
        function viewStaff(firstName, lastName, email, phone, position, department, salary, hireDate, status, address) {
            document.getElementById('viewAvatar').textContent = firstName.charAt(0) + lastName.charAt(0);
            document.getElementById('viewName').textContent = firstName + ' ' + lastName;
            document.getElementById('viewPosition').textContent = position;
            document.getElementById('viewEmail').textContent = email;
            document.getElementById('viewPhone').textContent = phone || '-';
            document.getElementById('viewDepartment').textContent = department || '-';
            document.getElementById('viewSalary').textContent = 'LKR ' + new Intl.NumberFormat().format(salary);
            document.getElementById('viewHireDate').textContent = hireDate || '-';
            document.getElementById('viewStatus').innerHTML = '<span class="status-badge ' + status.toLowerCase() + '">' + status.replace('_', ' ') + '</span>';
            document.getElementById('viewAddress').textContent = address || '-';
            openModal('viewStaffModal');
        }
        
        // Edit staff
        function editStaff(id, firstName, lastName, email, phone, position, department, salary, hireDate, status, address) {
            document.getElementById('editStaffId').value = id;
            document.getElementById('editFirstName').value = firstName;
            document.getElementById('editLastName').value = lastName;
            document.getElementById('editEmail').value = email;
            document.getElementById('editPhone').value = phone;
            document.getElementById('editPosition').value = position;
            document.getElementById('editDepartment').value = department;
            document.getElementById('editSalary').value = salary;
            document.getElementById('editHireDate').value = hireDate;
            document.getElementById('editStatus').value = status;
            document.getElementById('editAddress').value = address;
            openModal('editStaffModal');
        }
        
        // Delete staff
        function deleteStaff(id, name) {
            Swal.fire({
                title: 'Delete ' + name + '?',
                text: 'This action cannot be undone!',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#dc3545',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, delete!'
            }).then((result) => {
                if (result.isConfirmed) {
                    window.location.href = '<%= request.getContextPath() %>/admin/admin-staff.jsp?action=deleteStaff&staffId=' + id;
                }
            });
        }
        
        // Close modal on outside click
        document.querySelectorAll('.modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', function(e) {
                if (e.target === this) this.classList.remove('active');
            });
        });
        
        // Show alerts
        <% if (successMessage != null) { %>
        Swal.fire({icon: 'success', title: 'Success!', text: '<%= escapeJs(successMessage) %>', confirmButtonColor: '#008080'});
        <% } %>
        <% if (errorMessage != null) { %>
        Swal.fire({icon: 'error', title: 'Error', text: '<%= escapeJs(errorMessage) %>', confirmButtonColor: '#008080'});
        <% } %>
    </script>
</body>
</html>
<%
    if (conn != null) {
        try { conn.close(); } catch (Exception e) {}
    }
%>
