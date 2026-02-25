<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <!DOCTYPE html>
        <html lang="en">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Add Staff - Ocean View Resort</title>
            <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        </head>

        <body>
            <div class="dashboard-container">
                <!-- Sidebar -->
                <aside class="sidebar">
                    <div class="sidebar-header">
                        <i class="fas fa-hotel" style="font-size: 2rem; margin-bottom: 10px;"></i>
                        <h2>Ocean View Resort</h2>
                        <p>Admin Panel</p>
                    </div>

                    <nav class="sidebar-nav">
                        <a href="${pageContext.request.contextPath}/admin/dashboard" class="nav-item">
                            <i class="fas fa-tachometer-alt"></i> Dashboard
                        </a>

                        <div class="nav-section-title">Management</div>

                        <a href="${pageContext.request.contextPath}/reservation/list" class="nav-item">
                            <i class="fas fa-calendar-check"></i> Reservations
                        </a>
                        <a href="${pageContext.request.contextPath}/room/list" class="nav-item">
                            <i class="fas fa-bed"></i> Rooms
                        </a>
                        <a href="${pageContext.request.contextPath}/guest/list" class="nav-item">
                            <i class="fas fa-users"></i> Guests
                        </a>
                        <a href="${pageContext.request.contextPath}/bill/list" class="nav-item">
                            <i class="fas fa-file-invoice-dollar"></i> Billing
                        </a>
                        <a href="${pageContext.request.contextPath}/user/list" class="nav-item active">
                            <i class="fas fa-user-cog"></i> Staff
                        </a>

                        <div class="nav-divider"></div>

                        <a href="${pageContext.request.contextPath}/logout" class="nav-item">
                            <i class="fas fa-sign-out-alt"></i> Logout
                        </a>
                    </nav>
                </aside>

                <!-- Main Content -->
                <main class="main-content">
                    <!-- Top Bar -->
                    <div class="top-bar">
                        <h1><i class="fas fa-user-plus"></i> Add New Staff</h1>
                        <div class="user-info">
                            <div class="user-details">
                                <div class="name">${sessionScope.fullName}</div>
                                <div class="role">${sessionScope.role}</div>
                            </div>
                            <div class="user-avatar">
                                ${sessionScope.fullName.substring(0,1)}
                            </div>
                        </div>
                    </div>

                    <!-- Messages -->
                    <c:if test="${not empty sessionScope.error}">
                        <div class="alert alert-error">
                            <i class="fas fa-exclamation-circle"></i> ${sessionScope.error}
                        </div>
                        <c:remove var="error" scope="session" />
                    </c:if>

                    <!-- Add Staff Form -->
                    <div class="card" style="max-width: 800px;">
                        <div class="card-header">
                            <h3><i class="fas fa-user-edit"></i> Staff Information</h3>
                            <a href="${pageContext.request.contextPath}/user/list" class="btn btn-secondary">
                                <i class="fas fa-arrow-left"></i> Back
                            </a>
                        </div>
                        <div class="card-body">
                            <form action="${pageContext.request.contextPath}/user/create" method="post">
                                <div
                                    style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px;">
                                    <!-- Username -->
                                    <div class="form-group">
                                        <label for="username">
                                            <i class="fas fa-user"></i> Username <span style="color: #e53e3e;">*</span>
                                        </label>
                                        <input type="text" id="username" name="username" class="form-control" required
                                            pattern="[a-zA-Z0-9_]{3,20}"
                                            title="3-20 characters, letters, numbers, and underscores only">
                                        <small style="color: #718096;">3-20 characters, alphanumeric and
                                            underscore</small>
                                    </div>

                                    <!-- Password -->
                                    <div class="form-group">
                                        <label for="password">
                                            <i class="fas fa-lock"></i> Password <span style="color: #e53e3e;">*</span>
                                        </label>
                                        <input type="password" id="password" name="password" class="form-control"
                                            required minlength="6">
                                        <small style="color: #718096;">Minimum 6 characters</small>
                                    </div>

                                    <!-- Full Name -->
                                    <div class="form-group">
                                        <label for="fullName">
                                            <i class="fas fa-id-card"></i> Full Name <span
                                                style="color: #e53e3e;">*</span>
                                        </label>
                                        <input type="text" id="fullName" name="fullName" class="form-control" required>
                                    </div>

                                    <!-- Role -->
                                    <div class="form-group">
                                        <label for="role">
                                            <i class="fas fa-user-tag"></i> Role <span style="color: #e53e3e;">*</span>
                                        </label>
                                        <select id="role" name="role" class="form-control" required>
                                            <option value="">Select Role</option>
                                            <option value="STAFF">Staff</option>
                                            <option value="ADMIN">Admin</option>
                                        </select>
                                    </div>

                                    <!-- Email -->
                                    <div class="form-group">
                                        <label for="email">
                                            <i class="fas fa-envelope"></i> Email Address
                                        </label>
                                        <input type="email" id="email" name="email" class="form-control"
                                            placeholder="Optional">
                                    </div>

                                    <!-- Phone -->
                                    <div class="form-group">
                                        <label for="phone">
                                            <i class="fas fa-phone"></i> Phone Number
                                        </label>
                                        <input type="tel" id="phone" name="phone" class="form-control"
                                            placeholder="Optional">
                                    </div>
                                </div>

                                <!-- Role Description -->
                                <div style="background: #f7fafc; padding: 20px; border-radius: 8px; margin-top: 20px;">
                                    <h4 style="margin-bottom: 15px; color: #0077b6;"><i class="fas fa-info-circle"></i>
                                        Role Permissions</h4>
                                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                                        <div>
                                            <h5 style="color: #2b6cb0; margin-bottom: 10px;"><i
                                                    class="fas fa-user-shield"></i> Admin</h5>
                                            <ul style="color: #718096; padding-left: 20px; margin: 0;">
                                                <li>Full system access</li>
                                                <li>Staff management</li>
                                                <li>Room rate updates</li>
                                                <li>Apply discounts</li>
                                                <li>View all reports</li>
                                            </ul>
                                        </div>
                                        <div>
                                            <h5 style="color: #38a169; margin-bottom: 10px;"><i class="fas fa-user"></i>
                                                Staff</h5>
                                            <ul style="color: #718096; padding-left: 20px; margin: 0;">
                                                <li>Manage reservations</li>
                                                <li>Check-in/Check-out</li>
                                                <li>Guest management</li>
                                                <li>Process payments</li>
                                                <li>View room status</li>
                                            </ul>
                                        </div>
                                    </div>
                                </div>

                                <div
                                    style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e2e8f0; display: flex; gap: 10px; justify-content: flex-end;">
                                    <a href="${pageContext.request.contextPath}/user/list" class="btn btn-secondary">
                                        <i class="fas fa-times"></i> Cancel
                                    </a>
                                    <button type="submit" class="btn btn-primary">
                                        <i class="fas fa-user-plus"></i> Create Staff Account
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </main>
            </div>
        </body>

        </html>