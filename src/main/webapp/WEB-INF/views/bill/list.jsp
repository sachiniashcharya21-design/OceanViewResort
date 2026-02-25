<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html>
<head><title>Bills</title></head>
<body>
<h2>Bills</h2>
<p><a href="${pageContext.request.contextPath}/bill/generate">Generate Bill</a> | <a href="${pageContext.request.contextPath}/bill/pending">Pending</a></p>
<table border="1" cellpadding="6" cellspacing="0">
<tr><th>Bill #</th><th>Reservation</th><th>Total</th><th>Status</th><th>Action</th></tr>
<c:forEach var="bill" items="${bills}">
<tr>
<td>${bill.billNumber}</td>
<td>${bill.reservationId}</td>
<td><fmt:formatNumber value="${bill.totalAmount}" pattern="#0.00"/></td>
<td>${bill.paymentStatus}</td>
<td><a href="${pageContext.request.contextPath}/bill/view?id=${bill.billNumber}">View</a></td>
</tr>
</c:forEach>
</table>
</body>
</html>
