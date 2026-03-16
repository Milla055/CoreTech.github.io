-- phpMyAdmin SQL Dump
-- version 5.1.2
-- https://www.phpmyadmin.net/
--
-- Gép: localhost:8889
-- Létrehozás ideje: 2026. Már 16. 09:58
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
DROP PROCEDURE IF EXISTS `addProductNotification`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `addProductNotification` (IN `emailIN` VARCHAR(255), IN `productIdIN` BIGINT)   BEGIN
    DECLARE existingNotification INT DEFAULT 0;
    
    SELECT COUNT(*) INTO existingNotification
    FROM `product_notifications`
    WHERE `user_email` = emailIN
      AND `product_id` = productIdIN
      AND `notified` = 0;
    
    IF existingNotification = 0 THEN
        INSERT INTO `product_notifications` (`user_email`, `product_id`)
        VALUES (emailIN, productIdIN);
        
        SELECT 'SUCCESS' AS `status`, 'Notification added successfully' AS `message`;
    ELSE
        SELECT 'ALREADY_EXISTS' AS `status`, 'You are already subscribed for this product' AS `message`;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `addProductToConfiguration`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `addProductToConfiguration` (IN `configurationIdIN` BIGINT, IN `productIdIN` BIGINT, IN `quantityIN` INT, IN `componentTypeIN` VARCHAR(50), IN `isRequiredIN` TINYINT(1))   BEGIN
    INSERT INTO `configuration_products` (
        `configuration_id`,
        `product_id`,
        `quantity`,
        `component_type`,
        `is_required`
    ) VALUES (
        configurationIdIN,
        productIdIN,
        quantityIN,
        componentTypeIN,
        isRequiredIN
    );
    
    SELECT 'SUCCESS' AS `status`, 'Product added to configuration' AS `message`;
END$$

DROP PROCEDURE IF EXISTS `addToCart`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `addToCart` (IN `userIdIN` INT, IN `productIdIN` INT, IN `quantityIN` INT)   BEGIN
    DECLARE cartId    INT DEFAULT NULL;
    DECLARE itemExists INT DEFAULT 0;

    -- Aktív kosár keresése a userhez
    SELECT `cart`.`id` INTO cartId
    FROM `cart`
    WHERE `cart`.`user_id` = userIdIN
      AND `cart`.`is_deleted` IS NULL
    LIMIT 1;

    -- Ha nincs aktív kosár, létrehozzuk
    IF cartId IS NULL THEN
        INSERT INTO `cart` (`user_id`) VALUES (userIdIN);
        SET cartId = LAST_INSERT_ID();
    END IF;

    -- Ellenőrizzük, hogy a termék már benne van-e
    SELECT COUNT(*) INTO itemExists
    FROM `cart_items`
    WHERE `cart_items`.`cart_id`    = cartId
      AND `cart_items`.`product_id` = productIdIN
      AND `cart_items`.`is_deleted` IS NULL;

    IF itemExists > 0 THEN
        -- Már benne van → mennyiség növelése
        UPDATE `cart_items`
        SET `cart_items`.`quantity` = `cart_items`.`quantity` + quantityIN
        WHERE `cart_items`.`cart_id`    = cartId
          AND `cart_items`.`product_id` = productIdIN
          AND `cart_items`.`is_deleted` IS NULL;
    ELSE
        -- Még nincs benne → új tétel
        INSERT INTO `cart_items` (`cart_id`, `product_id`, `quantity`)
        VALUES (cartId, productIdIN, quantityIN);
    END IF;
END$$

DROP PROCEDURE IF EXISTS `checkout`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `checkout` (IN `userIdIN` INT, IN `addressIdIN` INT, OUT `newOrderId` INT)   BEGIN
    DECLARE cartId     INT     DEFAULT NULL;
    DECLARE totalPrice DECIMAL(10,2) DEFAULT 0;
    
    -- Aktív kosár id
    SELECT `cart`.`id` INTO cartId
    FROM `cart`
    WHERE `cart`.`user_id`    = userIdIN
      AND `cart`.`is_deleted` IS NULL
    LIMIT 1;
    
    -- Végösszeg számítás
    SELECT SUM(`cart_items`.`quantity` * `products`.`price`)
    INTO totalPrice
    FROM `cart_items`
    INNER JOIN `products` ON `cart_items`.`product_id` = `products`.`id`
    WHERE `cart_items`.`cart_id`    = cartId
      AND `cart_items`.`is_deleted` IS NULL
      AND `products`.`is_deleted`   IS NULL;
    
    -- Új rendelés létrehozása
    INSERT INTO `orders` (`user_id`, `address_id`, `total_price`, `status`)
    VALUES (userIdIN, addressIdIN, totalPrice, 'pending');
    
    SET newOrderId = LAST_INSERT_ID();  -- ← This sets the OUT parameter
    
    -- Cart tételek átmásolása order_items-be
    INSERT INTO `order_items` (`order_id`, `product_id`, `quantity`, `price`)
    SELECT
        newOrderId,
        `cart_items`.`product_id`,
        `cart_items`.`quantity`,
        `products`.`price`
    FROM `cart_items`
    INNER JOIN `products` ON `cart_items`.`product_id` = `products`.`id`
    WHERE `cart_items`.`cart_id`    = cartId
      AND `cart_items`.`is_deleted` IS NULL
      AND `products`.`is_deleted`   IS NULL;
    
    -- Kosár törlése
    CALL clearCart(userIdIN);
END$$

DROP PROCEDURE IF EXISTS `checkoutCart`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `checkoutCart` (IN `userIdIN` INT, IN `addressIdIN` INT, OUT `newOrderId` INT)   BEGIN
    DECLARE cartId     INT     DEFAULT NULL;
    DECLARE totalPrice DECIMAL(10,2) DEFAULT 0;

    -- Aktív kosár id
    SELECT `cart`.`id` INTO cartId
    FROM `cart`
    WHERE `cart`.`user_id`    = userIdIN
      AND `cart`.`is_deleted` IS NULL
    LIMIT 1;

    -- Végösszeg számítás
    SELECT SUM(`cart_items`.`quantity` * `products`.`price`)
    INTO totalPrice
    FROM `cart_items`
    INNER JOIN `products` ON `cart_items`.`product_id` = `products`.`id`
    WHERE `cart_items`.`cart_id`    = cartId
      AND `cart_items`.`is_deleted` IS NULL
      AND `products`.`is_deleted`   IS NULL;

    -- Új rendelés létrehozása
    INSERT INTO `orders` (`user_id`, `address_id`, `total_price`, `status`)
    VALUES (userIdIN, addressIdIN, totalPrice, 'pending');

    SET newOrderId = LAST_INSERT_ID();

    -- Cart tételek átmásolása order_items-be
    INSERT INTO `order_items` (`order_id`, `product_id`, `quantity`, `price`)
    SELECT
        newOrderId,
        `cart_items`.`product_id`,
        `cart_items`.`quantity`,
        `products`.`price`
    FROM `cart_items`
    INNER JOIN `products` ON `cart_items`.`product_id` = `products`.`id`
    WHERE `cart_items`.`cart_id`    = cartId
      AND `cart_items`.`is_deleted` IS NULL
      AND `products`.`is_deleted`   IS NULL;

    -- Kosár törlése
    CALL clearCart(userIdIN);
END$$

DROP PROCEDURE IF EXISTS `clearCart`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `clearCart` (IN `userIdIN` INT)   BEGIN
    DECLARE cartId INT DEFAULT NULL;

    SELECT `cart`.`id` INTO cartId
    FROM `cart`
    WHERE `cart`.`user_id` = userIdIN
      AND `cart`.`is_deleted` IS NULL
    LIMIT 1;

    IF cartId IS NOT NULL THEN
        -- HARD DELETE - teljesen töröljük a tételeket
        DELETE FROM `cart_items`
        WHERE `cart_items`.`cart_id` = cartId;
        
        -- A cart MARAD, updated_at frissül
        UPDATE `cart`
        SET `cart`.`updated_at` = NOW()
        WHERE `cart`.`id` = cartId;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `createAddress`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `createAddress` (IN `userIDIN` INT, IN `streetIN` VARCHAR(255), IN `cityIN` VARCHAR(100), IN `postalcodeIN` VARCHAR(20), IN `countryIN` VARCHAR(100), IN `isDefaultIN` TINYINT)   BEGIN
    -- Ha ez lesz alapértelmezett, előbb nullázzuk a többit
    IF isDefaultIN = 1 THEN
        UPDATE addresses
        SET is_default = 0
        WHERE user_id = userIDIN
          AND is_deleted IS NULL;
    END IF;

    -- Új cím beszúrása
    INSERT INTO addresses(user_id, street, city, postal_code, country, is_default)
    VALUES (userIDIN, streetIN, cityIN, postalcodeIN, countryIN, isDefaultIN);
END$$

DROP PROCEDURE IF EXISTS `createAttributes`$$
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

DROP PROCEDURE IF EXISTS `createBrands`$$
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

DROP PROCEDURE IF EXISTS `createCategories`$$
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

DROP PROCEDURE IF EXISTS `createFavorites`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `createFavorites` (IN `userIdIN` INT, IN `productIdIN` INT)   BEGIN
    -- Ellenőrizzük, hogy már létezik-e ez a kedvenc
    DECLARE favoriteExists INT;
    
    SELECT COUNT(*) INTO favoriteExists
    FROM `favorites`
    WHERE `favorites`.`user_id` = userIdIN 
    AND `favorites`.`product_id` = productIdIN;
    
    -- Ha még nem létezik, akkor hozzáadjuk
    IF favoriteExists = 0 THEN
        INSERT INTO `favorites`(
            `favorites`.`user_id`,
            `favorites`.`product_id`
        )
        VALUES (
            userIdIN,
            productIdIN
        );
    END IF;
END$$

DROP PROCEDURE IF EXISTS `createOrderItems`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `createOrderItems` (IN `orderIdiN` INT, IN `productIdIN` INT, IN `quantityIN` INT, IN `priceIN` DOUBLE)   BEGIN

