<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head><title>Edit Room</title></head>
<body>
<h2>Edit Room ${room.roomNumber}</h2>
<form method="post" action="${pageContext.request.contextPath}/room/update-status">
<input type="hidden" name="roomId" value="${room.roomId}" />
<label>Status</label>
<select name="status">
<option value="AVAILABLE">AVAILABLE</option>
<option value="MAINTENANCE">MAINTENANCE</option>
<option value="RESERVED">RESERVED</option>
<option value="OCCUPIED">OCCUPIED</option>
</select>
<button type="submit">Update</button>
</form>
<p><a href="${pageContext.request.contextPath}/room/list">Back</a></p>
</body>
</html>
