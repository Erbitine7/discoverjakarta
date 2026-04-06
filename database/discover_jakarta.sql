-- Discover Jakarta — import this file in phpMyAdmin (Import tab).
-- Database: discover_jakarta
--
-- Tables:
--   locations   — Jakarta regions for the map / dropdown (Central, North, …).
--   categories  — Article types (Culinary, Entertainment, …).
--   account     — Admin users only (app login).
--   sessions    — Tokens after login (used by the Node/Express API for add/edit/delete).
--   poi         — Point of interest / article; image_url stores a full URL or path for the cover image.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS `discover_jakarta` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `discover_jakarta`;

DROP TABLE IF EXISTS `sessions`;
DROP TABLE IF EXISTS `poi`;
DROP TABLE IF EXISTS `account`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `locations`;

CREATE TABLE `locations` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `slug` varchar(32) NOT NULL,
  `name` varchar(128) NOT NULL,
  `sort_order` tinyint unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `categories` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `slug` varchar(64) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `account` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sessions` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `account_id` int unsigned NOT NULL,
  `token` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token` (`token`),
  KEY `account_id` (`account_id`),
  CONSTRAINT `sessions_account_fk` FOREIGN KEY (`account_id`) REFERENCES `account` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `poi` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `location_id` int unsigned NOT NULL,
  `category_id` int unsigned NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `address` varchar(512) NOT NULL DEFAULT '',
  `image_url` varchar(1024) NOT NULL DEFAULT '',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `location_id` (`location_id`),
  KEY `category_id` (`category_id`),
  CONSTRAINT `poi_location_fk` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `poi_category_fk` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- Regions (matches Flutter area ids)
INSERT INTO `locations` (`slug`, `name`, `sort_order`) VALUES
  ('central', 'Central Jakarta', 1),
  ('north', 'North Jakarta', 2),
  ('south', 'South Jakarta', 3),
  ('west', 'West Jakarta', 4),
  ('east', 'East Jakarta', 5);

INSERT INTO `categories` (`name`, `slug`) VALUES
  ('Culinary', 'culinary'),
  ('Entertainment', 'entertainment'),
  ('Culture', 'culture'),
  ('Nature', 'nature'),
  ('Shopping', 'shopping'),
  ('History', 'history');

-- Default admin: username admin / password admin123 (change after first login in production)
-- Hash generated with Node bcrypt (PHP $2y$ seed in older dumps did not match this password).
INSERT INTO `account` (`username`, `password_hash`) VALUES
  ('admin', '$2b$10$ubxbzhTyrtSjvsRdoSEzlOn3Kwlyr1/DQp7d1ayLbbkk4zOMKhGtO');

-- Sample articles (image_url can be replaced with your own URLs or uploaded file paths later)
INSERT INTO `poi` (`location_id`, `category_id`, `title`, `description`, `address`, `image_url`) VALUES
  (1, 6, 'Monas', 'National Monument of Indonesia — iconic symbol of Jakarta and a great starting point to explore the capital.', 'Gambir, Central Jakarta', 'https://picsum.photos/seed/monas/800/400'),
  (1, 3, 'Istiqlal Mosque', 'One of the largest mosques in Southeast Asia, standing near Monas and Jakarta Cathedral.', 'Sawah Besar, Central Jakarta', 'https://picsum.photos/seed/istiqlal/800/400'),
  (2, 6, 'Kota Tua', 'Old Town of Jakarta with Dutch colonial buildings, museums, and street food.', 'Penjaringan, North Jakarta', 'https://picsum.photos/seed/kotatua/800/400');
