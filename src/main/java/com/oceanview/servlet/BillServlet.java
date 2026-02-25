package com.oceanview.servlet;

import com.oceanview.dao.*;
import com.oceanview.model.*;
import com.oceanview.model.Bill.PaymentMethod;
import com.oceanview.model.Bill.PaymentStatus;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;

/**
 * Bill Servlet - Handles all billing operations
 * 
 * @author Ocean View Resort Development Team
 */
@WebServlet(name = "BillServlet", urlPatterns = { "/bill/*" })
public class BillServlet extends HttpServlet {

    private BillDAO billDAO;
    private ReservationDAO reservationDAO;
    private UserDAO userDAO;

    @Override
    public void init() throws ServletException {
        try {
            billDAO = new BillDAO();
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
            case "/list" -> listBills(request, response);
            case "/pending" -> listPendingBills(request, response);
            case "/view" -> viewBill(request, response);
            case "/generate" -> showGenerateForm(request, response);
            case "/payment" -> showPaymentForm(request, response);
            case "/discount" -> showDiscountForm(request, response);
            case "/search" -> searchBills(request, response);
            default -> listBills(request, response);
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
            case "/generate" -> generateBill(request, response);
            case "/pay" -> processPayment(request, response);
            case "/processPayment" -> processPayment(request, response);
            case "/discount" -> applyDiscount(request, response);
            case "/applyDiscount" -> applyDiscount(request, response);
            default -> response.sendRedirect(request.getContextPath() + "/bill/list");
        }
    }

    private void listBills(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        List<Bill> bills = billDAO.getAllBills();
        request.setAttribute("bills", bills);
        request.setAttribute("pageTitle", "All Bills");
        request.getRequestDispatcher("/WEB-INF/views/bill/list.jsp").forward(request, response);
    }

    private void listPendingBills(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        List<Bill> bills = billDAO.getPendingBills();
        request.setAttribute("bills", bills);
        request.setAttribute("pageTitle", "Pending Bills");
        request.getRequestDispatcher("/WEB-INF/views/bill/list.jsp").forward(request, response);
    }

    private void viewBill(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String billNumber = request.getParameter("id");
        Bill bill = billDAO.getBillByNumber(billNumber);

        if (bill != null) {
            request.setAttribute("bill", bill);
            request.getRequestDispatcher("/WEB-INF/views/bill/view.jsp").forward(request, response);
        } else {
            request.getSession().setAttribute("error", "Bill not found");
            response.sendRedirect(request.getContextPath() + "/bill/list");
        }
    }

