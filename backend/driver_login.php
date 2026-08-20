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

$stmt = $pdo->prepare("SELECT d.id, d.password_hash, d.full_name, d.bus_id, b.bus_name
                        FROM drivers d
                        LEFT JOIN buses b ON d.bus_id = b.id
                        WHERE d.username = ?");
$stmt->execute([$username]);
$driver = $stmt->fetch();

if ($driver && password_verify($password, $driver['password_hash'])) {
    echo json_encode([
        "status" => "ok",
        "driver_id" => $driver['id'],
        "full_name" => $driver['full_name'],
        "bus_id" => $driver['bus_id'],
        "bus_name" => $driver['bus_name']
    ]);
} else {
    http_response_code(401);
    echo json_encode(["status" => "error", "message" => "Invalid username or password"]);
}
