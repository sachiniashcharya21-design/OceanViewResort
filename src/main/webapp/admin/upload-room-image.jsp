<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ page import="java.sql.*" %>
        <%@ page import="java.io.*" %>
            <%@ page import="java.util.*" %>
                <%@ page import="java.nio.file.*" %>
                    <%@ page import="javax.servlet.http.Part" %>
                        <%@ page import="javax.servlet.annotation.MultipartConfig" %>
                            <% response.setContentType("application/json"); response.setCharacterEncoding("UTF-8"); //
                                Check session String userRole=(String) session.getAttribute("userRole"); if
                                (!"ADMIN".equalsIgnoreCase(userRole)) { out.print("{\"success\": false, \"message\":
                                \"Unauthorized access\"}"); return; } String result="{\" success\": false, \"message\":
                                \"Unknown error\"}"; try { String action=request.getParameter("action"); if
                                ("upload".equals(action)) { // Get uploaded file Part
                                filePart=request.getPart("roomImage"); if (filePart==null || filePart.getSize()==0) {
                                result="{\" success\": false, \"message\": \"No file uploaded\"}"; } else { // Validate
                                file type String contentType=filePart.getContentType(); if
                                (!contentType.startsWith("image/")) { result="{\" success\": false, \"message\": \"Only
                                image files are allowed\"}"; } else { // Get original filename String
                                fileName=Paths.get(filePart.getSubmittedFileName()).getFileName().toString(); //
                                Generate unique filename String ext=fileName.substring(fileName.lastIndexOf("."));
                                String newFileName="room_" + System.currentTimeMillis() + ext; // Upload directory
                                String uploadDir=application.getRealPath("/uploads/rooms/"); File uploadFolder=new
                                File(uploadDir); if (!uploadFolder.exists()) { uploadFolder.mkdirs(); } // Save file
                                String filePath=uploadDir + File.separator + newFileName; filePart.write(filePath); //
                                Return relative URL String imageUrl=request.getContextPath() + "/uploads/rooms/" +
                                newFileName; result="{\" success\": true, \"imageUrl\": \"" + imageUrl + "\" ,
                                \"fileName\": \"" + newFileName + "\" }"; } } } else if ("delete".equals(action)) {
                                String fileName=request.getParameter("fileName"); if (fileName !=null &&
                                !fileName.isEmpty()) { String uploadDir=application.getRealPath("/uploads/rooms/"); File
                                file=new File(uploadDir + File.separator + fileName); if (file.exists()) {
                                file.delete(); result="{\" success\": true}"; } else { result="{\" success\": false,
                                \"message\": \"File not found\"}"; } } } } catch (Exception e) { result="{\" success\":
                                false, \"message\": \"" + e.getMessage().replace("\"", "'" ) + "\" }";
                                e.printStackTrace(); } out.print(result); %>