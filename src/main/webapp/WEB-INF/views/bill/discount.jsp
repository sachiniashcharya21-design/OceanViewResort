<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head><title>Discount</title></head>
<body>
<h2>Apply Discount: ${bill.billNumber}</h2>
<form method="post" action="${pageContext.request.contextPath}/bill/applyDiscount">
<input type="hidden" name="billId" value="${bill.billId}" />
<label>Discount (0-100 as %, or absolute amount)</label>
<input type="number" step="0.01" min="0" name="discount" required />
<button type="submit">Apply</button>
</form>
<p><a href="${pageContext.request.contextPath}/bill/view?id=${bill.billNumber}">Cancel</a></p>
</body>
</html>
