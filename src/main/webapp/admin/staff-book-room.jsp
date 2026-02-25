<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat, java.text.DecimalFormat" %>
<%
    // Session check - STAFF role
    String userRole = (String) session.getAttribute("userRole");
    String username = (String) session.getAttribute("username");
    Integer staffId = (Integer) session.getAttribute("userId");
    
    if (username == null || userRole == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?role=staff");
        return;
    }
    if (!"STAFF".equalsIgnoreCase(userRole)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }
    
    // Get guest info from parameters
    int guestId = 0;
    String guestName = "";
    try {
        guestId = Integer.parseInt(request.getParameter("guestId"));
        guestName = request.getParameter("guestName");
        if (guestName != null) {
            guestName = java.net.URLDecoder.decode(guestName, "UTF-8");
        }
    } catch (Exception e) {
        response.sendRedirect("staff-customers.jsp");
        return;
    }
    
    // Filter parameters
    String filterRoomType = request.getParameter("roomType") != null ? request.getParameter("roomType") : "";
    String filterCheckIn = request.getParameter("checkIn") != null ? request.getParameter("checkIn") : "";
    String filterCheckOut = request.getParameter("checkOut") != null ? request.getParameter("checkOut") : "";
    
    // Database connection
    Connection conn = null;
    String successMessage = null;
    String errorMessage = null;
    int newReservationId = 0;
    DecimalFormat df = new DecimalFormat("#,##0.00");
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    
    // Process booking
    String action = request.getParameter("action");
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/ocean_view_resort", "root", "");
        
        if ("createBooking".equals(action)) {
            int roomId = Integer.parseInt(request.getParameter("roomId"));
            String checkInDate = request.getParameter("bookCheckIn");
            String checkOutDate = request.getParameter("bookCheckOut");
            int numberOfGuests = Integer.parseInt(request.getParameter("numberOfGuests"));
            String specialRequests = request.getParameter("specialRequests");
            
            // Generate reservation number
            String reservationNumber = "RES" + System.currentTimeMillis();
            
            // Check room availability for the dates
            PreparedStatement checkPs = conn.prepareStatement(
                "SELECT COUNT(*) FROM reservations WHERE room_id = ? AND status IN ('CONFIRMED', 'CHECKED_IN') " +
                "AND ((check_in_date <= ? AND check_out_date > ?) OR (check_in_date < ? AND check_out_date >= ?) OR (check_in_date >= ? AND check_out_date <= ?))"
            );
            checkPs.setInt(1, roomId);
            checkPs.setString(2, checkInDate);
            checkPs.setString(3, checkInDate);
            checkPs.setString(4, checkOutDate);
            checkPs.setString(5, checkOutDate);
            checkPs.setString(6, checkInDate);
            checkPs.setString(7, checkOutDate);
            ResultSet checkRs = checkPs.executeQuery();
            checkRs.next();
            int conflicts = checkRs.getInt(1);
            checkRs.close();
            checkPs.close();
            
            if (conflicts > 0) {
                errorMessage = "Room is not available for the selected dates!";
            } else {
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO reservations (reservation_number, guest_id, room_id, check_in_date, check_out_date, number_of_guests, special_requests, status, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, 'CONFIRMED', ?)",
                    Statement.RETURN_GENERATED_KEYS
                );
                ps.setString(1, reservationNumber);
                ps.setInt(2, guestId);
                ps.setInt(3, roomId);
                ps.setString(4, checkInDate);
                ps.setString(5, checkOutDate);
                ps.setInt(6, numberOfGuests);
                ps.setString(7, specialRequests);
                ps.setInt(8, staffId);
                ps.executeUpdate();
                
                // Get the generated reservation ID
                ResultSet generatedKeys = ps.getGeneratedKeys();
                if (generatedKeys.next()) {
                    newReservationId = generatedKeys.getInt(1);
                }
                generatedKeys.close();
                ps.close();
                
                successMessage = "Booking created successfully! Reservation #: " + reservationNumber;
            }
        }
        
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
    <title>Book Room - Ocean View Resort Staff</title>
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
            --success: #28a745;
            --warning: #ffc107;
            --danger: #dc3545;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Poppins', sans-serif;
        }
        
        body {
            background: var(--bg);
            min-height: 100vh;
        }
        
        /* Header */
        .header {
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
            color: white;
            padding: 20px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .header h1 {
            font-size: 1.5rem;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .header-actions {
            display: flex;
            gap: 15px;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 500;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
            text-decoration: none;
        }
        
        .btn-back {
            background: rgba(255,255,255,0.2);
            color: white;
        }
        
        .btn-back:hover {
            background: rgba(255,255,255,0.3);
        }
        
        .btn-primary {
            background: var(--primary);
            color: white;
        }
        
        .btn-primary:hover {
            background: var(--primary-dark);
            transform: translateY(-2px);
        }
        
        .btn-success {
            background: var(--success);
            color: white;
        }
        
        .btn-success:hover {
            background: #218838;
        }
        
        /* Main Content */
        .main-content {
            padding: 30px;
            max-width: 1400px;
            margin: 0 auto;
        }
        
        /* Customer Info Card */
        .customer-info {
            background: var(--card-bg);
            border-radius: 15px;
            padding: 20px 25px;
            margin-bottom: 25px;
            display: flex;
            align-items: center;
            gap: 20px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.05);
            border-left: 4px solid var(--primary);
        }
        
        .customer-avatar {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--primary), var(--glow));
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.5rem;
            font-weight: 600;
        }
        
        .customer-details h2 {
            font-size: 1.3rem;
            color: var(--text);
            margin-bottom: 5px;
        }
        
        .customer-details p {
            color: var(--text-light);
            font-size: 0.9rem;
        }
        
        /* Filter Section */
        .filter-section {
            background: var(--card-bg);
            border-radius: 15px;
            padding: 25px;
            margin-bottom: 25px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.05);
        }
        
        .filter-header {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 20px;
            color: var(--primary-dark);
            font-weight: 600;
            font-size: 1.1rem;
        }
        
        .filter-form {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
            align-items: flex-end;
        }
        
        .filter-group {
            flex: 1;
            min-width: 200px;
        }
        
        .filter-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            color: var(--text);
            font-size: 0.9rem;
        }
        
        .filter-group label i {
            color: var(--primary);
            margin-right: 5px;
        }
        
        .form-control {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 0.95rem;
            transition: all 0.3s ease;
        }
        
        .form-control:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(0, 128, 128, 0.1);
        }
        
        .filter-buttons {
            display: flex;
            gap: 10px;
        }
        
        .btn-filter {
            background: var(--primary);
            color: white;
            padding: 12px 25px;
        }
        
        .btn-clear {
            background: #e0e0e0;
            color: var(--text);
            padding: 12px 25px;
        }
        
        /* Rooms Grid */
        .rooms-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 25px;
        }
        
        .room-card {
            background: var(--card-bg);
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            transition: all 0.3s ease;
        }
        
        .room-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 15px 40px rgba(0,0,0,0.15);
        }
        
        .room-image {
            height: 200px;
            background: linear-gradient(135deg, var(--primary-dark), var(--primary));
            position: relative;
            overflow: hidden;
        }
        
        .room-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        
        .room-image .no-image {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            color: rgba(255,255,255,0.7);
        }
        
        .room-image .no-image i {
            font-size: 50px;
            margin-bottom: 10px;
        }
        
        .room-number-badge {
            position: absolute;
            top: 15px;
            left: 15px;
            background: rgba(0,0,0,0.7);
            color: white;
            padding: 8px 15px;
            border-radius: 10px;
            font-weight: 600;
        }
        
        .room-status-badge {
            position: absolute;
            top: 15px;
            right: 15px;
            padding: 6px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .room-status-badge.available { background: var(--success); color: white; }
        .room-status-badge.occupied { background: #17a2b8; color: white; }
        .room-status-badge.maintenance { background: var(--warning); color: #333; }
        
        .room-card.unavailable {
            opacity: 0.7;
        }
        
        .room-card.unavailable:hover {
            transform: none;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
        }
        
        .room-details-content {
            padding: 20px;
        }
        
        .room-type-label {
            font-size: 18px;
            font-weight: 600;
            color: var(--text);
            margin-bottom: 5px;
        }
        
        .room-floor {
            font-size: 13px;
            color: var(--text-light);
            margin-bottom: 15px;
        }
        
        .room-price {
            font-size: 22px;
            font-weight: 700;
            color: var(--primary);
            margin-bottom: 15px;
        }
        
        .room-price span {
            font-size: 14px;
            font-weight: 400;
            color: var(--text-light);
        }
        
        .room-facilities {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-bottom: 15px;
        }
        
        .facility-tag {
            background: var(--bg);
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 12px;
            color: var(--text-light);
            display: flex;
            align-items: center;
            gap: 5px;
        }
        
        .facility-tag i {
            color: var(--primary);
            font-size: 11px;
        }
        
        .room-description {
            font-size: 13px;
            color: var(--text-light);
            line-height: 1.6;
            margin-bottom: 15px;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }
        
        .btn-book {
            width: 100%;
            padding: 12px;
            background: linear-gradient(135deg, var(--primary), var(--primary-dark));
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        
        .btn-book:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0, 128, 128, 0.4);
        }
        
        .btn-book:disabled {
            background: #ccc;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }
        
        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            background: var(--card-bg);
            border-radius: 15px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.05);
        }
        
        .empty-state i {
            font-size: 4rem;
            color: #ddd;
            margin-bottom: 20px;
        }
        
        .empty-state h3 {
            color: var(--text);
            margin-bottom: 10px;
        }
        
        .empty-state p {
            color: var(--text-light);
        }
        
        /* Modal */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1000;
            padding: 20px;
        }
        
        .modal-overlay.active {
            display: flex;
        }
        
        .modal-content {
            background: white;
            border-radius: 15px;
            width: 100%;
            max-width: 500px;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        }
        
        .modal-header {
            background: linear-gradient(135deg, var(--primary-dark), var(--primary));
            color: white;
            padding: 20px 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-header h3 {
            font-size: 1.2rem;
        }
        
        .modal-close {
            background: none;
            border: none;
            color: white;
            font-size: 1.5rem;
            cursor: pointer;
            opacity: 0.8;
        }
        
        .modal-close:hover {
            opacity: 1;
        }
        
        .modal-body {
            padding: 25px;
        }
        
        .booking-summary {
            background: #f5f5f5;
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 20px;
        }
        
        .booking-summary h4 {
            color: var(--primary-dark);
            margin-bottom: 10px;
            font-size: 0.9rem;
        }
        
        .booking-summary-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            font-size: 0.9rem;
        }
        
        .booking-summary-item span:first-child {
            color: var(--text-light);
        }
        
        .booking-summary-item span:last-child {
            font-weight: 600;
            color: var(--text);
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            color: var(--text);
        }
        
        .form-group label i {
            color: var(--primary);
            margin-right: 5px;
        }
        
        .modal-footer {
            padding: 20px 25px;
            background: #f9f9f9;
            border-top: 1px solid #eee;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
        }
        
        .btn-secondary {
            background: #e0e0e0;
            color: var(--text);
        }
        
        .btn-secondary:hover {
            background: #d0d0d0;
        }
        
        @media (max-width: 768px) {
            .header {
                flex-direction: column;
                gap: 15px;
                text-align: center;
            }
            
            .filter-form {
                flex-direction: column;
            }
            
            .rooms-grid {
                grid-template-columns: 1fr;
            }
            
            .customer-info {
                flex-direction: column;
                text-align: center;
            }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <div class="header">
        <h1><i class="fas fa-calendar-plus"></i> Book Room for Customer</h1>
        <div class="header-actions">
            <a href="staff-customers.jsp" class="btn btn-back"><i class="fas fa-arrow-left"></i> Back to Customers</a>
            <a href="<%= request.getContextPath() %>/staff/staff-dashboard.jsp" class="btn btn-back"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
        </div>
    </div>
    
    <div class="main-content">
        <!-- Customer Info -->
        <div class="customer-info">
            <div class="customer-avatar">
                <%= guestName.length() > 0 ? guestName.charAt(0) : "?" %>
            </div>
            <div class="customer-details">
                <h2>Booking for: <%= guestName %></h2>
                <p><i class="fas fa-user"></i> Customer ID: #<%= guestId %></p>
            </div>
        </div>
        
        <!-- Filter Section -->
        <div class="filter-section">
            <div class="filter-header">
                <i class="fas fa-filter"></i> Filter Available Rooms
            </div>
            <form method="GET" action="staff-book-room.jsp" class="filter-form">
                <input type="hidden" name="guestId" value="<%= guestId %>">
                <input type="hidden" name="guestName" value="<%= java.net.URLEncoder.encode(guestName, "UTF-8") %>">
                
                <div class="filter-group">
                    <label><i class="fas fa-bed"></i> Room Type</label>
                    <select name="roomType" class="form-control">
                        <option value="">All Room Types</option>
                        <%
                            try {
                                Statement typeStmt = conn.createStatement();
                                ResultSet typeRs = typeStmt.executeQuery("SELECT room_type_id, type_name FROM room_types WHERE status = 'AVAILABLE' ORDER BY type_name");
                                while (typeRs.next()) {
                                    int typeId = typeRs.getInt("room_type_id");
                                    String typeName = typeRs.getString("type_name");
                                    boolean selected = String.valueOf(typeId).equals(filterRoomType);
                        %>
                        <option value="<%= typeId %>" <%= selected ? "selected" : "" %>><%= typeName %></option>
                        <%
                                }
                                typeRs.close();
                                typeStmt.close();
                            } catch (Exception e) { }
                        %>
                    </select>
                </div>
                
                <div class="filter-group">
                    <label><i class="fas fa-calendar-alt"></i> Check-in Date</label>
                    <input type="date" name="checkIn" class="form-control" value="<%= filterCheckIn %>" min="<%= sdf.format(new java.util.Date()) %>">
                </div>
                
                <div class="filter-group">
                    <label><i class="fas fa-calendar-check"></i> Check-out Date</label>
                    <input type="date" name="checkOut" class="form-control" value="<%= filterCheckOut %>" min="<%= sdf.format(new java.util.Date()) %>">
                </div>
                
                <div class="filter-buttons">
                    <button type="submit" class="btn btn-filter"><i class="fas fa-search"></i> Search</button>
                    <a href="staff-book-room.jsp?guestId=<%= guestId %>&guestName=<%= java.net.URLEncoder.encode(guestName, "UTF-8") %>" class="btn btn-clear"><i class="fas fa-times"></i> Clear</a>
                </div>
            </form>
        </div>
        
        <!-- Rooms Grid -->
        <div class="rooms-grid">
            <%
                try {
                    // Build query with filters - show ALL rooms
                    StringBuilder query = new StringBuilder();
                    query.append("SELECT r.*, rt.type_name, rt.rate_per_night, rt.max_occupancy, rt.amenities ");
                    query.append("FROM rooms r ");
                    query.append("JOIN room_types rt ON r.room_type_id = rt.room_type_id ");
                    query.append("WHERE 1=1 ");
                    
                    if (!filterRoomType.isEmpty()) {
                        query.append("AND r.room_type_id = ").append(filterRoomType).append(" ");
                    }
                    
                    query.append("ORDER BY r.room_number");
                    
                    Statement roomStmt = conn.createStatement();
                    ResultSet roomRs = roomStmt.executeQuery(query.toString());
                    boolean hasRooms = false;
                    
                    while (roomRs.next()) {
                        hasRooms = true;
                        int roomId = roomRs.getInt("room_id");
                        String roomNumber = roomRs.getString("room_number");
                        String typeName = roomRs.getString("type_name");
                        int typeId = roomRs.getInt("room_type_id");
                        double ratePerNight = roomRs.getDouble("rate_per_night");
                        int maxOccupancy = roomRs.getInt("max_occupancy");
                        int floor = roomRs.getInt("floor");
                        String status = roomRs.getString("status");
                        String description = roomRs.getString("description");
                        String facilities = roomRs.getString("facilities");
                        String amenities = roomRs.getString("amenities");
                        String imageUrl = roomRs.getString("image_url");
                        
                        // Check if room is available for booking
                        boolean canBook = "AVAILABLE".equalsIgnoreCase(status);
                        String statusClass = status.toLowerCase().replace("_", "-");
                        
                        // If dates specified, check for conflicting reservations
                        if (canBook && !filterCheckIn.isEmpty() && !filterCheckOut.isEmpty()) {
                            PreparedStatement checkPs = conn.prepareStatement(
                                "SELECT COUNT(*) FROM reservations WHERE room_id = ? AND status IN ('CONFIRMED', 'CHECKED_IN') " +
                                "AND ((check_in_date <= ? AND check_out_date > ?) OR (check_in_date < ? AND check_out_date >= ?) OR (check_in_date >= ? AND check_out_date <= ?))"
                            );
                            checkPs.setInt(1, roomId);
                            checkPs.setString(2, filterCheckIn);
                            checkPs.setString(3, filterCheckIn);
                            checkPs.setString(4, filterCheckOut);
                            checkPs.setString(5, filterCheckOut);
                            checkPs.setString(6, filterCheckIn);
                            checkPs.setString(7, filterCheckOut);
                            ResultSet checkRs = checkPs.executeQuery();
                            if (checkRs.next() && checkRs.getInt(1) > 0) {
                                canBook = false;
                            }
                            checkRs.close();
                            checkPs.close();
                        }
            %>
            <div class="room-card <%= !canBook ? "unavailable" : "" %>">
                <div class="room-image">
                    <% if (imageUrl != null && !imageUrl.isEmpty()) { %>
                        <img src="<%= imageUrl %>" alt="<%= typeName %>">
                    <% } else { %>
                        <div class="no-image">
                            <i class="fas fa-bed"></i>
                            <span>No Image</span>
                        </div>
                    <% } %>
                    <span class="room-number-badge">Room <%= roomNumber %></span>
                    <span class="room-status-badge <%= statusClass %>"><%= status %></span>
                </div>
                <div class="room-details-content">
                    <div class="room-type-label"><%= typeName %></div>
                    <div class="room-floor"><i class="fas fa-layer-group"></i> Floor <%= floor %> | <i class="fas fa-users"></i> Max <%= maxOccupancy %> guests</div>
                    <div class="room-price">LKR <%= df.format(ratePerNight) %> <span>/ night</span></div>
                    
                    <% 
                        String amenitiesStr = amenities != null ? amenities : facilities;
                        if (amenitiesStr != null && !amenitiesStr.isEmpty()) {
                    %>
                    <div class="room-facilities">
                        <% 
                            String[] amenityList = amenitiesStr.split(",");
                            int count = 0;
                            for (String amenity : amenityList) {
                                if (count < 4) {
                        %>
                        <span class="facility-tag"><i class="fas fa-check"></i> <%= amenity.trim() %></span>
                        <%
                                    count++;
                                }
                            }
                            if (amenityList.length > 4) {
                        %>
                        <span class="facility-tag">+<%= amenityList.length - 4 %> more</span>
                        <% } %>
                    </div>
                    <% } %>
                    
                    <% if (description != null && !description.isEmpty()) { %>
                    <div class="room-description"><%= description %></div>
                    <% } %>
                    
                    <% if (canBook) { %>
                    <button class="btn-book" 
                        data-room-id="<%= roomId %>"
                        data-room-number="<%= roomNumber %>"
                        data-room-type="<%= typeName %>"
                        data-rate="<%= ratePerNight %>"
                        data-max-occupancy="<%= maxOccupancy %>"
                        onclick="selectRoom(this)">
                        <i class="fas fa-calendar-check"></i> Select This Room
                    </button>
                    <% } else { %>
                    <button class="btn-book" disabled>
                        <i class="fas fa-ban"></i> <%= "AVAILABLE".equalsIgnoreCase(status) ? "Booked for dates" : status %>
                    </button>
                    <% } %>
                </div>
            </div>
            <%
                    }
                    
                    if (!hasRooms) {
            %>
            <div class="empty-state" style="grid-column: 1 / -1;">
                <i class="fas fa-bed"></i>
                <h3>No rooms found</h3>
                <p>Try adjusting your filters</p>
            </div>
            <%
                    }
                    
                    roomRs.close();
                    roomStmt.close();
                } catch (Exception e) {
                    e.printStackTrace();
            %>
            <div class="empty-state" style="grid-column: 1 / -1;">
                <i class="fas fa-exclamation-triangle"></i>
                <h3>Error loading rooms</h3>
                <p><%= e.getMessage() %></p>
            </div>
            <%
                }
            %>
        </div>
    </div>
    
    <!-- Booking Modal -->
    <div id="bookingModal" class="modal-overlay">
        <div class="modal-content">
            <div class="modal-header">
                <h3><i class="fas fa-calendar-plus"></i> Complete Booking</h3>
                <button class="modal-close" onclick="closeModal()">&times;</button>
            </div>
            <form method="POST" action="staff-book-room.jsp?guestId=<%= guestId %>&guestName=<%= java.net.URLEncoder.encode(guestName, "UTF-8") %>">
                <input type="hidden" name="action" value="createBooking">
                <input type="hidden" name="roomId" id="bookRoomId">
                
                <div class="modal-body">
                    <div class="booking-summary">
                        <h4><i class="fas fa-info-circle"></i> Booking Summary</h4>
                        <div class="booking-summary-item">
                            <span>Guest</span>
                            <span><%= guestName %></span>
                        </div>
                        <div class="booking-summary-item">
                            <span>Room</span>
                            <span id="summaryRoom">-</span>
                        </div>
                        <div class="booking-summary-item">
                            <span>Room Type</span>
                            <span id="summaryType">-</span>
                        </div>
                        <div class="booking-summary-item">
                            <span>Rate per Night</span>
                            <span id="summaryRate">-</span>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label><i class="fas fa-calendar-alt"></i> Check-in Date *</label>
                        <input type="date" name="bookCheckIn" id="bookCheckIn" class="form-control" required min="<%= sdf.format(new java.util.Date()) %>" value="<%= filterCheckIn %>">
                    </div>
                    
                    <div class="form-group">
                        <label><i class="fas fa-calendar-check"></i> Check-out Date *</label>
                        <input type="date" name="bookCheckOut" id="bookCheckOut" class="form-control" required min="<%= sdf.format(new java.util.Date()) %>" value="<%= filterCheckOut %>">
                    </div>
                    
                    <div class="form-group">
                        <label><i class="fas fa-users"></i> Number of Guests *</label>
                        <select name="numberOfGuests" id="numberOfGuests" class="form-control" required>
                            <option value="1">1 Guest</option>
                            <option value="2">2 Guests</option>
                            <option value="3">3 Guests</option>
                            <option value="4">4 Guests</option>
                            <option value="5">5 Guests</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label><i class="fas fa-comment-alt"></i> Special Requests</label>
                        <textarea name="specialRequests" class="form-control" rows="3" placeholder="Any special requests or notes..."></textarea>
                    </div>
                </div>
                
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal()">Cancel</button>
                    <button type="submit" class="btn btn-success"><i class="fas fa-check"></i> Confirm Booking</button>
                </div>
            </form>
        </div>
    </div>
    
    <script>
        // Show success/error messages
        <% if (successMessage != null && newReservationId > 0) { %>
            Swal.fire({
                icon: 'success',
                title: 'Booking Created!',
                text: '<%= successMessage %>',
                confirmButtonColor: '#008080'
            }).then(() => {
                window.location.href = 'staff-payment.jsp?reservationId=<%= newReservationId %>';
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
        
        // Select room from data attributes
        function selectRoom(btn) {
            const roomId = btn.getAttribute('data-room-id');
            const roomNumber = btn.getAttribute('data-room-number');
            const roomType = btn.getAttribute('data-room-type');
            const rate = parseFloat(btn.getAttribute('data-rate'));
            const maxOccupancy = parseInt(btn.getAttribute('data-max-occupancy'));
            openBookingModal(roomId, roomNumber, roomType, rate, maxOccupancy);
        }
        
        // Modal functions
        function openBookingModal(roomId, roomNumber, roomType, rate, maxOccupancy) {
            document.getElementById('bookRoomId').value = roomId;
            document.getElementById('summaryRoom').textContent = 'Room ' + roomNumber;
            document.getElementById('summaryType').textContent = roomType;
            document.getElementById('summaryRate').textContent = 'LKR ' + rate.toLocaleString('en-US', {minimumFractionDigits: 2});
            
            // Update maximum guests
            const guestSelect = document.getElementById('numberOfGuests');
            guestSelect.innerHTML = '';
            for (let i = 1; i <= maxOccupancy; i++) {
                const option = document.createElement('option');
                option.value = i;
                option.textContent = i + (i === 1 ? ' Guest' : ' Guests');
                guestSelect.appendChild(option);
            }
            
            document.getElementById('bookingModal').classList.add('active');
        }
        
        function closeModal() {
            document.getElementById('bookingModal').classList.remove('active');
        }
        
        // Close modal on outside click
        document.getElementById('bookingModal').addEventListener('click', function(e) {
            if (e.target === this) {
                closeModal();
            }
        });
        
        // Validate checkout > checkin
        document.getElementById('bookCheckIn').addEventListener('change', function() {
            document.getElementById('bookCheckOut').min = this.value;
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
