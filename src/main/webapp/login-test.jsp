<%@ page contentType="text/html;charset=UTF-8" language="java" %>
    <!DOCTYPE html>
    <html lang="en">

    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Login - Ocean View Resort</title>
        <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap"
            rel="stylesheet">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: 'Poppins', sans-serif;
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
                overflow: hidden;
                position: relative;
            }

            /* Animated Background Slider */
            .bg-slider {
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                z-index: -2;
            }

            .bg-slide {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background-size: cover;
                background-position: center;
                opacity: 0;
                transition: opacity 1.5s ease-in-out;
            }

            .bg-slide.active {
                opacity: 1;
            }

            .bg-slide:nth-child(1) {
                background-image: url('https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80');
            }

            .bg-slide:nth-child(2) {
                background-image: url('https://images.unsplash.com/photo-1582719508461-905c673771fd?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80');
            }

            .bg-slide:nth-child(3) {
                background-image: url('https://images.unsplash.com/photo-1571896349842-33c89424de2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80');
            }

            .bg-slide:nth-child(4) {
                background-image: url('https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80');
            }

            .bg-slide:nth-child(5) {
                background-image: url('https://images.unsplash.com/photo-1584132967334-10e028bd69f7?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80');
            }

            /* Overlay */
            .bg-overlay {
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
            }

            /* Login Container */
            .login-container {
                width: 100%;
                max-width: 450px;
                padding: 20px;
                animation: fadeInUp 0.8s ease-out;
            }

            @keyframes fadeInUp {
                from {
                    opacity: 0;
                    transform: translateY(30px);
                }

                to {
                    opacity: 1;
                    transform: translateY(0);
                }
            }

            /* Login Box */
            .login-box {
                background: rgba(255, 255, 255, 0.95);
                border-radius: 20px;
                padding: 40px;
                box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
                backdrop-filter: blur(10px);
            }

            /* Logo Section */
            .logo-section {
                text-align: center;
                margin-bottom: 30px;
            }

            .logo-icon {
                width: 80px;
                height: 80px;
                background: linear-gradient(135deg, #004040 0%, #008080 100%);
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                margin: 0 auto 15px;
                box-shadow: 0 10px 30px rgba(0, 128, 128, 0.4);
            }

            .logo-icon i {
                font-size: 35px;
                color: white;
            }

            .logo-section h1 {
                color: #004040;
                font-size: 24px;
                font-weight: 700;
                margin-bottom: 5px;
            }

            .logo-section p {
                color: #666;
                font-size: 14px;
            }

            /* Role Tabs */
            .role-tabs {
                display: flex;
                background: #f0f0f0;
                border-radius: 12px;
                padding: 5px;
                margin-bottom: 25px;
            }

            .role-tab {
                flex: 1;
                padding: 12px 20px;
                text-align: center;
                border-radius: 10px;
                cursor: pointer;
                transition: all 0.3s ease;
                font-weight: 500;
                color: #666;
            }

            .role-tab:hover {
                color: #004040;
            }

            .role-tab.active {
                background: linear-gradient(135deg, #004040 0%, #008080 100%);
                color: white;
                box-shadow: 0 5px 15px rgba(0, 128, 128, 0.3);
            }

            .role-tab i {
                margin-right: 8px;
            }

            /* Form Styles */
            .form-group {
                margin-bottom: 20px;
            }

            .form-group label {
                display: block;
                margin-bottom: 8px;
                color: #333;
                font-weight: 500;
                font-size: 14px;
            }

            .input-wrapper {
                position: relative;
            }

            .input-wrapper i {
                position: absolute;
                left: 15px;
                top: 50%;
                transform: translateY(-50%);
                color: #008080;
                font-size: 18px;
            }

            .input-wrapper input {
                width: 100%;
                padding: 15px 15px 15px 50px;
                border: 2px solid #e0e0e0;
                border-radius: 12px;
                font-size: 16px;
                font-family: 'Poppins', sans-serif;
                transition: all 0.3s ease;
                background: #fafafa;
            }

            .input-wrapper input:focus {
                outline: none;
                border-color: #008080;
                background: white;
                box-shadow: 0 0 0 4px rgba(0, 128, 128, 0.1);
            }

            .password-toggle {
                position: absolute;
                right: 15px;
                top: 50%;
                transform: translateY(-50%);
                cursor: pointer;
                color: #999;
                transition: color 0.3s ease;
            }

            .password-toggle:hover {
                color: #008080;
            }

            /* Login Button */
            .login-btn {
                width: 100%;
                padding: 15px;
                background: linear-gradient(135deg, #004040 0%, #008080 100%);
                border: none;
                border-radius: 12px;
                color: white;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.3s ease;
                font-family: 'Poppins', sans-serif;
                display: flex;
                align-items: center;
                justify-content: center;
                gap: 10px;
            }

            .login-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 10px 30px rgba(0, 128, 128, 0.4);
            }

            .login-btn:active {
                transform: translateY(0);
            }

            /* Back to Home Link */
            .back-link {
                text-align: center;
                margin-top: 25px;
            }

            .back-link a {
                color: #008080;
                text-decoration: none;
                font-weight: 500;
                transition: color 0.3s ease;
            }

            .back-link a:hover {
                color: #004040;
            }

            .back-link a i {
                margin-right: 5px;
            }

            /* Hidden role input */
            #selectedRole {
                display: none;
            }

            /* Responsive */
            @media (max-width: 480px) {
                .login-box {
                    padding: 30px 25px;
                }

                .logo-section h1 {
                    font-size: 20px;
                }

                .role-tab {
                    padding: 10px 15px;
                    font-size: 14px;
                }

                .role-tab i {
                    display: none;
                }
            }
        </style>
    </head>

    <body>
        <% // Get error from Servlet if any String errorMessage=(String) request.getAttribute("error"); // Get form data
            to repopulate fields if needed String usernameValue=(String) request.getAttribute("username"); if
            (usernameValue==null) { usernameValue=request.getParameter("username"); } if (usernameValue==null) {
            usernameValue="" ; } // Get role for tab selection String roleParam=(String)
            request.getAttribute("selectedRole"); if (roleParam==null) { roleParam=request.getParameter("role"); } if
            (roleParam==null) { roleParam="staff" ; } %>

            <!-- Animated Background Slider -->
            <div class="bg-slider">
                <div class="bg-slide active"></div>
                <div class="bg-slide"></div>
                <div class="bg-slide"></div>
                <div class="bg-slide"></div>
                <div class="bg-slide"></div>
            </div>
            <div class="bg-overlay"></div>

            <div class="login-container">
                <div class="login-box">
                    <div class="logo-section">
                        <div class="logo-icon">
                            <i class="fas fa-umbrella-beach"></i>
                        </div>
                        <h1>Ocean View Resort</h1>
                        <p>Sign in to your account</p>
                    </div>

                    <!-- Role Tabs -->
                    <div class="role-tabs">
                        <div class="role-tab <%= " staff".equalsIgnoreCase(roleParam) ? "active" : "" %>"
                            data-role="staff">
                            <i class="fas fa-user-tie"></i>Staff
                        </div>
                        <div class="role-tab <%= " admin".equalsIgnoreCase(roleParam) ? "active" : "" %>"
                            data-role="admin">
                            <i class="fas fa-user-shield"></i>Admin
                        </div>
                    </div>

                    <form action="${pageContext.request.contextPath}/login" method="post" id="loginForm">
                        <input type="hidden" name="selectedRole" id="selectedRole" value="<%= roleParam %>">

                        <div class="form-group">
                            <label for="username">Username</label>
                            <div class="input-wrapper">
                                <i class="fas fa-user"></i>
                                <input type="text" id="username" name="username" placeholder="Enter your username"
                                    value="<%= usernameValue %>" required>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="password">Password</label>
                            <div class="input-wrapper">
                                <i class="fas fa-lock"></i>
                                <input type="password" id="password" name="password" placeholder="Enter your password"
                                    required>
                                <span class="password-toggle" onclick="togglePassword()">
                                    <i class="fas fa-eye" id="toggleIcon"></i>
                                </span>
                            </div>
                        </div>

                        <button type="submit" class="login-btn">
                            <i class="fas fa-sign-in-alt"></i>
                            Sign In
                        </button>
                    </form>

                    <div class="back-link">
                        <a href="${pageContext.request.contextPath}/home.jsp">
                            <i class="fas fa-arrow-left"></i>Back to Home
                        </a>
                    </div>
                </div>
            </div>

            <script>
                // Background slider
                const slides = document.querySelectorAll('.bg-slide');
                let currentSlide = 0;

                function nextSlide() {
                    slides[currentSlide].classList.remove('active');
                    currentSlide = (currentSlide + 1) % slides.length;
                    slides[currentSlide].classList.add('active');
                }

                setInterval(nextSlide, 3000);

                // Role tab switching
                const roleTabs = document.querySelectorAll('.role-tab');
                const selectedRoleInput = document.getElementById('selectedRole');

                roleTabs.forEach(tab => {
                    tab.addEventListener('click', () => {
                        roleTabs.forEach(t => t.classList.remove('active'));
                        tab.classList.add('active');
                        selectedRoleInput.value = tab.dataset.role;
                    });
                });

                // Password toggle
                function togglePassword() {
                    const passwordInput = document.getElementById('password');
                    const toggleIcon = document.getElementById('toggleIcon');

                    if (passwordInput.type === 'password') {
                        passwordInput.type = 'text';
                        toggleIcon.classList.remove('fa-eye');
                        toggleIcon.classList.add('fa-eye-slash');
                    } else {
                        passwordInput.type = 'password';
                        toggleIcon.classList.remove('fa-eye-slash');
                        toggleIcon.classList.add('fa-eye');
                    }
                }

    // Show error message if exists
    <% if (errorMessage != null) { %>
                    Swal.fire({
                        icon: 'error',
                        title: '<i class="fas fa-exclamation-circle"></i> Login Failed!',
                        html: '<strong style="color: #dc3545;"><%= errorMessage.replace("'", "\\'") %></strong><br><br><small style="color: #666;">Please check your credentials and try again.</small>',
                        confirmButtonColor: '#008080',
                        confirmButtonText: 'Try Again',
                        showClass: {
                            popup: 'animate__animated animate__shakeX'
                        }
                    });
    <% } %>
            </script>
    </body>

    </html>