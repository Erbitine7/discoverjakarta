<?php
// Router script for PHP built-in server.
// Serves existing static files with CORS headers and forwards other requests to index.php.

declare(strict_types=1);

if (php_sapi_name() === 'cli-server') {
    $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $file = __DIR__ . $uri;

    if ($uri !== '/' && file_exists($file) && is_file($file)) {
        $mimeType = mime_content_type($file) ?: 'application/octet-stream';
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization');
        header('Content-Type: ' . $mimeType);
        readfile($file);
        return true;
    }
}

require __DIR__ . '/index.php';
