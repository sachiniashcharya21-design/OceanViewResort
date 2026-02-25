<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.util.*" %>
<%
    // Check if user is logged in (allow both ADMIN and STAFF)
    String userRole = (String) session.getAttribute("userRole");
    if (userRole == null || (!"ADMIN".equalsIgnoreCase(userRole) && !"STAFF".equalsIgnoreCase(userRole))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String dashboardLink = "ADMIN".equalsIgnoreCase(userRole)
        ? request.getContextPath() + "/admin/admin-dashboard.jsp"
        : request.getContextPath() + "/staff/staff-dashboard.jsp";
    
    String dateParam = request.getParameter("date");
    String reportDate;
    if (dateParam != null && !dateParam.isEmpty()) {
        reportDate = dateParam;
    } else {
        reportDate = new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
    }
    
    String displayDate = new SimpleDateFormat("MMMM dd, yyyy").format(
        new SimpleDateFormat("yyyy-MM-dd").parse(reportDate)
    );
    
    // Database connection
    Connection conn = null;
    String dbUrl = "jdbc:mysql://localhost:3306/ocean_view_resort";
    String dbUser = "root";
    String dbPass = "";
    
    double totalRevenue = 0, totalPaid = 0, totalPending = 0;
    int invoiceCount = 0;
    
    DecimalFormat df = new DecimalFormat("#,###.00");
    
    List<Map<String, String>> invoices = new ArrayList<>();
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        // Get all invoices for the date
        PreparedStatement ps = conn.prepareStatement(
            "SELECT b.*, r.reservation_number, g.full_name, rm.room_number, rt.type_name " +
            "FROM bills b " +
            "JOIN reservations r ON b.reservation_id = r.reservation_id " +
            "JOIN guests g ON r.guest_id = g.guest_id " +
            "JOIN rooms rm ON r.room_id = rm.room_id " +
            "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
            "WHERE DATE(b.generated_at) = ? " +
            "ORDER BY b.generated_at"
        );
        ps.setString(1, reportDate);
        ResultSet rs = ps.executeQuery();
        
        while (rs.next()) {
            Map<String, String> inv = new HashMap<>();
            inv.put("bill_number", rs.getString("bill_number"));
            inv.put("reservation_number", rs.getString("reservation_number"));
            inv.put("guest_name", rs.getString("full_name"));
            inv.put("room_number", rs.getString("room_number"));
            inv.put("room_type", rs.getString("type_name"));
            inv.put("nights", String.valueOf(rs.getInt("number_of_nights")));
            inv.put("room_total", df.format(rs.getDouble("room_total")));
            inv.put("additional", df.format(rs.getDouble("additional_charges")));
            inv.put("tax", df.format(rs.getDouble("tax_amount")));
            inv.put("total", df.format(rs.getDouble("total_amount")));
            inv.put("payment_status", rs.getString("payment_status"));
            inv.put("payment_method", rs.getString("payment_method"));
            Timestamp genAt = rs.getTimestamp("generated_at");
            inv.put("time", genAt != null ? new SimpleDateFormat("hh:mm a").format(genAt) : "");
            
            double amount = rs.getDouble("total_amount");
            totalRevenue += amount;
            if ("PAID".equals(rs.getString("payment_status"))) {
                totalPaid += amount;
            } else {
                totalPending += amount;
            }
            
            invoices.add(inv);
            invoiceCount++;
        }
        
        rs.close();
        ps.close();
    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daily Invoice Report - <%= displayDate %></title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
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
            max-width: 1000px;
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
            text-decoration: none;
            display: inline-block;
            transition: all 0.3s ease;
        }
        
        .btn-print { background: linear-gradient(135deg, #004040, #008080); color: white; }
        .btn-download { background: linear-gradient(135deg, #1f9d55, #28a745); color: white; }
        .btn-back { background: #e0e0e0; color: #333; }
        .btn:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,0,0,0.2); }
        
        .report-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 40px;
            padding-bottom: 20px;
            border-bottom: 3px solid #008080;
        }
        
        .hotel-info h1 { color: #004040; font-size: 24px; margin-bottom: 5px; }
        .hotel-info p { color: #666; font-size: 12px; line-height: 1.8; }
        
        .report-meta { text-align: right; }
        .report-meta h2 { color: #008080; font-size: 20px; margin-bottom: 5px; }
        .report-meta p { color: #666; font-size: 13px; }
        
        .summary-cards {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .summary-card {
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        
        .summary-card.total { background: linear-gradient(135deg, #004040, #008080); color: white; }
        .summary-card.paid { background: linear-gradient(135deg, #28a745, #20c997); color: white; }
        .summary-card.pending { background: linear-gradient(135deg, #ffc107, #ffb300); color: #333; }
        .summary-card.count { background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
        
        .summary-card h3 { font-size: 22px; margin-bottom: 5px; }
        .summary-card p { font-size: 11px; text-transform: uppercase; letter-spacing: 1px; opacity: 0.9; }
        
        .invoice-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
            font-size: 12px;
        }
        
        .invoice-table th {
            background: #004040;
            color: white;
            padding: 12px 10px;
            text-align: left;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .invoice-table td {
            padding: 12px 10px;
            border-bottom: 1px solid #eee;
        }
        
        .invoice-table tr:nth-child(even) { background: #f8f9fa; }
        .invoice-table tr:hover { background: #e8f4f4; }
        
        .status-badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 15px;
            font-size: 10px;
            font-weight: 600;
        }
        
        .status-paid { background: rgba(40,167,69,0.15); color: #28a745; }
        .status-pending { background: rgba(255,193,7,0.15); color: #d39e00; }
        
        .total-section {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
        }
        
        .total-section h4 {
            color: #004040;
            margin-bottom: 15px;
            font-size: 14px;
        }
        
        .total-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px dashed #ddd;
        }
        
        .total-row:last-child { border-bottom: none; }
        .total-row.grand { background: linear-gradient(135deg, #004040, #008080); color: white; padding: 12px 15px; border-radius: 8px; margin-top: 10px; font-weight: 600; }
        
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            display: flex;
            justify-content: space-between;
            font-size: 11px;
            color: #666;
        }
        
        .signature-box {
            text-align: center;
            min-width: 200px;
        }
        
        .signature-line {
            border-top: 1px solid #333;
            margin-top: 40px;
            padding-top: 5px;
        }
        
        .no-data {
            text-align: center;
            padding: 40px;
            color: #666;
        }
        
        @media print {
            body { background: white; padding: 0; }
            .no-print { display: none !important; }
            .report-container { box-shadow: none; padding: 20px; }
        }
    </style>
</head>
<body>
    <div class="no-print">
        <button class="btn btn-download" onclick="downloadDailyReportPdf()">Download PDF</button>
        <input type="date" id="reportDatePicker" value="<%= reportDate %>" style="padding: 10px; border-radius: 5px; border: 1px solid #ddd; margin-right: 10px;">
        <button class="btn btn-back" onclick="changeDate()">Change Date</button>
        <button class="btn btn-print" onclick="window.print()">🖨️ Print Report</button>
        <a href="<%= dashboardLink %>" class="btn btn-back">← Back</a>
    </div>
    
    <div class="report-container">
        <div class="report-header">
            <div class="hotel-info">
                <h1>🏨 Ocean View Resort</h1>
                <p>
                    No. 123, Beach Road, Unawatuna, Galle<br>
                    Phone: +94 91 222 4455 | Email: info@oceanviewresort.lk
                </p>
            </div>
            <div class="report-meta">
                <h2>Daily Invoice Report</h2>
                <p><strong><%= displayDate %></strong></p>
                <p>Generated: <%= new SimpleDateFormat("hh:mm a").format(new java.util.Date()) %></p>
            </div>
        </div>
        
        <div class="summary-cards">
            <div class="summary-card total">
                <h3>Rs. <%= df.format(totalRevenue) %></h3>
                <p>Total Revenue</p>
            </div>
            <div class="summary-card paid">
                <h3>Rs. <%= df.format(totalPaid) %></h3>
                <p>Collected</p>
            </div>
            <div class="summary-card pending">
                <h3>Rs. <%= df.format(totalPending) %></h3>
                <p>Pending</p>
            </div>
            <div class="summary-card count">
                <h3><%= invoiceCount %></h3>
                <p>Invoices</p>
            </div>
        </div>
        
        <% if (invoices.isEmpty()) { %>
        <div class="no-data">
            <h3>No invoices found for <%= displayDate %></h3>
            <p>There are no billing records for the selected date.</p>
        </div>
        <% } else { %>
        <table class="invoice-table">
            <thead>
                <tr>
                    <th>Time</th>
                    <th>Invoice #</th>
                    <th>Guest</th>
                    <th>Room</th>
                    <th>Nights</th>
                    <th>Room Total</th>
                    <th>Tax</th>
                    <th>Total</th>
                    <th>Method</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <% for (Map<String, String> inv : invoices) { %>
                <tr>
                    <td><%= inv.get("time") %></td>
                    <td><strong><%= inv.get("bill_number") %></strong></td>
                    <td><%= inv.get("guest_name") %></td>
                    <td><%= inv.get("room_number") %> (<%= inv.get("room_type") %>)</td>
                    <td><%= inv.get("nights") %></td>
                    <td>Rs. <%= inv.get("room_total") %></td>
                    <td>Rs. <%= inv.get("tax") %></td>
                    <td><strong>Rs. <%= inv.get("total") %></strong></td>
                    <td><%= inv.get("payment_method") %></td>
                    <td><span class="status-badge <%= "PAID".equals(inv.get("payment_status")) ? "status-paid" : "status-pending" %>"><%= inv.get("payment_status") %></span></td>
                </tr>
                <% } %>
            </tbody>
        </table>
        <% } %>
        
        <div class="total-section">
            <h4>Summary</h4>
            <div class="total-row">
                <span>Total Invoices Generated:</span>
                <span><%= invoiceCount %></span>
            </div>
            <div class="total-row">
                <span>Total Amount:</span>
                <span>Rs. <%= df.format(totalRevenue) %></span>
            </div>
            <div class="total-row">
                <span>Amount Collected (Paid):</span>
                <span style="color: #28a745;">Rs. <%= df.format(totalPaid) %></span>
            </div>
            <div class="total-row">
                <span>Amount Pending:</span>
                <span style="color: #d39e00;">Rs. <%= df.format(totalPending) %></span>
            </div>
            <div class="total-row grand">
                <span>Net Collection for the Day:</span>
                <span>Rs. <%= df.format(totalPaid) %></span>
            </div>
        </div>
        
        <div class="footer">
            <div>
                <p>Report generated by: <%= session.getAttribute("fullName") %></p>
                <p>Date & Time: <%= new SimpleDateFormat("MMMM dd, yyyy hh:mm a").format(new java.util.Date()) %></p>
            </div>
            <div class="signature-box">
                <div class="signature-line">Authorized Signature</div>
            </div>
        </div>
    </div>
    
    <script>
        async function downloadDailyReportPdf() {
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

                pdf.save('ocean-view-daily-invoice-summary-<%= reportDate %>.pdf');
            } catch (e) {
                alert('Failed to generate PDF. Please try again.');
            }
        }

        function changeDate() {
            const date = document.getElementById('reportDatePicker').value;
            if (date) {
                window.location.href = '<%= request.getContextPath() %>/admin/generate-daily-report.jsp?date=' + date;
            }
        }
    </script>
    
    <% if (conn != null) { try { conn.close(); } catch (Exception e) {} } %>
</body>
</html>
