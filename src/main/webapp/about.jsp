<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>About Us - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/landing-pages.css">
</head>
<body>
<!-- Mobile Header -->
<header class="mobile-header">
    <a href="${pageContext.request.contextPath}/home.jsp" class="mobile-logo">
        <div class="mobile-logo-icon"><i class="fas fa-hotel"></i></div>
        <span>Ocean View Resort</span>
    </a>
    <div class="hamburger" onclick="toggleMobileMenu()">
        <span></span><span></span><span></span>
    </div>
</header>

<!-- Mobile Overlay -->
<div class="mobile-overlay" onclick="toggleMobileMenu()"></div>

<!-- Left Sidebar -->
<aside class="sidebar">
    <div class="sidebar-header">
        <a href="${pageContext.request.contextPath}/home.jsp" class="logo">
            <img src="${pageContext.request.contextPath}/images/logo.png" alt="Ocean View Resort" class="logo-image"
                 onerror="this.style.display='none'; document.querySelector('.logo-icon').style.display='flex';">
            <div class="logo-icon" style="display: none;">
                <i class="fas fa-hotel"></i>
            </div>
            <h1>Ocean View Resort</h1>
            <p>Galle, Sri Lanka</p>
        </a>
    </div>

    <nav class="sidebar-nav">
        <a href="${pageContext.request.contextPath}/home.jsp#home" class="nav-item">
            <i class="fas fa-home"></i><span>Home</span>
        </a>
        <a href="${pageContext.request.contextPath}/home.jsp#features" class="nav-item">
            <i class="fas fa-star"></i><span>Features</span>
        </a>
        <a href="${pageContext.request.contextPath}/home.jsp#rooms" class="nav-item">
            <i class="fas fa-bed"></i><span>Rooms</span>
        </a>
        <a href="${pageContext.request.contextPath}/home.jsp#testimonials" class="nav-item">
            <i class="fas fa-quote-left"></i><span>Reviews</span>
        </a>
        <a href="${pageContext.request.contextPath}/home.jsp#contact" class="nav-item">
            <i class="fas fa-envelope"></i><span>Contact</span>
        </a>

        <div class="nav-divider"></div>

        <a href="${pageContext.request.contextPath}/about.jsp" class="nav-item active">
            <i class="fas fa-info-circle"></i><span>About Us</span>
        </a>
        <a href="${pageContext.request.contextPath}/gallery.jsp" class="nav-item">
            <i class="fas fa-images"></i><span>Gallery</span>
        </a>
    </nav>

    <div class="sidebar-footer">
        <div class="login-buttons">
            <a href="${pageContext.request.contextPath}/login.jsp?role=staff" class="btn-login btn-staff">
                <i class="fas fa-user"></i> Staff Login
            </a>
            <a href="${pageContext.request.contextPath}/login.jsp?role=admin" class="btn-login btn-admin">
                <i class="fas fa-user-shield"></i> Admin Login
            </a>
        </div>
    </div>
</aside>

