package com.oceanview.servlet;

import com.oceanview.dao.*;
import com.oceanview.model.*;
import com.oceanview.model.User.UserRole;
import com.oceanview.model.User.UserStatus;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.Date;
import java.sql.SQLException;
import java.util.List;

/**
 * User Servlet - Handles staff management (Admin only)
 * 
 * @author Ocean View Resort Development Team
 */
@WebServlet(name = "UserServlet", urlPatterns = { "/user/*" })
public class UserServlet extends HttpServlet {

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

        // Admin only access
        User currentUser = (User) request.getSession().getAttribute("user");
        if (currentUser == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        if (currentUser.getRole() != UserRole.ADMIN) {
            response.sendRedirect(request.getContextPath() + "/staff/dashboard");
            return;
        }

        String pathInfo = request.getPathInfo();
        if (pathInfo == null)
            pathInfo = "/list";

        switch (pathInfo) {
            case "/list" -> listStaff(request, response);
            case "/add" -> showAddForm(request, response);
            case "/edit" -> showEditForm(request, response);
            case "/profile" -> showProfile(request, response);
            case "/change-password" -> showChangePassword(request, response);
            default -> listStaff(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        User currentUser = (User) request.getSession().getAttribute("user");
        if (currentUser == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String pathInfo = request.getPathInfo();
        if (pathInfo == null)
            pathInfo = "/";

        // Password change allowed for all users
        if (pathInfo.equals("/change-password")) {
            changePassword(request, response);
            return;
        }

        // Admin only for staff management
        if (currentUser.getRole() != UserRole.ADMIN) {
            response.sendRedirect(request.getContextPath() + "/staff/dashboard");
            return;
        }

        switch (pathInfo) {
            case "/add" -> addStaff(request, response);
            case "/update" -> updateStaff(request, response);
            case "/deactivate" -> deactivateStaff(request, response);
            case "/activate" -> activateStaff(request, response);
            case "/reset-password" -> resetPassword(request, response);
            default -> response.sendRedirect(request.getContextPath() + "/user/list");
        }
    }

    private void listStaff(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        List<User> staff = userDAO.getAllStaff();
        List<User> admins = userDAO.getAllUsers().stream()
                .filter(u -> u.getRole() == UserRole.ADMIN)
                .toList();

        request.setAttribute("staff", staff);
        request.setAttribute("admins", admins);
        request.getRequestDispatcher("/WEB-INF/views/user/list.jsp").forward(request, response);
    }

    private void showAddForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/views/user/add.jsp").forward(request, response);
    }

    private void showEditForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        int userId = Integer.parseInt(request.getParameter("id"));
        User user = userDAO.getUserById(userId);
        request.setAttribute("editUser", user);
        request.getRequestDispatcher("/WEB-INF/views/user/edit.jsp").forward(request, response);
    }

    private void showProfile(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/views/user/profile.jsp").forward(request, response);
    }

    private void showChangePassword(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/views/user/change-password.jsp").forward(request, response);
    }

    private void addStaff(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            String username = request.getParameter("username");
            String password = request.getParameter("password");
            String fullName = request.getParameter("fullName");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String address = request.getParameter("address");
            String roleStr = request.getParameter("role");
            String hireDateStr = request.getParameter("hireDate");

            User newUser = new User();
            newUser.setUsername(username);
            newUser.setPassword(password);
            newUser.setFullName(fullName);
            newUser.setEmail(email);
            newUser.setPhone(phone);
            newUser.setAddress(address);
            newUser.setRole(UserRole.valueOf(roleStr));
            newUser.setStatus(UserStatus.ACTIVE);
            if (hireDateStr != null && !hireDateStr.isEmpty()) {
                newUser.setHireDate(Date.valueOf(hireDateStr));
            }

            if (userDAO.addUser(newUser)) {
                userDAO.logActivity(currentUser.getUserId(), "ADD_STAFF",
                        "Added new staff member: " + username);
                request.getSession().setAttribute("success", "Staff member added successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to add staff member");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/user/list");
    }

    private void updateStaff(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            int userId = Integer.parseInt(request.getParameter("userId"));
            User user = userDAO.getUserById(userId);

            user.setFullName(request.getParameter("fullName"));
            user.setEmail(request.getParameter("email"));
            user.setPhone(request.getParameter("phone"));
            user.setAddress(request.getParameter("address"));

            if (userDAO.updateUser(user)) {
                userDAO.logActivity(currentUser.getUserId(), "UPDATE_STAFF",
                        "Updated staff member: " + user.getUsername());
                request.getSession().setAttribute("success", "Staff updated successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to update staff");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/user/list");
    }

    private void deactivateStaff(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");
            int userId = Integer.parseInt(request.getParameter("userId"));

            // Cannot deactivate self
            if (userId == currentUser.getUserId()) {
                request.getSession().setAttribute("error", "Cannot deactivate your own account");
            } else if (userDAO.deactivateUser(userId)) {
                userDAO.logActivity(currentUser.getUserId(), "DEACTIVATE_STAFF",
                        "Deactivated user ID: " + userId);
                request.getSession().setAttribute("success", "Staff deactivated successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to deactivate staff");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/user/list");
    }

    private void activateStaff(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");
            int userId = Integer.parseInt(request.getParameter("userId"));

            if (userDAO.activateUser(userId)) {
                userDAO.logActivity(currentUser.getUserId(), "ACTIVATE_STAFF",
                        "Activated user ID: " + userId);
                request.getSession().setAttribute("success", "Staff activated successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to activate staff");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/user/list");
    }

    private void resetPassword(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");
            int userId = Integer.parseInt(request.getParameter("userId"));
            String newPassword = request.getParameter("newPassword");

            if (userDAO.changePassword(userId, newPassword)) {
                User user = userDAO.getUserById(userId);
                userDAO.logActivity(currentUser.getUserId(), "RESET_PASSWORD",
                        "Reset password for: " + user.getUsername());
                request.getSession().setAttribute("success", "Password reset successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to reset password");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/user/list");
    }

    private void changePassword(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            String currentPassword = request.getParameter("currentPassword");
            String newPassword = request.getParameter("newPassword");
            String confirmPassword = request.getParameter("confirmPassword");

            if (!currentPassword.equals(currentUser.getPassword())) {
                request.getSession().setAttribute("error", "Current password is incorrect");
            } else if (!newPassword.equals(confirmPassword)) {
                request.getSession().setAttribute("error", "New passwords do not match");
            } else if (newPassword.length() < 6) {
                request.getSession().setAttribute("error", "Password must be at least 6 characters");
            } else if (userDAO.changePassword(currentUser.getUserId(), newPassword)) {
                currentUser.setPassword(newPassword);
                userDAO.logActivity(currentUser.getUserId(), "CHANGE_PASSWORD", "Changed own password");
                request.getSession().setAttribute("success", "Password changed successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to change password");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }

        User currentUser = (User) request.getSession().getAttribute("user");
        if (currentUser.getRole() == UserRole.ADMIN) {
            response.sendRedirect(request.getContextPath() + "/admin/dashboard");
        } else {
            response.sendRedirect(request.getContextPath() + "/staff/dashboard");
        }
    }
}
