package com.oceanview.servlet;

import com.oceanview.dao.*;
import com.oceanview.model.*;

import com.oceanview.model.Reservation.ReservationStatus;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.Date;
import java.sql.SQLException;
import java.util.List;

/**
 * Reservation Servlet - Handles all reservation operations
 * 
 * @author Ocean View Resort Development Team
 */
@WebServlet(name = "ReservationServlet", urlPatterns = { "/reservation/*" })
public class ReservationServlet extends HttpServlet {

    private ReservationDAO reservationDAO;
    private RoomDAO roomDAO;
    private GuestDAO guestDAO;
    private UserDAO userDAO;
    private BillDAO billDAO;

    @Override
    public void init() throws ServletException {
        try {
            reservationDAO = new ReservationDAO();
            roomDAO = new RoomDAO();
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
        User user = (User) request.getSession().getAttribute("user");
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String pathInfo = request.getPathInfo();
        if (pathInfo == null)
            pathInfo = "/list";

        switch (pathInfo) {
            case "/list" -> listReservations(request, response);
            case "/add" -> showAddForm(request, response);
            case "/view" -> viewReservation(request, response);
            case "/search" -> searchReservation(request, response);
            case "/today-checkins" -> todayCheckIns(request, response);
            case "/today-checkouts" -> todayCheckOuts(request, response);
            default -> listReservations(request, response);
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
            case "/add" -> addReservation(request, response);
            case "/checkin" -> checkIn(request, response);
            case "/checkout" -> checkOut(request, response);
            case "/cancel" -> cancelReservation(request, response);
            default -> response.sendRedirect(request.getContextPath() + "/reservation/list");
        }
    }

    private void listReservations(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        List<Reservation> reservations = reservationDAO.getAllReservations();
        request.setAttribute("reservations", reservations);
        request.setAttribute("pageTitle", "All Reservations");
        request.getRequestDispatcher("/WEB-INF/views/reservation/list.jsp").forward(request, response);
    }

    private void showAddForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        List<RoomType> roomTypes = roomDAO.getAllRoomTypes();
        List<Room> availableRooms = roomDAO.getAvailableRooms();
        request.setAttribute("roomTypes", roomTypes);
        request.setAttribute("availableRooms", availableRooms);
        request.getRequestDispatcher("/WEB-INF/views/reservation/add.jsp").forward(request, response);
    }

    private void viewReservation(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String resNumber = request.getParameter("id");
        if (resNumber != null) {
            Reservation reservation = reservationDAO.getReservationByNumber(resNumber.toUpperCase());
            if (reservation != null) {
                request.setAttribute("reservation", reservation);
                request.getRequestDispatcher("/WEB-INF/views/reservation/view.jsp").forward(request, response);
                return;
            }
        }
        request.setAttribute("error", "Reservation not found");
        listReservations(request, response);
    }

    private void searchReservation(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String searchTerm = request.getParameter("q");
        List<Reservation> reservations;

        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            if (searchTerm.toUpperCase().startsWith("RES")) {
                Reservation res = reservationDAO.getReservationByNumber(searchTerm.toUpperCase());
                reservations = res != null ? List.of(res) : List.of();
            } else {
                reservations = reservationDAO.searchReservationsByGuestName(searchTerm);
            }
            request.setAttribute("searchTerm", searchTerm);
        } else {
            reservations = reservationDAO.getAllReservations();
        }

