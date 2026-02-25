package com.oceanview.servlet;

import com.oceanview.dao.UserDAO;
import com.oceanview.model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Logout Servlet - Handles user logout
 * 
 * @author Ocean View Resort Development Team
 */
@WebServlet(name = "LogoutServlet", urlPatterns = { "/logout" })
public class LogoutServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session != null) {
            User user = (User) session.getAttribute("user");

            // Log activity
            if (user != null) {
                try {
                    UserDAO userDAO = new UserDAO();
                    userDAO.logActivity(user.getUserId(), "LOGOUT", "User logged out");
                } catch (SQLException e) {
                    // Continue with logout even if logging fails
                }
            }

            // Invalidate session
            session.invalidate();
        }

        // Redirect to home page
        response.sendRedirect(request.getContextPath() + "/home.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}
