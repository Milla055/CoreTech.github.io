-- phpMyAdmin SQL Dump
-- version 5.1.2
-- https://www.phpmyadmin.net/
--
-- Gép: localhost:8889
-- Létrehozás ideje: 2025. Nov 21. 09:28
-- Kiszolgáló verziója: 5.7.24
-- PHP verzió: 8.3.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Adatbázis: `vizsgaremek`
--
CREATE DATABASE IF NOT EXISTS `vizsgaremek` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `vizsgaremek`;

DELIMITER $$
--
-- Eljárások
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `createAddress` (IN `userIdIN` INT, IN `streetIN` VARCHAR(100), IN `cityIN` VARCHAR(100), IN `postalcodeIN` INT(4), IN `countryIN` VARCHAR(100))   BEGIN

INSERT INTO `addresses`(
    `addresses`.`user_id`,
    `addresses`.`street`,
    `addresses`.`city`,
    `addresses`.`postal_code`,
    `addresses`.`country`
)
VALUES (
    userIDIN,
    streetIN,
    cityIN,
    postalcodeIN,
    countryIN
);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createAttributes` (IN `nameIN` VARCHAR(100), IN `unitIN` VARCHAR(100), IN `categoryIdIN` INT)   BEGIN

INSERT INTO `attributes`(
	`attributes`.`name`,
    `attributes`.`unit`,
    `attributes`.`category_id`
)
VALUES (
    nameIN,
    unitIN,
    categoryIdIN
);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createBrands` (IN `nameIN` VARCHAR(100), IN `descriptionIN` VARCHAR(100), IN `logourlIN` VARCHAR(100))   BEGIN

INSERT INTO `brands`(
	`brands`.`name`,
    `brands`.`description`,
    `brands`.`logo_url`
)
VALUES (
    nameIN,
    descriptionIN,
    logourlIN
);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createCategories` (IN `nameIN` VARCHAR(100), IN `descriptionIN` VARCHAR(100))   BEGIN

INSERT INTO `categories`(
	`categories`.`name`,
    `categories`.`description`
)
VALUES (
    nameIN,
    descriptionIN
);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createOrderItems` (IN `orderIdiN` INT, IN `productIdIN` INT, IN `quantityIN` INT, IN `priceIN` DOUBLE)   BEGIN

INSERT INTO `order_items`(
	`order_items`.`user_id`,
    `order_items`.`product_id`,
    `order_items`.`quantity`,
    `order_items`.`price`
)
VALUES (
    orderIdiN,
    productIdIN,
    quantityIN,
    priceIN
);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createOrders` (IN `userIdIN` INT, IN `addressIdIN` INT, IN `totalpriceIN` VARCHAR(100), IN `statusIN` VARCHAR(100))   BEGIN

INSERT INTO `orders`(
	`orders`.`user_id`,
    `orders`.`address_id`,
    `orders`.`total_price`,
    `orders`.`status`
)
VALUES (
    userIdIN,
    addressIdIN,
    totalpriceIN,
    statusIN
);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createProductAttributes` (IN `productIdIN` INT, IN `attributeIdIN` INT, IN `valueIN` VARCHAR(100))   BEGIN

INSERT INTO `product_attributes`(
	`product_attributes`.`product_id`,
    `product_attributes`.`attribute_id`,
    `product_attributes`.`value`
)
VALUES (
    productIdIN,
    attributeIdIN,
    valueIN
);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createProducts` (IN `categoryIdIN` INT, IN `brandIdIN` INT, IN `nameIN` VARCHAR(100), IN `descriptionIN` VARCHAR(100), IN `priceIN` DOUBLE, IN `stockIN` INT, IN `imageurlIN` VARCHAR(100))   BEGIN

INSERT INTO `products`(
	`products`.`name`,
    `products`.`description`,
    `products`.`price`,
    `products`.`stock`,
    `products`.`image_url`,
    `products`.`category_id`,
    `products`.`brand_id`
)
VALUES (
    categoryIdIN,
    brandIdIN,
    nameIN,
    descriptionIN,
    priceIN,
    stockIN,
    imageurlIN
);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createReviews` (IN `productIdIN` INT, IN `userIdIN` INT, IN `ratingIN` INT, IN `commentIN` TEXT)   BEGIN