        request.setAttribute("reservations", reservations);
        request.setAttribute("pageTitle", "Search Results");
        request.getRequestDispatcher("/WEB-INF/views/reservation/list.jsp").forward(request, response);
    }

    private void todayCheckIns(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        List<Reservation> reservations = reservationDAO.getTodayCheckIns();
        request.setAttribute("reservations", reservations);
        request.setAttribute("pageTitle", "Today's Check-ins");
        request.getRequestDispatcher("/WEB-INF/views/reservation/list.jsp").forward(request, response);
    }

    private void todayCheckOuts(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        List<Reservation> reservations = reservationDAO.getTodayCheckOuts();
        request.setAttribute("reservations", reservations);
        request.setAttribute("pageTitle", "Today's Check-outs");
        request.getRequestDispatcher("/WEB-INF/views/reservation/list.jsp").forward(request, response);
    }

    private void addReservation(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            // Get guest info
            String guestName = request.getParameter("guestName");
            String phone = request.getParameter("phone");
            String email = request.getParameter("email");
            String address = request.getParameter("address");
            String nicPassport = request.getParameter("nicPassport");

            // Check existing guest or create new
            Guest guest = guestDAO.getGuestByPhone(phone);
            if (guest == null) {
                guest = new Guest();
                guest.setFullName(guestName);
                guest.setPhone(phone);
                guest.setEmail(email);
                guest.setAddress(address);
                guest.setNicPassport(nicPassport);
                int guestId = guestDAO.addGuest(guest);
                if (guestId < 0) {
                    request.setAttribute("error", "Failed to register guest");
                    showAddForm(request, response);
                    return;
                }
            }

            // Get reservation details
            int roomId = Integer.parseInt(request.getParameter("roomId"));
            Date checkInDate = Date.valueOf(request.getParameter("checkInDate"));
            Date checkOutDate = Date.valueOf(request.getParameter("checkOutDate"));
            int numberOfGuests = Integer.parseInt(request.getParameter("numberOfGuests"));
            String specialRequests = request.getParameter("specialRequests");

            // Create reservation
            Reservation reservation = new Reservation();
            reservation.setReservationNumber(reservationDAO.generateReservationNumber());
            reservation.setGuestId(guest.getGuestId());
            reservation.setRoomId(roomId);
            reservation.setCheckInDate(checkInDate);
            reservation.setCheckOutDate(checkOutDate);
            reservation.setNumberOfGuests(numberOfGuests);
            reservation.setSpecialRequests(specialRequests);
            reservation.setCreatedBy(currentUser.getUserId());
            reservation.setStatus(ReservationStatus.CONFIRMED);

            if (reservationDAO.addReservation(reservation)) {

                userDAO.logActivity(currentUser.getUserId(), "CREATE_RESERVATION",
                        "Created reservation " + reservation.getReservationNumber());
                request.getSession().setAttribute("success",
                        "Reservation created successfully! Number: " + reservation.getReservationNumber());
                response.sendRedirect(request.getContextPath() + "/reservation/list");
            } else {
                request.setAttribute("error", "Failed to create reservation");
                showAddForm(request, response);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Error: " + e.getMessage());
            showAddForm(request, response);
        }
    }

    private void checkIn(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String resNumber = request.getParameter("id");
        User currentUser = (User) request.getSession().getAttribute("user");

        Reservation reservation = reservationDAO.getReservationByNumber(resNumber);
        if (reservation != null && reservation.getStatus() == ReservationStatus.CONFIRMED) {
            if (reservationDAO.checkIn(reservation.getReservationId())) {
                userDAO.logActivity(currentUser.getUserId(), "CHECK_IN",
                        "Checked in reservation " + resNumber);
                request.getSession().setAttribute("success", "Guest checked in successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to check in guest");
            }
        } else {
            request.getSession().setAttribute("error", "Invalid reservation or status");
        }
        response.sendRedirect(request.getContextPath() + "/reservation/list");
    }

    private void checkOut(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String resNumber = request.getParameter("id");
        User currentUser = (User) request.getSession().getAttribute("user");

        Reservation reservation = reservationDAO.getReservationByNumber(resNumber);
        if (reservation != null && reservation.getStatus() == ReservationStatus.CHECKED_IN) {
            // Generate bill first
            Bill bill = billDAO.generateBill(reservation.getReservationId(), currentUser.getUserId());

            if (reservationDAO.checkOut(reservation.getReservationId())) {
                userDAO.logActivity(currentUser.getUserId(), "CHECK_OUT",
                        "Checked out reservation " + resNumber);
                if (bill != null) {
                    request.getSession().setAttribute("success",
                            "Guest checked out. Bill generated: " + bill.getBillNumber());
                } else {
                    request.getSession().setAttribute("success", "Guest checked out successfully!");
                }
            } else {
                request.getSession().setAttribute("error", "Failed to check out guest");
            }
        } else {
            request.getSession().setAttribute("error", "Invalid reservation or status");
        }
        response.sendRedirect(request.getContextPath() + "/reservation/list");
    }

    private void cancelReservation(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String resNumber = request.getParameter("id");
        User currentUser = (User) request.getSession().getAttribute("user");

        Reservation reservation = reservationDAO.getReservationByNumber(resNumber);
        if (reservation != null && reservation.getStatus() == ReservationStatus.CONFIRMED) {
            if (reservationDAO.cancelReservation(reservation.getReservationId())) {
                userDAO.logActivity(currentUser.getUserId(), "CANCEL_RESERVATION",
                        "Cancelled reservation " + resNumber);
                request.getSession().setAttribute("success", "Reservation cancelled successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to cancel reservation");
            }
        } else {
            request.getSession().setAttribute("error", "Cannot cancel this reservation");
        }
        response.sendRedirect(request.getContextPath() + "/reservation/list");
    }
}
