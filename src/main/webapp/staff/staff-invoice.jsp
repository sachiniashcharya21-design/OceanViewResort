<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.text.SimpleDateFormat, java.text.DecimalFormat" %>
<%
    // Session check - STAFF role validation
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
    
    // Get bill ID from parameters (supports both billId and reservationId)
    int billId = 0;
    int reservationId = 0;
    
    try {
        String billIdParam = request.getParameter("billId");
        String resIdParam = request.getParameter("reservationId");
        
        if (billIdParam != null && !billIdParam.isEmpty()) {
            billId = Integer.parseInt(billIdParam);
        } else if (resIdParam != null && !resIdParam.isEmpty()) {
            reservationId = Integer.parseInt(resIdParam);
            // Lookup billId from reservationId
            Connection tempConn = null;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                tempConn = DriverManager.getConnection("jdbc:mysql://localhost:3306/ocean_view_resort", "root", "");
                PreparedStatement ps = tempConn.prepareStatement("SELECT bill_id FROM bills WHERE reservation_id = ?");
                ps.setInt(1, reservationId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    billId = rs.getInt("bill_id");
                }
                rs.close();
                ps.close();
            } finally {
                if (tempConn != null) try { tempConn.close(); } catch (Exception e) {}
            }
        }
        
        if (billId == 0) {
            response.sendRedirect(request.getContextPath() + "/staff/staff-customers.jsp?error=Invoice+not+found");
            return;
        }
    } catch (Exception e) {
        response.sendRedirect(request.getContextPath() + "/staff/staff-customers.jsp");
        return;
    }
    
    // Database connection
    Connection conn = null;
    DecimalFormat df = new DecimalFormat("#,##0.00");
    SimpleDateFormat displaySdf = new SimpleDateFormat("MMM dd, yyyy");
    SimpleDateFormat dateSdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    
    // Invoice details
    String billNumber = "";
    String reservationNumber = "";
    String guestName = "";
    String guestEmail = "";
    String guestPhone = "";
    String guestNic = "";
    String guestAddress = "";
    String roomNumber = "";
    String roomTypeName = "";
    double ratePerNight = 0;
    java.sql.Date checkInDate = null;
    java.sql.Date checkOutDate = null;
    int numberOfNights = 0;
    double roomTotal = 0;
    double serviceCharge = 0;
    double taxAmount = 0;
    double totalAmount = 0;
    String paymentStatus = "";
    String paymentMethod = "";
    java.sql.Timestamp paidAt = null;
    java.sql.Timestamp generatedAt = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/ocean_view_resort", "root", "");
        
        // Fetch bill with reservation, guest and room info
        PreparedStatement ps = conn.prepareStatement(
            "SELECT b.*, r.reservation_number, r.check_in_date, r.check_out_date, " +
            "g.full_name, g.email, g.phone, g.nic_passport, g.address, " +
            "ro.room_number, rt.type_name, rt.rate_per_night " +
            "FROM bills b " +
            "JOIN reservations r ON b.reservation_id = r.reservation_id " +
            "JOIN guests g ON r.guest_id = g.guest_id " +
            "JOIN rooms ro ON r.room_id = ro.room_id " +
            "JOIN room_types rt ON ro.room_type_id = rt.room_type_id " +
            "WHERE b.bill_id = ?"
        );
        ps.setInt(1, billId);
        ResultSet rs = ps.executeQuery();
        
        if (rs.next()) {
            billNumber = rs.getString("bill_number");
            reservationNumber = rs.getString("reservation_number");
            guestName = rs.getString("full_name");
            if (guestName == null) guestName = "Guest";
            guestEmail = rs.getString("email");
            guestPhone = rs.getString("phone");
            guestNic = rs.getString("nic_passport");
            guestAddress = rs.getString("address");
            roomNumber = rs.getString("room_number");
            roomTypeName = rs.getString("type_name");
            ratePerNight = rs.getDouble("rate_per_night");
            checkInDate = rs.getDate("check_in_date");
            checkOutDate = rs.getDate("check_out_date");
            numberOfNights = rs.getInt("number_of_nights");
            roomTotal = rs.getDouble("room_total");
            serviceCharge = rs.getDouble("service_charge");
            taxAmount = rs.getDouble("tax_amount");
            totalAmount = rs.getDouble("total_amount");
            paymentStatus = rs.getString("payment_status");
            paymentMethod = rs.getString("payment_method");
            paidAt = rs.getTimestamp("paid_at");
            generatedAt = rs.getTimestamp("generated_at");
        } else {
            response.sendRedirect(request.getContextPath() + "/staff/staff-customers.jsp?error=Bill+not+found");
            return;
        }
        rs.close();
        ps.close();
        
    } catch (Exception e) {
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
    <title>Invoice #<%= billNumber %> - Ocean View Resort</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
    <style>
        :root {
            --primary: #008080;
            --primary-dark: #004040;
            --glow: #00C0C0;
            --bg: #f5f7fa;
            --text: #333333;
            --text-light: #666666;
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
            padding: 20px;
        }
        
        .no-print {
            text-align: center;
            margin-bottom: 20px;
        }
        
        .btn {
            padding: 12px 25px;
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
            margin: 5px;
        }
        
        .btn-primary {
            background: var(--primary);
            color: white;
        }
        
        .btn-primary:hover {
            background: var(--primary-dark);
        }
        
        .btn-success {
            background: #28a745;
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
        
        /* Invoice Container */
        .invoice-container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        /* Invoice Header */
        .invoice-header {
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
            color: white;
            padding: 10px 10px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .logo-section {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .logo-img {
            width: 150px;
            height: 150px;
            object-fit: contain;
            border-radius: 8px;
        }
        
        .logo-text h1 {
            font-size: 1.8rem;
            font-weight: 700;
            margin-bottom: 5px;
        }
        
        .logo-text p {
            font-size: 0.9rem;
            opacity: 0.9;
        }
        
        .invoice-title {
            text-align: right;
        }
        
        .invoice-title h2 {
            font-size: 2rem;
            font-weight: 700;
            margin-bottom: 5px;
        }
        
        .invoice-title p {
            font-size: 0.95rem;
            opacity: 0.9;
        }
        
        /* Invoice Body */
        .invoice-body {
            padding: 40px;
        }
        
        /* Info Grid */
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            margin-bottom: 30px;
        }
        
        .info-box h3 {
            font-size: 0.85rem;
            color: var(--primary);
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
            padding-bottom: 8px;
            border-bottom: 2px solid var(--primary);
        }
        
        .info-box p {
            font-size: 0.95rem;
            color: var(--text);
            margin-bottom: 5px;
        }
        
        .info-box p strong {
            color: var(--text);
        }
        
        .info-box p span {
            color: var(--text-light);
        }
        
        /* Items Table */
        .invoice-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
        }
        
        .invoice-table thead {
            background: linear-gradient(135deg, var(--primary-dark), var(--primary));
        }
        
        .invoice-table th {
            padding: 15px;
            text-align: left;
            color: white;
            font-weight: 500;
            font-size: 0.9rem;
        }
        
        .invoice-table th:last-child {
            text-align: right;
        }
        
        .invoice-table td {
            padding: 15px;
            border-bottom: 1px solid #eee;
            color: var(--text);
        }
        
        .invoice-table td:last-child {
            text-align: right;
            font-weight: 500;
        }
        
        .invoice-table tbody tr:hover {
            background: #f8f9fa;
        }
        
        /* Totals Section */
        .totals-section {
            display: flex;
            justify-content: flex-end;
        }
        
        .totals-box {
            width: 300px;
        }
        
        .totals-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }
        
        .totals-row.grand-total {
            background: linear-gradient(135deg, var(--primary-dark), var(--primary));
            color: white;
            margin: 15px -15px -15px;
            padding: 20px 15px;
            border-radius: 0 0 10px 10px;
            border: none;
        }
        
        .totals-row .label {
            color: var(--text-light);
        }
        
        .totals-row .value {
            font-weight: 600;
            color: var(--text);
        }
        
        .totals-row.grand-total .label,
        .totals-row.grand-total .value {
            color: white;
            font-size: 1.1rem;
        }
        
        /* Payment Info */
        .payment-info {
            background: #e8f5f5;
            border-radius: 10px;
            padding: 20px;
            margin-top: 30px;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .payment-icon {
            width: 50px;
            height: 50px;
            background: var(--primary);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.5rem;
        }
        
        .payment-details h4 {
            color: var(--primary-dark);
            margin-bottom: 5px;
        }
        
        .payment-details p {
            color: var(--text-light);
            font-size: 0.9rem;
        }
        
        /* Footer */
        .invoice-footer {
            background: #f8f9fa;
            padding: 25px 40px;
            text-align: center;
            border-top: 2px dashed #ddd;
        }
        
        .invoice-footer h4 {
            color: var(--primary);
            margin-bottom: 10px;
        }
        
        .invoice-footer p {
            color: var(--text-light);
            font-size: 0.85rem;
            margin-bottom: 5px;
        }
        
        .invoice-footer .contact-info {
            display: flex;
            justify-content: center;
            gap: 30px;
            margin-top: 15px;
        }
        
        .invoice-footer .contact-item {
            display: flex;
            align-items: center;
            gap: 8px;
            color: var(--text-light);
            font-size: 0.85rem;
        }
        
        .invoice-footer .contact-item i {
            color: var(--primary);
        }
        
        /* Status Badge */
        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
        }
        
        .status-paid {
            background: #d4edda;
            color: #155724;
        }
        
        .status-pending {
            background: #fff3cd;
            color: #856404;
        }
        
        /* PDF Mode - Compact for single page */
        .pdf-mode {
            max-width: 100% !important;
        }
        
        .pdf-mode .invoice-header {
            padding: 20px 30px !important;
        }
        
        .pdf-mode .logo-img {
            width: 50px !important;
            height: 50px !important;
        }
        
        .pdf-mode .logo-text h1 {
            font-size: 1.4rem !important;
        }
        
        .pdf-mode .logo-text p {
            font-size: 0.8rem !important;
        }
        
        .pdf-mode .invoice-title h2 {
            font-size: 1.5rem !important;
        }
        
        .pdf-mode .invoice-body {
            padding: 25px 30px !important;
        }
        
        .pdf-mode .info-grid {
            gap: 20px !important;
            margin-bottom: 20px !important;
        }
        
        .pdf-mode .info-box h3 {
            font-size: 0.75rem !important;
            margin-bottom: 6px !important;
            padding-bottom: 5px !important;
        }
        
        .pdf-mode .info-box p {
            font-size: 0.85rem !important;
            margin-bottom: 3px !important;
        }
        
        .pdf-mode .invoice-table th,
        .pdf-mode .invoice-table td {
            padding: 10px !important;
            font-size: 0.85rem !important;
        }
        
        .pdf-mode .totals-row {
            padding: 8px 0 !important;
        }
        
        .pdf-mode .totals-row.grand-total {
            padding: 12px 15px !important;
        }
        
        .pdf-mode .payment-info {
            padding: 15px !important;
            margin-top: 20px !important;
        }
        
        .pdf-mode .payment-icon {
            width: 40px !important;
            height: 40px !important;
            font-size: 1.2rem !important;
        }
        
        .pdf-mode .invoice-footer {
            padding: 15px 30px !important;
        }
        
        .pdf-mode .invoice-footer h4 {
            font-size: 0.9rem !important;
        }
        
        .pdf-mode .invoice-footer p,
        .pdf-mode .invoice-footer .contact-item {
            font-size: 0.75rem !important;
        }
        
        /* Print Styles */
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .no-print {
                display: none !important;
            }
            
            .invoice-container {
                box-shadow: none;
                border-radius: 0;
            }
        }
    </style>
