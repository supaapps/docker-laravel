<?php
header('Content-Type: application/json');
echo json_encode([
    'version' => PHP_VERSION,
    'method' => $_SERVER['REQUEST_METHOD'],
    'field' => $_POST['field'] ?? null,
    'upload' => isset($_FILES['upload']) ? file_get_contents($_FILES['upload']['tmp_name']) : null,
    'upload_progress' => ini_get('session.upload_progress.enabled'),
    'environment' => getenv('BASE_IMAGE_ENV'),
    'request_environment' => getenv('BASE_IMAGE_REQUEST'),
], JSON_THROW_ON_ERROR);
