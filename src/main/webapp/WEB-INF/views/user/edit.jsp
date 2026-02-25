<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <!DOCTYPE html>
        <html lang="en">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Edit Staff - Ocean View Resort</title>
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
                        <h1><i class="fas fa-user-edit"></i> Edit Staff</h1>
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
                    <c:if test="${not empty sessionScope.success}">
                        <div class="alert alert-success">
                            <i class="fas fa-check-circle"></i> ${sessionScope.success}
                        </div>
                        <c:remove var="success" scope="session" />
                    </c:if>

                    <!-- Edit Staff Form -->
                    <div class="card" style="max-width: 800px;">
                        <div class="card-header">
                            <h3><i class="fas fa-id-badge"></i> Staff #${user.userId} - ${user.username}</h3>
                            <a href="${pageContext.request.contextPath}/user/list" class="btn btn-secondary">
                                <i class="fas fa-arrow-left"></i> Back
                            </a>
                        </div>
                        <div class="card-body">
                            <form action="${pageContext.request.contextPath}/user/update" method="post">
                                <input type="hidden" name="userId" value="${user.userId}">

                                <div
                                    style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px;">
                                    <!-- Username (Read-only) -->
                                    <div class="form-group">
                                        <label for="username">
                                            <i class="fas fa-user"></i> Username
                                        </label>
                                        <input type="text" id="username" class="form-control" value="${user.username}"
                                            readonly style="background: #f7fafc; cursor: not-allowed;">
                                        <small style="color: #718096;">Username cannot be changed</small>
                                    </div>

                                    <!-- Full Name -->
                                    <div class="form-group">
                                        <label for="fullName">
                                            <i class="fas fa-id-card"></i> Full Name <span
                                                style="color: #e53e3e;">*</span>
                                        </label>
                                        <input type="text" id="fullName" name="fullName" class="form-control"
                                            value="${user.fullName}" required>
                                    </div>

                                    <!-- Role -->
                                    <div class="form-group">
                                        <label for="role">
                                            <i class="fas fa-user-tag"></i> Role <span style="color: #e53e3e;">*</span>
                                        </label>
                                        <select id="role" name="role" class="form-control" required <c:if
                                            test="${user.userId == sessionScope.userId}">disabled</c:if>>
                                            <option value="STAFF" ${user.role=='STAFF' ? 'selected' : '' }>Staff
                                            </option>
                                            <option value="ADMIN" ${user.role=='ADMIN' ? 'selected' : '' }>Admin
                                            </option>
                                        </select>
                                        <c:if test="${user.userId == sessionScope.userId}">
                                            <input type="hidden" name="role" value="${user.role}">
                                            <small style="color: #718096;">Cannot change your own role</small>
                                        </c:if>
                                    </div>

                                    <!-- Status -->
                                    <div class="form-group">
                                        <label for="active">
                                            <i class="fas fa-toggle-on"></i> Status <span
                                                style="color: #e53e3e;">*</span>
                                        </label>
                                        <select id="active" name="active" class="form-control" required <c:if
                                            test="${user.userId == sessionScope.userId}">disabled</c:if>>
                                            <option value="true" ${user.active ? 'selected' : '' }>Active</option>
                                            <option value="false" ${!user.active ? 'selected' : '' }>Inactive</option>
                                        </select>
                                        <c:if test="${user.userId == sessionScope.userId}">
                                            <input type="hidden" name="active" value="${user.active}">
                                            <small style="color: #718096;">Cannot deactivate your own account</small>
                                        </c:if>
                                    </div>

                                    <!-- Email -->
                                    <div class="form-group">
                                        <label for="email">
                                            <i class="fas fa-envelope"></i> Email Address
                                        </label>
                                        <input type="email" id="email" name="email" class="form-control"
                                            value="${user.email}" placeholder="Optional">
                                    </div>

                                    <!-- Phone -->
                                    <div class="form-group">
                                        <label for="phone">
                                            <i class="fas fa-phone"></i> Phone Number
                                        </label>
                                        <input type="tel" id="phone" name="phone" class="form-control"
                                            value="${user.phone}" placeholder="Optional">
                                    </div>
                                </div>

                                <div
                                    style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e2e8f0; display: flex; gap: 10px; justify-content: flex-end;">
                                    <a href="${pageContext.request.contextPath}/user/list" class="btn btn-secondary">
                                        <i class="fas fa-times"></i> Cancel
                                    </a>
                                    <button type="submit" class="btn btn-primary">
                                        <i class="fas fa-save"></i> Save Changes
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>

                    <!-- Reset Password Card -->
                    <div class="card" style="max-width: 800px; margin-top: 20px;">
                        <div class="card-header">
                            <h3><i class="fas fa-key"></i> Reset Password</h3>
                        </div>
                        <div class="card-body">
                            <form action="${pageContext.request.contextPath}/user/resetPassword" method="post">
                                <input type="hidden" name="userId" value="${user.userId}">

                                <div
                                    style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px;">
                                    <div class="form-group">
                                        <label for="newPassword">
                                            <i class="fas fa-lock"></i> New Password <span
                                                style="color: #e53e3e;">*</span>
                                        </label>
                                        <input type="password" id="newPassword" name="newPassword" class="form-control"
                                            required minlength="6">
                                    </div>

                                    <div class="form-group">
                                        <label for="confirmPassword">
                                            <i class="fas fa-lock"></i> Confirm Password <span
                                                style="color: #e53e3e;">*</span>
                                        </label>
                                        <input type="password" id="confirmPassword" name="confirmPassword"
                                            class="form-control" required minlength="6">
                                    </div>
                                </div>

                                <div style="margin-top: 20px;">
                                    <button type="submit" class="btn btn-warning">
                                        <i class="fas fa-sync"></i> Reset Password
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </main>
            </div>

            <script>
                document.querySelector('form[action*="resetPassword"]').addEventListener('submit', function (e) {
                    var newPass = document.getElementById('newPassword').value;
                    var confirmPass = document.getElementById('confirmPassword').value;
                    if (newPass !== confirmPass) {
                        e.preventDefault();
                        alert('Passwords do not match!');
                    }
                });
            </script>
        </body>

        </html>