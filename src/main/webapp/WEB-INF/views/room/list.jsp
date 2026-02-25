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
                            <a href="${pageContext.request.contextPath}/room/list" class="nav-item active">
                                <i class="fas fa-bed"></i> Rooms
                            </a>
                            <a href="${pageContext.request.contextPath}/guest/list" class="nav-item">
                                <i class="fas fa-users"></i> Guests
                            </a>
                            <a href="${pageContext.request.contextPath}/bill/list" class="nav-item">
                                <i class="fas fa-file-invoice-dollar"></i> Billing
                            </a>

                            <c:if test="${sessionScope.role == 'ADMIN'}">
                                <div class="nav-divider"></div>
                                <div class="nav-section-title">Administration</div>
                                <a href="${pageContext.request.contextPath}/user/list" class="nav-item">
                                    <i class="fas fa-user-tie"></i> Staff Management
                                </a>
                                <a href="${pageContext.request.contextPath}/room/types" class="nav-item">
                                    <i class="fas fa-cog"></i> Room Types & Rates
                                </a>
                            </c:if>

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
                            <h1><i class="fas fa-bed"></i> ${pageTitle}</h1>
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

                        <!-- Actions -->
                        <div class="card">
                            <div class="card-body">
                                <div class="quick-actions">
                                    <a href="${pageContext.request.contextPath}/room/list" class="btn btn-secondary">
                                        <i class="fas fa-list"></i> All Rooms
                                    </a>
                                    <a href="${pageContext.request.contextPath}/room/available" class="btn btn-success">
                                        <i class="fas fa-door-open"></i> Available Rooms
                                    </a>
                                    <a href="${pageContext.request.contextPath}/room/types" class="btn btn-primary">
                                        <i class="fas fa-tags"></i> Room Types & Rates
                                    </a>
                                    <c:if test="${sessionScope.role == 'ADMIN'}">
                                        <a href="${pageContext.request.contextPath}/room/add" class="btn btn-primary">
                                            <i class="fas fa-plus"></i> Add Room
                                        </a>
                                    </c:if>
                                </div>
                            </div>
                        </div>

                        <!-- Rooms Table -->
                        <div class="card">
                            <div class="card-header">
                                <h3><i class="fas fa-bed"></i> Rooms (${rooms.size()})</h3>
                            </div>
                            <div class="card-body">
                                <div class="table-container">
                                    <table class="table">
                                        <thead>
                                            <tr>
                                                <th>Room No</th>
                                                <th>Floor</th>
                                                <th>Room Type</th>
                                                <th>Rate/Night</th>
                                                <th>Max Occupancy</th>
                                                <th>Status</th>
                                                <c:if test="${sessionScope.role == 'ADMIN'}">
                                                    <th>Actions</th>
                                                </c:if>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <c:forEach var="room" items="${rooms}">
                                                <tr>
                                                    <td><strong>${room.roomNumber}</strong></td>
                                                    <td>Floor ${room.floorNumber}</td>
                                                    <td>${room.roomType.typeName}</td>
                                                    <td>Rs.
                                                        <fmt:formatNumber value="${room.roomType.ratePerNight}"
                                                            pattern="#,##0.00" />
                                                    </td>
                                                    <td>${room.roomType.maxOccupancy} persons</td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${room.status == 'AVAILABLE'}">
                                                                <span class="badge badge-success">Available</span>
                                                            </c:when>
                                                            <c:when test="${room.status == 'OCCUPIED'}">
                                                                <span class="badge badge-danger">Occupied</span>
                                                            </c:when>
                                                            <c:when test="${room.status == 'MAINTENANCE'}">
                                                                <span class="badge badge-warning">Maintenance</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge badge-info">Reserved</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                    <c:if test="${sessionScope.role == 'ADMIN'}">
                                                        <td>
                                                            <form
                                                                action="${pageContext.request.contextPath}/room/update-status"
                                                                method="post" style="display:inline;">
                                                                <input type="hidden" name="roomId"
                                                                    value="${room.roomId}">
                                                                <select name="status" onchange="this.form.submit()"
                                                                    class="form-control"
                                                                    style="width: auto; padding: 5px 10px; font-size: 0.85rem;">
                                                                    <option value="">Change...</option>
                                                                    <option value="AVAILABLE">Available</option>
                                                                    <option value="MAINTENANCE">Maintenance</option>
                                                                </select>
                                                            </form>
                                                            <form
                                                                action="${pageContext.request.contextPath}/room/delete"
                                                                method="post" style="display: inline; margin-left: 5px;"
                                                                onsubmit="return confirm('Are you sure you want to delete room ${room.roomNumber}?');">
                                                                <input type="hidden" name="roomId"
                                                                    value="${room.roomId}">
                                                                <button type="submit" class="btn btn-sm btn-danger"
                                                                    title="Delete Room">
                                                                    <i class="fas fa-trash"></i>
                                                                </button>
                                                            </form>
                                                        </td>
                                                    </c:if>
                                                </tr>
                                            </c:forEach>
                                            <c:if test="${empty rooms}">
                                                <tr>
                                                    <td colspan="7"
                                                        style="text-align: center; color: #718096; padding: 40px;">
                                                        <i class="fas fa-bed"
                                                            style="font-size: 3rem; margin-bottom: 15px; display: block;"></i>
                                                        No rooms found
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