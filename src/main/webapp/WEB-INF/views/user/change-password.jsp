<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head><title>Change Password</title></head>
<body>
<h2>Change Password</h2>
<form method="post" action="${pageContext.request.contextPath}/user/change-password">
<p><label>Current Password</label><input type="password" name="currentPassword" required></p>
<p><label>New Password</label><input type="password" name="newPassword" required></p>
<p><label>Confirm Password</label><input type="password" name="confirmPassword" required></p>
<p><button type="submit">Update Password</button></p>
</form>
<p><a href="${pageContext.request.contextPath}/user/profile">Back</a></p>
</body>
</html>
