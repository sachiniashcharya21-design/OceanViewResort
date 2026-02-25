<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>500 - Server Error | Ocean View Resort</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #e53e3e 0%, #c53030 100%);
        }
        .error-container {
            text-align: center;
            padding: 60px;
            background: white;
            border-radius: 20px;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
            max-width: 500px;
        }
        .error-code {
            font-size: 8rem;
            font-weight: 800;
            color: #e53e3e;
            line-height: 1;
            margin-bottom: 10px;
            text-shadow: 3px 3px 0 #fed7d7;
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
            color: #e53e3e;
            margin-bottom: 20px;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.1); }
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
            margin-right: 10px;
        }
        .btn-home:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 25px rgba(0, 119, 182, 0.4);
        }
        .btn-retry {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 15px 30px;
            background: linear-gradient(135deg, #38a169 0%, #276749 100%);
            color: white;
            text-decoration: none;
            border-radius: 50px;
            font-weight: 600;
            transition: transform 0.3s, box-shadow 0.3s;
            border: none;
            cursor: pointer;
            font-size: 1rem;
        }
        .btn-retry:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 25px rgba(56, 161, 105, 0.4);
        }
        .buttons {
            display: flex;
            gap: 15px;
            justify-content: center;
            flex-wrap: wrap;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">
            <i class="fas fa-exclamation-triangle"></i>
        </div>
        <div class="error-code">500</div>
        <h1 class="error-title">Internal Server Error</h1>
        <p class="error-message">
            Something went wrong on our end. Our team has been notified and we're working to fix it.
            Please try again in a few moments.
        </p>
        <div class="buttons">
            <a href="${pageContext.request.contextPath}/login" class="btn-home">
                <i class="fas fa-home"></i> Go Home
            </a>
            <button onclick="location.reload()" class="btn-retry">
                <i class="fas fa-redo"></i> Try Again
            </button>
        </div>
    </div>
</body>
</html>
