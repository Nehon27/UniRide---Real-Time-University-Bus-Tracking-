<?php
require_once 'config.php';
header('Content-Type: application/json');

$data = get_input();
$driver_id = $data['driver_id'] ?? null;
$lat = $data['lat'] ?? null;
$lng = $data['lng'] ?? null;

if (!$driver_id || $lat === null || $lng === null) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "driver_id, lat, lng are required"]);
    exit();
}

// Confirm driver exists
$check = $pdo->prepare("SELECT id FROM drivers WHERE id = ?");
$check->execute([$driver_id]);
if (!$check->fetch()) {
    http_response_code(404);
    echo json_encode(["status" => "error", "message" => "Unknown driver_id"]);
    exit();
}

$stmt = $pdo->prepare("INSERT INTO driver_locations (driver_id, latitude, longitude, recorded_at) VALUES (?, ?, ?, NOW())");
$stmt->execute([$driver_id, $lat, $lng]);

// Upsert driver_status so we know who is currently "active"
$stmt2 = $pdo->prepare("INSERT INTO driver_status (driver_id, is_active, last_seen)
                         VALUES (?, 1, NOW())
                         ON DUPLICATE KEY UPDATE is_active = 1, last_seen = NOW()");
$stmt2->execute([$driver_id]);

echo json_encode(["status" => "ok"]);