</head>
<body>
    <!-- Action Buttons (No Print) -->
    <div class="no-print">
        <button class="btn btn-success" onclick="downloadPDF()">
            <i class="fas fa-file-pdf"></i> Download PDF
        </button>
        <button class="btn btn-primary" onclick="window.print()">
            <i class="fas fa-print"></i> Print Invoice
        </button>
        <a href="${pageContext.request.contextPath}/staff/staff-payments.jsp" class="btn btn-secondary">
            <i class="fas fa-arrow-left"></i> Back to Payments
        </a>
        <a href="${pageContext.request.contextPath}/staff/staff-dashboard.jsp" class="btn btn-secondary">
            <i class="fas fa-tachometer-alt"></i> Dashboard
        </a>
    </div>
    
    <!-- Invoice -->
    <div class="invoice-container" id="invoice">
        <!-- Header -->
        <div class="invoice-header">
            <div class="logo-section">
                <img src="${pageContext.request.contextPath}/images/logo.png" alt="Ocean View Resort" class="logo-img">
                <div class="logo-text">
                    <h1>Ocean View Resort</h1>
                    <p>Luxury Beachfront Hotel, Galle, Sri Lanka</p>
                </div>
            </div>
            <div class="invoice-title">
                <h2>INVOICE</h2>
                <p>#<%= billNumber %></p>
            </div>
        </div>
        
        <!-- Body -->
        <div class="invoice-body">
            <!-- Info Grid -->
            <div class="info-grid">
                <div class="info-box">
                    <h3><i class="fas fa-user"></i> Bill To</h3>
                    <p><strong><%= guestName %></strong></p>
                    <p><span>NIC/Passport:</span> <%= guestNic != null && !guestNic.isEmpty() ? guestNic : "N/A" %></p>
                    <p><span>Phone:</span> <%= guestPhone != null && !guestPhone.isEmpty() ? guestPhone : "N/A" %></p>
                    <p><span>Email:</span> <%= guestEmail != null && !guestEmail.isEmpty() ? guestEmail : "N/A" %></p>
                    <p><span>Address:</span> <%= guestAddress != null && !guestAddress.isEmpty() ? guestAddress : "N/A" %></p>
                </div>
                <div class="info-box">
                    <h3><i class="fas fa-calendar-check"></i> Booking Details</h3>
                    <p><strong>Reservation #:</strong> <%= reservationNumber %></p>
                    <p><strong>Room:</strong> <%= roomNumber %> (<%= roomTypeName %>)</p>
                    <p><strong>Check-in:</strong> <%= checkInDate != null ? displaySdf.format(checkInDate) : "N/A" %></p>
                    <p><strong>Check-out:</strong> <%= checkOutDate != null ? displaySdf.format(checkOutDate) : "N/A" %></p>
                    <p><strong>Duration:</strong> <%= numberOfNights %> Night<%= numberOfNights > 1 ? "s" : "" %></p>
                </div>
            </div>
            
            <!-- Items Table -->
            <table class="invoice-table">
                <thead>
                    <tr>
                        <th>Description</th>
                        <th>Rate</th>
                        <th>Qty</th>
                        <th>Amount</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>
                            <strong>Room Accommodation</strong><br>
                            <span style="color: var(--text-light); font-size: 0.85rem;">
                                Room <%= roomNumber %> - <%= roomTypeName %>
                            </span>
                        </td>
                        <td>LKR <%= df.format(ratePerNight) %></td>
                        <td><%= numberOfNights %> Night<%= numberOfNights > 1 ? "s" : "" %></td>
                        <td>LKR <%= df.format(roomTotal) %></td>
                    </tr>
                    <tr>
                        <td>Service Charge (10%)</td>
                        <td>-</td>
                        <td>-</td>
                        <td>LKR <%= df.format(serviceCharge) %></td>
                    </tr>
                    <tr>
                        <td>Tax (5%)</td>
                        <td>-</td>
                        <td>-</td>
                        <td>LKR <%= df.format(taxAmount) %></td>
                    </tr>
                </tbody>
            </table>
            
            <!-- Totals -->
            <div class="totals-section">
                <div class="totals-box">
                    <div class="totals-row">
                        <span class="label">Subtotal</span>
                        <span class="value">LKR <%= df.format(roomTotal) %></span>
                    </div>
                    <div class="totals-row">
                        <span class="label">Service Charge</span>
                        <span class="value">LKR <%= df.format(serviceCharge) %></span>
                    </div>
                    <div class="totals-row">
                        <span class="label">Tax</span>
                        <span class="value">LKR <%= df.format(taxAmount) %></span>
                    </div>
                    <div class="totals-row grand-total">
                        <span class="label">Total Amount</span>
                        <span class="value">LKR <%= df.format(totalAmount) %></span>
                    </div>
                </div>
            </div>
            
            <!-- Payment Info -->
            <div class="payment-info">
                <div class="payment-icon">
                    <i class="fas fa-<%= "PAID".equals(paymentStatus) ? "check-circle" : "clock" %>"></i>
                </div>
                <div class="payment-details">
                    <h4>Payment Status: 
                        <span class="status-badge status-<%= paymentStatus.toLowerCase() %>">
                            <i class="fas fa-<%= "PAID".equals(paymentStatus) ? "check" : "hourglass-half" %>"></i>
                            <%= paymentStatus %>
                        </span>
                    </h4>
                    <% if ("PAID".equals(paymentStatus)) { %>
                        <p>
                            <strong>Method:</strong> <%= paymentMethod != null ? paymentMethod.replace("_", " ") : "N/A" %> | 
                            <strong>Paid on:</strong> <%= paidAt != null ? displaySdf.format(paidAt) : "N/A" %>
                        </p>
                    <% } else { %>
                        <p>Payment is pending. Please complete the payment to confirm your booking.</p>
                    <% } %>
                </div>
            </div>
        </div>
        
        <!-- Footer -->
        <div class="invoice-footer">
            <h4>Thank You for Choosing Ocean View Resort!</h4>
            <p>We hope you enjoyed your stay. Looking forward to welcoming you again.</p>
            <div class="contact-info">
                <div class="contact-item">
                    <i class="fas fa-phone"></i> +94 91 223 4567
                </div>
                <div class="contact-item">
                    <i class="fas fa-envelope"></i> info@oceanviewresort.lk
                </div>
                <div class="contact-item">
                    <i class="fas fa-globe"></i> www.oceanviewresort.lk
                </div>
            </div>
        </div>
    </div>
    
    <script>
        function downloadPDF() {
            const element = document.getElementById('invoice');
            const opt = {
                margin: [0.2, 0.3, 0.2, 0.3],
                filename: 'Invoice_<%= billNumber %>.pdf',
                image: { type: 'jpeg', quality: 0.95 },
                html2canvas: { 
                    scale: 1.5, 
                    useCORS: true,
                    logging: false
                },
                jsPDF: { 
                    unit: 'in', 
                    format: 'a4', 
                    orientation: 'portrait'
                },
                pagebreak: { mode: 'avoid-all' }
            };
            
            // Add class to shrink content for PDF
            element.classList.add('pdf-mode');
            document.querySelector('.no-print').style.display = 'none';
            
            html2pdf().set(opt).from(element).save().then(() => {
                element.classList.remove('pdf-mode');
                document.querySelector('.no-print').style.display = 'block';
            });
        }
    </script>
</body>
</html>
