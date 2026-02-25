<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
            <!DOCTYPE html>
            <html lang="en">

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Guest Details - Ocean View Resort</title>
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
                            <h1><i class="fas fa-user"></i> Guest Details</h1>
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

                        <!-- Guest Details Card -->
                        <div class="card">
                            <div class="card-header">
                                <h3><i class="fas fa-user-circle"></i> ${guest.fullName}</h3>
                                <div>
                                    <a href="${pageContext.request.contextPath}/guest/edit?id=${guest.guestId}"
                                        class="btn btn-warning">
                                        <i class="fas fa-edit"></i> Edit
                                    </a>
                                    <a href="${pageContext.request.contextPath}/reservation/add?guestId=${guest.guestId}"
                                        class="btn btn-primary">
                                        <i class="fas fa-plus"></i> New Booking
                                    </a>
                                    <a href="${pageContext.request.contextPath}/guest/list" class="btn btn-secondary">
                                        <i class="fas fa-arrow-left"></i> Back
                                    </a>
                                </div>
                            </div>
                            <div class="card-body">
                                <div
                                    style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 30px;">
                                    <!-- Personal Information -->
                                    <div>
                                        <h4
                                            style="color: #0077b6; margin-bottom: 15px; padding-bottom: 10px; border-bottom: 2px solid #e2e8f0;">
                                            <i class="fas fa-id-card"></i> Personal Information
                                        </h4>
                                        <table style="width: 100%;">
                                            <tr>
                                                <td style="padding: 8px 0; color: #718096; width: 40%;">Guest ID</td>
                                                <td style="padding: 8px 0; font-weight: 600;">#${guest.guestId}</td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; color: #718096;">Full Name</td>
                                                <td style="padding: 8px 0; font-weight: 600;">${guest.fullName}</td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; color: #718096;">ID/Passport</td>
                                                <td style="padding: 8px 0; font-weight: 600;">${guest.idPassport}</td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; color: #718096;">Nationality</td>
                                                <td style="padding: 8px 0;">${guest.nationality}</td>
                                            </tr>
                                        </table>
                                    </div>

                                    <!-- Contact Information -->
                                    <div>
                                        <h4
                                            style="color: #0077b6; margin-bottom: 15px; padding-bottom: 10px; border-bottom: 2px solid #e2e8f0;">
                                            <i class="fas fa-address-book"></i> Contact Information
                                        </h4>
                                        <table style="width: 100%;">
                                            <tr>
                                                <td style="padding: 8px 0; color: #718096; width: 40%;">Phone</td>
                                                <td style="padding: 8px 0;">
                                                    <a href="tel:${guest.phone}" style="color: #0077b6;">
                                                        <i class="fas fa-phone"></i> ${guest.phone}
                                                    </a>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; color: #718096;">Email</td>
                                                <td style="padding: 8px 0;">
                                                    <c:choose>
                                                        <c:when test="${not empty guest.email}">
                                                            <a href="mailto:${guest.email}" style="color: #0077b6;">
                                                                <i class="fas fa-envelope"></i> ${guest.email}
                                                            </a>
                                                        </c:when>
                                                        <c:otherwise>
                                                            <span style="color: #a0aec0;">Not provided</span>
                                                        </c:otherwise>
                                                    </c:choose>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0; color: #718096;">Address</td>
                                                <td style="padding: 8px 0;">${guest.address}</td>
                                            </tr>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Booking History -->
                        <div class="card">
                            <div class="card-header">
                                <h3><i class="fas fa-history"></i> Booking History</h3>
                            </div>
                            <div class="card-body">
                                <div class="table-container">
                                    <table class="table">
                                        <thead>
                                            <tr>
                                                <th>Reservation ID</th>
                                                <th>Room</th>
                                                <th>Check-in</th>
                                                <th>Check-out</th>
                                                <th>Guests</th>
                                                <th>Total</th>
                                                <th>Status</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <c:forEach var="res" items="${reservations}">
                                                <tr>
                                                    <td><strong>#${res.reservationId}</strong></td>
                                                    <td>Room ${res.roomNumber}</td>
                                                    <td>
                                                        <fmt:formatDate value="${res.checkInDate}"
                                                            pattern="dd MMM yyyy" />
                                                    </td>
                                                    <td>
                                                        <fmt:formatDate value="${res.checkOutDate}"
                                                            pattern="dd MMM yyyy" />
                                                    </td>
                                                    <td>${res.numberOfGuests}</td>
                                                    <td><strong>LKR
                                                            <fmt:formatNumber value="${res.totalAmount}"
                                                                pattern="#,##0.00" />
                                                        </strong></td>
                                                    <td>
                                                        <c:choose>
                                                            <c:when test="${res.status == 'PENDING'}">
                                                                <span class="badge badge-warning">${res.status}</span>
                                                            </c:when>
                                                            <c:when test="${res.status == 'CONFIRMED'}">
                                                                <span class="badge badge-primary">${res.status}</span>
                                                            </c:when>
                                                            <c:when test="${res.status == 'CHECKED_IN'}">
                                                                <span class="badge badge-info">${res.status}</span>
                                                            </c:when>
                                                            <c:when test="${res.status == 'CHECKED_OUT'}">
                                                                <span class="badge badge-success">${res.status}</span>
                                                            </c:when>
                                                            <c:when test="${res.status == 'CANCELLED'}">
                                                                <span class="badge badge-danger">${res.status}</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge">${res.status}</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                    <td>
                                                        <a href="${pageContext.request.contextPath}/reservation/view?id=${res.reservationId}"
                                                            class="btn btn-sm btn-secondary">
                                                            <i class="fas fa-eye"></i>
                                                        </a>
                                                        <a href="${pageContext.request.contextPath}/bill/view?resId=${res.reservationId}"
                                                            class="btn btn-sm btn-primary">
                                                            <i class="fas fa-file-invoice"></i>
                                                        </a>
                                                    </td>
                                                </tr>
                                            </c:forEach>
                                            <c:if test="${empty reservations}">
                                                <tr>
                                                    <td colspan="8"
                                                        style="text-align: center; color: #718096; padding: 40px;">
                                                        <i class="fas fa-calendar-times"
                                                            style="font-size: 2rem; margin-bottom: 10px; display: block;"></i>
                                                        No booking history found
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