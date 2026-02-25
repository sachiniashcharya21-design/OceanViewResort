<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gallery - Ocean View Resort</title>
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

        <a href="${pageContext.request.contextPath}/about.jsp" class="nav-item">
            <i class="fas fa-info-circle"></i><span>About Us</span>
        </a>
        <a href="${pageContext.request.contextPath}/gallery.jsp" class="nav-item active">
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
    <section class="page-hero bg-gallery">
        <div class="hero-inner">
            <div class="hero-badge"><i class="fas fa-camera-retro"></i> Visual Tour</div>
            <h1 class="hero-title">Ocean View <span>Gallery</span></h1>
            <p class="hero-subtitle">
                A curated collection of calm corners, golden sunsets, and oceanfront comfort. Tap any photo to view it larger.
            </p>
            <div class="breadcrumb">
                <a href="${pageContext.request.contextPath}/home.jsp">Home</a>
                <span>/</span>
                <span>Gallery</span>
            </div>
            <div class="btn-row">
                <a class="btn-cta primary" href="${pageContext.request.contextPath}/home.jsp#rooms">
                    <i class="fas fa-bed"></i> View Rooms
                </a>
                <a class="btn-cta ghost" href="${pageContext.request.contextPath}/home.jsp#contact">
                    <i class="fas fa-phone"></i> Get In Touch
                </a>
            </div>
        </div>
    </section>

    <section class="section alt">
        <div class="section-header">
            <div class="section-badge">Browse</div>
            <h2 class="section-title">Moments by Category</h2>
            <p class="section-subtitle">
                Filter the gallery to quickly explore the resort, rooms, and the coastal vibe.
            </p>
        </div>

        <div class="filter-bar" role="tablist" aria-label="Gallery filters">
            <button class="filter-btn active" data-filter="all" type="button">All</button>
            <button class="filter-btn" data-filter="resort" type="button">Resort</button>
            <button class="filter-btn" data-filter="rooms" type="button">Rooms</button>
            <button class="filter-btn" data-filter="views" type="button">Views</button>
        </div>

        <div class="gallery-grid" id="galleryGrid">
            <div class="gallery-item" data-category="resort" data-title="Welcome to Ocean View" data-desc="A calm coastal entrance to your stay.">
                <img src="${pageContext.request.contextPath}/images/resort-1.jpg" alt="Resort photo 1">
                <div class="gallery-overlay">
                    <div class="meta">
                        <h4>Welcome to Ocean View</h4>
                        <p>Coastal arrival</p>
                    </div>
                    <div class="zoom"><i class="fas fa-magnifying-glass-plus"></i></div>
                </div>
            </div>

            <div class="gallery-item" data-category="views" data-title="Sunset Glow" data-desc="Golden hours feel different by the ocean.">
                <img src="${pageContext.request.contextPath}/images/resort-2.jpg" alt="Resort photo 2">
                <div class="gallery-overlay">
                    <div class="meta">
                        <h4>Sunset Glow</h4>
                        <p>Ocean horizon</p>
                    </div>
                    <div class="zoom"><i class="fas fa-magnifying-glass-plus"></i></div>
                </div>
            </div>

            <div class="gallery-item" data-category="resort" data-title="Resort Ambience" data-desc="Designed for calm, built for comfort.">
                <img src="${pageContext.request.contextPath}/images/resort-3.jpg" alt="Resort photo 3">
                <div class="gallery-overlay">
                    <div class="meta">
                        <h4>Resort Ambience</h4>
                        <p>Serene spaces</p>
                    </div>
                    <div class="zoom"><i class="fas fa-magnifying-glass-plus"></i></div>
                </div>
            </div>

            <div class="gallery-item" data-category="views" data-title="Ocean Breeze" data-desc="Blue tones and gentle waves—always nearby.">
                <img src="${pageContext.request.contextPath}/images/resort-4.jpg" alt="Resort photo 4">
                <div class="gallery-overlay">
                    <div class="meta">
                        <h4>Ocean Breeze</h4>
                        <p>Coastal calm</p>
                    </div>
                    <div class="zoom"><i class="fas fa-magnifying-glass-plus"></i></div>
                </div>
            </div>

            <div class="gallery-item" data-category="views" data-title="Evening Light" data-desc="A soft glow that ends the day perfectly.">
                <img src="${pageContext.request.contextPath}/images/resort-5.jpg" alt="Resort photo 5">
                <div class="gallery-overlay">
                    <div class="meta">
                        <h4>Evening Light</h4>
                        <p>After sunset</p>
                    </div>
                    <div class="zoom"><i class="fas fa-magnifying-glass-plus"></i></div>
                </div>
            </div>

            <div class="gallery-item" data-category="rooms" data-title="Standard Room" data-desc="Comfort-first design with a relaxing palette.">
                <img src="${pageContext.request.contextPath}/images/room-standard.jpg" alt="Standard room">
                <div class="gallery-overlay">
                    <div class="meta">
                        <h4>Standard Room</h4>
                        <p>Comfort essentials</p>
                    </div>
                    <div class="zoom"><i class="fas fa-magnifying-glass-plus"></i></div>
                </div>
            </div>

            <div class="gallery-item" data-category="rooms" data-title="Deluxe Room" data-desc="Extra space and premium comfort for longer stays.">
                <img src="${pageContext.request.contextPath}/images/room-deluxe.jpg" alt="Deluxe room">
                <div class="gallery-overlay">
                    <div class="meta">
                        <h4>Deluxe Room</h4>
                        <p>Premium comfort</p>
                    </div>
                    <div class="zoom"><i class="fas fa-magnifying-glass-plus"></i></div>
                </div>
            </div>

            <div class="gallery-item" data-category="rooms" data-title="Suite" data-desc="An elevated stay with refined details and calm luxury.">
                <img src="${pageContext.request.contextPath}/images/room-suite.webp" alt="Suite room">
                <div class="gallery-overlay">
                    <div class="meta">
                        <h4>Suite</h4>
                        <p>Refined details</p>
                    </div>
                    <div class="zoom"><i class="fas fa-magnifying-glass-plus"></i></div>
                </div>
            </div>

            <div class="gallery-item" data-category="rooms" data-title="Family Room" data-desc="Room to relax together, with thoughtful touches for families.">
                <img src="${pageContext.request.contextPath}/images/room-family.jpg" alt="Family room">
                <div class="gallery-overlay">
                    <div class="meta">
                        <h4>Family Room</h4>
                        <p>Space for all</p>
                    </div>
                    <div class="zoom"><i class="fas fa-magnifying-glass-plus"></i></div>
                </div>
            </div>

            <div class="gallery-item" data-category="rooms" data-title="Presidential Suite" data-desc="Top-tier space for special moments and celebrations.">
                <img src="${pageContext.request.contextPath}/images/room-presidential.webp" alt="Presidential suite">
                <div class="gallery-overlay">
                    <div class="meta">
                        <h4>Presidential Suite</h4>
                        <p>Signature stay</p>
                    </div>
                    <div class="zoom"><i class="fas fa-magnifying-glass-plus"></i></div>
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

