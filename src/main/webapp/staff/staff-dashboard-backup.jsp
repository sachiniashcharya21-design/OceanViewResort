<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.io.*" %>
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
    
    // Database connection
    Connection conn = null;
    String dbUrl = "jdbc:mysql://localhost:3306/ocean_view_resort";
    String dbUser = "root";
    String dbPass = "";
    
    String profilePic = null;
    String email = "", phone = "", address = "", hireDate = "", status = "";
    String successMessage = null, errorMessage = null;
    
    // Statistics
    int myReservations = 0, totalGuests = 0, totalRooms = 0, todayCheckIns = 0;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        // Handle form submissions
        String action = request.getParameter("action");
        
        if ("updateProfile".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            String newFullName = request.getParameter("fullName");
            String newUsername = request.getParameter("username");
            String newEmail = request.getParameter("email");
            String newPhone = request.getParameter("phone");
            String newAddress = request.getParameter("address");
            
            // Check if username already exists (excluding current user)
            PreparedStatement checkPs = conn.prepareStatement("SELECT user_id FROM users WHERE username = ? AND user_id != ?");
            checkPs.setString(1, newUsername);
            checkPs.setInt(2, userId);
            ResultSet checkRs = checkPs.executeQuery();
            
            if (checkRs.next()) {
                errorMessage = "Username already taken by another user.";
            } else {
                PreparedStatement updatePs = conn.prepareStatement(
                    "UPDATE users SET full_name = ?, username = ?, email = ?, phone = ?, address = ? WHERE user_id = ?"
                );
                updatePs.setString(1, newFullName);
                updatePs.setString(2, newUsername);
                updatePs.setString(3, newEmail);
                updatePs.setString(4, newPhone);
                updatePs.setString(5, newAddress);
                updatePs.setInt(6, userId);
                updatePs.executeUpdate();
                updatePs.close();
                
                // Update session
                session.setAttribute("fullName", newFullName);
                session.setAttribute("username", newUsername);
                fullName = newFullName;
                username = newUsername;
                successMessage = "Profile updated successfully!";
            }
            checkRs.close();
            checkPs.close();
        }
        
        if ("changePassword".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            String currentPassword = request.getParameter("currentPassword");
            String newPassword = request.getParameter("newPassword");
            String confirmPassword = request.getParameter("confirmPassword");
            
            // Verify current password
            PreparedStatement verifyPs = conn.prepareStatement("SELECT password FROM users WHERE user_id = ?");
            verifyPs.setInt(1, userId);
            ResultSet verifyRs = verifyPs.executeQuery();
            
            if (verifyRs.next()) {
                String storedPassword = verifyRs.getString("password");
                if (!storedPassword.equals(currentPassword)) {
                    errorMessage = "Current password is incorrect.";
                } else if (!newPassword.equals(confirmPassword)) {
                    errorMessage = "New passwords do not match.";
                } else if (newPassword.length() < 6) {
                    errorMessage = "Password must be at least 6 characters.";
                } else {
                    PreparedStatement updatePs = conn.prepareStatement("UPDATE users SET password = ? WHERE user_id = ?");
                    updatePs.setString(1, newPassword);
                    updatePs.setInt(2, userId);
                    updatePs.executeUpdate();
                    updatePs.close();
                    successMessage = "Password changed successfully!";
                }
            }
            verifyRs.close();
            verifyPs.close();
        }
        
        // Get user details
        PreparedStatement psProfile = conn.prepareStatement("SELECT * FROM users WHERE user_id = ?");
        psProfile.setInt(1, userId);
        ResultSet rsProfile = psProfile.executeQuery();
        if (rsProfile.next()) {
            profilePic = rsProfile.getString("profile_picture");
            email = rsProfile.getString("email") != null ? rsProfile.getString("email") : "";
            phone = rsProfile.getString("phone") != null ? rsProfile.getString("phone") : "";
            address = rsProfile.getString("address") != null ? rsProfile.getString("address") : "";
            status = rsProfile.getString("status") != null ? rsProfile.getString("status") : "ACTIVE";
            java.sql.Date hd = rsProfile.getDate("hire_date");
            if (hd != null) hireDate = new SimpleDateFormat("MMMM dd, yyyy").format(hd);
        }
        rsProfile.close();
        psProfile.close();
        
        // Get statistics
        Statement stmt = conn.createStatement();
        
        // My reservations
        PreparedStatement psMyRes = conn.prepareStatement("SELECT COUNT(*) FROM reservations WHERE created_by = ?");
        psMyRes.setInt(1, userId);
        ResultSet rsMyRes = psMyRes.executeQuery();
        if (rsMyRes.next()) myReservations = rsMyRes.getInt(1);
        rsMyRes.close();
        psMyRes.close();
        
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM guests");
        if (rs.next()) totalGuests = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM rooms");
        if (rs.next()) totalRooms = rs.getInt(1);
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) FROM reservations WHERE check_in_date = CURDATE()");
        if (rs.next()) todayCheckIns = rs.getInt(1);
        rs.close();
        
        stmt.close();
    } catch (Exception e) {
        errorMessage = "Error: " + e.getMessage();
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile - Ocean View Resort Staff</title>
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
        }
        
        .header-left {
            display: flex;
            align-items: center;
            gap: 20px;
        }
        
        .header-left h1 {
            font-size: 24px;
            font-weight: 600;
        }
        
        .header-left h1 i { margin-right: 10px; }
        
        .back-btn {
            background: rgba(255,255,255,0.2);
            color: white;
            border: 1px solid rgba(255,255,255,0.3);
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            font-family: 'Poppins', sans-serif;
            font-weight: 500;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .back-btn:hover {
            background: rgba(255,255,255,0.3);
            transform: translateY(-2px);
        }
        
        /* Main Content */
        .main-content {
            max-width: 1200px;
            margin: 40px auto;
            padding: 0 20px;
        }
        
        .profile-grid {
            display: grid;
            grid-template-columns: 380px 1fr;
            gap: 30px;
        }
        
        @media (max-width: 900px) {
            .profile-grid { grid-template-columns: 1fr; }
        }
        
        /* Profile Card */
        .profile-card {
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
            border-radius: 20px;
            padding: 40px 30px;
            text-align: center;
            color: white;
            box-shadow: 0 15px 40px rgba(0, 64, 64, 0.3);
            position: relative;
            overflow: hidden;
        }
        
        .profile-card::before {
            content: '';
            position: absolute;
            top: -50%;
            right: -50%;
            width: 100%;
            height: 100%;
            background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%);
            pointer-events: none;
        }
        
        .avatar-container {
            position: relative;
            width: 160px;
            height: 160px;
            margin: 0 auto 25px;
        }
        
        .avatar {
            width: 160px;
            height: 160px;
            border-radius: 50%;
            border: 5px solid white;
            overflow: hidden;
            background: var(--bg);
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            cursor: pointer;
            transition: transform 0.3s ease;
        }
        
        .avatar:hover { transform: scale(1.05); }
        
        .avatar img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        
        .avatar i {
            font-size: 70px;
            color: var(--primary);
        }
        
        .avatar-overlay {
            position: absolute;
            bottom: 5px;
            right: 5px;
            width: 45px;
            height: 45px;
            background: var(--glow);
            border-radius: 50%;
            border: 3px solid white;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(0, 192, 192, 0.4);
        }
        
        .avatar-overlay:hover {
            background: #00e6e6;
            transform: scale(1.1);
        }
        
        .avatar-overlay i { color: white; font-size: 18px; }
        
        #profilePicInput { display: none; }
        
        .profile-name {
            font-size: 26px;
            font-weight: 700;
            margin-bottom: 5px;
        }
        
        .profile-username {
            font-size: 14px;
            opacity: 0.85;
            margin-bottom: 15px;
        }
        
        .profile-role {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: rgba(255,255,255,0.2);
            padding: 8px 20px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 500;
            margin-bottom: 15px;
        }
        
        .profile-status {
            display: inline-block;
            background: #00e676;
            color: #004d40;
            padding: 6px 18px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .profile-stats {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 15px;
            margin-top: 30px;
            padding-top: 25px;
            border-top: 1px solid rgba(255,255,255,0.2);
        }
        
        .stat-item {
            text-align: center;
        }
        
        .stat-value {
            font-size: 28px;
            font-weight: 700;
        }
        
        .stat-label {
            font-size: 12px;
            opacity: 0.85;
        }
        
        /* Details Section */
        .details-section {
            display: flex;
            flex-direction: column;
            gap: 25px;
        }
        
        .card {
            background: var(--card-bg);
            border-radius: 15px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            overflow: hidden;
        }
        
        .card-header {
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
            color: white;
            padding: 18px 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .card-header h3 {
            font-size: 18px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .card-body {
            padding: 25px;
        }
        
        /* Form Styles */
        .form-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 20px;
        }
        
        @media (max-width: 600px) {
            .form-grid { grid-template-columns: 1fr; }
        }
        
        .form-group {
            margin-bottom: 0;
        }
        
        .form-group.full-width {
            grid-column: 1 / -1;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            color: var(--text);
            font-size: 14px;
        }
        
        .form-group label i {
            margin-right: 8px;
            color: var(--primary);
        }
        
        .form-control {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid var(--border);
            border-radius: 10px;
            font-size: 15px;
            font-family: 'Poppins', sans-serif;
            transition: all 0.3s ease;
            background: #fafafa;
        }
        
        .form-control:focus {
            outline: none;
            border-color: var(--primary);
            background: white;
            box-shadow: 0 0 0 4px rgba(0, 128, 128, 0.1);
        }
        
        .form-control:read-only {
            background: #f0f0f0;
            cursor: not-allowed;
        }
        
        textarea.form-control {
            min-height: 80px;
            resize: vertical;
        }
        
        /* Buttons */
        .btn {
            padding: 12px 25px;
            border: none;
            border-radius: 10px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            font-family: 'Poppins', sans-serif;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
            color: white;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0, 128, 128, 0.4);
        }
        
        .btn-secondary {
            background: #e0e0e0;
            color: var(--text);
        }
        
        .btn-secondary:hover {
            background: #d0d0d0;
        }
        
        .btn-danger {
            background: var(--danger);
            color: white;
        }
        
        .btn-danger:hover {
            background: #c82333;
            box-shadow: 0 8px 25px rgba(220, 53, 69, 0.4);
        }
        
        .form-actions {
            display: flex;
            gap: 15px;
            justify-content: flex-end;
            margin-top: 25px;
            padding-top: 20px;
            border-top: 1px solid var(--border);
        }
        
        /* Info Grid */
        .info-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 20px;
        }
        
        @media (max-width: 600px) {
            .info-grid { grid-template-columns: 1fr; }
        }
        
        .info-item {
            background: var(--bg);
            border-radius: 12px;
            padding: 18px;
            border-left: 4px solid var(--primary);
        }
        
        .info-label {
            font-size: 12px;
            color: var(--text-light);
            text-transform: uppercase;
            margin-bottom: 5px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        
        .info-label i { color: var(--primary); }
        
        .info-value {
            font-size: 16px;
            font-weight: 500;
            color: var(--text);
            word-break: break-all;
        }
        
        /* Password Section */
        .password-requirements {
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 20px;
        }
        
        .password-requirements h4 {
            font-size: 14px;
            color: #856404;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .password-requirements ul {
            list-style: none;
            font-size: 13px;
            color: #856404;
        }
        
        .password-requirements ul li {
            margin-bottom: 5px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .password-requirements ul li i { font-size: 12px; }
        
        /* Alert Messages */
        .alert {
            padding: 15px 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .alert-danger {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        /* Upload Progress */
        .upload-progress {
            display: none;
            margin-top: 15px;
        }
        
        .progress-bar {
            height: 6px;
            background: #e0e0e0;
            border-radius: 3px;
            overflow: hidden;
        }
        
        .progress-fill {
            height: 100%;
            background: var(--glow);
            width: 0%;
            transition: width 0.3s ease;
        }
        
        .progress-text {
            font-size: 12px;
            color: var(--text-light);
            margin-top: 5px;
            text-align: center;
        }
    </style>
</head>
<body>
    <!-- Header -->
    <div class="header">
        <div class="header-left">
            <h1><i class="fas fa-user-circle"></i> My Profile</h1>
        </div>
        <a href="staff-dashboard.jsp" class="back-btn">
            <i class="fas fa-arrow-left"></i> Back to Dashboard
        </a>
    </div>
    
    <!-- Main Content -->
    <div class="main-content">
        <% if (successMessage != null) { %>
        <div class="alert alert-success">
            <i class="fas fa-check-circle"></i> <%= successMessage %>
        </div>
        <% } %>
        
        <% if (errorMessage != null) { %>
        <div class="alert alert-danger">
            <i class="fas fa-exclamation-circle"></i> <%= errorMessage %>
        </div>
        <% } %>
        
        <div class="profile-grid">
            <!-- Profile Card -->
            <div class="profile-card">
                <div class="avatar-container">
                    <div class="avatar" onclick="document.getElementById('profilePicInput').click()">
                        <% if (profilePic != null && !profilePic.isEmpty()) { %>
                            <img id="profileImage" src="${pageContext.request.contextPath}/uploads/profiles/<%= profilePic %>" alt="Profile">
                        <% } else { %>
                            <i class="fas fa-user" id="profileIcon"></i>
                        <% } %>
                    </div>
                    <div class="avatar-overlay" onclick="document.getElementById('profilePicInput').click()">
                        <i class="fas fa-camera"></i>
                    </div>
                </div>
                <input type="file" id="profilePicInput" accept="image/*" onchange="uploadProfilePic(this)">
                
                <div class="upload-progress" id="uploadProgress">
                    <div class="progress-bar"><div class="progress-fill" id="progressFill"></div></div>
                    <div class="progress-text" id="progressText">Uploading...</div>
                </div>
                
                <div class="profile-name"><%= fullName %></div>
                <div class="profile-username">@<%= username %></div>
                <div class="profile-role"><i class="fas fa-id-badge"></i> Staff Member</div>
                <br>
                <div class="profile-status"><i class="fas fa-circle"></i> <%= status %></div>
                
                <div class="profile-stats">
                    <div class="stat-item">
                        <div class="stat-value"><%= myReservations %></div>
                        <div class="stat-label">My Reservations</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-value"><%= totalGuests %></div>
                        <div class="stat-label">Total Guests</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-value"><%= totalRooms %></div>
                        <div class="stat-label">Rooms</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-value"><%= todayCheckIns %></div>
                        <div class="stat-label">Today Check-ins</div>
                    </div>
                </div>
            </div>
            
            <!-- Details Section -->
            <div class="details-section">
                <!-- Profile Information Card -->
                <div class="card">
                    <div class="card-header">
                        <h3><i class="fas fa-id-card"></i> Profile Information</h3>
                    </div>
                    <div class="card-body">
                        <form method="POST" action="staff-profile.jsp">
                            <input type="hidden" name="action" value="updateProfile">
                            
                            <div class="form-grid">
                                <div class="form-group">
                                    <label><i class="fas fa-user"></i> Full Name *</label>
                                    <input type="text" name="fullName" class="form-control" value="<%= fullName %>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label><i class="fas fa-at"></i> Username *</label>
                                    <input type="text" name="username" class="form-control" value="<%= username %>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label><i class="fas fa-envelope"></i> Email Address</label>
                                    <input type="email" name="email" class="form-control" value="<%= email %>">
                                </div>
                                
                                <div class="form-group">
                                    <label><i class="fas fa-phone"></i> Phone Number</label>
                                    <input type="tel" name="phone" class="form-control" value="<%= phone %>">
                                </div>
                                
                                <div class="form-group full-width">
                                    <label><i class="fas fa-map-marker-alt"></i> Address</label>
                                    <textarea name="address" class="form-control"><%= address %></textarea>
                                </div>
                            </div>
                            
                            <div class="form-actions">
                                <button type="reset" class="btn btn-secondary"><i class="fas fa-undo"></i> Reset</button>
                                <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Save Changes</button>
                            </div>
                        </form>
                    </div>
                </div>
                
                <!-- Employment Details Card -->
                <div class="card">
                    <div class="card-header">
                        <h3><i class="fas fa-briefcase"></i> Employment Details</h3>
                    </div>
                    <div class="card-body">
                        <div class="info-grid">
                            <div class="info-item">
                                <div class="info-label"><i class="fas fa-id-badge"></i> User ID</div>
                                <div class="info-value">#<%= userId %></div>
                            </div>
                            <div class="info-item">
                                <div class="info-label"><i class="fas fa-user-tie"></i> Role</div>
                                <div class="info-value">Staff Member</div>
                            </div>
                            <div class="info-item">
                                <div class="info-label"><i class="fas fa-calendar-alt"></i> Hire Date</div>
                                <div class="info-value"><%= !hireDate.isEmpty() ? hireDate : "Not Available" %></div>
                            </div>
                            <div class="info-item">
                                <div class="info-label"><i class="fas fa-building"></i> Department</div>
                                <div class="info-value">Operations</div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Change Password Card -->
                <div class="card">
                    <div class="card-header">
                        <h3><i class="fas fa-key"></i> Change Password</h3>
                    </div>
                    <div class="card-body">
                        <div class="password-requirements">
                            <h4><i class="fas fa-info-circle"></i> Password Requirements</h4>
                            <ul>
                                <li><i class="fas fa-check"></i> Minimum 6 characters long</li>
                                <li><i class="fas fa-check"></i> Use a mix of letters and numbers for better security</li>
                                <li><i class="fas fa-check"></i> Avoid using common words or personal information</li>
                            </ul>
                        </div>
                        
                        <form method="POST" action="staff-profile.jsp" id="passwordForm">
                            <input type="hidden" name="action" value="changePassword">
                            
                            <div class="form-grid">
                                <div class="form-group full-width">
                                    <label><i class="fas fa-lock"></i> Current Password *</label>
                                    <input type="password" name="currentPassword" class="form-control" required>
                                </div>
                                
                                <div class="form-group">
                                    <label><i class="fas fa-key"></i> New Password *</label>
                                    <input type="password" name="newPassword" id="newPassword" class="form-control" required minlength="6">
                                </div>
                                
                                <div class="form-group">
                                    <label><i class="fas fa-check-double"></i> Confirm New Password *</label>
                                    <input type="password" name="confirmPassword" id="confirmPassword" class="form-control" required minlength="6">
                                </div>
                            </div>
                            
                            <div class="form-actions">
                                <button type="reset" class="btn btn-secondary"><i class="fas fa-undo"></i> Clear</button>
                                <button type="submit" class="btn btn-danger"><i class="fas fa-key"></i> Change Password</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Profile picture upload
        function uploadProfilePic(input) {
            if (input.files && input.files[0]) {
                const file = input.files[0];
                
                // Validate file type
                if (!file.type.startsWith('image/')) {
                    Swal.fire({
                        icon: 'error',
                        title: 'Invalid File',
                        text: 'Please select an image file.',
                        confirmButtonColor: '#008080'
                    });
                    return;
                }
                
                // Validate file size (max 5MB)
                if (file.size > 5 * 1024 * 1024) {
                    Swal.fire({
                        icon: 'error',
                        title: 'File Too Large',
                        text: 'Please select an image under 5MB.',
                        confirmButtonColor: '#008080'
                    });
                    return;
                }
                
                // Show progress
                document.getElementById('uploadProgress').style.display = 'block';
                document.getElementById('progressFill').style.width = '0%';
                document.getElementById('progressText').textContent = 'Uploading...';
                
                const fd = new FormData();
                fd.append('profilePic', file);
                fd.append('action', 'uploadProfilePic');
                
                const xhr = new XMLHttpRequest();
                
                xhr.upload.addEventListener('progress', function(e) {
                    if (e.lengthComputable) {
                        const percentComplete = (e.loaded / e.total) * 100;
                        document.getElementById('progressFill').style.width = percentComplete + '%';
                        document.getElementById('progressText').textContent = Math.round(percentComplete) + '% uploaded';
                    }
                });
                
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === 4) {
                        document.getElementById('uploadProgress').style.display = 'none';
                        
                        if (xhr.status === 200) {
                            try {
                                const result = JSON.parse(xhr.responseText);
                                if (result.success) {
                                    // Update avatar
                                    const avatar = document.querySelector('.avatar');
                                    const existingImg = avatar.querySelector('img');
                                    const existingIcon = avatar.querySelector('i');
                                    
                                    if (existingImg) {
                                        existingImg.src = result.imagePath + '?t=' + new Date().getTime();
                                    } else {
                                        if (existingIcon) existingIcon.remove();
                                        const newImg = document.createElement('img');
                                        newImg.src = result.imagePath;
                                        newImg.alt = 'Profile';
                                        newImg.id = 'profileImage';
                                        avatar.appendChild(newImg);
                                    }
                                    
                                    Swal.fire({
                                        icon: 'success',
                                        title: 'Success!',
                                        text: 'Profile picture updated.',
                                        confirmButtonColor: '#008080'
                                    });
                                } else {
                                    Swal.fire({
                                        icon: 'error',
                                        title: 'Upload Failed',
                                        text: result.message || 'Failed to upload image.',
                                        confirmButtonColor: '#008080'
                                    });
                                }
                            } catch (e) {
                                Swal.fire({
                                    icon: 'error',
                                    title: 'Error',
                                    text: 'Invalid server response.',
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
                
                xhr.open('POST', '${pageContext.request.contextPath}/admin/admin-actions.jsp', true);
                xhr.send(fd);
            }
        }
        
        // Password validation
        document.getElementById('passwordForm').addEventListener('submit', function(e) {
            const newPass = document.getElementById('newPassword').value;
            const confirmPass = document.getElementById('confirmPassword').value;
            
            if (newPass !== confirmPass) {
                e.preventDefault();
                Swal.fire({
                    icon: 'error',
                    title: 'Password Mismatch',
                    text: 'New password and confirmation do not match.',
                    confirmButtonColor: '#008080'
                });
                return false;
            }
            
            if (newPass.length < 6) {
                e.preventDefault();
                Swal.fire({
                    icon: 'error',
                    title: 'Password Too Short',
                    text: 'Password must be at least 6 characters.',
                    confirmButtonColor: '#008080'
                });
                return false;
            }
        });
        
        // Show success/error messages with SweetAlert
        <% if (successMessage != null) { %>
        Swal.fire({
            icon: 'success',
            title: 'Success!',
            text: '<%= successMessage %>',
            confirmButtonColor: '#008080'
        });
        <% } %>
        
        <% if (errorMessage != null) { %>
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: '<%= errorMessage %>',
            confirmButtonColor: '#008080'
        });
        <% } %>
    </script>
</body>
</html>
<%
    // Close connection
    if (conn != null) {
        try { conn.close(); } catch (Exception e) {}
    }
%>
