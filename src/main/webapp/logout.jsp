<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Invalidate the session
    HttpSession userSession = request.getSession(false);
    if (userSession != null) {
        userSession.invalidate();
    }
    // Redirect to home page
    response.sendRedirect("home.jsp");
%>
