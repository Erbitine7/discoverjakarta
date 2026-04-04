<?php
/**
 * Discover Jakarta — minimal API for the Flutter app.
 * Run with Apache/XAMPP (point document root here) or:
 *   php -S 127.0.0.1:8080 -t public
 *
 * Copy ../config.sample.php to ../config.php and edit DB settings.
 */

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$configPath = dirname(__DIR__) . '/config.php';
if (!is_readable($configPath)) {
    http_response_code(500);
    echo json_encode(['error' => 'Missing backend/config.php — copy config.sample.php to config.php']);
    exit;
}
$config = require $configPath;
$dbCfg = $config['db'];

$dsn = sprintf(
    'mysql:host=%s;port=%s;dbname=%s;charset=%s',
    $dbCfg['host'],
    $dbCfg['port'] ?? '3306',
    $dbCfg['name'],
    $dbCfg['charset'] ?? 'utf8mb4'
);

try {
    $pdo = new PDO($dsn, $dbCfg['user'], $dbCfg['pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    error_log('Database connection error: ' . $e->getMessage());
    echo json_encode(['error' => 'Database connection failed']);
    exit;
}

function json_input(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === false || $raw === '') {
        return [];
    }
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function bearer_token(): ?string
{
    $h = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['Authorization'] ?? '';
    if (preg_match('/Bearer\s+(\S+)/i', $h, $m)) {
        return $m[1];
    }
    return null;
}

function require_auth(PDO $pdo): array
{
    $token = bearer_token();
    if (!$token || strlen($token) !== 64) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized']);
        exit;
    }
    $st = $pdo->prepare(
        'SELECT a.id, a.username FROM sessions s
         JOIN account a ON a.id = s.account_id
         WHERE s.token = ? AND s.expires_at > NOW() LIMIT 1'
    );
    $st->execute([$token]);
    $row = $st->fetch();
    if (!$row) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized']);
        exit;
    }
    return $row;
}

$action = $_GET['action'] ?? '';
$method = $_SERVER['REQUEST_METHOD'];

