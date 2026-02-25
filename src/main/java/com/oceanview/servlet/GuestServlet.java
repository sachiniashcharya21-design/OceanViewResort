package com.oceanview.servlet;

import com.oceanview.dao.*;
import com.oceanview.model.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Guest Servlet - Handles all guest operations
 * 
 * @author Ocean View Resort Development Team
 */
@WebServlet(name = "GuestServlet", urlPatterns = { "/guest/*" })
public class GuestServlet extends HttpServlet {

    private GuestDAO guestDAO;
    private ReservationDAO reservationDAO;
    private UserDAO userDAO;

    @Override
    public void init() throws ServletException {
        try {
            guestDAO = new GuestDAO();
            reservationDAO = new ReservationDAO();
            userDAO = new UserDAO();
        } catch (SQLException e) {
            throw new ServletException("Cannot initialize DAOs", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = (User) request.getSession().getAttribute("user");
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String pathInfo = request.getPathInfo();
        if (pathInfo == null)
            pathInfo = "/list";

        switch (pathInfo) {
            case "/list" -> listGuests(request, response);
            case "/view" -> viewGuest(request, response);
            case "/search" -> searchGuests(request, response);
            case "/history" -> guestHistory(request, response);
            case "/edit" -> showEditForm(request, response);
            case "/add" -> showAddForm(request, response);
            default -> listGuests(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = (User) request.getSession().getAttribute("user");
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String pathInfo = request.getPathInfo();
        if (pathInfo == null)
            pathInfo = "/";

        switch (pathInfo) {
            case "/update" -> updateGuest(request, response);
            case "/register" -> registerGuest(request, response);
            case "/delete" -> deleteGuest(request, response);
            default -> response.sendRedirect(request.getContextPath() + "/guest/list");
        }
    }

    private void listGuests(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        List<Guest> guests = guestDAO.getAllGuests();
        request.setAttribute("guests", guests);
        request.setAttribute("pageTitle", "All Guests");
        request.getRequestDispatcher("/WEB-INF/views/guest/list.jsp").forward(request, response);
    }

    private void viewGuest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        int guestId = Integer.parseInt(request.getParameter("id"));
        Guest guest = guestDAO.getGuestById(guestId);

        if (guest != null) {
            List<Reservation> reservations = reservationDAO.getReservationsByGuestId(guestId);
            request.setAttribute("guest", guest);
            request.setAttribute("reservations", reservations);
            request.getRequestDispatcher("/WEB-INF/views/guest/view.jsp").forward(request, response);
        } else {
            request.getSession().setAttribute("error", "Guest not found");
            response.sendRedirect(request.getContextPath() + "/guest/list");
        }
    }

    private void searchGuests(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String searchTerm = request.getParameter("q");
        List<Guest> guests;

        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            guests = guestDAO.searchGuestsByName(searchTerm);
            request.setAttribute("searchTerm", searchTerm);
        } else {
            guests = guestDAO.getAllGuests();
        }

        request.setAttribute("guests", guests);
        request.setAttribute("pageTitle", "Search Results");
        request.getRequestDispatcher("/WEB-INF/views/guest/list.jsp").forward(request, response);
    }

    private void guestHistory(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        int guestId = Integer.parseInt(request.getParameter("id"));
        Guest guest = guestDAO.getGuestById(guestId);
        List<Reservation> reservations = reservationDAO.getReservationsByGuestId(guestId);

        request.setAttribute("guest", guest);
        request.setAttribute("reservations", reservations);
        request.getRequestDispatcher("/WEB-INF/views/guest/history.jsp").forward(request, response);
    }

    private void showEditForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        int guestId = Integer.parseInt(request.getParameter("id"));
        Guest guest = guestDAO.getGuestById(guestId);

        request.setAttribute("guest", guest);
        request.getRequestDispatcher("/WEB-INF/views/guest/edit.jsp").forward(request, response);
    }

    private void showAddForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/views/guest/add.jsp").forward(request, response);
    }

    private void registerGuest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            Guest guest = new Guest();
            guest.setFullName(request.getParameter("fullName"));
            guest.setPhone(request.getParameter("phone"));
            guest.setEmail(request.getParameter("email"));
            guest.setAddress(request.getParameter("address"));
            guest.setNicPassport(request.getParameter("nicPassport"));
            guest.setNationality(request.getParameter("nationality"));

            int guestId = guestDAO.addGuest(guest);
            if (guestId > 0) {
                userDAO.logActivity(currentUser.getUserId(), "REGISTER_GUEST",
                        "Registered new guest: " + guest.getFullName());
                request.getSession().setAttribute("success", "Guest registered successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to register guest");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/guest/list");
    }

    private void deleteGuest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            if (currentUser.getRole() != User.UserRole.ADMIN) {
                request.getSession().setAttribute("error", "Only admin can delete guests");
                response.sendRedirect(request.getContextPath() + "/guest/list");
                return;
            }

            int guestId = Integer.parseInt(request.getParameter("id"));
            Guest guest = guestDAO.getGuestById(guestId);

            if (guestDAO.deleteGuest(guestId)) {
                userDAO.logActivity(currentUser.getUserId(), "DELETE_GUEST",
                        "Deleted guest: " + guest.getFullName());
                request.getSession().setAttribute("success", "Guest deleted successfully!");
            } else {
                request.getSession().setAttribute("error", "Cannot delete guest with existing reservations");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/guest/list");
    }

    private void updateGuest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            int guestId = Integer.parseInt(request.getParameter("guestId"));
            Guest guest = guestDAO.getGuestById(guestId);

            guest.setFullName(request.getParameter("fullName"));
            guest.setPhone(request.getParameter("phone"));
            guest.setEmail(request.getParameter("email"));
            guest.setAddress(request.getParameter("address"));
            guest.setNicPassport(request.getParameter("nicPassport"));
            guest.setNationality(request.getParameter("nationality"));

            if (guestDAO.updateGuest(guest)) {
                userDAO.logActivity(currentUser.getUserId(), "UPDATE_GUEST",
                        "Updated guest " + guest.getFullName());
                request.getSession().setAttribute("success", "Guest updated successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to update guest");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/guest/list");
    }
}
