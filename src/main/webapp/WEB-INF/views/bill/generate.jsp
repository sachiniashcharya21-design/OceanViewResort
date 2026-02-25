<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head><title>Generate Bill</title></head>
<body>
<h2>Generate Bill</h2>
<form method="post" action="${pageContext.request.contextPath}/bill/generate">
<label>Reservation Number</label>
<input type="text" name="reservationNumber" placeholder="RES2026020001" required />
<button type="submit">Generate</button>
</form>
<p><a href="${pageContext.request.contextPath}/bill/list">Back</a></p>
</body>
</html>
