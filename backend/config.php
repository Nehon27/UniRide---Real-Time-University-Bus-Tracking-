<?php
// ============================================
// UniRide - Database Configuration
// Edit these values to match your local MySQL setup
// (defaults below match a fresh XAMPP / Laragon install)
// ============================================

$DB_HOST = "localhost";
$DB_NAME = "uniride";
$DB_USER = "root";
$DB_PASS = "";

// Allow requests from the admin panel / viewer page / Flutter app.
// For a local student project, allowing all origins is fine.
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $pdo = new PDO(
        "mysql:host=$DB_HOST;dbname=$DB_NAME;charset=utf8mb4",
        $DB_USER,
        $DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (PDOException $e) {
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode(["status" => "error", "message" => "Database connection failed. Check config.php"]);
    exit();
}

// Small helper to read JSON body OR form-encoded POST, whichever was sent
function get_input() {
    $raw = file_get_contents('php://input');
    $json = json_decode($raw, true);
    if (is_array($json)) {
        return $json;
    }
    return $_POST;
}
