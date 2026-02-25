<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error | Ocean View Resort</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #718096 0%, #4a5568 100%);
        }
        .error-container {
            text-align: center;
            padding: 60px;
            background: white;
            border-radius: 20px;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
            max-width: 500px;
        }
        .error-title {
            font-size: 1.8rem;
            color: #2d3748;
            margin-bottom: 15px;
        }
        .error-message {
            color: #718096;
            margin-bottom: 30px;
            font-size: 1.1rem;
        }
        .error-icon {
            font-size: 5rem;
            color: #718096;
            margin-bottom: 20px;
        }
        .btn-home {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 15px 30px;
            background: linear-gradient(135deg, #0077b6 0%, #023e8a 100%);
            color: white;
            text-decoration: none;
            border-radius: 50px;
            font-weight: 600;
            transition: transform 0.3s, box-shadow 0.3s;
        }
        .btn-home:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 25px rgba(0, 119, 182, 0.4);
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">
            <i class="fas fa-frown"></i>
        </div>
        <h1 class="error-title">Oops! Something Went Wrong</h1>
        <p class="error-message">
            We encountered an unexpected error. Please try again or contact support if the problem persists.
        </p>
        <a href="${pageContext.request.contextPath}/login" class="btn-home">
            <i class="fas fa-home"></i> Return to Home
        </a>
    </div>
</body>
</html>
