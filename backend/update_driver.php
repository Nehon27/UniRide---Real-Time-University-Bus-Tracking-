<?php
require_once 'config.php';
header('Content-Type: application/json');

$data = get_input();
$driver_id = $data['driver_id'] ?? null;
$full_name = trim($data['full_name'] ?? '');
$bus_id    = $data['bus_id'] ?? null;
if ($bus_id === '') { $bus_id = null; }

if (!$driver_id || $full_name === '') {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "driver_id and full_name are required"]);
    exit();
}

$stmt = $pdo->prepare("UPDATE drivers SET full_name = ?, bus_id = ? WHERE id = ?");
$stmt->execute([$full_name, $bus_id, $driver_id]);

echo json_encode(["status" => "ok"]);
