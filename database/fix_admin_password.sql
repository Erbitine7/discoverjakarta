-- Run in phpMyAdmin or mysql CLI if you already imported the old seed and admin login fails.
-- Resets password to: admin / admin123
USE `discover_jakarta`;
UPDATE `account`
SET `password_hash` = '$2b$10$ubxbzhTyrtSjvsRdoSEzlOn3Kwlyr1/DQp7d1ayLbbkk4zOMKhGtO'
WHERE `username` = 'admin';