    private void showGenerateForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/views/bill/generate.jsp").forward(request, response);
    }

    private void showPaymentForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        Bill bill = resolveBill(request);
        if (bill == null) {
            request.getSession().setAttribute("error", "Bill not found");
            response.sendRedirect(request.getContextPath() + "/bill/list");
            return;
        }
        request.setAttribute("bill", bill);
        request.getRequestDispatcher("/WEB-INF/views/bill/payment.jsp").forward(request, response);
    }

    private void showDiscountForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        Bill bill = resolveBill(request);
        if (bill == null) {
            request.getSession().setAttribute("error", "Bill not found");
            response.sendRedirect(request.getContextPath() + "/bill/list");
            return;
        }
        request.setAttribute("bill", bill);
        request.getRequestDispatcher("/WEB-INF/views/bill/discount.jsp").forward(request, response);
    }

    private void searchBills(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String searchTerm = request.getParameter("q");

        if (searchTerm != null && !searchTerm.trim().isEmpty()) {
            Bill bill = billDAO.getBillByNumber(searchTerm.toUpperCase());
            if (bill != null) {
                request.setAttribute("bills", List.of(bill));
            } else {
                request.setAttribute("bills", List.of());
            }
            request.setAttribute("searchTerm", searchTerm);
        } else {
            request.setAttribute("bills", billDAO.getAllBills());
        }

        request.setAttribute("pageTitle", "Search Results");
        request.getRequestDispatcher("/WEB-INF/views/bill/list.jsp").forward(request, response);
    }

    private void generateBill(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");
            String resNumber = request.getParameter("reservationNumber");

            Reservation reservation = reservationDAO.getReservationByNumber(resNumber.toUpperCase());
            if (reservation != null) {
                Bill bill = billDAO.generateBill(reservation.getReservationId(), currentUser.getUserId());
                if (bill != null) {
                    userDAO.logActivity(currentUser.getUserId(), "GENERATE_BILL",
                            "Generated bill " + bill.getBillNumber());
                    request.getSession().setAttribute("success",
                            "Bill generated successfully! Number: " + bill.getBillNumber());
                    response.sendRedirect(request.getContextPath() + "/bill/view?id=" + bill.getBillNumber());
                    return;
                }
            }
            request.getSession().setAttribute("error", "Failed to generate bill");
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/bill/list");
    }

    private void processPayment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            String billNumber = request.getParameter("billNumber");
            String paymentMethodStr = request.getParameter("paymentMethod");

            Bill bill = resolveBill(request);
            if (bill != null && bill.getPaymentStatus() != PaymentStatus.PAID) {
                PaymentMethod method = PaymentMethod.valueOf(paymentMethodStr);

                if (billDAO.updatePaymentStatus(bill.getBillId(), PaymentStatus.PAID, method)) {
                    userDAO.logActivity(currentUser.getUserId(), "PROCESS_PAYMENT",
                            "Processed payment for bill " + bill.getBillNumber());
                    request.getSession().setAttribute("success", "Payment processed successfully!");
                } else {
                    request.getSession().setAttribute("error", "Failed to process payment");
                }
            } else {
                request.getSession().setAttribute("error", "Bill not found or already paid");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/bill/list");
    }

    private void applyDiscount(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User currentUser = (User) request.getSession().getAttribute("user");

        // Only admin can apply discounts
        if (currentUser.getRole() != User.UserRole.ADMIN) {
            request.getSession().setAttribute("error", "Access denied. Admin only.");
            response.sendRedirect(request.getContextPath() + "/bill/list");
            return;
        }

        try {
            BigDecimal discountInput = new BigDecimal(request.getParameter("discount"));
            Bill bill = resolveBill(request);
            if (bill != null) {
                BigDecimal discountAmount = discountInput;
                // Accept either absolute amount or percentage (0-100)
                if (discountInput.compareTo(BigDecimal.ZERO) >= 0
                        && discountInput.compareTo(BigDecimal.valueOf(100)) <= 0) {
                    discountAmount = bill.getRoomTotal().multiply(discountInput)
                            .divide(BigDecimal.valueOf(100));
                }

                if (billDAO.applyDiscount(bill.getBillId(), discountAmount)) {
                    userDAO.logActivity(currentUser.getUserId(), "APPLY_DISCOUNT",
                            "Applied discount Rs. " + discountAmount + " to bill " + bill.getBillNumber());
                    request.getSession().setAttribute("success", "Discount applied successfully!");
                } else {
                    request.getSession().setAttribute("error", "Failed to apply discount");
                }
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/bill/list");
    }

    private Bill resolveBill(HttpServletRequest request) {
        String billNumber = request.getParameter("billNumber");
        if (billNumber != null && !billNumber.isBlank()) {
            return billDAO.getBillByNumber(billNumber.trim().toUpperCase());
        }

        String idParam = request.getParameter("id");
        if (idParam == null || idParam.isBlank()) {
            idParam = request.getParameter("billId");
        }
        if (idParam != null && !idParam.isBlank()) {
            try {
                return billDAO.getBillById(Integer.parseInt(idParam));
            } catch (NumberFormatException ignored) {
                // ignore invalid id format
            }
        }
        return null;
    }
}
