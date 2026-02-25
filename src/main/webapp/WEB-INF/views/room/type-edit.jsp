<%@ page contentType="text/html;charset=UTF-8" language="java" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
            <!DOCTYPE html>
            <html lang="en">

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Edit Room Type - Ocean View Resort</title>
                <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
                <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
            </head>

            <body>
                <div class="dashboard-container">
                    <!-- Sidebar -->
                    <aside class="sidebar">
                        <div class="sidebar-header">
                            <h2><i class="fas fa-hotel"></i> Ocean View</h2>
                        </div>
                        <nav class="sidebar-nav">
                            <a href="${pageContext.request.contextPath}/admin/dashboard">
                                <i class="fas fa-tachometer-alt"></i> Dashboard
                            </a>
                            <a href="${pageContext.request.contextPath}/reservation/list">
                                <i class="fas fa-calendar-check"></i> Reservations
                            </a>
                            <a href="${pageContext.request.contextPath}/room/list" class="active">
                                <i class="fas fa-door-open"></i> Rooms
                            </a>
                            <a href="${pageContext.request.contextPath}/guest/list">
                                <i class="fas fa-users"></i> Guests
                            </a>
                            <a href="${pageContext.request.contextPath}/bill/list">
                                <i class="fas fa-file-invoice-dollar"></i> Bills
                            </a>
                            <a href="${pageContext.request.contextPath}/user/list">
                                <i class="fas fa-user-cog"></i> Staff
                            </a>
                            <a href="${pageContext.request.contextPath}/logout">
                                <i class="fas fa-sign-out-alt"></i> Logout
                            </a>
                        </nav>
                    </aside>

                    <!-- Main Content -->
                    <main class="main-content">
                        <header class="content-header">
                            <h1><i class="fas fa-edit"></i> Edit Room Type</h1>
                            <div class="header-actions">
                                <a href="${pageContext.request.contextPath}/room/types" class="btn btn-secondary">
                                    <i class="fas fa-arrow-left"></i> Back to Room Types
                                </a>
                            </div>
                        </header>

                        <div class="content-body">
                            <!-- Alert Messages -->
                            <c:if test="${not empty sessionScope.error}">
                                <div class="alert alert-danger">
                                    <i class="fas fa-exclamation-circle"></i>
                                    ${sessionScope.error}
                                    <c:remove var="error" scope="session" />
                                </div>
                            </c:if>

                            <div class="form-card">
                                <form action="${pageContext.request.contextPath}/room/type/update" method="post"
                                    class="styled-form">
                                    <input type="hidden" name="roomTypeId" value="${roomType.roomTypeId}">

                                    <div class="form-section">
                                        <h3><i class="fas fa-bed"></i> Room Type Details</h3>

                                        <div class="form-row">
                                            <div class="form-group">
                                                <label for="typeName">Type Name *</label>
                                                <input type="text" id="typeName" name="typeName" required
                                                    value="${roomType.typeName}">
                                            </div>
                                            <div class="form-group">
                                                <label for="baseRate">Base Rate Per Night (LKR) *</label>
                                                <input type="number" id="baseRate" name="baseRate" required min="0"
                                                    step="0.01" value="${roomType.ratePerNight}">
                                            </div>
                                        </div>

                                        <div class="form-row">
                                            <div class="form-group">
                                                <label for="maxOccupancy">Max Occupancy *</label>
                                                <input type="number" id="maxOccupancy" name="maxOccupancy" required
                                                    min="1" max="10" value="${roomType.maxOccupancy}">
                                            </div>
                                            <div class="form-group">
                                                <label for="description">Description</label>
                                                <input type="text" id="description" name="description"
                                                    value="${roomType.description}">
                                            </div>
                                        </div>

                                        <div class="form-group full-width">
                                            <label for="amenities">Amenities</label>
                                            <textarea id="amenities" name="amenities"
                                                rows="3">${roomType.amenities}</textarea>
                                        </div>
                                    </div>

                                    <div class="form-actions">
                                        <button type="submit" class="btn btn-primary">
                                            <i class="fas fa-save"></i> Update Room Type
                                        </button>
                                        <a href="${pageContext.request.contextPath}/room/types"
                                            class="btn btn-secondary">
                                            <i class="fas fa-times"></i> Cancel
                                        </a>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </main>
                </div>
            </body>

            </html>