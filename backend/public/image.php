<?php
/**
 * Serve uploaded images with CORS headers.
 * Use only for files inside the uploads directory.
 */

declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$path = $_GET['path'] ?? '';
$path = trim((string) $path);

if ($path === '' || strpos($path, '..') !== false) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid path']);
    exit;
}

$uploadsDir = __DIR__ . '/uploads/';
$filePath = realpath($uploadsDir . ltrim($path, '/'));

if ($filePath === false || strncmp($filePath, realpath($uploadsDir), strlen(realpath($uploadsDir))) !== 0) {
    http_response_code(404);
    echo json_encode(['error' => 'File not found']);
    exit;
}

if (!is_file($filePath)) {
    http_response_code(404);
    echo json_encode(['error' => 'File not found']);
    exit;
}

$mimeType = mime_content_type($filePath) ?: 'application/octet-stream';
header('Content-Type: ' . $mimeType);
readfile($filePath);
