<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%
    // Check if user is logged in
    String userRole = (String) session.getAttribute("userRole");
    if (userRole == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String idParam = request.getParameter("id");
    String typeParam = request.getParameter("type"); // "reservation" or "bill"
    if (idParam == null || idParam.trim().isEmpty()) {
        out.println("No ID provided");
        return;
    }
    
    int entityId = 0;
    try {
        entityId = Integer.parseInt(idParam.trim());
    } catch (NumberFormatException nfe) {
        out.println("Invalid ID provided");
        return;
    }
    
    // Database connection
    Connection conn = null;
    String dbUrl = "jdbc:mysql://localhost:3306/ocean_view_resort";
    String dbUser = "root";
    String dbPass = "";
    
    String billNumber = "", reservationNumber = "", guestName = "", guestPhone = "", guestEmail = "";
    String roomNumber = "", roomType = "", checkIn = "", checkOut = "", paymentMethod = "", paymentStatus = "";
    String generatedAt = "", paidAt = "", createdBy = "", guestAddress = "";
    double roomRate = 0, roomTotal = 0, additionalCharges = 0, discountAmount = 0, taxAmount = 0, totalAmount = 0;
    int nights = 0;
    boolean billExists = false;
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        PreparedStatement ps;
        
        // Check if looking up by reservation or bill
        if ("reservation".equals(typeParam)) {
            // Look up by reservation_id - get the bill for this reservation
            ps = conn.prepareStatement(
                "SELECT b.*, r.reservation_number, r.check_in_date, r.check_out_date, r.number_of_guests, " +
                "g.full_name, g.phone, g.email, g.address, " +
                "rm.room_number, rt.type_name, rt.rate_per_night, u.full_name as staff_name " +
                "FROM reservations r " +
                "LEFT JOIN bills b ON r.reservation_id = b.reservation_id " +
                "JOIN guests g ON r.guest_id = g.guest_id " +
                "JOIN rooms rm ON r.room_id = rm.room_id " +
                "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
                "LEFT JOIN users u ON r.created_by = u.user_id " +
                "WHERE r.reservation_id = ?"
            );
        } else {
            // Default: look up by bill_id
            ps = conn.prepareStatement(
                "SELECT b.*, r.reservation_number, r.check_in_date, r.check_out_date, r.number_of_guests, " +
                "g.full_name, g.phone, g.email, g.address, " +
                "rm.room_number, rt.type_name, rt.rate_per_night, u.full_name as staff_name " +
                "FROM bills b " +
                "JOIN reservations r ON b.reservation_id = r.reservation_id " +
                "JOIN guests g ON r.guest_id = g.guest_id " +
                "JOIN rooms rm ON r.room_id = rm.room_id " +
                "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
                "LEFT JOIN users u ON b.generated_by = u.user_id " +
                "WHERE b.bill_id = ?"
            );
        }
        ps.setInt(1, entityId);
        ResultSet rs = ps.executeQuery();
        
        if (rs.next()) {
            // Read common fields first (needed for calculations in no-bill scenario)
            reservationNumber = rs.getString("reservation_number");
            guestName = rs.getString("full_name");
            guestPhone = rs.getString("phone") != null ? rs.getString("phone") : "N/A";
            guestEmail = rs.getString("email") != null ? rs.getString("email") : "N/A";
            guestAddress = rs.getString("address") != null ? rs.getString("address") : "N/A";
            roomNumber = rs.getString("room_number");
            roomType = rs.getString("type_name");
            roomRate = rs.getDouble("rate_per_night");
            checkIn = rs.getDate("check_in_date").toString();
            checkOut = rs.getDate("check_out_date").toString();
            createdBy = rs.getString("staff_name") != null ? rs.getString("staff_name") : "System";
            
            // Check if bill exists (for reservation lookup, bill might be null)
            String billNum = rs.getString("bill_number");
            if (billNum != null) {
                billExists = true;
                billNumber = billNum;
                nights = rs.getInt("number_of_nights");
                roomTotal = rs.getDouble("room_total");
                additionalCharges = rs.getDouble("service_charge");
                discountAmount = rs.getDouble("discount");
                taxAmount = rs.getDouble("tax_amount");
                totalAmount = rs.getDouble("total_amount");
                paymentMethod = rs.getString("payment_method") != null ? rs.getString("payment_method") : "N/A";
                paymentStatus = rs.getString("payment_status") != null ? rs.getString("payment_status") : "PENDING";
                Timestamp genAt = rs.getTimestamp("generated_at");
                generatedAt = genAt != null ? new SimpleDateFormat("MMM dd, yyyy hh:mm a").format(genAt) : new SimpleDateFormat("MMM dd, yyyy hh:mm a").format(new java.util.Date());
                Timestamp pdAt = rs.getTimestamp("paid_at");
                paidAt = pdAt != null ? new SimpleDateFormat("MMM dd, yyyy hh:mm a").format(pdAt) : "Not Paid";
            } else {
                // No bill yet - calculate from reservation data
                billExists = false;
                billNumber = "DRAFT-" + System.currentTimeMillis();
                java.sql.Date ciDate = rs.getDate("check_in_date");
                java.sql.Date coDate = rs.getDate("check_out_date");
                long diffMillis = coDate.getTime() - ciDate.getTime();
                nights = (int) (diffMillis / (1000 * 60 * 60 * 24));
                if (nights < 1) nights = 1;
                roomTotal = roomRate * nights;
                taxAmount = roomTotal * 0.1; // 10% tax
                totalAmount = roomTotal + taxAmount;
                paymentMethod = "N/A";
                paymentStatus = "PENDING";
                generatedAt = new SimpleDateFormat("MMM dd, yyyy hh:mm a").format(new java.util.Date());
                paidAt = "Not Paid";
            }
        } else {
            out.println("Reservation/Invoice not found");
            return;
        }
        
        rs.close();
        ps.close();
        conn.close();
    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
        return;
    }
    
    DecimalFormat df = new DecimalFormat("#,###.00");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Invoice <%= billNumber %> - Ocean View Resort</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Poppins', sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        
        .invoice-container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        
        .no-print {
            text-align: center;
            margin-bottom: 20px;
        }
        
        .btn {
            padding: 12px 30px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-family: 'Poppins', sans-serif;
            font-weight: 500;
            font-size: 14px;
            margin: 0 5px;
            transition: all 0.3s ease;
        }
        
        .btn-print {
            background: linear-gradient(135deg, #004040, #008080);
            color: white;
        }
        
        .btn-download {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
        }
        
        .btn-back {
            background: #e0e0e0;
            color: #333;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        }
        
        .invoice-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 40px;
            padding-bottom: 20px;
            border-bottom: 3px solid #008080;
        }
        
        .hotel-info h1 {
            color: #004040;
            font-size: 28px;
            margin-bottom: 5px;
        }
        
        .hotel-info p {
            color: #666;
            font-size: 13px;
            line-height: 1.8;
        }
        
        .invoice-meta {
            text-align: right;
        }
        
        .invoice-meta h2 {
            color: #008080;
            font-size: 32px;
            margin-bottom: 10px;
        }
        
        .invoice-meta p {
            color: #666;
            font-size: 14px;
        }
        
        .invoice-meta .invoice-number {
            font-weight: 600;
            color: #333;
            font-size: 16px;
        }
        
        .status-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            margin-top: 10px;
        }
        
        .status-paid {
            background: rgba(40,167,69,0.15);
            color: #28a745;
        }
        
        .status-pending {
            background: rgba(255,193,7,0.15);
            color: #d39e00;
        }
        
        .guest-details {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            margin-bottom: 30px;
        }
        
        .detail-box {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
        }
        
        .detail-box h3 {
            color: #004040;
            font-size: 14px;
            margin-bottom: 15px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .detail-box p {
            color: #333;
            font-size: 14px;
            margin-bottom: 5px;
        }
        
        .detail-box p strong {
            color: #666;
            font-weight: 500;
        }
        
        .booking-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
        }
        
        .booking-table th {
            background: #004040;
            color: white;
            padding: 15px;
            text-align: left;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .booking-table td {
            padding: 15px;
            border-bottom: 1px solid #eee;
            font-size: 14px;
        }
        
        .booking-table tr:hover {
            background: #f8f9fa;
        }
        
        .summary-section {
            display: flex;
            justify-content: flex-end;
        }
        
        .summary-table {
            width: 350px;
        }
        
        .summary-table tr td {
            padding: 10px 15px;
            font-size: 14px;
        }
        
        .summary-table tr td:first-child {
            text-align: left;
            color: #666;
        }
        
        .summary-table tr td:last-child {
            text-align: right;
            color: #333;
            font-weight: 500;
        }
        
        .summary-table .total-row {
            border-top: 2px solid #008080;
            background: #f8f9fa;
        }
        
        .summary-table .total-row td {
            font-size: 18px;
            font-weight: 700;
            color: #004040;
            padding: 15px;
        }
        
        .invoice-footer {
            margin-top: 40px;
            padding-top: 30px;
            border-top: 1px solid #eee;
            text-align: center;
        }
        
        .invoice-footer h4 {
            color: #008080;
            margin-bottom: 10px;
        }
        
        .invoice-footer p {
            color: #666;
            font-size: 13px;
            line-height: 1.8;
        }
        
        .terms {
            margin-top: 20px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 8px;
            font-size: 12px;
            color: #666;
        }
        
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
                padding: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="no-print">
        <button class="btn btn-print" onclick="window.print()"><i class="fas fa-print"></i> Print Invoice</button>
        <button class="btn btn-download" onclick="downloadPDF()">Download PDF</button>
        <button class="btn btn-back" onclick="window.close()">Close</button>
    </div>
    
    <div class="invoice-container" id="invoiceContent">
        <div class="invoice-header">
            <div class="hotel-info">
                <img src="../images/logo.png" alt="Ocean View Resort" style="height: 60px; margin-bottom: 10px;">
                <h1>Ocean View Resort</h1>
                <p>
                    No. 123, Beach Road<br>
                    Unawatuna, Galle, Sri Lanka<br>
                    Phone: +94 91 222 4455<br>
                    Email: info@oceanviewresort.lk<br>
                    Website: www.oceanviewresort.lk
                </p>
            </div>
            <div class="invoice-meta">
                <h2>INVOICE</h2>
                <p class="invoice-number"><%= billNumber %></p>
                <p>Reservation: <%= reservationNumber %></p>
                <p>Date: <%= generatedAt %></p>
                <span class="status-badge <%= "PAID".equals(paymentStatus) ? "status-paid" : "status-pending" %>">
                    <%= paymentStatus %>
                </span>
            </div>
        </div>
        
        <div class="guest-details">
            <div class="detail-box">
                <h3>Bill To</h3>
                <p><strong>Name:</strong> <%= guestName %></p>
                <p><strong>Phone:</strong> <%= guestPhone %></p>
                <p><strong>Email:</strong> <%= guestEmail %></p>
                <p><strong>Address:</strong> <%= guestAddress %></p>
            </div>
            <div class="detail-box">
                <h3>Stay Details</h3>
                <p><strong>Room:</strong> <%= roomNumber %> (<%= roomType %>)</p>
                <p><strong>Check-in:</strong> <%= checkIn %></p>
                <p><strong>Check-out:</strong> <%= checkOut %></p>
                <p><strong>Duration:</strong> <%= nights %> Night(s)</p>
            </div>
        </div>
        
        <table class="booking-table">
            <thead>
                <tr>
                    <th>Description</th>
                    <th>Rate</th>
                    <th>Qty/Nights</th>
                    <th style="text-align: right;">Amount</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>
                        <strong>Room Accommodation</strong><br>
                        <span style="color: #666; font-size: 12px;"><%= roomType %> - Room <%= roomNumber %></span>
                    </td>
                    <td>Rs. <%= df.format(roomRate) %></td>
                    <td><%= nights %> night(s)</td>
                    <td style="text-align: right;">Rs. <%= df.format(roomTotal) %></td>
                </tr>
                <% if (additionalCharges > 0) { %>
                <tr>
                    <td><strong>Additional Services</strong></td>
                    <td>-</td>
                    <td>-</td>
                    <td style="text-align: right;">Rs. <%= df.format(additionalCharges) %></td>
                </tr>
                <% } %>
            </tbody>
        </table>
        
        <div class="summary-section">
            <table class="summary-table">
                <tr>
                    <td>Room Total:</td>
                    <td>Rs. <%= df.format(roomTotal) %></td>
                </tr>
                <% if (additionalCharges > 0) { %>
                <tr>
                    <td>Additional Charges:</td>
                    <td>Rs. <%= df.format(additionalCharges) %></td>
                </tr>
                <% } %>
                <% if (discountAmount > 0) { %>
                <tr style="color: #28a745;">
                    <td>Discount:</td>
                    <td>- Rs. <%= df.format(discountAmount) %></td>
                </tr>
                <% } %>
                <tr>
                    <td>Tax (VAT):</td>
                    <td>Rs. <%= df.format(taxAmount) %></td>
                </tr>
                <tr class="total-row">
                    <td>Grand Total:</td>
                    <td>Rs. <%= df.format(totalAmount) %></td>
                </tr>
            </table>
        </div>
        
        <div class="detail-box" style="margin-top: 30px;">
            <h3>Payment Information</h3>
            <p><strong>Payment Method:</strong> <%= paymentMethod %></p>
            <p><strong>Payment Status:</strong> <%= paymentStatus %></p>
            <p><strong>Paid At:</strong> <%= paidAt %></p>
            <p><strong>Processed By:</strong> <%= createdBy %></p>
        </div>
        
        <div class="terms">
            <strong>Terms & Conditions:</strong>
            <ul style="margin-top: 10px; padding-left: 20px;">
                <li>Check-in time: 2:00 PM | Check-out time: 12:00 PM</li>
                <li>Early check-in or late check-out is subject to availability and additional charges.</li>
                <li>Cancellation policy: 24 hours prior notice required.</li>
                <li>All rates are inclusive of applicable taxes unless stated otherwise.</li>
            </ul>
        </div>
        
        <div class="invoice-footer">
            <h4>Thank You for Choosing Ocean View Resort!</h4>
            <p>
                We hope you enjoyed your stay with us. We look forward to welcoming you again.<br>
                For feedback or inquiries, please contact us at <strong>feedback@oceanviewresort.lk</strong>
            </p>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/jspdf@2.5.1/dist/jspdf.umd.min.js"></script>
    <script>
        async function downloadPDF() {
            const invoice = document.getElementById('invoiceContent');
            if (!invoice) return;

            const originalBodyBg = document.body.style.background;
            document.body.style.background = '#ffffff';

            try {
                const canvas = await html2canvas(invoice, {
                    scale: 2,
                    useCORS: true,
                    backgroundColor: '#ffffff'
                });

                const { jsPDF } = window.jspdf;
                const pdf = new jsPDF('p', 'mm', 'a4');
                const pageWidth = pdf.internal.pageSize.getWidth();
                const pageHeight = pdf.internal.pageSize.getHeight();

                const imgData = canvas.toDataURL('image/png');
                const imgWidth = pageWidth;
                const imgHeight = (canvas.height * imgWidth) / canvas.width;

                let y = 0;
                let remaining = imgHeight;

                pdf.addImage(imgData, 'PNG', 0, y, imgWidth, imgHeight);
                remaining -= pageHeight;

                while (remaining > 0) {
                    y = remaining - imgHeight;
                    pdf.addPage();
                    pdf.addImage(imgData, 'PNG', 0, y, imgWidth, imgHeight);
                    remaining -= pageHeight;
                }

                pdf.save('invoice-<%= billNumber %>.pdf');
            } catch (e) {
                alert('PDF download failed. Please use Print and choose Save as PDF.');
                window.print();
            } finally {
                document.body.style.background = originalBodyBg;
            }
        }
    </script>
</body>
</html>
