<?php
require_once 'config.php';
header('Content-Type: application/json');

// Only show drivers who have sent a location in the last 2 minutes
// and are currently marked active (so a closed app disappears from the map)
$sql = "SELECT
            dl.driver_id,
            d.full_name,
            b.bus_name,
            dl.latitude,
            dl.longitude,
            dl.recorded_at
        FROM driver_locations dl
        INNER JOIN (
            SELECT driver_id, MAX(id) AS latest_id
            FROM driver_locations
            GROUP BY driver_id
        ) latest_dl ON dl.id = latest_dl.latest_id
        JOIN drivers d ON d.id = dl.driver_id
        LEFT JOIN buses b ON d.bus_id = b.id
        JOIN driver_status ds ON ds.driver_id = dl.driver_id
        WHERE ds.is_active = 1
          AND dl.recorded_at >= (NOW() - INTERVAL 2 MINUTE)
        ORDER BY b.bus_name";

$rows = $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);
echo json_encode(["status" => "ok", "buses" => $rows]);
