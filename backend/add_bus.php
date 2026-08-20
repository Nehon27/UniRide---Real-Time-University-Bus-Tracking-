<?php
require_once 'config.php';
header('Content-Type: application/json');

$data = get_input();
$bus_name = trim($data['bus_name'] ?? '');

if ($bus_name === '') {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "bus_name is required"]);
    exit();
}

$stmt = $pdo->prepare("INSERT INTO buses (bus_name) VALUES (?)");
$stmt->execute([$bus_name]);

echo json_encode(["status" => "ok", "bus_id" => $pdo->lastInsertId()]);
