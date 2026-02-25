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

                            <a href="${pageContext.request.contextPath}/reservation/list" class="nav-item active">
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
                                <div class="nav-divider"></div>
                                <div class="nav-section-title">Administration</div>
                                <a href="${pageContext.request.contextPath}/user/list" class="nav-item">
                                    <i class="fas fa-user-tie"></i> Staff Management
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
                            <h1><i class="fas fa-calendar-check"></i> ${pageTitle}</h1>
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
                        <c:if test="${not empty error}">
                            <div class="alert alert-error">
                                <i class="fas fa-exclamation-circle"></i> ${error}
                            </div>
                        </c:if>

                        <!-- Actions & Search -->
                        <div class="card">
                            <div class="card-body">
                                <div
                                    style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 15px;">
                                    <a href="${pageContext.request.contextPath}/reservation/add"
                                        class="btn btn-primary">
                                        <i class="fas fa-plus"></i> New Reservation
                                    </a>

                                    <form action="${pageContext.request.contextPath}/reservation/search" method="get"
                                        class="search-box" style="margin-bottom: 0;">
                                        <input type="text" name="q"
                                            placeholder="Search by reservation no. or guest name..."
                                            value="${searchTerm}" style="min-width: 300px;">
                                        <button type="submit" class="btn btn-primary">
                                            <i class="fas fa-search"></i> Search
                                        </button>
                                    </form>

                                    <div class="quick-actions" style="margin-bottom: 0;">
                                        <a href="${pageContext.request.contextPath}/reservation/today-checkins"
                                            class="btn btn-sm btn-success">
                                            <i class="fas fa-sign-in-alt"></i> Today's Check-ins
                                        </a>
                                        <a href="${pageContext.request.contextPath}/reservation/today-checkouts"
                                            class="btn btn-sm btn-warning">
                                            <i class="fas fa-sign-out-alt"></i> Today's Check-outs
                                        </a>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Reservations Table -->
                        <div class="card">
                            <div class="card-header">
                                <h3><i class="fas fa-list"></i> Reservations (${reservations.size()})</h3>
                            </div>
                            <div class="card-body">
                                <div class="table-container">
                                    <table class="table">
                                        <thead>
                                            <tr>
                                                <th>Reservation No</th>
                                                <th>Guest Name</th>
                                                <th>Room</th>
                                                <th>Check-in</th>
                                                <th>Check-out</th>
                                                <th>Guests</th>
                                                <th>Status</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <c:forEach var="res" items="${reservations}">
                                                <tr>
                                                    <td><strong>${res.reservationNumber}</strong></td>
                                                    <td>${res.guest.fullName}</td>
                                                    <td>${res.room.roomNumber} (${res.room.roomType.typeName})</td>
                                                    <td>
                                                        <fmt:formatDate value="${res.checkInDate}"
                                                            pattern="MMM dd, yyyy" />
                                                    </td>
                                                    <td>
                                                        <fmt:formatDate value="${res.checkOutDate}"
                                                            pattern="MMM dd, yyyy" />
                                                    </td>
                                                    <td>${res.numberOfGuests}</td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${res.status == 'CONFIRMED'}">
                                                                <span class="badge badge-info">Confirmed</span>
                                                            </c:when>
                                                            <c:when test="${res.status == 'CHECKED_IN'}">
                                                                <span class="badge badge-success">Checked In</span>
                                                            </c:when>
                                                            <c:when test="${res.status == 'CHECKED_OUT'}">
                                                                <span class="badge badge-secondary">Checked Out</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge badge-danger">Cancelled</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                    <td>
                                                        <a href="${pageContext.request.contextPath}/reservation/view?id=${res.reservationNumber}"
                                                            class="btn btn-sm btn-secondary" title="View Details">
                                                            <i class="fas fa-eye"></i>
                                                        </a>
                                                        <c:if test="${res.status == 'CONFIRMED'}">
                                                            <form
                                                                action="${pageContext.request.contextPath}/reservation/checkin"
                                                                method="post" style="display:inline;">
                                                                <input type="hidden" name="id"
                                                                    value="${res.reservationNumber}">
                                                                <button type="submit" class="btn btn-sm btn-success"
                                                                    title="Check-in">
                                                                    <i class="fas fa-sign-in-alt"></i>
                                                                </button>
                                                            </form>
                                                            <form
                                                                action="${pageContext.request.contextPath}/reservation/cancel"
                                                                method="post" style="display:inline;"
                                                                onsubmit="return confirm('Are you sure you want to cancel this reservation?');">
                                                                <input type="hidden" name="id"
                                                                    value="${res.reservationNumber}">
                                                                <button type="submit" class="btn btn-sm btn-danger"
                                                                    title="Cancel">
                                                                    <i class="fas fa-times"></i>
                                                                </button>
                                                            </form>
                                                        </c:if>
                                                        <c:if test="${res.status == 'CHECKED_IN'}">
                                                            <form
                                                                action="${pageContext.request.contextPath}/reservation/checkout"
                                                                method="post" style="display:inline;">
                                                                <input type="hidden" name="id"
                                                                    value="${res.reservationNumber}">
                                                                <button type="submit" class="btn btn-sm btn-warning"
                                                                    title="Check-out">
                                                                    <i class="fas fa-sign-out-alt"></i>
                                                                </button>
                                                            </form>
                                                        </c:if>
                                                    </td>
                                                </tr>
                                            </c:forEach>
                                            <c:if test="${empty reservations}">
                                                <tr>
                                                    <td colspan="8"
                                                        style="text-align: center; color: #718096; padding: 40px;">
                                                        <i class="fas fa-calendar-times"
                                                            style="font-size: 3rem; margin-bottom: 15px; display: block;"></i>
                                                        No reservations found
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