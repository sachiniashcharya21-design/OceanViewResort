package com.oceanview.servlet;

import com.oceanview.dao.UserDAO;
import com.oceanview.model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.SQLException;

/**
 * Login Servlet - Handles user authentication
 * 
 * @author Ocean View Resort Development Team
 */
@WebServlet(name = "LoginServlet", urlPatterns = { "/login", "/LoginServlet" })
public class LoginServlet extends HttpServlet {

    private UserDAO userDAO;

    @Override
    public void init() throws ServletException {
        try {
            userDAO = new UserDAO();
        } catch (SQLException e) {
            throw new ServletException("Cannot initialize UserDAO", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session != null && session.getAttribute("user") != null) {
            User user = (User) session.getAttribute("user");
            if (user.isAdmin()) {
                response.sendRedirect(request.getContextPath() + "/admin/admin-dashboard.jsp");
            } else {
                response.sendRedirect(request.getContextPath() + "/staff/staff-dashboard.jsp");
            }
            return;
        }
        request.getRequestDispatcher("/login.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String selectedRole = request.getParameter("selectedRole");

        // Validate input
        if (username == null || username.trim().isEmpty() ||
                password == null || password.trim().isEmpty()) {
            request.setAttribute("error", "Please enter both username and password.");
            request.setAttribute("selectedRole", selectedRole);
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        try {
            User user = userDAO.getUserByUsername(username.trim());

            if (user != null) {
                // Check password
                String storedPassword = user.getPassword() != null ? user.getPassword() : "";
                String hashedInput = sha256(password);
                if (!storedPassword.equals(password) && !storedPassword.equals(hashedInput)) {
                    request.setAttribute("error", "Invalid username or password.");
                    request.setAttribute("username", username);
                    request.setAttribute("selectedRole", selectedRole);
                    request.getRequestDispatcher("/login.jsp").forward(request, response);
                    return;
                }

                // Check if user is active
                if (user.getStatus() != User.UserStatus.ACTIVE) {
                    request.setAttribute("error", "Your account is inactive. Please contact administrator.");
                    request.getRequestDispatcher("/login.jsp").forward(request, response);
                    return;
                }

                // Check if selected role matches user role
                boolean roleMatch = false;
                if ("admin".equalsIgnoreCase(selectedRole) && user.getRole() == User.UserRole.ADMIN) {
                    roleMatch = true;
                } else if ("staff".equalsIgnoreCase(selectedRole) && user.getRole() == User.UserRole.STAFF) {
                    roleMatch = true;
                }

                if (!roleMatch) {
                    request.setAttribute("error", "Access denied. You do not have " + selectedRole + " privileges.");
                    request.setAttribute("username", username);
                    request.setAttribute("selectedRole", selectedRole);
                    request.getRequestDispatcher("/login.jsp").forward(request, response);
                    return;
                }

                // Create session
                HttpSession session = request.getSession();
                session.setAttribute("user", user);
                session.setAttribute("userId", user.getUserId());
                session.setAttribute("username", user.getUsername());
                session.setAttribute("fullName", user.getFullName());
                session.setAttribute("userRole", user.getRole().toString());
                session.setAttribute("role", user.getRole().toString());

                // Log activity
                userDAO.logActivity(user.getUserId(), "LOGIN", "User logged in successfully");

                // Store success info for SweetAlert
                session.setAttribute("loginSuccess", true);
                session.setAttribute("welcomeMessage", "Welcome back, " + user.getFullName() + "!");

                // Redirect based on role to JSP dashboards
                if (user.isAdmin()) {
                    response.sendRedirect(request.getContextPath() + "/admin/admin-dashboard.jsp");
                } else {
                    response.sendRedirect(request.getContextPath() + "/staff/staff-dashboard.jsp");
                }
            } else {
                request.setAttribute("error", "Username not found. Please check your credentials.");
                request.setAttribute("username", username);
                request.setAttribute("selectedRole", selectedRole);
                request.getRequestDispatcher("/login.jsp").forward(request, response);
            }
        } catch (Exception e) {
            request.setAttribute("error", "System error: " + e.getMessage());
            request.getRequestDispatcher("/login.jsp").forward(request, response);
        }
    }

    private String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            return value;
        }
    }
}
