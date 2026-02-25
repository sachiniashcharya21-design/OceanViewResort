<%@ page contentType="text/html;charset=UTF-8" language="java" %>
    <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
        <!DOCTYPE html>
        <html lang="en">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Register Guest - Ocean View Resort</title>
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
                        <a href="${pageContext.request.contextPath}/room/list">
                            <i class="fas fa-door-open"></i> Rooms
                        </a>
                        <a href="${pageContext.request.contextPath}/guest/list" class="active">
                            <i class="fas fa-users"></i> Guests
                        </a>
                        <a href="${pageContext.request.contextPath}/bill/list">
                            <i class="fas fa-file-invoice-dollar"></i> Bills
                        </a>
                        <c:if test="${sessionScope.user.role == 'ADMIN'}">
                            <a href="${pageContext.request.contextPath}/user/list">
                                <i class="fas fa-user-cog"></i> Staff
                            </a>
                        </c:if>
                        <a href="${pageContext.request.contextPath}/logout">
                            <i class="fas fa-sign-out-alt"></i> Logout
                        </a>
                    </nav>
                </aside>

                <!-- Main Content -->
                <main class="main-content">
                    <header class="content-header">
                        <h1><i class="fas fa-user-plus"></i> Register New Guest</h1>
                        <div class="header-actions">
                            <a href="${pageContext.request.contextPath}/guest/list" class="btn btn-secondary">
                                <i class="fas fa-arrow-left"></i> Back to Guests
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
                            <form action="${pageContext.request.contextPath}/guest/register" method="post"
                                class="styled-form">
                                <div class="form-section">
                                    <h3><i class="fas fa-user"></i> Personal Information</h3>

                                    <div class="form-row">
                                        <div class="form-group">
                                            <label for="fullName">Full Name *</label>
                                            <input type="text" id="fullName" name="fullName" required
                                                placeholder="Enter guest's full name">
                                        </div>
                                        <div class="form-group">
                                            <label for="nicPassport">NIC/Passport *</label>
                                            <input type="text" id="nicPassport" name="nicPassport" required
                                                placeholder="NIC or Passport number">
                                        </div>
                                    </div>

                                    <div class="form-row">
                                        <div class="form-group">
                                            <label for="phone">Phone Number *</label>
                                            <input type="tel" id="phone" name="phone" required
                                                placeholder="+94 XX XXX XXXX">
                                        </div>
                                        <div class="form-group">
                                            <label for="email">Email Address</label>
                                            <input type="email" id="email" name="email" placeholder="guest@email.com">
                                        </div>
                                    </div>

                                    <div class="form-row">
                                        <div class="form-group">
                                            <label for="nationality">Nationality</label>
                                            <select id="nationality" name="nationality">
                                                <option value="">Select Nationality</option>
                                                <option value="Sri Lankan">Sri Lankan</option>
                                                <option value="Indian">Indian</option>
                                                <option value="British">British</option>
                                                <option value="American">American</option>
                                                <option value="German">German</option>
                                                <option value="French">French</option>
                                                <option value="Australian">Australian</option>
                                                <option value="Chinese">Chinese</option>
                                                <option value="Japanese">Japanese</option>
                                                <option value="Other">Other</option>
                                            </select>
                                        </div>
                                        <div class="form-group">
                                            <label for="address">Address</label>
                                            <input type="text" id="address" name="address"
                                                placeholder="Guest's address">
                                        </div>
                                    </div>
                                </div>

                                <div class="form-actions">
                                    <button type="submit" class="btn btn-primary">
                                        <i class="fas fa-user-plus"></i> Register Guest
                                    </button>
                                    <button type="reset" class="btn btn-secondary">
                                        <i class="fas fa-undo"></i> Reset Form
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </main>
            </div>
        </body>

        </html>