<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <!DOCTYPE html>
        <html lang="en">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Add Room - Ocean View Resort</title>
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
                        <a href="${pageContext.request.contextPath}/room/list" class="nav-item active">
                            <i class="fas fa-bed"></i> Rooms
                        </a>
                        <a href="${pageContext.request.contextPath}/guest/list" class="nav-item">
                            <i class="fas fa-users"></i> Guests
                        </a>
                        <a href="${pageContext.request.contextPath}/bill/list" class="nav-item">
                            <i class="fas fa-file-invoice-dollar"></i> Billing
                        </a>
                        <a href="${pageContext.request.contextPath}/user/list" class="nav-item">
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
                        <h1><i class="fas fa-plus-circle"></i> Add New Room</h1>
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

                    <!-- Add Room Form -->
                    <div class="card" style="max-width: 700px;">
                        <div class="card-header">
                            <h3><i class="fas fa-bed"></i> Room Details</h3>
                            <a href="${pageContext.request.contextPath}/room/list" class="btn btn-secondary">
                                <i class="fas fa-arrow-left"></i> Back
                            </a>
                        </div>
                        <div class="card-body">
                            <form action="${pageContext.request.contextPath}/room/create" method="post">
                                <div
                                    style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px;">
                                    <!-- Room Number -->
                                    <div class="form-group">
                                        <label for="roomNumber">
                                            <i class="fas fa-door-open"></i> Room Number <span
                                                style="color: #e53e3e;">*</span>
                                        </label>
                                        <input type="text" id="roomNumber" name="roomNumber" class="form-control"
                                            required placeholder="e.g., 101, 202, 301">
                                    </div>

                                    <!-- Floor -->
                                    <div class="form-group">
                                        <label for="floor">
                                            <i class="fas fa-building"></i> Floor <span style="color: #e53e3e;">*</span>
                                        </label>
                                        <select id="floor" name="floor" class="form-control" required>
                                            <option value="">Select Floor</option>
                                            <option value="1">1st Floor</option>
                                            <option value="2">2nd Floor</option>
                                            <option value="3">3rd Floor</option>
                                            <option value="4">4th Floor</option>
                                            <option value="5">5th Floor</option>
                                        </select>
                                    </div>

                                    <!-- Room Type -->
                                    <div class="form-group">
                                        <label for="roomTypeId">
                                            <i class="fas fa-star"></i> Room Type <span style="color: #e53e3e;">*</span>
                                        </label>
                                        <select id="roomTypeId" name="roomTypeId" class="form-control" required>
                                            <option value="">Select Room Type</option>
                                            <c:forEach var="type" items="${roomTypes}">
                                                <option value="${type.typeId}">${type.typeName} - LKR
                                                    ${type.baseRate}/night</option>
                                            </c:forEach>
                                        </select>
                                    </div>

                                    <!-- Status -->
                                    <div class="form-group">
                                        <label for="status">
                                            <i class="fas fa-info-circle"></i> Initial Status <span
                                                style="color: #e53e3e;">*</span>
                                        </label>
                                        <select id="status" name="status" class="form-control" required>
                                            <option value="AVAILABLE" selected>Available</option>
                                            <option value="MAINTENANCE">Under Maintenance</option>
                                        </select>
                                    </div>
                                </div>

                                <!-- Room Types Info -->
                                <div style="background: #f7fafc; padding: 20px; border-radius: 8px; margin-top: 25px;">
                                    <h4 style="margin-bottom: 15px; color: #0077b6;"><i class="fas fa-info-circle"></i>
                                        Room Type Details</h4>
                                    <div class="table-container">
                                        <table class="table" style="margin: 0;">
                                            <thead>
                                                <tr>
                                                    <th>Type</th>
                                                    <th>Base Rate</th>
                                                    <th>Max Occupancy</th>
                                                    <th>Description</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <c:forEach var="type" items="${roomTypes}">
                                                    <tr>
                                                        <td><strong>${type.typeName}</strong></td>
                                                        <td>LKR ${type.baseRate}</td>
                                                        <td>${type.maxOccupancy} guests</td>
                                                        <td>${type.description}</td>
                                                    </tr>
                                                </c:forEach>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>

                                <div
                                    style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e2e8f0; display: flex; gap: 10px; justify-content: flex-end;">
                                    <a href="${pageContext.request.contextPath}/room/list" class="btn btn-secondary">
                                        <i class="fas fa-times"></i> Cancel
                                    </a>
                                    <button type="submit" class="btn btn-primary">
                                        <i class="fas fa-plus"></i> Add Room
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </main>
            </div>
        </body>

        </html>