<?php
$profile = $argv[1];
$expected = $argv[2];
if (PHP_VERSION !== $expected) {
    throw new RuntimeException('Unexpected PHP runtime: ' . PHP_VERSION);
}
foreach (['ctype', 'curl', 'dom', 'fileinfo', 'mbstring', 'openssl', 'pdo', 'session', 'tokenizer', 'xml', 'imagick', 'redis', 'pdo_mysql', 'pdo_pgsql', 'pdo_sqlite', 'mysqli', 'gd', 'sockets', 'zip', 'pcntl'] as $extension) {
    if (!extension_loaded($extension)) {
        throw new RuntimeException('Missing extension: ' . $extension);
    }
}
if (extension_loaded('xdebug') !== ($profile === 'build')) {
    throw new RuntimeException('Xdebug must be exclusive to build images');
}
if (ini_get('session.upload_progress.enabled')) {
    throw new RuntimeException('Upload progress must remain disabled');
}
// Vendor builds may append a Git revision to libxml's numeric version string.
if (!preg_match('/^([0-9]{5,})(?:$|[-+])/', LIBXML_LOADED_VERSION, $loadedVersion)
    || (int) $loadedVersion[1] < 21504 || LIBXML_VERSION < 21504) {
    throw new RuntimeException('Patched libxml2 must be loaded: ' . LIBXML_LOADED_VERSION);
}
$xml = new DOMDocument();
if (!$xml->loadXML('<root><value>checked</value></root>', LIBXML_NONET) || $xml->getElementsByTagName('value')->item(0)->textContent !== 'checked') {
    throw new RuntimeException('DOM parsing failed');
}
if ((string) simplexml_load_string('<value>checked</value>') !== 'checked') {
    throw new RuntimeException('SimpleXML parsing failed');
}
$db = new PDO('sqlite::memory:');
if ((int) $db->query('SELECT 42')->fetchColumn() !== 42) {
    throw new RuntimeException('PDO operation failed');
}
echo 'Verified ', PHP_VERSION, ' ', $profile, ' with libxml2 ', LIBXML_DOTTED_VERSION, ' (loaded ', LIBXML_LOADED_VERSION, ')', PHP_EOL;
