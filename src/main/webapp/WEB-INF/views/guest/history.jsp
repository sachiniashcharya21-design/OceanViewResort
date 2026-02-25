<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head><title>Guest History</title></head>
<body>
<h2>Guest History - ${guest.fullName}</h2>
<table border="1" cellpadding="6" cellspacing="0">
<tr><th>Reservation #</th><th>Check In</th><th>Check Out</th><th>Status</th></tr>
<c:forEach var="r" items="${reservations}">
<tr><td>${r.reservationNumber}</td><td>${r.checkInDate}</td><td>${r.checkOutDate}</td><td>${r.status}</td></tr>
</c:forEach>
</table>
<p><a href="${pageContext.request.contextPath}/guest/list">Back</a></p>
</body>
</html>
