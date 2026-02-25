package com.oceanview.servlet;

import com.oceanview.dao.*;
import com.oceanview.model.*;
import com.oceanview.model.Room.RoomStatus;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;

/**
 * Room Servlet - Handles all room operations
 * 
 * @author Ocean View Resort Development Team
 */
@WebServlet(name = "RoomServlet", urlPatterns = { "/room/*" })
public class RoomServlet extends HttpServlet {

    private RoomDAO roomDAO;
    private UserDAO userDAO;

    @Override
    public void init() throws ServletException {
        try {
            roomDAO = new RoomDAO();
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
            case "/list" -> listRooms(request, response);
            case "/available" -> listAvailableRooms(request, response);
            case "/types" -> listRoomTypes(request, response);
            case "/add" -> showAddForm(request, response);
            case "/edit" -> showEditForm(request, response);
            case "/type/add" -> showAddTypeForm(request, response);
            case "/type/edit" -> showEditTypeForm(request, response);
            default -> listRooms(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();
        if (pathInfo == null)
            pathInfo = "/";

        User user = (User) request.getSession().getAttribute("user");
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        // Only admin can modify rooms
        if (user.getRole() != User.UserRole.ADMIN) {
            request.getSession().setAttribute("error", "Access denied. Admin only.");
            response.sendRedirect(request.getContextPath() + "/room/list");
            return;
        }

        switch (pathInfo) {
            case "/add" -> addRoom(request, response);
            case "/update-status" -> updateRoomStatus(request, response);
            case "/update-rate" -> updateRoomRate(request, response);
            case "/delete" -> deleteRoom(request, response);
            case "/type/add" -> addRoomType(request, response);
            case "/type/update" -> updateRoomType(request, response);
            case "/type/delete" -> deleteRoomType(request, response);
            default -> response.sendRedirect(request.getContextPath() + "/room/list");
        }
    }

    private void listRooms(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        List<Room> rooms = roomDAO.getAllRooms();
        request.setAttribute("rooms", rooms);
        request.setAttribute("pageTitle", "All Rooms");
        request.getRequestDispatcher("/WEB-INF/views/room/list.jsp").forward(request, response);
    }

    private void listAvailableRooms(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        List<Room> rooms = roomDAO.getAvailableRooms();
        request.setAttribute("rooms", rooms);
        request.setAttribute("pageTitle", "Available Rooms");
        request.getRequestDispatcher("/WEB-INF/views/room/list.jsp").forward(request, response);
    }

    private void listRoomTypes(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        List<RoomType> roomTypes = roomDAO.getAllRoomTypes();
        request.setAttribute("roomTypes", roomTypes);
        request.getRequestDispatcher("/WEB-INF/views/room/types.jsp").forward(request, response);
    }

    private void showAddForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = (User) request.getSession().getAttribute("user");
        if (user.getRole() != User.UserRole.ADMIN) {
            response.sendRedirect(request.getContextPath() + "/room/list");
            return;
        }

        List<RoomType> roomTypes = roomDAO.getAllRoomTypes();
        request.setAttribute("roomTypes", roomTypes);
        request.getRequestDispatcher("/WEB-INF/views/room/add.jsp").forward(request, response);
    }

    private void showEditForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = (User) request.getSession().getAttribute("user");
        if (user.getRole() != User.UserRole.ADMIN) {
            response.sendRedirect(request.getContextPath() + "/room/list");
            return;
        }

        int roomId = Integer.parseInt(request.getParameter("id"));
        Room room = roomDAO.getRoomById(roomId);
        List<RoomType> roomTypes = roomDAO.getAllRoomTypes();

        request.setAttribute("room", room);
        request.setAttribute("roomTypes", roomTypes);
        request.getRequestDispatcher("/WEB-INF/views/room/edit.jsp").forward(request, response);
    }

