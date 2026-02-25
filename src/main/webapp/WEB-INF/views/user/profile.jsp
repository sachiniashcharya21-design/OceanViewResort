<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
            <!DOCTYPE html>
            <html lang="en">

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>My Profile - Ocean View Resort</title>
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
                            <p>${sessionScope.role == 'ADMIN' ? 'Admin Panel' : 'Staff Panel'}</p>
                        </div>

                        <nav class="sidebar-nav">
                            <c:choose>
                                <c:when test="${sessionScope.role == 'ADMIN'}">
                                    <a href="${pageContext.request.contextPath}/admin/dashboard" class="nav-item">
                                        <i class="fas fa-tachometer-alt"></i> Dashboard
                                    </a>
                                </c:when>
                                <c:otherwise>
                                    <a href="${pageContext.request.contextPath}/staff/dashboard" class="nav-item">
                                        <i class="fas fa-tachometer-alt"></i> Dashboard
                                    </a>
                                </c:otherwise>
                            </c:choose>

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

                            <c:if test="${sessionScope.role == 'ADMIN'}">
                                <a href="${pageContext.request.contextPath}/user/list" class="nav-item">
                                    <i class="fas fa-user-cog"></i> Staff
                                </a>
                            </c:if>

                            <div class="nav-divider"></div>

                            <a href="${pageContext.request.contextPath}/user/profile" class="nav-item active">
                                <i class="fas fa-user-circle"></i> My Profile
                            </a>

                            <a href="${pageContext.request.contextPath}/logout" class="nav-item">
                                <i class="fas fa-sign-out-alt"></i> Logout
                            </a>
                        </nav>
                    </aside>

                    <!-- Main Content -->
                    <main class="main-content">
                        <!-- Top Bar -->
                        <div class="top-bar">
                            <h1><i class="fas fa-user-circle"></i> My Profile</h1>
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
                        <c:if test="${not empty sessionScope.success}">
                            <div class="alert alert-success">
                                <i class="fas fa-check-circle"></i> ${sessionScope.success}
                            </div>
                            <c:remove var="success" scope="session" />
                        </c:if>
                        <c:if test="${not empty sessionScope.error}">
                            <div class="alert alert-error">
                                <i class="fas fa-exclamation-circle"></i> ${sessionScope.error}
                            </div>
                            <c:remove var="error" scope="session" />
                        </c:if>

                        <div
                            style="display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 30px;">
                            <!-- Profile Card -->
                            <div class="card">
                                <div class="card-header">
                                    <h3><i class="fas fa-id-card-alt"></i> Profile Information</h3>
                                </div>
                                <div class="card-body">
                                    <!-- Profile Avatar -->
                                    <div style="text-align: center; margin-bottom: 30px;">
                                        <div style="width: 120px; height: 120px; border-radius: 50%; background: linear-gradient(135deg, #0077b6 0%, #023e8a 100%); 
                                        display: flex; align-items: center; justify-content: center; margin: 0 auto 15px;
                                        font-size: 3rem; color: white; font-weight: 700;">
                                            ${user.fullName.substring(0,1)}
                                        </div>
                                        <h2 style="margin: 0;">${user.fullName}</h2>
                                        <c:choose>
                                            <c:when test="${user.role == 'ADMIN'}">
                                                <span class="badge badge-primary"
                                                    style="margin-top: 10px;">${user.role}</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge badge-info"
                                                    style="margin-top: 10px;">${user.role}</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>

                                    <!-- Profile Details -->
                                    <table style="width: 100%;">
                                        <tr>
                                            <td style="padding: 12px 0; color: #718096; width: 40%;">
                                                <i class="fas fa-user" style="width: 20px;"></i> Username
                                            </td>
                                            <td style="padding: 12px 0; font-weight: 600;">${user.username}</td>
                                        </tr>
                                        <tr>
                                            <td style="padding: 12px 0; color: #718096;">
                                                <i class="fas fa-envelope" style="width: 20px;"></i> Email
                                            </td>
                                            <td style="padding: 12px 0;">
                                                ${not empty user.email ? user.email : 'Not provided'}
                                            </td>
                                        </tr>
                                        <tr>
                                            <td style="padding: 12px 0; color: #718096;">
                                                <i class="fas fa-phone" style="width: 20px;"></i> Phone
                                            </td>
                                            <td style="padding: 12px 0;">
                                                ${not empty user.phone ? user.phone : 'Not provided'}
                                            </td>
                                        </tr>
                                        <tr>
                                            <td style="padding: 12px 0; color: #718096;">
                                                <i class="fas fa-calendar" style="width: 20px;"></i> Member Since
                                            </td>
                                            <td style="padding: 12px 0;">
                                                <fmt:formatDate value="${user.createdAt}" pattern="dd MMMM yyyy" />
                                            </td>
                                        </tr>
                                        <tr>
                                            <td style="padding: 12px 0; color: #718096;">
                                                <i class="fas fa-clock" style="width: 20px;"></i> Last Login
                                            </td>
                                            <td style="padding: 12px 0;">
                                                <c:choose>
                                                    <c:when test="${not empty user.lastLogin}">
                                                        <fmt:formatDate value="${user.lastLogin}"
                                                            pattern="dd MMM yyyy, hh:mm a" />
                                                    </c:when>
                                                    <c:otherwise>
                                                        First login
                                                    </c:otherwise>
                                                </c:choose>
                                            </td>
                                        </tr>
                                    </table>
                                </div>
                            </div>

                            <!-- Edit Profile & Change Password -->
                            <div>
                                <!-- Edit Profile -->
                                <div class="card" style="margin-bottom: 20px;">
                                    <div class="card-header">
                                        <h3><i class="fas fa-edit"></i> Update Profile</h3>
                                    </div>
                                    <div class="card-body">
                                        <form action="${pageContext.request.contextPath}/user/updateProfile"
                                            method="post">
                                            <div class="form-group">
                                                <label for="fullName">
                                                    <i class="fas fa-user"></i> Full Name <span
                                                        style="color: #e53e3e;">*</span>
                                                </label>
                                                <input type="text" id="fullName" name="fullName" class="form-control"
                                                    value="${user.fullName}" required>
                                            </div>

                                            <div class="form-group">
                                                <label for="email">
                                                    <i class="fas fa-envelope"></i> Email
                                                </label>
                                                <input type="email" id="email" name="email" class="form-control"
                                                    value="${user.email}" placeholder="Optional">
                                            </div>

                                            <div class="form-group">
                                                <label for="phone">
                                                    <i class="fas fa-phone"></i> Phone
                                                </label>
                                                <input type="tel" id="phone" name="phone" class="form-control"
                                                    value="${user.phone}" placeholder="Optional">
                                            </div>

                                            <button type="submit" class="btn btn-primary" style="width: 100%;">
                                                <i class="fas fa-save"></i> Update Profile
                                            </button>
                                        </form>
                                    </div>
                                </div>

                                <!-- Change Password -->
                                <div class="card">
                                    <div class="card-header">
                                        <h3><i class="fas fa-key"></i> Change Password</h3>
                                    </div>
                                    <div class="card-body">
                                        <form action="${pageContext.request.contextPath}/user/changePassword"
                                            method="post" id="changePasswordForm">
                                            <div class="form-group">
                                                <label for="currentPassword">
                                                    <i class="fas fa-lock"></i> Current Password <span
                                                        style="color: #e53e3e;">*</span>
                                                </label>
                                                <input type="password" id="currentPassword" name="currentPassword"
                                                    class="form-control" required>
                                            </div>

                                            <div class="form-group">
                                                <label for="newPassword">
                                                    <i class="fas fa-lock"></i> New Password <span
                                                        style="color: #e53e3e;">*</span>
                                                </label>
                                                <input type="password" id="newPassword" name="newPassword"
                                                    class="form-control" required minlength="6">
                                                <small style="color: #718096;">Minimum 6 characters</small>
                                            </div>

                                            <div class="form-group">
                                                <label for="confirmNewPassword">
                                                    <i class="fas fa-lock"></i> Confirm New Password <span
                                                        style="color: #e53e3e;">*</span>
                                                </label>
                                                <input type="password" id="confirmNewPassword" name="confirmNewPassword"
                                                    class="form-control" required minlength="6">
                                            </div>

                                            <button type="submit" class="btn btn-warning" style="width: 100%;">
                                                <i class="fas fa-sync"></i> Change Password
                                            </button>
                                        </form>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </main>
                </div>

                <script>
                    document.getElementById('changePasswordForm').addEventListener('submit', function (e) {
                        var newPass = document.getElementById('newPassword').value;
                        var confirmPass = document.getElementById('confirmNewPassword').value;
                        if (newPass !== confirmPass) {
                            e.preventDefault();
                            alert('New passwords do not match!');
                        }
                    });
                </script>
            </body>

            </html>