<!-- Lightbox -->
<div class="lightbox" id="lightbox" aria-hidden="true">
    <div class="lightbox-card" role="dialog" aria-modal="true" aria-label="Image viewer">
        <div class="lightbox-media">
            <img id="lightboxImg" src="" alt="">
        </div>
        <div class="lightbox-caption">
            <div class="text">
                <h4 id="lightboxTitle"></h4>
                <p id="lightboxDesc"></p>
            </div>
            <div class="lightbox-actions">
                <button class="icon-btn" id="prevBtn" type="button" aria-label="Previous"><i class="fas fa-chevron-left"></i></button>
                <button class="icon-btn" id="nextBtn" type="button" aria-label="Next"><i class="fas fa-chevron-right"></i></button>
                <button class="icon-btn" id="closeBtn" type="button" aria-label="Close"><i class="fas fa-xmark"></i></button>
            </div>
        </div>
    </div>
</div>

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

    // Filters
    const filterButtons = Array.from(document.querySelectorAll('.filter-btn'));
    const galleryItems = Array.from(document.querySelectorAll('.gallery-item'));

    filterButtons.forEach(btn => btn.addEventListener('click', () => {
        filterButtons.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');

        const filter = btn.dataset.filter;
        galleryItems.forEach(item => {
            const match = filter === 'all' || item.dataset.category === filter;
            item.classList.toggle('hidden', !match);
        });
    }));

    // Lightbox
    const lightbox = document.getElementById('lightbox');
    const lightboxImg = document.getElementById('lightboxImg');
    const lightboxTitle = document.getElementById('lightboxTitle');
    const lightboxDesc = document.getElementById('lightboxDesc');
    const closeBtn = document.getElementById('closeBtn');
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');

    function visibleItems() {
        return galleryItems.filter(i => !i.classList.contains('hidden'));
    }

    let currentIndex = -1;

    function openLightbox(index) {
        const items = visibleItems();
        if (!items.length) return;
        currentIndex = Math.max(0, Math.min(index, items.length - 1));
        const item = items[currentIndex];
        const img = item.querySelector('img');

        lightboxImg.src = img.getAttribute('src');
        lightboxImg.alt = img.getAttribute('alt') || '';
        lightboxTitle.textContent = item.dataset.title || '';
        lightboxDesc.textContent = item.dataset.desc || '';

        lightbox.classList.add('active');
        lightbox.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';
    }

    function closeLightbox() {
        lightbox.classList.remove('active');
        lightbox.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
        currentIndex = -1;
    }

    function stepLightbox(delta) {
        const items = visibleItems();
        if (currentIndex < 0 || !items.length) return;
        currentIndex = (currentIndex + delta + items.length) % items.length;
        const item = items[currentIndex];
        const img = item.querySelector('img');
        lightboxImg.src = img.getAttribute('src');
        lightboxImg.alt = img.getAttribute('alt') || '';
        lightboxTitle.textContent = item.dataset.title || '';
        lightboxDesc.textContent = item.dataset.desc || '';
    }

    galleryItems.forEach((item) => {
        item.addEventListener('click', () => {
            const items = visibleItems();
            const index = items.indexOf(item);
            openLightbox(index >= 0 ? index : 0);
        });
    });

    closeBtn.addEventListener('click', closeLightbox);
    prevBtn.addEventListener('click', () => stepLightbox(-1));
    nextBtn.addEventListener('click', () => stepLightbox(1));

    lightbox.addEventListener('click', (e) => {
        if (e.target === lightbox) closeLightbox();
    });

    document.addEventListener('keydown', (e) => {
        if (!lightbox.classList.contains('active')) return;
        if (e.key === 'Escape') closeLightbox();
        if (e.key === 'ArrowLeft') stepLightbox(-1);
        if (e.key === 'ArrowRight') stepLightbox(1);
    });
</script>
</body>
</html>

