<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Help Section - Staff Reservation Guide</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-dark: #004040;
            --primary: #008080;
            --primary-light: #00C0C0;
            --accent: #006060;
            --soft: #EAF9F9;
            --bg: #F5FBFB;
            --white: #ffffff;
            --text: #223535;
            --muted: #5c7777;
            --border: #d7ecec;
            --gradient: linear-gradient(135deg, #004040 0%, #008080 55%, #00C0C0 100%);
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Poppins', sans-serif;
            background: var(--bg);
            color: var(--text);
            line-height: 1.65;
            overflow-x: hidden;
        }

        .topbar {
            position: sticky;
            top: 0;
            z-index: 100;
            background: var(--gradient);
            color: var(--white);
            padding: 14px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 8px 22px rgba(0, 64, 64, 0.22);
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 10px;
            font-weight: 700;
            font-size: 15px;
        }

        .top-links { display: flex; gap: 8px; flex-wrap: wrap; }

        .top-links a {
            text-decoration: none;
            color: var(--white);
            border: 1px solid rgba(255,255,255,0.42);
            padding: 8px 11px;
            border-radius: 10px;
            font-size: 12px;
            font-weight: 600;
            transition: 0.25s ease;
            background: rgba(255,255,255,0.06);
        }

        .top-links a:hover { background: rgba(255,255,255,0.18); transform: translateY(-2px); }

        .container {
            max-width: 1180px;
            margin: 24px auto;
            padding: 0 14px 36px;
        }

        .hero {
            background: var(--gradient);
            color: var(--white);
            border-radius: 22px;
            padding: 26px;
            position: relative;
            overflow: hidden;
            box-shadow: 0 18px 32px rgba(0, 64, 64, 0.2);
            margin-bottom: 16px;
        }

        .hero::after {
            content: "";
            position: absolute;
            width: 260px;
            height: 260px;
            right: -80px;
            top: -90px;
            border-radius: 50%;
            background: rgba(255,255,255,0.12);
        }

        .hero h1 {
            font-size: clamp(26px, 4vw, 40px);
            margin-bottom: 8px;
            position: relative;
            z-index: 1;
        }

        .hero p {
            max-width: 800px;
            font-size: 14px;
            opacity: 0.95;
            position: relative;
            z-index: 1;
        }

        .section {
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: 18px;
            padding: 18px;
            box-shadow: 0 8px 22px rgba(0,64,64,0.08);
            margin-bottom: 12px;
            opacity: 0;
            transform: translateY(22px);
            transition: all 0.65s ease;
        }

        .section.reveal {
            opacity: 1;
            transform: translateY(0);
        }

        .section h2 {
            color: var(--primary-dark);
            font-size: 22px;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .section .sub {
            color: var(--muted);
            font-size: 14px;
            margin-bottom: 12px;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 12px;
        }

        .card {
            background: linear-gradient(180deg, #ffffff, #f9ffff);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 14px;
            transition: 0.25s ease;
        }

        .card:hover {
            transform: translateY(-6px);
            box-shadow: 0 14px 24px rgba(0, 64, 64, 0.12);
            border-color: #b8e5e5;
        }

        .card h3 {
            color: var(--accent);
            font-size: 15px;
            margin-bottom: 7px;
            display: flex;
            align-items: center;
            gap: 9px;
        }

        .card ul { padding-left: 18px; }
        .card li { font-size: 13px; margin-bottom: 6px; }

        .icon {
            width: 34px;
            height: 34px;
            border-radius: 10px;
            background: var(--soft);
            color: var(--primary);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            animation: floatIcon 3.8s ease-in-out infinite;
            border: 1px solid #c6eaea;
        }

        @keyframes floatIcon {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-5px); }
        }

        .workflow {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
            gap: 11px;
            counter-reset: steps;
        }

        .step {
            background: var(--soft);
            border: 1px solid #c9eaea;
            border-radius: 12px;
            padding: 12px;
            position: relative;
        }

        .step::before {
            counter-increment: steps;
            content: counter(steps);
            width: 25px;
            height: 25px;
            border-radius: 50%;
            background: var(--primary-dark);
            color: var(--white);
            font-size: 12px;
            font-weight: 700;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 7px;
        }

        .step strong {
            color: var(--primary-dark);
            display: block;
            margin-bottom: 4px;
            font-size: 14px;
        }

        .step p { font-size: 12px; color: #385454; }

        .quick-links {
            margin-top: 12px;
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }

        .quick-links a {
            text-decoration: none;
            background: linear-gradient(135deg, #006060, #009a9a);
            color: var(--white);
            padding: 8px 10px;
            border-radius: 10px;
            font-size: 12px;
            font-weight: 600;
            transition: 0.2s ease;
        }

        .quick-links a:hover { transform: translateY(-3px); }

        @media (max-width: 760px) {
            .topbar { flex-direction: column; align-items: flex-start; gap: 8px; }
            .top-links { width: 100%; }
        }
    </style>
</head>
<body>
    <header class="topbar">
        <div class="brand"><i class="fas fa-life-ring"></i> Help Section - Reservation System Guide</div>
        <div class="top-links">
            <a href="${pageContext.request.contextPath}/home.jsp"><i class="fas fa-home"></i> Home</a>
            <a href="${pageContext.request.contextPath}/login.jsp?role=staff"><i class="fas fa-sign-in-alt"></i> Staff Login</a>
            <a href="${pageContext.request.contextPath}/staff/staff-dashboard.jsp"><i class="fas fa-gauge"></i> Dashboard</a>
        </div>
    </header>

    <main class="container">
        <section class="hero">
            <h1>System Analysis & Staff Help</h1>
            <p>
                This help page explains how the Ocean View Resort reservation system works and provides clear guidelines
                for new staff members to handle reservations accurately, quickly, and professionally.
            </p>
        </section>

        <section class="section reveal-on-scroll">
            <h2><span class="icon"><i class="fas fa-diagram-project"></i></span> System Analysis (How the system flows)</h2>
            <p class="sub">Understand the real process before operating modules.</p>
            <div class="grid">
                <article class="card">
                    <h3><span class="icon"><i class="fas fa-users"></i></span> Guest Management</h3>
                    <ul>
                        <li>Search guest records first before creating a new profile.</li>
                        <li>Keep NIC/Passport, email, and phone details correct.</li>
                        <li>Guest data quality affects reservation and billing quality.</li>
                    </ul>
                </article>
                <article class="card">
                    <h3><span class="icon"><i class="fas fa-bed"></i></span> Room Availability</h3>
                    <ul>
                        <li>Check room status and room type before assigning.</li>
                        <li>Avoid conflicts by verifying check-in/check-out dates.</li>
                        <li>Use matching occupancy for number of guests.</li>
                    </ul>
                </article>
                <article class="card">
                    <h3><span class="icon"><i class="fas fa-file-invoice-dollar"></i></span> Billing & Payments</h3>
                    <ul>
                        <li>Generate invoice after reservation details are confirmed.</li>
                        <li>Verify nights, rates, discounts, and extra charges.</li>
                        <li>Update payment status correctly to match finance reports.</li>
                    </ul>
                </article>
            </div>
        </section>

        <section class="section reveal-on-scroll" id="workflow">
            <h2><span class="icon"><i class="fas fa-route"></i></span> Guidelines for New Staff (Reservation Workflow)</h2>
            <p class="sub">Follow these steps in the same order for every booking.</p>
            <div class="workflow">
                <div class="step"><strong>Open Customers</strong><p>Select existing guest or add a new guest profile.</p></div>
                <div class="step"><strong>Verify Guest Details</strong><p>Check full name, NIC/Passport, mobile, and email.</p></div>
                <div class="step"><strong>Choose Room</strong><p>Confirm availability, room type, and guest capacity.</p></div>
                <div class="step"><strong>Create Reservation</strong><p>Set check-in/out dates and number of guests correctly.</p></div>
                <div class="step"><strong>Update Status</strong><p>Use CONFIRMED -> CHECKED_IN -> CHECKED_OUT when appropriate.</p></div>
                <div class="step"><strong>Invoice & Payment</strong><p>Create invoice and mark payment status accurately.</p></div>
            </div>
        </section>

        <section class="section reveal-on-scroll">
            <h2><span class="icon"><i class="fas fa-circle-check"></i></span> Best Practice Guidelines</h2>
            <p class="sub">Simple rules to avoid mistakes and maintain professional service.</p>
            <div class="grid">
                <article class="card">
                    <h3><span class="icon"><i class="fas fa-user-lock"></i></span> Use your own login only</h3>
                    <ul>
                        <li>Do not share staff credentials with others.</li>
                        <li>All actions are tracked by account activity.</li>
                    </ul>
                </article>
                <article class="card">
                    <h3><span class="icon"><i class="fas fa-calendar-days"></i></span> Double-check reservation dates</h3>
                    <ul>
                        <li>Always recheck check-in and check-out before saving.</li>
                        <li>Wrong dates can create room allocation conflicts.</li>
                    </ul>
                </article>
                <article class="card">
                    <h3><span class="icon"><i class="fas fa-repeat"></i></span> Keep statuses updated</h3>
                    <ul>
                        <li>Late status updates cause report and room errors.</li>
                        <li>Update both reservation and payment states on time.</li>
                    </ul>
                </article>
            </div>
            <div class="quick-links">
                <a href="${pageContext.request.contextPath}/staff/staff-customers.jsp"><i class="fas fa-users"></i> Customers</a>
                <a href="${pageContext.request.contextPath}/staff/staff-reservations.jsp"><i class="fas fa-calendar-check"></i> Reservations</a>
                <a href="${pageContext.request.contextPath}/staff/staff-rooms.jsp"><i class="fas fa-bed"></i> Rooms</a>
                <a href="${pageContext.request.contextPath}/staff/staff-invoices.jsp"><i class="fas fa-file-invoice"></i> Invoices</a>
                <a href="${pageContext.request.contextPath}/staff/staff-payments.jsp"><i class="fas fa-credit-card"></i> Payments</a>
            </div>
        </section>
    </main>

    <script>
        const sections = document.querySelectorAll('.reveal-on-scroll');
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('reveal');
                }
            });
        }, { threshold: 0.15 });

        sections.forEach(section => observer.observe(section));
    </script>
</body>
</html>
