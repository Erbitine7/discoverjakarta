<?php
// Simple test script to verify multipart form data handling
echo "Testing multipart form data handling:\n\n";

echo "POST fields:\n";
var_dump($_POST);

echo "\nFILES:\n";
var_dump($_FILES);

echo "\nHeaders:\n";
var_dump(getallheaders());

echo "\nServer info:\n";
echo "REQUEST_METHOD: " . $_SERVER['REQUEST_METHOD'] . "\n";
echo "CONTENT_TYPE: " . ($_SERVER['CONTENT_TYPE'] ?? 'not set') . "\n";
?>
