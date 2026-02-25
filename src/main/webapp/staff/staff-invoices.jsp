<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.*" %>
<%
    // Check if user is logged in and is staff
    String userRole = (String) session.getAttribute("userRole");
    String username = (String) session.getAttribute("username");
    String fullName = (String) session.getAttribute("fullName");
    
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
    String contextPath = request.getContextPath();
    String dbError = null;
    String pageError = request.getParameter("error");
    
    DecimalFormat df = new DecimalFormat("#,##0.00");
    
    try {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ex) {
            Class.forName("com.mysql.jdbc.Driver");
        }
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
    } catch (Exception e) {
        dbError = e.getMessage();
        e.printStackTrace();
    }
%>
<%!
    public String escHtml(String str) {
        if (str == null) return "";
        return str.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }

    public String escJs(String str) {
        if (str == null) return "";
        return str.replace("\\", "\\\\").replace("'", "\\'").replace("\r", " ").replace("\n", " ");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Invoices - Ocean View Resort Staff</title>
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
            --warning: #ffc107;
            --danger: #dc3545;
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
        
        .header-left h1 { font-size: 24px; font-weight: 600; }
        .header-left h1 i { margin-right: 10px; }
        .header-left p { font-size: 13px; opacity: 0.9; margin-top: 5px; }
        .header-actions { display: flex; gap: 15px; }
        
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
        
        .btn-back:hover { background: rgba(255,255,255,0.3); transform: translateY(-2px); }
        
        /* Main Content */
        .main-content {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        /* Search Section */
        .search-card {
            background: var(--card-bg);
            border-radius: 15px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            margin-bottom: 30px;
            padding: 25px;
        }
        
        .search-card h3 {
            color: var(--primary-dark);
            margin-bottom: 20px;
            font-size: 18px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .search-row {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            align-items: flex-end;
        }
        
        .search-group { display: flex; flex-direction: column; gap: 5px; flex: 1; min-width: 200px; }
        .search-group label { font-size: 12px; font-weight: 600; color: var(--text-light); text-transform: uppercase; }
        
        .search-control {
            padding: 12px 15px;
            border: 2px solid var(--border);
            border-radius: 10px;
            font-size: 14px;
            font-family: 'Poppins', sans-serif;
            transition: all 0.3s ease;
        }
        
        .search-control:focus { border-color: var(--primary); outline: none; }
        
        .btn-search {
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
            color: white;
            padding: 12px 30px;
        }
        
        .btn-search:hover { transform: translateY(-2px); box-shadow: 0 5px 20px rgba(0, 128, 128, 0.3); }
        
        .btn-clear { background: #e74c3c; color: white; }
        
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
            background: linear-gradient(135deg, var(--primary) 0%, var(--glow) 100%);
            color: white;
        }
        
        .table-header h3 { font-size: 18px; font-weight: 600; display: flex; align-items: center; gap: 10px; }
        
        .table-wrapper { overflow-x: auto; }
        
        .data-table { width: 100%; border-collapse: collapse; }
        .data-table th { background: var(--bg); padding: 15px; text-align: left; font-size: 12px; font-weight: 600; color: var(--text-light); text-transform: uppercase; white-space: nowrap; }
        .data-table td { padding: 15px; border-bottom: 1px solid var(--border); vertical-align: middle; }
        .data-table tr:hover { background: #f8f9fa; }
        
        .invoice-number { font-weight: 700; color: var(--primary-dark); font-size: 14px; }
        
        .status-badge {
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            display: inline-block;
        }
        
        .status-badge.paid { background: #d1fae5; color: #059669; }
        .status-badge.pending { background: #fef3c7; color: #d97706; }
        .status-badge.partial { background: #dbeafe; color: #2563eb; }
        
        .amount { font-weight: 700; color: var(--primary-dark); }
        
        .action-btn {
            padding: 8px 15px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            font-size: 13px;
            font-family: 'Poppins', sans-serif;
            margin-right: 5px;
            text-decoration: none;
        }
        
        .action-btn.view { background: #e3f2fd; color: #1976d2; }
        .action-btn.print { background: #e8f5e9; color: #388e3c; }
        .action-btn.pdf { background: #fff3e0; color: #e65100; }
        .action-btn:hover { transform: scale(1.05); }
        
        .empty-state { text-align: center; padding: 60px 20px; }
        .empty-state i { font-size: 60px; color: var(--primary); opacity: 0.3; margin-bottom: 15px; }
        .empty-state h3 { color: var(--text); margin-bottom: 8px; }
        .empty-state p { color: var(--text-light); }
        
        @media (max-width: 768px) {
            .header { padding: 15px 20px; flex-direction: column; gap: 15px; }
            .search-row { flex-direction: column; }
            .search-group { min-width: 100%; }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="header-left">
            <h1><i class="fas fa-file-invoice"></i> Invoices</h1>
            <p><i class="fas fa-user"></i> Staff: <%= fullName %></p>
        </div>
        <div class="header-actions">
            <a href="<%= contextPath %>/staff/staff-dashboard.jsp" class="btn btn-back"><i class="fas fa-arrow-left"></i> Back to Dashboard</a>
        </div>
    </header>
    
    <!-- Main Content -->
    <main class="main-content">
        <% if (dbError != null) { %>
            <script>
                Swal.fire({
                    icon: 'error',
                    title: 'Database Error',
                    text: '<%= escJs(dbError) %>',
                    confirmButtonColor: '#008080'
                });
            </script>
        <% } %>
        <% if (pageError != null && !pageError.trim().isEmpty()) { %>
            <script>
                Swal.fire({
                    icon: 'warning',
                    title: 'Notice',
                    text: '<%= escJs(pageError) %>',
                    confirmButtonColor: '#008080'
                });
            </script>
        <% } %>
        <!-- Search Section -->
        <div class="search-card">
            <h3><i class="fas fa-search"></i> Search Invoices</h3>
            <div class="search-row">
                <div class="search-group">
                    <label>Invoice / Bill Number</label>
                    <input type="text" id="billSearch" class="search-control" placeholder="e.g., BILL-001">
                </div>
                <div class="search-group">
                    <label>Guest Name</label>
                    <input type="text" id="guestSearch" class="search-control" placeholder="Guest name...">
                </div>
                <div class="search-group">
                    <label>Reservation Number</label>
                    <input type="text" id="resSearch" class="search-control" placeholder="e.g., RES-001">
                </div>
                <div class="search-group">
                    <label>Status</label>
                    <select id="statusFilter" class="search-control">
                        <option value="">All Status</option>
                        <option value="PAID">Paid</option>
                        <option value="PENDING">Pending</option>
                        <option value="PARTIAL">Partial</option>
                    </select>
                </div>
                <button class="btn btn-search" onclick="filterInvoices()"><i class="fas fa-search"></i> Search</button>
                <button class="btn btn-clear" onclick="clearFilters()"><i class="fas fa-times"></i> Clear</button>
            </div>
        </div>
        
        <!-- Invoices Table -->
        <div class="table-card">
            <div class="table-header">
                <h3><i class="fas fa-list"></i> All Invoices</h3>
            </div>
            <div class="table-wrapper">
                <table class="data-table" id="invoicesTable">
                    <thead>
                        <tr>
                            <th>Invoice #</th>
                            <th>Reservation #</th>
                            <th>Guest</th>
                            <th>Room</th>
                            <th>Check-in</th>
                            <th>Check-out</th>
                            <th>Total Amount</th>
                            <th>Status</th>
                            <th>Generated</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            if (conn == null) {
                                out.println("<tr><td colspan='10' style='text-align:center; color:red;'>Database connection failed.</td></tr>");
                            } else {
                            int rowCount = 0;
                            try {
                                String sql = "SELECT b.bill_id, b.bill_number, b.total_amount, b.payment_status, b.generated_at, " +
                                    "r.reservation_number, r.check_in_date, r.check_out_date, " +
                                    "g.full_name as guest_name, rm.room_number, rt.type_name " +
                                    "FROM bills b " +
                                    "JOIN reservations r ON b.reservation_id = r.reservation_id " +
                                    "JOIN guests g ON r.guest_id = g.guest_id " +
                                    "JOIN rooms rm ON r.room_id = rm.room_id " +
                                    "JOIN room_types rt ON rm.room_type_id = rt.room_type_id " +
                                    "ORDER BY b.generated_at DESC";
                                Statement stmt = conn.createStatement();
                                ResultSet rs = stmt.executeQuery(sql);
                                
                                SimpleDateFormat dateFormat = new SimpleDateFormat("MMM dd, yyyy");
                                SimpleDateFormat dateTimeFormat = new SimpleDateFormat("MMM dd, yyyy HH:mm");
                                
                                while (rs.next()) {
                                    rowCount++;
                                    int billId = rs.getInt("bill_id");
                                    String billNumber = rs.getString("bill_number");
                                    String resNumber = rs.getString("reservation_number");
                                    String guestName = rs.getString("guest_name");
                                    String roomNumber = rs.getString("room_number");
                                    String roomType = rs.getString("type_name");
                                    java.sql.Date checkIn = rs.getDate("check_in_date");
                                    java.sql.Date checkOut = rs.getDate("check_out_date");
                                    double totalAmount = rs.getDouble("total_amount");
                                    String paymentStatus = rs.getString("payment_status");
                                    Timestamp generatedAt = rs.getTimestamp("generated_at");
                                    String statusClass = paymentStatus != null ? paymentStatus.toLowerCase() : "pending";
                        %>
                        <tr data-bill="<%= escHtml((billNumber != null ? billNumber : "").toLowerCase()) %>" 
                            data-guest="<%= escHtml((guestName != null ? guestName : "").toLowerCase()) %>" 
                            data-res="<%= escHtml((resNumber != null ? resNumber : "").toLowerCase()) %>"
                            data-status="<%= paymentStatus %>">
                            <td><span class="invoice-number"><%= escHtml(billNumber) %></span></td>
                            <td><%= escHtml(resNumber) %></td>
                            <td><%= escHtml(guestName) %></td>
                            <td><%= escHtml(roomNumber) %> (<%= escHtml(roomType) %>)</td>
                            <td><%= checkIn != null ? dateFormat.format(checkIn) : "-" %></td>
                            <td><%= checkOut != null ? dateFormat.format(checkOut) : "-" %></td>
                            <td><span class="amount">Rs. <%= df.format(totalAmount) %></span></td>
                            <td><span class="status-badge <%= statusClass %>"><%= paymentStatus %></span></td>
                            <td><%= generatedAt != null ? dateTimeFormat.format(generatedAt) : "-" %></td>
                            <td>
                                <a class="action-btn view" href="<%= contextPath %>/staff/staff-invoice-view.jsp?billId=<%= billId %>">
                                    <i class="fas fa-eye"></i> View
                                </a>
                                <a class="action-btn print" href="<%= contextPath %>/staff/staff-invoice-view.jsp?billId=<%= billId %>&print=true" target="_blank">
                                    <i class="fas fa-print"></i> Print
                                </a>
                            </td>
                        </tr>
                        <% } 
                        if (rowCount == 0) {
                            out.println("<tr><td colspan='10' class='empty-state'><i class='fas fa-file-invoice'></i><h3>No invoices found</h3><p>Bills will appear here when reservations are completed.</p></td></tr>");
                        }
                        rs.close(); stmt.close(); } catch (Exception e) { out.println("<tr><td colspan='10' style='color:red;'>Error: " + e.getMessage() + "</td></tr>"); } } %>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
    
    <script>
        function filterInvoices() {
            const billSearch = document.getElementById('billSearch').value.toLowerCase();
            const guestSearch = document.getElementById('guestSearch').value.toLowerCase();
            const resSearch = document.getElementById('resSearch').value.toLowerCase();
            const statusFilter = document.getElementById('statusFilter').value;
            
            const rows = document.querySelectorAll('#invoicesTable tbody tr');
            
            rows.forEach(row => {
                const billData = row.getAttribute('data-bill') || '';
                const guestData = row.getAttribute('data-guest') || '';
                const resData = row.getAttribute('data-res') || '';
                const statusData = row.getAttribute('data-status') || '';
                
                let showRow = true;
                
                if (billSearch && !billData.includes(billSearch)) showRow = false;
                if (guestSearch && !guestData.includes(guestSearch)) showRow = false;
                if (resSearch && !resData.includes(resSearch)) showRow = false;
                if (statusFilter && statusData !== statusFilter) showRow = false;
                
                row.style.display = showRow ? '' : 'none';
            });
        }
        
        function clearFilters() {
            document.getElementById('billSearch').value = '';
            document.getElementById('guestSearch').value = '';
            document.getElementById('resSearch').value = '';
            document.getElementById('statusFilter').value = '';
            
            const rows = document.querySelectorAll('#invoicesTable tbody tr');
            rows.forEach(row => row.style.display = '');
        }
        
        // Filter on Enter key
        document.querySelectorAll('.search-control').forEach(input => {
            input.addEventListener('keypress', function(e) {
                if (e.key === 'Enter') filterInvoices();
            });
        });
    </script>
    
<%
    if (conn != null) {
        try { conn.close(); } catch (Exception e) {}
    }
%>
</body>
</html>
