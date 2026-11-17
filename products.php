<?php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");

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

/*
   مساعدة: سمّ الملف بالتنسيق التالي لتحديد السعر والاسم بنفسك:

       {السعر}_{الاسم}.jpg

   مثال:
       149_إضاءة غرفة معيشة.jpg   ->  السعر 149 والاسم "إضاءة غرفة معيشة"
       250_Brown Velvet Sofa.png ->  السعر 250 والاسم "Brown Velvet Sofa"

   لو الاسم يحتوي على سعر بأول الملف فقط، ياخذ السعر تلقائياً
   وإلا السعر تلقائي من الصيغة الأدنى.
*/

function humanize(string $name): string {
    $clean = trim(str_replace(['-', '_'], ' ', $name));
    return preg_replace('/\s+/', ' ', $clean);
}

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

        $productName = humanize($fileName);
        $price = 50 + ($id * 15);

        $parts = preg_split('/\s*_\s*/', $fileName, 2);

        if (count($parts) === 2 && is_numeric($parts[0]) && trim($parts[1]) !== "") {
            $price = (float)$parts[0];
            $productName = humanize($parts[1]);
        }

        if ($productName === "") {
            $productName = $category . " Item " . $id;
        }

        $products[] = [
            "id" => $id,
            "name" => $productName,
            "description" => "Beautiful " . strtolower($category) . " product for your home.",
            "price" => number_format($price, 2, '.', ''),
            "image" => $imageUrl,
            "category" => $category
        ];

        $id++;
    }
}

echo json_encode($products, JSON_UNESCAPED_UNICODE);

?>