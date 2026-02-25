<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head><title>Payment</title></head>
<body>
<h2>Process Payment: ${bill.billNumber}</h2>
<form method="post" action="${pageContext.request.contextPath}/bill/processPayment">
<input type="hidden" name="billId" value="${bill.billId}" />
<label>Payment Method</label>
<select name="paymentMethod" required>
<option value="CASH">Cash</option>
<option value="CARD">Card</option>
<option value="BANK_TRANSFER">Bank Transfer</option>
<option value="ONLINE">Online</option>
</select>
<button type="submit">Pay</button>
</form>
<p><a href="${pageContext.request.contextPath}/bill/view?id=${bill.billNumber}">Cancel</a></p>
</body>
</html>
