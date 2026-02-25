<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
            <!DOCTYPE html>
            <html lang="en">

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>${pageTitle} - Ocean View Resort</title>
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
                            <a href="${pageContext.request.contextPath}/guest/list" class="nav-item active">
                                <i class="fas fa-users"></i> Guests
                            </a>
                            <a href="${pageContext.request.contextPath}/bill/list" class="nav-item">
                                <i class="fas fa-file-invoice-dollar"></i> Billing
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
                            <h1><i class="fas fa-users"></i> ${pageTitle}</h1>
                            <div class="user-info">
                                <a href="${pageContext.request.contextPath}/guest/add" class="btn btn-primary"
                                    style="margin-right: 15px;">
                                    <i class="fas fa-user-plus"></i> Register Guest
                                </a>
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

                        <!-- Search -->
                        <div class="card">
                            <div class="card-body">
                                <form action="${pageContext.request.contextPath}/guest/search" method="get"
                                    class="search-box" style="margin-bottom: 0;">
                                    <input type="text" name="q" placeholder="Search by guest name..."
                                        value="${searchTerm}" style="flex: 1;">
                                    <button type="submit" class="btn btn-primary">
                                        <i class="fas fa-search"></i> Search
                                    </button>
                                    <a href="${pageContext.request.contextPath}/guest/list" class="btn btn-secondary">
                                        <i class="fas fa-list"></i> View All
                                    </a>
                                </form>
                            </div>
                        </div>

                        <!-- Guests Table -->
                        <div class="card">
                            <div class="card-header">
                                <h3><i class="fas fa-users"></i> Guests (${guests.size()})</h3>
                            </div>
                            <div class="card-body">
                                <div class="table-container">
                                    <table class="table">
                                        <thead>
                                            <tr>
                                                <th>ID</th>
                                                <th>Name</th>
                                                <th>Phone</th>
                                                <th>Email</th>
                                                <th>Address</th>
                                                <th>Nationality</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <c:forEach var="guest" items="${guests}">
                                                <tr>
                                                    <td>${guest.guestId}</td>
                                                    <td><strong>${guest.fullName}</strong></td>
                                                    <td>${guest.phone}</td>
                                                    <td>${not empty guest.email ? guest.email : 'N/A'}</td>
                                                    <td>${guest.address}</td>
                                                    <td>${guest.nationality}</td>
                                                    <td>
                                                        <a href="${pageContext.request.contextPath}/guest/view?id=${guest.guestId}"
                                                            class="btn btn-sm btn-secondary" title="View Details">
                                                            <i class="fas fa-eye"></i>
                                                        </a>
                                                        <a href="${pageContext.request.contextPath}/guest/history?id=${guest.guestId}"
                                                            class="btn btn-sm btn-primary" title="Booking History">
                                                            <i class="fas fa-history"></i>
                                                        </a>
                                                        <a href="${pageContext.request.contextPath}/guest/edit?id=${guest.guestId}"
                                                            class="btn btn-sm btn-warning" title="Edit">
                                                            <i class="fas fa-edit"></i>
                                                        </a>
                                                        <c:if test="${sessionScope.role == 'ADMIN'}">
                                                            <form
                                                                action="${pageContext.request.contextPath}/guest/delete"
                                                                method="post" style="display: inline;"
                                                                onsubmit="return confirm('Are you sure you want to delete this guest?');">
                                                                <input type="hidden" name="id" value="${guest.guestId}">
                                                                <button type="submit" class="btn btn-sm btn-danger"
                                                                    title="Delete">
                                                                    <i class="fas fa-trash"></i>
                                                                </button>
                                                            </form>
                                                        </c:if>
                                                    </td>
                                                </tr>
                                            </c:forEach>
                                            <c:if test="${empty guests}">
                                                <tr>
                                                    <td colspan="7"
                                                        style="text-align: center; color: #718096; padding: 40px;">
                                                        <i class="fas fa-users"
                                                            style="font-size: 3rem; margin-bottom: 15px; display: block;"></i>
                                                        No guests found
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