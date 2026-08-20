<?php
require_once 'config.php';
header('Content-Type: application/json');

$data = get_input();
$username  = trim($data['username'] ?? '');
$password  = $data['password'] ?? '';
$full_name = trim($data['full_name'] ?? '');
$bus_id    = $data['bus_id'] ?? null;
if ($bus_id === '' ) { $bus_id = null; }

if ($username === '' || $password === '' || $full_name === '') {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "username, password, full_name are required"]);
    exit();
}

// Check username isn't already taken
$check = $pdo->prepare("SELECT id FROM drivers WHERE username = ?");
$check->execute([$username]);
if ($check->fetch()) {
    http_response_code(409);
    echo json_encode(["status" => "error", "message" => "Username already exists"]);
    exit();
}

$hash = password_hash($password, PASSWORD_DEFAULT);

$stmt = $pdo->prepare("INSERT INTO drivers (username, password_hash, full_name, bus_id) VALUES (?, ?, ?, ?)");
$stmt->execute([$username, $hash, $full_name, $bus_id]);

echo json_encode(["status" => "ok", "driver_id" => $pdo->lastInsertId()]);
