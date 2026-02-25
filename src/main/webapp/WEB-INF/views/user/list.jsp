<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
            <!DOCTYPE html>
            <html lang="en">

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Staff Management - Ocean View Resort</title>
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
                            <h1><i class="fas fa-users-cog"></i> Staff Management</h1>
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

                        <!-- Add New Staff Button -->
                        <div style="margin-bottom: 20px;">
                            <a href="${pageContext.request.contextPath}/user/add" class="btn btn-primary">
                                <i class="fas fa-user-plus"></i> Add New Staff
                            </a>
                        </div>

                        <!-- Staff Table -->
                        <div class="card">
                            <div class="card-header">
                                <h3><i class="fas fa-id-badge"></i> Staff Members (${users.size()})</h3>
                            </div>
                            <div class="card-body">
                                <div class="table-container">
                                    <table class="table">
                                        <thead>
                                            <tr>
                                                <th>ID</th>
                                                <th>Username</th>
                                                <th>Full Name</th>
                                                <th>Email</th>
                                                <th>Phone</th>
                                                <th>Role</th>
                                                <th>Status</th>
                                                <th>Last Login</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <c:forEach var="user" items="${users}">
                                                <tr>
                                                    <td>${user.userId}</td>
                                                    <td><strong>${user.username}</strong></td>
                                                    <td>${user.fullName}</td>
                                                    <td>${not empty user.email ? user.email : 'N/A'}</td>
                                                    <td>${not empty user.phone ? user.phone : 'N/A'}</td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${user.role == 'ADMIN'}">
                                                                <span class="badge badge-primary">${user.role}</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge badge-info">${user.role}</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${user.active}">
                                                                <span class="badge badge-success">Active</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge badge-danger">Inactive</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${not empty user.lastLogin}">
                                                                <fmt:formatDate value="${user.lastLogin}"
                                                                    pattern="dd MMM yyyy HH:mm" />
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span style="color: #a0aec0;">Never</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                    <td>
                                                        <a href="${pageContext.request.contextPath}/user/edit?id=${user.userId}"
                                                            class="btn btn-sm btn-warning" title="Edit">
                                                            <i class="fas fa-edit"></i>
                                                        </a>
                                                        <c:if test="${user.userId != sessionScope.userId}">
                                                            <c:choose>
                                                                <c:when test="${user.active}">
                                                                    <form
                                                                        action="${pageContext.request.contextPath}/user/deactivate"
                                                                        method="post" style="display: inline;">
                                                                        <input type="hidden" name="userId"
                                                                            value="${user.userId}">
                                                                        <button type="submit"
                                                                            class="btn btn-sm btn-danger"
                                                                            title="Deactivate"
                                                                            onclick="return confirm('Are you sure you want to deactivate this user?');">
                                                                            <i class="fas fa-user-slash"></i>
                                                                        </button>
                                                                    </form>
                                                                </c:when>
                                                                <c:otherwise>
                                                                    <form
                                                                        action="${pageContext.request.contextPath}/user/activate"
                                                                        method="post" style="display: inline;">
                                                                        <input type="hidden" name="userId"
                                                                            value="${user.userId}">
                                                                        <button type="submit"
                                                                            class="btn btn-sm btn-success"
                                                                            title="Activate">
                                                                            <i class="fas fa-user-check"></i>
                                                                        </button>
                                                                    </form>
                                                                </c:otherwise>
                                                            </c:choose>
                                                        </c:if>
                                                    </td>
                                                </tr>
                                            </c:forEach>
                                            <c:if test="${empty users}">
                                                <tr>
                                                    <td colspan="9"
                                                        style="text-align: center; color: #718096; padding: 40px;">
                                                        <i class="fas fa-users"
                                                            style="font-size: 3rem; margin-bottom: 15px; display: block;"></i>
                                                        No staff members found
                                                    </td>
                                                </tr>
                                            </c:if>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </main>
                </div>
            </body>

            </html>