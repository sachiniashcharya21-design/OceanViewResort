<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html>
<head><title>Bill</title></head>
<body>
<h2>Bill ${bill.billNumber}</h2>
<p>Reservation: ${bill.reservationId}</p>
<p>Nights: ${bill.numberOfNights}</p>
<p>Room total: <fmt:formatNumber value="${bill.roomTotal}" pattern="#0.00"/></p>
<p>Service charge: <fmt:formatNumber value="${bill.serviceCharge}" pattern="#0.00"/></p>
<p>Tax: <fmt:formatNumber value="${bill.taxAmount}" pattern="#0.00"/></p>
<p>Discount: <fmt:formatNumber value="${bill.discount}" pattern="#0.00"/></p>
<p>Total: <strong><fmt:formatNumber value="${bill.totalAmount}" pattern="#0.00"/></strong></p>
<p>Status: ${bill.paymentStatus}</p>
<p><a href="${pageContext.request.contextPath}/bill/payment?id=${bill.billId}">Process Payment</a> | <a href="${pageContext.request.contextPath}/bill/discount?id=${bill.billId}">Apply Discount</a> | <a href="${pageContext.request.contextPath}/bill/list">Back</a></p>
</body>
</html>
