package com.oceanview.servlet;

import com.oceanview.dao.*;
import com.oceanview.model.*;
import com.oceanview.model.Room.RoomStatus;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Staff Dashboard Servlet - Handles staff dashboard display
 * 
 * @author Ocean View Resort Development Team
 */
@WebServlet(name = "StaffDashboardServlet", urlPatterns = { "/staff/dashboard" })
public class StaffDashboardServlet extends HttpServlet {

    private RoomDAO roomDAO;
    private ReservationDAO reservationDAO;

    @Override
    public void init() throws ServletException {
        try {
            roomDAO = new RoomDAO();
            reservationDAO = new ReservationDAO();
        } catch (SQLException e) {
            throw new ServletException("Cannot initialize DAOs", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // Get dashboard statistics
            int availableRooms = roomDAO.getRoomCountByStatus(RoomStatus.AVAILABLE);
            int occupiedRooms = roomDAO.getRoomCountByStatus(RoomStatus.OCCUPIED);
            int todayCheckIns = reservationDAO.getTodayCheckIns().size();
            int todayCheckOuts = reservationDAO.getTodayCheckOuts().size();

            // Get today's check-ins and check-outs
            List<Reservation> todayCheckInsList = reservationDAO.getTodayCheckIns();
            List<Reservation> todayCheckOutsList = reservationDAO.getTodayCheckOuts();

            // Set attributes
            request.setAttribute("availableRooms", availableRooms);
            request.setAttribute("occupiedRooms", occupiedRooms);
            request.setAttribute("todayCheckIns", todayCheckIns);
            request.setAttribute("todayCheckOuts", todayCheckOuts);
            request.setAttribute("todayCheckInsList", todayCheckInsList);
            request.setAttribute("todayCheckOutsList", todayCheckOutsList);

            request.getRequestDispatcher("/WEB-INF/views/staff/dashboard.jsp").forward(request, response);

        } catch (Exception e) {
            request.setAttribute("error", "Error loading dashboard: " + e.getMessage());
            request.getRequestDispatcher("/WEB-INF/views/staff/dashboard.jsp").forward(request, response);
        }
    }
}