INSERT INTO `reviews`(
	`reviews`.`product_id`,
    `reviews`.`user_id`,
    `reviews`.`rating`,
    `reviews`.`comment`
)
VALUES (
    productIdIN,
    userIdIN,
    ratingIN,
    commentIN
);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createUser` (IN `usernameIN` VARCHAR(100), IN `emailIN` VARCHAR(100), IN `passwordIN` MEDIUMTEXT, IN `roleIN` VARCHAR(30))   BEGIN

INSERT INTO `users`(
    `users`.`username`,
    `users`.`email`,
    `users`.`password_hash`,
    `users`.`role`
)
VALUES (
    usernameIN,
    emailIN,
    passwordIN,
    roleIN
);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAddressById` (IN `addressIdIN` INT)   BEGIN
    SELECT 
        `addresses`.`id`,
        `addresses`.`user_id`,
        `addresses`.`street`,
        `addresses`.`city`,
        `addresses`.`postal_code`,
        `addresses`.`country`,
        `addresses`.`is_default`,
        `addresses`.`created_at`
    FROM `addresses`
    WHERE `addresses`.`id` = addressIdIN AND `addresses`.`is_deleted` IS NULL
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAddressesByUserId` (IN `userIdIN` INT)   BEGIN
    SELECT 
        `addresses`.`id`,
        `addresses`.`user_id`,
        `addresses`.`street`,
        `addresses`.`city`,
        `addresses`.`postal_code`,
        `addresses`.`country`,
        `addresses`.`is_default`,
        `addresses`.`created_at`
    FROM `addresses`
    WHERE `addresses`.`user_id` = userIdIN AND `addresses`.`is_deleted` IS NULL
    ORDER BY `addresses`.`is_default` DESC, `addresses`.`created_at` DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllAddresses` ()   BEGIN
    SELECT 
        `addresses`.`id`,
        `addresses`.`user_id`,
        `addresses`.`street`,
        `addresses`.`city`,
        `addresses`.`postal_code`,
        `addresses`.`country`,
        `addresses`.`is_default`,
        `addresses`.`created_at`
    FROM `addresses`
    WHERE `addresses`.`is_deleted` IS NULL
    ORDER BY `addresses`.`created_at` DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllAttributes` ()   BEGIN
    SELECT 
        `attributes`.`id`,
        `attributes`.`name`,
        `attributes`.`unit`,
        `attributes`.`category_id`,
        `attributes`.`created_at`,
        `categories`.`name` AS category_name
    FROM `attributes`
    LEFT JOIN `categories` ON `attributes`.`category_id` = `categories`.`id`
    WHERE `attributes`.`is_deleted` IS NULL
    ORDER BY `attributes`.`name` ASC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllBrands` ()   BEGIN
    SELECT 
        `brands`.`id`,
        `brands`.`name`,
        `brands`.`description`,
        `brands`.`logo_url`,
        `brands`.`created_at`
    FROM `brands`
    WHERE `brands`.`is_deleted` IS NULL
    ORDER BY `brands`.`name` ASC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllCategories` ()   BEGIN
    SELECT 
        `categories`.`id`,
        `categories`.`name`,
        `categories`.`description`,
        `categories`.`created_at`
    FROM `categories`
    WHERE `categories`.`is_deleted` IS NULL
    ORDER BY `categories`.`name` ASC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllOrders` ()   BEGIN
    SELECT 
        `orders`.`id`,
        `orders`.`user_id`,
        `orders`.`address_id`,
        `orders`.`total_price`,
        `orders`.`status`,
        `orders`.`created_at`,
        `users`.`username`
    FROM `orders`
    INNER JOIN `users` ON `orders`.`user_id` = `users`.`id`
    WHERE `orders`.`is_deleted` IS NULL
    ORDER BY `orders`.`created_at` DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllProducts` ()   BEGIN
    SELECT 
        `products`.`id`,
        `products`.`name`,
        `products`.`description`,
        `products`.`price`,
        `products`.`stock`,
        `products`.`image_url`,
        `products`.`category_id`,
        `products`.`brand_id`,
        `products`.`created_at`,
        `categories`.`name` AS category_name,
        `brands`.`name` AS brand_name
    FROM `products`
    INNER JOIN `categories` ON `products`.`category_id` = `categories`.`id`
    INNER JOIN `brands` ON `products`.`brand_id` = `brands`.`id`
    WHERE `products`.`is_deleted` IS NULL
    ORDER BY `products`.`created_at` DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllReviews` ()   BEGIN
    SELECT 
        `reviews`.`id`,
        `reviews`.`product_id`,
        `reviews`.`user_id`,
        `reviews`.`rating`,
        `reviews`.`comment`,
        `reviews`.`created_at`,
        `users`.`username`,
        `products`.`name` AS product_name
    FROM `reviews`
    INNER JOIN `users` ON `reviews`.`user_id` = `users`.`id`
    INNER JOIN `products` ON `reviews`.`product_id` = `products`.`id`
    WHERE `reviews`.`is_deleted` IS NULL
    ORDER BY `reviews`.`created_at` DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllUsers` ()   BEGIN
    SELECT 
        `users`.`id`,
        `users`.`username`,
        `users`.`email`,
        `users`.`role`,
        `users`.`created_at`
    FROM `users`
    WHERE `users`.`is_deleted` = 0
    ORDER BY `users`.`created_at` DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAttributeById` (IN `attributeIdIN` INT)   BEGIN
    SELECT 
        `attributes`.`id`,
        `attributes`.`name`,
        `attributes`.`unit`,
        `attributes`.`category_id`,
        `attributes`.`created_at`,
        `categories`.`name` AS category_name
    FROM `attributes`
    INNER JOIN `categories` ON `attributes`.`category_id` = `categories`.`id`
    WHERE `attributes`.`id` = attributeIdIN AND `attributes`.`is_deleted` IS NULL
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getBrandById` (IN `brandIdIN` INT)   BEGIN
    SELECT 
        `brands`.`id`,
        `brands`.`name`,
        `brands`.`description`,
        `brands`.`logo_url`,
        `brands`.`created_at`
    FROM `brands`
    WHERE `brands`.`id` = brandIdIN AND `brands`.`is_deleted` IS NULL
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getCategoryById` (IN `categoryIdIN` INT)   BEGIN
    SELECT 
        `categories`.`id`,
        `categories`.`name`,
        `categories`.`description`,
        `categories`.`created_at`
    FROM `categories`
    WHERE `categories`.`id` = categoryIdIN AND `categories`.`is_deleted` IS NULL
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrderById` (IN `orderIdIN` INT)   BEGIN
    SELECT 
        `orders`.`id`,
        `orders`.`user_id`,
        `orders`.`address_id`,
        `orders`.`total_price`,
        `orders`.`status`,
        `orders`.`created_at`
    FROM `orders`
    WHERE `orders`.`id` = orderIdIN AND `orders`.`is_deleted` IS NULL
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrderItemById` (IN `orderItemIdIN` INT)   BEGIN
    SELECT 
        `order_items`.`id`,
        `order_items`.`order_id`,
        `order_items`.`product_id`,
        `order_items`.`quantity`,
        `order_items`.`price`,
        `order_items`.`created_at`,
        `products`.`name` AS product_name
    FROM `order_items`
    INNER JOIN `products` ON `order_items`.`product_id` = `products`.`id`
    WHERE `order_items`.`id` = orderItemIdIN AND `order_items`.`is_deleted` IS NULL
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrderItemsByOrderId` (IN `orderIdIN` INT)   BEGIN
    SELECT 
        `order_items`.`id`,
        `order_items`.`order_id`,
        `order_items`.`product_id`,
        `order_items`.`quantity`,
        `order_items`.`price`,
        `order_items`.`created_at`,
        `products`.`name` AS product_name,
        `products`.`image_url`
    FROM `order_items`
    INNER JOIN `products` ON `order_items`.`product_id` = `products`.`id`
    WHERE `order_items`.`order_id` = orderIdIN AND `order_items`.`is_deleted` IS NULL
    ORDER BY `order_items`.`created_at` ASC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrdersByUserId` (IN `userIdIN` INT)   BEGIN
    SELECT
        `orders`.`id` AS "order_id",
        `products`.`name`,
        `products`.`image_url`,
        `orders`.`total_price`,
        `orders`.`status`,
        `order_items`.`quantity`,
        `orders`.`created_at`
    FROM `orders`
    INNER JOIN
        `order_items` ON `orders`.`id` = `order_items`.`order_id` 
    INNER JOIN
        `products` ON `order_items`.`product_id` = `products`.`id`
    WHERE
        `orders`.`user_id` = userIdIN
    ORDER BY
        `orders`.`created_at` DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getPasswordByEmail` (IN `emailIN` VARCHAR(255))   BEGIN

    SELECT `users`.`password_hash`
    FROM users
    WHERE `users`.`is_deleted` = 0 AND `users`.`email` = emailIN
    LIMIT 1;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getProductAttributeById` (IN `productAttributeIdIN` INT)   BEGIN
    SELECT 
        `product_attributes`.`id`,
        `product_attributes`.`product_id`,
        `product_attributes`.`attribute_id`,
        `product_attributes`.`value`,
        `product_attributes`.`created_at`,
        `attributes`.`name` AS attribute_name,
        `attributes`.`unit`
    FROM `product_attributes`
    INNER JOIN `attributes` ON `product_attributes`.`attribute_id` = `attributes`.`id`
    WHERE `product_attributes`.`id` = productAttributeIdIN AND `product_attributes`.`is_deleted` IS NULL
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getProductAttributesByProductId` (IN `productIdIN` INT)   BEGIN
    SELECT 
        `product_attributes`.`id`,
        `product_attributes`.`product_id`,
        `product_attributes`.`attribute_id`,
        `product_attributes`.`value`,
        `product_attributes`.`created_at`,
        `attributes`.`name` AS attribute_name,
        `attributes`.`unit`
    FROM `product_attributes`
    INNER JOIN `attributes` ON `product_attributes`.`attribute_id` = `attributes`.`id`
    WHERE `product_attributes`.`product_id` = productIdIN AND `product_attributes`.`is_deleted` IS NULL
    ORDER BY `attributes`.`name` ASC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getProductById` (IN `productIdIN` INT)   BEGIN
    SELECT 
        `products`.`id`,
        `products`.`name`,
        `products`.`description`,
        `products`.`price`,
        `products`.`stock`,
        `products`.`image_url`,
        `products`.`category_id`,
        `products`.`brand_id`,
        `products`.`created_at`,
        `categories`.`name` AS category_name,
        `brands`.`name` AS brand_name
    FROM `products`
    INNER JOIN `categories` ON `products`.`category_id` = `categories`.`id`
    INNER JOIN `brands` ON `products`.`brand_id` = `brands`.`id`
    WHERE `products`.`id` = productIdIN AND `products`.`is_deleted` IS NULL
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getProductsByCategoryId` (IN `categoryIdIN` INT)   BEGIN
    SELECT 
        `products`.`id`,
        `products`.`name`,
        `products`.`description`,
        `products`.`price`,
        `products`.`stock`,
        `products`.`image_url`,
        `products`.`category_id`,
        `products`.`brand_id`,
        `products`.`created_at`,
        `brands`.`name` AS brand_name
    FROM `products`
    INNER JOIN `brands` ON `products`.`brand_id` = `brands`.`id`
    WHERE `products`.`category_id` = categoryIdIN AND `products`.`is_deleted` IS NULL
    ORDER BY `products`.`created_at` DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getReviewById` (IN `reviewIdIN` INT)   BEGIN
    SELECT 
        `reviews`.`id`,
        `reviews`.`product_id`,
        `reviews`.`user_id`,
        `reviews`.`rating`,
        `reviews`.`comment`,
        `reviews`.`created_at`,
        `users`.`username`,
        `products`.`name` AS product_name
    FROM `reviews`
    INNER JOIN `users` ON `reviews`.`user_id` = `users`.`id`
    INNER JOIN `products` ON `reviews`.`product_id` = `products`.`id`
    WHERE `reviews`.`id` = reviewIdIN AND `reviews`.`is_deleted` IS NULL
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getReviewsByProductId` (IN `productIdIN` INT)   BEGIN
    SELECT 
        `reviews`.`id`,
        `reviews`.`product_id`,
        `reviews`.`user_id`,
        `reviews`.`rating`,
        `reviews`.`comment`,
        `reviews`.`created_at`,
        `users`.`username`
    FROM `reviews`
    INNER JOIN `users` ON `reviews`.`user_id` = `users`.`id`
    WHERE `reviews`.`product_id` = productIdIN AND `reviews`.`is_deleted` IS NULL
    ORDER BY `reviews`.`created_at` DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserById` (IN `userIdIN` INT)   BEGIN
    SELECT 
        `users`.`id`,
        `users`.`username`,
        `users`.`email`,
        `users`.`role`,
        `users`.`created_at`
    FROM `users`
    WHERE `users`.`id` = userIdIN AND `users`.`is_deleted` = 0
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelAddresses` (IN `addressesIdIN` INT)   BEGIN
    UPDATE `addresses`
    SET 
        `addresses`.`is_deleted` = 1,
        `addresses`.`deleted_at` = NOW()
    WHERE `addresses`.`id` = addressesIdIN;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelAttributes` (IN `attributesIdIN` INT)   BEGIN
    UPDATE `attributes`
    SET 
        `attributes`.`is_deleted` = 1,
        `attributes`.`deleted_at` = NOW()
    WHERE `attributes`.`id` = attributesIdIN;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelBrands` (IN `brandsIdIN` INT)   BEGIN
    UPDATE `brands`
    SET 
        `brands`.`is_deleted` = 1,
        `brands`.`deleted_at` = NOW()
    WHERE `brands`.`id` = brandsIdIN;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelCategories` (IN `categoriesIdIN` INT)   BEGIN
    UPDATE `categories`
    SET 
        `categories`.`is_deleted` = 1,
        `categories`.`deleted_at` = NOW()
    WHERE `categories`.`id` = categoriesIdIN;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelOrderItems` (IN `orderItemsIdIN` INT)   BEGIN
    UPDATE `order_items`
    SET 
        `order_items`.`is_deleted` = 1,
        `order_items`.`deleted_at` = NOW()
    WHERE `order_items`.`id` = orderItemsIdIN;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelOrders` (IN `ordersIdIN` INT)   BEGIN
    UPDATE `orders`
    SET 
        `orders`.`is_deleted` = 1,
        `orders`.`deleted_at` = NOW()
    WHERE `orders`.`id` = ordersIdIN;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelProductAttributes` (IN `productAttributesIdIN` INT)   BEGIN
    UPDATE `product_attributes`
    SET 
        `product_attributes`.`is_deleted` = 1,
        `product_attributes`.`deleted_at` = NOW()
    WHERE `product_attributes`.`id` = productAttributesIdIN;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelProducts` (IN `productsIdIN` INT)   BEGIN
    UPDATE `products`
    SET 
        `products`.`is_deleted` = 1,
        `products`.`deleted_at` = NOW()
    WHERE `products`.`id` = productsIdIN;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelReviews` (IN `reviewsIdIN` INT)   BEGIN
    UPDATE `reviews`
    SET 
        `reviews`.`is_deleted` = 1,
        `reviews`.`deleted_at` = NOW()
    WHERE `reviews`.`id` = reviewsIdIN;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelUser` (IN `userIDIN` INT)   BEGIN
    UPDATE `users`
    SET 
        `users`.`is_deleted` = 1,
        `users`.`deleted_at` = NOW()
    WHERE `users`.`id` = userIDIN;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateAddressById` (IN `addressIdIN` INT, IN `streetIN` VARCHAR(100), IN `cityIN` VARCHAR(100), IN `postalcodeIN` VARCHAR(20), IN `countryIN` VARCHAR(100), IN `isDefaultIN` TINYINT(1))   BEGIN
    UPDATE `addresses`
    SET 
        `addresses`.`street` = streetIN,
        `addresses`.`city` = cityIN,
        `addresses`.`postal_code` = postalcodeIN,
        `addresses`.`country` = countryIN,
        `addresses`.`is_default` = isDefaultIN
    WHERE `addresses`.`id` = addressIdIN AND `addresses`.`is_deleted` IS NULL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateAttributeById` (IN `attributeIdIN` INT, IN `nameIN` VARCHAR(255), IN `unitIN` VARCHAR(50), IN `categoryIdIN` INT)   BEGIN
    UPDATE `attributes`
    SET 
        `attributes`.`name` = nameIN,
        `attributes`.`unit` = unitIN,
        `attributes`.`category_id` = categoryIdIN
    WHERE `attributes`.`id` = attributeIdIN AND `attributes`.`is_deleted` IS NULL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateBrandById` (IN `brandIdIN` INT, IN `nameIN` VARCHAR(100), IN `descriptionIN` TEXT, IN `logourlIN` VARCHAR(255))   BEGIN
    UPDATE `brands`
    SET 
        `brands`.`name` = nameIN,
        `brands`.`description` = descriptionIN,
        `brands`.`logo_url` = logourlIN
    WHERE `brands`.`id` = brandIdIN AND `brands`.`is_deleted` IS NULL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateCategoryById` (IN `categoryIdIN` INT, IN `nameIN` VARCHAR(100), IN `descriptionIN` TEXT)   BEGIN
    UPDATE `categories`
    SET 
        `categories`.`name` = nameIN,
        `categories`.`description` = descriptionIN
    WHERE `categories`.`id` = categoryIdIN AND `categories`.`is_deleted` IS NULL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrderById` (IN `orderIdIN` INT, IN `statusIN` VARCHAR(50))   BEGIN
    UPDATE `orders`
    SET 
        `orders`.`status` = statusIN
    WHERE `orders`.`id` = orderIdIN AND `orders`.`is_deleted` IS NULL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrderItemById` (IN `orderItemIdIN` INT, IN `quantityIN` INT, IN `priceIN` DECIMAL(10,2))   BEGIN
    UPDATE `order_items`
    SET 
        `order_items`.`quantity` = quantityIN,
        `order_items`.`price` = priceIN
    WHERE `order_items`.`id` = orderItemIdIN AND `order_items`.`is_deleted` IS NULL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateProductAttributeById` (IN `productAttributeIdIN` INT, IN `valueIN` VARCHAR(255))   BEGIN
    UPDATE `product_attributes`
    SET 
        `product_attributes`.`value` = valueIN
    WHERE `product_attributes`.`id` = productAttributeIdIN AND `product_attributes`.`is_deleted` IS NULL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateProductById` (IN `productIdIN` INT, IN `nameIN` VARCHAR(255), IN `descriptionIN` TEXT, IN `priceIN` DECIMAL(10,2), IN `stockIN` INT, IN `imageurlIN` VARCHAR(255), IN `categoryIdIN` INT, IN `brandIdIN` INT)   BEGIN
    UPDATE `products`
    SET 
        `products`.`name` = nameIN,
        `products`.`description` = descriptionIN,
        `products`.`price` = priceIN,
        `products`.`stock` = stockIN,
        `products`.`image_url` = imageurlIN,
        `products`.`category_id` = categoryIdIN,
        `products`.`brand_id` = brandIdIN
    WHERE `products`.`id` = productIdIN AND `products`.`is_deleted` IS NULL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateReviewById` (IN `reviewIdIN` INT, IN `ratingIN` INT, IN `commentIN` TEXT)   BEGIN
    UPDATE `reviews`
    SET 
        `reviews`.`rating` = ratingIN,
        `reviews`.`comment` = commentIN
    WHERE `reviews`.`id` = reviewIdIN AND `reviews`.`is_deleted` IS NULL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUserById` (IN `userIdIN` INT, IN `usernameIN` VARCHAR(100), IN `emailIN` VARCHAR(100), IN `roleIN` VARCHAR(30))   BEGIN
    UPDATE `users`
    SET 
        `users`.`username` = usernameIN,
        `users`.`email` = emailIN,
        `users`.`role` = roleIN
    WHERE `users`.`id` = userIdIN AND `users`.`is_deleted` = 0;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `addresses`
