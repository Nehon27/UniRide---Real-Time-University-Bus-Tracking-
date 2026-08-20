<?php
require_once 'config.php';
header('Content-Type: application/json');

$data = get_input();
$bus_id = $data['bus_id'] ?? null;

if (!$bus_id) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "bus_id is required"]);
    exit();
}

$stmt = $pdo->prepare("DELETE FROM buses WHERE id = ?");
$stmt->execute([$bus_id]);
echo json_encode(["status" => "ok"]);
