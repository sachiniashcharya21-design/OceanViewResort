<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <!DOCTYPE html>
    <html lang="en">

    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Ocean View Resort - Luxury Beachfront Hotel in Galle, Sri Lanka</title>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap"
            rel="stylesheet">
        <style>
            :root {
                --primary-dark: #004040;
                --primary: #008080;
                --primary-light: #00C0C0;
                --accent: #006060;
                --soft: #80D0D0;
                --glow: #00C0C0;
                --white: #ffffff;
                --gradient-1: linear-gradient(135deg, #004040 0%, #008080 50%, #00C0C0 100%);
                --gradient-2: linear-gradient(45deg, #008080 0%, #00C0C0 100%);
                --gradient-3: linear-gradient(180deg, #004040 0%, #008080 100%);
            }

            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: 'Poppins', sans-serif;
                overflow-x: hidden;
                background: var(--white);
            }

            /* ==================== LEFT SIDEBAR ==================== */
            .sidebar {
                position: fixed;
                left: 0;
                top: 0;
                bottom: 0;
                width: 280px;
                background: #1C4444;
                z-index: 1000;
                display: flex;
                flex-direction: column;
                box-shadow: 5px 0 30px rgba(0, 64, 64, 0.4);
            }

            .sidebar-header {
                padding: 30px 20px;
                text-align: center;
                border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            }

            .logo {
                display: flex;
                flex-direction: column;
                align-items: center;
                text-decoration: none;
                color: var(--white);
            }

            .logo-image {
                width: 120px;
                height: 120px;
                border-radius: 50%;
                object-fit: cover;
                border: 3px solid var(--glow);
                box-shadow: 0 0 30px rgba(0, 192, 192, 0.5);
                margin-bottom: 15px;
                animation: pulse-glow 2s ease-in-out infinite;
            }

            @keyframes pulse-glow {

                0%,
                100% {
                    box-shadow: 0 0 20px rgba(0, 192, 192, 0.4);
                }

                50% {
                    box-shadow: 0 0 40px rgba(0, 192, 192, 0.8);
                }
            }

            @keyframes logo-rotate {
                0% {
                    transform: rotateY(0deg);
                }

                100% {
                    transform: rotateY(360deg);
                }
            }

            @keyframes logo-bounce {

                0%,
                100% {
                    transform: scale(1);
                }

                50% {
                    transform: scale(1.1);
                }
            }

            @keyframes logo-glow-pulse {

                0%,
                100% {
                    box-shadow: 0 0 20px rgba(0, 192, 192, 0.5),
                        0 0 40px rgba(0, 192, 192, 0.3),
                        0 0 60px rgba(0, 192, 192, 0.1);
                    border-color: #00C0C0;
                }

                50% {
                    box-shadow: 0 0 30px rgba(0, 192, 192, 0.8),
                        0 0 60px rgba(0, 192, 192, 0.5),
                        0 0 90px rgba(0, 192, 192, 0.3);
                    border-color: #ffffff;
                }
            }

            .logo-image,
            .logo-icon {
                animation: logo-glow-pulse 2s ease-in-out infinite, logo-bounce 3s ease-in-out infinite;
            }

            .logo:hover .logo-image,
            .logo:hover .logo-icon {
                animation: logo-rotate 1s ease-in-out, logo-glow-pulse 2s ease-in-out infinite;
            }

            .logo-icon {
                width: 100px;
                height: 100px;
                border-radius: 50%;
                background: var(--gradient-2);
                display: flex;
                align-items: center;
                justify-content: center;
                margin-bottom: 15px;
                border: 3px solid var(--white);
                box-shadow: 0 0 30px rgba(0, 192, 192, 0.5);
            }

            .logo-icon i {
                font-size: 3rem;
                color: var(--white);
            }

            .logo h1 {
                font-size: 1.5rem;
                font-weight: 700;
                letter-spacing: 1px;
                margin-bottom: 5px;
            }

            .logo p {
                font-size: 0.7rem;
                opacity: 0.8;
                letter-spacing: 3px;
                text-transform: uppercase;
            }

            .sidebar-nav {
                flex: 1;
                padding: 30px 0;
                display: flex;
                flex-direction: column;
            }

            .nav-item {
                display: flex;
                align-items: center;
                gap: 15px;
                padding: 15px 30px;
                color: rgba(255, 255, 255, 0.8);
                text-decoration: none;
                font-size: 0.95rem;
                font-weight: 500;
                transition: all 0.3s ease;
                position: relative;
                overflow: hidden;
            }

            .nav-item::before {
                content: '';
                position: absolute;
                left: 0;
                top: 0;
                bottom: 0;
                width: 0;
                background: var(--gradient-2);
                transition: width 0.3s ease;
                z-index: -1;
            }

            .nav-item:hover {
                color: var(--white);
                padding-left: 40px;
            }

            .nav-item:hover::before {
                width: 100%;
            }

            .nav-item.active {
                color: var(--white);
                background: rgba(0, 192, 192, 0.2);
                border-left: 4px solid var(--glow);
            }

            .nav-item i {
                width: 25px;
                text-align: center;
                font-size: 1.1rem;
            }

            .nav-divider {
                height: 1px;
                background: rgba(255, 255, 255, 0.1);
                margin: 20px 30px;
            }

            .sidebar-footer {
                padding: 20px;
                border-top: 1px solid rgba(255, 255, 255, 0.1);
            }

            .login-buttons {
                display: flex;
                flex-direction: column;
                gap: 10px;
            }

            .btn-login {
                display: flex;
                align-items: center;
                justify-content: center;
                gap: 10px;
                padding: 12px 20px;
                border-radius: 10px;
                text-decoration: none;
                font-weight: 600;
                font-size: 0.9rem;
                transition: all 0.3s ease;
            }

            .btn-staff {
                background: transparent;
                border: 2px solid var(--glow);
                color: var(--glow);
            }

            .btn-staff:hover {
                background: var(--glow);
                color: var(--primary-dark);
                transform: translateY(-2px);
                box-shadow: 0 5px 20px rgba(0, 192, 192, 0.4);
            }

            .btn-admin {
                background: var(--gradient-2);
                color: var(--primary-dark);
                border: none;
            }

            .btn-admin:hover {
                transform: translateY(-2px);
                box-shadow: 0 5px 25px rgba(0, 192, 192, 0.5);
            }

            /* ==================== MAIN CONTENT ==================== */
            .main-content {
                margin-left: 280px;
                min-height: 100vh;
            }

            /* ==================== HERO SLIDER ==================== */
            .hero-section {
                height: 100vh;
                position: relative;
                overflow: hidden;
            }

            .slider-container {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
            }

            .slide {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                opacity: 0;
                transition: opacity 1.5s ease-in-out;
                background-size: cover;
                background-position: center;
            }

            .slide.active {
                opacity: 1;
            }

            .slide::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
            }

            /* Slides now use background images from resort-1.jpg to resort-5.jpg */
            .slide {
                background-color: var(--primary-dark);
            }

            .hero-content {
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                text-align: center;
                color: var(--white);
                z-index: 10;
                width: 80%;
                max-width: 900px;
            }

            .hero-badge {
                display: inline-block;
                padding: 10px 25px;
                background: rgba(0, 192, 192, 0.3);
                border: 1px solid var(--glow);
                border-radius: 30px;
                font-size: 0.85rem;
                letter-spacing: 3px;
                text-transform: uppercase;
                margin-bottom: 25px;
                animation: fadeInDown 1s ease;
            }

            .hero-title {
                font-size: 4rem;
                font-weight: 800;
                margin-bottom: 20px;
                text-shadow: 0 5px 30px rgba(0, 0, 0, 0.3);
                animation: fadeInUp 1s ease 0.3s both;
            }

            .hero-title span {
                background: var(--gradient-2);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                background-clip: text;
            }

            .hero-subtitle {
                font-size: 1.3rem;
                opacity: 0.9;
                margin-bottom: 40px;
                font-weight: 300;
                animation: fadeInUp 1s ease 0.5s both;
            }

            .hero-buttons {
                display: flex;
                gap: 20px;
                justify-content: center;
                animation: fadeInUp 1s ease 0.7s both;
            }

            .btn-hero {
                padding: 15px 40px;
                border-radius: 50px;
                font-size: 1rem;
                font-weight: 600;
                text-decoration: none;
                transition: all 0.3s ease;
                display: flex;
                align-items: center;
                gap: 10px;
            }

            .btn-primary-hero {
                background: white;
                color: var(--primary-dark);
                box-shadow: #8FD0D0;
            }

            .btn-primary-hero:hover {
                transform: translateY(-5px);
                box-shadow: 0 15px 40px rgba(0, 192, 192, 0.6);
            }

            .btn-secondary-hero {
                background: transparent;
                color: var(--white);
                border: 2px solid var(--white);
            }

            .btn-secondary-hero:hover {
                background: var(--white);
                color: var(--primary-dark);
                transform: translateY(-5px);
            }

            /* Slide Progress Indicators */
            .slide-indicators {
                position: absolute;
                bottom: 40px;
                left: 50%;
                transform: translateX(-50%);
                display: flex;
                gap: 15px;
                z-index: 20;
            }

            .indicator {
                width: 50px;
                height: 4px;
                background: rgba(255, 255, 255, 0.3);
                border-radius: 2px;
                overflow: hidden;
                cursor: pointer;
            }

            .indicator.active .progress {
                animation: progress 3s linear forwards;
            }

            .indicator .progress {
                height: 100%;
                width: 0;
                background: var(--glow);
                border-radius: 2px;
            }

            @keyframes progress {
                0% {
                    width: 0;
                }

                100% {
                    width: 100%;
                }
            }

            /* Slide transition animation */
            .slide {
                animation: slideZoom 3s ease-in-out;
            }

            @keyframes slideZoom {
                0% {
                    transform: scale(1);
                }

                50% {
                    transform: scale(1.05);
                }

                100% {
                    transform: scale(1);
                }
            }

            /* ==================== FEATURES SECTION ==================== */
            .features-section {
                padding: 120px 60px;
                background: var(--white);
                position: relative;
                overflow: hidden;
            }

            .features-section::before {
                content: '';
                position: absolute;
                top: -100px;
                left: -100px;
                width: 300px;
                height: 300px;
                background: var(--soft);
                border-radius: 50%;
                opacity: 0.3;
                animation: float 6s ease-in-out infinite;
            }

            .features-section::after {
                content: '';
                position: absolute;
                bottom: -50px;
                right: -50px;
                width: 200px;
                height: 200px;
                background: var(--glow);
                border-radius: 50%;
                opacity: 0.2;
                animation: float 8s ease-in-out infinite reverse;
            }

            @keyframes float {

                0%,
                100% {
                    transform: translateY(0) rotate(0deg);
                }

                50% {
                    transform: translateY(-30px) rotate(10deg);
                }
            }

            .section-header {
                text-align: center;
                margin-bottom: 80px;
                position: relative;
                z-index: 1;
            }

            .section-badge {
                display: inline-block;
                padding: 8px 20px;
                background: var(--soft);
                color: var(--primary-dark);
                border-radius: 20px;
                font-size: 0.8rem;
                font-weight: 600;
                letter-spacing: 2px;
                text-transform: uppercase;
                margin-bottom: 20px;
            }

            .section-title {
                font-size: 3rem;
                color: var(--primary-dark);
                font-weight: 700;
                margin-bottom: 20px;
            }

            .section-subtitle {
                font-size: 1.1rem;
                color: var(--accent);
                max-width: 600px;
                margin: 0 auto;
            }

            .features-grid {
                display: grid;
                grid-template-columns: repeat(3, 1fr);
                gap: 30px;
                position: relative;
                z-index: 1;
            }

            .feature-card {
                background: var(--white);
                border-radius: 20px;
                padding: 40px 30px;
                text-align: center;
                box-shadow: 0 10px 40px rgba(0, 64, 64, 0.1);
                transition: all 0.4s ease;
                position: relative;
                overflow: hidden;
                opacity: 0;
                transform: translateY(50px);
            }

            .feature-card.animate {
                animation: fadeInUp 0.8s ease forwards;
            }

            .feature-card:nth-child(1) {
                animation-delay: 0.1s;
            }

            .feature-card:nth-child(2) {
                animation-delay: 0.2s;
            }

            .feature-card:nth-child(3) {
                animation-delay: 0.3s;
            }

            .feature-card:nth-child(4) {
                animation-delay: 0.4s;
            }

            .feature-card:nth-child(5) {
                animation-delay: 0.5s;
            }

            .feature-card:nth-child(6) {
                animation-delay: 0.6s;
            }

            .feature-card::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                height: 4px;
                background: var(--gradient-2);
                transform: scaleX(0);
                transition: transform 0.4s ease;
            }

            .feature-card:hover {
                transform: translateY(-15px);
                box-shadow: 0 20px 60px rgba(0, 64, 64, 0.15);
            }

            .feature-card:hover::before {
                transform: scaleX(1);
            }

            .feature-icon {
                width: 80px;
                height: 80px;
                background: var(--gradient-1);
                border-radius: 20px;
                display: flex;
                align-items: center;
                justify-content: center;
                margin: 0 auto 25px;
                transition: all 0.4s ease;
            }

            .feature-card:hover .feature-icon {
                transform: rotateY(180deg);
                border-radius: 50%;
            }

            .feature-icon i {
                font-size: 2rem;
                color: var(--white);
            }

            .feature-card h3 {
                font-size: 1.3rem;
                color: var(--primary-dark);
                margin-bottom: 15px;
                font-weight: 600;
            }

            .feature-card p {
                color: var(--accent);
                font-size: 0.95rem;
                line-height: 1.7;
            }

            /* ==================== ROOMS SECTION ==================== */
            .rooms-section {
                padding: 120px 60px;
                background: #2F7170;
                position: relative;
            }

            .rooms-section .section-title,
            .rooms-section .section-subtitle {
                color: var(--white);
            }

            .rooms-section .section-badge {
                background: rgba(0, 192, 192, 0.2);
                color: var(--glow);
                border: 1px solid var(--glow);
            }

            .rooms-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
                gap: 30px;
            }

            .room-card {
                background: #1C4444;
                backdrop-filter: blur(10px);
                border-radius: 25px;
                overflow: hidden;
                transition: all 0.4s ease;
                border: 5px solid rgba(255, 255, 255, 0.1);
                opacity: 0;
                transform: scale(0.9);
            }

            .room-card.animate {
                animation: scaleIn 0.6s ease forwards;
            }

            .room-card:nth-child(1) {
                animation-delay: 0.1s;
            }

            .room-card:nth-child(2) {
                animation-delay: 0.2s;
            }

            .room-card:nth-child(3) {
                animation-delay: 0.3s;
            }

            .room-card:nth-child(4) {
                animation-delay: 0.4s;
            }

            .room-card:nth-child(5) {
                animation-delay: 0.5s;
            }

            @keyframes scaleIn {
                to {
                    opacity: 1;
                    transform: scale(1);
                }
            }

            .room-card:hover {
                transform: translateY(-10px);
                box-shadow: 0 30px 60px rgba(0, 0, 0, 0.3);
                border-color: var(--glow);
            }

            .room-image {
                height: 220px;
                background: var(--gradient-2);
                position: relative;
                display: flex;
                align-items: center;
                justify-content: center;
                overflow: hidden;
                background-size: cover;
                background-position: center;
                background-repeat: no-repeat;
            }

            .room-image::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: linear-gradient(180deg, transparent 0%, rgba(0, 64, 64, 0.3) 100%);
                z-index: 1;
                transition: all 0.4s ease;
            }

            .room-card:hover .room-image::before {
                background: linear-gradient(180deg, transparent 0%, rgba(0, 64, 64, 0.5) 100%);
            }

            .room-image i {
                font-size: 4rem;
                color: rgba(255, 255, 255, 0.3);
                transition: all 0.4s ease;
                position: relative;
                z-index: 2;
            }

            .room-card:hover .room-image i {
                transform: scale(1.2);
                color: rgba(255, 255, 255, 0.6);
            }

            .room-image img {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                object-fit: cover;
                transition: transform 0.5s ease;
            }

            .room-card:hover .room-image img {
                transform: scale(1.1);
            }

            .room-badge {
                position: absolute;
                top: 15px;
                right: 15px;
                background: var(--glow);
                color: var(--primary-dark);
                padding: 8px 15px;
                border-radius: 20px;
                font-size: 0.8rem;
                font-weight: 600;
                z-index: 3;
                box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
            }

            .room-content {
                padding: 30px;
                color: var(--white);
            }

            .room-type {
                font-size: 1.4rem;
                font-weight: 700;
                margin-bottom: 10px;
            }

            .room-amenities {
                display: flex;
                flex-wrap: wrap;
                gap: 10px;
                margin-bottom: 20px;
            }

            .room-amenities span {
                background: rgba(0, 192, 192, 0.2);
                padding: 5px 12px;
                border-radius: 15px;
                font-size: 0.8rem;
                color: var(--glow);
            }

            .room-price {
                display: flex;
                align-items: baseline;
                gap: 5px;
            }

            .room-price .amount {
                font-size: 2rem;
                font-weight: 800;
                color: var(--glow);
            }

            .room-price .period {
                opacity: 0.7;
                font-size: 0.9rem;
            }

            /* ==================== STATS SECTION ==================== */
            .stats-section {
                padding: 80px 60px;
                background: var(--white);
            }

            .stats-grid {
                display: grid;
                grid-template-columns: repeat(4, 1fr);
                gap: 40px;
            }

            .stat-card {
                text-align: center;
                padding: 40px 20px;
                border-radius: 20px;
                background: var(--white);
                box-shadow: 0 10px 40px rgba(0, 64, 64, 0.08);
                transition: all 0.4s ease;
                opacity: 0;
                transform: translateY(30px);
            }

            .stat-card.animate {
                animation: fadeInUp 0.6s ease forwards;
            }

            .stat-card:nth-child(1) {
                animation-delay: 0.1s;
            }

            .stat-card:nth-child(2) {
                animation-delay: 0.2s;
            }

            .stat-card:nth-child(3) {
                animation-delay: 0.3s;
            }

            .stat-card:nth-child(4) {
                animation-delay: 0.4s;
            }

            .stat-card:hover {
                transform: translateY(-10px);
                box-shadow: 0 20px 50px rgba(0, 64, 64, 0.15);
            }

            .stat-icon {
                width: 70px;
                height: 70px;
                background: var(--gradient-1);
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                margin: 0 auto 20px;
            }

            .stat-icon i {
                font-size: 1.8rem;
                color: var(--white);
            }

            .stat-number {
                font-size: 3rem;
                font-weight: 800;
                color: var(--primary-dark);
                margin-bottom: 10px;
            }

            .stat-label {
                color: var(--accent);
                font-weight: 500;
                text-transform: uppercase;
                letter-spacing: 2px;
                font-size: 0.85rem;
            }

            /* ==================== TESTIMONIALS SECTION ==================== */
            .testimonials-section {
                padding: 120px 60px;
                background: linear-gradient(135deg, var(--soft) 0%, var(--glow) 100%);
                position: relative;
            }

            .testimonials-section .section-title {
                color: var(--primary-dark);
            }

            .testimonials-section .section-badge {
                background: var(--white);
            }

            .testimonials-slider {
                max-width: 800px;
                margin: 0 auto;
                position: relative;
            }

            .testimonial-card {
                background: var(--white);
                border-radius: 30px;
                padding: 50px;
                text-align: center;
                box-shadow: 0 20px 60px rgba(0, 64, 64, 0.15);
            }

            .testimonial-text {
                font-size: 1.3rem;
                color: var(--primary-dark);
                line-height: 1.8;
                margin-bottom: 30px;
                font-style: italic;
            }

            .testimonial-author {
                display: flex;
                align-items: center;
                justify-content: center;
                gap: 15px;
            }

            .author-avatar {
                width: 60px;
                height: 60px;
                border-radius: 50%;
                background: var(--gradient-1);
                display: flex;
                align-items: center;
                justify-content: center;
                color: var(--white);
                font-size: 1.5rem;
                font-weight: 700;
            }

            .author-info h4 {
                color: var(--primary-dark);
                font-size: 1.1rem;
                margin-bottom: 5px;
            }

            .author-info p {
                color: var(--accent);
                font-size: 0.9rem;
            }

            .stars {
                color: #ffc107;
                font-size: 1.2rem;
                margin-bottom: 20px;
            }

            /* ==================== CONTACT SECTION ==================== */
            .contact-section {
                padding: 120px 60px;
                background: var(--primary-dark);
                position: relative;
                overflow: hidden;
            }

            .contact-section::before {
                content: '';
                position: absolute;
                top: 0;
                right: 0;
                width: 50%;
                height: 100%;
                background: var(--gradient-2);
                opacity: 0.1;
                clip-path: polygon(30% 0, 100% 0, 100% 100%, 0% 100%);
            }

            .contact-section .section-title,
            .contact-section .section-subtitle {
                color: var(--white);
            }

            .contact-section .section-badge {
                background: rgba(0, 192, 192, 0.2);
                color: var(--glow);
                border: 1px solid var(--glow);
            }

            .contact-grid {
                display: grid;
                grid-template-columns: repeat(4, 1fr);
                gap: 30px;
                position: relative;
                z-index: 1;
            }

            .contact-card {
                background: rgba(255, 255, 255, 0.05);
                backdrop-filter: blur(10px);
                border-radius: 20px;
                padding: 40px 30px;
                text-align: center;
                border: 1px solid rgba(255, 255, 255, 0.1);
                transition: all 0.4s ease;
                opacity: 0;
                transform: translateY(30px);
            }

            .contact-card.animate {
                animation: fadeInUp 0.6s ease forwards;
            }

            .contact-card:nth-child(1) {
                animation-delay: 0.1s;
            }

            .contact-card:nth-child(2) {
                animation-delay: 0.2s;
            }

            .contact-card:nth-child(3) {
                animation-delay: 0.3s;
            }

            .contact-card:nth-child(4) {
                animation-delay: 0.4s;
            }

            .contact-card:hover {
                background: rgba(255, 255, 255, 0.1);
                transform: translateY(-10px);
                border-color: var(--glow);
            }

            .contact-icon {
                width: 70px;
                height: 70px;
                background: var(--gradient-2);
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                margin: 0 auto 25px;
            }

            .contact-icon i {
                font-size: 1.8rem;
                color: var(--primary-dark);
            }

            .contact-card h3 {
                color: var(--white);
                font-size: 1.2rem;
                margin-bottom: 15px;
            }

            .contact-card p {
                color: var(--soft);
                line-height: 1.7;
            }

            /* ==================== FOOTER ==================== */
            .footer {
                padding: 40px 60px;
                background: var(--primary-dark);
                text-align: center;
                color: var(--soft);
                border-top: 3px solid var(--primary);
            }

            .footer p {
                font-size: 0.9rem;
            }

            .footer-social {
                display: flex;
                justify-content: center;
                gap: 20px;
                margin-bottom: 20px;
            }

            .footer-social a {
                width: 45px;
                height: 45px;
                background: rgba(255, 255, 255, 0.1);
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                color: var(--glow);
                text-decoration: none;
                transition: all 0.3s ease;
            }

            .footer-social a:hover {
                background: var(--glow);
                color: var(--primary-dark);
                transform: translateY(-5px);
            }

            /* ==================== ANIMATIONS ==================== */
            @keyframes fadeInUp {
                from {
                    opacity: 0;
                    transform: translateY(30px);
                }

                to {
                    opacity: 1;
                    transform: translateY(0);
                }
            }

            @keyframes fadeInDown {
                from {
                    opacity: 0;
                    transform: translateY(-30px);
                }

                to {
                    opacity: 1;
                    transform: translateY(0);
                }
            }

            /* ==================== RESPONSIVE ==================== */
            @media (max-width: 1200px) {
                .features-grid {
                    grid-template-columns: repeat(2, 1fr);
                }

                .stats-grid,
                .contact-grid {
                    grid-template-columns: repeat(2, 1fr);
                }
            }

            @media (max-width: 992px) {
                .sidebar {
                    width: 80px;
                    overflow: hidden;
                }

                .sidebar:hover {
                    width: 280px;
                }

                .sidebar-header {
                    padding: 20px 10px;
                }

                .logo h1,
                .logo p,
                .nav-item span {
                    opacity: 0;
                }

                .sidebar:hover .logo h1,
                .sidebar:hover .logo p,
                .sidebar:hover .nav-item span {
                    opacity: 1;
                }

                .logo-image,
                .logo-icon {
                    width: 50px;
                    height: 50px;
                }

                .sidebar:hover .logo-image,
                .sidebar:hover .logo-icon {
                    width: 100px;
                    height: 100px;
                }

                .main-content {
                    margin-left: 80px;
                }

                .hero-title {
                    font-size: 3rem;
                }
            }

            @media (max-width: 768px) {
                .sidebar {
                    transform: translateX(-100%);
                    transition: transform 0.3s ease;
                    width: 280px;
                }

                .sidebar.active {
                    transform: translateX(0);
                }

                .main-content {
                    margin-left: 0;
                }

                /* Mobile Header */
                .mobile-header {
                    display: flex;
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    height: 70px;
                    background: var(--gradient-3);
                    z-index: 999;
                    align-items: center;
                    justify-content: space-between;
                    padding: 0 20px;
                    box-shadow: 0 2px 20px rgba(0, 0, 0, 0.3);
                }

                .mobile-logo {
                    display: flex;
                    align-items: center;
                    gap: 10px;
                    color: var(--white);
                    text-decoration: none;
                }

                .mobile-logo-icon {
                    width: 45px;
                    height: 45px;
                    background: var(--gradient-2);
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    border: 2px solid var(--glow);
                    animation: logo-glow-pulse 2s ease-in-out infinite;
                }

                .mobile-logo-icon i {
                    font-size: 1.3rem;
                    color: var(--white);
                }

                .mobile-logo span {
                    font-weight: 700;
                    font-size: 1.1rem;
                }

                .hamburger {
                    width: 35px;
                    height: 30px;
                    display: flex;
                    flex-direction: column;
                    justify-content: space-between;
                    cursor: pointer;
                    z-index: 1001;
                }

                .hamburger span {
                    display: block;
                    width: 100%;
                    height: 4px;
                    background: var(--glow);
                    border-radius: 2px;
                    transition: all 0.3s ease;
                }

                .hamburger.active span:nth-child(1) {
                    transform: rotate(45deg) translate(8px, 8px);
                }

                .hamburger.active span:nth-child(2) {
                    opacity: 0;
                }

                .hamburger.active span:nth-child(3) {
                    transform: rotate(-45deg) translate(8px, -8px);
                }

                .mobile-overlay {
                    display: none;
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: rgba(0, 0, 0, 0.5);
                    z-index: 998;
                }

                .mobile-overlay.active {
                    display: block;
                }

                .hero-section {
                    padding-top: 70px;
                }

                .hero-content {
                    width: 90%;
                    padding: 0 15px;
                }

                .hero-title {
                    font-size: 2rem;
                    line-height: 1.2;
                }

                .hero-subtitle {
                    font-size: 0.95rem;
                    margin-bottom: 30px;
                }

                .hero-badge {
                    font-size: 0.7rem;
                    padding: 8px 15px;
                    letter-spacing: 2px;
                }

                .hero-buttons {
                    flex-direction: column;
                    align-items: center;
                    gap: 15px;
                }

                .btn-hero {
                    padding: 12px 30px;
                    font-size: 0.9rem;
                    width: 100%;
                    max-width: 250px;
                    justify-content: center;
                }

                .slide-indicators {
                    bottom: 20px;
                    gap: 8px;
                }

                .indicator {
                    width: 30px;
                    height: 3px;
                }

                .features-section,
                .rooms-section,
                .stats-section,
                .testimonials-section,
                .contact-section {
                    padding: 60px 15px;
                }

                .section-header {
                    margin-bottom: 40px;
                }

                .section-badge {
                    font-size: 0.7rem;
                    padding: 6px 15px;
                }

                .section-title {
                    font-size: 1.8rem;
                }

                .section-subtitle {
                    font-size: 0.95rem;
                }

                .features-grid,
                .stats-grid,
                .contact-grid {
                    grid-template-columns: 1fr;
                    gap: 20px;
                }

                .feature-card {
                    padding: 30px 20px;
                }

                .feature-icon {
                    width: 65px;
                    height: 65px;
                }

                .feature-icon i {
                    font-size: 1.6rem;
                }

                .feature-card h3 {
                    font-size: 1.1rem;
                }

                .rooms-grid {
                    grid-template-columns: 1fr;
                }

                .room-card {
                    max-width: 100%;
                }

                .room-image {
                    height: 180px;
                }

                .room-content {
                    padding: 20px;
                }

                .room-type {
                    font-size: 1.2rem;
                }

                .room-price .amount {
                    font-size: 1.6rem;
                }

                .stat-card {
                    padding: 30px 15px;
                }

                .stat-number {
                    font-size: 2.2rem;
                }

                .stat-label {
                    font-size: 0.75rem;
                }

                .testimonial-card {
                    padding: 30px 20px;
                }

                .testimonial-text {
                    font-size: 1rem;
                }

                .contact-card {
                    padding: 30px 20px;
                }

                .contact-icon {
                    width: 55px;
                    height: 55px;
                }

                .contact-icon i {
                    font-size: 1.4rem;
                }

                .contact-card h3 {
                    font-size: 1rem;
                }

                .contact-card p {
                    font-size: 0.9rem;
                }

                .footer {
                    padding: 30px 15px;
                }

                .footer-social {
                    gap: 12px;
                }

                .footer-social a {
                    width: 40px;
                    height: 40px;
                }

                .footer p {
                    font-size: 0.8rem;
                }
            }

            @media (max-width: 480px) {
                .hero-title {
                    font-size: 1.6rem;
                }

                .hero-subtitle {
                    font-size: 0.85rem;
                }

                .section-title {
                    font-size: 1.5rem;
                }

                .btn-hero {
                    padding: 10px 25px;
                    font-size: 0.85rem;
                }

                .stats-grid {
                    grid-template-columns: repeat(2, 1fr);
                    gap: 15px;
                }

                .stat-card {
                    padding: 20px 10px;
                }

                .stat-icon {
                    width: 50px;
                    height: 50px;
                }

                .stat-icon i {
                    font-size: 1.3rem;
                }

                .stat-number {
                    font-size: 1.8rem;
                }

                .room-amenities span {
                    font-size: 0.7rem;
                    padding: 4px 8px;
                }
            }

            /* Hide mobile header on desktop */
            .mobile-header {
                display: none;
            }

            .mobile-overlay {
                display: none;
            }
        </style>
    </head>

    <body>
        <!-- Mobile Header -->
        <header class="mobile-header">
            <a href="#" class="mobile-logo">
                <div class="mobile-logo-icon">
                    <i class="fas fa-hotel"></i>
                </div>
                <span>Ocean View Resort</span>
            </a>
            <div class="hamburger" onclick="toggleMobileMenu()">
                <span></span>
                <span></span>
                <span></span>
            </div>
        </header>

        <!-- Mobile Overlay -->
        <div class="mobile-overlay" onclick="toggleMobileMenu()"></div>

        <!-- Left Sidebar -->
        <aside class="sidebar">
            <div class="sidebar-header">
                <a href="#" class="logo">
                    <img src="${pageContext.request.contextPath}/images/logo.png" alt="Ocean View Resort"
                        class="logo-image"
                        onerror="this.style.display='none'; document.querySelector('.logo-icon').style.display='flex';">
                    <div class="logo-icon" style="display: none;">
                        <i class="fas fa-hotel"></i>
                    </div>
                    <h1>Ocean View Resort</h1>
                    <p>Galle, Sri Lanka</p>
                </a>
            </div>

            <nav class="sidebar-nav">
                <a href="#home" class="nav-item active">
                    <i class="fas fa-home"></i>
                    <span>Home</span>
                </a>
                <a href="#features" class="nav-item">
                    <i class="fas fa-star"></i>
                    <span>Features</span>
                </a>
                <a href="#rooms" class="nav-item">
                    <i class="fas fa-bed"></i>
                    <span>Rooms</span>
                </a>
                <a href="#testimonials" class="nav-item">
                    <i class="fas fa-quote-left"></i>
                    <span>Reviews</span>
                </a>
                <a href="#contact" class="nav-item">
                    <i class="fas fa-envelope"></i>
                    <span>Contact</span>
                </a>

                <div class="nav-divider"></div>

                <a href="${pageContext.request.contextPath}/help-staff.jsp" class="nav-item">
                    <i class="fas fa-life-ring"></i>
                    <span>Staff Help</span>
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
            <!-- Hero Section with Auto-Sliding Images -->
            <section class="hero-section" id="home">
                <div class="slider-container">

                    <div class="slide active"
                        style="background-image:url('${pageContext.request.contextPath}/images/resort-1.jpg');"></div>

                    <div class="slide"
                        style="background-image:url('${pageContext.request.contextPath}/images/resort-2.jpg');"></div>

                    <div class="slide"
                        style="background-image:url('${pageContext.request.contextPath}/images/resort-3.jpg');"></div>

                    <div class="slide"
                        style="background-image:url('${pageContext.request.contextPath}/images/resort-4.jpg');"></div>

                    <div class="slide"
                        style="background-image:url('${pageContext.request.contextPath}/images/resort-5.jpg');"></div>

                </div>

                <div class="hero-content">
                    <div class="hero-badge">
                        <i class="fas fa-star"></i> 5-Star Luxury Resort
                    </div>
                    <h1 class="hero-title">
                        Experience <span>Paradise</span><br>By The Ocean
                    </h1>
                    <p class="hero-subtitle">
                        Discover the ultimate beachfront luxury in historic Galle, Sri Lanka.
                        Where tropical elegance meets world-class hospitality.
                    </p>
                    <div class="hero-buttons">
                        <a href="#rooms" class="btn-hero btn-primary-hero">
                            <i class="fas fa-calendar-check"></i> Book Now
                        </a>
                        <a href="#features" class="btn-hero btn-secondary-hero">
                            <i class="fas fa-play"></i> Explore More
                        </a>
                        <a href="${pageContext.request.contextPath}/login.jsp?role=staff" class="btn-hero btn-secondary-hero">
                            <i class="fas fa-user"></i> Staff Login
                        </a>
                        <a href="${pageContext.request.contextPath}/login.jsp?role=admin" class="btn-hero btn-secondary-hero">
                            <i class="fas fa-user-shield"></i> Admin Login
                        </a>
                    </div>
                </div>

                <div class="slide-indicators">
                    <div class="indicator active">
                        <div class="progress"></div>
                    </div>
                    <div class="indicator">
                        <div class="progress"></div>
                    </div>
                    <div class="indicator">
                        <div class="progress"></div>
                    </div>
                    <div class="indicator">
                        <div class="progress"></div>
                    </div>
                    <div class="indicator">
                        <div class="progress"></div>
                    </div>
                </div>
            </section>

            <!-- Features Section -->
            <section class="features-section" id="features">
                <div class="section-header">
                    <span class="section-badge">Why Choose Us</span>
                    <h2 class="section-title">World-Class Amenities</h2>
                    <p class="section-subtitle">
                        Immerse yourself in luxury with our exceptional facilities and services
                    </p>
                </div>

                <div class="features-grid">
                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-water"></i>
                        </div>
                        <h3>Infinity Pool</h3>
                        <p>Stunning oceanfront infinity pool with panoramic views of the Indian Ocean sunset</p>
                    </div>

                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-spa"></i>
                        </div>
                        <h3>Luxury Spa</h3>
                        <p>Rejuvenate with traditional Ayurvedic treatments and modern wellness therapies</p>
                    </div>

                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-utensils"></i>
                        </div>
                        <h3>Fine Dining</h3>
                        <p>Exquisite culinary experiences with fresh seafood and international cuisine</p>
                    </div>

                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-umbrella-beach"></i>
                        </div>
                        <h3>Private Beach</h3>
                        <p>Exclusive beach access with premium sunbeds and personalized service</p>
                    </div>

                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-wifi"></i>
                        </div>
                        <h3>Free High-Speed WiFi</h3>
                        <p>Stay connected throughout your stay with complimentary premium internet</p>
                    </div>

                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-concierge-bell"></i>
                        </div>
                        <h3>24/7 Concierge</h3>
                        <p>Dedicated concierge team ready to fulfill your every request anytime</p>
                    </div>
                </div>
            </section>

            <!-- Rooms Section -->
            <section class="rooms-section" id="rooms">
                <div class="section-header">
                    <span class="section-badge">Accommodations</span>
                    <h2 class="section-title">Our Luxury Rooms</h2>
                    <p class="section-subtitle">
                        Choose from our elegantly designed rooms and suites
                    </p>
                </div>

                <div class="rooms-grid">
                    <div class="room-card">
                        <div class="room-image">
                            <img src="${pageContext.request.contextPath}/images/room-standard.jpg" alt="Standard Room"
                                onerror="this.style.display='none'; this.nextElementSibling.style.display='block';">
                            <i class="fas fa-bed" style="display: none;"></i>
                            <span class="room-badge">Popular</span>
                        </div>
                        <div class="room-content">
                            <h3 class="room-type">Standard Room</h3>
                            <div class="room-amenities">
                                <span><i class="fas fa-wind"></i> AC</span>
                                <span><i class="fas fa-tv"></i> TV</span>
                                <span><i class="fas fa-wifi"></i> WiFi</span>
                            </div>
                            <div class="room-price">
                                <span class="amount">Rs. 15,000</span>
                                <span class="period">/ night</span>
                            </div>
                        </div>
                    </div>

                    <div class="room-card">
                        <div class="room-image">
                            <img src="${pageContext.request.contextPath}/images/room-deluxe.jpg" alt="Deluxe Room"
                                onerror="this.style.display='none'; this.nextElementSibling.style.display='block';">
                            <i class="fas fa-bed" style="display: none;"></i>
                            <span class="room-badge">Best Value</span>
                        </div>
                        <div class="room-content">
                            <h3 class="room-type">Deluxe Room</h3>
                            <div class="room-amenities">
                                <span><i class="fas fa-wind"></i> AC</span>
                                <span><i class="fas fa-tv"></i> TV</span>
                                <span><i class="fas fa-water"></i> Ocean View</span>
                            </div>
                            <div class="room-price">
                                <span class="amount">Rs. 25,000</span>
                                <span class="period">/ night</span>
                            </div>
                        </div>
                    </div>

                    <div class="room-card">
                        <div class="room-image">
                            <img src="${pageContext.request.contextPath}/images/room-suite.webp" alt="Suite"
                                onerror="this.style.display='none'; this.nextElementSibling.style.display='block';">
                            <i class="fas fa-bed" style="display: none;"></i>
                            <span class="room-badge">Luxury</span>
                        </div>
                        <div class="room-content">
                            <h3 class="room-type">Suite</h3>
                            <div class="room-amenities">
                                <span><i class="fas fa-hot-tub"></i> Jacuzzi</span>
                                <span><i class="fas fa-couch"></i> Living Room</span>
                                <span><i class="fas fa-water"></i> Ocean View</span>
                            </div>
                            <div class="room-price">
                                <span class="amount">Rs. 40,000</span>
                                <span class="period">/ night</span>
                            </div>
                        </div>
                    </div>

                    <div class="room-card">
                        <div class="room-image">
                            <img src="${pageContext.request.contextPath}/images/room-presidential.webp"
                                alt="Presidential Suite"
                                onerror="this.style.display='none'; this.nextElementSibling.style.display='block';">
                            <i class="fas fa-bed" style="display: none;"></i>
                            <span class="room-badge">Premium</span>
                        </div>
                        <div class="room-content">
                            <h3 class="room-type">Presidential Suite</h3>
                            <div class="room-amenities">
                                <span><i class="fas fa-swimming-pool"></i> Private Pool</span>
                                <span><i class="fas fa-user-tie"></i> Butler</span>
                                <span><i class="fas fa-utensils"></i> Dining Area</span>
                            </div>
                            <div class="room-price">
                                <span class="amount">Rs. 75,000</span>
                                <span class="period">/ night</span>
                            </div>
                        </div>
                    </div>

                    <div class="room-card">
                        <div class="room-image">
                            <img src="${pageContext.request.contextPath}/images/room-family.jpg" alt="Family Room"
                                onerror="this.style.display='none'; this.nextElementSibling.style.display='block';">
                            <i class="fas fa-bed" style="display: none;"></i>
                            <span class="room-badge">Family</span>
                        </div>
                        <div class="room-content">
                            <h3 class="room-type">Family Room</h3>
                            <div class="room-amenities">
                                <span><i class="fas fa-child"></i> Kids Area</span>
                                <span><i class="fas fa-bed"></i> Extra Beds</span>
                                <span><i class="fas fa-wifi"></i> WiFi</span>
                            </div>
                            <div class="room-price">
                                <span class="amount">Rs. 30,000</span>
                                <span class="period">/ night</span>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <!-- Stats Section -->
            <section class="stats-section">
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-icon">
                            <i class="fas fa-bed"></i>
                        </div>
                        <div class="stat-number">50+</div>
                        <div class="stat-label">Luxury Rooms</div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-icon">
                            <i class="fas fa-users"></i>
                        </div>
                        <div class="stat-number">10K+</div>
                        <div class="stat-label">Happy Guests</div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-icon">
                            <i class="fas fa-award"></i>
                        </div>
                        <div class="stat-number">15+</div>
                        <div class="stat-label">Awards Won</div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-icon">
                            <i class="fas fa-star"></i>
                        </div>
                        <div class="stat-number">4.9</div>
                        <div class="stat-label">Guest Rating</div>
                    </div>
                </div>
            </section>

            <!-- Testimonials Section -->
            <section class="testimonials-section" id="testimonials">
                <div class="section-header">
                    <span class="section-badge">Testimonials</span>
                    <h2 class="section-title">What Our Guests Say</h2>
                </div>

                <div class="testimonials-slider">
                    <div class="testimonial-card">
                        <div class="stars">
                            <i class="fas fa-star"></i>
                            <i class="fas fa-star"></i>
                            <i class="fas fa-star"></i>
                            <i class="fas fa-star"></i>
                            <i class="fas fa-star"></i>
                        </div>
                        <p class="testimonial-text">
                            "An absolutely breathtaking experience! The ocean view from our suite was incredible,
                            and the staff went above and beyond to make our honeymoon unforgettable."
                        </p>
                        <div class="testimonial-author">
                            <div class="author-avatar">JS</div>
                            <div class="author-info">
                                <h4>John & Sarah Smith</h4>
                                <p>Honeymoon Guests, UK</p>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <!-- Contact Section -->
            <section class="contact-section" id="contact">
                <div class="section-header">
                    <span class="section-badge">Get In Touch</span>
                    <h2 class="section-title">Contact Us</h2>
                    <p class="section-subtitle">
                        We'd love to hear from you. Reach out for reservations or inquiries.
                    </p>
                </div>

                <div class="contact-grid">
                    <div class="contact-card">
                        <div class="contact-icon">
                            <i class="fas fa-map-marker-alt"></i>
                        </div>
                        <h3>Location</h3>
                        <p>123 Beach Road<br>Galle, Sri Lanka</p>
                    </div>

                    <div class="contact-card">
                        <div class="contact-icon">
                            <i class="fas fa-phone"></i>
                        </div>
                        <h3>Phone</h3>
                        <p>+94 91 234 5678<br>+94 77 123 4567</p>
                    </div>

                    <div class="contact-card">
                        <div class="contact-icon">
                            <i class="fas fa-envelope"></i>
                        </div>
                        <h3>Email</h3>
                        <p>info@oceanviewresort.com<br>reservations@oceanviewresort.com</p>
                    </div>

                    <div class="contact-card">
                        <div class="contact-icon">
                            <i class="fas fa-clock"></i>
                        </div>
                        <h3>Reception</h3>
                        <p>Available 24/7<br>Check-in: 2:00 PM</p>
                    </div>
                </div>
            </section>

            <!-- Footer -->
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
            // Auto-sliding images - one by one animation (no buttons needed)
            let currentSlide = 0;
            const slides = document.querySelectorAll('.slide');
            const indicators = document.querySelectorAll('.indicator');
            const totalSlides = slides.length;

            function showSlide(index) {
                slides.forEach(slide => slide.classList.remove('active'));
                indicators.forEach(ind => ind.classList.remove('active'));

                currentSlide = index;
                if (currentSlide >= totalSlides) currentSlide = 0;
                if (currentSlide < 0) currentSlide = totalSlides - 1;

                slides[currentSlide].classList.add('active');
                indicators[currentSlide].classList.add('active');
            }

            function nextSlide() {
                showSlide(currentSlide + 1);
            }

            // Auto-advance every 3 seconds - automatic animation
            setInterval(nextSlide, 3000);

            // Click indicators to change slide
            indicators.forEach((indicator, index) => {
                indicator.addEventListener('click', () => showSlide(index));
            });

            // Smooth scroll for navigation
            document.querySelectorAll('a[href^="#"]').forEach(anchor => {
                anchor.addEventListener('click', function (e) {
                    e.preventDefault();
                    const target = document.querySelector(this.getAttribute('href'));
                    if (target) {
                        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
                    }
                    document.querySelectorAll('.nav-item').forEach(item => item.classList.remove('active'));
                    this.classList.add('active');
                });
            });

            // Intersection Observer for scroll animations
            const observerOptions = {
                threshold: 0.1,
                rootMargin: '0px 0px -50px 0px'
            };

            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('animate');
                    }
                });
            }, observerOptions);

            document.querySelectorAll('.feature-card, .room-card, .stat-card, .contact-card').forEach(el => {
                observer.observe(el);
            });

            // Update active nav on scroll
            window.addEventListener('scroll', () => {
                const sections = document.querySelectorAll('section[id]');
                let current = '';

                sections.forEach(section => {
                    const sectionTop = section.offsetTop - 200;
                    if (window.pageYOffset >= sectionTop) {
                        current = section.getAttribute('id');
                    }
                });

                document.querySelectorAll('.nav-item').forEach(item => {
                    item.classList.remove('active');
                    if (item.getAttribute('href') === '#' + current) {
                        item.classList.add('active');
                    }
                });
            });

            // Mobile Menu Toggle
            function toggleMobileMenu() {
                const sidebar = document.querySelector('.sidebar');
                const hamburger = document.querySelector('.hamburger');
                const overlay = document.querySelector('.mobile-overlay');

                sidebar.classList.toggle('active');
                hamburger.classList.toggle('active');
                overlay.classList.toggle('active');

                // Prevent body scroll when menu is open
                document.body.style.overflow = sidebar.classList.contains('active') ? 'hidden' : '';
            }

            // Close mobile menu when clicking nav items
            document.querySelectorAll('.sidebar .nav-item').forEach(item => {
                item.addEventListener('click', () => {
                    if (window.innerWidth <= 768) {
                        toggleMobileMenu();
                    }
                });
            });

            // Close mobile menu on resize to desktop
            window.addEventListener('resize', () => {
                if (window.innerWidth > 768) {
                    const sidebar = document.querySelector('.sidebar');
                    const hamburger = document.querySelector('.hamburger');
                    const overlay = document.querySelector('.mobile-overlay');

                    sidebar.classList.remove('active');
                    hamburger.classList.remove('active');
                    overlay.classList.remove('active');
                    document.body.style.overflow = '';
                }
            });
        </script>
    </body>

    </html>