<!-- Main Content -->
<main class="main-content">
    <section class="page-hero bg-about">
        <div class="hero-inner">
            <div class="hero-badge"><i class="fas fa-compass"></i> Our Story</div>
            <h1 class="hero-title">Crafting <span>Oceanfront</span> Moments</h1>
            <p class="hero-subtitle">
                From sunrise breakfasts to sunset walks along the shore, Ocean View Resort is built around calm luxury,
                warm Sri Lankan hospitality, and the timeless beauty of Galle.
            </p>
            <div class="breadcrumb">
                <a href="${pageContext.request.contextPath}/home.jsp">Home</a>
                <span>/</span>
                <span>About Us</span>
            </div>
            <div class="btn-row">
                <a class="btn-cta primary" href="${pageContext.request.contextPath}/home.jsp#rooms">
                    <i class="fas fa-calendar-check"></i> Explore Rooms
                </a>
                <a class="btn-cta ghost" href="${pageContext.request.contextPath}/home.jsp#contact">
                    <i class="fas fa-envelope"></i> Contact Us
                </a>
            </div>
        </div>
    </section>

    <section class="section alt">
        <div class="section-header">
            <div class="section-badge">Who We Are</div>
            <h2 class="section-title">A Resort With a Heart</h2>
            <p class="section-subtitle">
                Designed for serenity, curated for comfort, and perfected for unforgettable stays—right at the edge of the Indian Ocean.
            </p>
        </div>

        <div class="grid-2">
            <div class="content-card">
                <h3>Inspired by Galle, shaped by the sea</h3>
                <p>
                    Ocean View Resort blends modern beachfront luxury with the charm of Sri Lanka’s southern coast.
                    Every detail—from ocean-view suites to our attentive service—is built to help you slow down and truly unwind.
                </p>
                <div class="pill-row">
                    <div class="pill"><i class="fas fa-water"></i> Beachfront</div>
                    <div class="pill"><i class="fas fa-leaf"></i> Calm &amp; Quiet</div>
                    <div class="pill"><i class="fas fa-star"></i> Premium Service</div>
                    <div class="pill"><i class="fas fa-map-marker-alt"></i> Galle</div>
                </div>
                <ul>
                    <li>Ocean-view rooms with thoughtfully designed interiors</li>
                    <li>Curated experiences: local culture, coastal adventures, and relaxation</li>
                    <li>Comfort-first amenities for couples, families, and business travelers</li>
                </ul>
            </div>

            <div class="image-card" aria-label="Ocean View Resort view">
                <img src="${pageContext.request.contextPath}/images/resort-3.jpg" alt="Ocean View Resort view">
            </div>
        </div>
    </section>

    <section class="section">
        <div class="section-header">
            <div class="section-badge">Our Promise</div>
            <h2 class="section-title">Values That Guide Us</h2>
            <p class="section-subtitle">
                We keep it simple: genuine hospitality, exceptional comfort, and respect for our environment and community.
            </p>
        </div>

        <div class="cards-3">
            <div class="mini-card">
                <div class="icon"><i class="fas fa-hand-holding-heart"></i></div>
                <h4>Warm Hospitality</h4>
                <p>Friendly service that feels personal, from check-in to the last goodbye.</p>
            </div>
            <div class="mini-card">
                <div class="icon"><i class="fas fa-gem"></i></div>
                <h4>Thoughtful Luxury</h4>
                <p>Elevated comfort without the noise—clean design, quality details, peaceful spaces.</p>
            </div>
            <div class="mini-card">
                <div class="icon"><i class="fas fa-seedling"></i></div>
                <h4>Coastal Care</h4>
                <p>Mindful choices that protect the shoreline and celebrate local culture and craftsmanship.</p>
            </div>
        </div>
    </section>

    <section class="section dark">
        <div class="section-header">
            <div class="section-badge">By The Numbers</div>
            <h2 class="section-title">A Stay You Can Trust</h2>
            <p class="section-subtitle">Comfort, consistency, and a team that takes pride in every detail.</p>
        </div>

        <div class="stats">
            <div class="stat"><div class="num">5★</div><div class="label">Luxury Standard</div></div>
            <div class="stat"><div class="num">24/7</div><div class="label">Reception</div></div>
            <div class="stat"><div class="num">100%</div><div class="label">Ocean Breeze</div></div>
            <div class="stat"><div class="num">∞</div><div class="label">Sunset Views</div></div>
        </div>
    </section>

    <section class="section alt">
        <div class="section-header">
            <div class="section-badge">Milestones</div>
            <h2 class="section-title">Our Journey</h2>
            <p class="section-subtitle">A few highlights that shaped Ocean View Resort into what it is today.</p>
        </div>

        <div class="timeline">
            <div class="timeline-item">
                <div class="year">2018</div>
                <div>
                    <h4>Resort vision begins</h4>
                    <p>Planning started with one goal: create a calm oceanfront escape that feels genuinely Sri Lankan.</p>
                </div>
            </div>
            <div class="timeline-item">
                <div class="year">2021</div>
                <div>
                    <h4>Doors open in Galle</h4>
                    <p>Welcomed our first guests with a small team focused on comfort, cleanliness, and warmth.</p>
                </div>
            </div>
            <div class="timeline-item">
                <div class="year">2024</div>
                <div>
                    <h4>Experience upgrades</h4>
                    <p>Expanded guest experiences: curated local tours, room enhancements, and elevated dining moments.</p>
                </div>
            </div>
            <div class="timeline-item">
                <div class="year">2026</div>
                <div>
                    <h4>Designed for today</h4>
                    <p>Refreshed our look with a modern coastal theme—clean, vibrant, and consistent across all guest pages.</p>
                </div>
            </div>
        </div>
    </section>

    <footer class="footer">
        <div class="footer-social">
            <a href="#"><i class="fab fa-facebook-f"></i></a>
            <a href="#"><i class="fab fa-instagram"></i></a>
            <a href="#"><i class="fab fa-twitter"></i></a>
            <a href="#"><i class="fab fa-tripadvisor"></i></a>
        </div>
        <p>&copy; 2026 Ocean View Resort. All rights reserved. | Galle, Sri Lanka</p>
    </footer>
</main>

<script>
    function toggleMobileMenu() {
        const sidebar = document.querySelector('.sidebar');
        const hamburger = document.querySelector('.hamburger');
        const overlay = document.querySelector('.mobile-overlay');

        if (!sidebar || !hamburger || !overlay) return;

        sidebar.classList.toggle('active');
        hamburger.classList.toggle('active');
        overlay.classList.toggle('active');
    }

    document.querySelectorAll('.sidebar .nav-item').forEach(item => {
        item.addEventListener('click', () => {
            const sidebar = document.querySelector('.sidebar');
            const hamburger = document.querySelector('.hamburger');
            const overlay = document.querySelector('.mobile-overlay');

            if (window.innerWidth <= 768 && sidebar && hamburger && overlay) {
                sidebar.classList.remove('active');
                hamburger.classList.remove('active');
                overlay.classList.remove('active');
            }
        });
    });
</script>
</body>
</html>

