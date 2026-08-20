<?php
require_once 'config.php';
header('Content-Type: application/json');

$sql = "SELECT b.id, b.bus_name, b.created_at,
               d.id AS driver_id, d.full_name AS driver_name
        FROM buses b
        LEFT JOIN drivers d ON d.bus_id = b.id
        ORDER BY b.id DESC";
$rows = $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);
echo json_encode(["status" => "ok", "buses" => $rows]);
