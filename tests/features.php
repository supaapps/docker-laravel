<?php
$expected = json_decode(file_get_contents('/usr/local/share/base-image/imagick-formats.json'), true, 512, JSON_THROW_ON_ERROR);
$actual = Imagick::queryFormats();
sort($expected);
sort($actual);
if ($expected !== $actual) {
    throw new RuntimeException('Image formats changed after removing build dependencies');
}
foreach (['PNG', 'JPEG', 'GIF'] as $format) {
    $image = new Imagick();
    $image->newImage(8, 8, 'white');
    $image->setImageFormat($format);
    $decoded = new Imagick();
    $decoded->readImageBlob($image->getImageBlob());
    if ($decoded->getImageWidth() !== 8 || $decoded->getImageHeight() !== 8) {
        throw new RuntimeException('Image round-trip failed: ' . $format);
    }
}
if (in_array('SVG', $expected, true)) {
    $image = new Imagick();
    $image->readImageBlob('<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8"><rect width="8" height="8" fill="white"/></svg>');
    $image->setImageFormat('PNG');
    if ($image->getImageBlob() === '') {
        throw new RuntimeException('SVG rasterization failed');
    }
}
echo 'Preserved ', count($actual), ' image formats and verified image round-trips', PHP_EOL;
