package com.oceanview.filter;

import com.oceanview.model.User;
import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * Authentication Filter - Protects admin and staff pages
 * 
 * @author Ocean View Resort Development Team
 */
@WebFilter(filterName = "AuthFilter", urlPatterns = { "/admin/*", "/staff/*", "/reservation/*", "/room/*", "/guest/*",
        "/bill/*", "/user/*" })
public class AuthFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // Initialization if needed
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        HttpSession session = httpRequest.getSession(false);

        String requestURI = httpRequest.getRequestURI();
        String contextPath = httpRequest.getContextPath();

        // Check if user is logged in
        boolean isLoggedIn = (session != null && session.getAttribute("user") != null);

        if (!isLoggedIn) {
            // Redirect to login page
            httpResponse.sendRedirect(contextPath + "/login");
            return;
        }

        User user = (User) session.getAttribute("user");

        // Check role-based access
        if (requestURI.startsWith(contextPath + "/admin/")) {
            // Only admins can access admin pages
            if (user.getRole() != User.UserRole.ADMIN) {
                httpResponse.sendRedirect(contextPath + "/staff/dashboard");
                return;
            }
        }

        // Continue with the request
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
        // Cleanup if needed
    }
}
