<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.util.*" %>
<%
    // Check if user is logged in (allow both ADMIN and STAFF)
    String userRole = (String) session.getAttribute("userRole");
    if (userRole == null || (!("ADMIN".equalsIgnoreCase(userRole)) && !("STAFF".equalsIgnoreCase(userRole)))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String dashboardLink = "ADMIN".equalsIgnoreCase(userRole)
        ? request.getContextPath() + "/admin/admin-dashboard.jsp"
        : request.getContextPath() + "/staff/staff-dashboard.jsp";
    
    String period = request.getParameter("period");
    if (period == null) period = "monthly";
    
    String periodTitle = "Monthly";
    String dateCondition = "MONTH(generated_at) = MONTH(CURDATE()) AND YEAR(generated_at) = YEAR(CURDATE())";
    String startDate = "", endDate = "";
    
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    SimpleDateFormat displaySdf = new SimpleDateFormat("MMMM dd, yyyy");
    Calendar cal = Calendar.getInstance();
    
    if ("daily".equals(period)) {
        periodTitle = "Daily";
        dateCondition = "DATE(generated_at) = CURDATE()";
        startDate = endDate = displaySdf.format(new java.util.Date());
    } else if ("weekly".equals(period)) {
        periodTitle = "Weekly";
        dateCondition = "YEARWEEK(generated_at) = YEARWEEK(CURDATE())";
        cal.set(Calendar.DAY_OF_WEEK, cal.getFirstDayOfWeek());
        startDate = displaySdf.format(cal.getTime());
        cal.add(Calendar.DAY_OF_WEEK, 6);
        endDate = displaySdf.format(cal.getTime());
    } else {
        cal.set(Calendar.DAY_OF_MONTH, 1);
        startDate = displaySdf.format(cal.getTime());
        cal.set(Calendar.DAY_OF_MONTH, cal.getActualMaximum(Calendar.DAY_OF_MONTH));
        endDate = displaySdf.format(cal.getTime());
    }
    
    // Database connection
    Connection conn = null;
    String dbUrl = "jdbc:mysql://localhost:3306/ocean_view_resort";
    String dbUser = "root";
    String dbPass = "";
    
    double totalRevenue = 0, roomRevenue = 0, additionalRevenue = 0, taxRevenue = 0, discountGiven = 0;
    int totalBookings = 0, confirmedBookings = 0, cancelledBookings = 0, checkedInBookings = 0, checkedOutBookings = 0;
    int newGuests = 0, totalBills = 0, paidBills = 0, pendingBills = 0;
    int cashPayments = 0, cardPayments = 0, bankPayments = 0;
    
    DecimalFormat df = new DecimalFormat("#,###.00");
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        Statement stmt = conn.createStatement();
        ResultSet rs;
        
        // Revenue
        rs = stmt.executeQuery("SELECT IFNULL(SUM(total_amount), 0) as total, IFNULL(SUM(room_total), 0) as room, IFNULL(SUM(additional_charges), 0) as additional, IFNULL(SUM(tax_amount), 0) as tax, IFNULL(SUM(discount_amount), 0) as discount FROM bills WHERE payment_status = 'PAID' AND " + dateCondition);
        if (rs.next()) {
            totalRevenue = rs.getDouble("total");
            roomRevenue = rs.getDouble("room");
            additionalRevenue = rs.getDouble("additional");
            taxRevenue = rs.getDouble("tax");
            discountGiven = rs.getDouble("discount");
        }
        rs.close();
        
        // Bookings
        String resDateCondition = dateCondition.replace("generated_at", "created_at");
        rs = stmt.executeQuery("SELECT COUNT(*) as total FROM reservations WHERE " + resDateCondition);
        if (rs.next()) totalBookings = rs.getInt("total");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM reservations WHERE status = 'CONFIRMED' AND " + resDateCondition);
        if (rs.next()) confirmedBookings = rs.getInt("cnt");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM reservations WHERE status = 'CANCELLED' AND " + resDateCondition);
        if (rs.next()) cancelledBookings = rs.getInt("cnt");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM reservations WHERE status = 'CHECKED_IN' AND " + resDateCondition);
        if (rs.next()) checkedInBookings = rs.getInt("cnt");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM reservations WHERE status = 'CHECKED_OUT' AND " + resDateCondition);
        if (rs.next()) checkedOutBookings = rs.getInt("cnt");
        rs.close();
        
        // Guests
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM guests WHERE " + dateCondition.replace("generated_at", "created_at"));
        if (rs.next()) newGuests = rs.getInt("cnt");
        rs.close();
        
        // Bills
        rs = stmt.executeQuery("SELECT COUNT(*) as total FROM bills WHERE " + dateCondition);
        if (rs.next()) totalBills = rs.getInt("total");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM bills WHERE payment_status = 'PAID' AND " + dateCondition);
        if (rs.next()) paidBills = rs.getInt("cnt");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM bills WHERE payment_status = 'PENDING' AND " + dateCondition);
        if (rs.next()) pendingBills = rs.getInt("cnt");
        rs.close();
        
        // Payment methods
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM bills WHERE payment_method = 'CASH' AND payment_status = 'PAID' AND " + dateCondition);
        if (rs.next()) cashPayments = rs.getInt("cnt");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM bills WHERE payment_method = 'CARD' AND payment_status = 'PAID' AND " + dateCondition);
        if (rs.next()) cardPayments = rs.getInt("cnt");
        rs.close();
        
        rs = stmt.executeQuery("SELECT COUNT(*) as cnt FROM bills WHERE payment_method = 'BANK_TRANSFER' AND payment_status = 'PAID' AND " + dateCondition);
        if (rs.next()) bankPayments = rs.getInt("cnt");
        rs.close();
        
        stmt.close();
    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= periodTitle %> Report - Ocean View Resort</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/jspdf@2.5.1/dist/jspdf.umd.min.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Poppins', sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        
        .report-container {
            max-width: 900px;
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
        
        .btn-print { background: linear-gradient(135deg, #004040, #008080); color: white; }
        .btn-download { background: linear-gradient(135deg, #1f9d55, #28a745); color: white; }
        .btn-back { background: #e0e0e0; color: #333; }
        .btn:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,0,0,0.2); }
        
        .report-header {
            text-align: center;
            margin-bottom: 40px;
            padding-bottom: 20px;
            border-bottom: 3px solid #008080;
        }
        
        .report-header h1 { color: #004040; font-size: 28px; margin-bottom: 5px; }
        .report-header h2 { color: #008080; font-size: 20px; margin-bottom: 15px; }
        .report-header p { color: #666; font-size: 14px; }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: linear-gradient(135deg, #004040, #008080);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        
        .stat-card h3 { font-size: 24px; margin-bottom: 5px; }
        .stat-card p { font-size: 12px; opacity: 0.9; }
        
        .section { margin-bottom: 30px; }
        .section h3 {
            color: #004040;
            font-size: 16px;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #f0f0f0;
        }
        
        .data-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .data-table th, .data-table td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        
        .data-table th {
            background: #f8f9fa;
            color: #004040;
            font-weight: 600;
            font-size: 13px;
        }
        
        .data-table tr:hover { background: #f8f9fa; }
        
        .chart-container {
            height: 250px;
            margin-bottom: 30px;
        }
        
        .two-col {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
        }
        
        .summary-box {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
        }
        
        .summary-box h4 {
            color: #004040;
            margin-bottom: 15px;
            font-size: 14px;
        }
        
        .summary-item {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px dashed #ddd;
        }
        
        .summary-item:last-child { border-bottom: none; }
        .summary-item .label { color: #666; }
        .summary-item .value { color: #333; font-weight: 600; }
        
        .total-row {
            background: linear-gradient(135deg, #004040, #008080);
            color: white;
            padding: 15px 20px;
            border-radius: 10px;
            display: flex;
            justify-content: space-between;
            margin-top: 20px;
        }
        
        .total-row .label { font-size: 16px; }
        .total-row .value { font-size: 24px; font-weight: 700; }
        
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            text-align: center;
            color: #666;
            font-size: 12px;
        }
        
        @media print {
            body { background: white; padding: 0; }
            .no-print { display: none !important; }
            .report-container { box-shadow: none; }
            .chart-container { page-break-inside: avoid; }
        }
    </style>
</head>
<body>
    <div class="no-print">
        <button class="btn btn-download" onclick="downloadReportPdf()">Download PDF</button>
        <button class="btn btn-print" onclick="window.print()">🖨️ Print Report</button>
        <a href="<%= dashboardLink %>" class="btn btn-back">← Back to Dashboard</a>
    </div>
    
    <div class="report-container">
        <div class="report-header">
            <h1>🏨 Ocean View Resort</h1>
            <h2><%= periodTitle %> Report</h2>
            <p>Period: <%= startDate %> - <%= endDate %></p>
            <p>Generated: <%= new SimpleDateFormat("MMMM dd, yyyy hh:mm a").format(new java.util.Date()) %></p>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <h3>Rs. <%= df.format(totalRevenue) %></h3>
                <p>Total Revenue</p>
            </div>
            <div class="stat-card" style="background: linear-gradient(135deg, #667eea, #764ba2);">
                <h3><%= totalBookings %></h3>
                <p>Reservations</p>
            </div>
            <div class="stat-card" style="background: linear-gradient(135deg, #f093fb, #f5576c);">
                <h3><%= newGuests %></h3>
                <p>New Guests</p>
            </div>
            <div class="stat-card" style="background: linear-gradient(135deg, #43e97b, #38f9d7); color: #004040;">
                <h3><%= paidBills %></h3>
                <p>Paid Bills</p>
            </div>
        </div>
        
        <div class="two-col">
            <div class="section">
                <h3>📊 Revenue Breakdown</h3>
                <div class="summary-box">
                    <div class="summary-item">
                        <span class="label">Room Revenue</span>
                        <span class="value">Rs. <%= df.format(roomRevenue) %></span>
                    </div>
                    <div class="summary-item">
                        <span class="label">Additional Services</span>
                        <span class="value">Rs. <%= df.format(additionalRevenue) %></span>
                    </div>
                    <div class="summary-item">
                        <span class="label">Tax Collected</span>
                        <span class="value">Rs. <%= df.format(taxRevenue) %></span>
                    </div>
                    <div class="summary-item">
                        <span class="label">Discounts Given</span>
                        <span class="value" style="color: #dc3545;">- Rs. <%= df.format(discountGiven) %></span>
                    </div>
                </div>
                <div class="total-row">
                    <span class="label">Net Revenue</span>
                    <span class="value">Rs. <%= df.format(totalRevenue) %></span>
                </div>
            </div>
            
            <div class="section">
                <h3>📅 Booking Summary</h3>
                <div class="summary-box">
                    <div class="summary-item">
                        <span class="label">Total Reservations</span>
                        <span class="value"><%= totalBookings %></span>
                    </div>
                    <div class="summary-item">
                        <span class="label">Confirmed</span>
                        <span class="value" style="color: #28a745;"><%= confirmedBookings %></span>
                    </div>
                    <div class="summary-item">
                        <span class="label">Checked In</span>
                        <span class="value" style="color: #17a2b8;"><%= checkedInBookings %></span>
                    </div>
                    <div class="summary-item">
                        <span class="label">Checked Out</span>
                        <span class="value" style="color: #667eea;"><%= checkedOutBookings %></span>
                    </div>
                    <div class="summary-item">
                        <span class="label">Cancelled</span>
                        <span class="value" style="color: #dc3545;"><%= cancelledBookings %></span>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="two-col" style="margin-top: 20px;">
            <div class="section">
                <h3>💳 Payment Summary</h3>
                <div class="summary-box">
                    <div class="summary-item">
                        <span class="label">Total Bills Generated</span>
                        <span class="value"><%= totalBills %></span>
                    </div>
                    <div class="summary-item">
                        <span class="label">Paid Bills</span>
                        <span class="value" style="color: #28a745;"><%= paidBills %></span>
                    </div>
                    <div class="summary-item">
                        <span class="label">Pending Bills</span>
                        <span class="value" style="color: #ffc107;"><%= pendingBills %></span>
                    </div>
                </div>
            </div>
            
            <div class="section">
                <h3>💵 Payment Methods</h3>
                <div class="summary-box">
                    <div class="summary-item">
                        <span class="label">Cash Payments</span>
                        <span class="value"><%= cashPayments %></span>
                    </div>
                    <div class="summary-item">
                        <span class="label">Card Payments</span>
                        <span class="value"><%= cardPayments %></span>
                    </div>
                    <div class="summary-item">
                        <span class="label">Bank Transfers</span>
                        <span class="value"><%= bankPayments %></span>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="section" style="margin-top: 30px;">
            <h3>📈 Revenue Chart</h3>
            <div class="chart-container">
                <canvas id="revenueChart"></canvas>
            </div>
        </div>
        
        <div class="section">
            <h3>📋 Recent Transactions</h3>
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Bill #</th>
                        <th>Guest</th>
                        <th>Room</th>
                        <th>Amount</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        try {
                            Statement transStmt = conn.createStatement();
                            ResultSet transRs = transStmt.executeQuery(
                                "SELECT b.bill_number, b.total_amount, b.payment_status, g.full_name, rm.room_number " +
                                "FROM bills b JOIN reservations r ON b.reservation_id = r.reservation_id " +
                                "JOIN guests g ON r.guest_id = g.guest_id JOIN rooms rm ON r.room_id = rm.room_id " +
                                "WHERE " + dateCondition + " ORDER BY b.generated_at DESC LIMIT 10"
                            );
                            while (transRs.next()) {
                    %>
                    <tr>
                        <td><%= transRs.getString("bill_number") %></td>
                        <td><%= transRs.getString("full_name") %></td>
                        <td>Room <%= transRs.getString("room_number") %></td>
                        <td>Rs. <%= df.format(transRs.getDouble("total_amount")) %></td>
                        <td style="color: <%= "PAID".equals(transRs.getString("payment_status")) ? "#28a745" : "#ffc107" %>;"><%= transRs.getString("payment_status") %></td>
                    </tr>
                    <%
                            }
                            transRs.close();
                            transStmt.close();
                        } catch (Exception e) {
                            out.println("<tr><td colspan='5'>No transactions found</td></tr>");
                        }
                    %>
                </tbody>
            </table>
        </div>
        
        <div class="footer">
            <p>This report was automatically generated by Ocean View Resort Management System</p>
            <p>&copy; <%= new SimpleDateFormat("yyyy").format(new java.util.Date()) %> Ocean View Resort, Galle, Sri Lanka</p>
        </div>
    </div>
    
    <script>
        async function downloadReportPdf() {
            try {
                const report = document.querySelector('.report-container');
                const canvas = await html2canvas(report, {
                    scale: 2,
                    useCORS: true,
                    backgroundColor: '#ffffff'
                });
                const { jsPDF } = window.jspdf;
                const pdf = new jsPDF('p', 'mm', 'a4');
                const pageWidth = 210;
                const pageHeight = 297;
                const margin = 10;
                const imgWidth = pageWidth - (margin * 2);
                const imgHeight = (canvas.height * imgWidth) / canvas.width;
                const imgData = canvas.toDataURL('image/png');
                let remainingHeight = imgHeight;
                let y = margin;

                pdf.addImage(imgData, 'PNG', margin, y, imgWidth, imgHeight);
                remainingHeight -= (pageHeight - (margin * 2));

                while (remainingHeight > 0) {
                    y = remainingHeight - imgHeight + margin;
                    pdf.addPage();
                    pdf.addImage(imgData, 'PNG', margin, y, imgWidth, imgHeight);
                    remainingHeight -= (pageHeight - (margin * 2));
                }

                pdf.save('ocean-view-<%= periodTitle.toLowerCase() %>-report.pdf');
            } catch (e) {
                alert('Failed to generate PDF. Please try again.');
            }
        }

        const ctx = document.getElementById('revenueChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: ['Room Revenue', 'Additional Services', 'Tax Collected', 'Discounts'],
                datasets: [{
                    label: 'Amount (Rs.)',
                    data: [<%= roomRevenue %>, <%= additionalRevenue %>, <%= taxRevenue %>, <%= discountGiven %>],
                    backgroundColor: ['#008080', '#667eea', '#43e97b', '#f5576c']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } }
            }
        });
    </script>
    
    <% if (conn != null) { try { conn.close(); } catch (Exception e) {} } %>
</body>
</html>