    private void addRoom(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            String roomNumber = request.getParameter("roomNumber");
            int roomTypeId = Integer.parseInt(request.getParameter("roomTypeId"));
            int floorNumber = Integer.parseInt(request.getParameter("floorNumber"));
            String notes = request.getParameter("notes");

            Room room = new Room();
            room.setRoomNumber(roomNumber);
            room.setRoomTypeId(roomTypeId);
            room.setFloorNumber(floorNumber);
            room.setNotes(notes);
            room.setStatus(RoomStatus.AVAILABLE);

            if (roomDAO.addRoom(room)) {
                userDAO.logActivity(currentUser.getUserId(), "ADD_ROOM",
                        "Added room " + roomNumber);
                request.getSession().setAttribute("success", "Room added successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to add room");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/room/list");
    }

    private void updateRoomStatus(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            int roomId = Integer.parseInt(request.getParameter("roomId"));
            String statusStr = request.getParameter("status");
            RoomStatus status = RoomStatus.valueOf(statusStr);

            if (roomDAO.updateRoomStatus(roomId, status)) {
                Room room = roomDAO.getRoomById(roomId);
                userDAO.logActivity(currentUser.getUserId(), "UPDATE_ROOM_STATUS",
                        "Updated room " + room.getRoomNumber() + " status to " + status);
                request.getSession().setAttribute("success", "Room status updated!");
            } else {
                request.getSession().setAttribute("error", "Failed to update status");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/room/list");
    }

    private void updateRoomRate(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            int roomTypeId = Integer.parseInt(request.getParameter("roomTypeId"));
            BigDecimal newRate = new BigDecimal(request.getParameter("newRate"));

            if (roomDAO.updateRoomTypeRate(roomTypeId, newRate)) {
                userDAO.logActivity(currentUser.getUserId(), "UPDATE_RATE",
                        "Updated room type rate to " + newRate);
                request.getSession().setAttribute("success", "Room rate updated!");
            } else {
                request.getSession().setAttribute("error", "Failed to update rate");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/room/types");
    }

    private void deleteRoom(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            int roomId = Integer.parseInt(request.getParameter("roomId"));
            Room room = roomDAO.getRoomById(roomId);

            if (roomDAO.deleteRoom(roomId)) {
                userDAO.logActivity(currentUser.getUserId(), "DELETE_ROOM",
                        "Deleted room " + room.getRoomNumber());
                request.getSession().setAttribute("success", "Room deleted successfully!");
            } else {
                request.getSession().setAttribute("error", "Cannot delete room with existing reservations");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/room/list");
    }

    private void showAddTypeForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = (User) request.getSession().getAttribute("user");
        if (user.getRole() != User.UserRole.ADMIN) {
            response.sendRedirect(request.getContextPath() + "/room/types");
            return;
        }
        request.getRequestDispatcher("/WEB-INF/views/room/type-add.jsp").forward(request, response);
    }

    private void showEditTypeForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = (User) request.getSession().getAttribute("user");
        if (user.getRole() != User.UserRole.ADMIN) {
            response.sendRedirect(request.getContextPath() + "/room/types");
            return;
        }

        int typeId = Integer.parseInt(request.getParameter("id"));
        RoomType roomType = roomDAO.getRoomTypeById(typeId);
        request.setAttribute("roomType", roomType);
        request.getRequestDispatcher("/WEB-INF/views/room/type-edit.jsp").forward(request, response);
    }

    private void addRoomType(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            String typeName = request.getParameter("typeName");
            String description = request.getParameter("description");
            BigDecimal baseRate = new BigDecimal(request.getParameter("baseRate"));
            int maxOccupancy = Integer.parseInt(request.getParameter("maxOccupancy"));
            String amenities = request.getParameter("amenities");

            RoomType roomType = new RoomType();
            roomType.setTypeName(typeName);
            roomType.setDescription(description);
            roomType.setRatePerNight(baseRate);
            roomType.setMaxOccupancy(maxOccupancy);
            roomType.setAmenities(amenities);

            if (roomDAO.addRoomType(roomType)) {
                userDAO.logActivity(currentUser.getUserId(), "ADD_ROOM_TYPE",
                        "Added room type: " + typeName);
                request.getSession().setAttribute("success", "Room type added successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to add room type");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/room/types");
    }

    private void updateRoomType(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            int typeId = Integer.parseInt(request.getParameter("roomTypeId"));
            String typeName = request.getParameter("typeName");
            String description = request.getParameter("description");
            BigDecimal baseRate = new BigDecimal(request.getParameter("baseRate"));
            int maxOccupancy = Integer.parseInt(request.getParameter("maxOccupancy"));
            String amenities = request.getParameter("amenities");

            RoomType roomType = roomDAO.getRoomTypeById(typeId);
            roomType.setTypeName(typeName);
            roomType.setDescription(description);
            roomType.setRatePerNight(baseRate);
            roomType.setMaxOccupancy(maxOccupancy);
            roomType.setAmenities(amenities);

            if (roomDAO.updateRoomType(roomType)) {
                userDAO.logActivity(currentUser.getUserId(), "UPDATE_ROOM_TYPE",
                        "Updated room type: " + typeName);
                request.getSession().setAttribute("success", "Room type updated successfully!");
            } else {
                request.getSession().setAttribute("error", "Failed to update room type");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/room/types");
    }

    private void deleteRoomType(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            User currentUser = (User) request.getSession().getAttribute("user");

            int typeId = Integer.parseInt(request.getParameter("roomTypeId"));
            RoomType roomType = roomDAO.getRoomTypeById(typeId);

            if (roomDAO.deleteRoomType(typeId)) {
                userDAO.logActivity(currentUser.getUserId(), "DELETE_ROOM_TYPE",
                        "Deleted room type: " + roomType.getTypeName());
                request.getSession().setAttribute("success", "Room type deleted successfully!");
            } else {
                request.getSession().setAttribute("error", "Cannot delete room type with existing rooms");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("error", "Error: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/room/types");
    }
}
