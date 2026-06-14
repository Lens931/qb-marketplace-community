CREATE TABLE IF NOT EXISTS `marketplace_offers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_citizenid` VARCHAR(64) NOT NULL,
  `seller_name` VARCHAR(128) NULL DEFAULT NULL,
  `item_name` VARCHAR(100) NOT NULL,
  `item_label` VARCHAR(150) NOT NULL,
  `quantity` INT UNSIGNED NOT NULL,
  `price` INT UNSIGNED NOT NULL,
  `metadata` JSON NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_marketplace_offers_seller` (`seller_citizenid`),
  KEY `idx_marketplace_offers_item` (`item_name`),
  KEY `idx_marketplace_offers_created` (`created_at`),
  KEY `idx_marketplace_offers_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `marketplace_sales` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `offer_id` INT UNSIGNED NULL DEFAULT NULL,
  `seller_citizenid` VARCHAR(64) NOT NULL,
  `buyer_citizenid` VARCHAR(64) NOT NULL,
  `item_name` VARCHAR(100) NOT NULL,
  `item_label` VARCHAR(150) NOT NULL,
  `quantity` INT UNSIGNED NOT NULL,
  `unit_price` INT UNSIGNED NOT NULL,
  `total_price` INT UNSIGNED NOT NULL,
  `withdrawn` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `withdrawn_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_marketplace_sales_offer` (`offer_id`),
  KEY `idx_marketplace_sales_seller` (`seller_citizenid`),
  KEY `idx_marketplace_sales_buyer` (`buyer_citizenid`),
  KEY `idx_marketplace_sales_item` (`item_name`),
  KEY `idx_marketplace_sales_created` (`created_at`),
  KEY `idx_marketplace_sales_withdrawn` (`withdrawn`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
