<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
            <!DOCTYPE html>
            <html lang="en">

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Add Reservation - Ocean View Resort</title>
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
                            <h1><i class="fas fa-plus-circle"></i> New Reservation</h1>
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
                        <c:if test="${not empty error}">
                            <div class="alert alert-error">
                                <i class="fas fa-exclamation-circle"></i> ${error}
                            </div>
                        </c:if>

                        <!-- Add Reservation Form -->
                        <form action="${pageContext.request.contextPath}/reservation/add" method="post">
                            <!-- Guest Information -->
                            <div class="card">
                                <div class="card-header">
                                    <h3><i class="fas fa-user"></i> Guest Information</h3>
                                </div>
                                <div class="card-body">
                                    <div class="form-row">
                                        <div class="form-group">
                                            <label for="guestName">Full Name *</label>
                                            <input type="text" id="guestName" name="guestName" class="form-control"
                                                required placeholder="Enter guest's full name">
                                        </div>
                                        <div class="form-group">
                                            <label for="phone">Phone Number *</label>
                                            <input type="tel" id="phone" name="phone" class="form-control" required
                                                placeholder="+94XXXXXXXXX">
                                        </div>
                                    </div>
                                    <div class="form-row">
                                        <div class="form-group">
                                            <label for="email">Email Address</label>
                                            <input type="email" id="email" name="email" class="form-control"
                                                placeholder="guest@email.com">
                                        </div>
                                        <div class="form-group">
                                            <label for="nicPassport">NIC / Passport</label>
                                            <input type="text" id="nicPassport" name="nicPassport" class="form-control"
                                                placeholder="NIC or Passport number">
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label for="address">Address *</label>
                                        <input type="text" id="address" name="address" class="form-control" required
                                            placeholder="Enter guest's address">
                                    </div>
                                </div>
                            </div>

                            <!-- Booking Details -->
                            <div class="card">
                                <div class="card-header">
                                    <h3><i class="fas fa-calendar-alt"></i> Booking Details</h3>
                                </div>
                                <div class="card-body">
                                    <div class="form-row">
                                        <div class="form-group">
                                            <label for="checkInDate">Check-in Date *</label>
                                            <input type="date" id="checkInDate" name="checkInDate" class="form-control"
                                                required min="${java.time.LocalDate.now()}">
                                        </div>
                                        <div class="form-group">
                                            <label for="checkOutDate">Check-out Date *</label>
                                            <input type="date" id="checkOutDate" name="checkOutDate"
                                                class="form-control" required>
                                        </div>
                                    </div>
                                    <div class="form-row">
                                        <div class="form-group">
                                            <label for="numberOfGuests">Number of Guests *</label>
                                            <input type="number" id="numberOfGuests" name="numberOfGuests"
                                                class="form-control" required min="1" max="10" value="1">
                                        </div>
                                        <div class="form-group">
                                            <label for="roomId">Select Room *</label>
                                            <select id="roomId" name="roomId" class="form-control" required>
                                                <option value="">-- Select a Room --</option>
                                                <c:forEach var="room" items="${availableRooms}">
                                                    <option value="${room.roomId}">
                                                        Room ${room.roomNumber} - ${room.roomType.typeName}
                                                        (Rs.
                                                        <fmt:formatNumber value="${room.roomType.ratePerNight}"
                                                            pattern="#,##0.00" />/night)
                                                    </option>
                                                </c:forEach>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label for="specialRequests">Special Requests</label>
                                        <textarea id="specialRequests" name="specialRequests" class="form-control"
                                            rows="3" placeholder="Any special requests or notes..."></textarea>
                                    </div>
                                </div>
                            </div>

                            <!-- Room Types Reference -->
                            <div class="card">
                                <div class="card-header">
                                    <h3><i class="fas fa-bed"></i> Available Room Types</h3>
                                </div>
                                <div class="card-body">
                                    <div class="table-container">
                                        <table class="table">
                                            <thead>
                                                <tr>
                                                    <th>Room Type</th>
                                                    <th>Rate / Night</th>
                                                    <th>Max Occupancy</th>
                                                    <th>Amenities</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <c:forEach var="rt" items="${roomTypes}">
                                                    <tr>
                                                        <td><strong>${rt.typeName}</strong></td>
                                                        <td>Rs.
                                                            <fmt:formatNumber value="${rt.ratePerNight}"
                                                                pattern="#,##0.00" />
                                                        </td>
                                                        <td>${rt.maxOccupancy} persons</td>
                                                        <td>${rt.amenities}</td>
                                                    </tr>
                                                </c:forEach>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                            <!-- Form Actions -->
                            <div class="card">
                                <div class="card-body">
                                    <div class="form-actions" style="border-top: none; padding-top: 0; margin-top: 0;">
                                        <button type="submit" class="btn btn-primary">
                                            <i class="fas fa-check"></i> Create Reservation
                                        </button>
                                        <a href="${pageContext.request.contextPath}/reservation/list"
                                            class="btn btn-secondary">
                                            <i class="fas fa-times"></i> Cancel
                                        </a>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </main>
                </div>

                <script>
                    // Set minimum check-out date based on check-in date
                    document.getElementById('checkInDate').addEventListener('change', function () {
                        var checkIn = new Date(this.value);
                        checkIn.setDate(checkIn.getDate() + 1);
                        var minCheckOut = checkIn.toISOString().split('T')[0];
                        document.getElementById('checkOutDate').min = minCheckOut;
                    });
                </script>
            </body>

            </html>