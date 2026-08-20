<?php
require_once 'config.php';
header('Content-Type: application/json');

$data = get_input();
$username = trim($data['username'] ?? '');
$password = $data['password'] ?? '';

if ($username === '' || $password === '') {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Username and password required"]);
    exit();
}

$stmt = $pdo->prepare("SELECT id, password_hash FROM admins WHERE username = ?");
$stmt->execute([$username]);
$admin = $stmt->fetch();

if ($admin && password_verify($password, $admin['password_hash'])) {
    echo json_encode(["status" => "ok", "admin_id" => $admin['id'], "username" => $username]);
} else {
    http_response_code(401);
    echo json_encode(["status" => "error", "message" => "Invalid username or password"]);
}
