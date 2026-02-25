<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat, java.text.DecimalFormat" %>
<%! 
    private String escapeJs(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\").replace("'", "\\'").replace("\r", " ").replace("\n", " ");
    }
%>
<%
    // Session check - Allow both ADMIN and STAFF
    String userRole = (String) session.getAttribute("userRole");
    String username = (String) session.getAttribute("username");
    Integer adminId = (Integer) session.getAttribute("userId");
    
    if (username == null || userRole == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    if (!"ADMIN".equalsIgnoreCase(userRole) && !"STAFF".equalsIgnoreCase(userRole)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }
    
    // Determine back link based on role
    String backLink = "ADMIN".equalsIgnoreCase(userRole)
        ? request.getContextPath() + "/admin/admin-payments.jsp"
        : request.getContextPath() + "/staff/staff-payments.jsp";
    
    // Get reservation ID from parameters
    int reservationId = 0;
    try {
        reservationId = Integer.parseInt(request.getParameter("reservationId"));
    } catch (Exception e) {
        response.sendRedirect(backLink);
        return;
    }
    
    // Database connection
    Connection conn = null;
    String successMessage = null;
    String errorMessage = null;
    DecimalFormat df = new DecimalFormat("#,##0.00");
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    SimpleDateFormat displaySdf = new SimpleDateFormat("MMM dd, yyyy");
    
    // Reservation details
    String reservationNumber = "";
    String guestName = "";
    String guestEmail = "";
    String guestPhone = "";
    String guestNic = "";
    String guestAddress = "";
    String guestNationality = "";
    int guestId = 0;
    String roomNumber = "";
    String roomTypeName = "";
    double ratePerNight = 0;
    java.sql.Date checkInDate = null;
    java.sql.Date checkOutDate = null;
    int numberOfGuests = 0;
    String specialRequests = "";
    String status = "";
    int numberOfNights = 0;
    double roomTotal = 0;
    double serviceCharge = 0;
    double taxAmount = 0;
    double totalAmount = 0;
    int billId = 0;
    String paymentStatus = "PENDING";
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/ocean_view_resort", "root", "");
        
        // Process payment
        String action = request.getParameter("action");
        
        if ("processPayment".equals(action)) {
            String paymentMethod = request.getParameter("paymentMethod");
            String amountParam = request.getParameter("amountPaid");
            String notes = request.getParameter("notes");
            int currentBillId = Integer.parseInt(request.getParameter("billId"));
            double amountPaid = 0.0;
            try {
                amountPaid = Double.parseDouble(amountParam);
            } catch (Exception ignored) {
                amountPaid = 0.0;
            }

            if (paymentMethod == null || paymentMethod.trim().isEmpty()) {
                errorMessage = "Please select a payment method.";
            } else if (amountPaid <= 0) {
                errorMessage = "Payment amount must be greater than 0.";
            } else {
                PreparedStatement totalPs = conn.prepareStatement("SELECT total_amount FROM bills WHERE bill_id = ?");
                totalPs.setInt(1, currentBillId);
                ResultSet totalRs = totalPs.executeQuery();
                double billTotalAmount = 0.0;
                if (totalRs.next()) {
                    billTotalAmount = totalRs.getDouble("total_amount");
                }
                totalRs.close();
                totalPs.close();

                if (amountPaid + 0.0001 < billTotalAmount) {
                    errorMessage = "Full payment is required. Amount due: LKR " + df.format(billTotalAmount);
                } else {
                    PreparedStatement updatePs = conn.prepareStatement(
                        "UPDATE bills SET payment_status = 'PAID', payment_method = ?, paid_at = NOW() WHERE bill_id = ?"
                    );
                    updatePs.setString(1, paymentMethod);
                    updatePs.setInt(2, currentBillId);
                    updatePs.executeUpdate();
                    updatePs.close();

                    successMessage = "Payment processed successfully!";
                    paymentStatus = "PAID";
                }
            }
        }
        
        // Fetch reservation details with guest and room info
        PreparedStatement ps = conn.prepareStatement(
            "SELECT r.*, g.full_name, g.email, g.phone, g.nic_passport, g.address, g.nationality, " +
            "ro.room_number, rt.type_name, rt.rate_per_night " +
            "FROM reservations r " +
            "JOIN guests g ON r.guest_id = g.guest_id " +
            "JOIN rooms ro ON r.room_id = ro.room_id " +
            "JOIN room_types rt ON ro.room_type_id = rt.room_type_id " +
            "WHERE r.reservation_id = ?"
        );
        ps.setInt(1, reservationId);
        ResultSet rs = ps.executeQuery();
        
        if (rs.next()) {
            reservationNumber = rs.getString("reservation_number");
            guestId = rs.getInt("guest_id");
            guestName = rs.getString("full_name");
            if (guestName == null || guestName.isEmpty()) guestName = "Guest";
            guestEmail = rs.getString("email");
            guestPhone = rs.getString("phone");
            guestNic = rs.getString("nic_passport");
            guestAddress = rs.getString("address");
            guestNationality = rs.getString("nationality");
            roomNumber = rs.getString("room_number");
            roomTypeName = rs.getString("type_name");
            ratePerNight = rs.getDouble("rate_per_night");
            checkInDate = rs.getDate("check_in_date");
            checkOutDate = rs.getDate("check_out_date");
            numberOfGuests = rs.getInt("number_of_guests");
            specialRequests = rs.getString("special_requests");
            status = rs.getString("status");
            
            // Calculate number of nights
            long diffInMillis = 0;
            if (checkInDate != null && checkOutDate != null) {
                diffInMillis = checkOutDate.getTime() - checkInDate.getTime();
            }
            numberOfNights = (int) (diffInMillis / (1000 * 60 * 60 * 24));
            if (numberOfNights < 1) numberOfNights = 1;
            
            // Calculate totals
            roomTotal = ratePerNight * numberOfNights;
            serviceCharge = roomTotal * 0.10; // 10% service charge
            taxAmount = (roomTotal + serviceCharge) * 0.05; // 5% tax
            totalAmount = roomTotal + serviceCharge + taxAmount;
        } else {
            response.sendRedirect(backLink + "?error=Reservation+not+found");
            return;
        }
        rs.close();
        ps.close();
        
        // Check if bill already exists
        PreparedStatement billCheckPs = conn.prepareStatement(
            "SELECT bill_id, payment_status FROM bills WHERE reservation_id = ?"
        );
        billCheckPs.setInt(1, reservationId);
        ResultSet billRs = billCheckPs.executeQuery();
        
        if (billRs.next()) {
            billId = billRs.getInt("bill_id");
            paymentStatus = billRs.getString("payment_status");
        } else {
            // Create new bill
            String billNumber = "BILL" + System.currentTimeMillis();
            PreparedStatement createBillPs = conn.prepareStatement(
                "INSERT INTO bills (bill_number, reservation_id, number_of_nights, room_rate, room_total, service_charge, tax_amount, total_amount, payment_status, generated_by) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PENDING', ?)",
                Statement.RETURN_GENERATED_KEYS
            );
            createBillPs.setString(1, billNumber);
            createBillPs.setInt(2, reservationId);
            createBillPs.setInt(3, numberOfNights);
            createBillPs.setDouble(4, ratePerNight);
            createBillPs.setDouble(5, roomTotal);
            createBillPs.setDouble(6, serviceCharge);
            createBillPs.setDouble(7, taxAmount);
            createBillPs.setDouble(8, totalAmount);
            if (adminId != null) {
                createBillPs.setInt(9, adminId);
            } else {
                createBillPs.setNull(9, java.sql.Types.INTEGER);
            }
            createBillPs.executeUpdate();
            
            ResultSet billKeys = createBillPs.getGeneratedKeys();
            if (billKeys.next()) {
                billId = billKeys.getInt(1);
            }
            billKeys.close();
            createBillPs.close();
        }
        billRs.close();
        billCheckPs.close();
        
    } catch (Exception e) {
        errorMessage = "Error: " + e.getMessage();
        e.printStackTrace();
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (Exception e) {}
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Process Payment - Ocean View Resort Admin</title>
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
            font-size: 0.95rem;
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
        
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        
        .btn-secondary:hover {
            background: #5a6268;
        }
        
        /* Main Content */
        .main-content {
            padding: 30px;
            max-width: 1200px;
            margin: 0 auto;
        }
        
        /* Cards */
        .card {
            background: var(--card-bg);
            border-radius: 15px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.05);
            margin-bottom: 25px;
            overflow: hidden;
        }
        
        .card-header {
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
            color: white;
            padding: 15px 25px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .card-body {
            padding: 25px;
        }
        
        /* Grid Layout */
        .payment-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 25px;
        }
        
        @media (max-width: 900px) {
            .payment-grid {
                grid-template-columns: 1fr;
            }
        }
        
        /* Booking Summary */
        .summary-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #eee;
        }
        
        .summary-row:last-child {
            border-bottom: none;
        }
        
        .summary-label {
            color: var(--text-light);
            font-size: 0.95rem;
        }
        
        .summary-value {
            font-weight: 500;
            color: var(--text);
        }
        
        .summary-total {
            background: linear-gradient(135deg, var(--primary-dark), var(--primary));
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-top: 15px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .summary-total .label {
            font-size: 1.1rem;
        }
        
        .summary-total .amount {
            font-size: 1.5rem;
            font-weight: 700;
        }
        
        /* Guest Info */
        .guest-info {
            display: flex;
            align-items: center;
            gap: 15px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        
        .guest-avatar {
            width: 50px;
            height: 50px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--primary), var(--glow));
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.2rem;
            font-weight: 600;
        }
        
        .guest-details h3 {
            font-size: 1rem;
            margin-bottom: 3px;
        }
        
        .guest-details p {
            font-size: 0.85rem;
            color: var(--text-light);
        }
        
        /* Payment Form */
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
        
        .form-control {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e2e8f0;
            border-radius: 8px;
            font-size: 1rem;
            transition: all 0.3s ease;
        }
        
        .form-control:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(0, 128, 128, 0.1);
        }
        
        /* Payment Methods */
        .payment-methods {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 10px;
            margin-bottom: 20px;
        }
        
        .payment-method {
            padding: 15px;
            text-align: center;
            border: 2px solid #e2e8f0;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .payment-method:hover {
            border-color: var(--primary);
            background: #f0f7f7;
        }
        
        .payment-method.selected {
            border-color: var(--primary);
            background: linear-gradient(135deg, rgba(0, 128, 128, 0.1), rgba(0, 192, 192, 0.1));
        }
        
        .payment-method i {
            font-size: 1.8rem;
            margin-bottom: 8px;
            display: block;
        }
        
        .payment-method span {
            font-size: 0.85rem;
            color: var(--text-light);
        }
        
        .payment-method.selected span {
            color: var(--primary);
            font-weight: 600;
        }
        
        /* Status Badge */
        .status-badge {
            padding: 8px 15px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }
        
        .status-pending {
            background: #fff3cd;
            color: #856404;
        }
        
        .status-paid {
            background: #d4edda;
            color: #155724;
        }
        
        /* Success Card */
        .success-card {
            text-align: center;
            padding: 40px;
        }
        
        .success-icon {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, var(--success), #34ce57);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
        }
        
        .success-icon i {
            font-size: 2.5rem;
            color: white;
        }
        
        .success-card h2 {
            color: var(--success);
            margin-bottom: 10px;
        }
        
        .success-card p {
            color: var(--text-light);
            margin-bottom: 25px;
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <h1><i class="fas fa-credit-card"></i> Process Payment</h1>
        <div class="header-actions">
            <a href="<%= backLink %>" class="btn btn-back">
                <i class="fas fa-arrow-left"></i> Back to Payments
            </a>
        </div>
    </header>
    
    <!-- Main Content -->
    <main class="main-content">
        <% if ("PAID".equals(paymentStatus)) { 
            // Redirect to invoice page after successful payment
            String invoicePath = "ADMIN".equalsIgnoreCase(userRole)
                ? request.getContextPath() + "/admin/admin-invoice.jsp?billId=" + billId
                : request.getContextPath() + "/staff/staff-invoice.jsp?billId=" + billId;
            response.sendRedirect(invoicePath);
            return;
        } else { %>
            <div class="payment-grid">
                <!-- Left Column - Booking Summary -->
                <div>
                    <!-- Guest Info Card -->
                    <div class="card">
                        <div class="card-header">
                            <i class="fas fa-user"></i> Guest Information
                        </div>
                        <div class="card-body">
                            <div class="guest-info">
                                <div class="guest-avatar">
                                    <%= guestName != null && !guestName.isEmpty() ? guestName.substring(0, 1).toUpperCase() : "G" %>
                                </div>
                                <div class="guest-details">
                                    <h3><%= guestName %></h3>
                                    <p><i class="fas fa-id-card"></i> <%= guestNic != null && !guestNic.isEmpty() ? guestNic : "N/A" %></p>
                                </div>
                            </div>
                            <hr style="margin: 15px 0; border: none; border-top: 1px solid #eee;">
                            <div class="summary-row">
                                <span class="summary-label"><i class="fas fa-envelope" style="color: var(--primary); margin-right: 8px;"></i>Email</span>
                                <span class="summary-value"><%= guestEmail != null && !guestEmail.isEmpty() ? guestEmail : "N/A" %></span>
                            </div>
                            <div class="summary-row">
                                <span class="summary-label"><i class="fas fa-phone" style="color: var(--primary); margin-right: 8px;"></i>Phone</span>
                                <span class="summary-value"><%= guestPhone != null && !guestPhone.isEmpty() ? guestPhone : "N/A" %></span>
                            </div>
                            <div class="summary-row">
                                <span class="summary-label"><i class="fas fa-map-marker-alt" style="color: var(--primary); margin-right: 8px;"></i>Address</span>
                                <span class="summary-value"><%= guestAddress != null && !guestAddress.isEmpty() ? guestAddress : "N/A" %></span>
                            </div>
                            <div class="summary-row">
                                <span class="summary-label"><i class="fas fa-globe" style="color: var(--primary); margin-right: 8px;"></i>Nationality</span>
                                <span class="summary-value"><%= guestNationality != null && !guestNationality.isEmpty() ? guestNationality : "N/A" %></span>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Booking Details Card -->
                    <div class="card">
                        <div class="card-header">
                            <i class="fas fa-file-invoice"></i> Booking Summary
                        </div>
                        <div class="card-body">
                            <div class="summary-row">
                                <span class="summary-label">Reservation #</span>
                                <span class="summary-value"><%= reservationNumber %></span>
                            </div>
                            <div class="summary-row">
                                <span class="summary-label">Room</span>
                                <span class="summary-value">Room <%= roomNumber %> (<%= roomTypeName %>)</span>
                            </div>
                            <div class="summary-row">
                                <span class="summary-label">Check-in</span>
                                <span class="summary-value"><%= checkInDate != null ? displaySdf.format(checkInDate) : "N/A" %></span>
                            </div>
                            <div class="summary-row">
                                <span class="summary-label">Check-out</span>
                                <span class="summary-value"><%= checkOutDate != null ? displaySdf.format(checkOutDate) : "N/A" %></span>
                            </div>
                            <div class="summary-row">
                                <span class="summary-label">Duration</span>
                                <span class="summary-value"><%= numberOfNights %> Night<%= numberOfNights > 1 ? "s" : "" %></span>
                            </div>
                            <div class="summary-row">
                                <span class="summary-label">Guests</span>
                                <span class="summary-value"><%= numberOfGuests %></span>
                            </div>
                            <div class="summary-row">
                                <span class="summary-label">Rate per Night</span>
                                <span class="summary-value">LKR <%= df.format(ratePerNight) %></span>
                            </div>
                            
                            <hr style="margin: 20px 0; border: none; border-top: 1px dashed #ddd;">
                            
                            <div class="summary-row">
                                <span class="summary-label">Room Total (<%= numberOfNights %> nights)</span>
                                <span class="summary-value">LKR <%= df.format(roomTotal) %></span>
                            </div>
                            <div class="summary-row">
                                <span class="summary-label">Service Charge (10%)</span>
                                <span class="summary-value">LKR <%= df.format(serviceCharge) %></span>
                            </div>
                            <div class="summary-row">
                                <span class="summary-label">Tax (5%)</span>
                                <span class="summary-value">LKR <%= df.format(taxAmount) %></span>
                            </div>
                            
                            <div class="summary-total">
                                <span class="label">Total Amount</span>
                                <span class="amount">LKR <%= df.format(totalAmount) %></span>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Right Column - Payment Form -->
                <div>
                    <div class="card">
                        <div class="card-header">
                            <i class="fas fa-money-check-alt"></i> Payment Details
                        </div>
                        <div class="card-body">
                            <form action="<%= request.getContextPath() %>/admin/admin-payment.jsp" method="post" id="paymentForm">
                                <input type="hidden" name="action" value="processPayment">
                                <input type="hidden" name="reservationId" value="<%= reservationId %>">
                                <input type="hidden" name="billId" value="<%= billId %>">
                                <input type="hidden" name="paymentMethod" id="paymentMethodInput" value="">
                                
                                <div class="form-group">
                                    <label><i class="fas fa-credit-card"></i> Select Payment Method *</label>
                                    <div class="payment-methods">
                                        <div class="payment-method" data-method="CASH" onclick="selectPaymentMethod(this)">
                                            <i class="fas fa-money-bill-wave" style="color: #28a745;"></i>
                                            <span>Cash</span>
                                        </div>
                                        <div class="payment-method" data-method="CARD" onclick="selectPaymentMethod(this)">
                                            <i class="fas fa-credit-card" style="color: #0077b6;"></i>
                                            <span>Card</span>
                                        </div>
                                        <div class="payment-method" data-method="BANK_TRANSFER" onclick="selectPaymentMethod(this)">
                                            <i class="fas fa-university" style="color: #6f42c1;"></i>
                                            <span>Bank Transfer</span>
                                        </div>
                                        <div class="payment-method" data-method="ONLINE" onclick="selectPaymentMethod(this)">
                                            <i class="fas fa-mobile-alt" style="color: #fd7e14;"></i>
                                            <span>Online</span>
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="form-group">
                                    <label><i class="fas fa-money-bill"></i> Amount to Pay (LKR) *</label>
                                    <input type="number" name="amountPaid" class="form-control" 
                                           value="<%= String.format("%.2f", totalAmount) %>" 
                                           step="0.01" min="0" max="<%= totalAmount %>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label><i class="fas fa-sticky-note"></i> Notes (Optional)</label>
                                    <textarea name="notes" class="form-control" rows="3" 
                                              placeholder="Any additional payment notes..."></textarea>
                                </div>
                                
                                <div style="display: flex; gap: 10px; margin-top: 25px;">
                                    <a href="<%= backLink %>" class="btn btn-secondary" style="flex: 1; justify-content: center;">
                                        <i class="fas fa-times"></i> Cancel
                                    </a>
                                    <button type="submit" class="btn btn-success" style="flex: 2; justify-content: center;">
                                        <i class="fas fa-check"></i> Confirm Payment
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                    
                    <!-- Payment Info Card -->
                    <div class="card">
                        <div class="card-body" style="background: #f8f9fa;">
                            <h4 style="margin-bottom: 15px; color: var(--text);"><i class="fas fa-info-circle" style="color: var(--primary);"></i> Payment Information</h4>
                            <ul style="list-style: none; color: var(--text-light); font-size: 0.9rem;">
                                <li style="margin-bottom: 8px;"><i class="fas fa-check-circle" style="color: var(--success); margin-right: 8px;"></i> Full payment is required to confirm booking</li>
                                <li style="margin-bottom: 8px;"><i class="fas fa-check-circle" style="color: var(--success); margin-right: 8px;"></i> Receipt will be generated after payment</li>
                                <li style="margin-bottom: 8px;"><i class="fas fa-check-circle" style="color: var(--success); margin-right: 8px;"></i> Guest will be notified via email</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        <% } %>
    </main>
    
    <script>
        // Show success/error messages
        <% if (successMessage != null) { %>
            Swal.fire({
                icon: 'success',
                title: 'Payment Successful!',
                text: '<%= escapeJs(successMessage) %>',
                confirmButtonColor: '#008080'
            });
        <% } %>
        
        <% if (errorMessage != null) { %>
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: '<%= escapeJs(errorMessage) %>',
                confirmButtonColor: '#008080'
            });
        <% } %>
        
        // Payment method selection
        function selectPaymentMethod(element) {
            // Remove selected class from all
            document.querySelectorAll('.payment-method').forEach(el => {
                el.classList.remove('selected');
            });
            
            // Add selected class to clicked element
            element.classList.add('selected');
            
            // Update hidden input
            document.getElementById('paymentMethodInput').value = element.getAttribute('data-method');
        }
        
        // Form validation
        document.getElementById('paymentForm').addEventListener('submit', function(e) {
            const paymentMethod = document.getElementById('paymentMethodInput').value;
            
            if (!paymentMethod) {
                e.preventDefault();
                Swal.fire({
                    icon: 'warning',
                    title: 'Payment Method Required',
                    text: 'Please select a payment method to continue.',
                    confirmButtonColor: '#008080'
                });
                return false;
            }
            
            // Confirm before processing
            e.preventDefault();
            Swal.fire({
                title: 'Confirm Payment',
                text: 'Are you sure you want to process this payment?',
                icon: 'question',
                showCancelButton: true,
                confirmButtonColor: '#28a745',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, Process Payment'
            }).then((result) => {
                if (result.isConfirmed) {
                    this.submit();
                }
            });
        });
    </script>
</body>
</html>
