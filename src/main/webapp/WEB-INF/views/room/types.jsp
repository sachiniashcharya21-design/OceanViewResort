<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
            <!DOCTYPE html>
            <html lang="en">

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Room Types & Rates - Ocean View Resort</title>
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
                            <h1><i class="fas fa-tags"></i> Room Types & Rates</h1>
                            <div class="user-info">
                                <c:if test="${sessionScope.role == 'ADMIN'}">
                                    <a href="${pageContext.request.contextPath}/room/type/add" class="btn btn-primary"
                                        style="margin-right: 15px;">
                                        <i class="fas fa-plus"></i> Add Room Type
                                    </a>
                                </c:if>
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

                        <!-- Room Types -->
                        <div
                            style="display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 20px;">
                            <c:forEach var="rt" items="${roomTypes}">
                                <div class="card">
                                    <div class="card-header">
                                        <h3><i class="fas fa-bed"></i> ${rt.typeName}</h3>
                                        <span class="badge badge-success">Active</span>
                                    </div>
                                    <div class="card-body">
                                        <p style="color: #718096; margin-bottom: 20px;">${rt.description}</p>

                                        <div
                                            style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 20px;">
                                            <div
                                                style="background: #f8fafc; padding: 15px; border-radius: 10px; text-align: center;">
                                                <p style="color: #718096; font-size: 0.85rem;">Rate per Night</p>
                                                <p
                                                    style="font-size: 1.3rem; font-weight: 700; color: var(--primary-color);">
                                                    Rs.
                                                    <fmt:formatNumber value="${rt.ratePerNight}" pattern="#,##0" />
                                                </p>
                                            </div>
                                            <div
                                                style="background: #f8fafc; padding: 15px; border-radius: 10px; text-align: center;">
                                                <p style="color: #718096; font-size: 0.85rem;">Max Occupancy</p>
                                                <p
                                                    style="font-size: 1.3rem; font-weight: 700; color: var(--primary-color);">
                                                    ${rt.maxOccupancy} Persons
                                                </p>
                                            </div>
                                        </div>

                                        <p style="font-weight: 600; margin-bottom: 10px;"><i class="fas fa-star"></i>
                                            Amenities</p>
                                        <p style="color: #718096; font-size: 0.9rem;">${rt.amenities}</p>

                                        <c:if test="${sessionScope.role == 'ADMIN'}">
                                            <hr
                                                style="margin: 20px 0; border: none; border-top: 1px solid var(--border-color);">
                                            <form action="${pageContext.request.contextPath}/room/update-rate"
                                                method="post" style="display: flex; gap: 10px; align-items: end;">
                                                <input type="hidden" name="roomTypeId" value="${rt.roomTypeId}">
                                                <div style="flex: 1;">
                                                    <label style="font-size: 0.85rem; color: #718096;">Update Rate
                                                        (Rs.)</label>
                                                    <input type="number" name="newRate" class="form-control"
                                                        value="${rt.ratePerNight}" min="1000" step="100" required>
                                                </div>
                                                <button type="submit" class="btn btn-primary btn-sm">
                                                    <i class="fas fa-save"></i> Update
                                                </button>
                                            </form>
                                            <div style="display: flex; gap: 10px; margin-top: 15px;">
                                                <a href="${pageContext.request.contextPath}/room/type/edit?id=${rt.roomTypeId}"
                                                    class="btn btn-secondary btn-sm"
                                                    style="flex: 1; text-align: center;">
                                                    <i class="fas fa-edit"></i> Edit Type
                                                </a>
                                                <form action="${pageContext.request.contextPath}/room/type/delete"
                                                    method="post" style="flex: 1;"
                                                    onsubmit="return confirm('Are you sure you want to delete this room type?');">
                                                    <input type="hidden" name="roomTypeId" value="${rt.roomTypeId}">
                                                    <button type="submit" class="btn btn-danger btn-sm"
                                                        style="width: 100%;">
                                                        <i class="fas fa-trash"></i> Delete
                                                    </button>
                                                </form>
                                            </div>
                                        </c:if>
                                    </div>
                                </div>
                            </c:forEach>
                        </div>
                    </main>
                </div>
            </body>

            </html>