try {
    if ($action === 'locations' && $method === 'GET') {
        $rows = $pdo->query('SELECT id, slug, name, sort_order FROM locations ORDER BY sort_order, name')->fetchAll();
        echo json_encode(['data' => $rows]);
        exit;
    }

    if ($action === 'categories' && $method === 'GET') {
        $rows = $pdo->query('SELECT id, name, slug FROM categories ORDER BY name')->fetchAll();
        echo json_encode(['data' => $rows]);
        exit;
    }

    if ($action === 'pois' && $method === 'GET') {
        $slug = $_GET['location'] ?? '';
        if ($slug === '') {
            http_response_code(400);
            echo json_encode(['error' => 'location slug required']);
            exit;
        }
        $loc = $pdo->prepare('SELECT id FROM locations WHERE slug = ? LIMIT 1');
        $loc->execute([$slug]);
        $locRow = $loc->fetch();
        if (!$locRow) {
            http_response_code(404);
            echo json_encode(['error' => 'Location not found']);
            exit;
        }
        $locationId = (int) $locRow['id'];

        $search = trim((string) ($_GET['q'] ?? ''));
        $categoryId = $_GET['category_id'] ?? '';
        $params = [$locationId];
        $sql = 'SELECT p.id, l.slug AS location_slug, p.title AS name, p.description, p.address, p.image_url,
                c.id AS category_id, c.name AS category_name
                FROM poi p
                JOIN locations l ON l.id = p.location_id
                JOIN categories c ON c.id = p.category_id
                WHERE p.location_id = ?';

        if ($categoryId !== '' && ctype_digit((string) $categoryId)) {
            $sql .= ' AND p.category_id = ?';
            $params[] = (int) $categoryId;
        }

        if ($search !== '') {
            $sql .= ' AND (p.title LIKE ? OR p.description LIKE ? OR p.address LIKE ?)';
            $like = '%' . $search . '%';
            $params[] = $like;
            $params[] = $like;
            $params[] = $like;
        }

        $sql .= ' ORDER BY p.created_at DESC';
        $st = $pdo->prepare($sql);
        $st->execute($params);
        echo json_encode(['data' => $st->fetchAll()]);
        exit;
    }

    if ($action === 'poi' && $method === 'GET') {
        $id = $_GET['id'] ?? '';
        if ($id === '' || !ctype_digit((string) $id)) {
            http_response_code(400);
            echo json_encode(['error' => 'id required']);
            exit;
        }
        $st = $pdo->prepare(
            'SELECT p.id, l.slug AS location_slug, p.title AS name, p.description, p.address, p.image_url,
             c.id AS category_id, c.name AS category_name
             FROM poi p
             JOIN locations l ON l.id = p.location_id
             JOIN categories c ON c.id = p.category_id
             WHERE p.id = ? LIMIT 1'
        );
        $st->execute([(int) $id]);
        $row = $st->fetch();
        if (!$row) {
            http_response_code(404);
            echo json_encode(['error' => 'Not found']);
            exit;
        }
        echo json_encode(['data' => $row]);
        exit;
    }

    if ($action === 'login' && $method === 'POST') {
        $in = json_input();
        $user = trim((string) ($in['username'] ?? ''));
        $pass = (string) ($in['password'] ?? '');
        if ($user === '' || $pass === '') {
            http_response_code(400);
            echo json_encode(['error' => 'username and password required']);
            exit;
        }
        $st = $pdo->prepare('SELECT id, password_hash FROM account WHERE username = ? LIMIT 1');
        $st->execute([$user]);
        $acc = $st->fetch();
        if (!$acc || !password_verify($pass, $acc['password_hash'])) {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid credentials']);
            exit;
        }
        $accountId = (int) $acc['id'];
        $pdo->prepare('DELETE FROM sessions WHERE account_id = ?')->execute([$accountId]);
        $token = bin2hex(random_bytes(32));
        $expires = (new DateTimeImmutable('+30 days'))->format('Y-m-d H:i:s');
        $ins = $pdo->prepare('INSERT INTO sessions (account_id, token, expires_at) VALUES (?, ?, ?)');
        $ins->execute([$accountId, $token, $expires]);
        echo json_encode(['token' => $token, 'username' => $user]);
        exit;
    }

    if ($action === 'logout' && $method === 'POST') {
        $token = bearer_token();
        if ($token) {
            $pdo->prepare('DELETE FROM sessions WHERE token = ?')->execute([$token]);
        }
        echo json_encode(['ok' => true]);
        exit;
    }

    if ($action === 'poi' && $method === 'POST') {
        require_auth($pdo);
        $id = (int) ($_POST['id'] ?? 0);
        $catId = (int) ($_POST['category_id'] ?? 0);
        $title = trim((string) ($_POST['title'] ?? ''));
        $description = trim((string) ($_POST['description'] ?? ''));
        $address = trim((string) ($_POST['address'] ?? ''));
        $imageUrl = null; // Will be set if file is uploaded

        if ($id > 0) {
            // Update existing POI
            if ($catId < 1 || $title === '' || $description === '') {
                http_response_code(400);
                echo json_encode(['error' => 'category_id, title, description required']);
                exit;
            }
            $cat = $pdo->prepare('SELECT id FROM categories WHERE id = ? LIMIT 1');
            $cat->execute([$catId]);
            if (!$cat->fetch()) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid category']);
                exit;
            }
        } else {
            // Create new POI
            $slug = trim((string) ($_POST['location_slug'] ?? ''));
            if ($slug === '' || $catId < 1 || $title === '' || $description === '') {
                http_response_code(400);
                echo json_encode(['error' => 'location_slug, category_id, title, description required']);
                exit;
            }
            $loc = $pdo->prepare('SELECT id FROM locations WHERE slug = ? LIMIT 1');
            $loc->execute([$slug]);
            $lr = $loc->fetch();
            if (!$lr) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid location']);
                exit;
            }
            $cat = $pdo->prepare('SELECT id FROM categories WHERE id = ? LIMIT 1');
            $cat->execute([$catId]);
            if (!$cat->fetch()) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid category']);
                exit;
            }
        }

        // Handle file upload
        if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $file = $_FILES['image'];
            $maxSize = 5 * 1024 * 1024; // 5MB
            if ($file['size'] > $maxSize) {
                http_response_code(400);
                echo json_encode(['error' => 'Image too large (max 5MB)']);
                exit;
            }
            $allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
            if (!in_array($file['type'], $allowedTypes)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid image type']);
                exit;
            }
            $uploadDir = __DIR__ . '/uploads/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0755, true);
            }
            $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
            $filename = uniqid('img_', true) . '.' . $ext;
            $path = $uploadDir . $filename;
            if (!move_uploaded_file($file['tmp_name'], $path)) {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to save image']);
                exit;
            }
            $imageUrl = $filename; // filename only, image.php adds uploads/ prefix
        }

        if ($id > 0) {
            if ($imageUrl !== null) {
                $up = $pdo->prepare(
                    'UPDATE poi SET category_id = ?, title = ?, description = ?, address = ?, image_url = ? WHERE id = ?'
                );
                $up->execute([$catId, $title, $description, $address, $imageUrl, $id]);
            } else {
                $up = $pdo->prepare(
                    'UPDATE poi SET category_id = ?, title = ?, description = ?, address = ? WHERE id = ?'
                );
                $up->execute([$catId, $title, $description, $address, $id]);
            }
            echo json_encode(['ok' => true, 'affected' => $up->rowCount()]);
            exit;
        }

        $ins = $pdo->prepare(
            'INSERT INTO poi (location_id, category_id, title, description, address, image_url)
             VALUES (?, ?, ?, ?, ?, ?)'
        );
        $ins->execute([(int) $lr['id'], $catId, $title, $description, $address, $imageUrl ?? '']);
        echo json_encode(['id' => (int) $pdo->lastInsertId()]);
        exit;
    }

    if ($action === 'poi' && $method === 'PUT') {
        require_auth($pdo);
        $id = (int) ($_POST['id'] ?? 0);
        if ($id < 1) {
            http_response_code(400);
            echo json_encode(['error' => 'id required']);
            exit;
        }
        $catId = (int) ($_POST['category_id'] ?? 0);
        $title = trim((string) ($_POST['title'] ?? ''));
        $description = trim((string) ($_POST['description'] ?? ''));
        $address = trim((string) ($_POST['address'] ?? ''));

        if ($catId < 1 || $title === '' || $description === '') {
            http_response_code(400);
            echo json_encode(['error' => 'category_id, title, description required']);
            exit;
        }
        $cat = $pdo->prepare('SELECT id FROM categories WHERE id = ? LIMIT 1');
        $cat->execute([$catId]);
        if (!$cat->fetch()) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid category']);
            exit;
        }

        // Handle file upload (optional - only if a new image is provided)
        $imageUrl = null; // null means don't update the image_url field
        if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $file = $_FILES['image'];
            $maxSize = 5 * 1024 * 1024; // 5MB
            if ($file['size'] > $maxSize) {
                http_response_code(400);
                echo json_encode(['error' => 'Image too large (max 5MB)']);
                exit;
            }
            $allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
            if (!in_array($file['type'], $allowedTypes)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid image type']);
                exit;
            }
            $uploadDir = __DIR__ . '/uploads/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0755, true);
            }
            $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
            $filename = uniqid('img_', true) . '.' . $ext;
            $path = $uploadDir . $filename;
            if (!move_uploaded_file($file['tmp_name'], $path)) {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to save image']);
                exit;
            }
            $imageUrl = $filename; // filename only, image.php adds uploads/ prefix
        }

        // Update POI
        if ($imageUrl !== null) {
            $up = $pdo->prepare(
                'UPDATE poi SET category_id = ?, title = ?, description = ?, address = ?, image_url = ? WHERE id = ?'
            );
            $up->execute([$catId, $title, $description, $address, $imageUrl, $id]);
        } else {
            $up = $pdo->prepare(
                'UPDATE poi SET category_id = ?, title = ?, description = ?, address = ? WHERE id = ?'
            );
            $up->execute([$catId, $title, $description, $address, $id]);
        }
        echo json_encode(['ok' => true, 'affected' => $up->rowCount()]);
        exit;
    }

    if ($action === 'poi' && $method === 'DELETE') {
        require_auth($pdo);
        $id = $_GET['id'] ?? '';
        if ($id === '' || !ctype_digit((string) $id)) {
            http_response_code(400);
            echo json_encode(['error' => 'id required']);
            exit;
        }
        $del = $pdo->prepare('DELETE FROM poi WHERE id = ?');
        $del->execute([(int) $id]);
        echo json_encode(['ok' => true, 'affected' => $del->rowCount()]);
        exit;
    }

    http_response_code(404);
    echo json_encode(['error' => 'Unknown action']);
} catch (Throwable $e) {
    http_response_code(500);
    error_log('API Error: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine());
    echo json_encode(['error' => 'Server error: ' . $e->getMessage()]);
}