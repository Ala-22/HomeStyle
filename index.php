<?php
require_once __DIR__ . "/db.php";

$userCount = 0;
$productCount = 0;

$res = $conn->query("SELECT COUNT(*) AS c FROM users");
if ($res) { $userCount = (int)$res->fetch_assoc()["c"]; }

$res = $conn->query("SELECT COUNT(*) AS c FROM products");
if ($res) { $productCount = (int)$res->fetch_assoc()["c"]; }

$conn->close();
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HomeStyle API</title>
    <style>
        body { font-family: Tahoma, Arial, sans-serif; background: #f4f4f6; margin: 0; padding: 40px 20px; }
        .card { max-width: 560px; margin: 0 auto; background: #fff; border-radius: 14px; padding: 30px;
                box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
        h1 { margin: 0 0 6px; font-size: 24px; color: #222; }
        p { color: #666; margin: 4px 0 18px; }
        .stats { display: flex; gap: 14px; margin-bottom: 24px; }
        .stat { flex: 1; background: #f0f4ff; border-radius: 10px; padding: 14px; text-align: center; }
        .stat b { display: block; font-size: 26px; color: #1c5fd8; }
        .stat span { font-size: 13px; color: #555; }
        a.btn { display: block; text-decoration: none; background: #1c5fd8; color: #fff; padding: 12px;
                border-radius: 10px; margin-bottom: 10px; text-align: center; font-weight: bold; }
        a.btn.alt { background: #e8edf5; color: #1c5fd8; }
        .ok { color: #1a8f3c; font-weight: bold; }
    </style>
</head>
<body>
    <div class="card">
        <h1>HomeStyle API</h1>
        <p class="ok">قاعدة البيانات متصلة بنجاح</p>
        <div class="stats">
            <div class="stat"><b><?php echo $userCount; ?></b><span>مستخدم</span></div>
            <div class="stat"><b><?php echo $productCount; ?></b><span>منتج</span></div>
        </div>
        <a class="btn" href="products.php">عرض المنتجات (JSON)</a>
        <a class="btn alt" href="delete_account.php">حذف حساب</a>
        <a class="btn alt" href="forgot_password.php">استعادة كلمة المرور</a>
        <a class="btn alt" href="sync_products.php">إعادة مزامنة المنتجات من الصور</a>
    </div>
</body>
</html>