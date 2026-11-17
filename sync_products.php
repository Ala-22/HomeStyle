<?php

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/db.php";

$baseFolder = __DIR__ . "/images";

$categories = [
    "AI Images",
    "Kitchen",
    "Guest Room",
    "Bedrooms",
    "Living Room",
    "Bathroom",
    "Kitchen Tools",
    "General Tools",
    "Bathroom Tools",
    "Office",
    "Kids Room",
    "Dining Room",
    "Balcony"
];

function sync_humanize(string $name): string {
    $clean = trim(str_replace(['-', '_'], ' ', $name));
    return preg_replace('/\s+/', ' ', $clean);
}

$conn->query("DELETE FROM products");
$conn->query("ALTER TABLE products AUTO_INCREMENT = 1");

$products = [];
$id = 1;

foreach ($categories as $category) {

    $folder = $baseFolder . "/" . $category;

    if (!is_dir($folder)) {
        continue;
    }

    $files = scandir($folder);

    foreach ($files as $file) {

        $extension = strtolower(pathinfo($file, PATHINFO_EXTENSION));

        if (!in_array($extension, ["jpg", "jpeg", "png", "webp"])) {
            continue;
        }

        $imageUrl =
            "http://localhost/homestyle_api/images/"
            . rawurlencode($category)
            . "/"
            . rawurlencode($file);

        $fileName = pathinfo($file, PATHINFO_FILENAME);

        $productName = sync_humanize($fileName);
        $price = 50 + ($id * 15);

        $parts = preg_split('/\s*_\s*/', $fileName, 2);

        if (count($parts) === 2 && is_numeric($parts[0]) && trim($parts[1]) !== "") {
            $price = (float)$parts[0];
            $productName = sync_humanize($parts[1]);
        }

        if ($productName === "") {
            $productName = $category . " Item " . $id;
        }

        $stmt = $conn->prepare(
            "INSERT INTO products (name, description, price, image, category) VALUES (?, ?, ?, ?, ?)"
        );

        $description = "Beautiful " . strtolower($category) . " product for your home.";

        $stmt->bind_param(
            "ssdss",
            $productName,
            $description,
            $price,
            $imageUrl,
            $category
        );

        $stmt->execute();
        $stmt->close();

        $products[] = ["id" => $id, "name" => $productName];

        $id++;
    }
}

echo json_encode([
    "ok" => true,
    "synced" => count($products)
], JSON_UNESCAPED_UNICODE);

$conn->close();

?>