INSERT INTO `order_items`(
	`order_items`.`order_id`,
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

DROP PROCEDURE IF EXISTS `createOrders`$$
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

DROP PROCEDURE IF EXISTS `createPCConfiguration`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `createPCConfiguration` (IN `nameIN` VARCHAR(255), IN `descriptionIN` TEXT, IN `budgetMinIN` INT, IN `budgetMaxIN` INT, IN `useCaseIN` VARCHAR(50), IN `gameTypesIN` VARCHAR(255), IN `requirementLevelIN` TINYINT, IN `totalPriceIN` DECIMAL(10,2), IN `isFeaturedIN` TINYINT(1))   BEGIN
    INSERT INTO `pc_configurations` (
        `name`,
        `description`,
        `budget_min`,
        `budget_max`,
        `use_case`,
        `game_types`,
        `requirement_level`,
        `total_price`,
        `is_featured`
    ) VALUES (
        nameIN,
        descriptionIN,
        budgetMinIN,
        budgetMaxIN,
        useCaseIN,
        gameTypesIN,
        requirementLevelIN,
        totalPriceIN,
        isFeaturedIN
    );
    
    SELECT LAST_INSERT_ID() AS `new_configuration_id`;
END$$

DROP PROCEDURE IF EXISTS `createProductAttributes`$$
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

DROP PROCEDURE IF EXISTS `createProducts`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `createProducts` (IN `categoryIdIN` INT, IN `brandIdIN` INT, IN `nameIN` VARCHAR(100), IN `descriptionIN` VARCHAR(100), IN `priceIN` DOUBLE, IN `stockIN` INT, IN `imageurlIN` VARCHAR(100), IN `ppriceIN` INT)   BEGIN

INSERT INTO `products`(
	`products`.`name`,
    `products`.`description`,
    `products`.`price`,
    `products`.`stock`,
    `products`.`image_url`,
    `products`.`category_id`,
    `products`.`brand_id`,
    `products`.`p_price`
)
VALUES (
    nameIN,
    descriptionIN,
    priceIN,
    stockIN,
    imageurlIN,
    categoryIdIN,
    brandIdIN,
    ppriceIN
);

END$$

DROP PROCEDURE IF EXISTS `createReviews`$$
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

DROP PROCEDURE IF EXISTS `createUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `createUser` (IN `usernameIN` VARCHAR(100), IN `emailIN` VARCHAR(100), IN `passwordIN` MEDIUMTEXT, IN `phoneIN` VARCHAR(50), IN `roleIN` VARCHAR(30))   BEGIN

INSERT INTO `users`(
    `users`.`username`,
    `users`.`email`,
    `users`.`password_hash`,
    `users`.`phone`,
    `users`.`role`
)
VALUES (
    usernameIN,
    emailIN,
    passwordIN,
    phoneIN,
    roleIN
);

END$$

DROP PROCEDURE IF EXISTS `deleteFavorites`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteFavorites` (IN `userIdIN` INT, IN `productIdIN` INT)   BEGIN
    DELETE FROM `favorites`
    WHERE `favorites`.`user_id` = userIdIN 
    AND `favorites`.`product_id` = productIdIN;
END$$

DROP PROCEDURE IF EXISTS `getAddressById`$$
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

DROP PROCEDURE IF EXISTS `getAddressesByUserId`$$
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

DROP PROCEDURE IF EXISTS `getAllAddresses`$$
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

DROP PROCEDURE IF EXISTS `getAllAttributes`$$
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

DROP PROCEDURE IF EXISTS `getAllBrands`$$
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

DROP PROCEDURE IF EXISTS `getAllCategories`$$
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

DROP PROCEDURE IF EXISTS `getAllFavorites`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllFavorites` ()   BEGIN
    SELECT 
        `favorites`.`id`,
        `favorites`.`user_id`,
        `favorites`.`product_id`,
        `favorites`.`created_at`,
        `users`.`username`,
        `products`.`name` AS product_name,
        `products`.`price` AS product_price,
        `categories`.`name` AS category_name,
        `brands`.`name` AS brand_name
    FROM `favorites`
    INNER JOIN `users` ON `favorites`.`user_id` = `users`.`id`
    INNER JOIN `products` ON `favorites`.`product_id` = `products`.`id`
    INNER JOIN `categories` ON `products`.`category_id` = `categories`.`id`
    INNER JOIN `brands` ON `products`.`brand_id` = `brands`.`id`
    WHERE `products`.`is_deleted` IS NULL
    AND `users`.`is_deleted` = 0
    ORDER BY `favorites`.`created_at` DESC;
END$$

DROP PROCEDURE IF EXISTS `getAllOrders`$$
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

DROP PROCEDURE IF EXISTS `getAllProducts`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllProducts` ()   BEGIN
    SELECT 
        `products`.`id`,
        `products`.`name`,
        `products`.`description`,
        `products`.`properties`,
        `products`.`price`,
        `products`.`p_price`,
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

DROP PROCEDURE IF EXISTS `getAllReviews`$$
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

DROP PROCEDURE IF EXISTS `getAllUsers`$$
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

DROP PROCEDURE IF EXISTS `getAttributeById`$$
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

DROP PROCEDURE IF EXISTS `getBrandById`$$
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

DROP PROCEDURE IF EXISTS `getCartByUserId`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getCartByUserId` (IN `userIdIN` INT)   BEGIN
    SELECT
        `cart`.`id`                        AS cart_id,
        `cart`.`user_id`,
        `cart`.`created_at`                AS cart_created_at,
        `cart_items`.`id`                  AS item_id,
        `cart_items`.`product_id`,
        `cart_items`.`quantity`,
        `products`.`name`                  AS product_name,
        `products`.`price`                 AS product_price,
        `products`.`p_price`               AS product_p_price,
        `products`.`image_url`             AS product_image_url,
        `products`.`stock`                 AS product_stock,
        `categories`.`name`                AS category_name,
        `brands`.`name`                    AS brand_name,
        (`cart_items`.`quantity` * `products`.`price`) AS line_total
    FROM `cart`
    INNER JOIN `cart_items`  ON `cart_items`.`cart_id`          = `cart`.`id`
                             AND `cart_items`.`is_deleted`        IS NULL
    INNER JOIN `products`    ON `cart_items`.`product_id`        = `products`.`id`
                             AND `products`.`is_deleted`          IS NULL
    INNER JOIN `categories`  ON `products`.`category_id`         = `categories`.`id`
    INNER JOIN `brands`      ON `products`.`brand_id`            = `brands`.`id`
    WHERE `cart`.`user_id`    = userIdIN
      AND `cart`.`is_deleted` IS NULL
    ORDER BY `cart_items`.`created_at` ASC;
END$$

DROP PROCEDURE IF EXISTS `getCategoryById`$$
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

DROP PROCEDURE IF EXISTS `getConfigurationDetails`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getConfigurationDetails` (IN `configIdIN` BIGINT)   BEGIN
    SELECT 
        `pc`.`id`,
        `pc`.`name`,
        `pc`.`description`,
        `pc`.`budget_min`,
        `pc`.`budget_max`,
        `pc`.`use_case`,
        `pc`.`game_types`,
        `pc`.`requirement_level`,
        `pc`.`total_price`,
        `pc`.`is_featured`,
        `pc`.`created_at`
    FROM `pc_configurations` `pc`
    WHERE `pc`.`id` = configIdIN
      AND `pc`.`is_deleted` IS NULL
    LIMIT 1;
END$$

DROP PROCEDURE IF EXISTS `getConfigurationProducts`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getConfigurationProducts` (IN `configIdIN` BIGINT)   BEGIN
    SELECT 
        `cp`.`id` AS `config_product_id`,
        `cp`.`component_type`,
        `cp`.`quantity`,
        `cp`.`is_required`,
        `p`.`id` AS `product_id`,
        `p`.`name` AS `product_name`,
        `p`.`description` AS `product_description`,
        `p`.`price`,
        `p`.`stock`,
        `p`.`image_url`,
        `c`.`name` AS `category_name`,
        `b`.`name` AS `brand_name`,
        (`p`.`price` * `cp`.`quantity`) AS `subtotal`,
        CASE 
            WHEN `p`.`stock` >= `cp`.`quantity` THEN 1
            ELSE 0
        END AS `in_stock`
    FROM `configuration_products` `cp`
    INNER JOIN `products` `p` ON `cp`.`product_id` = `p`.`id`
    LEFT JOIN `categories` `c` ON `p`.`category_id` = `c`.`id`
    LEFT JOIN `brands` `b` ON `p`.`brand_id` = `b`.`id`
    WHERE `cp`.`configuration_id` = configIdIN
      AND `cp`.`is_deleted` IS NULL
      AND `p`.`is_deleted` IS NULL
    ORDER BY 
        FIELD(`cp`.`component_type`, 'CPU', 'GPU', 'MOTHERBOARD', 'RAM', 'STORAGE', 'PSU', 'COOLER', 'CASE', 'OTHER'),
        `p`.`name` ASC;
END$$

DROP PROCEDURE IF EXISTS `getFavoriteById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getFavoriteById` (IN `favoriteIdIN` INT)   BEGIN
    SELECT
        `favorites`.`id`,
        `favorites`.`user_id`,
        `favorites`.`product_id`,
        `favorites`.`created_at`,
        `users`.`username`,
        `products`.`name`          AS product_name,
        `products`.`description`   AS product_description,
        `products`.`price`         AS product_price,
        `products`.`p_price`       AS product_p_price,
        `products`.`stock`         AS product_stock,
        `products`.`image_url`     AS product_image_url,
        `products`.`category_id`,
        `products`.`brand_id`,
        `categories`.`name`        AS category_name,
        `brands`.`name`            AS brand_name
    FROM `favorites`
    INNER JOIN `users`      ON `favorites`.`user_id`      = `users`.`id`
    INNER JOIN `products`   ON `favorites`.`product_id`   = `products`.`id`
    INNER JOIN `categories` ON `products`.`category_id`   = `categories`.`id`
    INNER JOIN `brands`     ON `products`.`brand_id`      = `brands`.`id`
    WHERE `favorites`.`id` = favoriteIdIN
    AND `products`.`is_deleted` IS NULL
    AND `users`.`is_deleted` = 0
    LIMIT 1;
END$$

DROP PROCEDURE IF EXISTS `getFavoriteCountByUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getFavoriteCountByUser` (IN `userIdIN` INT)   BEGIN
    SELECT COUNT(*) AS favorite_count
    FROM `favorites`
    INNER JOIN `products` ON `favorites`.`product_id` = `products`.`id`
    WHERE `favorites`.`user_id` = userIdIN
    AND `products`.`is_deleted` IS NULL;
END$$

DROP PROCEDURE IF EXISTS `getFavoritesByUserId`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getFavoritesByUserId` (IN `userIdIN` INT)   BEGIN
    SELECT 
        `favorites`.`id`,
        `favorites`.`user_id`,
        `favorites`.`product_id`,
        `favorites`.`created_at`,
        `products`.`name` AS product_name,
        `products`.`description` AS product_description,
        `products`.`price` AS product_price,
        `products`.`p_price` AS product_p_price,
        `products`.`stock` AS product_stock,
        `products`.`image_url` AS product_image_url,
        `products`.`category_id`,
        `products`.`brand_id`,
        `categories`.`name` AS category_name,
        `brands`.`name` AS brand_name
    FROM `favorites`
    INNER JOIN `products` ON `favorites`.`product_id` = `products`.`id`
    INNER JOIN `categories` ON `products`.`category_id` = `categories`.`id`
    INNER JOIN `brands` ON `products`.`brand_id` = `brands`.`id`
    WHERE `favorites`.`user_id` = userIdIN
    AND `products`.`is_deleted` IS NULL
    ORDER BY `favorites`.`created_at` DESC;
END$$

DROP PROCEDURE IF EXISTS `getGamesList`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getGamesList` (IN `gameTypeFilter` VARCHAR(50))   BEGIN
    IF gameTypeFilter IS NULL OR gameTypeFilter = '' THEN
        SELECT 
            `id`,
            `name`,
            `game_type`,
            `requirement_level`,
            `description`
        FROM `games`
        WHERE `is_deleted` IS NULL
        ORDER BY `requirement_level` ASC, `name` ASC;
    ELSE
        SELECT 
            `id`,
            `name`,
            `game_type`,
            `requirement_level`,
            `description`
        FROM `games`
        WHERE `is_deleted` IS NULL
          AND `game_type` = gameTypeFilter
        ORDER BY `requirement_level` ASC, `name` ASC;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `getOrderById`$$
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

DROP PROCEDURE IF EXISTS `getOrderItemById`$$
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

DROP PROCEDURE IF EXISTS `getOrderItemsByOrderId`$$
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

DROP PROCEDURE IF EXISTS `getOrdersByUserId`$$
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

DROP PROCEDURE IF EXISTS `getPendingNotifications`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getPendingNotifications` (IN `productIdIN` BIGINT)   BEGIN
    IF productIdIN IS NULL THEN
        SELECT 
            `pn`.`id` AS `notification_id`,
            `pn`.`user_email`,
            `pn`.`product_id`,
            `pn`.`created_at`,
            `p`.`name` AS `product_name`,
            `p`.`price`,
            `p`.`stock`
        FROM `product_notifications` `pn`
        INNER JOIN `products` `p` ON `pn`.`product_id` = `p`.`id`
        WHERE `pn`.`notified` = 0
          AND `p`.`stock` > 0
          AND `p`.`is_deleted` IS NULL
        ORDER BY `pn`.`created_at` ASC;
    ELSE
        SELECT 
            `pn`.`id` AS `notification_id`,
            `pn`.`user_email`,
            `pn`.`product_id`,
            `pn`.`created_at`,
            `p`.`name` AS `product_name`,
            `p`.`price`,
            `p`.`stock`
        FROM `product_notifications` `pn`
        INNER JOIN `products` `p` ON `pn`.`product_id` = `p`.`id`
        WHERE `pn`.`notified` = 0
          AND `pn`.`product_id` = productIdIN
          AND `p`.`stock` > 0
          AND `p`.`is_deleted` IS NULL
        ORDER BY `pn`.`created_at` ASC;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `getProductAttributeById`$$
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

DROP PROCEDURE IF EXISTS `getProductAttributesByProductId`$$
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

DROP PROCEDURE IF EXISTS `getProductById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getProductById` (IN `productIdIN` INT)   BEGIN
    SELECT 
        `products`.`id`,
        `products`.`name`,
        `products`.`description`,
        `products`.`properties`,
        `products`.`price`,
        `products`.`p_price`,
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

DROP PROCEDURE IF EXISTS `getProductsByBrandId`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getProductsByBrandId` (IN `brandIdIN` INT)   BEGIN
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
    WHERE `products`.`brand_id` = brandIdIN AND `products`.`is_deleted` IS NULL
    ORDER BY `products`.`created_at` DESC;
END$$

DROP PROCEDURE IF EXISTS `getProductsByCategoryId`$$
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

DROP PROCEDURE IF EXISTS `getRecommendedConfigurations`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getRecommendedConfigurations` (IN `budgetMinIN` INT, IN `budgetMaxIN` INT, IN `useCaseIN` VARCHAR(50), IN `selectedGameIdsIN` TEXT)   BEGIN
    DECLARE maxRequirementLevel TINYINT DEFAULT 1;
    DECLARE gameTypesString VARCHAR(500) DEFAULT '';
    
    IF selectedGameIdsIN IS NOT NULL AND selectedGameIdsIN != '' THEN
        SELECT MAX(`requirement_level`) INTO maxRequirementLevel
        FROM `games`
        WHERE FIND_IN_SET(`id`, selectedGameIdsIN) > 0
          AND `is_deleted` IS NULL;
        
        SELECT GROUP_CONCAT(DISTINCT `game_type` SEPARATOR ',') INTO gameTypesString
        FROM `games`
        WHERE FIND_IN_SET(`id`, selectedGameIdsIN) > 0
          AND `is_deleted` IS NULL;
    END IF;
    
    IF maxRequirementLevel IS NULL THEN
        SET maxRequirementLevel = 1;
    END IF;
    
    IF useCaseIN = 'gaming' AND selectedGameIdsIN IS NOT NULL AND selectedGameIdsIN != '' THEN
        SELECT 
            `pc`.`id`,
            `pc`.`name`,
            `pc`.`description`,
            `pc`.`budget_min`,
            `pc`.`budget_max`,
            `pc`.`use_case`,
            `pc`.`game_types`,
            `pc`.`requirement_level`,
            `pc`.`total_price`,
            `pc`.`is_featured`
        FROM `pc_configurations` `pc`
        WHERE `pc`.`is_deleted` IS NULL
          AND `pc`.`use_case` = 'gaming'
          AND `pc`.`budget_min` <= budgetMaxIN
          AND `pc`.`budget_max` >= budgetMinIN
          AND `pc`.`requirement_level` >= maxRequirementLevel
          AND (
              `pc`.`game_types` IS NULL 
              OR gameTypesString IS NULL
              OR (
                  FIND_IN_SET(SUBSTRING_INDEX(gameTypesString, ',', 1), `pc`.`game_types`) > 0
                  OR FIND_IN_SET(SUBSTRING_INDEX(SUBSTRING_INDEX(gameTypesString, ',', 2), ',', -1), `pc`.`game_types`) > 0
                  OR FIND_IN_SET(SUBSTRING_INDEX(SUBSTRING_INDEX(gameTypesString, ',', 3), ',', -1), `pc`.`game_types`) > 0
                  OR FIND_IN_SET(SUBSTRING_INDEX(gameTypesString, ',', -1), `pc`.`game_types`) > 0
              )
          )
        ORDER BY 
            `pc`.`is_featured` DESC,
            ABS(`pc`.`requirement_level` - maxRequirementLevel) ASC,
            `pc`.`total_price` ASC
        LIMIT 5;
        
    ELSEIF useCaseIN = 'gaming' AND (selectedGameIdsIN IS NULL OR selectedGameIdsIN = '') THEN
        SELECT 
            `pc`.`id`,
            `pc`.`name`,
            `pc`.`description`,
            `pc`.`budget_min`,
            `pc`.`budget_max`,
            `pc`.`use_case`,
            `pc`.`game_types`,
            `pc`.`requirement_level`,
            `pc`.`total_price`,
            `pc`.`is_featured`
        FROM `pc_configurations` `pc`
        WHERE `pc`.`is_deleted` IS NULL
          AND `pc`.`use_case` = 'gaming'
          AND `pc`.`budget_min` <= budgetMaxIN
          AND `pc`.`budget_max` >= budgetMinIN
        ORDER BY 
            `pc`.`is_featured` DESC,
            `pc`.`total_price` ASC
        LIMIT 5;
        
    ELSE
        SELECT 
            `pc`.`id`,
            `pc`.`name`,
            `pc`.`description`,
            `pc`.`budget_min`,
            `pc`.`budget_max`,
            `pc`.`use_case`,
            `pc`.`game_types`,
            `pc`.`requirement_level`,
            `pc`.`total_price`,
            `pc`.`is_featured`
        FROM `pc_configurations` `pc`
        WHERE `pc`.`is_deleted` IS NULL
          AND `pc`.`use_case` = useCaseIN
          AND `pc`.`budget_min` <= budgetMaxIN
          AND `pc`.`budget_max` >= budgetMinIN
        ORDER BY 
            `pc`.`is_featured` DESC,
            `pc`.`total_price` ASC
        LIMIT 5;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `getReviewById`$$
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

DROP PROCEDURE IF EXISTS `getReviewsByProductId`$$
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

DROP PROCEDURE IF EXISTS `getUserById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserById` (IN `userIdIN` INT)   BEGIN
    SELECT 
        `users`.`id`,
        `users`.`username`,
        `users`.`teljesnév`,
        `users`.`email`,
        `users`.`phone`,
        `users`.`password_hash`,
        `users`.`role`,
        `users`.`created_at`,
        `users`.`is_subscripted`
    FROM `users`
    WHERE `users`.`id` = userIdIN AND `users`.`is_deleted` = 0
    LIMIT 1;
END$$

DROP PROCEDURE IF EXISTS `login`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `login` (IN `emailIN` VARCHAR(255))   BEGIN

    SELECT `users`.`password_hash`, `users`.`username`,`users`.`role`
    FROM users
    WHERE `users`.`is_deleted` = 0 AND `users`.`email` = emailIN
    LIMIT 1;
    
END$$

DROP PROCEDURE IF EXISTS `markNotificationAsSent`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `markNotificationAsSent` (IN `notificationIdIN` BIGINT)   BEGIN
    UPDATE `product_notifications`
    SET 
        `notified` = 1,
        `notified_at` = NOW()
    WHERE `id` = notificationIdIN;
    
    SELECT 'SUCCESS' AS `status`, 'Notification marked as sent' AS `message`;
END$$

DROP PROCEDURE IF EXISTS `removeFromCart`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `removeFromCart` (IN `cartItemIdIN` INT)   BEGIN
    UPDATE `cart_items`
    SET
        `cart_items`.`is_deleted` = 1,
        `cart_items`.`deleted_at` = NOW()
    WHERE `cart_items`.`id` = cartItemIdIN;
END$$

DROP PROCEDURE IF EXISTS `setDefaultAddress`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `setDefaultAddress` (IN `addressIdIN` INT, IN `userIdIN` INT)   BEGIN
    -- Először minden cím is_default-ját nullázzuk
    UPDATE addresses
    SET is_default = 0
    WHERE user_id = userIdIN
      AND is_deleted IS NULL;

    -- Aztán a kiválasztottnál 1-re állítjuk
    UPDATE addresses
    SET is_default = 1
    WHERE id = addressIdIN
      AND user_id = userIdIN
      AND is_deleted IS NULL;
END$$

DROP PROCEDURE IF EXISTS `softDelAddresses`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelAddresses` (IN `addressesIdIN` INT)   BEGIN
    UPDATE `addresses`
    SET 
        `addresses`.`is_deleted` = 1,
        `addresses`.`deleted_at` = NOW()
    WHERE `addresses`.`id` = addressesIdIN;
END$$

DROP PROCEDURE IF EXISTS `softDelAttributes`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelAttributes` (IN `attributesIdIN` INT)   BEGIN
    UPDATE `attributes`
    SET 
        `attributes`.`is_deleted` = 1,
        `attributes`.`deleted_at` = NOW()
    WHERE `attributes`.`id` = attributesIdIN;
END$$

DROP PROCEDURE IF EXISTS `softDelBrands`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelBrands` (IN `brandsIdIN` INT)   BEGIN
    UPDATE `brands`
    SET 
        `brands`.`is_deleted` = 1,
        `brands`.`deleted_at` = NOW()
    WHERE `brands`.`id` = brandsIdIN;
END$$

DROP PROCEDURE IF EXISTS `softDelCategories`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelCategories` (IN `categoriesIdIN` INT)   BEGIN
    UPDATE `categories`
    SET 
        `categories`.`is_deleted` = 1,
        `categories`.`deleted_at` = NOW()
    WHERE `categories`.`id` = categoriesIdIN;
END$$

DROP PROCEDURE IF EXISTS `softDelOrderItems`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelOrderItems` (IN `orderItemsIdIN` INT)   BEGIN
    UPDATE `order_items`
    SET 
        `order_items`.`is_deleted` = 1,
        `order_items`.`deleted_at` = NOW()
    WHERE `order_items`.`id` = orderItemsIdIN;
END$$

DROP PROCEDURE IF EXISTS `softDelOrders`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelOrders` (IN `ordersIdIN` INT)   BEGIN
    UPDATE `orders`
    SET 
        `orders`.`is_deleted` = 1,
        `orders`.`deleted_at` = NOW()
    WHERE `orders`.`id` = ordersIdIN;
END$$

DROP PROCEDURE IF EXISTS `softDelProductAttributes`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelProductAttributes` (IN `productAttributesIdIN` INT)   BEGIN
    UPDATE `product_attributes`
    SET 
        `product_attributes`.`is_deleted` = 1,
        `product_attributes`.`deleted_at` = NOW()
    WHERE `product_attributes`.`id` = productAttributesIdIN;
END$$

DROP PROCEDURE IF EXISTS `softDelProducts`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelProducts` (IN `productsIdIN` INT)   BEGIN
    UPDATE `products`
    SET 
        `products`.`is_deleted` = 1,
        `products`.`deleted_at` = NOW()
    WHERE `products`.`id` = productsIdIN;
END$$

DROP PROCEDURE IF EXISTS `softDelReviews`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelReviews` (IN `reviewsIdIN` INT)   BEGIN
    UPDATE `reviews`
    SET 
        `reviews`.`is_deleted` = 1,
        `reviews`.`deleted_at` = NOW()
    WHERE `reviews`.`id` = reviewsIdIN;
END$$

DROP PROCEDURE IF EXISTS `softDelUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `softDelUser` (IN `userIDIN` INT)   BEGIN
    UPDATE `users`
    SET 
        `users`.`is_deleted` = 1,
        `users`.`deleted_at` = NOW()
    WHERE `users`.`id` = userIDIN;
END$$

DROP PROCEDURE IF EXISTS `updateAddressById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateAddressById` (IN `addressIdIN` INT, IN `streetIN` VARCHAR(100), IN `cityIN` VARCHAR(100), IN `postalcodeIN` VARCHAR(20), IN `countryIN` VARCHAR(100), IN `isDefaultIN` TINYINT)   BEGIN
    DECLARE userIdVar INT;

    -- Kinyerjük melyik userhez tartozik
    SELECT user_id INTO userIdVar
    FROM addresses
    WHERE id = addressIdIN;

    -- Ha alapértelmezett lesz, nullázzuk a többit
    IF isDefaultIN = 1 THEN
        UPDATE addresses
        SET is_default = 0
        WHERE user_id = userIdVar
          AND is_deleted IS NULL;
    END IF;

    -- Frissítés
    UPDATE addresses
    SET 
        street = streetIN,
        city = cityIN,
        postal_code = postalcodeIN,
        country = countryIN,
        is_default = isDefaultIN
    WHERE id = addressIdIN 
      AND is_deleted IS NULL;
END$$

DROP PROCEDURE IF EXISTS `updateAttributeById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateAttributeById` (IN `attributeIdIN` INT, IN `nameIN` VARCHAR(255), IN `unitIN` VARCHAR(50), IN `categoryIdIN` INT)   BEGIN
    UPDATE `attributes`
    SET 
        `attributes`.`name` = nameIN,
        `attributes`.`unit` = unitIN,
        `attributes`.`category_id` = categoryIdIN
    WHERE `attributes`.`id` = attributeIdIN AND `attributes`.`is_deleted` IS NULL;
END$$

DROP PROCEDURE IF EXISTS `updateBrandById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateBrandById` (IN `brandIdIN` INT, IN `nameIN` VARCHAR(100), IN `descriptionIN` TEXT, IN `logourlIN` VARCHAR(255))   BEGIN
    UPDATE `brands`
    SET 
        `brands`.`name` = nameIN,
        `brands`.`description` = descriptionIN,
        `brands`.`logo_url` = logourlIN
    WHERE `brands`.`id` = brandIdIN AND `brands`.`is_deleted` IS NULL;
END$$

DROP PROCEDURE IF EXISTS `updateCartItemQuantity`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateCartItemQuantity` (IN `cartItemIdIN` INT, IN `quantityIN` INT)   BEGIN
    IF quantityIN <= 0 THEN
        UPDATE `cart_items`
        SET
            `cart_items`.`is_deleted` = 1,
            `cart_items`.`deleted_at` = NOW()
        WHERE `cart_items`.`id` = cartItemIdIN;
    ELSE
        UPDATE `cart_items`
        SET `cart_items`.`quantity` = quantityIN
        WHERE `cart_items`.`id` = cartItemIdIN
          AND `cart_items`.`is_deleted` IS NULL;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `updateCategoryById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateCategoryById` (IN `categoryIdIN` INT, IN `nameIN` VARCHAR(100), IN `descriptionIN` TEXT)   BEGIN
    UPDATE `categories`
    SET 
        `categories`.`name` = nameIN,
        `categories`.`description` = descriptionIN
    WHERE `categories`.`id` = categoryIdIN AND `categories`.`is_deleted` IS NULL;
END$$

DROP PROCEDURE IF EXISTS `updateConfigurationTotalPrice`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateConfigurationTotalPrice` (IN `configurationIdIN` BIGINT)   BEGIN
    DECLARE newTotalPrice DECIMAL(10,2) DEFAULT 0;
    
    SELECT SUM(`p`.`price` * `cp`.`quantity`) INTO newTotalPrice
    FROM `configuration_products` `cp`
    INNER JOIN `products` `p` ON `cp`.`product_id` = `p`.`id`
    WHERE `cp`.`configuration_id` = configurationIdIN
      AND `cp`.`is_deleted` IS NULL
      AND `p`.`is_deleted` IS NULL;
    
    UPDATE `pc_configurations`
    SET `total_price` = COALESCE(newTotalPrice, 0)
    WHERE `id` = configurationIdIN;
    
    SELECT 'SUCCESS' AS `status`, COALESCE(newTotalPrice, 0) AS `new_total_price`;
END$$

DROP PROCEDURE IF EXISTS `updateFavoriteById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateFavoriteById` (IN `favoriteIdIN` INT, IN `userIdIN` INT, IN `productIdIN` INT)   BEGIN
    DECLARE favoriteExists INT;

    SELECT COUNT(*) INTO favoriteExists
    FROM `favorites`
    WHERE `favorites`.`user_id`    = userIdIN
    AND   `favorites`.`product_id` = productIdIN
    AND   `favorites`.`id`        != favoriteIdIN;

    IF favoriteExists = 0 THEN
        UPDATE `favorites`
        SET
            `favorites`.`user_id`    = userIdIN,
            `favorites`.`product_id` = productIdIN
        WHERE `favorites`.`id` = favoriteIdIN;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `updateOrderById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrderById` (IN `orderIdIN` INT, IN `statusIN` VARCHAR(50))   BEGIN
    UPDATE `orders`
    SET 
        `orders`.`status` = statusIN
    WHERE `orders`.`id` = orderIdIN AND `orders`.`is_deleted` IS NULL;
END$$

DROP PROCEDURE IF EXISTS `updateOrderItemById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrderItemById` (IN `orderItemIdIN` INT, IN `quantityIN` INT, IN `priceIN` DECIMAL(10,2))   BEGIN
    UPDATE `order_items`
    SET 
        `order_items`.`quantity` = quantityIN,
        `order_items`.`price` = priceIN
    WHERE `order_items`.`id` = orderItemIdIN AND `order_items`.`is_deleted` IS NULL;
END$$

DROP PROCEDURE IF EXISTS `updatePassword`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updatePassword` (IN `userIdIN` INT, IN `passwordIN` VARCHAR(100))   BEGIN
    UPDATE `users`
    SET 
        `users`.`password_hash` = passwordIN
    WHERE `users`.`id` = userIdIN AND `users`.`is_deleted` = 0;
END$$

DROP PROCEDURE IF EXISTS `updateProductAttributeById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateProductAttributeById` (IN `productAttributeIdIN` INT, IN `valueIN` VARCHAR(255))   BEGIN
    UPDATE `product_attributes`
    SET 
        `product_attributes`.`value` = valueIN
    WHERE `product_attributes`.`id` = productAttributeIdIN AND `product_attributes`.`is_deleted` IS NULL;
END$$

DROP PROCEDURE IF EXISTS `updateProductById`$$
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

DROP PROCEDURE IF EXISTS `updateReviewById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateReviewById` (IN `reviewIdIN` INT, IN `ratingIN` INT, IN `commentIN` TEXT)   BEGIN
    UPDATE `reviews`
    SET 
        `reviews`.`rating` = ratingIN,
        `reviews`.`comment` = commentIN
    WHERE `reviews`.`id` = reviewIdIN AND `reviews`.`is_deleted` IS NULL;
END$$

DROP PROCEDURE IF EXISTS `updateUserById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUserById` (IN `userIdIN` INT, IN `usernameIN` VARCHAR(100), IN `emailIN` VARCHAR(100), IN `roleIN` VARCHAR(30), IN `phoneIN` VARCHAR(50))   BEGIN
    UPDATE `users`
    SET 
        `users`.`username` = usernameIN,
        `users`.`email` = emailIN,
        `users`.`role` = roleIN,
        `users`.`phone` = phoneIN
    WHERE `users`.`id` = userIdIN AND `users`.`is_deleted` = 0;
END$$

DROP PROCEDURE IF EXISTS `updateUserProfile`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUserProfile` (IN `userIdIN` INT, IN `usernameIN` VARCHAR(100), IN `teljesnevIN` VARCHAR(255), IN `emailIN` VARCHAR(255), IN `phoneIN` VARCHAR(50))   BEGIN
    UPDATE `users`
    SET 
        `users`.`username` = usernameIN,
        `users`.`teljesnév` = teljesnevIN,
        `users`.`email` = emailIN,
        `users`.`phone` = phoneIN
    WHERE `users`.`id` = userIdIN 
      AND `users`.`is_deleted` = 0;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `addresses`
--

DROP TABLE IF EXISTS `addresses`;
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
(1, 1, 'Fő utca 12.', 'Budapest', '1011', 'Magyarország', 1, '2025-08-13 08:30:00', NULL, NULL),
(2, 2, 'Kossuth tér 5.', 'Debrecen', '4024', 'Magyarország', 1, '2025-08-13 12:50:00', NULL, NULL),
(3, 3, 'Tisza Lajos krt. 18.', 'Szeged', '6720', 'Magyarország', 0, '2025-08-14 06:20:00', NULL, NULL),
(4, 4, 'Rákóczi út 45.', 'Pécs', '7621', 'Magyarország', 1, '2025-08-14 14:45:00', NULL, NULL),
(5, 5, 'Baross Gábor út 3.', 'Győr', '9022', 'Magyarország', 0, '2025-08-15 07:15:00', NULL, NULL),
(6, 6, 'Széchenyi István út 11.', 'Miskolc', '3525', 'Magyarország', 1, '2025-08-15 10:20:00', NULL, NULL),
(7, 7, 'Kossuth Lajos út 8.', 'Nyíregyháza', '4400', 'Magyarország', 0, '2025-08-15 11:40:00', NULL, NULL),
(8, 8, 'Fő tér 2.', 'Székesfehérvár', '8000', 'Magyarország', 1, '2025-08-15 15:55:00', NULL, NULL),
(9, 9, 'Katona József tér 7.', 'Kecskemét', '6000', 'Magyarország', 0, '2025-08-16 06:35:00', NULL, NULL),
(10, 10, 'Dobó István tér 1.', 'Eger', '3300', 'Magyarország', 1, '2025-08-16 08:10:00', NULL, NULL),
(11, 11, 'Várkerület 20.', 'Sopron', '9400', 'Magyarország', 0, '2025-08-16 12:05:00', NULL, NULL),
(12, 12, 'Fő tér 9.', 'Szombathely', '9700', 'Magyarország', 1, '2025-08-17 05:50:00', NULL, NULL),
(13, 13, 'Petőfi Sándor utca 14.', 'Salgótarján', '3100', 'Magyarország', 0, '2025-08-17 10:30:00', NULL, NULL),
(14, 14, 'Rákóczi út 22.', 'Tatabánya', '2800', 'Magyarország', 1, '2025-08-17 19:15:00', NULL, NULL),
(15, 15, 'Kossuth Lajos utca 6.', 'Zalaegerszeg', '8900', 'Magyarország', 0, '2025-08-18 07:59:00', NULL, NULL),
(16, 5, 'szigetiut', 'Pécs', '7636', 'Hungary', 0, '2025-08-18 08:33:23', NULL, NULL),
(18, 50, 'alkotmány tér 5', 'Kozármisleny', '7761', 'Magyarország', 1, '2026-03-02 09:57:30', NULL, NULL),
(19, 52, 'Petőfi utca 1.', 'Pécs', '7634', 'Magyarország', 1, '2026-03-02 20:01:33', NULL, NULL),
(21, 56, 'Petőfi utca 1.', 'Pécs', '7634', 'Magyarország', 1, '2026-03-03 07:25:25', NULL, NULL),
(22, 57, 'Bolgár köz 5.', 'Pécs', '7634', 'Magyarország', 1, '2026-03-03 07:48:22', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `attributes`
--

DROP TABLE IF EXISTS `attributes`;
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
(1, 'Clock Speed', 'GHz', 2, '2025-10-03 07:19:06', NULL, NULL),
(2, 'Cores', 'Count', 2, '2025-10-03 07:19:06', NULL, NULL),
(3, 'VRAM', 'GB', 1, '2025-10-03 07:19:06', NULL, NULL),
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
(16, 'test', 'testest', 6, '2025-11-20 09:34:55', NULL, NULL),
(17, 'teszt', 'teszt', 1, '2026-02-03 08:01:24', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `brands`
--

DROP TABLE IF EXISTS `brands`;
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
(16, 'NZXT', 'PC cases and cooling solutions', 'https://example.com/nzxt.png', '2025-10-03 05:18:11', NULL, NULL),
(17, 'Noctua', 'Premium CPU coolers and case fans', 'https://example.com/noctua.png', '2025-10-03 05:18:11', NULL, NULL),
(18, 'SteelSeries', 'SteelSeries is a premium gaming gear brand built for performance and esports', 'teszteszt', '2026-02-03 08:03:20', NULL, NULL),
(19, 'SAMSON', 'Professional audio equipment and microphone manufacturer', 'https://example.com/samson.png', '2026-02-19 09:16:10', NULL, NULL),
(20, 'Finalmouse', 'Ultra-lightweight premium gaming mouse manufacturer', 'teszt', '2026-02-25 08:58:15', NULL, NULL),
(21, 'Attack Shark', 'Budget-to-mid gaming peripherals with high-end sensors', 'teszt', '2026-02-25 08:58:31', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `cart`
--

DROP TABLE IF EXISTS `cart`;
CREATE TABLE `cart` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint(4) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `cart`
--

INSERT INTO `cart` (`id`, `user_id`, `created_at`, `updated_at`, `is_deleted`, `deleted_at`) VALUES
(20, 50, '2026-03-02 09:58:06', '2026-03-02 09:58:06', NULL, NULL),
(21, 52, '2026-03-02 20:02:23', '2026-03-06 09:03:57', NULL, NULL),
(23, 56, '2026-03-03 07:26:04', '2026-03-03 07:26:38', NULL, NULL),
(24, 57, '2026-03-03 07:48:52', '2026-03-03 07:49:29', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `cart_items`
--

DROP TABLE IF EXISTS `cart_items`;
CREATE TABLE `cart_items` (
  `id` int(11) NOT NULL,
  `cart_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint(4) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `categories`
--

DROP TABLE IF EXISTS `categories`;
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
(1, 'Videókártyák', 'NVIDIA és AMD videókártyák játékhoz, munkához és szerverekhez.', '2025-08-11 10:00:00', NULL, NULL),
(2, 'Processzorok', 'Intel és AMD CPU-k különböző teljesítményosztályokban.', '2025-08-12 07:30:00', NULL, NULL),
(3, 'Alaplapok', 'ATX, microATX és ITX formátumú alaplapok különféle chipsetekkel.', '2025-08-12 12:45:00', NULL, NULL),
(4, 'Memória (RAM)', 'DDR4 és DDR5 memóriamodulok különböző órajelekkel és kapacitással.', '2025-08-12 06:20:00', NULL, NULL),
(5, 'Tápegységek', 'Minőségi PSU-k 400W-tól 1200W-ig, moduláris és nem moduláris kivitelben.', '2025-08-12 14:50:00', NULL, NULL),
(6, 'SSD-k', 'SATA és NVMe SSD-k nagy sebességű adattároláshoz.', '2025-08-12 09:05:00', NULL, NULL),
(7, 'Merevlemezek (HDD)', 'Nagy kapacitású 3.5” és 2.5” merevlemezek adattárolásra.', '2025-08-12 17:25:00', NULL, NULL),
(8, 'Házak', 'ATX, mATX és mini-ITX PC házak gamer és irodai felhasználásra.', '2025-08-13 08:15:00', NULL, NULL),
(9, 'Processzor hűtők', 'Léghűtők és folyadékhűtések CPU-khoz.', '2025-08-13 11:55:00', NULL, NULL),
(10, 'Videókártya hűtők', 'GPU hűtési megoldások jobb teljesítmény és halkabb működés érdekében.', '2025-08-13 15:40:00', NULL, NULL),
(11, 'Egerek', 'Vezetékes és vezeték nélküli gamer és irodai egerek.', '2025-08-14 07:10:00', NULL, NULL),
(12, 'Billentyűzetek', 'Mechanikus, membrános és gamer billentyűzetek háttérvilágítással.', '2025-08-14 12:35:00', NULL, NULL),
(13, 'Monitorok', 'Full HD, 2K és 4K monitorok 60Hz-től 240Hz-ig.', '2025-08-14 16:55:00', NULL, NULL),
(14, 'Hangszórók & Fejhallgatók', 'Gamer headsetek, mikrofonos fejhallgatók és sztereó hangszórók.', '2025-08-15 10:25:00', NULL, NULL),
(15, 'Egérpadok', 'Klasszikus és gamer egérpadok különböző méretekben.', '2025-08-15 18:05:00', NULL, NULL),
(16, 'Mikrofon', 'csak külön mikrofonok, álványos mikrofon, stúdió mikrofon', '2026-01-23 10:29:44', NULL, NULL),
(17, 'teszt', 'teszteszt', '2026-02-03 08:10:57', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `configuration_products`
--

DROP TABLE IF EXISTS `configuration_products`;
CREATE TABLE `configuration_products` (
  `id` bigint(20) NOT NULL,
  `configuration_id` bigint(20) NOT NULL,
  `product_id` bigint(20) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT '1',
  `component_type` enum('CPU','GPU','RAM','MOTHERBOARD','PSU','CASE','STORAGE','COOLER','OTHER') NOT NULL,
  `is_required` tinyint(1) DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(1) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `favorites`
--

DROP TABLE IF EXISTS `favorites`;
CREATE TABLE `favorites` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `favorites`
--

INSERT INTO `favorites` (`id`, `user_id`, `product_id`, `created_at`) VALUES
(27, 56, 48, '2026-03-03 07:25:50'),
(29, 57, 55, '2026-03-03 07:48:42');

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `games`
--

DROP TABLE IF EXISTS `games`;
CREATE TABLE `games` (
  `id` bigint(20) NOT NULL,
  `name` varchar(255) NOT NULL,
  `game_type` enum('solo_rpg','competitive_fps','aaa_games','indie_casual') NOT NULL COMMENT 'Játék típusa',
  `requirement_level` tinyint(4) NOT NULL COMMENT '1=Office/Basic, 2=Light Gaming, 3=Mid-range, 4=High-end, 5=Enthusiast/4K',
  `min_cpu_score` int(11) DEFAULT NULL,
  `min_gpu_score` int(11) DEFAULT NULL,
  `min_ram_gb` int(11) DEFAULT NULL,
  `recommended_storage_type` enum('HDD','SSD','NVME') DEFAULT 'SSD',
  `description` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(1) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `games`
--

INSERT INTO `games` (`id`, `name`, `game_type`, `requirement_level`, `min_cpu_score`, `min_gpu_score`, `min_ram_gb`, `recommended_storage_type`, `description`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(1, 'The Witcher 3', 'solo_rpg', 3, 7000, 6000, 8, 'SSD', 'Nyílt világú RPG', '2026-03-16 09:55:57', NULL, NULL),
(2, 'Cyberpunk 2077', 'solo_rpg', 5, 12000, 15000, 16, 'NVME', 'AAA RPG, ray-tracing', '2026-03-16 09:55:57', NULL, NULL),
(3, 'Elden Ring', 'solo_rpg', 4, 9000, 10000, 12, 'SSD', 'Souls-like RPG', '2026-03-16 09:55:57', NULL, NULL),
(4, 'Skyrim', 'solo_rpg', 2, 4000, 3000, 8, 'HDD', 'Régebbi RPG', '2026-03-16 09:55:57', NULL, NULL),
(5, 'CS2 (Counter-Strike 2)', 'competitive_fps', 3, 7000, 6000, 16, 'SSD', 'Kompetitív FPS', '2026-03-16 09:55:57', NULL, NULL),
(6, 'Valorant', 'competitive_fps', 2, 5000, 4000, 8, 'SSD', 'Könnyű FPS', '2026-03-16 09:55:57', NULL, NULL),
(7, 'Apex Legends', 'competitive_fps', 3, 7500, 7000, 16, 'SSD', 'Battle royale', '2026-03-16 09:55:57', NULL, NULL),
(8, 'Overwatch 2', 'competitive_fps', 3, 7000, 6500, 8, 'SSD', 'Team-based FPS', '2026-03-16 09:55:57', NULL, NULL),
(9, 'Red Dead Redemption 2', 'aaa_games', 5, 11000, 14000, 16, 'SSD', 'Grafikai mestermű', '2026-03-16 09:55:57', NULL, NULL),
(10, 'Hogwarts Legacy', 'aaa_games', 4, 9000, 10000, 16, 'SSD', 'Modern AAA', '2026-03-16 09:55:57', NULL, NULL),
(11, 'God of War', 'aaa_games', 4, 9500, 11000, 16, 'NVME', 'PlayStation port', '2026-03-16 09:55:57', NULL, NULL),
(12, 'Starfield', 'aaa_games', 4, 10000, 12000, 16, 'NVME', 'Űr RPG', '2026-03-16 09:55:57', NULL, NULL),
(13, 'Stardew Valley', 'indie_casual', 1, 2000, 1000, 4, 'HDD', 'Pixel art farming', '2026-03-16 09:55:57', NULL, NULL),
(14, 'Terraria', 'indie_casual', 1, 2500, 1500, 4, 'HDD', '2D sandbox', '2026-03-16 09:55:57', NULL, NULL),
(15, 'Hades', 'indie_casual', 2, 4000, 3500, 8, 'SSD', 'Roguelike', '2026-03-16 09:55:57', NULL, NULL),
(16, 'Hollow Knight', 'indie_casual', 1, 3000, 2000, 4, 'SSD', '2D metroidvania', '2026-03-16 09:55:57', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `orders`
--

DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `address_id` int(11) NOT NULL,
  `total_price` decimal(10,2) NOT NULL,
  `status` varchar(100) DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(4) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `orders`
--

INSERT INTO `orders` (`id`, `user_id`, `address_id`, `total_price`, `status`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(1, 1, 1, '12990.50', 'shipping', '2025-12-06 11:10:30', NULL, NULL),
(2, 2, 2, '4590.00', 'shipping', '2025-12-06 11:11:30', NULL, NULL),
(3, 3, 3, '25999.99', 'delivered', '2025-12-06 11:12:30', NULL, NULL),
(4, 4, 4, '8990.00', 'delivered', '2025-12-06 11:13:30', NULL, NULL),
(5, 5, 5, '13500.75', 'cancelled', '2025-12-06 11:13:43', NULL, NULL),
(6, 6, 6, '2200.00', 'shipping', '2025-12-06 11:13:47', NULL, NULL),
(7, 7, 7, '7490.90', 'shipping', '2025-12-06 11:13:50', NULL, NULL),
(8, 8, 8, '32999.00', 'delivered', '2025-12-06 11:13:54', NULL, NULL),
(9, 9, 9, '15490.25', 'delivered', '2025-12-06 11:14:40', NULL, NULL),
(10, 10, 10, '2750.00', 'shipping', '2025-12-06 11:14:42', NULL, NULL),
(11, 11, 11, '19999.99', 'shipping', '2025-12-06 11:14:44', NULL, NULL),
(15, 15, 15, '6999.99', 'shipping', '2025-12-06 11:14:52', NULL, NULL),
(16, 17, 3, '28999.00', 'pending', '2025-12-06 11:14:54', NULL, NULL),
(17, 5, 5, '99999.00', 'processing', '2026-02-03 08:19:09', NULL, NULL),
(24, 56, 21, '849999.00', 'pending', '2026-03-03 07:26:38', NULL, NULL),
(25, 57, 22, '851489.00', 'pending', '2026-03-03 07:49:29', NULL, NULL),
(26, 52, 19, '121800.00', 'pending', '2026-03-06 09:03:57', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `order_items`
--

DROP TABLE IF EXISTS `order_items`;
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
(81, 24, 238, 1, '849999.00', '2026-03-03 07:26:38', NULL, NULL),
(82, 25, 238, 1, '849999.00', '2026-03-03 07:49:29', NULL, NULL),
(83, 26, 189, 1, '41900.00', '2026-03-06 09:03:57', NULL, NULL),
(84, 26, 148, 1, '79900.00', '2026-03-06 09:03:57', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `pc_configurations`
--

DROP TABLE IF EXISTS `pc_configurations`;
CREATE TABLE `pc_configurations` (
  `id` bigint(20) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `budget_min` int(11) NOT NULL,
  `budget_max` int(11) NOT NULL,
  `use_case` enum('gaming','video_editing','programming','all_purpose') NOT NULL,
  `game_types` varchar(255) DEFAULT NULL,
  `requirement_level` tinyint(4) NOT NULL,
  `total_price` decimal(10,2) NOT NULL,
  `is_featured` tinyint(1) DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(1) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `pc_configurations`
--

INSERT INTO `pc_configurations` (`id`, `name`, `description`, `budget_min`, `budget_max`, `use_case`, `game_types`, `requirement_level`, `total_price`, `is_featured`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(1, 'Budget Gaming PC', 'Belépő gaming indie és régebbi játékokhoz. 1080p, közepes beállítások.', 200000, 350000, 'gaming', 'indie_casual,competitive_fps', 2, '289990.00', 1, '2026-03-16 09:55:58', NULL, NULL),
(2, 'Mid-Range Gaming PC', 'Modern játékokhoz 1080p-1440p, magas beállítások.', 350000, 550000, 'gaming', 'competitive_fps,aaa_games,solo_rpg', 3, '459990.00', 1, '2026-03-16 09:55:58', NULL, NULL),
(3, 'High-End Gaming PC', 'Prémium 1440p-4K, ultra beállítások, ray-tracing.', 550000, 800000, 'gaming', 'aaa_games,solo_rpg,competitive_fps', 4, '689990.00', 1, '2026-03-16 09:55:58', NULL, NULL),
(4, 'Enthusiast 4K Gaming PC', 'Top tier 4K max beállítások, streaming, content creation.', 800000, 1500000, 'gaming', 'aaa_games,solo_rpg,competitive_fps', 5, '1199990.00', 0, '2026-03-16 09:55:58', NULL, NULL),
(5, 'Competitive FPS Beast', 'Optimalizált competitive gaming, 240Hz+, low input lag.', 400000, 600000, 'gaming', 'competitive_fps', 3, '499990.00', 1, '2026-03-16 09:55:58', NULL, NULL),
(6, 'Video Editing Workstation', 'Professzionális videószerkesztés: erős CPU, 32GB+ RAM.', 450000, 700000, 'video_editing', NULL, 4, '599990.00', 0, '2026-03-16 09:55:58', NULL, NULL),
(7, 'Budget Content Creator', 'Kezdő content creator: streaming, basic videószerkesztés.', 300000, 450000, 'video_editing', NULL, 3, '379990.00', 0, '2026-03-16 09:55:58', NULL, NULL),
(8, 'Developer Workstation', 'Programozói munkaállomás: gyors CPU, 32GB RAM.', 350000, 550000, 'programming', NULL, 3, '449990.00', 0, '2026-03-16 09:55:58', NULL, NULL),
(9, 'Office / Home PC', 'Irodai használat: böngészés, Office, Teams, videóhívások.', 150000, 250000, 'programming', NULL, 1, '189990.00', 0, '2026-03-16 09:55:58', NULL, NULL),
(10, 'All-Purpose Powerhouse', 'Univerzális: gaming, munka, content creation.', 600000, 900000, 'all_purpose', 'aaa_games,solo_rpg,competitive_fps', 4, '749990.00', 1, '2026-03-16 09:55:58', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `products`
--

DROP TABLE IF EXISTS `products`;
CREATE TABLE `products` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `properties` json DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `p_price` decimal(11,2) NOT NULL,
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

INSERT INTO `products` (`id`, `name`, `description`, `properties`, `price`, `p_price`, `stock`, `image_url`, `category_id`, `brand_id`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(31, 'Intel Core i7-12700K', '12th Gen Intel CPU', '{\"pcie\": \"PCIe 5.0 (16 lane) + PCIe 4.0 (4 lane)\", \"gyarto\": \"Intel\", \"sorozat\": \"Core i7\", \"tdp_max\": \"190 W (PL2)\", \"cache_l2\": \"12 MB\", \"cache_l3\": \"25 MB Intel Smart Cache\", \"foglalat\": \"LGA 1700\", \"tdp_alap\": \"125 W (PL1)\", \"generacio\": \"12. generáció (Alder Lake)\", \"megjegyzes\": \"Hibrid architektúra Thread Director-ral\", \"magok_szama\": \"12 (8 P-core + 4 E-core)\", \"max_memoria\": \"128 GB (dual-channel)\", \"szalak_szama\": \"20\", \"integralt_gpu\": \"Intel UHD Graphics 770\", \"feloldott_szorzo\": \"Igen\", \"e_core_max_orajel\": \"3.8 GHz\", \"p_core_max_orajel\": \"5.0 GHz (Turbo Boost Max 3.0)\", \"e_core_alap_orajel\": \"2.7 GHz\", \"p_core_alap_orajel\": \"3.6 GHz\", \"tamogatott_memoria\": \"DDR5-4800, DDR4-3200\", \"gyartasi_technologia\": \"Intel 7 (10nm)\"}', '110000.99', '99000.99', 50, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 1, '2025-10-03 07:23:38', NULL, NULL),
(32, 'AMD Ryzen 7 5800X', '8-core AMD CPU', '{\"tdp\": \"105 W\", \"pcie\": \"PCIe 4.0 (20 lane)\", \"gyarto\": \"AMD\", \"sorozat\": \"Ryzen 7\", \"cache_l2\": \"4 MB\", \"cache_l3\": \"32 MB\", \"foglalat\": \"AM4\", \"generacio\": \"5000 sorozat (Zen 3)\", \"max_orajel\": \"4.7 GHz (Precision Boost)\", \"megjegyzes\": \"Zen 3 architektúra, kiváló gaming teljesítmény\", \"alap_orajel\": \"3.8 GHz\", \"magok_szama\": \"8\", \"max_memoria\": \"128 GB (dual-channel)\", \"szalak_szama\": \"16\", \"integralt_gpu\": \"Nincs\", \"feloldott_szorzo\": \"Igen\", \"tamogatott_memoria\": \"DDR4-3200\", \"gyartasi_technologia\": \"TSMC 7nm\"}', '80000.99', '70000.99', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 2, '2025-10-03 07:23:38', NULL, NULL),
(33, 'GIGABYTE GV-N710D3-2GL GeForce GT 710', '2GB DDR3 PCIE', '{\"DVI\": \"Igen\", \"HDMI\": \"1db\", \"Hossz\": \"144mm\", \"Súly\": \"0g\", \"Hangtalan\": \"Nem\", \"VGA/D-SUB\": \"Nem\", \"DisplayPort\": \"0db\", \"Helyfoglalás\": \"1\", \"Videó chipset\": \"GeForce GT 710\", \"Memória mérete\": \"2GB\", \"Memória típusa\": \"DDR3\", \"Mini DisplayPort\": \"0db\", \"Chipset gyártója\": \"NVIDIA\", \"Ajánlott min. táp.\": \"300watt\"}', '170000.99', '160000.99', 20, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 1, 3, '2025-10-03 07:23:38', 1, '2026-02-26 12:25:22'),
(34, 'ASUS ROG Strix Z690E', 'Gaming motherboard', '{\"rgb\": \"Aura Sync\", \"audio\": \"SupremeFX 7.1\", \"gyarto\": \"ASUS\", \"chipset\": \"Intel Z690\", \"halozat\": \"2.5G LAN, WiFi 6E\", \"sorozat\": \"ROG Strix\", \"foglalat\": \"LGA 1700\", \"m2_slotok\": \"4x M.2 (PCIe 4.0)\", \"megjegyzes\": \"Premium Z690 gaming alaplap\", \"max_memoria\": \"128 GB\", \"pcie_slotok\": \"1x PCIe 5.0 x16, 2x PCIe 4.0 x16\", \"sata_portok\": \"6x SATA III\", \"forma_faktor\": \"ATX\", \"memoria_tipus\": \"DDR5\", \"memoria_slotok\": \"4 x DIMM\", \"tamogatott_cpu\": \"Intel 12. es 13. gen (Alder Lake, Raptor Lake)\", \"memoria_sebesseg\": \"DDR5-6400+ (OC)\"}', '125500.99', '110000.99', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 3, 4, '2025-10-03 07:23:38', NULL, NULL),
(35, 'Corsair Vengeance 16GB', 'DDR4 RAM', '{\"ecc\": \"Nem\", \"rgb\": \"Nem\", \"tipus\": \"DDR4\", \"gyarto\": \"Corsair\", \"konfig\": \"2 x 8 GB\", \"sorozat\": \"Vengeance\", \"timings\": \"16-18-18-36\", \"sebesseg\": \"3200 MHz\", \"kapacitas\": \"16 GB\", \"feszultseg\": \"1.35V\", \"megjegyzes\": \"Alacsony profil, fekete hőelvezetővel\", \"cas_latency\": \"CL16\", \"forma_faktor\": \"DIMM 288-pin\"}', '620000.99', '550000.99', 100, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 7, '2025-10-03 07:23:38', NULL, NULL),
(36, 'Samsung 970 EVO 1TB', 'NVMe SSD', '{\"tbw\": \"600 TB\", \"iras\": \"2500 MB/s\", \"tipus\": \"NVMe M.2\", \"gyarto\": \"Samsung\", \"olvasas\": \"3500 MB/s\", \"sorozat\": \"970 EVO\", \"garancia\": \"5 ev\", \"interfesz\": \"PCIe 3.0 x4\", \"kapacitas\": \"1 TB\", \"megjegyzes\": \"Megbizhato NVMe SSD\", \"nand_tipus\": \"3D TLC V-NAND\", \"random_iras\": \"480K IOPS\", \"forma_faktor\": \"M.2 2280\", \"random_olvasas\": \"500K IOPS\"}', '90000.99', '78000.99', 60, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 8, '2025-10-03 07:23:38', NULL, NULL),
(37, 'Corsair RM750x', '750W PSU', '{\"pfc\": \"Aktiv PFC\", \"gyarto\": \"Corsair\", \"sorozat\": \"RM Series\", \"vedelem\": \"OVP, UVP, OCP, OTP, SCP\", \"garancia\": \"10 ev\", \"hatekonyag\": \"80 Plus Gold\", \"megjegyzes\": \"Zero RPM mod, alacsony zaj\", \"modularitas\": \"Teljesen modularis\", \"ventillator\": \"135mm FDB ventillator\", \"forma_faktor\": \"ATX\", \"teljesitmeny\": \"750 W\"}', '60000.99', '50000.99', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 7, '2025-10-03 07:23:38', 1, '2026-03-02 09:50:52'),
(38, 'NZXT H510', 'Mid-tower case', '{\"szin\": \"Fekete/Fehér\", \"gyarto\": \"NZXT\", \"meretek\": \"210 x 460 x 428 mm\", \"sorozat\": \"H Series\", \"io_panel\": \"1x USB 3.1 Gen 2 Type-C, 1x USB 3.1 Gen 1, Audio\", \"megjegyzes\": \"Minimalista design, jó kábel menedzsment\", \"oldalpanel\": \"Edzett üveg\", \"max_alaplap\": \"ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"2+1\", \"drive_bay_35\": \"2\", \"forma_faktor\": \"Mid-Tower ATX\", \"max_gpu_hossz\": \"381 mm\", \"max_psu_hossz\": \"180 mm\", \"radiator_tamogatas\": \"Elöl: 2x120/140mm, Fent: 1x120mm\", \"ventillator_helyek\": \"2x 120mm elöl, 1x 120mm hátul\", \"max_cpu_huto_magassag\": \"165 mm\"}', '35000.99', '28000.99', 25, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 16, '2025-10-03 07:23:38', NULL, NULL),
(39, 'Noctua NH-U12S', 'CPU cooler', '{\"tdp\": \"165 W\", \"szin\": \"Barna/bezs\", \"tipus\": \"Air Cooler (Tower)\", \"gyarto\": \"Noctua\", \"sorozat\": \"NH-U12S\", \"heatpipe\": \"5x 6mm heatpipe\", \"magassag\": \"158 mm\", \"zajszint\": \"22.4 dBA\", \"foglalatok\": \"Intel LGA1700/1200/115x, AMD AM5/AM4\", \"megjegyzes\": \"Premium air cooler, csendes\", \"ventillator\": \"1x NF-F12 (120mm)\"}', '35000.99', '26000.99', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 17, '2025-10-03 07:23:38', 1, '2026-02-26 12:07:46'),
(40, 'Dell UltraSharp 27\"', '4K monitor', '{\"hdr\": \"Nem\", \"vesa\": \"100x100mm\", \"pivot\": \"Igen\", \"dontes\": \"Igen\", \"fenyero\": \"350 cd/m²\", \"szinter\": \"99% sRGB\", \"keparany\": \"16:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"3840 x 2160\", \"hangszoro\": \"Nem\", \"kontraszt\": \"1300:1\", \"valaszido\": \"8 ms (GtG)\", \"elforgatas\": \"Igen\", \"csatlakozok\": \"HDMI, DisplayPort, Mini DisplayPort, USB hub\", \"panel_tipus\": \"IPS\", \"kepfrissites\": \"60 Hz\", \"kepernyo_meret\": \"27\\\"\", \"magassag_allitas\": \"Igen\"}', '300000.99', '200000.99', 15, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 12, '2025-10-03 07:23:38', NULL, NULL),
(41, 'Logitech G Pro X Keyboard', 'Mechanical keyboard', '{\"tipus\": \"Mechanikus gaming keyboard\", \"gyarto\": \"Logitech\", \"layout\": \"Tenkeyless (TKL)\", \"sorozat\": \"G Pro X\", \"szoftver\": \"Logitech G HUB\", \"megjegyzes\": \"Professzionalis TKL mechanikus billentyuzet\", \"csatlakozas\": \"USB-C leveheto kabel\", \"switch_tipus\": \"GX (valaszthato: Blue/Brown/Red)\", \"hattervilagitas\": \"RGB per-key\"}', '49999.99', '40000.99', 50, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 10, '2025-10-03 07:23:38', NULL, NULL),
(42, 'Razer DeathAdder V2', 'Gaming mouse', '{\"ips\": \"650\", \"rgb\": \"Igen (Razer Chroma)\", \"suly\": \"82g\", \"kabel\": \"Razer Speedflex (kábelezett)\", \"max_dpi\": \"20000\", \"szenzor\": \"Razer Focus+ 20K\", \"profilok\": \"5 (beépített memória)\", \"szoftver\": \"Razer Synapse 3\", \"ergonomia\": \"Jobbkezes\", \"gyorsulas\": \"50g\", \"kapcsolok\": \"Razer Optical Mouse Switch (70M kattintás)\", \"megjegyzes\": \"Fokozott 99.6% felbontás pontosság\", \"gombok_szama\": \"8\", \"polling_rate\": \"1000 Hz\"}', '32000.99', '28000.99', 70, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 11, '2025-10-03 07:23:38', NULL, NULL),
(46, 'RTX 3060 Gaming OC 12G 2.0', '12GB GDDR6 videókártya', '{\"tdp\": \"170 W\", \"dlss\": \"Igen (DLSS 2.0)\", \"pcie\": \"PCIe 4.0 x16\", \"hossz\": \"282 mm\", \"hutes\": \"WINDFORCE 3X huto\", \"gyarto\": \"Gigabyte\", \"opengl\": \"4.6\", \"chipset\": \"NVIDIA GeForce RTX 3060\", \"directx\": \"12 Ultimate\", \"memoria\": \"12 GB GDDR6\", \"kimenetek\": \"2x HDMI 2.1, 2x DisplayPort 1.4a\", \"cuda_magok\": \"3584\", \"megjegyzes\": \"Gaming OC verzio, 12GB VRAM, kiváló 1080p/1440p gaming\", \"alap_orajel\": \"1320 MHz\", \"ray_tracing\": \"Igen (2. gen RT Cores)\", \"ajanlott_tap\": \"550 W\", \"boost_orajel\": \"1837 MHz\", \"helyfoglalas\": \"2.5 slot\", \"max_felbontas\": \"7680 x 4320\", \"tap_csatlakozo\": \"1x 8-pin\", \"memoria_sebesseg\": \"15 Gbps\", \"memoria_interfesz\": \"192-bit\"}', '160000.00', '140000.00', 13, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 1, 6, '2026-01-20 10:25:24', NULL, NULL),
(47, 'AMD 100-300000074 Radeon Pro', 'W7900 48GB GDDR6 PCIE', '{\"DVI\": \"Nem\", \"HDMI\": \"0db\", \"Hossz\": \"280mm\", \"Súly\": \"1200g\", \"Hangtalan\": \"Nem\", \"VGA/D-SUB\": \"Nem\", \"DisplayPort\": \"3db\", \"Helyfoglalás\": \"3\", \"Tápellátás\": \"2 x 8 tűs\", \"Videó chipset\": \"RadeOn Pro W7900\", \"Memória mérete\": \"48GB\", \"Memória típusa\": \"GDDR6\", \"Mini DisplayPort\": \"1db\", \"Chipset gyártója\": \"AMD\", \"Ajánlott min. táp.\": \"650watt\"}', '1370900.00', '1320990.00', 9, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 1, 2, '2026-01-20 10:25:24', NULL, NULL),
(48, 'GeForce RTX 5070', '12GB GDDR7 DLSS4\nvideókártya', '{\"DVI\": \"Nem\", \"HDMI\": \"1db\", \"Hossz\": \"236mm\", \"Súly\": \"1500g\", \"Hangtalan\": \"Nem\", \"VGA/D-SUB\": \"Nem\", \"DisplayPort\": \"3db\", \"Helyfoglalás\": \"2\", \"Tápellátás\": \"1 x 16 12VHPWR tűs\", \"Videó chipset\": \"GeForce RTX 5070\", \"Memória mérete\": \"12GB\", \"Memória típusa\": \"GDDR7\", \"Mini DisplayPort\": \"0db\", \"Chipset gyártója\": \"NVIDIA\", \"Ajánlott min. táp.\": \"650watt\"}', '350000.00', '320000.00', 20, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 1, 6, '2026-01-20 10:25:24', NULL, NULL),
(49, 'GIGABYTE  AORUS MASTER GeForce RTX 5080', ' 16GB GDDR7 DLSS4 videokártya', '{\"DVI\": \"Nem\", \"HDMI\": \"1db\", \"Hossz\": \"360mm\", \"Súly\": \"2500g\", \"Hangtalan\": \"Nem\", \"VGA/D-SUB\": \"Nem\", \"DisplayPort\": \"3db\", \"Helyfoglalás\": \"4\", \"Tápellátás\": \"1 x 16 12VHPWR tűs\", \"Videó chipset\": \"GeForce RTX 5080\", \"Memória mérete\": \"16GB\", \"Memória típusa\": \"GDDR7\", \"Mini DisplayPort\": \"0db\", \"Chipset gyártója\": \"NVIDIA\", \"Ajánlott min. táp.\": \"850watt\"}', '750000.00', '730000.00', 50, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 1, 6, '2026-01-20 10:33:36', NULL, NULL),
(50, 'Gigabyte GeForce RTX 5050', 'Windforce OC 8GB videókártya', '{\"DVI\": \"Nem\", \"HDMI\": \"2db\", \"Hossz\": \"201mm\", \"Súly\": \"1000g\", \"Hangtalan\": \"Nem\", \"VGA/D-SUB\": \"Nem\", \"DisplayPort\": \"2db\", \"Helyfoglalás\": \"2\", \"Tápellátás\": \"1 x 8 tűs\", \"Videó chipset\": \"GeForce RTX 5050\", \"Memória mérete\": \"8GB\", \"Memória típusa\": \"GDDR6\", \"Mini DisplayPort\": \"0db\", \"Chipset gyártója\": \"NVIDIA\", \"Ajánlott min. táp.\": \"550watt\"}', '110000.00', '90000.00', 13, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 1, 6, '2026-01-20 10:43:19', NULL, NULL),
(51, 'Gigabyte GeForce RTX 3050', '6GB GDDR6 Low Profile OC videókártya', '{\"DVI\": \"Nem\", \"HDMI\": \"2db\", \"Hossz\": \"181mm\", \"Súly\": \"0g\", \"Hangtalan\": \"Nem\", \"VGA/D-SUB\": \"Nem\", \"DisplayPort\": \"2db\", \"Helyfoglalás\": \"2\", \"Tápellátás\": \"Nincs\", \"Videó chipset\": \"GeForce RTX 3050\", \"Memória mérete\": \"6GB\", \"Memória típusa\": \"GDDR6\", \"Mini DisplayPort\": \"0db\", \"Chipset gyártója\": \"NVIDIA\", \"Ajánlott min. táp.\": \"300watt\"}', '85000.00', '75000.00', 10, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 1, 6, '2026-01-20 10:43:19', NULL, NULL),
(52, 'Radeon AMD 100 Radeon Pro', '48GB GDDR6 videókártya', '{\"DVI\": \"Nem\", \"HDMI\": \"2db\", \"Hossz\": \"280mm\", \"Súly\": \"1200g\", \"Hangtalan\": \"Nem\", \"VGA/D-SUB\": \"Nem\", \"DisplayPort\": \"3db\", \"Helyfoglalás\": \"3\", \"Tápellátás\": \"2 X 8 tús\", \"Videó chipset\": \"RadeOn Pro W7900\", \"Memória mérete\": \"6GB\", \"Memória típusa\": \"GDDR6\", \"Mini DisplayPort\": \"1db\", \"Chipset gyártója\": \"AMD\", \"Ajánlott min. táp.\": \"650watt\"}', '173000.00', '164000.00', 14, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 1, 2, '2026-01-20 10:43:19', NULL, NULL),
(53, 'Radeon RX 9060 XT', '16GB GDDR6 videókártya', '{\"DVI\": \"Nem\", \"HDMI\": \"1db\", \"Hossz\": \"330mm\", \"Súly\": \"1500g\", \"Hangtalan\": \"Nem\", \"VGA/D-SUB\": \"Nem\", \"DisplayPort\": \"2db\", \"Helyfoglalás\": \"2\", \"Tápellátás\": \"1 X 8 tús\", \"Videó chipset\": \"RadeOn RX 9060XT\", \"Memória mérete\": \"16GB\", \"Memória típusa\": \"GDDR6\", \"Mini DisplayPort\": \"0db\", \"Chipset gyártója\": \"AMD\", \"Ajánlott min. táp.\": \"550watt\"}', '221790.00', '200000.00', 10, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 1, 6, '2026-01-20 10:43:19', NULL, NULL),
(54, 'Gigabyte Radeon RX 6750 XT', '12 GB GDDR6 videókártya', '{\"fsr\": \"Igen (FidelityFX Super Resolution)\", \"tdp\": \"250 W\", \"pcie\": \"PCIe 4.0 x16\", \"hossz\": \"306 mm\", \"hutes\": \"WINDFORCE 3X huto\", \"gyarto\": \"Gigabyte\", \"opengl\": \"4.6\", \"chipset\": \"AMD Radeon RX 6750 XT\", \"directx\": \"12 Ultimate\", \"memoria\": \"12 GB GDDR6\", \"kimenetek\": \"2x HDMI 2.1, 2x DisplayPort 1.4\", \"megjegyzes\": \"AMD RDNA 2, 12GB VRAM, 1440p gaming\", \"game_orajel\": \"2495 MHz\", \"ray_tracing\": \"Igen (RDNA 2)\", \"ajanlott_tap\": \"650 W\", \"boost_orajel\": \"2600 MHz\", \"helyfoglalas\": \"2.5 slot\", \"max_felbontas\": \"7680 x 4320\", \"infinity_cache\": \"96 MB\", \"tap_csatlakozo\": \"2x 8-pin\", \"memoria_sebesseg\": \"18 Gbps\", \"memoria_interfesz\": \"192-bit\", \"stream_processzorok\": \"2560\"}', '300000.00', '250000.00', 11, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 1, 6, '2026-01-20 10:43:19', NULL, NULL),
(55, 'Gigabyte GeForce RTX 5080', '16 GB GDDR7 videókártya', '{\"tdp\": \"360 W\", \"dlss\": \"Igen (DLSS 4)\", \"pcie\": \"PCIe 5.0 x16\", \"hossz\": \"336 mm\", \"hutes\": \"WINDFORCE huto\", \"gyarto\": \"Gigabyte\", \"chipset\": \"NVIDIA GeForce RTX 5080\", \"directx\": \"12 Ultimate\", \"memoria\": \"16 GB GDDR7\", \"ai_cores\": \"5. gen Tensor Cores\", \"generacio\": \"Blackwell (RTX 50-series)\", \"kimenetek\": \"1x HDMI 2.1, 3x DisplayPort 2.1\", \"cuda_magok\": \"10752\", \"megjegyzes\": \"RTX 50-series Blackwell, GDDR7, DLSS 4, 4K/1440p flagship\", \"ray_tracing\": \"Igen (4. gen RT Cores)\", \"ajanlott_tap\": \"850 W\", \"boost_orajel\": \"2620 MHz\", \"helyfoglalas\": \"3.5 slot\", \"max_felbontas\": \"7680 x 4320\", \"tap_csatlakozo\": \"1x 12VHPWR (16-pin)\", \"memoria_sebesseg\": \"30 Gbps\", \"memoria_interfesz\": \"256-bit\"}', '706000.00', '640000.00', 0, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 1, 6, '2026-01-20 10:43:19', NULL, NULL),
(56, 'Dell UltraSharp U2723QE', '42.51\" 4K IPS UHD monitor', '{\"hdr\": \"VESA DisplayHDR 400\", \"vesa\": \"100x100mm\", \"pivot\": \"Igen\", \"dontes\": \"-5° / +21°\", \"fenyero\": \"400 cd/m²\", \"szinter\": \"100% sRGB, 100% Rec.709, 98% DCI-P3\", \"keparany\": \"16:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"3840 x 2160\", \"hangszoro\": \"Nem\", \"kontraszt\": \"2000:1\", \"valaszido\": \"5 ms (GtG fast) / 8 ms (GtG normal)\", \"elforgatas\": \"-45° / +45°\", \"csatlakozok\": \"HDMI, DisplayPort 1.4, USB-C (90W PD), RJ45\", \"panel_tipus\": \"IPS Black\", \"kepfrissites\": \"60 Hz\", \"kepernyo_meret\": \"27\\\"\", \"magassag_allitas\": \"150mm\"}', '210000.00', '195000.00', 20, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 12, '2026-01-23 09:20:34', NULL, NULL),
(57, 'Dell Alienware AW2725Q', '27\" 4K QD-OLED gaming monitor', '{\"hdr\": \"VESA DisplayHDR True Black 400, Dolby Vision\", \"vesa\": \"100x100mm\", \"pivot\": \"+/- 90°\", \"dontes\": \"-5° / +21°\", \"fenyero\": \"450 cd/m² (HDR peak 1000 cd/m²)\", \"szinter\": \"99% DCI-P3\", \"keparany\": \"16:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"3840 x 2160\", \"hangszoro\": \"Nem\", \"kontraszt\": \"Infinite (OLED)\", \"valaszido\": \"0.03 ms (GtG)\", \"elforgatas\": \"+/- 20°\", \"csatlakozok\": \"DisplayPort 1.4, 2x HDMI 2.1, USB-C (15W PD), 3x USB-A 3.0\", \"panel_tipus\": \"QD-OLED\", \"kepfrissites\": \"240 Hz\", \"adaptive_sync\": \"G-SYNC Compatible, FreeSync Premium Pro\", \"kepernyo_meret\": \"27\\\" (26.7\\\")\", \"magassag_allitas\": \"110mm\"}', '360000.00', '335000.00', 10, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 12, '2026-01-23 09:20:34', NULL, NULL),
(58, 'MSI MAG 274QRF-QD', '27\" QHD Rapid IPS gaming monitor', '{\"hdr\": \"VESA DisplayHDR 400\", \"vesa\": \"75x75mm\", \"pivot\": \"Igen\", \"dontes\": \"Igen\", \"fenyero\": \"400 cd/m²\", \"szinter\": \"94% Adobe RGB, 98% DCI-P3, 150% sRGB\", \"keparany\": \"16:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"2560 x 1440\", \"hangszoro\": \"Nem\", \"kontraszt\": \"1000:1\", \"valaszido\": \"1 ms (GtG)\", \"elforgatas\": \"Igen\", \"csatlakozok\": \"DisplayPort 1.4a, 2x HDMI 2.0b, USB-C (DP Alt, 65W PD)\", \"panel_tipus\": \"Rapid IPS, Quantum Dot\", \"kepfrissites\": \"165 Hz / 180 Hz (OC)\", \"adaptive_sync\": \"G-SYNC Compatible, FreeSync Premium\", \"kepernyo_meret\": \"27\\\"\", \"magassag_allitas\": \"Igen\"}', '165000.00', '149000.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 5, '2026-01-23 09:20:34', NULL, NULL),
(59, 'MSI MPG 321UR-QD', '32\" 4K QD gaming monitor', '{\"hdr\": \"VESA DisplayHDR 600\", \"vesa\": \"100x100mm\", \"pivot\": \"Igen\", \"dontes\": \"Igen\", \"fenyero\": \"600 cd/m²\", \"szinter\": \"97% DCI-P3, 95% Adobe RGB\", \"keparany\": \"16:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"3840 x 2160\", \"hangszoro\": \"Nem\", \"kontraszt\": \"1000:1\", \"valaszido\": \"1 ms (MPRT)\", \"elforgatas\": \"Igen\", \"csatlakozok\": \"DisplayPort 1.4, 2x HDMI 2.0, USB-C (DP Alt Mode, 65W PD)\", \"panel_tipus\": \"IPS, Quantum Dot\", \"kepfrissites\": \"144 Hz\", \"adaptive_sync\": \"G-SYNC Compatible\", \"kepernyo_meret\": \"32\\\"\", \"magassag_allitas\": \"Igen\"}', '290000.00', '269000.00', 12, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 5, '2026-01-23 09:20:34', NULL, NULL),
(60, 'MSI G2712F', '27\" Full HD Rapid IPS gaming monitor', '{\"hdr\": \"Nem\", \"vesa\": \"75x75mm\", \"pivot\": \"Nem\", \"dontes\": \"Igen\", \"fenyero\": \"300 cd/m²\", \"szinter\": \"99% sRGB\", \"keparany\": \"16:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"1920 x 1080\", \"hangszoro\": \"Nem\", \"kontraszt\": \"1000:1\", \"valaszido\": \"1 ms (GtG)\", \"elforgatas\": \"Nem\", \"csatlakozok\": \"DisplayPort 1.2a, 2x HDMI 2.0\", \"panel_tipus\": \"Rapid IPS\", \"kepfrissites\": \"180 Hz\", \"adaptive_sync\": \"FreeSync Premium\", \"kepernyo_meret\": \"27\\\"\", \"magassag_allitas\": \"Igen\"}', '75000.00', '69900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 5, '2026-01-23 09:20:34', NULL, NULL),
(61, 'Samsung Odyssey G5 LC27G55T', '27\" QHD Curved gaming monitor', '{\"hdr\": \"HDR10\", \"vesa\": \"75x75mm\", \"pivot\": \"Nem\", \"dontes\": \"Igen\", \"fenyero\": \"250 cd/m²\", \"szinter\": \"99% sRGB\", \"gorbules\": \"1000R\", \"keparany\": \"16:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"2560 x 1440\", \"hangszoro\": \"Nem\", \"kontraszt\": \"2500:1\", \"valaszido\": \"1 ms (MPRT)\", \"elforgatas\": \"Nem\", \"csatlakozok\": \"DisplayPort 1.2, HDMI 2.0, 3.5mm audio\", \"panel_tipus\": \"VA\", \"kepfrissites\": \"144 Hz\", \"adaptive_sync\": \"FreeSync Premium\", \"kepernyo_meret\": \"27\\\"\", \"magassag_allitas\": \"Nem\"}', '135000.00', '119000.00', 25, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 8, '2026-01-23 09:20:34', NULL, NULL),
(62, 'Samsung Odyssey G7 LS28BG700', '28\" 4K IPS gaming monitor', '{\"hdr\": \"VESA DisplayHDR 400\", \"vesa\": \"100x100mm\", \"pivot\": \"Igen\", \"dontes\": \"Igen\", \"fenyero\": \"300 cd/m²\", \"szinter\": \"sRGB coverage\", \"keparany\": \"16:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"3840 x 2160\", \"hangszoro\": \"Yes (built-in)\", \"kontraszt\": \"1000:1\", \"valaszido\": \"1 ms (GtG)\", \"elforgatas\": \"Igen\", \"csatlakozok\": \"DisplayPort 1.4, 2x HDMI 2.1, USB hub, RJ45\", \"panel_tipus\": \"IPS\", \"kepfrissites\": \"144 Hz\", \"adaptive_sync\": \"G-SYNC Compatible, FreeSync Premium Pro\", \"okos_funkciok\": \"Tizen OS, Gaming Hub\", \"kepernyo_meret\": \"28\\\"\", \"magassag_allitas\": \"Igen\"}', '275000.00', '249000.00', 15, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 8, '2026-01-23 09:20:34', NULL, NULL),
(63, 'Samsung ViewFinity S8 S80PB', '27\" 4K IPS professional monitor', '{\"hdr\": \"Nem\", \"vesa\": \"100x100mm\", \"pivot\": \"Igen\", \"dontes\": \"Igen\", \"fenyero\": \"350 cd/m²\", \"szinter\": \"99% sRGB\", \"keparany\": \"16:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"3840 x 2160\", \"hangszoro\": \"Nem\", \"kontraszt\": \"1000:1\", \"valaszido\": \"5 ms\", \"elforgatas\": \"Igen\", \"csatlakozok\": \"DisplayPort, 2x HDMI, USB-C (90W PD), USB hub\", \"panel_tipus\": \"IPS\", \"kepfrissites\": \"60 Hz\", \"kepernyo_meret\": \"27\\\"\", \"professzionalis\": \"Igen\", \"magassag_allitas\": \"Igen\"}', '185000.00', '169000.00', 18, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 8, '2026-01-23 09:20:34', NULL, NULL),
(64, 'Dell P2723D', '27\" QHD IPS business monitor', '{\"hdr\": \"Nem\", \"vesa\": \"100x100mm\", \"pivot\": \"Igen\", \"dontes\": \"Igen\", \"uzleti\": \"Igen\", \"fenyero\": \"350 cd/m²\", \"szinter\": \"99% sRGB\", \"keparany\": \"16:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"2560 x 1440\", \"hangszoro\": \"Nem\", \"kontraszt\": \"1000:1\", \"valaszido\": \"5 ms (GtG)\", \"elforgatas\": \"Igen\", \"csatlakozok\": \"DisplayPort 1.4, HDMI 1.4, USB-C (65W PD), USB hub\", \"panel_tipus\": \"IPS\", \"kepfrissites\": \"60 Hz\", \"kepernyo_meret\": \"27\\\"\", \"magassag_allitas\": \"Igen\"}', '145000.00', '129000.00', 28, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 12, '2026-01-23 09:20:34', NULL, NULL),
(65, 'Dell S3422DWG', '34\" Ultrawide curved gaming monitor', '{\"hdr\": \"VESA DisplayHDR 400\", \"vesa\": \"100x100mm\", \"pivot\": \"Nem\", \"dontes\": \"Igen\", \"fenyero\": \"400 cd/m²\", \"szinter\": \"90% DCI-P3\", \"gorbules\": \"1800R\", \"keparany\": \"21:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"3440 x 1440\", \"hangszoro\": \"Nem\", \"kontraszt\": \"3000:1\", \"valaszido\": \"2 ms (GtG)\", \"elforgatas\": \"Igen\", \"csatlakozok\": \"DisplayPort 1.4, 2x HDMI 2.0, USB hub\", \"panel_tipus\": \"VA\", \"kepfrissites\": \"144 Hz\", \"adaptive_sync\": \"FreeSync Premium Pro\", \"kepernyo_meret\": \"34\\\"\", \"magassag_allitas\": \"Igen\"}', '195000.00', '179000.00', 16, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 12, '2026-01-23 09:20:34', NULL, NULL),
(66, 'Logitech G Pro X Gaming Display', '27\" QHD esports gaming monitor', '{\"hdr\": \"VESA DisplayHDR 400\", \"vesa\": \"100x100mm\", \"pivot\": \"Igen\", \"dontes\": \"Igen\", \"esport\": \"Igen\", \"fenyero\": \"400 cd/m²\", \"szinter\": \"98% DCI-P3\", \"keparany\": \"16:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"2560 x 1440\", \"hangszoro\": \"Nem\", \"kontraszt\": \"1000:1\", \"valaszido\": \"1 ms (GtG)\", \"elforgatas\": \"Igen\", \"csatlakozok\": \"DisplayPort 1.4, HDMI 2.0, USB hub\", \"panel_tipus\": \"IPS\", \"kepfrissites\": \"165 Hz\", \"adaptive_sync\": \"G-SYNC Compatible\", \"kepernyo_meret\": \"27\\\"\", \"magassag_allitas\": \"Igen\"}', '225000.00', '209000.00', 14, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 10, '2026-01-23 09:20:34', 1, '2026-02-25 09:07:52'),
(67, 'Samsung Odyssey G3 LF24G35TF', '24\" Full HD gaming monitor', '{\"hdr\": \"Nem\", \"vesa\": \"75x75mm\", \"pivot\": \"Nem\", \"dontes\": \"Igen\", \"fenyero\": \"250 cd/m²\", \"szinter\": \"sRGB coverage\", \"keparany\": \"16:9\", \"latoszog\": \"178°/178°\", \"felbontas\": \"1920 x 1080\", \"hangszoro\": \"Nem\", \"kontraszt\": \"3000:1\", \"valaszido\": \"1 ms (MPRT)\", \"elforgatas\": \"Nem\", \"csatlakozok\": \"DisplayPort 1.2, HDMI 1.4, 3.5mm audio\", \"panel_tipus\": \"VA\", \"kepfrissites\": \"144 Hz\", \"adaptive_sync\": \"FreeSync\", \"kepernyo_meret\": \"24\\\"\", \"magassag_allitas\": \"Nem\"}', '65000.00', '59900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 13, 8, '2026-01-23 09:20:34', NULL, NULL),
(94, 'Logitech G Pro X Superlight', 'Wireless gaming mouse, 63g', '{\"ips\": \"400+\", \"rgb\": \"Nem\", \"suly\": \"63g\", \"kabel\": \"Vezeték nélküli (LIGHTSPEED)\", \"max_dpi\": \"25600\", \"szenzor\": \"HERO 25K\", \"profilok\": \"5 (beépített memória)\", \"szoftver\": \"Logitech G HUB\", \"ergonomia\": \"Szimmetrikus\", \"gyorsulas\": \"40g\", \"kapcsolok\": \"Logitech mechanikus\", \"megjegyzes\": \"Ultra-könnyű, profi esports egér\", \"akkumulator\": \"70 óra\", \"gombok_szama\": \"5\", \"polling_rate\": \"1000 Hz\"}', '59900.00', '54900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 10, '2026-01-23 09:46:16', NULL, NULL),
(95, 'Logitech G502 X Lightspeed', 'Wireless gaming mouse, HERO 25K', '{\"ips\": \"400+\", \"rgb\": \"Igen (LIGHTSYNC)\", \"suly\": \"102g\", \"kabel\": \"Vezeték nélküli (LIGHTSPEED)\", \"max_dpi\": \"25600\", \"szenzor\": \"HERO 25K\", \"profilok\": \"5 (beépített memória)\", \"szoftver\": \"Logitech G HUB\", \"ergonomia\": \"Jobbkezes\", \"gyorsulas\": \"40g\", \"kapcsolok\": \"LIGHTFORCE hibrid optikai-mechanikus\", \"megjegyzes\": \"Dual-mode görgő, súlyrendszer\", \"akkumulator\": \"120 óra\", \"gombok_szama\": \"13\", \"polling_rate\": \"1000 Hz\"}', '64900.00', '59900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 10, '2026-01-23 09:46:16', NULL, NULL),
(96, 'Logitech MX Master 3S', 'Wireless productivity mouse', '{\"rgb\": \"Nem\", \"suly\": \"141g\", \"egyeb\": \"MagSpeed görgő, Easy-Switch (3 eszköz)\", \"kabel\": \"Vezeték nélküli (Bluetooth + Logi Bolt)\", \"max_dpi\": \"8000\", \"szenzor\": \"Darkfield 8000 DPI\", \"szoftver\": \"Logi Options+\", \"ergonomia\": \"Jobbkezes\", \"kapcsolok\": \"Logitech csendes kapcsolók\", \"megjegyzes\": \"Prémium produktivitási egér\", \"akkumulator\": \"70 nap\", \"gombok_szama\": \"7\", \"polling_rate\": \"125 Hz\"}', '45900.00', '41900.00', 50, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 10, '2026-01-23 09:46:16', NULL, NULL),
(97, 'Logitech G305 Lightspeed', 'Wireless gaming mouse', '{\"ips\": \"400\", \"rgb\": \"Nem\", \"suly\": \"99g (elemekkel)\", \"kabel\": \"Vezeték nélküli (LIGHTSPEED)\", \"max_dpi\": \"12000\", \"szenzor\": \"HERO 12K\", \"profilok\": \"1 (beépített memória)\", \"szoftver\": \"Logitech G HUB\", \"ergonomia\": \"Szimmetrikus\", \"gyorsulas\": \"40g\", \"kapcsolok\": \"Mechanikus (10M kattintás)\", \"megjegyzes\": \"Megfizethető vezeték nélküli gaming egér\", \"akkumulator\": \"250 óra (1 AA elem)\", \"gombok_szama\": \"6\", \"polling_rate\": \"1000 Hz\"}', '18900.00', '16900.00', 60, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 10, '2026-01-23 09:46:16', NULL, NULL),
(98, 'Razer DeathAdder V3 Pro', 'Wireless esports gaming mouse', '{\"ips\": \"750\", \"rgb\": \"Nem\", \"suly\": \"63g\", \"kabel\": \"Vezeték nélküli (HyperSpeed) / USB-C\", \"max_dpi\": \"30000\", \"szenzor\": \"Razer Focus Pro 30K\", \"profilok\": \"5 (beépített memória)\", \"szoftver\": \"Razer Synapse 3\", \"ergonomia\": \"Jobbkezes\", \"gyorsulas\": \"70g\", \"kapcsolok\": \"Razer Optical Gen-3 (90M kattintás)\", \"megjegyzes\": \"Esports profi egér, 8K polling támogatás\", \"akkumulator\": \"90 óra\", \"gombok_szama\": \"5\", \"polling_rate\": \"1000 Hz / 4000 Hz / 8000 Hz (HyperPolling)\"}', '64900.00', '59900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 11, '2026-01-23 09:46:16', NULL, NULL),
(99, 'Razer Viper V2 Pro', 'Ultra-light wireless gaming mouse', '{\"ips\": \"750\", \"rgb\": \"Nem\", \"suly\": \"58g\", \"kabel\": \"Vezeték nélküli (HyperSpeed)\", \"max_dpi\": \"30000\", \"szenzor\": \"Razer Focus Pro 30K\", \"profilok\": \"5 (beépített memória)\", \"szoftver\": \"Razer Synapse 3\", \"ergonomia\": \"Szimmetrikus\", \"gyorsulas\": \"70g\", \"kapcsolok\": \"Razer Optical Gen-3 (90M kattintás)\", \"megjegyzes\": \"Ultra-könnyű ambi esports egér\", \"akkumulator\": \"80 óra\", \"gombok_szama\": \"5\", \"polling_rate\": \"1000 Hz\"}', '62900.00', '57900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 11, '2026-01-23 09:46:16', NULL, NULL),
(100, 'Razer Basilisk V3', 'RGB wired gaming mouse', '{\"ips\": \"650\", \"rgb\": \"Igen (Razer Chroma - 11 zóna)\", \"suly\": \"101g\", \"egyeb\": \"HyperScroll dönthető görgő\", \"kabel\": \"Razer Speedflex (kábelezett)\", \"max_dpi\": \"26000\", \"szenzor\": \"Razer Focus+ 26K\", \"profilok\": \"5 (beépített memória)\", \"szoftver\": \"Razer Synapse 3\", \"ergonomia\": \"Jobbkezes\", \"gyorsulas\": \"50g\", \"kapcsolok\": \"Razer Optical Gen-2 (70M kattintás)\", \"megjegyzes\": \"RGB gaming egér testreszabható görgővel\", \"gombok_szama\": \"11\", \"polling_rate\": \"1000 Hz\"}', '27900.00', '24900.00', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 11, '2026-01-23 09:46:16', NULL, NULL),
(101, 'Razer Orochi V2', 'Compact wireless gaming mouse', '{\"ips\": \"450\", \"rgb\": \"Nem\", \"suly\": \"60g (1x AA elem)\", \"kabel\": \"Vezeték nélküli (Bluetooth + HyperSpeed)\", \"max_dpi\": \"18000\", \"szenzor\": \"Razer 5G Advanced Optical\", \"profilok\": \"5 (beépített memória)\", \"szoftver\": \"Razer Synapse 3\", \"ergonomia\": \"Szimmetrikus\", \"gyorsulas\": \"40g\", \"kapcsolok\": \"Razer mechanikus (60M kattintás)\", \"megjegyzes\": \"Kompakt, hordozható dual-mode egér\", \"akkumulator\": \"950 óra (Bluetooth) / 425 óra (HyperSpeed)\", \"gombok_szama\": \"6\", \"polling_rate\": \"1000 Hz\"}', '24900.00', '21900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 11, '2026-01-23 09:46:16', NULL, NULL),
(102, 'FINALMOUSE ULX Frostlord Classic', 'Wireless optical mouse', '{\"ips\": \"400\", \"rgb\": \"Nem\", \"suly\": \"42g\", \"kabel\": \"Kábelezett (Phantom Cord – rugalmas)\", \"max_acc\": \"50g\", \"max_dpi\": \"3200\", \"szenzor\": \"Finalmouse ULX (saját fejlesztésű)\", \"profilok\": \"Nincs (hardver szintű beállítás)\", \"szoftver\": \"Nincs szükséges\", \"ergonomia\": \"Szimmetrikus\", \"gyorsulas\": \"50g\", \"haz_anyag\": \"Magnesium alloy\", \"kapcsolok\": \"Finalmouse saját optikai kapcsolók\", \"also_anyag\": \"PTFE (100% pure)\", \"kiadasi_ev\": \"2024\", \"megjegyzes\": \"Világ egyik legkönnyebb gaming egere, magnesium alloy vázzal\", \"gombok_szama\": \"6\", \"polling_rate\": \"1000 Hz\"}', '75900.00', '67000.00', 65, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 20, '2026-01-23 09:46:16', NULL, NULL),
(103, 'STEELSERIES CS2 Dragon Lore Wireless', 'Silent wireless mouse', '{\"ips\": \"400\", \"rgb\": \"Igen (SteelSeries Prism – korlátozott, CS2 Dragon Lore dizájn)\", \"suly\": \"73g\", \"kabel\": \"Vezeték nélküli (Quantum 2.0 Wireless 2.4 GHz) + USB-C\", \"max_dpi\": \"18000\", \"szenzor\": \"SteelSeries TrueMove Air\", \"profilok\": \"5 (SteelSeries GG / beépített memória)\", \"szoftver\": \"SteelSeries GG\", \"ergonomia\": \"Szimmetrikus\", \"gyorsulas\": \"40g\", \"haz_anyag\": \"Műanyag, UV-bevonat\", \"kapcsolok\": \"SteelSeries Golden Micro IP54 (60M kattintás)\", \"also_anyag\": \"PTFE (100% pure)\", \"kiadasi_ev\": \"2024\", \"megjegyzes\": \"Limitált CS2 Dragon Lore Edition, IP54 vízállóság, 200 óra akkuidő\", \"vedettség\": \"IP54\", \"akkumulator\": \"200 óra\", \"gombok_szama\": \"6\", \"polling_rate\": \"1000 Hz\"}', '45900.00', '39900.00', 55, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 8, '2026-01-23 09:46:16', NULL, NULL),
(104, 'STEELSERIES Aerox 3 Wireless 2022 Edition fehér', 'Bluetooth office mouse', '{\"ips\": \"400\", \"rgb\": \"Igen (SteelSeries Prism RGB)\", \"suly\": \"68g\", \"szin\": \"Fehér\", \"kabel\": \"Vezeték nélküli (Quantum 2.0 Wireless 2.4 GHz + Bluetooth 5.0) + USB-C\", \"max_dpi\": \"18000\", \"szenzor\": \"SteelSeries TrueMove Air\", \"profilok\": \"5 (SteelSeries GG / beépített memória)\", \"szoftver\": \"SteelSeries GG\", \"ergonomia\": \"Szimmetrikus\", \"gyorsulas\": \"40g\", \"haz_anyag\": \"Lyukasztott ABS műanyag\", \"kapcsolok\": \"SteelSeries Golden Micro IP54 (60M kattintás)\", \"also_anyag\": \"PTFE (100% pure)\", \"kiadasi_ev\": \"2022\", \"megjegyzes\": \"Ultra-könnyű lyukasztott váz, IP54 vízállóság, dual-wireless\", \"vedettség\": \"IP54\", \"akkumulator\": \"200 óra (2.4 GHz) / 300 óra (Bluetooth)\", \"gombok_szama\": \"6\", \"polling_rate\": \"1000 Hz\"}', '24900.00', '21900.00', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 8, '2026-01-23 09:46:16', NULL, NULL),
(105, 'ATTACK SHARK R2 Magnesium Alloy PAW3950 Gaming Mouse', 'RGB wired gaming mouse', '{\"ips\": \"750\", \"rgb\": \"Igen (RGB underglow)\", \"suly\": \"55g\", \"kabel\": \"Tri-mode: Bluetooth 5.2 + 2.4 GHz Wireless + USB-C kábelezett\", \"max_acc\": \"50g\", \"max_dpi\": \"36000\", \"szenzor\": \"PixArt PAW3950\", \"profilok\": \"5 (beépített memória)\", \"szoftver\": \"Attack Shark app\", \"ergonomia\": \"Szimmetrikus\", \"gyorsulas\": \"50g\", \"haz_anyag\": \"Magnesium alloy + ABS\", \"kapcsolok\": \"Kailh GM 8.0 optikai (80M kattintás)\", \"also_anyag\": \"PTFE (100% pure)\", \"kiadasi_ev\": \"2024\", \"megjegyzes\": \"Magnesium alloy felső keret, PAW3950 csúcsszenzor, tri-mode csatlakozás\", \"akkumulator\": \"65 óra (2.4 GHz)\", \"gombok_szama\": \"6\", \"polling_rate\": \"1000 Hz (kábelezett: 4000 Hz)\"}', '37900.00', '34900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 11, 21, '2026-01-23 09:46:16', NULL, NULL),
(106, 'Corsair Vengeance LPX 16GB', 'DDR4 3200MHz RAM kit (2x8GB)', '{\"ecc\": \"Nem\", \"rgb\": \"Nem\", \"xmp\": \"XMP 2.0\", \"tipus\": \"DDR4\", \"gyarto\": \"Corsair\", \"konfig\": \"2 x 8 GB\", \"sorozat\": \"Vengeance LPX\", \"timings\": \"16-18-18-36\", \"sebesseg\": \"3200 MHz\", \"kapacitas\": \"16 GB\", \"feszultseg\": \"1.35V\", \"megjegyzes\": \"Népszerű low-profile RAM, kiváló gaming\", \"cas_latency\": \"CL16\", \"forma_faktor\": \"DIMM 288-pin\"}', '24900.00', '21900.00', 80, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 7, '2026-01-23 10:03:16', NULL, NULL),
(107, 'Corsair Vengeance RGB Pro 32GB', 'DDR4 3600MHz RGB RAM kit (2x16GB)', '{\"ecc\": \"Nem\", \"rgb\": \"Igen (10 LED per modul)\", \"xmp\": \"XMP 2.0\", \"tipus\": \"DDR4\", \"gyarto\": \"Corsair\", \"konfig\": \"2 x 16 GB\", \"sorozat\": \"Vengeance RGB Pro\", \"timings\": \"18-22-22-42\", \"sebesseg\": \"3600 MHz\", \"kapacitas\": \"32 GB\", \"feszultseg\": \"1.35V\", \"megjegyzes\": \"RGB világítás, iCUE szoftver támogatás\", \"cas_latency\": \"CL18\", \"forma_faktor\": \"DIMM 288-pin\"}', '48900.00', '44900.00', 60, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 7, '2026-01-23 10:03:16', NULL, NULL),
(108, 'Corsair Dominator Platinum RGB 32GB', 'DDR5 5600MHz premium RAM kit', '{\"ecc\": \"Nem\", \"rgb\": \"Igen (12 Capellix LED/modul)\", \"xmp\": \"XMP 3.0\", \"tipus\": \"DDR5\", \"gyarto\": \"Corsair\", \"konfig\": \"2 x 16 GB\", \"sorozat\": \"Dominator Platinum RGB\", \"timings\": \"36-36-36-76\", \"sebesseg\": \"5600 MHz\", \"kapacitas\": \"32 GB\", \"feszultseg\": \"1.25V\", \"megjegyzes\": \"Prémium DDR5, erős túlhajtás\", \"cas_latency\": \"CL36\", \"forma_faktor\": \"DIMM 288-pin\"}', '109900.00', '99900.00', 25, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 7, '2026-01-23 10:03:16', NULL, NULL),
(109, 'Samsung DDR4 16GB OEM', 'DDR4 3200MHz desktop RAM', '{\"ecc\": \"Nem\", \"rgb\": \"Nem\", \"tipus\": \"DDR4\", \"gyarto\": \"Samsung\", \"konfig\": \"1 x 16 GB\", \"sebesseg\": \"3200 MHz\", \"kapacitas\": \"16 GB\", \"feszultseg\": \"1.2V\", \"megjegyzes\": \"OEM RAM, alapvető használatra\", \"cas_latency\": \"CL22\", \"forma_faktor\": \"DIMM 288-pin\"}', '17900.00', '15900.00', 100, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 8, '2026-01-23 10:03:16', NULL, NULL),
(110, 'Samsung DDR5 16GB', 'DDR5 4800MHz desktop RAM', '{\"ecc\": \"Nem\", \"rgb\": \"Nem\", \"tipus\": \"DDR5\", \"gyarto\": \"Samsung\", \"konfig\": \"1 x 16 GB\", \"sebesseg\": \"4800 MHz\", \"kapacitas\": \"16 GB\", \"feszultseg\": \"1.1V\", \"megjegyzes\": \"DDR5 alap RAM\", \"cas_latency\": \"CL40\", \"forma_faktor\": \"DIMM 288-pin\"}', '29900.00', '26900.00', 70, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 8, '2026-01-23 10:03:16', NULL, NULL),
(111, 'Samsung DDR5 32GB', 'DDR5 5600MHz desktop RAM', '{\"ecc\": \"Nem\", \"rgb\": \"Nem\", \"tipus\": \"DDR5\", \"gyarto\": \"Samsung\", \"konfig\": \"1 x 32 GB\", \"sebesseg\": \"5600 MHz\", \"kapacitas\": \"32 GB\", \"feszultseg\": \"1.1V\", \"megjegyzes\": \"Nagy kapacitású DDR5 modul\", \"cas_latency\": \"CL46\", \"forma_faktor\": \"DIMM 288-pin\"}', '58900.00', '54900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 8, '2026-01-23 10:03:16', NULL, NULL),
(112, 'MSI SPATIUM DDR4 16GB', 'DDR4 3200MHz gaming RAM', '{\"ecc\": \"Nem\", \"rgb\": \"Nem\", \"xmp\": \"XMP 2.0\", \"tipus\": \"DDR4\", \"gyarto\": \"MSI\", \"konfig\": \"2 x 8 GB\", \"sorozat\": \"SPATIUM\", \"sebesseg\": \"3200 MHz\", \"kapacitas\": \"16 GB\", \"feszultseg\": \"1.35V\", \"megjegyzes\": \"MSI gaming RAM\", \"cas_latency\": \"CL16\", \"forma_faktor\": \"DIMM 288-pin\"}', '22900.00', '19900.00', 75, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 5, '2026-01-23 10:03:16', 1, '2026-03-02 09:49:45'),
(113, 'MSI SPATIUM DDR4 RGB 32GB', 'DDR4 3600MHz RGB RAM kit', '{\"ecc\": \"Nem\", \"rgb\": \"Igen (Mystic Light)\", \"xmp\": \"XMP 2.0\", \"tipus\": \"DDR4\", \"gyarto\": \"MSI\", \"konfig\": \"2 x 16 GB\", \"sorozat\": \"SPATIUM RGB\", \"sebesseg\": \"3600 MHz\", \"kapacitas\": \"32 GB\", \"feszultseg\": \"1.35V\", \"megjegyzes\": \"RGB világítás, MSI Mystic Light\", \"cas_latency\": \"CL18\", \"forma_faktor\": \"DIMM 288-pin\"}', '45900.00', '41900.00', 55, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 5, '2026-01-23 10:03:16', 1, '2026-03-02 09:49:39'),
(114, 'Corsair ValueSelect 8GB', 'DDR4 2666MHz basic RAM', '{\"ecc\": \"Nem\", \"rgb\": \"Nem\", \"tipus\": \"DDR4\", \"gyarto\": \"Corsair\", \"konfig\": \"1 x 8 GB\", \"sorozat\": \"ValueSelect\", \"sebesseg\": \"2666 MHz\", \"kapacitas\": \"8 GB\", \"feszultseg\": \"1.2V\", \"megjegyzes\": \"Költséghatékony alapvető RAM\", \"cas_latency\": \"CL18\", \"forma_faktor\": \"DIMM 288-pin\"}', '12900.00', '10900.00', 90, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 7, '2026-01-23 10:03:16', NULL, NULL),
(115, 'Samsung DDR4 8GB OEM', 'DDR4 2666MHz desktop RAM', '{\"ecc\": \"Nem\", \"rgb\": \"Nem\", \"tipus\": \"DDR4\", \"gyarto\": \"Samsung\", \"konfig\": \"1 x 8 GB\", \"sebesseg\": \"2666 MHz\", \"kapacitas\": \"8 GB\", \"feszultseg\": \"1.2V\", \"megjegyzes\": \"OEM alap RAM modul\", \"cas_latency\": \"CL19\", \"forma_faktor\": \"DIMM 288-pin\"}', '9900.00', '8500.00', 110, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 8, '2026-01-23 10:03:16', NULL, NULL),
(116, 'Corsair Vengeance DDR5 32GB', 'DDR5 6000MHz gaming RAM', '{\"ecc\": \"Nem\", \"rgb\": \"Nem\", \"xmp\": \"XMP 3.0 / EXPO\", \"tipus\": \"DDR5\", \"gyarto\": \"Corsair\", \"konfig\": \"2 x 16 GB\", \"sorozat\": \"Vengeance DDR5\", \"timings\": \"36-36-36-76\", \"sebesseg\": \"6000 MHz\", \"kapacitas\": \"32 GB\", \"feszultseg\": \"1.35V\", \"megjegyzes\": \"Nagy sebességű DDR5 gaming RAM\", \"cas_latency\": \"CL36\", \"forma_faktor\": \"DIMM 288-pin\"}', '89900.00', '82900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 7, '2026-01-23 10:03:16', NULL, NULL),
(117, 'MSI SPATIUM DDR5 32GB', 'DDR5 6000MHz high-performance RAM', '{\"ecc\": \"Nem\", \"rgb\": \"Nem\", \"xmp\": \"XMP 3.0 / EXPO\", \"tipus\": \"DDR5\", \"gyarto\": \"MSI\", \"konfig\": \"2 x 16 GB\", \"sorozat\": \"SPATIUM DDR5\", \"sebesseg\": \"6000 MHz\", \"kapacitas\": \"32 GB\", \"feszultseg\": \"1.35V\", \"megjegyzes\": \"High-performance DDR5\", \"cas_latency\": \"CL36\", \"forma_faktor\": \"DIMM 288-pin\"}', '85900.00', '79900.00', 28, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 4, 5, '2026-01-23 10:03:16', 1, '2026-03-02 09:49:32'),
(118, 'NZXT H510', 'Mid-tower ATX PC case', '{\"szin\": \"Fekete/Fehér\", \"gyarto\": \"NZXT\", \"meretek\": \"210 x 460 x 428 mm\", \"sorozat\": \"H Series\", \"io_panel\": \"1x USB 3.1 Gen 2 Type-C, 1x USB 3.1 Gen 1, Audio\", \"megjegyzes\": \"Duplikátum - ugyanaz mint ID 38\", \"oldalpanel\": \"Edzett üveg\", \"max_alaplap\": \"ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"2+1\", \"drive_bay_35\": \"2\", \"forma_faktor\": \"Mid-Tower ATX\", \"max_gpu_hossz\": \"381 mm\", \"max_psu_hossz\": \"180 mm\", \"radiator_tamogatas\": \"Elöl: 2x120/140mm, Fent: 1x120mm\", \"ventillator_helyek\": \"2x 120mm elöl, 1x 120mm hátul\", \"max_cpu_huto_magassag\": \"165 mm\"}', '29900.00', '26900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 16, '2026-01-23 10:03:55', 1, '2026-02-25 09:06:39'),
(119, 'NZXT H7 Flow', 'Airflow focused ATX mid-tower case', '{\"szin\": \"Fekete/Fehér\", \"gyarto\": \"NZXT\", \"meretek\": \"230 x 505 x 480 mm\", \"sorozat\": \"H Series Flow\", \"io_panel\": \"1x USB 3.2 Gen 2 Type-C, 2x USB 3.2 Gen 1, Audio\", \"megjegyzes\": \"Fokozott légáramlás, RGB ventilátorokkal\", \"oldalpanel\": \"Edzett üveg\", \"max_alaplap\": \"E-ATX, ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"4\", \"drive_bay_35\": \"2+2\", \"forma_faktor\": \"Mid-Tower ATX\", \"max_gpu_hossz\": \"400 mm\", \"max_psu_hossz\": \"200 mm\", \"radiator_tamogatas\": \"Elöl: 360mm, Fent: 360mm, Hátul: 120mm\", \"ventillator_helyek\": \"3x 120mm/140mm elöl, 1x 120mm hátul, 3x 120mm fent\", \"ventillator_tartalma\": \"3x 120mm F Series RGB\", \"max_cpu_huto_magassag\": \"185 mm\"}', '54900.00', '49900.00', 25, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 16, '2026-01-23 10:03:55', NULL, NULL),
(120, 'NZXT H9 Flow', 'Dual-chamber premium ATX case', '{\"szin\": \"Fekete/Fehér\", \"egyeb\": \"Függőleges GPU mount, dual-chamber design\", \"gyarto\": \"NZXT\", \"meretek\": \"230 x 505 x 505 mm\", \"sorozat\": \"H Series Flow\", \"io_panel\": \"1x USB 3.2 Gen 2x2 Type-C, 2x USB 3.2 Gen 1, Audio\", \"megjegyzes\": \"Prémium dual-chamber, kiváló légáramlás\", \"oldalpanel\": \"Edzett üveg (függőleges GPU)\", \"max_alaplap\": \"E-ATX, ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"6\", \"drive_bay_35\": \"4\", \"forma_faktor\": \"Mid-Tower ATX (Dual-Chamber)\", \"max_gpu_hossz\": \"435 mm (vízszintes) / 365 mm (függőleges)\", \"max_psu_hossz\": \"220 mm\", \"radiator_tamogatas\": \"Elöl: 360/280mm, Fent: 360mm\", \"ventillator_helyek\": \"3x 120/140mm elöl, 3x 120mm fent, 1x 120mm hátul\", \"ventillator_tartalma\": \"3x 120mm F Series RGB\", \"max_cpu_huto_magassag\": \"185 mm\"}', '79900.00', '74900.00', 18, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 16, '2026-01-23 10:03:55', NULL, NULL),
(121, 'Corsair 4000D Airflow', 'High airflow ATX mid-tower case', '{\"szin\": \"Fekete/Fehér\", \"gyarto\": \"Corsair\", \"meretek\": \"230 x 466 x 453 mm\", \"sorozat\": \"4000 Series\", \"io_panel\": \"1x USB 3.1 Type-C, 1x USB 3.0, Audio\", \"megjegyzes\": \"Kiváló légáramlás, RapidRoute kábel menedzsment\", \"oldalpanel\": \"Edzett üveg\", \"max_alaplap\": \"ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"2\", \"drive_bay_35\": \"2\", \"forma_faktor\": \"Mid-Tower ATX\", \"max_gpu_hossz\": \"360 mm\", \"max_psu_hossz\": \"220 mm\", \"radiator_tamogatas\": \"Elöl: 360/280mm, Fent: 240/280mm\", \"ventillator_helyek\": \"2x 120/140mm elöl, 1x 120mm hátul, 2x 120/140mm fent\", \"ventillator_tartalma\": \"2x 120mm AirGuide\", \"max_cpu_huto_magassag\": \"170 mm\"}', '38900.00', '34900.00', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 7, '2026-01-23 10:03:55', NULL, NULL),
(122, 'Corsair 5000D Airflow', 'Premium ATX mid-tower case', '{\"szin\": \"Fekete/Fehér\", \"gyarto\": \"Corsair\", \"meretek\": \"245 x 520 x 520 mm\", \"sorozat\": \"5000 Series\", \"io_panel\": \"1x USB 3.1 Type-C, 2x USB 3.0, Audio\", \"megjegyzes\": \"Prémium mid-tower, E-ATX támogatás\", \"oldalpanel\": \"Edzett üveg\", \"max_alaplap\": \"E-ATX, ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"4\", \"drive_bay_35\": \"2\", \"forma_faktor\": \"Mid-Tower ATX\", \"max_gpu_hossz\": \"420 mm\", \"max_psu_hossz\": \"225 mm\", \"radiator_tamogatas\": \"Elöl: 360/420mm, Fent: 360/420mm, Hátul: 120mm\", \"ventillator_helyek\": \"3x 120/140mm elöl, 1x 120/140mm hátul, 3x 120/140mm fent\", \"ventillator_tartalma\": \"2x 120mm AirGuide\", \"max_cpu_huto_magassag\": \"170 mm\"}', '64900.00', '59900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 7, '2026-01-23 10:03:55', NULL, NULL),
(123, 'Corsair iCUE 465X RGB', 'RGB tempered glass mid-tower case', '{\"rgb\": \"3x LL120 RGB ventilátor, Lighting Node PRO\", \"szin\": \"Fekete/Fehér\", \"gyarto\": \"Corsair\", \"meretek\": \"230 x 462 x 430 mm\", \"sorozat\": \"iCUE RGB\", \"io_panel\": \"2x USB 3.0, Audio\", \"megjegyzes\": \"3 oldalas üveg, iCUE RGB világítás\", \"oldalpanel\": \"Edzett üveg (3 oldal)\", \"max_alaplap\": \"ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"2\", \"drive_bay_35\": \"2\", \"forma_faktor\": \"Mid-Tower ATX\", \"max_gpu_hossz\": \"370 mm\", \"max_psu_hossz\": \"180 mm\", \"radiator_tamogatas\": \"Elöl: 360/280mm, Fent: 240mm\", \"ventillator_helyek\": \"3x 120mm elöl, 1x 120mm hátul\", \"ventillator_tartalma\": \"3x 120mm RGB LL120\", \"max_cpu_huto_magassag\": \"170 mm\"}', '52900.00', '48900.00', 28, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 7, '2026-01-23 10:03:55', NULL, NULL),
(124, 'MSI MPG GUNGNIR 110R', 'RGB gaming ATX case', '{\"rgb\": \"ARGB lighting, Mystic Light Sync\", \"szin\": \"Fekete\", \"gyarto\": \"MSI\", \"meretek\": \"230 x 492 x 491 mm\", \"sorozat\": \"MPG GUNGNIR\", \"io_panel\": \"1x USB 3.2 Gen 2 Type-C, 2x USB 3.2 Gen 1, Audio\", \"megjegyzes\": \"RGB gaming ház, Mystic Light\", \"oldalpanel\": \"Edzett üveg\", \"max_alaplap\": \"E-ATX, ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"2\", \"drive_bay_35\": \"2\", \"forma_faktor\": \"Mid-Tower ATX\", \"max_gpu_hossz\": \"400 mm\", \"max_psu_hossz\": \"200 mm\", \"radiator_tamogatas\": \"Elöl: 360mm, Fent: 360mm\", \"ventillator_helyek\": \"3x 120mm elöl, 1x 120mm hátul, 3x 120mm fent\", \"ventillator_tartalma\": \"4x 120mm ARGB\", \"max_cpu_huto_magassag\": \"175 mm\"}', '39900.00', '36900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 5, '2026-01-23 10:03:55', NULL, NULL),
(125, 'MSI MAG FORGE 100R', 'RGB airflow mid-tower case', '{\"rgb\": \"ARGB ventilátorok\", \"szin\": \"Fekete\", \"gyarto\": \"MSI\", \"meretek\": \"210 x 455 x 445 mm\", \"sorozat\": \"MAG FORGE\", \"io_panel\": \"2x USB 3.2 Gen 1, Audio\", \"megjegyzes\": \"Költséghatékony RGB gaming ház\", \"oldalpanel\": \"Edzett üveg\", \"max_alaplap\": \"ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"2\", \"drive_bay_35\": \"2\", \"forma_faktor\": \"Mid-Tower ATX\", \"max_gpu_hossz\": \"335 mm\", \"max_psu_hossz\": \"180 mm\", \"radiator_tamogatas\": \"Elöl: 280mm, Fent: 240mm\", \"ventillator_helyek\": \"3x 120mm elöl, 1x 120mm hátul, 2x 120mm fent\", \"ventillator_tartalma\": \"4x 120mm ARGB\", \"max_cpu_huto_magassag\": \"165 mm\"}', '29900.00', '26900.00', 50, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 5, '2026-01-23 10:03:55', NULL, NULL),
(126, 'ASUS TUF Gaming GT301', 'Durable ATX gaming case', '{\"rgb\": \"Aura Sync RGB\", \"szin\": \"Fekete\", \"gyarto\": \"ASUS\", \"meretek\": \"210 x 457 x 451 mm\", \"sorozat\": \"TUF Gaming\", \"io_panel\": \"1x USB 3.2 Gen 2 Type-C, 2x USB 3.0, Audio\", \"megjegyzes\": \"Strapabíró gaming ház, Aura Sync\", \"oldalpanel\": \"Edzett üveg\", \"max_alaplap\": \"ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"2\", \"drive_bay_35\": \"2\", \"forma_faktor\": \"Mid-Tower ATX\", \"max_gpu_hossz\": \"340 mm\", \"max_psu_hossz\": \"160 mm\", \"radiator_tamogatas\": \"Elöl: 360mm, Fent: 240mm\", \"ventillator_helyek\": \"3x 120mm elöl, 1x 120mm hátul, 2x 120mm fent\", \"ventillator_tartalma\": \"3x 120mm RGB\", \"max_cpu_huto_magassag\": \"160 mm\"}', '34900.00', '31900.00', 32, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 4, '2026-01-23 10:03:55', NULL, NULL);
INSERT INTO `products` (`id`, `name`, `description`, `properties`, `price`, `p_price`, `stock`, `image_url`, `category_id`, `brand_id`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(127, 'ASUS ROG Strix Helios', 'Premium full-tower gaming case', '{\"rgb\": \"Aura Sync RGB világítás\", \"szin\": \"Fekete/Fehér\", \"egyeb\": \"Függőleges GPU mount, alumínium váz\", \"gyarto\": \"ASUS\", \"meretek\": \"280 x 622 x 601 mm\", \"sorozat\": \"ROG Strix\", \"io_panel\": \"1x USB 3.1 Gen 2 Type-C, 4x USB 3.1 Gen 1, Audio\", \"megjegyzes\": \"Prémium full-tower, kiváló hűtés\", \"oldalpanel\": \"Edzett üveg + alumínium\", \"max_alaplap\": \"E-ATX, ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"6\", \"drive_bay_35\": \"6\", \"forma_faktor\": \"Full-Tower ATX\", \"max_gpu_hossz\": \"420 mm (vízszintes) / 330 mm (függőleges)\", \"max_psu_hossz\": \"200 mm\", \"radiator_tamogatas\": \"Elöl: 420mm, Fent: 280mm, Hátul: 140mm\", \"ventillator_helyek\": \"3x 140mm elöl, 2x 140mm fent, 1x 140mm hátul\", \"ventillator_tartalma\": \"4x 140mm Aura Sync RGB\", \"max_cpu_huto_magassag\": \"190 mm\"}', '109900.00', '99900.00', 12, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 4, '2026-01-23 10:03:55', NULL, NULL),
(128, 'NZXT H5 Flow', 'Compact airflow ATX case', '{\"szin\": \"Fekete/Fehér\", \"gyarto\": \"NZXT\", \"meretek\": \"210 x 460 x 435 mm\", \"sorozat\": \"H Series Flow\", \"io_panel\": \"1x USB 3.2 Gen 2 Type-C, 1x USB 3.2 Gen 1, Audio\", \"megjegyzes\": \"Kompakt, jó légáramlás\", \"oldalpanel\": \"Edzett üveg\", \"max_alaplap\": \"ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"2+2\", \"drive_bay_35\": \"2\", \"forma_faktor\": \"Mid-Tower ATX\", \"max_gpu_hossz\": \"365 mm\", \"max_psu_hossz\": \"180 mm\", \"radiator_tamogatas\": \"Elöl: 280mm, Fent: 240/280mm\", \"ventillator_helyek\": \"2x 120/140mm elöl, 1x 120mm hátul, 2x 120/140mm fent\", \"ventillator_tartalma\": \"2x 120mm F Series\", \"max_cpu_huto_magassag\": \"165 mm\"}', '36900.00', '33900.00', 38, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 16, '2026-01-23 10:03:55', NULL, NULL),
(129, 'Corsair Carbide 275R', 'Minimalist ATX mid-tower case', '{\"szin\": \"Fekete/Fehér\", \"gyarto\": \"Corsair\", \"meretek\": \"210 x 462 x 445 mm\", \"sorozat\": \"Carbide\", \"io_panel\": \"2x USB 3.0, Audio\", \"megjegyzes\": \"Minimalista, költséghatékony\", \"oldalpanel\": \"Edzett üveg vagy acrylic\", \"max_alaplap\": \"ATX, Micro-ATX, Mini-ITX\", \"drive_bay_25\": \"2\", \"drive_bay_35\": \"2\", \"forma_faktor\": \"Mid-Tower ATX\", \"max_gpu_hossz\": \"370 mm\", \"max_psu_hossz\": \"180 mm\", \"radiator_tamogatas\": \"Elöl: 240/280mm, Fent: 240/280mm\", \"ventillator_helyek\": \"2x 120/140mm elöl, 1x 120mm hátul, 2x 120/140mm fent\", \"max_cpu_huto_magassag\": \"170 mm\"}', '31900.00', '28900.00', 42, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 8, 7, '2026-01-23 10:03:55', NULL, NULL),
(130, 'Samsung 970 EVO Plus 1TB', 'NVMe M.2 SSD', '{\"tbw\": \"600 TB\", \"iras\": \"3300 MB/s\", \"tipus\": \"NVMe M.2\", \"gyarto\": \"Samsung\", \"olvasas\": \"3500 MB/s\", \"sorozat\": \"970 EVO Plus\", \"garancia\": \"5 ev\", \"interfesz\": \"PCIe 3.0 x4\", \"kapacitas\": \"1 TB\", \"megjegyzes\": \"Tovabbfejlesztett 970 EVO\", \"nand_tipus\": \"3D TLC V-NAND\", \"random_iras\": \"550K IOPS\", \"forma_faktor\": \"M.2 2280\", \"random_olvasas\": \"600K IOPS\"}', '39900.00', '36900.00', 60, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 8, '2026-01-23 10:15:34', NULL, NULL),
(131, 'Samsung 980 PRO 1TB', 'PCIe 4.0 NVMe SSD', '{\"tbw\": \"600 TB\", \"iras\": \"5000 MB/s\", \"tipus\": \"NVMe M.2\", \"gyarto\": \"Samsung\", \"olvasas\": \"7000 MB/s\", \"sorozat\": \"980 PRO\", \"garancia\": \"5 ev\", \"interfesz\": \"PCIe 4.0 x4\", \"kapacitas\": \"1 TB\", \"megjegyzes\": \"PCIe 4.0 gaming SSD\", \"nand_tipus\": \"3D TLC V-NAND\", \"random_iras\": \"1000K IOPS\", \"forma_faktor\": \"M.2 2280\", \"random_olvasas\": \"1000K IOPS\"}', '49900.00', '45900.00', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 8, '2026-01-23 10:15:34', NULL, NULL),
(132, 'Samsung 990 PRO 2TB', 'High-end NVMe SSD', '{\"tbw\": \"1200 TB\", \"iras\": \"6900 MB/s\", \"tipus\": \"NVMe M.2\", \"gyarto\": \"Samsung\", \"olvasas\": \"7450 MB/s\", \"sorozat\": \"990 PRO\", \"garancia\": \"5 ev\", \"interfesz\": \"PCIe 4.0 x4\", \"kapacitas\": \"2 TB\", \"controller\": \"Samsung Pascal (8nm)\", \"megjegyzes\": \"Csucskategorias PCIe 4.0, PS5 ready\", \"nand_tipus\": \"7th Gen 3D TLC V-NAND (176-layer)\", \"random_iras\": \"1550K IOPS\", \"forma_faktor\": \"M.2 2280\", \"random_olvasas\": \"1400K IOPS\", \"ps5_kompatibilis\": \"Igen\"}', '89900.00', '82900.00', 25, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 8, '2026-01-23 10:15:34', NULL, NULL),
(133, 'WD Black SN850X 1TB', 'Gaming NVMe SSD', '{\"tbw\": \"600 TB\", \"iras\": \"6300 MB/s\", \"tipus\": \"NVMe M.2\", \"gyarto\": \"Western Digital\", \"olvasas\": \"7300 MB/s\", \"sorozat\": \"WD Black SN850X\", \"garancia\": \"5 ev\", \"interfesz\": \"PCIe 4.0 x4\", \"kapacitas\": \"1 TB\", \"megjegyzes\": \"Gaming NVMe, Game Mode 2.0\", \"nand_tipus\": \"3D TLC NAND\", \"random_iras\": \"1100K IOPS\", \"forma_faktor\": \"M.2 2280\", \"random_olvasas\": \"1200K IOPS\"}', '46900.00', '42900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 9, '2026-01-23 10:15:34', NULL, NULL),
(134, 'WD Blue SN570 1TB', 'NVMe SSD', '{\"tbw\": \"600 TB\", \"iras\": \"3000 MB/s\", \"tipus\": \"NVMe M.2\", \"gyarto\": \"Western Digital\", \"olvasas\": \"3500 MB/s\", \"sorozat\": \"WD Blue SN570\", \"garancia\": \"5 ev\", \"interfesz\": \"PCIe 3.0 x4\", \"kapacitas\": \"1 TB\", \"megjegyzes\": \"Megbizhato mainstream NVMe\", \"nand_tipus\": \"3D TLC NAND\", \"forma_faktor\": \"M.2 2280\"}', '32900.00', '29900.00', 70, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 9, '2026-01-23 10:15:34', NULL, NULL),
(135, 'WD Green 480GB', 'SATA SSD', '{\"tbw\": \"80 TB\", \"iras\": \"430 MB/s\", \"tipus\": \"SATA 2.5 inch\", \"gyarto\": \"Western Digital\", \"olvasas\": \"545 MB/s\", \"sorozat\": \"WD Green\", \"garancia\": \"3 ev\", \"interfesz\": \"SATA III (6 Gb/s)\", \"kapacitas\": \"480 GB\", \"megjegyzes\": \"Koltseghatekony SATA SSD\", \"nand_tipus\": \"3D NAND\", \"forma_faktor\": \"2.5 inch 7mm\"}', '17900.00', '15900.00', 80, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 9, '2026-01-23 10:15:34', NULL, NULL),
(136, 'Corsair MP600 Pro LPX 1TB', 'PCIe 4.0 NVMe SSD', '{\"tbw\": \"700 TB\", \"iras\": \"5800 MB/s\", \"tipus\": \"NVMe M.2\", \"gyarto\": \"Corsair\", \"olvasas\": \"7100 MB/s\", \"sorozat\": \"MP600 Pro LPX\", \"garancia\": \"5 ev\", \"interfesz\": \"PCIe 4.0 x4\", \"kapacitas\": \"1 TB\", \"megjegyzes\": \"PS5 optimalizalt, hoelvezetovel\", \"nand_tipus\": \"3D TLC NAND\", \"forma_faktor\": \"M.2 2280\", \"ps5_kompatibilis\": \"Igen\"}', '48900.00', '44900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 7, '2026-01-23 10:15:34', NULL, NULL),
(137, 'Corsair MP510 960GB', 'NVMe SSD', '{\"tbw\": \"1700 TB\", \"iras\": \"3000 MB/s\", \"tipus\": \"NVMe M.2\", \"gyarto\": \"Corsair\", \"olvasas\": \"3480 MB/s\", \"sorozat\": \"Force MP510\", \"garancia\": \"5 ev\", \"interfesz\": \"PCIe 3.0 x4\", \"kapacitas\": \"960 GB\", \"megjegyzes\": \"Magas endurance SSD\", \"nand_tipus\": \"3D TLC NAND\", \"forma_faktor\": \"M.2 2280\"}', '35900.00', '32900.00', 50, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 7, '2026-01-23 10:15:34', NULL, NULL),
(138, 'MSI SPATIUM M450 1TB', 'NVMe SSD', '{\"tbw\": \"600 TB\", \"iras\": \"3000 MB/s\", \"tipus\": \"NVMe M.2\", \"gyarto\": \"MSI\", \"olvasas\": \"3600 MB/s\", \"sorozat\": \"SPATIUM M450\", \"garancia\": \"5 ev\", \"interfesz\": \"PCIe 4.0 x4\", \"kapacitas\": \"1 TB\", \"megjegyzes\": \"MSI gaming SSD\", \"nand_tipus\": \"3D NAND\", \"forma_faktor\": \"M.2 2280\"}', '31900.00', '28900.00', 55, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 5, '2026-01-23 10:15:34', NULL, NULL),
(139, 'MSI SPATIUM M480 Pro 2TB', 'High-performance NVMe SSD', '{\"tbw\": \"1400 TB\", \"iras\": \"7000 MB/s\", \"tipus\": \"NVMe M.2\", \"gyarto\": \"MSI\", \"olvasas\": \"7400 MB/s\", \"sorozat\": \"SPATIUM M480 Pro\", \"garancia\": \"5 ev\", \"interfesz\": \"PCIe 4.0 x4\", \"kapacitas\": \"2 TB\", \"megjegyzes\": \"High-performance gaming SSD\", \"nand_tipus\": \"3D NAND\", \"forma_faktor\": \"M.2 2280\"}', '87900.00', '81900.00', 22, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 5, '2026-01-23 10:15:34', NULL, NULL),
(140, 'Gigabyte AORUS Gen4 1TB', 'PCIe 4.0 NVMe SSD', '{\"tbw\": \"700 TB\", \"iras\": \"4400 MB/s\", \"tipus\": \"NVMe M.2\", \"gyarto\": \"Gigabyte\", \"olvasas\": \"5000 MB/s\", \"sorozat\": \"AORUS Gen4\", \"garancia\": \"5 ev\", \"interfesz\": \"PCIe 4.0 x4\", \"kapacitas\": \"1 TB\", \"megjegyzes\": \"Gaming SSD hoelvezetovel\", \"nand_tipus\": \"3D TLC NAND\", \"forma_faktor\": \"M.2 2280\"}', '45900.00', '41900.00', 38, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 6, '2026-01-23 10:15:34', NULL, NULL),
(141, 'Gigabyte NVMe 512GB', 'Budget NVMe SSD', '{\"iras\": \"1550 MB/s\", \"tipus\": \"NVMe M.2\", \"gyarto\": \"Gigabyte\", \"olvasas\": \"1700 MB/s\", \"garancia\": \"3 ev\", \"interfesz\": \"PCIe 3.0 x4\", \"kapacitas\": \"512 GB\", \"megjegyzes\": \"Budget NVMe SSD\", \"nand_tipus\": \"3D NAND\", \"forma_faktor\": \"M.2 2280\"}', '21900.00', '19900.00', 65, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 6, 6, '2026-01-23 10:15:34', NULL, NULL),
(142, 'WD Blue 1TB', '3.5\" SATA HDD', '{\"cache\": \"64 MB\", \"tipus\": \"3.5 inch HDD\", \"gyarto\": \"Western Digital\", \"sorozat\": \"WD Blue\", \"fordulat\": \"7200 RPM\", \"interfesz\": \"SATA III (6 Gb/s)\", \"kapacitas\": \"1 TB\", \"megjegyzes\": \"Desktop HDD\", \"forma_faktor\": \"3.5 inch\"}', '17900.00', '15900.00', 70, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 7, 9, '2026-01-23 10:15:48', NULL, NULL),
(143, 'WD Blue 2TB', '3.5\" SATA HDD', '{\"cache\": \"256 MB\", \"tipus\": \"3.5 inch HDD\", \"gyarto\": \"Western Digital\", \"sorozat\": \"WD Blue\", \"fordulat\": \"5400 RPM\", \"interfesz\": \"SATA III (6 Gb/s)\", \"kapacitas\": \"2 TB\", \"megjegyzes\": \"Alacsony zaj, energiatakarékos\", \"forma_faktor\": \"3.5 inch\"}', '22900.00', '20900.00', 60, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 7, 9, '2026-01-23 10:15:48', NULL, NULL),
(144, 'WD Blue 4TB', '3.5\" SATA HDD', '{\"cache\": \"256 MB\", \"tipus\": \"3.5 inch HDD\", \"gyarto\": \"Western Digital\", \"sorozat\": \"WD Blue\", \"fordulat\": \"5400 RPM\", \"interfesz\": \"SATA III (6 Gb/s)\", \"kapacitas\": \"4 TB\", \"megjegyzes\": \"Nagy kapacitas desktop-hoz\", \"forma_faktor\": \"3.5 inch\"}', '34900.00', '31900.00', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 7, 9, '2026-01-23 10:15:48', NULL, NULL),
(145, 'WD Black 2TB', 'High-performance HDD', '{\"cache\": \"256 MB\", \"tipus\": \"3.5 inch HDD\", \"gyarto\": \"Western Digital\", \"sorozat\": \"WD Black\", \"fordulat\": \"7200 RPM\", \"garancia\": \"5 ev\", \"interfesz\": \"SATA III (6 Gb/s)\", \"kapacitas\": \"2 TB\", \"megjegyzes\": \"High-performance gaming HDD\", \"forma_faktor\": \"3.5 inch\"}', '48900.00', '44900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 7, 9, '2026-01-23 10:15:48', NULL, NULL),
(146, 'WD Black 4TB', 'Gaming HDD', '{\"cache\": \"256 MB\", \"tipus\": \"3.5 inch HDD\", \"gyarto\": \"Western Digital\", \"sorozat\": \"WD Black\", \"fordulat\": \"7200 RPM\", \"garancia\": \"5 ev\", \"interfesz\": \"SATA III (6 Gb/s)\", \"kapacitas\": \"4 TB\", \"megjegyzes\": \"Gaming es munkaallomas HDD\", \"forma_faktor\": \"3.5 inch\"}', '69900.00', '64900.00', 22, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 7, 9, '2026-01-23 10:15:48', NULL, NULL),
(147, 'WD Red Plus 4TB', 'NAS HDD', '{\"cache\": \"128 MB\", \"tipus\": \"3.5 inch NAS HDD\", \"gyarto\": \"Western Digital\", \"sorozat\": \"WD Red Plus\", \"fordulat\": \"5400 RPM\", \"garancia\": \"3 ev\", \"interfesz\": \"SATA III (6 Gb/s)\", \"kapacitas\": \"4 TB\", \"alkalmazas\": \"NAS (1-8 rekesz)\", \"megjegyzes\": \"CMR technologia, NAS optimalizalt\", \"forma_faktor\": \"3.5 inch\"}', '59900.00', '55900.00', 28, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 7, 9, '2026-01-23 10:15:48', NULL, NULL),
(148, 'WD Red Plus 6TB', 'NAS HDD', '{\"cache\": \"128 MB\", \"tipus\": \"3.5 inch NAS HDD\", \"gyarto\": \"Western Digital\", \"sorozat\": \"WD Red Plus\", \"fordulat\": \"5400 RPM\", \"garancia\": \"3 ev\", \"interfesz\": \"SATA III (6 Gb/s)\", \"kapacitas\": \"6 TB\", \"alkalmazas\": \"NAS (1-8 rekesz)\", \"megjegyzes\": \"NAS tarolas, 24/7 mukodes\", \"forma_faktor\": \"3.5 inch\"}', '84900.00', '79900.00', 18, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 7, 9, '2026-01-23 10:15:48', NULL, NULL),
(149, 'WD Purple 2TB', 'Surveillance HDD', '{\"cache\": \"128 MB\", \"tipus\": \"3.5 inch Surveillance HDD\", \"gyarto\": \"Western Digital\", \"sorozat\": \"WD Purple\", \"fordulat\": \"5400 RPM\", \"garancia\": \"3 ev\", \"interfesz\": \"SATA III (6 Gb/s)\", \"kapacitas\": \"2 TB\", \"alkalmazas\": \"Biztonsagi kamerak\", \"megjegyzes\": \"24/7 videorögzites optimalizalt\", \"forma_faktor\": \"3.5 inch\"}', '25900.00', '23900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 7, 9, '2026-01-23 10:15:48', NULL, NULL),
(150, 'WD Purple 4TB', 'Surveillance HDD', '{\"cache\": \"256 MB\", \"tipus\": \"3.5 inch Surveillance HDD\", \"gyarto\": \"Western Digital\", \"sorozat\": \"WD Purple\", \"fordulat\": \"5400 RPM\", \"garancia\": \"3 ev\", \"interfesz\": \"SATA III (6 Gb/s)\", \"kapacitas\": \"4 TB\", \"alkalmazas\": \"Biztonsagi kamerak\", \"megjegyzes\": \"Surveillance optimalizalt\", \"forma_faktor\": \"3.5 inch\"}', '38900.00', '35900.00', 25, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 7, 9, '2026-01-23 10:15:48', NULL, NULL),
(151, 'WD Gold 8TB', 'Enterprise HDD', '{\"cache\": \"256 MB\", \"tipus\": \"3.5 inch Enterprise HDD\", \"gyarto\": \"Western Digital\", \"sorozat\": \"WD Gold\", \"fordulat\": \"7200 RPM\", \"garancia\": \"5 ev\", \"interfesz\": \"SATA III (6 Gb/s)\", \"kapacitas\": \"8 TB\", \"alkalmazas\": \"Enterprise, adatkozpont\", \"megjegyzes\": \"Enterprise-osztalyu megbizhhatosag\", \"forma_faktor\": \"3.5 inch\"}', '139900.00', '129900.00', 10, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 7, 9, '2026-01-23 10:15:48', NULL, NULL),
(152, 'WD Elements 2TB', 'External HDD', '{\"tipus\": \"Kulso HDD\", \"gyarto\": \"Western Digital\", \"sorozat\": \"WD Elements\", \"interfesz\": \"USB 3.0\", \"kapacitas\": \"2 TB\", \"megjegyzes\": \"Plug & Play kulso HDD\", \"forma_faktor\": \"3.5 inch Desktop\"}', '24900.00', '22900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 7, 9, '2026-01-23 10:15:48', NULL, NULL),
(153, 'WD My Passport 4TB', 'Portable external HDD', '{\"tipus\": \"Hordozhato kulso HDD\", \"gyarto\": \"Western Digital\", \"sorozat\": \"WD My Passport\", \"szoftver\": \"WD Backup, WD Security, WD Drive Utilities\", \"interfesz\": \"USB 3.2 Gen 1\", \"kapacitas\": \"4 TB\", \"megjegyzes\": \"Kompakt, hordozhato backup megoldas\", \"forma_faktor\": \"2.5 inch Portable\"}', '39900.00', '36900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 7, 9, '2026-01-23 10:15:48', NULL, NULL),
(154, 'Logitech G Pro X', 'Wired gaming headset', '{\"tipus\": \"Wired gaming headset\", \"driver\": \"Pro-G 50mm\", \"gyarto\": \"Logitech\", \"sorozat\": \"G Pro X\", \"fulparna\": \"Csereleheto (memory foam, velour)\", \"mikrofon\": \"Leveheto Blue VO!CE mikrofon\", \"szoftver\": \"Logitech G HUB\", \"zajszures\": \"Blue VO!CE szoftver\", \"megjegyzes\": \"Professzionalis wired gaming headset\", \"csatlakozas\": \"3.5mm + USB (DAC)\", \"frekvencia_valasz\": \"20Hz - 20kHz\"}', '45900.00', '41900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 14, 10, '2026-01-23 10:16:02', NULL, NULL),
(155, 'Logitech G Pro X Wireless', 'Wireless gaming headset', '{\"tipus\": \"Wireless gaming headset\", \"driver\": \"Pro-G 50mm\", \"gyarto\": \"Logitech\", \"sorozat\": \"G Pro X Wireless\", \"mikrofon\": \"Leveheto Blue VO!CE mikrofon\", \"szoftver\": \"Logitech G HUB\", \"zajszures\": \"Blue VO!CE szoftver\", \"megjegyzes\": \"Wireless esport headset\", \"akkumulator\": \"20+ ora\", \"csatlakozas\": \"Wireless 2.4GHz (USB dongle)\", \"frekvencia_valasz\": \"20Hz - 20kHz\"}', '69900.00', '64900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 14, 10, '2026-01-23 10:16:02', NULL, NULL),
(156, 'Logitech G733 Lightspeed', 'Wireless RGB headset', '{\"rgb\": \"RGB LIGHTSYNC\", \"suly\": \"278g (konnyu)\", \"tipus\": \"Wireless RGB headset\", \"driver\": \"Pro-G 40mm\", \"gyarto\": \"Logitech\", \"sorozat\": \"G733 Lightspeed\", \"mikrofon\": \"Leveheto\", \"szoftver\": \"Logitech G HUB\", \"megjegyzes\": \"Konnyu wireless RGB headset\", \"akkumulator\": \"29 ora\", \"csatlakozas\": \"Wireless 2.4GHz (USB dongle)\", \"frekvencia_valasz\": \"20Hz - 20kHz\"}', '48900.00', '44900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 14, 10, '2026-01-23 10:16:02', NULL, NULL),
(157, 'Logitech G435', 'Lightweight wireless headset', '{\"suly\": \"165g (ultra konnyu)\", \"tipus\": \"Lightweight wireless headset\", \"driver\": \"40mm\", \"gyarto\": \"Logitech\", \"sorozat\": \"G435\", \"mikrofon\": \"Dual beamforming mikrofon\", \"megjegyzes\": \"Ultra konnyu dual wireless headset\", \"akkumulator\": \"18 ora\", \"csatlakozas\": \"Wireless 2.4GHz + Bluetooth\", \"frekvencia_valasz\": \"20Hz - 20kHz\"}', '25900.00', '23900.00', 50, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 14, 10, '2026-01-23 10:16:02', NULL, NULL),
(158, 'Razer BlackShark V2', 'Esports gaming headset', '{\"thx\": \"THX Spatial Audio\", \"tipus\": \"Esports gaming headset\", \"driver\": \"Razer TriForce Titanium 50mm\", \"gyarto\": \"Razer\", \"sorozat\": \"BlackShark V2\", \"fulparna\": \"Memory foam\", \"mikrofon\": \"Razer HyperClear Cardioid\", \"szoftver\": \"Razer Synapse\", \"megjegyzes\": \"Esport headset THX-szel\", \"csatlakozas\": \"3.5mm + USB (THX)\", \"frekvencia_valasz\": \"12Hz - 28kHz\"}', '39900.00', '36900.00', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 14, 11, '2026-01-23 10:16:02', NULL, NULL),
(159, 'Razer BlackShark V2 Pro', 'Wireless esports headset', '{\"thx\": \"THX Spatial Audio\", \"tipus\": \"Wireless esports headset\", \"driver\": \"Razer TriForce Titanium 50mm\", \"gyarto\": \"Razer\", \"sorozat\": \"BlackShark V2 Pro\", \"mikrofon\": \"Razer HyperClear Cardioid leveheto\", \"szoftver\": \"Razer Synapse\", \"megjegyzes\": \"Wireless esport headset, 70h akksi\", \"akkumulator\": \"70 ora\", \"csatlakozas\": \"Wireless 2.4GHz (USB dongle)\", \"frekvencia_valasz\": \"12Hz - 28kHz\"}', '64900.00', '59900.00', 28, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 14, 11, '2026-01-23 10:16:02', NULL, NULL),
(160, 'Razer Kraken V3', 'RGB gaming headset', '{\"rgb\": \"Razer Chroma RGB\", \"thx\": \"THX Spatial Audio\", \"tipus\": \"RGB gaming headset\", \"driver\": \"Razer TriForce 50mm\", \"gyarto\": \"Razer\", \"sorozat\": \"Kraken V3\", \"mikrofon\": \"Razer HyperClear Cardioid\", \"szoftver\": \"Razer Synapse\", \"megjegyzes\": \"RGB gaming headset THX-szel\", \"csatlakozas\": \"USB\", \"frekvencia_valasz\": \"12Hz - 28kHz\"}', '32900.00', '29900.00', 42, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 14, 11, '2026-01-23 10:16:02', NULL, NULL),
(161, 'Razer Barracuda X', 'Wireless multi-platform headset', '{\"suly\": \"250g\", \"tipus\": \"Wireless multi-platform headset\", \"driver\": \"Razer TriForce 40mm\", \"gyarto\": \"Razer\", \"sorozat\": \"Barracuda X\", \"mikrofon\": \"Leveheto HyperClear Cardioid\", \"megjegyzes\": \"Multi-platform wireless, PC/PS5/Switch/mobil\", \"akkumulator\": \"50 ora (2.4GHz), 200 ora (Bluetooth)\", \"csatlakozas\": \"Wireless 2.4GHz + Bluetooth + 3.5mm\", \"frekvencia_valasz\": \"20Hz - 20kHz\"}', '37900.00', '34900.00', 38, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 14, 11, '2026-01-23 10:16:02', NULL, NULL),
(162, 'Samsung Odyssey Gaming Headset', 'Wired gaming headset', '{\"tipus\": \"Wired gaming headset\", \"driver\": \"40mm\", \"gyarto\": \"Samsung\", \"sorozat\": \"Odyssey\", \"mikrofon\": \"Beepitett mikrofon\", \"megjegyzes\": \"Alapveto wired gaming headset\", \"csatlakozas\": \"3.5mm\"}', '24900.00', '21900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 14, 8, '2026-01-23 10:16:02', 1, '2026-02-25 09:11:23'),
(163, 'Samsung AKG EO-IG955', 'In-ear headset', '{\"tipus\": \"In-ear headset\", \"driver\": \"AKG\", \"gyarto\": \"Samsung\", \"sorozat\": \"AKG\", \"mikrofon\": \"Inline mikrofon es vezerlok\", \"megjegyzes\": \"AKG minosegu in-ear headset\", \"csatlakozas\": \"3.5mm\"}', '15900.00', '13900.00', 60, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 14, 8, '2026-01-23 10:16:02', 1, '2026-02-25 09:12:49'),
(164, 'Samsung Wireless Headset Level U2', 'Bluetooth headset', '{\"tipus\": \"Bluetooth headset\", \"driver\": \"Nyakpantos in-ear\", \"gyarto\": \"Samsung\", \"sorozat\": \"Level U2\", \"mikrofon\": \"Beepitett mikrofon\", \"megjegyzes\": \"Bluetooth nyakpantos headset\", \"akkumulator\": \"10 ora\", \"csatlakozas\": \"Bluetooth\"}', '22900.00', '19900.00', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 14, 8, '2026-01-23 10:16:02', 1, '2026-02-25 09:10:34'),
(165, 'Samsung Gaming Headset GHS60', 'USB gaming headset', '{\"rgb\": \"RGB vilagitas\", \"tipus\": \"USB gaming headset\", \"driver\": \"50mm\", \"gyarto\": \"Samsung\", \"sorozat\": \"GHS60\", \"mikrofon\": \"Beepitett mikrofon\", \"megjegyzes\": \"Budget USB gaming headset\", \"csatlakozas\": \"USB\"}', '19900.00', '17900.00', 50, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 14, 8, '2026-01-23 10:16:02', 1, '2026-02-25 09:10:58'),
(166, 'Corsair RM750x', '750W 80+ Gold fully modular PSU', '{\"pfc\": \"Aktiv PFC\", \"gyarto\": \"Corsair\", \"sorozat\": \"RM Series\", \"vedelem\": \"OVP, UVP, OCP, OTP, SCP\", \"garancia\": \"10 ev\", \"hatekonyag\": \"80 Plus Gold\", \"megjegyzes\": \"Duplikatum - ugyanaz mint ID 37\", \"modularitas\": \"Teljesen modularis\", \"ventillator\": \"135mm FDB ventillator\", \"forma_faktor\": \"ATX\", \"teljesitmeny\": \"750 W\"}', '52900.00', '48900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 7, '2026-01-23 10:21:18', NULL, NULL),
(167, 'Corsair RM850x', '850W 80+ Gold fully modular PSU', '{\"pfc\": \"Aktiv PFC\", \"gyarto\": \"Corsair\", \"sorozat\": \"RM Series\", \"vedelem\": \"OVP, UVP, OCP, OTP, SCP\", \"garancia\": \"10 ev\", \"hatekonyag\": \"80 Plus Gold\", \"megjegyzes\": \"Zero RPM mod, kivalo teljesitmeny\", \"modularitas\": \"Teljesen modularis\", \"ventillator\": \"135mm FDB ventillator\", \"forma_faktor\": \"ATX\", \"teljesitmeny\": \"850 W\"}', '59900.00', '55900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 7, '2026-01-23 10:21:18', NULL, NULL),
(168, 'Corsair CV650', '650W 80+ Bronze PSU', '{\"pfc\": \"Aktiv PFC\", \"gyarto\": \"Corsair\", \"sorozat\": \"CV Series\", \"vedelem\": \"OVP, OCP, SCP\", \"garancia\": \"3 ev\", \"hatekonyag\": \"80 Plus Bronze\", \"megjegyzes\": \"Koltseghatekony megoldas\", \"modularitas\": \"Nem modularis\", \"ventillator\": \"120mm ventillator\", \"forma_faktor\": \"ATX\", \"teljesitmeny\": \"650 W\"}', '28900.00', '25900.00', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 7, '2026-01-23 10:21:18', NULL, NULL),
(169, 'MSI MPG A750GF', '750W 80+ Gold modular PSU', '{\"pfc\": \"Aktiv PFC\", \"gyarto\": \"MSI\", \"sorozat\": \"MPG\", \"vedelem\": \"OVP, UVP, OCP, OTP, SCP, OPP\", \"garancia\": \"10 ev\", \"hatekonyag\": \"80 Plus Gold\", \"megjegyzes\": \"Gaming PSU, alacsony zaj\", \"modularitas\": \"Teljesen modularis\", \"ventillator\": \"140mm HDB ventillator\", \"forma_faktor\": \"ATX\", \"teljesitmeny\": \"750 W\"}', '49900.00', '45900.00', 28, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 5, '2026-01-23 10:21:18', NULL, NULL),
(170, 'MSI MAG A650BN', '650W 80+ Bronze PSU', '{\"pfc\": \"Aktiv PFC\", \"gyarto\": \"MSI\", \"sorozat\": \"MAG\", \"vedelem\": \"OVP, OCP, SCP\", \"garancia\": \"5 ev\", \"hatekonyag\": \"80 Plus Bronze\", \"megjegyzes\": \"Gaming belepo szint\", \"modularitas\": \"Nem modularis\", \"ventillator\": \"120mm ventillator\", \"forma_faktor\": \"ATX\", \"teljesitmeny\": \"650 W\"}', '27900.00', '24900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 5, '2026-01-23 10:21:18', NULL, NULL),
(171, 'ASUS ROG Strix 850G', '850W 80+ Gold PSU', '{\"pfc\": \"Aktiv PFC\", \"rgb\": \"Aura Sync kompatibilis\", \"gyarto\": \"ASUS\", \"sorozat\": \"ROG Strix\", \"vedelem\": \"OVP, UVP, OCP, OTP, SCP, OPP\", \"garancia\": \"10 ev\", \"hatekonyag\": \"80 Plus Gold\", \"megjegyzes\": \"ROG gaming PSU\", \"modularitas\": \"Teljesen modularis\", \"ventillator\": \"135mm Axial-tech ventillator\", \"forma_faktor\": \"ATX\", \"teljesitmeny\": \"850 W\"}', '64900.00', '59900.00', 22, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 4, '2026-01-23 10:21:18', NULL, NULL),
(172, 'ASUS TUF Gaming 750B', '750W 80+ Bronze PSU', '{\"pfc\": \"Aktiv PFC\", \"gyarto\": \"ASUS\", \"sorozat\": \"TUF Gaming\", \"vedelem\": \"OVP, UVP, OCP, OTP, SCP\", \"garancia\": \"6 ev\", \"hatekonyag\": \"80 Plus Bronze\", \"megjegyzes\": \"Strapabiro gaming PSU\", \"modularitas\": \"Nem modularis\", \"ventillator\": \"135mm ventillator\", \"forma_faktor\": \"ATX\", \"teljesitmeny\": \"750 W\"}', '39900.00', '36900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 4, '2026-01-23 10:21:18', NULL, NULL),
(173, 'NZXT C650', '650W 80+ Gold modular PSU', '{\"pfc\": \"Aktiv PFC\", \"gyarto\": \"NZXT\", \"sorozat\": \"C Series\", \"vedelem\": \"OVP, UVP, OCP, OTP, SCP\", \"garancia\": \"10 ev\", \"hatekonyag\": \"80 Plus Gold\", \"megjegyzes\": \"Kompakt kabelek, alacsony zaj\", \"modularitas\": \"Teljesen modularis\", \"ventillator\": \"120mm FDB ventillator\", \"forma_faktor\": \"ATX\", \"teljesitmeny\": \"650 W\"}', '44900.00', '41900.00', 26, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 16, '2026-01-23 10:21:18', NULL, NULL),
(174, 'NZXT C850', '850W 80+ Gold PSU', '{\"pfc\": \"Aktiv PFC\", \"gyarto\": \"NZXT\", \"sorozat\": \"C Series\", \"vedelem\": \"OVP, UVP, OCP, OTP, SCP\", \"garancia\": \"10 ev\", \"hatekonyag\": \"80 Plus Gold\", \"megjegyzes\": \"Premium tap gaming rendszerekhez\", \"modularitas\": \"Teljesen modularis\", \"ventillator\": \"135mm FDB ventillator\", \"forma_faktor\": \"ATX\", \"teljesitmeny\": \"850 W\"}', '58900.00', '54900.00', 20, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 16, '2026-01-23 10:21:18', NULL, NULL),
(175, 'Corsair SF750', '750W SFX 80+ Platinum PSU', '{\"pfc\": \"Aktiv PFC\", \"gyarto\": \"Corsair\", \"sorozat\": \"SF Series\", \"vedelem\": \"OVP, UVP, OCP, OTP, SCP\", \"garancia\": \"7 ev\", \"hatekonyag\": \"80 Plus Platinum\", \"megjegyzes\": \"Kompakt SFX, mini-ITX rendszerekhez\", \"modularitas\": \"Teljesen modularis\", \"ventillator\": \"92mm FDB ventillator\", \"forma_faktor\": \"SFX\", \"teljesitmeny\": \"750 W\"}', '69900.00', '64900.00', 18, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 7, '2026-01-23 10:21:18', NULL, NULL),
(176, 'MSI MPG A1000G', '1000W 80+ Gold PSU', '{\"pfc\": \"Aktiv PFC\", \"gyarto\": \"MSI\", \"sorozat\": \"MPG\", \"vedelem\": \"OVP, UVP, OCP, OTP, SCP, OPP\", \"garancia\": \"10 ev\", \"hatekonyag\": \"80 Plus Gold\", \"megjegyzes\": \"High-end gaming es workstation\", \"modularitas\": \"Teljesen modularis\", \"ventillator\": \"140mm HDB ventillator\", \"forma_faktor\": \"ATX\", \"teljesitmeny\": \"1000 W\"}', '79900.00', '74900.00', 15, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 5, '2026-01-23 10:21:18', NULL, NULL),
(177, 'ASUS ROG Thor 1000P', '1000W 80+ Platinum PSU', '{\"pfc\": \"Aktiv PFC\", \"rgb\": \"Aura Sync RGB\", \"egyeb\": \"OLED kijelzo (watt mero)\", \"gyarto\": \"ASUS\", \"sorozat\": \"ROG Thor\", \"vedelem\": \"OVP, UVP, OCP, OTP, SCP, OPP\", \"garancia\": \"10 ev\", \"hatekonyag\": \"80 Plus Platinum\", \"megjegyzes\": \"Premium PSU OLED kijelzovel\", \"modularitas\": \"Teljesen modularis\", \"ventillator\": \"135mm Axial-tech ventillator\", \"forma_faktor\": \"ATX\", \"teljesitmeny\": \"1000 W\"}', '139900.00', '129900.00', 10, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 5, 4, '2026-01-23 10:21:18', NULL, NULL),
(178, 'Noctua NH-D15', 'Dual-tower premium air cooler', '{\"tdp\": \"220 W+\", \"szin\": \"Barna/bezs\", \"tipus\": \"Air Cooler (Dual Tower)\", \"gyarto\": \"Noctua\", \"sorozat\": \"NH-D15\", \"heatpipe\": \"6x 6mm heatpipe\", \"magassag\": \"165 mm\", \"zajszint\": \"24.6 dBA\", \"foglalatok\": \"Intel LGA1700/1200/115x, AMD AM5/AM4\", \"megjegyzes\": \"Flagship dual-tower air cooler\", \"ventillator\": \"2x NF-A15 (140mm)\"}', '42900.00', '39900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 17, '2026-01-23 10:21:40', 1, '2026-02-18 10:29:53'),
(179, 'Noctua NH-U12S', 'Single tower air cooler', '{\"tdp\": \"165 W\", \"szin\": \"Barna/bezs\", \"tipus\": \"Air Cooler (Tower)\", \"gyarto\": \"Noctua\", \"sorozat\": \"NH-U12S\", \"heatpipe\": \"5x 6mm heatpipe\", \"magassag\": \"158 mm\", \"zajszint\": \"22.4 dBA\", \"foglalatok\": \"Intel LGA1700/1200/115x, AMD AM5/AM4\", \"megjegyzes\": \"Duplikatum - ugyanaz mint ID 39\", \"ventillator\": \"1x NF-F12 (120mm)\"}', '28900.00', '25900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 17, '2026-01-23 10:21:40', NULL, NULL),
(180, 'Noctua NH-L9i', 'Low-profile CPU cooler', '{\"tdp\": \"95 W\", \"tipus\": \"Air Cooler (Low-Profile)\", \"gyarto\": \"Noctua\", \"sorozat\": \"NH-L9i\", \"magassag\": \"37 mm\", \"zajszint\": \"23.6 dBA\", \"foglalatok\": \"Intel LGA1700/1200/115x\", \"megjegyzes\": \"Ultra kompakt low-profile cooler\", \"ventillator\": \"1x NF-A9 (92mm)\"}', '18900.00', '16900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 17, '2026-01-23 10:21:40', NULL, NULL),
(181, 'Corsair iCUE H100i Elite', '240mm AIO liquid cooler', '{\"rgb\": \"iCUE RGB\", \"tdp\": \"250 W+\", \"pumpa\": \"RGB pumpa fej\", \"tipus\": \"AIO Liquid Cooler\", \"gyarto\": \"Corsair\", \"sorozat\": \"iCUE H100i Elite\", \"szoftver\": \"Corsair iCUE\", \"foglalatok\": \"Intel LGA1700/1200/115x, AMD AM5/AM4\", \"megjegyzes\": \"240mm AIO RGB vizihutessel\", \"ventillator\": \"2x ML120 RGB (120mm)\", \"radiator_meret\": \"240mm\"}', '56900.00', '52900.00', 25, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 7, '2026-01-23 10:21:40', NULL, NULL),
(182, 'Corsair iCUE H150i Elite', '360mm AIO liquid cooler', '{\"rgb\": \"iCUE RGB\", \"tdp\": \"300 W+\", \"pumpa\": \"RGB pumpa fej\", \"tipus\": \"AIO Liquid Cooler\", \"gyarto\": \"Corsair\", \"sorozat\": \"iCUE H150i Elite\", \"szoftver\": \"Corsair iCUE\", \"foglalatok\": \"Intel LGA1700/1200/115x, AMD AM5/AM4\", \"megjegyzes\": \"360mm AIO high-end vizihutessel\", \"ventillator\": \"3x ML120 RGB (120mm)\", \"radiator_meret\": \"360mm\"}', '69900.00', '64900.00', 20, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 7, '2026-01-23 10:21:40', NULL, NULL),
(183, 'MSI MAG CoreLiquid 240R', '240mm liquid CPU cooler', '{\"rgb\": \"ARGB\", \"tdp\": \"250 W\", \"pumpa\": \"RGB pumpa\", \"tipus\": \"AIO Liquid Cooler\", \"gyarto\": \"MSI\", \"sorozat\": \"MAG CoreLiquid 240R\", \"foglalatok\": \"Intel LGA1700/1200/115x, AMD AM5/AM4\", \"megjegyzes\": \"240mm AIO RGB vizihutessel\", \"ventillator\": \"2x 120mm RGB\", \"radiator_meret\": \"240mm\"}', '39900.00', '36900.00', 28, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 5, '2026-01-23 10:21:40', NULL, NULL),
(184, 'MSI MAG CoreLiquid 360R', '360mm AIO liquid cooler', '{\"rgb\": \"ARGB\", \"tdp\": \"300 W+\", \"pumpa\": \"RGB pumpa\", \"tipus\": \"AIO Liquid Cooler\", \"gyarto\": \"MSI\", \"sorozat\": \"MAG CoreLiquid 360R\", \"foglalatok\": \"Intel LGA1700/1200/115x, AMD AM5/AM4\", \"megjegyzes\": \"360mm AIO vizihutessel\", \"ventillator\": \"3x 120mm RGB\", \"radiator_meret\": \"360mm\"}', '54900.00', '50900.00', 18, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 5, '2026-01-23 10:21:40', NULL, NULL),
(185, 'NZXT Kraken X63', '280mm RGB AIO cooler', '{\"rgb\": \"RGB Infinity Mirror\", \"tdp\": \"280 W+\", \"pumpa\": \"Infinity Mirror RGB pumpa\", \"tipus\": \"AIO Liquid Cooler\", \"gyarto\": \"NZXT\", \"sorozat\": \"Kraken X63\", \"szoftver\": \"NZXT CAM\", \"foglalatok\": \"Intel LGA1700/1200/115x, AMD AM5/AM4\", \"megjegyzes\": \"280mm AIO RGB Infinity Mirror pumpával\", \"ventillator\": \"2x Aer P (140mm)\", \"radiator_meret\": \"280mm\"}', '64900.00', '59900.00', 22, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 16, '2026-01-23 10:21:40', NULL, NULL),
(186, 'NZXT Kraken Z73', '360mm LCD AIO cooler', '{\"lcd\": \"2.36 inch LCD (GIF, kepek, rendszerinfo)\", \"tdp\": \"300 W+\", \"pumpa\": \"2.36 inch LCD kijelzo\", \"tipus\": \"AIO Liquid Cooler\", \"gyarto\": \"NZXT\", \"sorozat\": \"Kraken Z73\", \"szoftver\": \"NZXT CAM\", \"foglalatok\": \"Intel LGA1700/1200/115x, AMD AM5/AM4\", \"megjegyzes\": \"Premium 360mm AIO LCD kijelzovel\", \"ventillator\": \"3x Aer P (120mm)\", \"radiator_meret\": \"360mm\"}', '89900.00', '84900.00', 15, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 16, '2026-01-23 10:21:40', NULL, NULL),
(187, 'ASUS ROG Ryujin II 360', 'Premium AIO liquid cooler', '{\"lcd\": \"3.5 inch Full-Color LCD\", \"rgb\": \"Aura Sync RGB\", \"tdp\": \"300 W+\", \"pumpa\": \"3.5 inch LCD kijelzo\", \"tipus\": \"AIO Liquid Cooler\", \"gyarto\": \"ASUS\", \"sorozat\": \"ROG Ryujin II 360\", \"szoftver\": \"Armoury Crate\", \"foglalatok\": \"Intel LGA1700/1200/115x, AMD AM5/AM4\", \"megjegyzes\": \"Premium ROG 360mm AIO nagy LCD-vel\", \"ventillator\": \"3x ROG 120mm RGB\", \"radiator_meret\": \"360mm\"}', '119900.00', '109900.00', 10, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 4, '2026-01-23 10:21:40', NULL, NULL),
(188, 'ASUS TUF Gaming LC 240', '240mm AIO CPU cooler', '{\"rgb\": \"Aura Sync RGB\", \"tdp\": \"250 W\", \"tipus\": \"AIO Liquid Cooler\", \"gyarto\": \"ASUS\", \"sorozat\": \"TUF Gaming LC 240\", \"szoftver\": \"Armoury Crate\", \"foglalatok\": \"Intel LGA1700/1200/115x, AMD AM5/AM4\", \"megjegyzes\": \"TUF 240mm AIO strapabiro kialakitassal\", \"ventillator\": \"2x TUF 120mm RGB\", \"radiator_meret\": \"240mm\"}', '36900.00', '33900.00', 24, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 4, '2026-01-23 10:21:40', NULL, NULL),
(189, 'Noctua NH-D15 chromax.black', 'Black premium air cooler', '{\"tdp\": \"220 W+\", \"szin\": \"Fekete (chromax)\", \"tipus\": \"Air Cooler (Dual Tower)\", \"gyarto\": \"Noctua\", \"sorozat\": \"NH-D15 chromax.black\", \"heatpipe\": \"6x 6mm heatpipe\", \"magassag\": \"165 mm\", \"zajszint\": \"24.6 dBA\", \"foglalatok\": \"Intel LGA1700/1200/115x, AMD AM5/AM4\", \"megjegyzes\": \"Fekete verzio a flagship NH-D15-bol\", \"ventillator\": \"2x NF-A15 PWM chromax.black (140mm)\"}', '44900.00', '41900.00', 20, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 9, 17, '2026-01-23 10:21:40', NULL, NULL),
(190, 'Logitech G Pro X Keyboard Pink', 'Mechanical esports keyboard', '{\"tipus\": \"Mechanikus gaming keyboard\", \"gyarto\": \"Logitech\", \"layout\": \"Tenkeyless (TKL)\", \"sorozat\": \"G Pro X\", \"szoftver\": \"Logitech G HUB\", \"megjegyzes\": \"Duplikatum - ugyanaz mint ID 41\", \"csatlakozas\": \"USB-C leveheto kabel\", \"switch_tipus\": \"GX csereleheto (Blue/Brown/Red)\", \"hattervilagitas\": \"RGB per-key\"}', '49900.00', '45900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 10, '2026-01-23 10:22:02', NULL, NULL),
(191, 'Logitech G915 Lightspeed', 'Wireless low-profile mechanical keyboard', '{\"anyag\": \"Aluminium felso panel\", \"tipus\": \"Mechanikus gaming keyboard\", \"gyarto\": \"Logitech\", \"layout\": \"Full-size\", \"sorozat\": \"G915\", \"szoftver\": \"Logitech G HUB\", \"megjegyzes\": \"Premium wireless low-profile mechanikus\", \"akkumulator\": \"30 ora (teljes fenyerovel)\", \"csatlakozas\": \"Wireless (2.4GHz + Bluetooth) / USB\", \"switch_tipus\": \"GL Low Profile (Clicky/Tactile/Linear)\", \"hattervilagitas\": \"RGB per-key LIGHTSYNC\"}', '79900.00', '74900.00', 20, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 10, '2026-01-23 10:22:02', NULL, NULL),
(192, 'Logitech G213', 'RGB gaming keyboard', '{\"tipus\": \"Membranos gaming keyboard\", \"gyarto\": \"Logitech\", \"layout\": \"Full-size\", \"sorozat\": \"G213\", \"vizallo\": \"Froccsenes ellen vedett\", \"szoftver\": \"Logitech G HUB\", \"megjegyzes\": \"Belepo szintu gaming keyboard\", \"csatlakozas\": \"USB\", \"hattervilagitas\": \"RGB 5-zona LIGHTSYNC\"}', '18900.00', '16900.00', 50, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 10, '2026-01-23 10:22:02', NULL, NULL),
(193, 'Razer BlackWidow V4', 'Mechanical RGB gaming keyboard', '{\"tipus\": \"Mechanikus gaming keyboard\", \"gyarto\": \"Razer\", \"layout\": \"Full-size\", \"sorozat\": \"BlackWidow V4\", \"szoftver\": \"Razer Synapse\", \"megjegyzes\": \"Flagship mechanikus gaming keyboard\", \"csatlakozas\": \"USB\", \"media_gombok\": \"Dedikalt media gombok es hangerovezerlok\", \"switch_tipus\": \"Razer Green (Clicky)\", \"csuklo_tamasz\": \"Leveheto csuklo tamasz\", \"hattervilagitas\": \"RGB per-key Chroma\"}', '69900.00', '64900.00', 25, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 11, '2026-01-23 10:22:02', NULL, NULL),
(194, 'Razer Huntsman Mini', '60% optical mechanical keyboard', '{\"tipus\": \"Mechanikus gaming keyboard\", \"gyarto\": \"Razer\", \"layout\": \"60% kompakt\", \"sorozat\": \"Huntsman Mini\", \"szoftver\": \"Razer Synapse\", \"megjegyzes\": \"Kompakt 60% optikai mechanikus\", \"csatlakozas\": \"USB-C leveheto kabel\", \"switch_tipus\": \"Razer Optical (Clicky/Linear)\", \"hattervilagitas\": \"RGB per-key Chroma\"}', '45900.00', '41900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 11, '2026-01-23 10:22:02', NULL, NULL),
(195, 'Razer Ornata V3', 'Low-profile gaming keyboard', '{\"tipus\": \"Mecha-membrane gaming keyboard\", \"gyarto\": \"Razer\", \"layout\": \"Full-size\", \"sorozat\": \"Ornata V3\", \"szoftver\": \"Razer Synapse\", \"megjegyzes\": \"Hibrid mecha-membrane technologia\", \"csatlakozas\": \"USB\", \"switch_tipus\": \"Razer Mecha-Membrane\", \"csuklo_tamasz\": \"Leveheto\", \"hattervilagitas\": \"RGB 10-zona Chroma\"}', '24900.00', '21900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 11, '2026-01-23 10:22:02', NULL, NULL),
(196, 'Corsair K70 RGB Pro', 'Mechanical gaming keyboard', '{\"anyag\": \"Aluminium keret\", \"tipus\": \"Mechanikus gaming keyboard\", \"gyarto\": \"Corsair\", \"layout\": \"Full-size\", \"sorozat\": \"K70 RGB Pro\", \"szoftver\": \"iCUE\", \"megjegyzes\": \"Premium Cherry MX mechanikus\", \"csatlakozas\": \"USB\", \"media_gombok\": \"Multimedias gombok\", \"switch_tipus\": \"Cherry MX (Red/Brown/Blue)\", \"hattervilagitas\": \"RGB per-key\"}', '64900.00', '59900.00', 28, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 7, '2026-01-23 10:22:02', NULL, NULL),
(197, 'Corsair K55 RGB Pro', 'Membrane RGB keyboard', '{\"tipus\": \"Membranos gaming keyboard\", \"gyarto\": \"Corsair\", \"layout\": \"Full-size\", \"sorozat\": \"K55 RGB Pro\", \"vizallo\": \"IP42 vedelem\", \"szoftver\": \"iCUE\", \"megjegyzes\": \"Koltseghatekony gaming keyboard\", \"csatlakozas\": \"USB\", \"media_gombok\": \"Dedikalt media gombok\", \"hattervilagitas\": \"RGB 5-zona\"}', '27900.00', '24900.00', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 7, '2026-01-23 10:22:02', NULL, NULL),
(198, 'MSI Vigor GK60', 'Mechanical gaming keyboard', '{\"tipus\": \"Mechanikus gaming keyboard\", \"gyarto\": \"MSI\", \"layout\": \"Full-size\", \"sorozat\": \"Vigor GK60\", \"szoftver\": \"MSI Center\", \"megjegyzes\": \"Gaming mechanikus Kailh switchekkel\", \"csatlakozas\": \"USB\", \"switch_tipus\": \"Kailh Box White (Clicky)\", \"hattervilagitas\": \"RGB per-key\"}', '32900.00', '29900.00', 32, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 5, '2026-01-23 10:22:02', NULL, NULL),
(199, 'MSI Vigor GK30', 'RGB gaming keyboard', '{\"tipus\": \"Membranos gaming keyboard\", \"gyarto\": \"MSI\", \"layout\": \"Full-size\", \"sorozat\": \"Vigor GK30\", \"szoftver\": \"MSI Center\", \"megjegyzes\": \"Belepo szintu gaming keyboard\", \"csatlakozas\": \"USB\", \"hattervilagitas\": \"RGB\"}', '19900.00', '17900.00', 48, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 5, '2026-01-23 10:22:02', NULL, NULL),
(200, 'ASUS TUF Gaming K1', 'RGB gaming keyboard', '{\"tipus\": \"Membranos gaming keyboard\", \"gyarto\": \"ASUS\", \"layout\": \"Full-size\", \"sorozat\": \"TUF Gaming K1\", \"vizallo\": \"Froccsenes ellen vedett\", \"szoftver\": \"Armoury Crate\", \"megjegyzes\": \"TUF strapabiro gaming keyboard\", \"csatlakozas\": \"USB\", \"csuklo_tamasz\": \"Leveheto\", \"hattervilagitas\": \"RGB Aura Sync\"}', '18900.00', '16900.00', 50, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 4, '2026-01-23 10:22:02', NULL, NULL),
(201, 'ASUS ROG Strix Scope II', 'Mechanical gaming keyboard', '{\"anyag\": \"Aluminium felso panel\", \"tipus\": \"Mechanikus gaming keyboard\", \"gyarto\": \"ASUS\", \"layout\": \"Full-size\", \"sorozat\": \"ROG Strix Scope\", \"szoftver\": \"Armoury Crate\", \"megjegyzes\": \"ROG mechanikus Cherry MX\", \"csatlakozas\": \"USB\", \"switch_tipus\": \"Cherry MX (Red/Brown/Blue)\", \"csuklo_tamasz\": \"Leveheto\", \"hattervilagitas\": \"RGB per-key Aura Sync\"}', '49900.00', '45900.00', 26, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 12, 4, '2026-01-23 10:22:02', NULL, NULL),
(202, 'Logitech G640', 'Large cloth mouse pad', '{\"meret\": \"Large (460 x 400 mm)\", \"tipus\": \"Textil egerpad\", \"gyarto\": \"Logitech\", \"felszin\": \"Kozepes surlodasu textil\", \"sorozat\": \"G640\", \"also_resz\": \"Gumi (csuszasmentes)\", \"vastagsag\": \"3 mm\", \"megjegyzes\": \"Nagy meretu textil gaming egerpad\"}', '11900.00', '9900.00', 70, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 15, 10, '2026-01-23 10:22:30', NULL, NULL),
(203, 'Logitech G840 XL', 'Extra large gaming mouse pad', '{\"meret\": \"XL (900 x 400 mm)\", \"tipus\": \"Textil egerpad\", \"gyarto\": \"Logitech\", \"felszin\": \"Kozepes surlodasu textil\", \"sorozat\": \"G840 XL\", \"also_resz\": \"Gumi (csuszasmentes)\", \"vastagsag\": \"3 mm\", \"megjegyzes\": \"Extra nagy full-desk egerpad\"}', '19900.00', '17900.00', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 15, 10, '2026-01-23 10:22:30', NULL, NULL),
(204, 'Razer Gigantus V2 Large', 'Gaming mouse pad', '{\"meret\": \"Large (450 x 400 mm)\", \"tipus\": \"Textil egerpad\", \"gyarto\": \"Razer\", \"felszin\": \"Textil felszin\", \"sorozat\": \"Gigantus V2\", \"also_resz\": \"Csuszasmentes gumi alap\", \"vastagsag\": \"3 mm\", \"megjegyzes\": \"Gaming egerpad textil felszinnel\"}', '10900.00', '8900.00', 80, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 15, 11, '2026-01-23 10:22:30', NULL, NULL),
(205, 'Razer Firefly V2', 'RGB hard mouse pad', '{\"rgb\": \"Razer Chroma RGB\", \"meret\": \"Medium (355 x 255 mm)\", \"tipus\": \"Kemeny (hard) RGB egerpad\", \"gyarto\": \"Razer\", \"felszin\": \"Kemeny mikrotexturas felszin\", \"sorozat\": \"Firefly V2\", \"vastagsag\": \"3 mm\", \"megjegyzes\": \"RGB gaming egerpad kemeny felszinnel\", \"csatlakozas\": \"USB (RGB-hez)\"}', '22900.00', '19900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 15, 11, '2026-01-23 10:22:30', NULL, NULL),
(206, 'Corsair MM300', 'Extended cloth mouse pad', '{\"meret\": \"Extended (930 x 300 mm)\", \"tipus\": \"Textil egerpad\", \"gyarto\": \"Corsair\", \"felszin\": \"Textil (low-friction)\", \"sorozat\": \"MM300\", \"also_resz\": \"Csuszasmentes gumi\", \"vastagsag\": \"3 mm\", \"megjegyzes\": \"Extended textil egerpad\"}', '12900.00', '10900.00', 60, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 15, 7, '2026-01-23 10:22:30', NULL, NULL),
(207, 'Corsair MM700 RGB', 'RGB extended mouse pad', '{\"rgb\": \"RGB vilagitas (3 zona)\", \"meret\": \"Extended (930 x 400 mm)\", \"tipus\": \"Kemeny (hard) RGB egerpad\", \"gyarto\": \"Corsair\", \"felszin\": \"Kemeny polimer felszin\", \"sorozat\": \"MM700\", \"also_resz\": \"Csuszasmentes\", \"vastagsag\": \"4 mm\", \"megjegyzes\": \"Extended RGB egerpad kemeny felszinnel\", \"csatlakozas\": \"USB (RGB-hez)\"}', '27900.00', '24900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 15, 7, '2026-01-23 10:22:30', NULL, NULL),
(208, 'MSI Agility GD70', 'Extended gaming mouse pad', '{\"meret\": \"Extended (900 x 400 mm)\", \"tipus\": \"Textil egerpad\", \"gyarto\": \"MSI\", \"felszin\": \"Textil gaming felszin\", \"sorozat\": \"Agility GD70\", \"also_resz\": \"Csuszasmentes gumi\", \"vastagsag\": \"3 mm\", \"megjegyzes\": \"Extended gaming egerpad\"}', '17900.00', '14900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 15, 5, '2026-01-23 10:22:30', NULL, NULL),
(209, 'MSI Agility GD30', 'Medium gaming mouse pad', '{\"meret\": \"Medium (320 x 270 mm)\", \"tipus\": \"Textil egerpad\", \"gyarto\": \"MSI\", \"felszin\": \"Textil gaming felszin\", \"sorozat\": \"Agility GD30\", \"also_resz\": \"Csuszasmentes gumi\", \"vastagsag\": \"3 mm\", \"megjegyzes\": \"Kozepes meretu gaming egerpad\"}', '8900.00', '7500.00', 75, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 15, 5, '2026-01-23 10:22:30', NULL, NULL),
(210, 'ASUS ROG Sheath', 'XL gaming mouse pad', '{\"meret\": \"XL (900 x 440 mm)\", \"tipus\": \"Textil egerpad\", \"gyarto\": \"ASUS\", \"felszin\": \"Finom szoves textil\", \"sorozat\": \"ROG Sheath\", \"also_resz\": \"Csuszasmentes gumi\", \"vastagsag\": \"3 mm\", \"megjegyzes\": \"ROG XL gaming egerpad\"}', '18900.00', '15900.00', 38, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 15, 4, '2026-01-23 10:22:30', NULL, NULL),
(211, 'ASUS TUF Gaming P3', 'Water-resistant mouse pad', '{\"meret\": \"Large (450 x 400 mm)\", \"tipus\": \"Textil egerpad\", \"gyarto\": \"ASUS\", \"felszin\": \"Vizallo textil felszin\", \"sorozat\": \"TUF Gaming P3\", \"vizallo\": \"Igen\", \"also_resz\": \"Csuszasmentes gumi\", \"vastagsag\": \"3 mm\", \"megjegyzes\": \"Vizallo gaming egerpad\"}', '11900.00', '9900.00', 55, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 15, 4, '2026-01-23 10:22:30', NULL, NULL),
(212, 'NZXT Mouse Pad XL', 'Extended minimal mouse pad', '{\"meret\": \"XL (900 x 400 mm)\", \"tipus\": \"Textil egerpad\", \"gyarto\": \"NZXT\", \"felszin\": \"Textil\", \"also_resz\": \"Csuszasmentes gumi\", \"vastagsag\": \"4 mm\", \"megjegyzes\": \"Minimalista XL egerpad\"}', '14900.00', '12900.00', 42, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 15, 16, '2026-01-23 10:22:30', NULL, NULL),
(215, 'Logitech Blue Yeti X', 'USB condenser microphone with LED meter', '{\"tipus\": \"USB kondenzator mikrofon\", \"gyarto\": \"Logitech (Blue)\", \"max_spl\": \"120 dB\", \"sorozat\": \"Yeti X\", \"szoftver\": \"Blue VO!CE\", \"led_meter\": \"11 szegmensu LED szintmero\", \"megjegyzes\": \"Professzionalis streaming mikrofon LED merovel\", \"monitoring\": \"3.5mm fejhallgato kimenet\", \"csatlakozas\": \"USB-C\", \"polar_mintak\": \"4 mod (cardioid, omni, bidirectional, stereo)\", \"mintaveteli_rata\": \"24-bit/48kHz\", \"frekvencia_valasz\": \"20Hz - 20kHz\"}', '64900.00', '59900.00', 25, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 16, 10, '2026-01-23 10:31:52', NULL, NULL),
(216, 'Logitech Blue Snowball iCE', 'USB desktop microphone', '{\"tipus\": \"USB kondenzator mikrofon\", \"gyarto\": \"Logitech (Blue)\", \"sorozat\": \"Snowball iCE\", \"megjegyzes\": \"Belepo szintu USB mikrofon\", \"csatlakozas\": \"USB\", \"polar_mintak\": \"Cardioid\", \"mintaveteli_rata\": \"16-bit/44.1kHz\", \"frekvencia_valasz\": \"40Hz - 18kHz\"}', '19900.00', '17900.00', 50, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 16, 10, '2026-01-23 10:31:52', NULL, NULL),
(217, 'Razer Seiren Mini', 'Compact USB condenser microphone', '{\"meret\": \"Kompakt design\", \"tipus\": \"USB kondenzator mikrofon\", \"gyarto\": \"Razer\", \"sorozat\": \"Seiren Mini\", \"megjegyzes\": \"Kis meretu streaming mikrofon\", \"csatlakozas\": \"USB\", \"polar_mintak\": \"Super-cardioid\", \"mintaveteli_rata\": \"16-bit/48kHz\", \"frekvencia_valasz\": \"20Hz - 20kHz\"}', '19900.00', '17900.00', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 16, 11, '2026-01-23 10:31:52', NULL, NULL);
INSERT INTO `products` (`id`, `name`, `description`, `properties`, `price`, `p_price`, `stock`, `image_url`, `category_id`, `brand_id`, `created_at`, `is_deleted`, `deleted_at`) VALUES
(218, 'Razer Seiren X', 'USB streaming microphone', '{\"tipus\": \"USB kondenzator mikrofon\", \"gyarto\": \"Razer\", \"sorozat\": \"Seiren X\", \"megjegyzes\": \"Streaming mikrofon shock mount-tal\", \"monitoring\": \"3.5mm fejhallgato kimenet\", \"csatlakozas\": \"USB\", \"shock_mount\": \"Beepitett rezgescsokkentos\", \"polar_mintak\": \"Super-cardioid\", \"mintaveteli_rata\": \"16-bit/48kHz\", \"frekvencia_valasz\": \"20Hz - 20kHz\"}', '34900.00', '31900.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 16, 11, '2026-01-23 10:31:52', NULL, NULL),
(219, 'Razer Seiren V2 Pro', 'Professional USB dynamic microphone', '{\"tipus\": \"USB dinamikus mikrofon\", \"gyarto\": \"Razer\", \"sorozat\": \"Seiren V2 Pro\", \"megjegyzes\": \"Professzionalis dinamikus mikrofon\", \"monitoring\": \"3.5mm fejhallgato kimenet\", \"csatlakozas\": \"USB-C\", \"polar_mintak\": \"Cardioid\", \"high_pass_filter\": \"Igen\", \"mintaveteli_rata\": \"24-bit/48kHz\", \"frekvencia_valasz\": \"20Hz - 20kHz\"}', '64900.00', '59900.00', 20, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 16, 11, '2026-01-23 10:31:52', NULL, NULL),
(220, 'Samson Q2U', 'USB/XLR dynamic microphone', '{\"tipus\": \"USB/XLR dinamikus mikrofon\", \"gyarto\": \"Samsung\", \"sorozat\": \"Q2U\", \"megjegyzes\": \"Sokoldalú dual-mode mikrofon\", \"monitoring\": \"3.5mm fejhallgato kimenet\", \"csatlakozas\": \"USB es XLR (dual mode)\", \"polar_mintak\": \"Cardioid\", \"mintaveteli_rata\": \"16-bit/48kHz (USB)\", \"frekvencia_valasz\": \"50Hz - 15kHz\"}', '34900.00', '31900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 16, 8, '2026-01-23 10:31:52', NULL, NULL),
(221, 'Samson Meteor Mic', 'USB studio microphone', '{\"tipus\": \"USB kondenzator mikrofon\", \"gyarto\": \"Samson\", \"sorozat\": \"Meteor\", \"megjegyzes\": \"Studio minosequ USB mikrofon\", \"monitoring\": \"3.5mm fejhallgato kimenet\", \"csatlakozas\": \"USB\", \"polar_mintak\": \"Cardioid\", \"mintaveteli_rata\": \"16-bit/48kHz\", \"frekvencia_valasz\": \"20Hz - 20kHz\"}', '24900.00', '21900.00', 40, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 16, 8, '2026-01-23 10:31:52', NULL, NULL),
(222, 'ASUS ROG Carnyx', 'USB gaming microphone', '{\"rgb\": \"Aura Sync RGB\", \"tipus\": \"USB kondenzator mikrofon\", \"ai_mic\": \"AI zajszures\", \"gyarto\": \"ASUS\", \"sorozat\": \"ROG Carnyx\", \"megjegyzes\": \"Gaming mikrofon AI zajszuressel es RGB-vel\", \"monitoring\": \"3.5mm fejhallgato kimenet\", \"csatlakozas\": \"USB-C\", \"polar_mintak\": \"Cardioid\", \"mintaveteli_rata\": \"24-bit/96kHz\", \"frekvencia_valasz\": \"20Hz - 20kHz\"}', '69900.00', '64900.00', 18, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 16, 4, '2026-01-23 10:31:52', NULL, NULL),
(223, 'ASUS TUF Gaming H1 Gen II FEJHALLGATÓ', 'USB condenser gaming microphone', '{\"tipus\": \"USB kondenzator mikrofon\", \"gyarto\": \"ASUS\", \"sorozat\": \"TUF Gaming\", \"megjegyzes\": \"TUF gaming mikrofon\", \"csatlakozas\": \"USB\", \"polar_mintak\": \"Cardioid\", \"mintaveteli_rata\": \"16-bit/48kHz\"}', '32900.00', '29900.00', 28, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 16, 4, '2026-01-23 10:31:52', 1, '2026-03-02 20:21:21'),
(224, 'MSI Immerse GV60', 'RGB USB streaming microphone', '{\"rgb\": \"RGB vilagitas\", \"tipus\": \"USB kondenzator mikrofon\", \"gyarto\": \"MSI\", \"sorozat\": \"Immerse GV60\", \"megjegyzes\": \"RGB streaming mikrofon\", \"monitoring\": \"3.5mm fejhallgato kimenet\", \"csatlakozas\": \"USB\", \"polar_mintak\": \"Cardioid\", \"mintaveteli_rata\": \"24-bit/96kHz\", \"frekvencia_valasz\": \"20Hz - 20kHz\"}', '34900.00', '31900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 16, 5, '2026-01-23 10:31:52', NULL, NULL),
(225, 'MSI Immerse GH30', 'USB condenser microphone', '{\"tipus\": \"USB kondenzator mikrofon\", \"gyarto\": \"MSI\", \"sorozat\": \"Immerse GH30\", \"megjegyzes\": \"Alapveto streaming mikrofon\", \"csatlakozas\": \"USB\", \"polar_mintak\": \"Cardioid\", \"mintaveteli_rata\": \"16-bit/48kHz\"}', '24900.00', '21900.00', 42, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 16, 5, '2026-01-23 10:31:52', NULL, NULL),
(226, 'Intel Core i9-14900K', '24 magos, 14. generációs Intel CPU', '{\"pcie\": \"PCIe 5.0 (16 lane) + PCIe 4.0 (4 lane)\", \"gyarto\": \"Intel\", \"sorozat\": \"Core i9\", \"tdp_max\": \"253 W (PL2)\", \"cache_l2\": \"32 MB\", \"cache_l3\": \"36 MB Intel Smart Cache\", \"foglalat\": \"LGA 1700\", \"tdp_alap\": \"125 W (PL1)\", \"generacio\": \"14. generáció (Raptor Lake Refresh)\", \"megjegyzes\": \"Csúcskategóriás gaming és munkaállomás CPU\", \"magok_szama\": \"24 (8 P-core + 16 E-core)\", \"max_memoria\": \"192 GB (dual-channel)\", \"szalak_szama\": \"32\", \"integralt_gpu\": \"Intel UHD Graphics 770\", \"feloldott_szorzo\": \"Igen\", \"e_core_max_orajel\": \"4.4 GHz\", \"p_core_max_orajel\": \"6.0 GHz (Thermal Velocity Boost)\", \"e_core_alap_orajel\": \"2.4 GHz\", \"p_core_alap_orajel\": \"3.2 GHz\", \"tamogatott_memoria\": \"DDR5-5600, DDR4-3200\", \"gyartasi_technologia\": \"Intel 7\"}', '589999.00', '549999.00', 23, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 1, '2026-01-30 09:40:16', NULL, NULL),
(227, 'Intel Core i7-14700K', '20 magos, 14. generációs Intel CPU', '{\"pcie\": \"PCIe 5.0 (16 lane) + PCIe 4.0 (4 lane)\", \"gyarto\": \"Intel\", \"sorozat\": \"Core i7\", \"tdp_max\": \"253 W (PL2)\", \"cache_l2\": \"28 MB\", \"cache_l3\": \"33 MB Intel Smart Cache\", \"foglalat\": \"LGA 1700\", \"tdp_alap\": \"125 W (PL1)\", \"generacio\": \"14. generáció (Raptor Lake Refresh)\", \"megjegyzes\": \"Kiváló gaming és tartalomkészítés\", \"magok_szama\": \"20 (8 P-core + 12 E-core)\", \"max_memoria\": \"192 GB (dual-channel)\", \"szalak_szama\": \"28\", \"integralt_gpu\": \"Intel UHD Graphics 770\", \"feloldott_szorzo\": \"Igen\", \"e_core_max_orajel\": \"4.3 GHz\", \"p_core_max_orajel\": \"5.6 GHz (Turbo Boost Max 3.0)\", \"e_core_alap_orajel\": \"2.5 GHz\", \"p_core_alap_orajel\": \"3.4 GHz\", \"tamogatott_memoria\": \"DDR5-5600, DDR4-3200\", \"gyartasi_technologia\": \"Intel 7\"}', '459999.00', '429999.00', 35, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 1, '2026-01-30 09:40:16', NULL, NULL),
(228, 'Intel Core i5-14600K', '14 magos, 14. generációs Intel CPU', '{\"pcie\": \"PCIe 5.0 (16 lane) + PCIe 4.0 (4 lane)\", \"gyarto\": \"Intel\", \"sorozat\": \"Core i5\", \"tdp_max\": \"181 W (PL2)\", \"cache_l2\": \"20 MB\", \"cache_l3\": \"24 MB Intel Smart Cache\", \"foglalat\": \"LGA 1700\", \"tdp_alap\": \"125 W (PL1)\", \"generacio\": \"14. generáció (Raptor Lake Refresh)\", \"megjegyzes\": \"Erős középkategóriás gaming CPU\", \"magok_szama\": \"14 (6 P-core + 8 E-core)\", \"max_memoria\": \"192 GB (dual-channel)\", \"szalak_szama\": \"20\", \"integralt_gpu\": \"Intel UHD Graphics 770\", \"feloldott_szorzo\": \"Igen\", \"e_core_max_orajel\": \"4.0 GHz\", \"p_core_max_orajel\": \"5.3 GHz (Turbo Boost Max 3.0)\", \"e_core_alap_orajel\": \"2.6 GHz\", \"p_core_alap_orajel\": \"3.5 GHz\", \"tamogatott_memoria\": \"DDR5-5600, DDR4-3200\", \"gyartasi_technologia\": \"Intel 7\"}', '319999.00', '299999.00', 42, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 1, '2026-01-30 09:40:16', NULL, NULL),
(229, 'Intel Core i9-13900K', '24 magos, 13. generációs Intel CPU', '{\"pcie\": \"PCIe 5.0 (16 lane) + PCIe 4.0 (4 lane)\", \"gyarto\": \"Intel\", \"sorozat\": \"Core i9\", \"tdp_max\": \"253 W (PL2)\", \"cache_l2\": \"32 MB\", \"cache_l3\": \"36 MB Intel Smart Cache\", \"foglalat\": \"LGA 1700\", \"tdp_alap\": \"125 W (PL1)\", \"generacio\": \"13. generáció (Raptor Lake)\", \"megjegyzes\": \"13. gen zászlóshajó CPU\", \"magok_szama\": \"24 (8 P-core + 16 E-core)\", \"max_memoria\": \"128 GB (dual-channel)\", \"szalak_szama\": \"32\", \"integralt_gpu\": \"Intel UHD Graphics 770\", \"feloldott_szorzo\": \"Igen\", \"e_core_max_orajel\": \"4.3 GHz\", \"p_core_max_orajel\": \"5.8 GHz (Turbo Boost Max 3.0)\", \"e_core_alap_orajel\": \"2.2 GHz\", \"p_core_alap_orajel\": \"3.0 GHz\", \"tamogatott_memoria\": \"DDR5-5600, DDR4-3200\", \"gyartasi_technologia\": \"Intel 7\"}', '529999.00', '489999.00', 18, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 1, '2026-01-30 09:40:16', NULL, NULL),
(230, 'Intel Core i5-13600K', '14 magos, 13. generációs Intel CPU', '{\"pcie\": \"PCIe 5.0 (16 lane) + PCIe 4.0 (4 lane)\", \"gyarto\": \"Intel\", \"sorozat\": \"Core i5\", \"tdp_max\": \"181 W (PL2)\", \"cache_l2\": \"20 MB\", \"cache_l3\": \"24 MB Intel Smart Cache\", \"foglalat\": \"LGA 1700\", \"tdp_alap\": \"125 W (PL1)\", \"generacio\": \"13. generáció (Raptor Lake)\", \"megjegyzes\": \"Népszerű ár/érték gaming CPU\", \"magok_szama\": \"14 (6 P-core + 8 E-core)\", \"max_memoria\": \"128 GB (dual-channel)\", \"szalak_szama\": \"20\", \"integralt_gpu\": \"Intel UHD Graphics 770\", \"feloldott_szorzo\": \"Igen\", \"e_core_max_orajel\": \"3.9 GHz\", \"p_core_max_orajel\": \"5.1 GHz (Turbo Boost Max 3.0)\", \"e_core_alap_orajel\": \"2.6 GHz\", \"p_core_alap_orajel\": \"3.5 GHz\", \"tamogatott_memoria\": \"DDR5-5600, DDR4-3200\", \"gyartasi_technologia\": \"Intel 7\"}', '289999.00', '269999.00', 51, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 1, '2026-01-30 09:40:16', NULL, NULL),
(231, 'Intel Core i3-14100', '4 magos, 14. generációs Intel CPU', '{\"pcie\": \"PCIe 5.0 (16 lane) + PCIe 4.0 (4 lane)\", \"gyarto\": \"Intel\", \"sorozat\": \"Core i3\", \"tdp_max\": \"110 W\", \"cache_l2\": \"5 MB\", \"cache_l3\": \"12 MB Intel Smart Cache\", \"foglalat\": \"LGA 1700\", \"tdp_alap\": \"60 W\", \"generacio\": \"14. generáció (Raptor Lake Refresh)\", \"max_orajel\": \"4.7 GHz (Turbo Boost)\", \"megjegyzes\": \"Belépő szintű desktop CPU\", \"alap_orajel\": \"3.5 GHz\", \"magok_szama\": \"4 (4 P-core)\", \"max_memoria\": \"192 GB (dual-channel)\", \"szalak_szama\": \"8\", \"integralt_gpu\": \"Intel UHD Graphics 730\", \"feloldott_szorzo\": \"Nem\", \"tamogatott_memoria\": \"DDR5-4800, DDR4-3200\", \"gyartasi_technologia\": \"Intel 7\"}', '149999.00', '139999.00', 67, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 1, '2026-01-30 09:40:16', NULL, NULL),
(232, 'AMD Ryzen 9 7950X', '16 magos, Zen 4 architektúra', '{\"tdp\": \"170 W\", \"pcie\": \"PCIe 5.0 (28 lane)\", \"gyarto\": \"AMD\", \"sorozat\": \"Ryzen 9\", \"cache_l2\": \"16 MB\", \"cache_l3\": \"64 MB\", \"foglalat\": \"AM5\", \"generacio\": \"7000 sorozat (Zen 4)\", \"max_orajel\": \"5.7 GHz (Precision Boost)\", \"megjegyzes\": \"Zen 4 zászlóshajó, 16 mag, PCIe 5.0\", \"alap_orajel\": \"4.5 GHz\", \"magok_szama\": \"16\", \"max_memoria\": \"128 GB (dual-channel)\", \"szalak_szama\": \"32\", \"integralt_gpu\": \"AMD Radeon Graphics (RDNA 2)\", \"feloldott_szorzo\": \"Igen\", \"tamogatott_memoria\": \"DDR5-5200\", \"gyartasi_technologia\": \"TSMC 5nm\"}', '599999.00', '569999.00', 15, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 2, '2026-01-30 09:40:16', NULL, NULL),
(233, 'AMD Ryzen 9 7900X', '12 magos, Zen 4 architektúra', '{\"tdp\": \"170 W\", \"pcie\": \"PCIe 5.0 (28 lane)\", \"gyarto\": \"AMD\", \"sorozat\": \"Ryzen 9\", \"cache_l2\": \"12 MB\", \"cache_l3\": \"64 MB\", \"foglalat\": \"AM5\", \"generacio\": \"7000 sorozat (Zen 4)\", \"max_orajel\": \"5.4 GHz (Precision Boost)\", \"megjegyzes\": \"12 magos Zen 4, kiváló teljesítmény\", \"alap_orajel\": \"4.7 GHz\", \"magok_szama\": \"12\", \"max_memoria\": \"128 GB (dual-channel)\", \"szalak_szama\": \"24\", \"integralt_gpu\": \"AMD Radeon Graphics (RDNA 2)\", \"feloldott_szorzo\": \"Igen\", \"tamogatott_memoria\": \"DDR5-5200\", \"gyartasi_technologia\": \"TSMC 5nm\"}', '479999.00', '449999.00', 28, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 2, '2026-01-30 09:40:16', NULL, NULL),
(234, 'AMD Ryzen 7 7800X3D', '8 magos, 3D V-Cache technológia', '{\"tdp\": \"120 W\", \"pcie\": \"PCIe 5.0 (28 lane)\", \"gyarto\": \"AMD\", \"sorozat\": \"Ryzen 7\", \"cache_l2\": \"8 MB\", \"cache_l3\": \"96 MB (3D V-Cache)\", \"foglalat\": \"AM5\", \"generacio\": \"7000 sorozat (Zen 4)\", \"max_orajel\": \"5.0 GHz (Precision Boost)\", \"megjegyzes\": \"3D V-Cache technológia, gaming bajnok\", \"alap_orajel\": \"4.2 GHz\", \"magok_szama\": \"8\", \"max_memoria\": \"128 GB (dual-channel)\", \"szalak_szama\": \"16\", \"integralt_gpu\": \"AMD Radeon Graphics (RDNA 2)\", \"feloldott_szorzo\": \"Nem\", \"tamogatott_memoria\": \"DDR5-5200\", \"gyartasi_technologia\": \"TSMC 5nm + 7nm (3D V-Cache)\"}', '449999.00', '419999.00', 31, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 2, '2026-01-30 09:40:16', NULL, NULL),
(235, 'AMD Ryzen 7 7700X', '8 magos, Zen 4 architektúra', '{\"tdp\": \"105 W\", \"pcie\": \"PCIe 5.0 (28 lane)\", \"gyarto\": \"AMD\", \"sorozat\": \"Ryzen 7\", \"cache_l2\": \"8 MB\", \"cache_l3\": \"32 MB\", \"foglalat\": \"AM5\", \"generacio\": \"7000 sorozat (Zen 4)\", \"max_orajel\": \"5.4 GHz (Precision Boost)\", \"megjegyzes\": \"8 magos Zen 4, gaming és munkához\", \"alap_orajel\": \"4.5 GHz\", \"magok_szama\": \"8\", \"max_memoria\": \"128 GB (dual-channel)\", \"szalak_szama\": \"16\", \"integralt_gpu\": \"AMD Radeon Graphics (RDNA 2)\", \"feloldott_szorzo\": \"Igen\", \"tamogatott_memoria\": \"DDR5-5200\", \"gyartasi_technologia\": \"TSMC 5nm\"}', '349999.00', '329999.00', 44, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 2, '2026-01-30 09:40:16', NULL, NULL),
(236, 'AMD Ryzen 5 7600X', '6 magos, Zen 4 architektúra', '{\"tdp\": \"105 W\", \"pcie\": \"PCIe 5.0 (28 lane)\", \"gyarto\": \"AMD\", \"sorozat\": \"Ryzen 5\", \"cache_l2\": \"6 MB\", \"cache_l3\": \"32 MB\", \"foglalat\": \"AM5\", \"generacio\": \"7000 sorozat (Zen 4)\", \"max_orajel\": \"5.3 GHz (Precision Boost)\", \"megjegyzes\": \"6 magos Zen 4, erős középkategória\", \"alap_orajel\": \"4.7 GHz\", \"magok_szama\": \"6\", \"max_memoria\": \"128 GB (dual-channel)\", \"szalak_szama\": \"12\", \"integralt_gpu\": \"AMD Radeon Graphics (RDNA 2)\", \"feloldott_szorzo\": \"Igen\", \"tamogatott_memoria\": \"DDR5-5200\", \"gyartasi_technologia\": \"TSMC 5nm\"}', '269999.00', '249999.00', 58, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 2, '2026-01-30 09:40:16', NULL, NULL),
(237, 'AMD Ryzen 5 5600X', '6 magos, Zen 3 architektúra', '{\"tdp\": \"65 W\", \"pcie\": \"PCIe 4.0 (20 lane)\", \"gyarto\": \"AMD\", \"sorozat\": \"Ryzen 5\", \"cache_l2\": \"3 MB\", \"cache_l3\": \"32 MB\", \"foglalat\": \"AM4\", \"generacio\": \"5000 sorozat (Zen 3)\", \"max_orajel\": \"4.6 GHz (Precision Boost)\", \"megjegyzes\": \"Népszerű gaming CPU, kiváló ár/érték\", \"alap_orajel\": \"3.7 GHz\", \"magok_szama\": \"6\", \"max_memoria\": \"128 GB (dual-channel)\", \"szalak_szama\": \"12\", \"integralt_gpu\": \"Nincs\", \"feloldott_szorzo\": \"Igen\", \"tamogatott_memoria\": \"DDR4-3200\", \"gyartasi_technologia\": \"TSMC 7nm\"}', '189999.00', '169999.00', 73, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 2, 2, '2026-01-30 09:40:16', NULL, NULL),
(238, 'AMD Radeon RX 7900 XTX', '24GB GDDR6 videókártya, RDNA 3 architektúra', '{\"DVI\": \"Nem\", \"HDMI\": \"1db\", \"Hossz\": \"213mm\", \"Súly\": \"1650g\", \"Hangtalan\": \"Nem\", \"VGA/D-SUB\": \"Nem\", \"DisplayPort\": \"2db\", \"Helyfoglalás\": \"2\", \"Tápellátás\": \"3 x 8 tűs\", \"Videó chipset\": \"GeForce RTX 3050\", \"Memória mérete\": \"24GB\", \"Memória típusa\": \"GDDR6\", \"Mini DisplayPort\": \"0db\", \"Chipset gyártója\": \"AMD\", \"Ajánlott min. táp.\": \"355watt\"}', '899999.00', '849999.00', 12, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 1, 2, '2026-01-30 09:41:58', NULL, NULL),
(239, 'ASUS ROG Strix Z790-E Gaming WiFi', 'Intel Z790 chipset, DDR5, ATX alaplap', '{\"rgb\": \"Aura Sync RGB\", \"audio\": \"SupremeFX 7.1 (ALC4080)\", \"gyarto\": \"ASUS\", \"chipset\": \"Intel Z790\", \"halozat\": \"2.5G LAN (Intel I225-V), WiFi 6E\", \"sorozat\": \"ROG Strix\", \"foglalat\": \"LGA 1700\", \"m2_slotok\": \"5x M.2 (4x PCIe 5.0, 1x PCIe 4.0)\", \"megjegyzes\": \"Flagship Z790 gaming alaplap, PCIe 5.0 M.2\", \"max_memoria\": \"192 GB\", \"pcie_slotok\": \"1x PCIe 5.0 x16, 1x PCIe 4.0 x16\", \"sata_portok\": \"4x SATA III\", \"forma_faktor\": \"ATX\", \"memoria_tipus\": \"DDR5\", \"memoria_slotok\": \"4 x DIMM\", \"tamogatott_cpu\": \"Intel 12., 13. es 14. gen (Alder Lake, Raptor Lake, Raptor Lake Refresh)\", \"memoria_sebesseg\": \"DDR5-7800+ (OC)\"}', '229900.00', '209900.00', 18, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 3, 4, '2026-02-02 09:10:37', 1, '2026-03-03 07:50:42'),
(240, 'ASUS TUF Gaming B650-PLUS WiFi', 'AMD B650 chipset, DDR5, ATX alaplap', '{\"rgb\": \"Aura Sync\", \"audio\": \"TUF Gaming Audio\", \"gyarto\": \"ASUS\", \"chipset\": \"AMD B650\", \"halozat\": \"2.5G LAN, WiFi 6\", \"sorozat\": \"TUF Gaming\", \"foglalat\": \"AM5\", \"m2_slotok\": \"3x M.2 (2x PCIe 4.0, 1x PCIe 3.0)\", \"megjegyzes\": \"TUF strapabiro B650 alaplap\", \"max_memoria\": \"128 GB\", \"pcie_slotok\": \"1x PCIe 5.0 x16, 1x PCIe 4.0 x16\", \"sata_portok\": \"4x SATA III\", \"forma_faktor\": \"ATX\", \"memoria_tipus\": \"DDR5\", \"memoria_slotok\": \"4 x DIMM\", \"tamogatott_cpu\": \"AMD Ryzen 7000 sorozat (Zen 4)\", \"memoria_sebesseg\": \"DDR5-6400+ (OC)\"}', '109900.00', '99900.00', 32, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 3, 4, '2026-02-02 09:10:37', NULL, NULL),
(241, 'ASUS Prime B760M-A WiFi D4', 'Intel B760 chipset, DDR4, microATX alaplap', '{\"audio\": \"Realtek ALC897\", \"gyarto\": \"ASUS\", \"chipset\": \"Intel B760\", \"halozat\": \"1G LAN, WiFi 6\", \"sorozat\": \"Prime\", \"foglalat\": \"LGA 1700\", \"m2_slotok\": \"2x M.2 (PCIe 4.0)\", \"megjegyzes\": \"Koltseghatekony microATX DDR4 alaplap\", \"max_memoria\": \"128 GB\", \"pcie_slotok\": \"1x PCIe 4.0 x16\", \"sata_portok\": \"4x SATA III\", \"forma_faktor\": \"microATX\", \"memoria_tipus\": \"DDR4\", \"memoria_slotok\": \"4 x DIMM\", \"tamogatott_cpu\": \"Intel 12., 13. es 14. gen\", \"memoria_sebesseg\": \"DDR4-5333+ (OC)\"}', '64900.00', '59900.00', 45, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 3, 4, '2026-02-02 09:10:37', NULL, NULL),
(242, 'ASUS ROG Strix B550-F Gaming WiFi II', 'AMD B550 chipset, DDR4, ATX alaplap', '{\"rgb\": \"Aura Sync\", \"audio\": \"SupremeFX S1220A\", \"gyarto\": \"ASUS\", \"chipset\": \"AMD B550\", \"halozat\": \"2.5G LAN, WiFi 6\", \"sorozat\": \"ROG Strix\", \"foglalat\": \"AM4\", \"m2_slotok\": \"2x M.2 (1x PCIe 4.0, 1x PCIe 3.0)\", \"megjegyzes\": \"ROG gaming AM4 alaplap\", \"max_memoria\": \"128 GB\", \"pcie_slotok\": \"1x PCIe 4.0 x16, 1x PCIe 3.0 x16\", \"sata_portok\": \"6x SATA III\", \"forma_faktor\": \"ATX\", \"memoria_tipus\": \"DDR4\", \"memoria_slotok\": \"4 x DIMM\", \"tamogatott_cpu\": \"AMD Ryzen 5000, 4000, 3000 sorozat\", \"memoria_sebesseg\": \"DDR4-5100+ (OC)\"}', '79900.00', '74900.00', 28, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 3, 4, '2026-02-02 09:10:37', NULL, NULL),
(243, 'MSI MPG Z790 Carbon WiFi', 'Intel Z790 chipset, DDR5, ATX alaplap', '{\"rgb\": \"Mystic Light RGB\", \"audio\": \"Realtek ALC4080\", \"gyarto\": \"MSI\", \"chipset\": \"Intel Z790\", \"halozat\": \"2.5G LAN, WiFi 6E\", \"sorozat\": \"MPG\", \"foglalat\": \"LGA 1700\", \"m2_slotok\": \"5x M.2 (4x PCIe 4.0, 1x PCIe 3.0)\", \"megjegyzes\": \"Premium Z790 Carbon gaming alaplap\", \"max_memoria\": \"192 GB\", \"pcie_slotok\": \"1x PCIe 5.0 x16, 1x PCIe 4.0 x16\", \"sata_portok\": \"6x SATA III\", \"forma_faktor\": \"ATX\", \"memoria_tipus\": \"DDR5\", \"memoria_slotok\": \"4 x DIMM\", \"tamogatott_cpu\": \"Intel 12., 13. es 14. gen\", \"memoria_sebesseg\": \"DDR5-7800+ (OC)\"}', '219900.00', '199900.00', 22, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 3, 5, '2026-02-02 09:10:37', NULL, NULL),
(244, 'MSI MAG B650 Tomahawk WiFi', 'AMD B650 chipset, DDR5, ATX alaplap', '{\"rgb\": \"Mystic Light\", \"audio\": \"Realtek ALC4080\", \"gyarto\": \"MSI\", \"chipset\": \"AMD B650\", \"halozat\": \"2.5G LAN, WiFi 6E\", \"sorozat\": \"MAG\", \"foglalat\": \"AM5\", \"m2_slotok\": \"4x M.2 (2x PCIe 4.0, 2x PCIe 3.0)\", \"megjegyzes\": \"MAG Tomahawk gaming AM5 alaplap\", \"max_memoria\": \"128 GB\", \"pcie_slotok\": \"1x PCIe 5.0 x16, 1x PCIe 4.0 x16\", \"sata_portok\": \"4x SATA III\", \"forma_faktor\": \"ATX\", \"memoria_tipus\": \"DDR5\", \"memoria_slotok\": \"4 x DIMM\", \"tamogatott_cpu\": \"AMD Ryzen 7000 sorozat (Zen 4)\", \"memoria_sebesseg\": \"DDR5-6400+ (OC)\"}', '114900.00', '104900.00', 26, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 3, 5, '2026-02-02 09:10:37', NULL, NULL),
(245, 'MSI PRO B760M-A WiFi DDR4', 'Intel B760 chipset, DDR4, microATX alaplap', '{\"audio\": \"Realtek ALC897\", \"gyarto\": \"MSI\", \"chipset\": \"Intel B760\", \"halozat\": \"1G LAN, WiFi 6\", \"sorozat\": \"PRO\", \"foglalat\": \"LGA 1700\", \"m2_slotok\": \"2x M.2 (PCIe 4.0)\", \"megjegyzes\": \"Uzleti/belepo microATX DDR4\", \"max_memoria\": \"128 GB\", \"pcie_slotok\": \"1x PCIe 4.0 x16\", \"sata_portok\": \"4x SATA III\", \"forma_faktor\": \"microATX\", \"memoria_tipus\": \"DDR4\", \"memoria_slotok\": \"4 x DIMM\", \"tamogatott_cpu\": \"Intel 12., 13. es 14. gen\", \"memoria_sebesseg\": \"DDR4-5333+ (OC)\"}', '59900.00', '54900.00', 38, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 3, 5, '2026-02-02 09:10:37', NULL, NULL),
(246, 'Gigabyte Z790 AORUS Elite AX', 'Intel Z790 chipset, DDR5, ATX alaplap', '{\"rgb\": \"RGB Fusion\", \"audio\": \"Realtek ALC1220\", \"gyarto\": \"Gigabyte\", \"chipset\": \"Intel Z790\", \"halozat\": \"2.5G LAN, WiFi 6E\", \"sorozat\": \"AORUS\", \"foglalat\": \"LGA 1700\", \"m2_slotok\": \"4x M.2 (PCIe 4.0)\", \"megjegyzes\": \"AORUS Z790 gaming alaplap\", \"max_memoria\": \"192 GB\", \"pcie_slotok\": \"1x PCIe 5.0 x16, 1x PCIe 4.0 x16\", \"sata_portok\": \"4x SATA III\", \"forma_faktor\": \"ATX\", \"memoria_tipus\": \"DDR5\", \"memoria_slotok\": \"4 x DIMM\", \"tamogatott_cpu\": \"Intel 12., 13. es 14. gen\", \"memoria_sebesseg\": \"DDR5-7600+ (OC)\"}', '179900.00', '164900.00', 20, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 3, 6, '2026-02-02 09:10:37', NULL, NULL),
(247, 'Gigabyte B650 AORUS Elite AX', 'AMD B650 chipset, DDR5, ATX alaplap', '{\"rgb\": \"RGB Fusion\", \"audio\": \"Realtek ALC1220\", \"gyarto\": \"Gigabyte\", \"chipset\": \"AMD B650\", \"halozat\": \"2.5G LAN, WiFi 6E\", \"sorozat\": \"AORUS\", \"foglalat\": \"AM5\", \"m2_slotok\": \"3x M.2 (PCIe 4.0)\", \"megjegyzes\": \"AORUS B650 gaming AM5\", \"max_memoria\": \"128 GB\", \"pcie_slotok\": \"1x PCIe 5.0 x16, 1x PCIe 4.0 x16\", \"sata_portok\": \"4x SATA III\", \"forma_faktor\": \"ATX\", \"memoria_tipus\": \"DDR5\", \"memoria_slotok\": \"4 x DIMM\", \"tamogatott_cpu\": \"AMD Ryzen 7000 sorozat (Zen 4)\", \"memoria_sebesseg\": \"DDR5-6400+ (OC)\"}', '99900.00', '89900.00', 30, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 3, 6, '2026-02-02 09:10:37', NULL, NULL),
(248, 'Gigabyte B760M DS3H DDR4', 'Intel B760 chipset, DDR4, microATX alaplap', '{\"audio\": \"Realtek ALC897\", \"gyarto\": \"Gigabyte\", \"chipset\": \"Intel B760\", \"halozat\": \"1G LAN\", \"foglalat\": \"LGA 1700\", \"m2_slotok\": \"2x M.2 (PCIe 4.0)\", \"megjegyzes\": \"Budget microATX DDR4 alaplap\", \"max_memoria\": \"128 GB\", \"pcie_slotok\": \"1x PCIe 4.0 x16\", \"sata_portok\": \"4x SATA III\", \"forma_faktor\": \"microATX\", \"memoria_tipus\": \"DDR4\", \"memoria_slotok\": \"4 x DIMM\", \"tamogatott_cpu\": \"Intel 12., 13. es 14. gen\", \"memoria_sebesseg\": \"DDR4-5333+ (OC)\"}', '49900.00', '44900.00', 42, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 3, 6, '2026-02-02 09:10:37', NULL, NULL),
(249, 'Gigabyte X670 AORUS Elite AX', 'AMD X670 chipset, DDR5, ATX alaplap', '{\"rgb\": \"RGB Fusion\", \"audio\": \"Realtek ALC1220\", \"gyarto\": \"Gigabyte\", \"chipset\": \"AMD X670\", \"halozat\": \"2.5G LAN, WiFi 6E\", \"sorozat\": \"AORUS\", \"foglalat\": \"AM5\", \"m2_slotok\": \"4x M.2 (3x PCIe 5.0, 1x PCIe 4.0)\", \"megjegyzes\": \"High-end X670 AORUS alaplap, PCIe 5.0 M.2\", \"max_memoria\": \"128 GB\", \"pcie_slotok\": \"1x PCIe 5.0 x16, 1x PCIe 4.0 x16\", \"sata_portok\": \"4x SATA III\", \"forma_faktor\": \"ATX\", \"memoria_tipus\": \"DDR5\", \"memoria_slotok\": \"4 x DIMM\", \"tamogatott_cpu\": \"AMD Ryzen 7000 sorozat (Zen 4)\", \"memoria_sebesseg\": \"DDR5-6400+ (OC)\"}', '149900.00', '139900.00', 24, '/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp', 3, 6, '2026-02-02 09:10:37', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `product_attributes`
--

DROP TABLE IF EXISTS `product_attributes`;
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
(43, 46, 3, '12', '2026-02-02 08:59:13', NULL, NULL),
(44, 47, 3, '8', '2026-02-02 08:59:13', NULL, NULL),
(45, 48, 3, '12', '2026-02-02 08:59:13', NULL, NULL),
(46, 49, 3, '16', '2026-02-02 08:59:13', NULL, NULL),
(47, 50, 3, '8', '2026-02-02 08:59:13', NULL, NULL),
(48, 51, 3, '6', '2026-02-02 08:59:13', NULL, NULL),
(49, 52, 3, '12', '2026-02-02 08:59:13', NULL, NULL),
(50, 53, 3, '8', '2026-02-02 08:59:13', NULL, NULL),
(51, 54, 3, '12', '2026-02-02 08:59:13', NULL, NULL),
(52, 55, 3, '16', '2026-02-02 08:59:13', NULL, NULL),
(53, 56, 10, '27', '2026-02-02 08:59:13', NULL, NULL),
(54, 57, 10, '27', '2026-02-02 08:59:13', NULL, NULL),
(55, 58, 10, '27', '2026-02-02 08:59:13', NULL, NULL),
(56, 59, 10, '32', '2026-02-02 08:59:13', NULL, NULL),
(57, 60, 10, '27', '2026-02-02 08:59:13', NULL, NULL),
(58, 61, 10, '27', '2026-02-02 08:59:13', NULL, NULL),
(59, 62, 10, '28', '2026-02-02 08:59:13', NULL, NULL),
(60, 63, 10, '27', '2026-02-02 08:59:13', NULL, NULL),
(61, 64, 10, '27', '2026-02-02 08:59:13', NULL, NULL),
(62, 65, 10, '34', '2026-02-02 08:59:13', NULL, NULL),
(63, 66, 10, '27', '2026-02-02 08:59:13', NULL, NULL),
(64, 67, 10, '24', '2026-02-02 08:59:13', NULL, NULL),
(65, 94, 12, '25600', '2026-02-02 08:59:13', NULL, NULL),
(66, 95, 12, '25600', '2026-02-02 08:59:13', NULL, NULL),
(67, 96, 12, '8000', '2026-02-02 08:59:13', NULL, NULL),
(68, 97, 12, '12000', '2026-02-02 08:59:13', NULL, NULL),
(69, 98, 12, '30000', '2026-02-02 08:59:13', NULL, NULL),
(70, 99, 12, '30000', '2026-02-02 08:59:13', NULL, NULL),
(71, 100, 12, '26000', '2026-02-02 08:59:13', NULL, NULL),
(72, 101, 12, '18000', '2026-02-02 08:59:13', NULL, NULL),
(73, 102, 12, '3200', '2026-02-02 08:59:13', NULL, NULL),
(74, 103, 12, '1600', '2026-02-02 08:59:13', NULL, NULL),
(75, 104, 12, '1000', '2026-02-02 08:59:13', NULL, NULL),
(76, 105, 12, '16000', '2026-02-02 08:59:13', NULL, NULL),
(77, 106, 5, '3200', '2026-02-02 08:59:13', NULL, NULL),
(78, 107, 5, '3600', '2026-02-02 08:59:13', NULL, NULL),
(79, 108, 5, '5600', '2026-02-02 08:59:13', NULL, NULL),
(80, 109, 5, '3200', '2026-02-02 08:59:13', NULL, NULL),
(81, 110, 5, '4800', '2026-02-02 08:59:13', NULL, NULL),
(82, 111, 5, '5600', '2026-02-02 08:59:13', NULL, NULL),
(83, 112, 5, '3200', '2026-02-02 08:59:13', NULL, NULL),
(84, 113, 5, '3600', '2026-02-02 08:59:13', NULL, NULL),
(85, 114, 5, '2666', '2026-02-02 08:59:13', NULL, NULL),
(86, 115, 5, '2666', '2026-02-02 08:59:13', NULL, NULL),
(87, 116, 5, '6000', '2026-02-02 08:59:13', NULL, NULL),
(88, 117, 5, '6000', '2026-02-02 08:59:13', NULL, NULL),
(89, 118, 8, 'ATX', '2026-02-02 08:59:13', NULL, NULL),
(90, 119, 8, 'ATX', '2026-02-02 08:59:13', NULL, NULL),
(91, 120, 8, 'ATX', '2026-02-02 08:59:13', NULL, NULL),
(92, 121, 8, 'ATX', '2026-02-02 08:59:13', NULL, NULL),
(93, 122, 8, 'ATX', '2026-02-02 08:59:13', NULL, NULL),
(94, 123, 8, 'ATX', '2026-02-02 08:59:13', NULL, NULL),
(95, 124, 8, 'ATX', '2026-02-02 08:59:13', NULL, NULL),
(96, 125, 8, 'ATX', '2026-02-02 08:59:13', NULL, NULL),
(97, 126, 8, 'ATX', '2026-02-02 08:59:13', NULL, NULL),
(98, 127, 8, 'Full Tower', '2026-02-02 08:59:13', NULL, NULL),
(99, 128, 8, 'ATX', '2026-02-02 08:59:13', NULL, NULL),
(100, 129, 8, 'ATX', '2026-02-02 08:59:13', NULL, NULL),
(101, 130, 6, '1', '2026-02-02 08:59:13', NULL, NULL),
(102, 131, 6, '1', '2026-02-02 08:59:13', NULL, NULL),
(103, 132, 6, '2', '2026-02-02 08:59:13', NULL, NULL),
(104, 133, 6, '1', '2026-02-02 08:59:13', NULL, NULL),
(105, 134, 6, '1', '2026-02-02 08:59:13', NULL, NULL),
(106, 135, 6, '0.48', '2026-02-02 08:59:13', NULL, NULL),
(107, 136, 6, '1', '2026-02-02 08:59:13', NULL, NULL),
(108, 137, 6, '0.96', '2026-02-02 08:59:13', NULL, NULL),
(109, 138, 6, '1', '2026-02-02 08:59:13', NULL, NULL),
(110, 139, 6, '2', '2026-02-02 08:59:13', NULL, NULL),
(111, 140, 6, '1', '2026-02-02 08:59:13', NULL, NULL),
(112, 141, 6, '0.512', '2026-02-02 08:59:13', NULL, NULL),
(113, 142, 6, '1', '2026-02-02 08:59:13', NULL, NULL),
(114, 143, 6, '2', '2026-02-02 08:59:13', NULL, NULL),
(115, 144, 6, '4', '2026-02-02 08:59:13', NULL, NULL),
(116, 145, 6, '2', '2026-02-02 08:59:13', NULL, NULL),
(117, 146, 6, '4', '2026-02-02 08:59:13', NULL, NULL),
(118, 147, 6, '4', '2026-02-02 08:59:13', NULL, NULL),
(119, 148, 6, '6', '2026-02-02 08:59:13', NULL, NULL),
(120, 149, 6, '2', '2026-02-02 08:59:13', NULL, NULL),
(121, 150, 6, '4', '2026-02-02 08:59:13', NULL, NULL),
(122, 151, 6, '8', '2026-02-02 08:59:13', NULL, NULL),
(123, 152, 6, '2', '2026-02-02 08:59:13', NULL, NULL),
(124, 153, 6, '4', '2026-02-02 08:59:13', NULL, NULL),
(125, 154, 14, 'USB', '2026-02-02 08:59:13', NULL, NULL),
(126, 155, 14, 'Wireless', '2026-02-02 08:59:13', NULL, NULL),
(127, 156, 14, 'Wireless', '2026-02-02 08:59:13', NULL, NULL),
(128, 157, 14, 'Wireless', '2026-02-02 08:59:13', NULL, NULL),
(129, 158, 14, '3.5mm', '2026-02-02 08:59:13', NULL, NULL),
(130, 159, 14, 'Wireless', '2026-02-02 08:59:13', NULL, NULL),
(131, 160, 14, 'USB', '2026-02-02 08:59:13', NULL, NULL),
(132, 161, 14, 'Wireless', '2026-02-02 08:59:13', NULL, NULL),
(133, 162, 14, '3.5mm', '2026-02-02 08:59:13', NULL, NULL),
(134, 163, 14, '3.5mm', '2026-02-02 08:59:13', NULL, NULL),
(135, 164, 14, 'Bluetooth', '2026-02-02 08:59:13', NULL, NULL),
(136, 165, 14, 'USB', '2026-02-02 08:59:13', NULL, NULL),
(137, 166, 7, '750', '2026-02-02 08:59:13', NULL, NULL),
(138, 167, 7, '850', '2026-02-02 08:59:13', NULL, NULL),
(139, 168, 7, '650', '2026-02-02 08:59:13', NULL, NULL),
(140, 169, 7, '750', '2026-02-02 08:59:13', NULL, NULL),
(141, 170, 7, '650', '2026-02-02 08:59:13', NULL, NULL),
(142, 171, 7, '850', '2026-02-02 08:59:13', NULL, NULL),
(143, 172, 7, '750', '2026-02-02 08:59:13', NULL, NULL),
(144, 173, 7, '650', '2026-02-02 08:59:13', NULL, NULL),
(145, 174, 7, '850', '2026-02-02 08:59:13', NULL, NULL),
(146, 175, 7, '750', '2026-02-02 08:59:13', NULL, NULL),
(147, 176, 7, '1000', '2026-02-02 08:59:13', NULL, NULL),
(148, 177, 7, '1000', '2026-02-02 08:59:13', NULL, NULL),
(149, 178, 9, '140', '2026-02-02 08:59:13', NULL, NULL),
(150, 179, 9, '120', '2026-02-02 08:59:13', NULL, NULL),
(151, 180, 9, '92', '2026-02-02 08:59:13', NULL, NULL),
(152, 181, 9, '240', '2026-02-02 08:59:13', NULL, NULL),
(153, 182, 9, '360', '2026-02-02 08:59:13', NULL, NULL),
(154, 183, 9, '240', '2026-02-02 08:59:13', NULL, NULL),
(155, 184, 9, '360', '2026-02-02 08:59:13', NULL, NULL),
(156, 185, 9, '280', '2026-02-02 08:59:13', NULL, NULL),
(157, 186, 9, '360', '2026-02-02 08:59:13', NULL, NULL),
(158, 187, 9, '360', '2026-02-02 08:59:13', NULL, NULL),
(159, 188, 9, '240', '2026-02-02 08:59:13', NULL, NULL),
(160, 189, 9, '140', '2026-02-02 08:59:13', NULL, NULL),
(161, 190, 11, 'Mechanical', '2026-02-02 08:59:13', NULL, NULL),
(162, 191, 11, 'Mechanical', '2026-02-02 08:59:13', NULL, NULL),
(163, 192, 11, 'Membrane', '2026-02-02 08:59:13', NULL, NULL),
(164, 193, 11, 'Mechanical', '2026-02-02 08:59:13', NULL, NULL),
(165, 194, 11, 'Optical', '2026-02-02 08:59:13', NULL, NULL),
(166, 195, 11, 'Mecha-Membrane', '2026-02-02 08:59:13', NULL, NULL),
(167, 196, 11, 'Mechanical', '2026-02-02 08:59:13', NULL, NULL),
(168, 197, 11, 'Membrane', '2026-02-02 08:59:13', NULL, NULL),
(169, 198, 11, 'Mechanical', '2026-02-02 08:59:13', NULL, NULL),
(170, 199, 11, 'Membrane', '2026-02-02 08:59:13', NULL, NULL),
(171, 200, 11, 'Membrane', '2026-02-02 08:59:13', NULL, NULL),
(172, 201, 11, 'Mechanical', '2026-02-02 08:59:13', NULL, NULL),
(173, 226, 1, '6.0', '2026-02-02 08:59:13', NULL, NULL),
(174, 226, 2, '24', '2026-02-02 08:59:13', NULL, NULL),
(175, 227, 1, '5.6', '2026-02-02 08:59:13', NULL, NULL),
(176, 227, 2, '20', '2026-02-02 08:59:13', NULL, NULL),
(177, 228, 1, '5.3', '2026-02-02 08:59:13', NULL, NULL),
(178, 228, 2, '14', '2026-02-02 08:59:13', NULL, NULL),
(179, 229, 1, '5.8', '2026-02-02 08:59:13', NULL, NULL),
(180, 229, 2, '24', '2026-02-02 08:59:13', NULL, NULL),
(181, 230, 1, '5.1', '2026-02-02 08:59:13', NULL, NULL),
(182, 230, 2, '14', '2026-02-02 08:59:13', NULL, NULL),
(183, 231, 1, '4.7', '2026-02-02 08:59:13', NULL, NULL),
(184, 231, 2, '4', '2026-02-02 08:59:13', NULL, NULL),
(185, 232, 1, '5.7', '2026-02-02 08:59:13', NULL, NULL),
(186, 232, 2, '16', '2026-02-02 08:59:13', NULL, NULL),
(187, 233, 1, '5.4', '2026-02-02 08:59:13', NULL, NULL),
(188, 233, 2, '12', '2026-02-02 08:59:13', NULL, NULL),
(189, 234, 1, '5.0', '2026-02-02 08:59:13', NULL, NULL),
(190, 234, 2, '8', '2026-02-02 08:59:13', NULL, NULL),
(191, 235, 1, '5.4', '2026-02-02 08:59:13', NULL, NULL),
(192, 235, 2, '8', '2026-02-02 08:59:13', NULL, NULL),
(193, 236, 1, '5.3', '2026-02-02 08:59:13', NULL, NULL),
(194, 236, 2, '6', '2026-02-02 08:59:13', NULL, NULL),
(195, 237, 1, '4.6', '2026-02-02 08:59:13', NULL, NULL),
(196, 237, 2, '6', '2026-02-02 08:59:13', NULL, NULL),
(197, 238, 3, '24', '2026-02-02 08:59:13', NULL, NULL),
(198, 239, 4, 'Z790', '2026-02-02 09:11:25', NULL, NULL),
(199, 240, 4, 'B650', '2026-02-02 09:11:25', NULL, NULL),
(200, 241, 4, 'B760', '2026-02-02 09:11:25', NULL, NULL),
(201, 242, 4, 'B550', '2026-02-02 09:11:25', NULL, NULL),
(202, 243, 4, 'Z790', '2026-02-02 09:11:25', NULL, NULL),
(203, 244, 4, 'B650', '2026-02-02 09:11:25', NULL, NULL),
(204, 245, 4, 'B760', '2026-02-02 09:11:25', NULL, NULL),
(205, 246, 4, 'Z790', '2026-02-02 09:11:25', NULL, NULL),
(206, 247, 4, 'B650', '2026-02-02 09:11:25', NULL, NULL),
(207, 248, 4, 'B760', '2026-02-02 09:11:25', NULL, NULL),
(208, 249, 4, 'X670', '2026-02-02 09:11:25', NULL, NULL),
(209, 42, 3, 'teszt', '2026-02-03 08:24:17', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `product_notifications`
--

DROP TABLE IF EXISTS `product_notifications`;
CREATE TABLE `product_notifications` (
  `id` bigint(20) NOT NULL,
  `user_email` varchar(255) NOT NULL,
  `product_id` bigint(20) NOT NULL,
  `notified` tinyint(1) DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notified_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `reviews`
--

DROP TABLE IF EXISTS `reviews`;
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
(13, 42, 1, 3, 'Teszt', '2026-02-03 08:32:52', NULL, NULL);

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `teljesnev` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('customer','admin') DEFAULT 'customer',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_subscripted` tinyint(1) DEFAULT NULL,
  `is_deleted` tinyint(1) DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- A tábla adatainak kiíratása `users`
--

INSERT INTO `users` (`id`, `username`, `teljesnev`, `email`, `phone`, `password_hash`, `role`, `created_at`, `is_subscripted`, `is_deleted`, `deleted_at`) VALUES
(1, 'Sancika', '', 'sanci@gmail.copm', '+36201234567', 'sancuuus', 'customer', '2025-09-05 07:52:07', 0, 0, NULL),
(2, 'gerike', '', 'gercso@gmail.com', '+36303458912', 'asder', 'customer', '2025-09-05 07:53:57', 1, 0, NULL),
(3, 'Adel', '', 'adel@gmail.com', '+36704231897', 'adel', 'customer', '2025-09-05 07:53:57', 0, 0, NULL),
(4, 'peterk', '', 'peter.kiss@example.com', '', 'hash1234', 'customer', '2025-10-02 09:31:35', 0, 0, NULL),
(5, 'annan', '', 'anna.nagy@example.com', '+36201234323', 'hash2345', 'customer', '2025-10-21 11:54:28', 0, 0, NULL),
(6, 'bencesz', '', 'bence.szabo@example.com', '+36303458222', 'hash3456', 'customer', '2025-10-04 15:51:22', 0, 0, NULL),
(7, 'lillat', '', 'lilla.toth@example.com', '+36704231111', 'hash4567', 'customer', '2025-10-18 18:23:38', 1, 0, NULL),
(8, 'davidv', '', 'david.varga@example.com', '+36201234837', 'hash5678', 'customer', '2025-10-06 17:38:36', 0, 0, NULL),
(9, 'zsofif', '', 'zsofia.farkas@example.com', '+36303458735', 'hash6789', 'customer', '2025-10-01 08:03:43', 0, 0, NULL),
(10, 'matek', '', 'mate.kovacs@example.com', '+36704231153', 'hash7890', 'customer', '2025-10-27 17:33:59', 0, 0, NULL),
(11, 'eszterb', '', 'eszter.balogh@example.com', '+36201234847', 'hash8901', 'customer', '2025-10-28 09:02:34', 0, 0, NULL),
(12, 'gaborm', '', 'asdasd@gmail.com', '+36303458938', 'hash9012', 'customer', '2025-10-25 14:56:43', 0, 0, NULL),
(13, 'dorah', '', 'dora.horvath@example.com', '+36704231184', 'hash0123', 'customer', '2025-10-26 08:20:49', 0, 0, NULL),
(14, 'adamp', '', 'adam.papp@example.com', '+36704231864', 'hash1122', 'customer', '2025-10-21 16:49:33', 0, 0, NULL),
(15, 'noraj', '', 'nora.juhasz@example.com', '+36704231265', 'hash2233', 'customer', '2025-10-24 07:21:15', 0, 0, NULL),
(16, 'pistike', '', 'pistike@gmail.com', '', '$2a$12$CDwxuDqn2nKTyeHUY6zd5e/1R7IrgGM.kyk0SI82orPfcdcpXBW2e', 'customer', '2025-11-20 09:18:40', 0, 0, NULL),
(17, 'milla120', '', 'kamillavarhegyi10@gmail.com', '493-457-7987', '$2a$12$WNSJqlh3/mAHl.m3iz736uAG3hHijlv3GDdnDsbcDrHpQHvTkzjly', 'admin', '2025-12-04 08:49:57', 1, 0, NULL),
(36, 'tesztuser2', '', 'teszt1@email.com', '12345678', '$2a$12$ul3oHttI40gfQcupwpDUmOvNlbrObKvL/u1C1fkhnmTSlyMZssdBO', 'customer', '2026-01-19 09:15:53', NULL, 0, NULL),
(40, 'viktorhorvath', '', 'hviktor04222006@gmail.com', '12345678', '$2a$12$OSUQk5O63W1nvzbpOkMHeurpdU8H2V3tlmJn2junJ0Q7pQkipWiba', 'admin', '2026-01-19 10:17:09', NULL, 1, '2026-01-19 10:17:30'),
(41, 'tesztteszt', '', 'teszteszt@gmail.com', '1234567', 'tesztelek', 'customer', '2026-02-03 08:35:13', NULL, 0, NULL),
(50, 'Milla', 'Kárhegyi Vamilla', 'kamillavarhegyi100@gmail.com', '06306200812', '$2a$12$Ms2C24ATQMqrUOLAqvW3nuvxK9v.U/9JpUKtQ10vmZNUyObr46lcm', 'admin', '2026-03-02 09:55:47', NULL, 0, NULL),
(52, 'marko', 'Bajor Márk', 'bajormark@gmail.com', '+36 70 361 7490', '$2a$12$MqYb49RU8EfKNfbw4XYAEuJYQFrDT1UQXbWMCbr7ayCMHp1eYV7q.', 'admin', '2026-03-02 19:48:50', NULL, 0, NULL),
(56, 'teszt', 'teszt teszt', 'teszt123@gmail.com', '+36 70 123 4567', '$2a$12$0ytGjSoyLoMiirl7IqZwtu3GYATorf5JQfh9hIM8KrtsFm6JJko7W', 'customer', '2026-03-03 07:24:25', NULL, 0, NULL),
(57, 'marko11', 'Bajor Márk', 'bbajormark@gmail.com', ' +36 70 361 7490', '$2a$12$uXwDe6HKohL9sPg/HnFTxed3eny.8AgJ.ZE7YCWfn3AEBWZNYZJkK', 'customer', '2026-03-03 07:47:28', NULL, 0, NULL),
(59, 'teszt11', '', 'teszt12344@gmail.com', ' 999999999', '$2a$12$X90D.rl2TKFRJKNvFzFktek9AlwkhAXYvIlzZ4UJdpBL1hxJlFmnO', 'customer', '2026-03-03 07:56:38', NULL, 0, NULL);

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
-- A tábla indexei `cart`
--
ALTER TABLE `cart`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_cart_user` (`user_id`),
  ADD KEY `user_id` (`user_id`);

--
-- A tábla indexei `cart_items`
--
ALTER TABLE `cart_items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_cart_item` (`cart_id`,`product_id`),
  ADD KEY `cart_id` (`cart_id`),
  ADD KEY `product_id` (`product_id`);

--
-- A tábla indexei `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- A tábla indexei `configuration_products`
--
ALTER TABLE `configuration_products`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_config_product` (`configuration_id`,`product_id`,`component_type`),
  ADD KEY `idx_configuration_id` (`configuration_id`),
  ADD KEY `idx_product_id` (`product_id`),
  ADD KEY `idx_component_type` (`component_type`);

--
-- A tábla indexei `favorites`
--
ALTER TABLE `favorites`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_favorite` (`user_id`,`product_id`),
  ADD KEY `product_id` (`product_id`);

--
-- A tábla indexei `games`
--
ALTER TABLE `games`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_game_type` (`game_type`),
  ADD KEY `idx_requirement_level` (`requirement_level`);

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
-- A tábla indexei `pc_configurations`
--
ALTER TABLE `pc_configurations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_use_case` (`use_case`),
  ADD KEY `idx_requirement_level` (`requirement_level`),
  ADD KEY `idx_budget` (`budget_min`,`budget_max`);

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
-- A tábla indexei `product_notifications`
--
ALTER TABLE `product_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_product_id` (`product_id`),
  ADD KEY `idx_notified` (`notified`);

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT a táblához `attributes`
--
ALTER TABLE `attributes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT a táblához `brands`
--
ALTER TABLE `brands`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT a táblához `cart`
--
ALTER TABLE `cart`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT a táblához `cart_items`
--
ALTER TABLE `cart_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT a táblához `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT a táblához `configuration_products`
--
ALTER TABLE `configuration_products`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `favorites`
--
ALTER TABLE `favorites`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT a táblához `games`
--
ALTER TABLE `games`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT a táblához `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT a táblához `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=85;

--
-- AUTO_INCREMENT a táblához `pc_configurations`
--
ALTER TABLE `pc_configurations`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT a táblához `products`
--
ALTER TABLE `products`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=251;

--
-- AUTO_INCREMENT a táblához `product_attributes`
--
ALTER TABLE `product_attributes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=210;

--
-- AUTO_INCREMENT a táblához `product_notifications`
--
ALTER TABLE `product_notifications`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT a táblához `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=60;

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
-- Megkötések a táblához `cart`
--
ALTER TABLE `cart`
  ADD CONSTRAINT `cart_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Megkötések a táblához `cart_items`
--
ALTER TABLE `cart_items`
  ADD CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`cart_id`) REFERENCES `cart` (`id`),
  ADD CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`);

--
-- Megkötések a táblához `favorites`
--
ALTER TABLE `favorites`
  ADD CONSTRAINT `favorites_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `favorites_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`);

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
