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

$stmt = $pdo->prepare("DELETE FROM drivers WHERE id = ?");
$stmt->execute([$driver_id]);
echo json_encode(["status" => "ok"]);
