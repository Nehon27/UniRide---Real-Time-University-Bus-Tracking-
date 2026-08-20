<?php
require_once 'config.php';
header('Content-Type: application/json');

$sql = "SELECT d.id, d.username, d.full_name, d.bus_id, b.bus_name,
               ds.is_active, ds.last_seen
        FROM drivers d
        LEFT JOIN buses b ON d.bus_id = b.id
        LEFT JOIN driver_status ds ON ds.driver_id = d.id
        ORDER BY d.id DESC";
$rows = $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);
echo json_encode(["status" => "ok", "drivers" => $rows]);