--

CREATE TABLE `addresses` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `street` varchar(255) NOT NULL,
  `city` varchar(100) NOT NULL,
  `postal_code` varchar(20) NOT NULL,
  `country` varchar(100) NOT NULL,
  `is_default` tinyint(1) DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(4) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `addresses`
--

INSERT INTO `addresses` (`id`, `user_id`, `street`, `city`, `postal_code`, `country`, `is_default`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(1, 1, 'Fő utca 12.', 'Budapest', '1011', 'Magyarország', 1, '2023-01-15 09:30:00', NULL, NULL),
(2, 2, 'Kossuth tér 5.', 'Debrecen', '4024', 'Magyarország', 1, '2023-01-20 13:50:00', NULL, NULL),
(3, 3, 'Tisza Lajos krt. 18.', 'Szeged', '6720', 'Magyarország', 0, '2023-02-02 07:20:00', NULL, NULL),
(4, 4, 'Rákóczi út 45.', 'Pécs', '7621', 'Magyarország', 1, '2023-02-18 15:45:00', NULL, NULL),
(5, 5, 'Baross Gábor út 3.', 'Győr', '9022', 'Magyarország', 0, '2023-03-05 08:15:00', NULL, NULL),
(6, 6, 'Széchenyi István út 11.', 'Miskolc', '3525', 'Magyarország', 1, '2023-03-21 12:20:00', NULL, NULL),
(7, 7, 'Kossuth Lajos út 8.', 'Nyíregyháza', '4400', 'Magyarország', 0, '2023-04-10 09:40:00', NULL, NULL),
(8, 8, 'Fő tér 2.', 'Székesfehérvár', '8000', 'Magyarország', 1, '2023-04-25 15:55:00', NULL, NULL),
(9, 9, 'Katona József tér 7.', 'Kecskemét', '6000', 'Magyarország', 0, '2023-05-12 06:35:00', NULL, NULL),
(10, 10, 'Dobó István tér 1.', 'Eger', '3300', 'Magyarország', 1, '2023-05-28 13:10:00', NULL, NULL),
(11, 11, 'Várkerület 20.', 'Sopron', '9400', 'Magyarország', 0, '2023-06-15 17:05:00', NULL, NULL),
(12, 12, 'Fő tér 9.', 'Szombathely', '9700', 'Magyarország', 1, '2023-07-01 05:50:00', NULL, NULL),
(13, 13, 'Petőfi Sándor utca 14.', 'Salgótarján', '3100', 'Magyarország', 0, '2023-07-18 10:30:00', NULL, NULL),
(14, 14, 'Rákóczi út 22.', 'Tatabánya', '2800', 'Magyarország', 1, '2023-08-03 19:15:00', NULL, NULL),
(15, 15, 'Kossuth Lajos utca 6.', 'Zalaegerszeg', '8900', 'Magyarország', 0, '2023-08-20 07:59:00', NULL, NULL),
(16, 5, 'szigetiut', 'Pécs', '7636', 'Hungary', 0, '2025-11-20 09:33:23', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `attributes`
--

CREATE TABLE `attributes` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `unit` varchar(50) DEFAULT NULL,
  `category_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(4) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `attributes`
--

INSERT INTO `attributes` (`id`, `name`, `unit`, `category_id`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(1, 'Clock Speed', 'GHz', 1, '2025-10-03 07:19:06', NULL, NULL),
(2, 'Cores', 'Count', 1, '2025-10-03 07:19:06', NULL, NULL),
(3, 'VRAM', 'GB', 2, '2025-10-03 07:19:06', NULL, NULL),
(4, 'Chipset', NULL, 3, '2025-10-03 07:19:06', NULL, NULL),
(5, 'Memory Speed', 'MHz', 4, '2025-10-03 07:19:06', NULL, NULL),
(6, 'Capacity', 'TB', 5, '2025-10-03 07:19:06', NULL, NULL),
(7, 'Wattage', 'W', 6, '2025-10-03 07:19:06', NULL, NULL),
(8, 'Form Factor', NULL, 7, '2025-10-03 07:19:06', NULL, NULL),
(9, 'Fan Size', 'mm', 8, '2025-10-03 07:19:06', NULL, NULL),
(10, 'Screen Size', 'inch', 9, '2025-10-03 07:19:06', NULL, NULL),
(11, 'Key Type', NULL, 10, '2025-10-03 07:19:06', NULL, NULL),
(12, 'DPI', NULL, 11, '2025-10-03 07:19:06', NULL, NULL),
(13, 'Battery Life', 'hours', 12, '2025-10-03 07:19:06', NULL, NULL),
(14, 'Connector Type', NULL, 13, '2025-10-03 07:19:06', NULL, NULL),
(15, 'License Type', NULL, 15, '2025-10-03 07:19:06', NULL, NULL),
(16, 'test', 'testest', 6, '2025-11-20 09:34:55', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `brands`
--

CREATE TABLE `brands` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `logo_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(4) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `brands`
--

INSERT INTO `brands` (`id`, `name`, `description`, `logo_url`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(1, 'Intel', 'Processor and chipset manufacturer', 'https://example.com/intel.png', '2025-10-03 07:18:11', NULL, NULL),
(2, 'AMD', 'Processor and GPU manufacturer', 'https://example.com/amd.png', '2025-10-03 07:18:11', NULL, NULL),
(3, 'NVIDIA', 'Graphics card manufacturer', 'https://example.com/nvidia.png', '2025-10-03 07:18:11', NULL, NULL),
(4, 'ASUS', 'Motherboards and peripherals', 'https://example.com/asus.png', '2025-10-03 07:18:11', NULL, NULL),
(5, 'MSI', 'Gaming hardware', 'https://example.com/msi.png', '2025-10-03 07:18:11', NULL, NULL),
(6, 'Gigabyte', 'Motherboards and GPUs', 'https://example.com/gigabyte.png', '2025-10-03 07:18:11', NULL, NULL),
(7, 'Corsair', 'RAM and cooling systems', 'https://example.com/corsair.png', '2025-10-03 07:18:11', NULL, NULL),
(8, 'Samsung', 'SSDs and monitors', 'https://example.com/samsung.png', '2025-10-03 07:18:11', NULL, NULL),
(9, 'Western Digital', 'Storage solutions', 'https://example.com/wd.png', '2025-10-03 07:18:11', NULL, NULL),
(10, 'Logitech', 'Peripherals and accessories', 'https://example.com/logitech.png', '2025-10-03 07:18:11', NULL, NULL),
(11, 'Razer', 'Gaming peripherals', 'https://example.com/razer.png', '2025-10-03 07:18:11', NULL, NULL),
(12, 'Dell', 'Laptops and monitors', 'https://example.com/dell.png', '2025-10-03 07:18:11', NULL, NULL),
(13, 'HP', 'Laptops and accessories', 'https://example.com/hp.png', '2025-10-03 07:18:11', NULL, NULL),
(14, 'TP-Link', 'Networking equipment', 'https://example.com/tplink.png', '2025-10-03 07:18:11', NULL, NULL),
(15, 'Microsoft', 'Software and peripherals', 'https://example.com/microsoft.png', '2025-10-03 07:18:11', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `categories`
--

CREATE TABLE `categories` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(4) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `categories`
--

INSERT INTO `categories` (`id`, `name`, `description`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(1, 'Videókártyák', 'NVIDIA és AMD videókártyák játékhoz, munkához és szerverekhez.', '2023-01-10 11:00:00', NULL, NULL),
(2, 'Processzorok', 'Intel és AMD CPU-k különböző teljesítményosztályokban.', '2023-01-11 08:30:00', NULL, NULL),
(3, 'Alaplapok', 'ATX, microATX és ITX formátumú alaplapok különféle chipsetekkel.', '2023-01-12 13:45:00', NULL, NULL),
(4, 'Memória (RAM)', 'DDR4 és DDR5 memóriamodulok különböző órajelekkel és kapacitással.', '2023-01-13 07:20:00', NULL, NULL),
(5, 'Tápegységek', 'Minőségi PSU-k 400W-tól 1200W-ig, moduláris és nem moduláris kivitelben.', '2023-01-14 15:50:00', NULL, NULL),
(6, 'SSD-k', 'SATA és NVMe SSD-k nagy sebességű adattároláshoz.', '2023-01-15 10:05:00', NULL, NULL),
(7, 'Merevlemezek (HDD)', 'Nagy kapacitású 3.5” és 2.5” merevlemezek adattárolásra.', '2023-01-16 18:25:00', NULL, NULL),
(8, 'Házak', 'ATX, mATX és mini-ITX PC házak gamer és irodai felhasználásra.', '2023-01-17 09:15:00', NULL, NULL),
(9, 'Processzor hűtők', 'Léghűtők és folyadékhűtések CPU-khoz.', '2023-01-18 12:55:00', NULL, NULL),
(10, 'Videókártya hűtők', 'GPU hűtési megoldások jobb teljesítmény és halkabb működés érdekében.', '2023-01-19 16:40:00', NULL, NULL),
(11, 'Egerek', 'Vezetékes és vezeték nélküli gamer és irodai egerek.', '2023-01-20 08:10:00', NULL, NULL),
(12, 'Billentyűzetek', 'Mechanikus, membrános és gamer billentyűzetek háttérvilágítással.', '2023-01-21 13:35:00', NULL, NULL),
(13, 'Monitorok', 'Full HD, 2K és 4K monitorok 60Hz-től 240Hz-ig.', '2023-01-22 17:55:00', NULL, NULL),
(14, 'Hangszórók & Fejhallgatók', 'Gamer headsetek, mikrofonos fejhallgatók és sztereó hangszórók.', '2023-01-23 11:25:00', NULL, NULL),
(15, 'Egérpadok', 'Klasszikus és gamer egérpadok különböző méretekben.', '2023-01-24 19:05:00', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `orders`
--

CREATE TABLE `orders` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `address_id` int(11) NOT NULL,
  `total_price` decimal(10,2) NOT NULL,
  `status` enum('pending','paid','shipped','delivered','cancelled') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(4) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `orders`
--

INSERT INTO `orders` (`id`, `user_id`, `address_id`, `total_price`, `status`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(1, 1, 1, '12990.50', 'pending', '2023-01-16 10:15:00', NULL, NULL),
(2, 2, 2, '4590.00', 'paid', '2023-01-22 14:40:00', NULL, NULL),
(3, 3, 3, '25999.99', 'shipped', '2023-02-05 08:10:00', NULL, NULL),
(4, 4, 4, '8990.00', 'delivered', '2023-02-20 17:20:00', NULL, NULL),
(5, 5, 5, '13500.75', 'cancelled', '2023-03-07 12:30:00', NULL, NULL),
(6, 6, 6, '2200.00', 'pending', '2023-03-23 09:25:00', NULL, NULL),
(7, 7, 7, '7490.90', 'paid', '2023-04-11 10:50:00', NULL, NULL),
(8, 8, 8, '32999.00', 'shipped', '2023-04-27 15:05:00', NULL, NULL),
(9, 9, 9, '15490.25', 'delivered', '2023-05-13 07:40:00', NULL, NULL),
(10, 10, 10, '2750.00', 'pending', '2023-05-29 14:55:00', NULL, NULL),
(11, 11, 11, '19999.99', 'paid', '2023-06-17 06:15:00', NULL, NULL),
(12, 12, 12, '899.00', 'shipped', '2023-07-02 12:35:00', NULL, NULL),
(13, 13, 13, '5690.00', 'delivered', '2023-07-19 18:10:00', NULL, NULL),
(14, 14, 14, '14990.50', 'cancelled', '2023-08-05 05:25:00', NULL, NULL),
(15, 15, 15, '6999.99', 'pending', '2023-08-22 09:45:00', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `order_items`
--

CREATE TABLE `order_items` (
  `id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(4) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `product_id`, `quantity`, `price`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(61, 1, 31, 1, '399.99', '2025-10-03 07:51:25', NULL, NULL),
(62, 1, 32, 1, '799.99', '2025-10-03 07:51:25', NULL, NULL),
(63, 2, 33, 1, '129.99', '2025-10-03 07:51:25', NULL, NULL),
(64, 3, 34, 1, '999.99', '2025-10-03 07:51:25', NULL, NULL),
(65, 4, 35, 1, '399.99', '2025-10-03 07:51:25', NULL, NULL),
(66, 5, 36, 1, '279.99', '2025-10-03 07:51:25', NULL, NULL),
(67, 6, 37, 1, '119.99', '2025-10-03 07:51:25', NULL, NULL),
(68, 7, 38, 1, '69.99', '2025-10-03 07:51:25', NULL, NULL),
(69, 8, 39, 1, '499.99', '2025-10-03 07:51:25', NULL, NULL),
(70, 9, 40, 1, '129.99', '2025-10-03 07:51:25', NULL, NULL),
(71, 10, 41, 1, '69.99', '2025-10-03 07:51:25', NULL, NULL),
(72, 11, 42, 1, '799.99', '2025-10-03 07:51:25', NULL, NULL),
(73, 12, 43, 1, '349.99', '2025-10-03 07:51:25', NULL, NULL),
(74, 13, 44, 1, '89.99', '2025-10-03 07:51:25', NULL, NULL),
(75, 14, 45, 1, '149.99', '2025-10-03 07:51:25', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `products`
--

CREATE TABLE `products` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `price` decimal(10,2) NOT NULL,
  `stock` int(11) DEFAULT '0',
  `image_url` varchar(255) DEFAULT NULL,
  `category_id` int(11) NOT NULL,
  `brand_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(4) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `products`
--

INSERT INTO `products` (`id`, `name`, `description`, `price`, `stock`, `image_url`, `category_id`, `brand_id`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(31, 'Intel Core i7-12700K', '12th Gen Intel CPU', '399.99', 50, 'https://example.com/i7.png', 1, 1, '2025-10-03 07:23:38', NULL, NULL),
(32, 'AMD Ryzen 7 5800X', '8-core AMD CPU', '349.99', 40, 'https://example.com/ryzen.png', 1, 2, '2025-10-03 07:23:38', NULL, NULL),
(33, 'NVIDIA RTX 3080', 'High-end GPU', '799.99', 20, 'https://example.com/rtx3080.png', 2, 3, '2025-10-03 07:23:38', NULL, NULL),
(34, 'ASUS ROG Strix Z690', 'Gaming motherboard', '279.99', 30, 'https://example.com/z690.png', 3, 4, '2025-10-03 07:23:38', NULL, NULL),
(35, 'Corsair Vengeance 16GB', 'DDR4 RAM', '89.99', 100, 'https://example.com/vengeance.png', 4, 5, '2025-10-03 07:23:38', NULL, NULL),
(36, 'Samsung 970 EVO 1TB', 'NVMe SSD', '129.99', 60, 'https://example.com/970evo.png', 5, 6, '2025-10-03 07:23:38', NULL, NULL),
(37, 'Corsair RM750x', '750W PSU', '119.99', 45, 'https://example.com/rm750x.png', 6, 7, '2025-10-03 07:23:38', NULL, NULL),
(38, 'NZXT H510', 'Mid-tower case', '69.99', 25, 'https://example.com/h510.png', 7, 8, '2025-10-03 07:23:38', NULL, NULL),
(39, 'Noctua NH-U12S', 'CPU cooler', '69.99', 35, 'https://example.com/nhu12s.png', 8, 9, '2025-10-03 07:23:38', NULL, NULL),
(40, 'Dell UltraSharp 27\"', '4K monitor', '499.99', 15, 'https://example.com/ultrasharp.png', 9, 10, '2025-10-03 07:23:38', NULL, NULL),
(41, 'Logitech G Pro X', 'Mechanical keyboard', '129.99', 50, 'https://example.com/gprox.png', 10, 11, '2025-10-03 07:23:38', NULL, NULL),
(42, 'Razer DeathAdder V2', 'Gaming mouse', '69.99', 70, 'https://example.com/deathadder.png', 11, 12, '2025-10-03 07:23:38', NULL, NULL),
(43, 'Dell XPS 13', '13-inch laptop', '999.99', 10, 'https://example.com/xps13.png', 12, 13, '2025-10-03 07:23:38', NULL, NULL),
(44, 'TP-Link Archer C7', 'Wi-Fi router', '79.99', 30, 'https://example.com/archer.png', 14, 14, '2025-10-03 07:23:38', NULL, NULL),
(45, 'Windows 11 Pro', 'Operating system', '149.99', 100, 'https://example.com/win11.png', 15, 15, '2025-10-03 07:23:38', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `product_attributes`
--

CREATE TABLE `product_attributes` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `attribute_id` int(11) NOT NULL,
  `value` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(4) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `product_attributes`
--

INSERT INTO `product_attributes` (`id`, `product_id`, `attribute_id`, `value`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(31, 31, 1, '3.6', '2025-10-03 07:49:49', NULL, NULL),
(32, 32, 2, '12', '2025-10-03 07:49:49', NULL, NULL),
(33, 33, 3, '3.8', '2025-10-03 07:49:49', NULL, NULL),
(34, 34, 4, '8', '2025-10-03 07:49:49', NULL, NULL),
(35, 35, 5, '10', '2025-10-03 07:49:49', NULL, NULL),
(36, 36, 6, 'Z690', '2025-10-03 07:49:49', NULL, NULL),
(37, 37, 7, '3200', '2025-10-03 07:49:49', NULL, NULL),
(38, 38, 8, '1', '2025-10-03 07:49:49', NULL, NULL),
(39, 39, 9, '750', '2025-10-03 07:49:49', NULL, NULL),
(40, 40, 10, 'ATX', '2025-10-03 07:49:49', NULL, NULL),
(41, 41, 11, '120', '2025-10-03 07:49:49', NULL, NULL),
(42, 42, 12, '27', '2025-10-03 07:49:49', NULL, NULL),
(43, 43, 13, 'Mechanical', '2025-10-03 07:49:49', NULL, NULL),
(44, 44, 14, '16000', '2025-10-03 07:49:49', NULL, NULL),
(45, 45, 15, '12', '2025-10-03 07:49:49', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `reviews`
--

CREATE TABLE `reviews` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `rating` int(11) NOT NULL,
  `comment` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(4) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `reviews`
--

INSERT INTO `reviews` (`id`, `product_id`, `user_id`, `rating`, `comment`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(1, 32, 1, 5, 'Gyors kiszállítás!', '2025-10-03 07:28:54', NULL, NULL),
(2, 31, 2, 5, 'Pontos és tökéeltes kiszállítás!', '2025-10-03 07:30:25', NULL, NULL),
(3, 33, 3, 4, 'Hibátlan állapotban érkezett meg a termék!', '2025-10-03 07:31:27', NULL, NULL),
(4, 34, 4, 5, 'Nem a várt termék érkezett meghozzám!', '2025-10-03 07:32:15', NULL, NULL),
(6, 36, 6, 3, 'Nem időben érkezett meg, de viszont a termék hibátlan állapotban van!', '2025-10-03 07:35:46', NULL, NULL),
(7, 37, 7, 4, 'Összeségében elégedett vagyok a rendelésemmel!', '2025-10-03 07:36:45', NULL, NULL),
(8, 38, 8, 4, 'Jó!', '2025-10-03 07:37:03', NULL, NULL),
(9, 39, 9, 5, 'Tökéletes!', '2025-10-03 07:37:23', NULL, NULL),
(10, 40, 10, 5, 'Minden tökéletes!', '2025-10-03 07:37:50', NULL, NULL),
(11, 41, 11, 1, 'Megsem érkezett amit rendeltem pedig kifizettem!', '2025-10-03 07:38:42', NULL, NULL),
(12, 42, 12, 3, 'NEm vagyok teljesen megelégedve a termékemmel!', '2025-10-03 07:42:55', NULL, NULL),
(13, 43, 13, 1, 'Nem működik ez a fos!', '2025-10-03 07:43:29', NULL, NULL),
(14, 44, 14, 4, 'Nem rossz!', '2025-10-03 07:43:52', NULL, NULL),
(15, 45, 15, 2, 'Nem elégszem meg a termékem minőségével mivel olcsó az anyag minősége!', '2025-10-03 07:45:23', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('customer','admin') DEFAULT 'customer',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(1) DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `users`
--

INSERT INTO `users` (`id`, `username`, `email`, `phone`, `password_hash`, `role`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(1, 'Sancika', 'sanci@gmail.copm', '+36201234567', 'sancuuus', 'customer', '2025-09-05 07:52:07', 0, NULL),
(2, 'gerike', 'gercso@gmail.com', '+36303458912', 'asder', 'customer', '2025-09-05 07:53:57', 0, NULL),
(3, 'Adel', 'adel@gmail.com', '+36704231897', 'adel', 'customer', '2025-09-05 07:53:57', 0, NULL),
(4, 'peterk', 'peter.kiss@example.com', '', 'hash1234', 'customer', '2023-01-15 09:23:00', 0, NULL),
(5, 'annan', 'anna.nagy@example.com', '+36201234323', 'hash2345', 'customer', '2023-01-20 13:55:00', 0, NULL),
(6, 'bencesz', 'bence.szabo@example.com', '+36303458222', 'hash3456', 'admin', '2023-02-02 07:12:00', 0, NULL),
(7, 'lillat', 'lilla.toth@example.com', '+36704231111', 'hash4567', 'customer', '2023-02-18 15:40:00', 0, NULL),
(8, 'davidv', 'david.varga@example.com', '+36201234837', 'hash5678', 'customer', '2023-03-05 08:25:00', 0, NULL),
(9, 'zsofif', 'zsofia.farkas@example.com', '+36303458735', 'hash6789', 'customer', '2023-03-21 12:11:00', 0, NULL),
(10, 'matek', 'mate.kovacs@example.com', '+36704231153', 'hash7890', 'customer', '2023-04-10 09:33:00', 0, NULL),
(11, 'eszterb', 'eszter.balogh@example.com', '+36201234847', 'hash8901', 'admin', '2023-04-25 15:44:00', 0, NULL),
(12, 'gaborm', 'gabor.molnar@example.com', '+36303458938', 'hash9012', 'customer', '2023-05-12 06:50:00', 0, NULL),
(13, 'dorah', 'dora.horvath@example.com', '+36704231184', 'hash0123', 'customer', '2023-05-28 13:05:00', 0, NULL),
(14, 'adamp', 'adam.papp@example.com', '+36704231864', 'hash1122', 'customer', '2023-06-15 17:20:00', 0, NULL),
(15, 'noraj', 'nora.juhasz@example.com', '+36704231265', 'hash2233', 'admin', '2023-07-01 05:45:00', 0, NULL),
(16, 'pistike', 'pistike@gmail.com', '', 'asder123', 'customer', '2025-11-20 09:18:40', 0, NULL);

--
-- Indexek a kiírt táblákhoz
--

--
-- A tábla indexei `addresses`
--
ALTER TABLE `addresses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- A tábla indexei `attributes`
--
ALTER TABLE `attributes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `category_id` (`category_id`);

--
-- A tábla indexei `brands`
--
ALTER TABLE `brands`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- A tábla indexei `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- A tábla indexei `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `address_id` (`address_id`);

--
-- A tábla indexei `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `product_id` (`product_id`);

--
-- A tábla indexei `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD KEY `category_id` (`category_id`),
  ADD KEY `brand_id` (`brand_id`);

--
-- A tábla indexei `product_attributes`
--
ALTER TABLE `product_attributes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `attribute_id` (`attribute_id`);

--
-- A tábla indexei `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `user_id` (`user_id`);

--
-- A tábla indexei `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- A kiírt táblák AUTO_INCREMENT értéke
--

--
-- AUTO_INCREMENT a táblához `addresses`
--
ALTER TABLE `addresses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT a táblához `attributes`
--
ALTER TABLE `attributes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT a táblához `brands`
--
ALTER TABLE `brands`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT a táblához `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT a táblához `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT a táblához `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=76;

--
-- AUTO_INCREMENT a táblához `products`
--
ALTER TABLE `products`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT a táblához `product_attributes`
--
ALTER TABLE `product_attributes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT a táblához `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT a táblához `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- Megkötések a kiírt táblákhoz
--

--
-- Megkötések a táblához `addresses`
--
ALTER TABLE `addresses`
  ADD CONSTRAINT `addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Megkötések a táblához `attributes`
--
ALTER TABLE `attributes`
  ADD CONSTRAINT `attributes_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`);

--
-- Megkötések a táblához `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`address_id`) REFERENCES `addresses` (`id`);

--
-- Megkötések a táblához `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`);

--
-- Megkötések a táblához `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`),
  ADD CONSTRAINT `products_ibfk_2` FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`);

--
-- Megkötések a táblához `product_attributes`
--
ALTER TABLE `product_attributes`
  ADD CONSTRAINT `product_attributes_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `product_attributes_ibfk_2` FOREIGN KEY (`attribute_id`) REFERENCES `attributes` (`id`);

--
-- Megkötések a táblához `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
