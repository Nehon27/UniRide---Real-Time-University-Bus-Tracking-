<?php
require_once 'config.php';
header('Content-Type: application/json');

$data = get_input();
$driver_id = $data['driver_id'] ?? null;

if (!$driver_id) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "driver_id is required"]);
    exit();
}

$stmt = $pdo->prepare("INSERT INTO driver_status (driver_id, is_active, last_seen)
                        VALUES (?, 0, NOW())
                        ON DUPLICATE KEY UPDATE is_active = 0, last_seen = NOW()");
$stmt->execute([$driver_id]);

echo json_encode(["status" => "ok"]);
