<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <!DOCTYPE html>
        <html lang="en">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Edit Guest - Ocean View Resort</title>
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
                        <h1><i class="fas fa-user-edit"></i> Edit Guest</h1>
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

                    <!-- Edit Form -->
                    <div class="card">
                        <div class="card-header">
                            <h3><i class="fas fa-edit"></i> Guest Information - #${guest.guestId}</h3>
                            <a href="${pageContext.request.contextPath}/guest/view?id=${guest.guestId}"
                                class="btn btn-secondary">
                                <i class="fas fa-arrow-left"></i> Back
                            </a>
                        </div>
                        <div class="card-body">
                            <form action="${pageContext.request.contextPath}/guest/update" method="post">
                                <input type="hidden" name="guestId" value="${guest.guestId}">

                                <div
                                    style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px;">
                                    <!-- Full Name -->
                                    <div class="form-group">
                                        <label for="fullName">
                                            <i class="fas fa-user"></i> Full Name <span style="color: #e53e3e;">*</span>
                                        </label>
                                        <input type="text" id="fullName" name="fullName" class="form-control"
                                            value="${guest.fullName}" required>
                                    </div>

                                    <!-- ID/Passport -->
                                    <div class="form-group">
                                        <label for="idPassport">
                                            <i class="fas fa-id-card"></i> ID/Passport Number <span
                                                style="color: #e53e3e;">*</span>
                                        </label>
                                        <input type="text" id="idPassport" name="idPassport" class="form-control"
                                            value="${guest.idPassport}" required>
                                    </div>

                                    <!-- Phone -->
                                    <div class="form-group">
                                        <label for="phone">
                                            <i class="fas fa-phone"></i> Phone Number <span
                                                style="color: #e53e3e;">*</span>
                                        </label>
                                        <input type="tel" id="phone" name="phone" class="form-control"
                                            value="${guest.phone}" required>
                                    </div>

                                    <!-- Email -->
                                    <div class="form-group">
                                        <label for="email">
                                            <i class="fas fa-envelope"></i> Email Address
                                        </label>
                                        <input type="email" id="email" name="email" class="form-control"
                                            value="${guest.email}" placeholder="Optional">
                                    </div>

                                    <!-- Address -->
                                    <div class="form-group" style="grid-column: 1 / -1;">
                                        <label for="address">
                                            <i class="fas fa-map-marker-alt"></i> Address <span
                                                style="color: #e53e3e;">*</span>
                                        </label>
                                        <textarea id="address" name="address" class="form-control" rows="2"
                                            required>${guest.address}</textarea>
                                    </div>

                                    <!-- Nationality -->
                                    <div class="form-group">
                                        <label for="nationality">
                                            <i class="fas fa-globe"></i> Nationality <span
                                                style="color: #e53e3e;">*</span>
                                        </label>
                                        <select id="nationality" name="nationality" class="form-control" required>
                                            <option value="">Select Country</option>
                                            <option value="Sri Lanka" ${guest.nationality=='Sri Lanka' ? 'selected' : ''
                                                }>Sri Lanka</option>
                                            <option value="India" ${guest.nationality=='India' ? 'selected' : '' }>India
                                            </option>
                                            <option value="United Kingdom" ${guest.nationality=='United Kingdom'
                                                ? 'selected' : '' }>United Kingdom</option>
                                            <option value="United States" ${guest.nationality=='United States'
                                                ? 'selected' : '' }>United States</option>
                                            <option value="Australia" ${guest.nationality=='Australia' ? 'selected' : ''
                                                }>Australia</option>
                                            <option value="Germany" ${guest.nationality=='Germany' ? 'selected' : '' }>
                                                Germany</option>
                                            <option value="France" ${guest.nationality=='France' ? 'selected' : '' }>
                                                France</option>
                                            <option value="China" ${guest.nationality=='China' ? 'selected' : '' }>China
                                            </option>
                                            <option value="Japan" ${guest.nationality=='Japan' ? 'selected' : '' }>Japan
                                            </option>
                                            <option value="Canada" ${guest.nationality=='Canada' ? 'selected' : '' }>
                                                Canada</option>
                                            <option value="Other" ${guest.nationality=='Other' ? 'selected' : '' }>Other
                                            </option>
                                        </select>
                                    </div>
                                </div>

                                <div
                                    style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e2e8f0; display: flex; gap: 10px; justify-content: flex-end;">
                                    <a href="${pageContext.request.contextPath}/guest/view?id=${guest.guestId}"
                                        class="btn btn-secondary">
                                        <i class="fas fa-times"></i> Cancel
                                    </a>
                                    <button type="submit" class="btn btn-primary">
                                        <i class="fas fa-save"></i> Save Changes
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </main>
            </div>
        </body>

        </html>