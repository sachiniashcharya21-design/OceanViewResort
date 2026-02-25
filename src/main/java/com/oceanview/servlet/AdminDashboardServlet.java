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
 * Admin Dashboard Servlet - Handles admin dashboard display
 * 
 * @author Ocean View Resort Development Team
 */
@WebServlet(name = "AdminDashboardServlet", urlPatterns = { "/admin/dashboard" })
public class AdminDashboardServlet extends HttpServlet {

    private RoomDAO roomDAO;
    private ReservationDAO reservationDAO;
    private GuestDAO guestDAO;
    private UserDAO userDAO;
    private BillDAO billDAO;

    @Override
    public void init() throws ServletException {
        try {
            roomDAO = new RoomDAO();
            reservationDAO = new ReservationDAO();
            guestDAO = new GuestDAO();
            userDAO = new UserDAO();
            billDAO = new BillDAO();
        } catch (SQLException e) {
            throw new ServletException("Cannot initialize DAOs", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // Get dashboard statistics
            int totalRooms = roomDAO.getAllRooms().size();
            int availableRooms = roomDAO.getRoomCountByStatus(RoomStatus.AVAILABLE);
            int occupiedRooms = roomDAO.getRoomCountByStatus(RoomStatus.OCCUPIED);
            int totalReservations = reservationDAO.getAllReservations().size();
            int todayCheckIns = reservationDAO.getTodayCheckIns().size();
            int todayCheckOuts = reservationDAO.getTodayCheckOuts().size();
            int totalGuests = guestDAO.getAllGuests().size();
            int totalStaff = userDAO.getAllStaff().size();

            // Get recent reservations
            List<Reservation> recentReservations = reservationDAO.getAllReservations();
            if (recentReservations.size() > 5) {
                recentReservations = recentReservations.subList(0, 5);
            }

            // Get pending bills
            List<Bill> pendingBills = billDAO.getPendingBills();
            if (pendingBills.size() > 5) {
                pendingBills = pendingBills.subList(0, 5);
            }

            // Set attributes
            request.setAttribute("totalRooms", totalRooms);
            request.setAttribute("availableRooms", availableRooms);
            request.setAttribute("occupiedRooms", occupiedRooms);
            request.setAttribute("totalReservations", totalReservations);
            request.setAttribute("todayCheckIns", todayCheckIns);
            request.setAttribute("todayCheckOuts", todayCheckOuts);
            request.setAttribute("totalGuests", totalGuests);
            request.setAttribute("totalStaff", totalStaff);
            request.setAttribute("recentReservations", recentReservations);
            request.setAttribute("pendingBills", pendingBills);

            request.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(request, response);

        } catch (Exception e) {
            request.setAttribute("error", "Error loading dashboard: " + e.getMessage());
            request.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(request, response);
        }
    }
}
