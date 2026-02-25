$content = Get-Content -Raw src\main\webapp\admin\admin-book-room.jsp

$content = $content.Replace("adminId", "staffId")
$content = $content.Replace("/login.jsp?role=admin", "/login.jsp?role=staff")
$content = $content.Replace("`"ADMIN`".equalsIgnoreCase", "`"STAFF`".equalsIgnoreCase")
$content = $content.Replace("/admin/admin-customers.jsp", "/staff/staff-customers.jsp")
$content = $content.Replace("/admin/admin-dashboard.jsp", "/staff/staff-dashboard.jsp")
$content = $content.Replace("/admin/admin-book-room.jsp", "/staff/staff-book-room.jsp")
$content = $content.Replace("/admin/admin-payment.jsp", "/staff/staff-payment.jsp")
$content = $content.Replace("Ocean View Resort Admin", "Ocean View Resort Staff")

# Now the literal block for guestName extraction
$oldGuest = @"
    try {
        guestId = Integer.parseInt(request.getParameter("guestId"));
        guestName = request.getParameter("guestName");
        if (guestName != null) {
            guestName = URLDecoder.decode(guestName, "UTF-8");
        }
    } catch (Exception e) {
        response.sendRedirect(request.getContextPath() + "/staff/staff-customers.jsp");
        return;
    }
"@
$oldGuest = $oldGuest.Replace("`n", "`r`n") # Windows CRLF

$newGuest = @"
    try {
        guestId = Integer.parseInt(request.getParameter("guestId"));
        guestName = request.getParameter("guestName");
        if (guestName != null) {
            guestName = URLDecoder.decode(guestName, "UTF-8");
        }
        if (guestName == null) guestName = "";
        guestName = guestName.trim();
    } catch (Exception e) {
        response.sendRedirect(request.getContextPath() + "/staff/staff-customers.jsp");
        return;
    }
"@
$newGuest = $newGuest.Replace("`n", "`r`n")

if ($content.Contains($oldGuest)) {
    $content = $content.Replace($oldGuest, $newGuest)
} else {
    Write-Host "Warning: oldGuest block not found. Checking without CRLF replace..."
    $oldGuest = $oldGuest.Replace("`r`n", "`n")
    $newGuest = $newGuest.Replace("`r`n", "`n")
    if ($content.Contains($oldGuest)) {
        $content = $content.Replace($oldGuest, $newGuest)
        Write-Host "Found with LF."
    } else {
        Write-Host "Still not found!"
    }
}

$oldAction = @"
        if ("createBooking".equals(action)) {
"@
$oldAction = $oldAction.Replace("`n", "`r`n")

$newAction = @"
        // Resolve guest name from DB if not present in URL
        if (guestName.isEmpty()) {
            PreparedStatement psGuest = conn.prepareStatement("SELECT full_name FROM guests WHERE guest_id = ?");
            psGuest.setInt(1, guestId);
            ResultSet rsGuest = psGuest.executeQuery();
            if (rsGuest.next()) {
                guestName = rsGuest.getString("full_name");
            }
            rsGuest.close();
            psGuest.close();
            if (guestName == null || guestName.trim().isEmpty()) {
                guestName = "Guest";
            }
        }
        
        if ("createBooking".equals(action)) {
"@
$newAction = $newAction.Replace("`n", "`r`n")

if ($content.Contains($oldAction.Trim())) {
    $content = $content.Replace('        if ("createBooking".equals(action)) {', $newAction.Trim())
}

# The user is a staff in DB, which doesn't guarantee staffId is in session because staff is a user with role=STAFF.
# Wait, wait, this is important:
# `admin-book-room.jsp` has `Integer adminId = (Integer) session.getAttribute("userId");`
# Then when booking it inserts to reservation: `ps.setInt(8, adminId);`
# `staff-book-room.jsp` initially used `Integer staffId = (Integer) session.getAttribute("userId");`
# In my copied version, it will also be `Integer staffId = (Integer) session.getAttribute("userId");` and `ps.setInt(8, staffId);`. That's completely correct.

Set-Content -Path src\main\webapp\staff\staff-book-room.jsp -Value $content -Encoding UTF8
Write-Host "Success"
