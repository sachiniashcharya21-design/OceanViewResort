<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
            <!DOCTYPE html>
            <html lang="en">

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Reservation Details - Ocean View Resort</title>
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
                            <h1><i class="fas fa-file-alt"></i> Reservation Details</h1>
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

                        <!-- Quick Actions -->
                        <div class="card">
                            <div class="card-body">
                                <div class="quick-actions">
                                    <a href="${pageContext.request.contextPath}/reservation/list"
                                        class="btn btn-secondary">
                                        <i class="fas fa-arrow-left"></i> Back to List
                                    </a>
                                    <c:if test="${reservation.status == 'CONFIRMED'}">
                                        <form action="${pageContext.request.contextPath}/reservation/checkin"
                                            method="post" style="display:inline;">
                                            <input type="hidden" name="id" value="${reservation.reservationNumber}">
                                            <button type="submit" class="btn btn-success">
                                                <i class="fas fa-sign-in-alt"></i> Check-in
                                            </button>
                                        </form>
                                        <form action="${pageContext.request.contextPath}/reservation/cancel"
                                            method="post" style="display:inline;"
                                            onsubmit="return confirm('Are you sure you want to cancel this reservation?');">
                                            <input type="hidden" name="id" value="${reservation.reservationNumber}">
                                            <button type="submit" class="btn btn-danger">
                                                <i class="fas fa-times"></i> Cancel
                                            </button>
                                        </form>
                                    </c:if>
                                    <c:if test="${reservation.status == 'CHECKED_IN'}">
                                        <form action="${pageContext.request.contextPath}/reservation/checkout"
                                            method="post" style="display:inline;">
                                            <input type="hidden" name="id" value="${reservation.reservationNumber}">
                                            <button type="submit" class="btn btn-warning">
                                                <i class="fas fa-sign-out-alt"></i> Check-out
                                            </button>
                                        </form>
                                        <a href="${pageContext.request.contextPath}/bill/generate?reservationNumber=${reservation.reservationNumber}"
                                            class="btn btn-primary">
                                            <i class="fas fa-file-invoice-dollar"></i> Generate Bill
                                        </a>
                                    </c:if>
                                </div>
                            </div>
                        </div>

                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                            <!-- Reservation Information -->
                            <div class="card">
                                <div class="card-header">
                                    <h3><i class="fas fa-calendar-check"></i> Reservation Information</h3>
                                    <c:choose>
                                        <c:when test="${reservation.status == 'CONFIRMED'}">
                                            <span class="badge badge-info">${reservation.status}</span>
                                        </c:when>
                                        <c:when test="${reservation.status == 'CHECKED_IN'}">
                                            <span class="badge badge-success">${reservation.status}</span>
                                        </c:when>
                                        <c:when test="${reservation.status == 'CHECKED_OUT'}">
                                            <span class="badge badge-secondary">${reservation.status}</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge badge-danger">${reservation.status}</span>
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                                <div class="card-body">
                                    <div class="profile-details">
                                        <div class="detail-row">
                                            <span class="detail-label">Reservation No</span>
                                            <span
                                                class="detail-value"><strong>${reservation.reservationNumber}</strong></span>
                                        </div>
                                        <div class="detail-row">
                                            <span class="detail-label">Check-in Date</span>
                                            <span class="detail-value">
                                                <fmt:formatDate value="${reservation.checkInDate}"
                                                    pattern="EEEE, MMM dd, yyyy" />
                                            </span>
                                        </div>
                                        <div class="detail-row">
                                            <span class="detail-label">Check-out Date</span>
                                            <span class="detail-value">
                                                <fmt:formatDate value="${reservation.checkOutDate}"
                                                    pattern="EEEE, MMM dd, yyyy" />
                                            </span>
                                        </div>
                                        <div class="detail-row">
                                            <span class="detail-label">Number of Nights</span>
                                            <span class="detail-value">${reservation.numberOfNights} nights</span>
                                        </div>
                                        <div class="detail-row">
                                            <span class="detail-label">Number of Guests</span>
                                            <span class="detail-value">${reservation.numberOfGuests}</span>
                                        </div>
                                        <div class="detail-row">
                                            <span class="detail-label">Special Requests</span>
                                            <span class="detail-value">${not empty reservation.specialRequests ?
                                                reservation.specialRequests : 'None'}</span>
                                        </div>
                                        <div class="detail-row">
                                            <span class="detail-label">Created At</span>
                                            <span class="detail-value">
                                                <fmt:formatDate value="${reservation.createdAt}"
                                                    pattern="MMM dd, yyyy HH:mm" />
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Guest Information -->
                            <div class="card">
                                <div class="card-header">
                                    <h3><i class="fas fa-user"></i> Guest Information</h3>
                                </div>
                                <div class="card-body">
                                    <div class="profile-details">
                                        <div class="detail-row">
                                            <span class="detail-label">Full Name</span>
                                            <span
                                                class="detail-value"><strong>${reservation.guest.fullName}</strong></span>
                                        </div>
                                        <div class="detail-row">
                                            <span class="detail-label">Phone</span>
                                            <span class="detail-value">${reservation.guest.phone}</span>
                                        </div>
                                        <div class="detail-row">
                                            <span class="detail-label">Email</span>
                                            <span class="detail-value">${not empty reservation.guest.email ?
                                                reservation.guest.email : 'N/A'}</span>
                                        </div>
                                        <div class="detail-row">
                                            <span class="detail-label">Address</span>
                                            <span class="detail-value">${reservation.guest.address}</span>
                                        </div>
                                        <div class="detail-row">
                                            <span class="detail-label">NIC/Passport</span>
                                            <span class="detail-value">${not empty reservation.guest.nicPassport ?
                                                reservation.guest.nicPassport : 'N/A'}</span>
                                        </div>
                                        <div class="detail-row">
                                            <span class="detail-label">Nationality</span>
                                            <span class="detail-value">${reservation.guest.nationality}</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Room Information -->
                        <div class="card">
                            <div class="card-header">
                                <h3><i class="fas fa-bed"></i> Room Information</h3>
                            </div>
                            <div class="card-body">
                                <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 30px;">
                                    <div>
                                        <p style="color: #718096; font-size: 0.85rem;">Room Number</p>
                                        <p style="font-size: 1.5rem; font-weight: 700; color: var(--primary-color);">
                                            ${reservation.room.roomNumber}</p>
                                    </div>
                                    <div>
                                        <p style="color: #718096; font-size: 0.85rem;">Room Type</p>
                                        <p style="font-size: 1.2rem; font-weight: 600;">
                                            ${reservation.room.roomType.typeName}</p>
                                    </div>
                                    <div>
                                        <p style="color: #718096; font-size: 0.85rem;">Floor</p>
                                        <p style="font-size: 1.2rem; font-weight: 600;">Floor
                                            ${reservation.room.floorNumber}</p>
                                    </div>
                                    <div>
                                        <p style="color: #718096; font-size: 0.85rem;">Rate per Night</p>
                                        <p style="font-size: 1.2rem; font-weight: 600;">Rs.
                                            <fmt:formatNumber value="${reservation.room.roomType.ratePerNight}"
                                                pattern="#,##0.00" />
                                        </p>
                                    </div>
                                </div>
                                <hr style="margin: 20px 0; border: none; border-top: 1px solid var(--border-color);">
                                <p style="color: #718096; font-size: 0.85rem; margin-bottom: 10px;">Amenities</p>
                                <p>${reservation.room.roomType.amenities}</p>
                            </div>
                        </div>

                        <!-- Bill Summary -->
                        <div class="card">
                            <div class="card-header">
                                <h3><i class="fas fa-calculator"></i> Estimated Charges</h3>
                            </div>
                            <div class="card-body">
                                <div class="invoice-totals">
                                    <div class="total-row">
                                        <span>Room Rate (${reservation.numberOfNights} nights x Rs.
                                            <fmt:formatNumber value="${reservation.room.roomType.ratePerNight}"
                                                pattern="#,##0.00" />)
                                        </span>
                                        <span>Rs.
                                            <fmt:formatNumber
                                                value="${reservation.room.roomType.ratePerNight * reservation.numberOfNights}"
                                                pattern="#,##0.00" />
                                        </span>
                                    </div>
                                    <div class="total-row">
                                        <span>Service Charge (10%)</span>
                                        <span>Rs.
                                            <fmt:formatNumber
                                                value="${(reservation.room.roomType.ratePerNight * reservation.numberOfNights) * 0.10}"
                                                pattern="#,##0.00" />
                                        </span>
                                    </div>
                                    <div class="total-row">
                                        <span>Tax (5%)</span>
                                        <span>Rs.
                                            <fmt:formatNumber
                                                value="${(reservation.room.roomType.ratePerNight * reservation.numberOfNights) * 0.05}"
                                                pattern="#,##0.00" />
                                        </span>
                                    </div>
                                    <div class="total-row grand-total">
                                        <span>Estimated Total</span>
                                        <span>Rs.
                                            <fmt:formatNumber
                                                value="${(reservation.room.roomType.ratePerNight * reservation.numberOfNights) * 1.15}"
                                                pattern="#,##0.00" />
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </main>
                </div>
            </body>

            </html>