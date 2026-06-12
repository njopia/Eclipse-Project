-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: 74.91.112.140    Database: natan_ban
-- ------------------------------------------------------
-- Server version	11.8.6-MariaDB-0+deb13u1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `natan_ban`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `natan_ban` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci */;

USE `natan_ban`;

--
-- Table structure for table `sb_admins`
--

DROP TABLE IF EXISTS `sb_admins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_admins` (
  `aid` int(6) NOT NULL AUTO_INCREMENT,
  `user` varchar(64) NOT NULL,
  `authid` varchar(64) NOT NULL DEFAULT '',
  `password` varchar(128) NOT NULL,
  `gid` int(6) NOT NULL,
  `email` varchar(128) NOT NULL,
  `validate` varchar(128) DEFAULT NULL,
  `extraflags` int(10) unsigned NOT NULL,
  `immunity` int(10) NOT NULL DEFAULT 0,
  `srv_group` varchar(128) DEFAULT NULL,
  `srv_flags` varchar(64) DEFAULT NULL,
  `srv_password` varchar(128) DEFAULT NULL,
  `lastvisit` int(11) DEFAULT NULL,
  `attempts` int(11) NOT NULL DEFAULT 0,
  `lockout_until` datetime DEFAULT NULL,
  PRIMARY KEY (`aid`),
  UNIQUE KEY `user` (`user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_admins_servers_groups`
--

DROP TABLE IF EXISTS `sb_admins_servers_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_admins_servers_groups` (
  `admin_id` int(10) NOT NULL,
  `group_id` int(10) NOT NULL,
  `srv_group_id` int(10) NOT NULL,
  `server_id` int(10) NOT NULL,
  PRIMARY KEY (`admin_id`,`group_id`,`srv_group_id`,`server_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_banlog`
--

DROP TABLE IF EXISTS `sb_banlog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_banlog` (
  `sid` int(6) NOT NULL,
  `time` int(11) NOT NULL,
  `name` varchar(128) NOT NULL,
  `bid` int(6) NOT NULL,
  PRIMARY KEY (`sid`,`time`,`bid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_bans`
--

DROP TABLE IF EXISTS `sb_bans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_bans` (
  `bid` int(6) NOT NULL AUTO_INCREMENT,
  `ip` varchar(32) DEFAULT NULL,
  `authid` varchar(64) NOT NULL DEFAULT '',
  `name` varchar(128) NOT NULL DEFAULT 'unnamed',
  `created` int(11) NOT NULL DEFAULT 0,
  `ends` int(11) NOT NULL DEFAULT 0,
  `length` int(10) NOT NULL DEFAULT 0,
  `reason` text NOT NULL,
  `aid` int(6) NOT NULL DEFAULT 0,
  `adminIp` varchar(128) NOT NULL DEFAULT '',
  `sid` int(6) NOT NULL DEFAULT 0,
  `country` varchar(4) DEFAULT NULL,
  `RemovedBy` int(8) DEFAULT NULL,
  `RemoveType` varchar(3) DEFAULT NULL,
  `RemovedOn` int(10) DEFAULT NULL,
  `type` tinyint(4) NOT NULL DEFAULT 0,
  `ureason` text DEFAULT NULL,
  PRIMARY KEY (`bid`),
  KEY `sid` (`sid`),
  KEY `type_authid` (`type`,`authid`),
  KEY `type_ip` (`type`,`ip`),
  FULLTEXT KEY `reason` (`reason`),
  FULLTEXT KEY `authid_2` (`authid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_comments`
--

DROP TABLE IF EXISTS `sb_comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_comments` (
  `cid` int(6) NOT NULL AUTO_INCREMENT,
  `bid` int(6) NOT NULL,
  `type` varchar(1) NOT NULL,
  `aid` int(6) NOT NULL,
  `commenttxt` longtext NOT NULL,
  `added` int(11) NOT NULL,
  `editaid` int(6) DEFAULT NULL,
  `edittime` int(11) DEFAULT NULL,
  KEY `cid` (`cid`),
  FULLTEXT KEY `commenttxt` (`commenttxt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_comms`
--

DROP TABLE IF EXISTS `sb_comms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_comms` (
  `bid` int(6) NOT NULL AUTO_INCREMENT,
  `authid` varchar(64) NOT NULL,
  `name` varchar(128) NOT NULL DEFAULT 'unnamed',
  `created` int(11) NOT NULL DEFAULT 0,
  `ends` int(11) NOT NULL DEFAULT 0,
  `length` int(10) NOT NULL DEFAULT 0,
  `reason` text NOT NULL,
  `aid` int(6) NOT NULL DEFAULT 0,
  `adminIp` varchar(128) NOT NULL DEFAULT '',
  `sid` int(6) NOT NULL DEFAULT 0,
  `RemovedBy` int(8) DEFAULT NULL,
  `RemoveType` varchar(3) DEFAULT NULL,
  `RemovedOn` int(11) DEFAULT NULL,
  `type` tinyint(4) NOT NULL DEFAULT 0 COMMENT '1 - Mute, 2 - Gag',
  `ureason` text DEFAULT NULL,
  PRIMARY KEY (`bid`),
  KEY `sid` (`sid`),
  KEY `type` (`type`),
  KEY `RemoveType` (`RemoveType`),
  KEY `authid` (`authid`),
  KEY `created` (`created`),
  KEY `aid` (`aid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_demos`
--

DROP TABLE IF EXISTS `sb_demos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_demos` (
  `demid` int(6) NOT NULL,
  `demtype` varchar(1) NOT NULL,
  `filename` varchar(128) NOT NULL,
  `origname` varchar(128) NOT NULL,
  PRIMARY KEY (`demid`,`demtype`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_groups`
--

DROP TABLE IF EXISTS `sb_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_groups` (
  `gid` int(6) NOT NULL AUTO_INCREMENT,
  `type` smallint(6) NOT NULL DEFAULT 0,
  `name` varchar(128) NOT NULL DEFAULT 'unnamed',
  `flags` int(10) unsigned NOT NULL,
  PRIMARY KEY (`gid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_log`
--

DROP TABLE IF EXISTS `sb_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_log` (
  `lid` int(11) NOT NULL AUTO_INCREMENT,
  `type` enum('m','w','e') NOT NULL,
  `title` varchar(512) NOT NULL,
  `message` text NOT NULL,
  `function` text NOT NULL,
  `query` text NOT NULL,
  `aid` int(11) NOT NULL,
  `host` text NOT NULL,
  `created` int(11) NOT NULL,
  PRIMARY KEY (`lid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_login_tokens`
--

DROP TABLE IF EXISTS `sb_login_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_login_tokens` (
  `jti` varchar(16) NOT NULL,
  `secret` varchar(64) NOT NULL,
  `lastAccessed` int(11) NOT NULL,
  PRIMARY KEY (`jti`),
  UNIQUE KEY `secret` (`secret`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_mods`
--

DROP TABLE IF EXISTS `sb_mods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_mods` (
  `mid` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `icon` varchar(128) NOT NULL,
  `modfolder` varchar(64) NOT NULL,
  `steam_universe` tinyint(4) NOT NULL DEFAULT 0,
  `enabled` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`mid`),
  UNIQUE KEY `modfolder` (`modfolder`),
  UNIQUE KEY `name` (`name`),
  KEY `steam_universe` (`steam_universe`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_notes`
--

DROP TABLE IF EXISTS `sb_notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_notes` (
  `nid` int(10) NOT NULL AUTO_INCREMENT,
  `steam_id` varchar(64) NOT NULL DEFAULT '',
  `aid` int(6) NOT NULL,
  `body` text NOT NULL,
  `created` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`nid`),
  KEY `steam_id` (`steam_id`),
  KEY `aid` (`aid`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_overrides`
--

DROP TABLE IF EXISTS `sb_overrides`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_overrides` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` enum('command','group') NOT NULL,
  `name` varchar(32) NOT NULL,
  `flags` varchar(30) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `type` (`type`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_protests`
--

DROP TABLE IF EXISTS `sb_protests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_protests` (
  `pid` int(6) NOT NULL AUTO_INCREMENT,
  `bid` int(6) NOT NULL,
  `datesubmitted` int(11) NOT NULL,
  `reason` text NOT NULL,
  `email` varchar(128) NOT NULL,
  `archiv` tinyint(1) DEFAULT 0,
  `archivedby` int(11) DEFAULT NULL,
  `pip` varchar(64) NOT NULL,
  PRIMARY KEY (`pid`),
  KEY `bid` (`bid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_servers`
--

DROP TABLE IF EXISTS `sb_servers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_servers` (
  `sid` int(6) NOT NULL AUTO_INCREMENT,
  `ip` varchar(64) NOT NULL,
  `port` int(5) NOT NULL,
  `rcon` varchar(64) NOT NULL,
  `modid` int(10) NOT NULL,
  `enabled` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`sid`),
  UNIQUE KEY `ip` (`ip`,`port`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_servers_groups`
--

DROP TABLE IF EXISTS `sb_servers_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_servers_groups` (
  `server_id` int(10) NOT NULL,
  `group_id` int(10) NOT NULL,
  PRIMARY KEY (`server_id`,`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_settings`
--

DROP TABLE IF EXISTS `sb_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_settings` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `setting` varchar(128) NOT NULL,
  `value` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `setting` (`setting`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_srvgroups`
--

DROP TABLE IF EXISTS `sb_srvgroups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_srvgroups` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `flags` varchar(30) NOT NULL,
  `immunity` int(10) unsigned NOT NULL,
  `name` varchar(120) NOT NULL,
  `groups_immune` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_srvgroups_overrides`
--

DROP TABLE IF EXISTS `sb_srvgroups_overrides`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_srvgroups_overrides` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) unsigned NOT NULL,
  `type` enum('command','group') NOT NULL,
  `name` varchar(32) NOT NULL,
  `access` enum('allow','deny') NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `group_id` (`group_id`,`type`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sb_submissions`
--

DROP TABLE IF EXISTS `sb_submissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sb_submissions` (
  `subid` int(6) NOT NULL AUTO_INCREMENT,
  `submitted` int(11) NOT NULL,
  `ModID` int(6) NOT NULL,
  `SteamId` varchar(64) NOT NULL DEFAULT 'unnamed',
  `name` varchar(128) NOT NULL,
  `email` varchar(128) NOT NULL,
  `reason` text NOT NULL,
  `ip` varchar(64) NOT NULL,
  `subname` varchar(128) DEFAULT NULL,
  `sip` varchar(64) DEFAULT NULL,
  `archiv` tinyint(1) DEFAULT 0,
  `archivedby` int(11) DEFAULT NULL,
  `server` tinyint(3) DEFAULT NULL,
  PRIMARY KEY (`subid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Current Database: `natan_admins`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `natan_admins` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci */;

USE `natan_admins`;

--
-- Table structure for table `sm_admins`
--

DROP TABLE IF EXISTS `sm_admins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_admins` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `authtype` enum('steam','name','ip') NOT NULL,
  `identity` varchar(65) NOT NULL,
  `password` varchar(65) DEFAULT NULL,
  `flags` varchar(30) NOT NULL,
  `name` varchar(65) NOT NULL,
  `immunity` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_admins_groups`
--

DROP TABLE IF EXISTS `sm_admins_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_admins_groups` (
  `admin_id` int(10) unsigned NOT NULL,
  `group_id` int(10) unsigned NOT NULL,
  `inherit_order` int(10) NOT NULL,
  PRIMARY KEY (`admin_id`,`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_config`
--

DROP TABLE IF EXISTS `sm_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_config` (
  `cfg_key` varchar(32) NOT NULL,
  `cfg_value` varchar(255) NOT NULL,
  PRIMARY KEY (`cfg_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_group_immunity`
--

DROP TABLE IF EXISTS `sm_group_immunity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_group_immunity` (
  `group_id` int(10) unsigned NOT NULL,
  `other_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`group_id`,`other_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_group_overrides`
--

DROP TABLE IF EXISTS `sm_group_overrides`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_group_overrides` (
  `group_id` int(10) unsigned NOT NULL,
  `type` enum('command','group') NOT NULL,
  `name` varchar(32) NOT NULL,
  `access` enum('allow','deny') NOT NULL,
  PRIMARY KEY (`group_id`,`type`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_groups`
--

DROP TABLE IF EXISTS `sm_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_groups` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `flags` varchar(30) NOT NULL,
  `name` varchar(120) NOT NULL,
  `immunity_level` int(1) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_overrides`
--

DROP TABLE IF EXISTS `sm_overrides`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_overrides` (
  `type` enum('command','group') NOT NULL,
  `name` varchar(32) NOT NULL,
  `flags` varchar(30) NOT NULL,
  PRIMARY KEY (`type`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Current Database: `natan_stats`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `natan_stats` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci */;

USE `natan_stats`;

--
-- Table structure for table `ip2country`
--

DROP TABLE IF EXISTS `ip2country`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ip2country` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `begin_ip_num` int(11) unsigned NOT NULL,
  `end_ip_num` int(11) unsigned NOT NULL,
  `country_code` varchar(4) NOT NULL,
  `country_name` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `begin_ip_num` (`begin_ip_num`,`end_ip_num`)
) ENGINE=InnoDB AUTO_INCREMENT=81217 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ip2country_blocks`
--

DROP TABLE IF EXISTS `ip2country_blocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ip2country_blocks` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `begin_ip_num` int(11) unsigned NOT NULL,
  `end_ip_num` int(11) unsigned NOT NULL,
  `loc_id` int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `beginend` (`begin_ip_num`,`end_ip_num`) USING BTREE,
  KEY `loc_id` (`loc_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1811273 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ip2country_locations`
--

DROP TABLE IF EXISTS `ip2country_locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ip2country_locations` (
  `loc_id` int(11) unsigned NOT NULL,
  `country_code` varchar(4) NOT NULL,
  `loc_region` varchar(128) NOT NULL,
  `loc_city` tinyblob NOT NULL,
  `latitude` double NOT NULL,
  `longitude` double NOT NULL,
  PRIMARY KEY (`loc_id`),
  KEY `country_code` (`country_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `maps`
--

DROP TABLE IF EXISTS `maps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `maps` (
  `name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
  `gamemode` int(1) NOT NULL DEFAULT 0,
  `custom` bit(1) NOT NULL DEFAULT b'0',
  `playtime_nor` int(11) NOT NULL DEFAULT 0,
  `playtime_adv` int(11) NOT NULL DEFAULT 0,
  `playtime_exp` int(11) NOT NULL DEFAULT 0,
  `restarts_nor` int(11) NOT NULL DEFAULT 0,
  `restarts_adv` int(11) NOT NULL DEFAULT 0,
  `restarts_exp` int(11) NOT NULL DEFAULT 0,
  `points_nor` int(11) NOT NULL DEFAULT 0,
  `points_adv` int(11) NOT NULL DEFAULT 0,
  `points_exp` int(11) NOT NULL DEFAULT 0,
  `points_infected_nor` int(11) NOT NULL DEFAULT 0,
  `points_infected_adv` int(11) NOT NULL DEFAULT 0,
  `points_infected_exp` int(11) NOT NULL DEFAULT 0,
  `kills_nor` int(11) NOT NULL DEFAULT 0,
  `kills_adv` int(11) NOT NULL DEFAULT 0,
  `kills_exp` int(11) NOT NULL DEFAULT 0,
  `survivor_kills_nor` int(11) NOT NULL DEFAULT 0,
  `survivor_kills_adv` int(11) NOT NULL DEFAULT 0,
  `survivor_kills_exp` int(11) NOT NULL DEFAULT 0,
  `infected_win_nor` int(11) NOT NULL DEFAULT 0,
  `infected_win_adv` int(11) NOT NULL DEFAULT 0,
  `infected_win_exp` int(11) NOT NULL DEFAULT 0,
  `survivors_win_nor` int(11) NOT NULL DEFAULT 0,
  `survivors_win_adv` int(11) NOT NULL DEFAULT 0,
  `survivors_win_exp` int(11) NOT NULL DEFAULT 0,
  `infected_smoker_damage_nor` bigint(20) NOT NULL DEFAULT 0,
  `infected_smoker_damage_adv` bigint(20) NOT NULL DEFAULT 0,
  `infected_smoker_damage_exp` bigint(20) NOT NULL DEFAULT 0,
  `infected_jockey_damage_nor` bigint(20) NOT NULL DEFAULT 0,
  `infected_jockey_damage_adv` bigint(20) NOT NULL DEFAULT 0,
  `infected_jockey_damage_exp` bigint(20) NOT NULL DEFAULT 0,
  `infected_jockey_ridetime_nor` double NOT NULL DEFAULT 0,
  `infected_jockey_ridetime_adv` double NOT NULL DEFAULT 0,
  `infected_jockey_ridetime_exp` double NOT NULL DEFAULT 0,
  `infected_charger_damage_nor` bigint(20) NOT NULL DEFAULT 0,
  `infected_charger_damage_adv` bigint(20) NOT NULL DEFAULT 0,
  `infected_charger_damage_exp` bigint(20) NOT NULL DEFAULT 0,
  `infected_tank_damage_nor` bigint(20) NOT NULL DEFAULT 0,
  `infected_tank_damage_adv` bigint(20) NOT NULL DEFAULT 0,
  `infected_tank_damage_exp` bigint(20) NOT NULL DEFAULT 0,
  `infected_boomer_vomits_nor` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_vomits_adv` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_vomits_exp` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_blinded_nor` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_blinded_adv` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_blinded_exp` int(11) NOT NULL DEFAULT 0,
  `infected_spitter_damage_nor` int(11) NOT NULL DEFAULT 0,
  `infected_spitter_damage_adv` int(11) NOT NULL DEFAULT 0,
  `infected_spitter_damage_exp` int(11) NOT NULL DEFAULT 0,
  `infected_spawn_1_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Smoker',
  `infected_spawn_1_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Smoker',
  `infected_spawn_1_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Smoker',
  `infected_spawn_2_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Boomer',
  `infected_spawn_2_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Boomer',
  `infected_spawn_2_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Boomer',
  `infected_spawn_3_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Hunter',
  `infected_spawn_3_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Hunter',
  `infected_spawn_3_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Hunter',
  `infected_spawn_4_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Spitter',
  `infected_spawn_4_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Spitter',
  `infected_spawn_4_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Spitter',
  `infected_spawn_5_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Jockey',
  `infected_spawn_5_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Jockey',
  `infected_spawn_5_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Jockey',
  `infected_spawn_6_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Charger',
  `infected_spawn_6_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Charger',
  `infected_spawn_6_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Charger',
  `infected_spawn_8_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Tank',
  `infected_spawn_8_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Tank',
  `infected_spawn_8_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Tank',
  `infected_hunter_pounce_counter_nor` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_counter_adv` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_counter_exp` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_damage_nor` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_damage_adv` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_damage_exp` int(11) NOT NULL DEFAULT 0,
  `infected_tanksniper_nor` int(11) NOT NULL DEFAULT 0,
  `infected_tanksniper_adv` int(11) NOT NULL DEFAULT 0,
  `infected_tanksniper_exp` int(11) NOT NULL DEFAULT 0,
  `caralarm_nor` int(11) NOT NULL DEFAULT 0,
  `caralarm_adv` int(11) NOT NULL DEFAULT 0,
  `caralarm_exp` int(11) NOT NULL DEFAULT 0,
  `jockey_rides_nor` int(11) NOT NULL DEFAULT 0,
  `jockey_rides_adv` int(11) NOT NULL DEFAULT 0,
  `jockey_rides_exp` int(11) NOT NULL DEFAULT 0,
  `charger_impacts_nor` int(11) NOT NULL DEFAULT 0,
  `charger_impacts_adv` int(11) NOT NULL DEFAULT 0,
  `charger_impacts_exp` int(11) NOT NULL DEFAULT 0,
  `mutation` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`name`,`gamemode`,`mutation`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `players`
--

DROP TABLE IF EXISTS `players`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `players` (
  `steamid` varchar(255) NOT NULL,
  `name` tinyblob NOT NULL,
  `lastontime` varchar(255) NOT NULL,
  `lastgamemode` int(1) NOT NULL DEFAULT 0,
  `ip` varchar(16) NOT NULL DEFAULT '0.0.0.0',
  `playtime` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Coop',
  `playtime_versus` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Versus',
  `playtime_realism` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Realism',
  `playtime_survival` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Survival',
  `playtime_scavenge` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Scavenge',
  `playtime_realismversus` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Realism',
  `points` int(11) NOT NULL DEFAULT 0,
  `points_realism` int(11) NOT NULL DEFAULT 0,
  `points_survival` int(11) NOT NULL DEFAULT 0,
  `points_survivors` int(11) NOT NULL DEFAULT 0,
  `points_infected` int(11) NOT NULL DEFAULT 0,
  `points_scavenge_survivors` int(11) NOT NULL DEFAULT 0,
  `points_scavenge_infected` int(11) NOT NULL DEFAULT 0,
  `points_realism_survivors` int(11) NOT NULL DEFAULT 0,
  `points_realism_infected` int(11) NOT NULL DEFAULT 0,
  `kills` int(11) NOT NULL DEFAULT 0,
  `melee_kills` int(11) NOT NULL DEFAULT 0,
  `headshots` int(11) NOT NULL DEFAULT 0,
  `kill_infected` int(11) NOT NULL DEFAULT 0,
  `kill_hunter` int(11) NOT NULL DEFAULT 0,
  `kill_smoker` int(11) NOT NULL DEFAULT 0,
  `kill_boomer` int(11) NOT NULL DEFAULT 0,
  `kill_spitter` int(11) NOT NULL DEFAULT 0,
  `kill_jockey` int(11) NOT NULL DEFAULT 0,
  `kill_charger` int(11) NOT NULL DEFAULT 0,
  `versus_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `scavenge_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `realism_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `jockey_rides` int(11) NOT NULL DEFAULT 0,
  `charger_impacts` int(11) NOT NULL DEFAULT 0,
  `award_pills` int(11) NOT NULL DEFAULT 0,
  `award_adrenaline` int(11) NOT NULL DEFAULT 0,
  `award_fincap` int(11) NOT NULL DEFAULT 0 COMMENT 'Friendly incapacitation',
  `award_medkit` int(11) NOT NULL DEFAULT 0,
  `award_defib` int(11) NOT NULL DEFAULT 0,
  `award_charger` int(11) NOT NULL DEFAULT 0,
  `award_jockey` int(11) NOT NULL DEFAULT 0,
  `award_hunter` int(11) NOT NULL DEFAULT 0,
  `award_smoker` int(11) NOT NULL DEFAULT 0,
  `award_protect` int(11) NOT NULL DEFAULT 0,
  `award_revive` int(11) NOT NULL DEFAULT 0,
  `award_rescue` int(11) NOT NULL DEFAULT 0,
  `award_campaigns` int(11) NOT NULL DEFAULT 0,
  `award_tankkill` int(11) NOT NULL DEFAULT 0,
  `award_tankkillnodeaths` int(11) NOT NULL DEFAULT 0,
  `award_allinsafehouse` int(11) NOT NULL DEFAULT 0,
  `award_friendlyfire` int(11) NOT NULL DEFAULT 0,
  `award_teamkill` int(11) NOT NULL DEFAULT 0,
  `award_left4dead` int(11) NOT NULL DEFAULT 0,
  `award_letinsafehouse` int(11) NOT NULL DEFAULT 0,
  `award_witchdisturb` int(11) NOT NULL DEFAULT 0,
  `award_pounce_perfect` int(11) NOT NULL DEFAULT 0,
  `award_pounce_nice` int(11) NOT NULL DEFAULT 0,
  `award_perfect_blindness` int(11) NOT NULL DEFAULT 0,
  `award_infected_win` int(11) NOT NULL DEFAULT 0,
  `award_scavenge_infected_win` int(11) NOT NULL DEFAULT 0,
  `award_bulldozer` int(11) NOT NULL DEFAULT 0,
  `award_survivor_down` int(11) NOT NULL DEFAULT 0,
  `award_ledgegrab` int(11) NOT NULL DEFAULT 0,
  `award_gascans_poured` int(11) NOT NULL DEFAULT 0,
  `award_upgrades_added` int(11) NOT NULL DEFAULT 0,
  `award_matador` int(11) NOT NULL DEFAULT 0,
  `award_witchcrowned` int(11) NOT NULL DEFAULT 0,
  `award_scatteringram` int(11) NOT NULL DEFAULT 0,
  `infected_spawn_1` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Smoker',
  `infected_spawn_2` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Boomer',
  `infected_spawn_3` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Hunter',
  `infected_spawn_4` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Spitter',
  `infected_spawn_5` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Jockey',
  `infected_spawn_6` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Charger',
  `infected_spawn_8` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Tank',
  `infected_boomer_vomits` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_blinded` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_counter` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_dmg` int(11) NOT NULL DEFAULT 0,
  `infected_smoker_damage` int(11) NOT NULL DEFAULT 0,
  `infected_jockey_damage` int(11) NOT NULL DEFAULT 0,
  `infected_jockey_ridetime` double NOT NULL DEFAULT 0,
  `infected_charger_damage` int(11) NOT NULL DEFAULT 0,
  `infected_tank_damage` int(11) NOT NULL DEFAULT 0,
  `infected_tanksniper` int(11) NOT NULL DEFAULT 0,
  `infected_spitter_damage` int(11) NOT NULL DEFAULT 0,
  `mutations_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `playtime_mutations` int(11) NOT NULL DEFAULT 0,
  `points_mutations` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `server_settings`
--

DROP TABLE IF EXISTS `server_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `server_settings` (
  `sname` varchar(64) NOT NULL,
  `svalue` blob DEFAULT NULL,
  PRIMARY KEY (`sname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `settings`
--

DROP TABLE IF EXISTS `settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `settings` (
  `steamid` varchar(255) NOT NULL,
  `mute` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `timedmaps`
--

DROP TABLE IF EXISTS `timedmaps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `timedmaps` (
  `map` varchar(255) NOT NULL,
  `gamemode` int(1) unsigned NOT NULL,
  `difficulty` int(1) unsigned NOT NULL,
  `steamid` varchar(255) NOT NULL,
  `plays` int(11) NOT NULL,
  `time` double NOT NULL,
  `players` int(2) NOT NULL,
  `modified` datetime NOT NULL,
  `created` date NOT NULL,
  `mutation` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`map`,`gamemode`,`difficulty`,`steamid`,`mutation`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Current Database: `natan_smod`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `natan_smod` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci */;

USE `natan_smod`;

--
-- Table structure for table `active_guests`
--

DROP TABLE IF EXISTS `active_guests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `active_guests` (
  `ip` varchar(15) NOT NULL,
  `timestamp` int(11) unsigned NOT NULL,
  PRIMARY KEY (`ip`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `active_users`
--

DROP TABLE IF EXISTS `active_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `active_users` (
  `username` varchar(30) NOT NULL,
  `timestamp` int(11) unsigned NOT NULL,
  PRIMARY KEY (`username`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `admin_ids`
--

DROP TABLE IF EXISTS `admin_ids`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_ids` (
  `steamid` text NOT NULL,
  UNIQUE KEY `steamid` (`steamid`(100))
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `admin_time`
--

DROP TABLE IF EXISTS `admin_time`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_time` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `steamid` text NOT NULL,
  `play_date` date NOT NULL,
  `play_time` int(11) NOT NULL,
  `server_name` text NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `steamid` (`steamid`(100),`play_date`)
) ENGINE=MyISAM AUTO_INCREMENT=5471 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `adsmysql`
--

DROP TABLE IF EXISTS `adsmysql`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `adsmysql` (
  `id` int(11) NOT NULL,
  `type` text NOT NULL,
  `text` text CHARACTER SET utf8mb3 COLLATE utf8mb3_swedish_ci NOT NULL,
  `flags` text NOT NULL,
  `game` text NOT NULL,
  `name` text NOT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `badnames`
--

DROP TABLE IF EXISTS `badnames`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `badnames` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bname` text NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `bname` (`bname`(250))
) ENGINE=MyISAM AUTO_INCREMENT=117 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `chatlogs`
--

DROP TABLE IF EXISTS `chatlogs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chatlogs` (
  `seqid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `srvid` varchar(255) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp(),
  `name` varchar(64) NOT NULL,
  `steamid` varchar(32) NOT NULL,
  `text` varchar(192) NOT NULL,
  `team` int(1) NOT NULL,
  `type` int(2) NOT NULL,
  PRIMARY KEY (`seqid`),
  KEY `srvid` (`srvid`),
  KEY `steamid` (`steamid`)
) ENGINE=MyISAM AUTO_INCREMENT=62743 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `crashes`
--

DROP TABLE IF EXISTS `crashes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `crashes` (
  `indexnum` int(11) NOT NULL AUTO_INCREMENT,
  `timedate` int(11) DEFAULT NULL,
  PRIMARY KEY (`indexnum`)
) ENGINE=MyISAM AUTO_INCREMENT=821 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `curmap`
--

DROP TABLE IF EXISTS `curmap`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `curmap` (
  `mapname` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `hostname` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `hostport` int(11) NOT NULL,
  `maxsurv` int(11) NOT NULL,
  `maxinf` int(11) NOT NULL,
  `version` varchar(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dblock`
--

DROP TABLE IF EXISTS `dblock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dblock` (
  `dateip` varchar(255) NOT NULL,
  `steamid` varchar(255) NOT NULL,
  `pname` varchar(255) NOT NULL,
  `cheat` varchar(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gungame_playerdata`
--

DROP TABLE IF EXISTS `gungame_playerdata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `gungame_playerdata` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `wins` int(12) NOT NULL DEFAULT 0,
  `authid` varchar(255) NOT NULL DEFAULT '',
  `name` varchar(255) NOT NULL DEFAULT '',
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `wins` (`wins`),
  KEY `authid` (`authid`)
) ENGINE=InnoDB AUTO_INCREMENT=658 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ip2country`
--

DROP TABLE IF EXISTS `ip2country`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ip2country` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `begin_ip_num` int(11) unsigned NOT NULL,
  `end_ip_num` int(11) unsigned NOT NULL,
  `country_code` varchar(4) NOT NULL,
  `country_name` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `begin_ip_num` (`begin_ip_num`,`end_ip_num`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ip2country_blocks`
--

DROP TABLE IF EXISTS `ip2country_blocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ip2country_blocks` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `begin_ip_num` int(11) unsigned NOT NULL,
  `end_ip_num` int(11) unsigned NOT NULL,
  `loc_id` int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `beginend` (`begin_ip_num`,`end_ip_num`),
  KEY `loc_id` (`loc_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ip2country_locations`
--

DROP TABLE IF EXISTS `ip2country_locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ip2country_locations` (
  `loc_id` int(11) unsigned NOT NULL,
  `country_code` varchar(4) NOT NULL,
  `loc_region` varchar(128) NOT NULL,
  `loc_city` tinyblob NOT NULL,
  `latitude` double NOT NULL,
  `longitude` double NOT NULL,
  PRIMARY KEY (`loc_id`),
  KEY `country_code` (`country_code`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `map_ratings`
--

DROP TABLE IF EXISTS `map_ratings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `map_ratings` (
  `steamid` varchar(24) DEFAULT NULL,
  `map` varchar(48) DEFAULT NULL,
  `rating` int(4) DEFAULT NULL,
  `rated` datetime DEFAULT NULL,
  UNIQUE KEY `map` (`map`,`steamid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `maps`
--

DROP TABLE IF EXISTS `maps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `maps` (
  `name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
  `gamemode` int(1) NOT NULL DEFAULT 0,
  `custom` bit(1) NOT NULL DEFAULT b'0',
  `playtime_nor` int(11) NOT NULL DEFAULT 0,
  `playtime_adv` int(11) NOT NULL DEFAULT 0,
  `playtime_exp` int(11) NOT NULL DEFAULT 0,
  `restarts_nor` int(11) NOT NULL DEFAULT 0,
  `restarts_adv` int(11) NOT NULL DEFAULT 0,
  `restarts_exp` int(11) NOT NULL DEFAULT 0,
  `points_nor` int(11) NOT NULL DEFAULT 0,
  `points_adv` int(11) NOT NULL DEFAULT 0,
  `points_exp` int(11) NOT NULL DEFAULT 0,
  `points_infected_nor` int(11) NOT NULL DEFAULT 0,
  `points_infected_adv` int(11) NOT NULL DEFAULT 0,
  `points_infected_exp` int(11) NOT NULL DEFAULT 0,
  `kills_nor` int(11) NOT NULL DEFAULT 0,
  `kills_adv` int(11) NOT NULL DEFAULT 0,
  `kills_exp` int(11) NOT NULL DEFAULT 0,
  `survivor_kills_nor` int(11) NOT NULL DEFAULT 0,
  `survivor_kills_adv` int(11) NOT NULL DEFAULT 0,
  `survivor_kills_exp` int(11) NOT NULL DEFAULT 0,
  `infected_win_nor` int(11) NOT NULL DEFAULT 0,
  `infected_win_adv` int(11) NOT NULL DEFAULT 0,
  `infected_win_exp` int(11) NOT NULL DEFAULT 0,
  `survivors_win_nor` int(11) NOT NULL DEFAULT 0,
  `survivors_win_adv` int(11) NOT NULL DEFAULT 0,
  `survivors_win_exp` int(11) NOT NULL DEFAULT 0,
  `infected_smoker_damage_nor` bigint(20) NOT NULL DEFAULT 0,
  `infected_smoker_damage_adv` bigint(20) NOT NULL DEFAULT 0,
  `infected_smoker_damage_exp` bigint(20) NOT NULL DEFAULT 0,
  `infected_spitter_damage_nor` bigint(20) NOT NULL DEFAULT 0,
  `infected_spitter_damage_adv` bigint(20) NOT NULL DEFAULT 0,
  `infected_spitter_damage_exp` bigint(20) NOT NULL DEFAULT 0,
  `infected_jockey_damage_nor` bigint(20) NOT NULL DEFAULT 0,
  `infected_jockey_damage_adv` bigint(20) NOT NULL DEFAULT 0,
  `infected_jockey_damage_exp` bigint(20) NOT NULL DEFAULT 0,
  `infected_jockey_ridetime_nor` double NOT NULL DEFAULT 0,
  `infected_jockey_ridetime_adv` double NOT NULL DEFAULT 0,
  `infected_jockey_ridetime_exp` double NOT NULL DEFAULT 0,
  `infected_charger_damage_nor` bigint(20) NOT NULL DEFAULT 0,
  `infected_charger_damage_adv` bigint(20) NOT NULL DEFAULT 0,
  `infected_charger_damage_exp` bigint(20) NOT NULL DEFAULT 0,
  `infected_tank_damage_nor` bigint(20) NOT NULL DEFAULT 0,
  `infected_tank_damage_adv` bigint(20) NOT NULL DEFAULT 0,
  `infected_tank_damage_exp` bigint(20) NOT NULL DEFAULT 0,
  `infected_boomer_vomits_nor` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_vomits_adv` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_vomits_exp` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_blinded_nor` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_blinded_adv` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_blinded_exp` int(11) NOT NULL DEFAULT 0,
  `infected_spawn_1_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Smoker',
  `infected_spawn_1_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Smoker',
  `infected_spawn_1_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Smoker',
  `infected_spawn_2_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Boomer',
  `infected_spawn_2_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Boomer',
  `infected_spawn_2_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Boomer',
  `infected_spawn_3_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Hunter',
  `infected_spawn_3_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Hunter',
  `infected_spawn_3_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Hunter',
  `infected_spawn_4_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Spitter',
  `infected_spawn_4_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Spitter',
  `infected_spawn_4_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Spitter',
  `infected_spawn_5_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Jockey',
  `infected_spawn_5_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Jockey',
  `infected_spawn_5_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Jockey',
  `infected_spawn_6_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Charger',
  `infected_spawn_6_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Charger',
  `infected_spawn_6_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Charger',
  `infected_spawn_8_nor` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Tank',
  `infected_spawn_8_adv` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Tank',
  `infected_spawn_8_exp` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawn as Tank',
  `infected_hunter_pounce_counter_nor` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_counter_adv` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_counter_exp` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_damage_nor` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_damage_adv` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_damage_exp` int(11) NOT NULL DEFAULT 0,
  `infected_tanksniper_nor` int(11) NOT NULL DEFAULT 0,
  `infected_tanksniper_adv` int(11) NOT NULL DEFAULT 0,
  `infected_tanksniper_exp` int(11) NOT NULL DEFAULT 0,
  `caralarm_nor` int(11) NOT NULL DEFAULT 0,
  `caralarm_adv` int(11) NOT NULL DEFAULT 0,
  `caralarm_exp` int(11) NOT NULL DEFAULT 0,
  `jockey_rides_nor` int(11) NOT NULL DEFAULT 0,
  `jockey_rides_adv` int(11) NOT NULL DEFAULT 0,
  `jockey_rides_exp` int(11) NOT NULL DEFAULT 0,
  `charger_impacts_nor` int(11) NOT NULL DEFAULT 0,
  `charger_impacts_adv` int(11) NOT NULL DEFAULT 0,
  `charger_impacts_exp` int(11) NOT NULL DEFAULT 0,
  `mutation` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`name`,`gamemode`,`mutation`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mysql_bans`
--

DROP TABLE IF EXISTS `mysql_bans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mysql_bans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steam_id` varchar(32) NOT NULL,
  `player_name` varchar(65) NOT NULL,
  `ipaddr` varchar(24) NOT NULL,
  `ban_length` int(1) NOT NULL DEFAULT 0,
  `ban_reason` varchar(100) NOT NULL,
  `banned_by` varchar(100) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `steam_id` (`steam_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `online`
--

DROP TABLE IF EXISTS `online`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `online` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `pname` varchar(255) NOT NULL,
  `playtime` varchar(255) NOT NULL,
  `score` int(11) NOT NULL,
  `rank` int(11) NOT NULL,
  `skill` int(11) NOT NULL,
  `autoskill` int(11) NOT NULL,
  `team` int(11) NOT NULL,
  `status` int(11) NOT NULL,
  `admin_lvl` int(11) NOT NULL,
  `steamid` varchar(255) NOT NULL,
  `hostname` varchar(255) NOT NULL,
  `hostport` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `steamid` (`steamid`)
) ENGINE=MyISAM AUTO_INCREMENT=61545 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `online_history`
--

DROP TABLE IF EXISTS `online_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `online_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hostname` text NOT NULL,
  `oh_date` date NOT NULL,
  `oh_hour` int(11) NOT NULL,
  `oh_minutes` int(11) NOT NULL,
  `nickname` text NOT NULL,
  `steamid` text NOT NULL,
  `vip` int(11) NOT NULL,
  `isadmin` int(11) NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `hostname` (`hostname`(255),`oh_date`,`oh_hour`,`steamid`(255)),
  KEY `steamid` (`steamid`(255)),
  KEY `hostname_2` (`hostname`(255)),
  KEY `nickname` (`nickname`(255)),
  KEY `steamid_2` (`steamid`(100),`oh_date`)
) ENGINE=InnoDB AUTO_INCREMENT=6113484 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `perkmod`
--

DROP TABLE IF EXISTS `perkmod`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `perkmod` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `steamid` varchar(255) NOT NULL,
  `pname` blob NOT NULL,
  `perks` varchar(100) NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `steamid` (`steamid`)
) ENGINE=MyISAM AUTO_INCREMENT=343454 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `player_stats`
--

DROP TABLE IF EXISTS `player_stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `player_stats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `event_id` int(11) NOT NULL,
  `steamid` text NOT NULL,
  `servername` text NOT NULL,
  `mapname` text NOT NULL,
  `roundnum` int(11) NOT NULL,
  `frags` int(11) NOT NULL,
  `deaths` int(11) NOT NULL,
  `alive` int(11) NOT NULL,
  `skillpoints` int(11) NOT NULL,
  `maptime` int(11) NOT NULL,
  `weapon` text NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `steamid` (`steamid`(100)),
  KEY `servername` (`servername`(100)),
  KEY `insertdt` (`insertdt`),
  KEY `alive` (`alive`,`frags`,`deaths`,`skillpoints`),
  KEY `servername_2` (`servername`(100),`mapname`(100),`roundnum`,`maptime`,`insertdt`),
  KEY `servername_3` (`servername`(100),`mapname`(100),`maptime`,`insertdt`)
) ENGINE=InnoDB AUTO_INCREMENT=926801 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `players`
--

DROP TABLE IF EXISTS `players`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `players` (
  `steamid` varchar(255) NOT NULL,
  `name` tinyblob NOT NULL,
  `lastontime` varchar(255) NOT NULL,
  `lastgamemode` int(1) NOT NULL DEFAULT 0,
  `playtime` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Coop',
  `playtime_versus` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Versus',
  `playtime_realism` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Realism',
  `points` int(11) NOT NULL DEFAULT 0,
  `points_realism` int(11) NOT NULL DEFAULT 0,
  `points_survivors` int(11) NOT NULL DEFAULT 0,
  `points_infected` int(11) NOT NULL DEFAULT 0,
  `kills` int(11) NOT NULL DEFAULT 0,
  `headshots` int(11) NOT NULL DEFAULT 0,
  `kill_infected` int(11) NOT NULL DEFAULT 0,
  `kill_hunter` int(11) NOT NULL DEFAULT 0,
  `kill_smoker` int(11) NOT NULL DEFAULT 0,
  `kill_boomer` int(11) NOT NULL DEFAULT 0,
  `kill_spitter` int(11) NOT NULL DEFAULT 0,
  `kill_jockey` int(11) NOT NULL DEFAULT 0,
  `kill_charger` int(11) NOT NULL DEFAULT 0,
  `versus_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `award_pills` int(11) NOT NULL DEFAULT 0,
  `award_adrenaline` int(11) NOT NULL DEFAULT 0,
  `award_fincap` int(11) NOT NULL DEFAULT 0 COMMENT 'Friendly incapacitation',
  `award_medkit` int(11) NOT NULL DEFAULT 0,
  `award_defib` int(11) NOT NULL DEFAULT 0,
  `award_charger` int(11) NOT NULL DEFAULT 0,
  `award_jockey` int(11) NOT NULL DEFAULT 0,
  `award_hunter` int(11) NOT NULL DEFAULT 0,
  `award_smoker` int(11) NOT NULL DEFAULT 0,
  `award_protect` int(11) NOT NULL DEFAULT 0,
  `award_revive` int(11) NOT NULL DEFAULT 0,
  `award_rescue` int(11) NOT NULL DEFAULT 0,
  `award_campaigns` int(11) NOT NULL DEFAULT 0,
  `award_tankkill` int(11) NOT NULL DEFAULT 0,
  `award_tankkillnodeaths` int(11) NOT NULL DEFAULT 0,
  `award_allinsafehouse` int(11) NOT NULL DEFAULT 0,
  `award_friendlyfire` int(11) NOT NULL DEFAULT 0,
  `award_teamkill` int(11) NOT NULL DEFAULT 0,
  `award_left4dead` int(11) NOT NULL DEFAULT 0,
  `award_letinsafehouse` int(11) NOT NULL DEFAULT 0,
  `award_witchdisturb` int(11) NOT NULL DEFAULT 0,
  `award_pounce_perfect` int(11) NOT NULL DEFAULT 0,
  `award_pounce_nice` int(11) NOT NULL DEFAULT 0,
  `award_perfect_blindness` int(11) NOT NULL DEFAULT 0,
  `award_infected_win` int(11) NOT NULL DEFAULT 0,
  `award_bulldozer` int(11) NOT NULL DEFAULT 0,
  `award_survivor_down` int(11) NOT NULL DEFAULT 0,
  `award_ledgegrab` int(11) NOT NULL DEFAULT 0,
  `infected_spawn_1` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Smoker',
  `infected_spawn_2` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Boomer',
  `infected_spawn_3` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Hunter',
  `infected_spawn_4` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Spitter',
  `infected_spawn_5` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Jockey',
  `infected_spawn_6` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Charger',
  `infected_spawn_8` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Tank',
  `infected_boomer_vomits` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_blinded` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_counter` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_dmg` int(11) NOT NULL DEFAULT 0,
  `infected_smoker_damage` int(11) NOT NULL DEFAULT 0,
  `infected_jockey_damage` int(11) NOT NULL DEFAULT 0,
  `infected_jockey_ridetime` double NOT NULL DEFAULT 0,
  `infected_charger_damage` int(11) NOT NULL DEFAULT 0,
  `infected_tank_damage` int(11) NOT NULL DEFAULT 0,
  `infected_tanksniper` int(11) NOT NULL DEFAULT 0,
  `infected_spitter_damage` int(11) NOT NULL DEFAULT 0,
  `playtime_survival` int(11) NOT NULL DEFAULT 0,
  `playtime_scavenge` int(11) NOT NULL DEFAULT 0,
  `points_scavenge_survivors` int(11) NOT NULL DEFAULT 0,
  `points_scavenge_infected` int(11) NOT NULL DEFAULT 0,
  `points_survival` int(11) NOT NULL DEFAULT 0,
  `scavenge_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `jockey_rides` int(11) NOT NULL DEFAULT 0,
  `award_scavenge_infected_win` int(11) NOT NULL DEFAULT 0,
  `award_matador` int(11) NOT NULL DEFAULT 0,
  `award_witchcrowned` int(11) NOT NULL DEFAULT 0,
  `award_gascans_poured` int(11) NOT NULL DEFAULT 0,
  `award_upgrades_added` int(11) NOT NULL DEFAULT 0,
  `ip` varchar(16) NOT NULL DEFAULT '0.0.0.0',
  `playtime_realismversus` int(11) NOT NULL DEFAULT 0,
  `points_realism_survivors` int(11) NOT NULL DEFAULT 0,
  `points_realism_infected` int(11) NOT NULL DEFAULT 0,
  `realism_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `award_scatteringram` int(11) NOT NULL DEFAULT 0,
  `charger_impacts` int(11) NOT NULL DEFAULT 0,
  `melee_kills` int(11) NOT NULL DEFAULT 0,
  `acharger_impacts` int(11) NOT NULL,
  `mutations_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `playtime_mutations` int(11) NOT NULL DEFAULT 0,
  `points_mutations` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`steamid`),
  KEY `steamid` (`steamid`),
  KEY `points_survivors` (`points_survivors`),
  KEY `points_infected` (`points_infected`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `players_names`
--

DROP TABLE IF EXISTS `players_names`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `players_names` (
  `steamid` varchar(255) NOT NULL,
  `name` tinyblob NOT NULL,
  `lastontime` varchar(255) NOT NULL,
  `lastgamemode` int(1) NOT NULL DEFAULT 0,
  `playtime` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Coop',
  `playtime_versus` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Versus',
  `playtime_realism` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Realism',
  `points` int(11) NOT NULL DEFAULT 0,
  `points_realism` int(11) NOT NULL DEFAULT 0,
  `points_survivors` int(11) NOT NULL DEFAULT 0,
  `points_infected` int(11) NOT NULL DEFAULT 0,
  `kills` int(11) NOT NULL DEFAULT 0,
  `headshots` int(11) NOT NULL DEFAULT 0,
  `kill_infected` int(11) NOT NULL DEFAULT 0,
  `kill_hunter` int(11) NOT NULL DEFAULT 0,
  `kill_smoker` int(11) NOT NULL DEFAULT 0,
  `kill_boomer` int(11) NOT NULL DEFAULT 0,
  `kill_spitter` int(11) NOT NULL DEFAULT 0,
  `kill_jockey` int(11) NOT NULL DEFAULT 0,
  `kill_charger` int(11) NOT NULL DEFAULT 0,
  `versus_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `award_pills` int(11) NOT NULL DEFAULT 0,
  `award_adrenaline` int(11) NOT NULL DEFAULT 0,
  `award_fincap` int(11) NOT NULL DEFAULT 0 COMMENT 'Friendly incapacitation',
  `award_medkit` int(11) NOT NULL DEFAULT 0,
  `award_defib` int(11) NOT NULL DEFAULT 0,
  `award_charger` int(11) NOT NULL DEFAULT 0,
  `award_jockey` int(11) NOT NULL DEFAULT 0,
  `award_hunter` int(11) NOT NULL DEFAULT 0,
  `award_smoker` int(11) NOT NULL DEFAULT 0,
  `award_protect` int(11) NOT NULL DEFAULT 0,
  `award_revive` int(11) NOT NULL DEFAULT 0,
  `award_rescue` int(11) NOT NULL DEFAULT 0,
  `award_campaigns` int(11) NOT NULL DEFAULT 0,
  `award_tankkill` int(11) NOT NULL DEFAULT 0,
  `award_tankkillnodeaths` int(11) NOT NULL DEFAULT 0,
  `award_allinsafehouse` int(11) NOT NULL DEFAULT 0,
  `award_friendlyfire` int(11) NOT NULL DEFAULT 0,
  `award_teamkill` int(11) NOT NULL DEFAULT 0,
  `award_left4dead` int(11) NOT NULL DEFAULT 0,
  `award_letinsafehouse` int(11) NOT NULL DEFAULT 0,
  `award_witchdisturb` int(11) NOT NULL DEFAULT 0,
  `award_pounce_perfect` int(11) NOT NULL DEFAULT 0,
  `award_pounce_nice` int(11) NOT NULL DEFAULT 0,
  `award_perfect_blindness` int(11) NOT NULL DEFAULT 0,
  `award_infected_win` int(11) NOT NULL DEFAULT 0,
  `award_bulldozer` int(11) NOT NULL DEFAULT 0,
  `award_survivor_down` int(11) NOT NULL DEFAULT 0,
  `award_ledgegrab` int(11) NOT NULL DEFAULT 0,
  `infected_spawn_1` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Smoker',
  `infected_spawn_2` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Boomer',
  `infected_spawn_3` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Hunter',
  `infected_spawn_4` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Spitter',
  `infected_spawn_5` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Jockey',
  `infected_spawn_6` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Charger',
  `infected_spawn_8` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Tank',
  `infected_boomer_vomits` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_blinded` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_counter` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_dmg` int(11) NOT NULL DEFAULT 0,
  `infected_smoker_damage` int(11) NOT NULL DEFAULT 0,
  `infected_jockey_damage` int(11) NOT NULL DEFAULT 0,
  `infected_jockey_ridetime` double NOT NULL DEFAULT 0,
  `infected_charger_damage` int(11) NOT NULL DEFAULT 0,
  `infected_tank_damage` int(11) NOT NULL DEFAULT 0,
  `infected_tanksniper` int(11) NOT NULL DEFAULT 0,
  `infected_spitter_damage` int(11) NOT NULL DEFAULT 0,
  `playtime_survival` int(11) NOT NULL DEFAULT 0,
  `playtime_scavenge` int(11) NOT NULL DEFAULT 0,
  `points_scavenge_survivors` int(11) NOT NULL DEFAULT 0,
  `points_scavenge_infected` int(11) NOT NULL DEFAULT 0,
  `points_survival` int(11) NOT NULL DEFAULT 0,
  `scavenge_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `jockey_rides` int(11) NOT NULL DEFAULT 0,
  `award_scavenge_infected_win` int(11) NOT NULL DEFAULT 0,
  `award_matador` int(11) NOT NULL DEFAULT 0,
  `award_witchcrowned` int(11) NOT NULL DEFAULT 0,
  `award_gascans_poured` int(11) NOT NULL DEFAULT 0,
  `award_upgrades_added` int(11) NOT NULL DEFAULT 0,
  `ip` varchar(16) NOT NULL DEFAULT '0.0.0.0',
  `playtime_realismversus` int(11) NOT NULL DEFAULT 0,
  `points_realism_survivors` int(11) NOT NULL DEFAULT 0,
  `points_realism_infected` int(11) NOT NULL DEFAULT 0,
  `realism_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `award_scatteringram` int(11) NOT NULL DEFAULT 0,
  `charger_impacts` int(11) NOT NULL DEFAULT 0,
  `melee_kills` int(11) NOT NULL DEFAULT 0,
  `acharger_impacts` int(11) NOT NULL,
  `mutations_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `playtime_mutations` int(11) NOT NULL DEFAULT 0,
  `points_mutations` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`steamid`),
  KEY `steamid` (`steamid`),
  KEY `steamid_2` (`steamid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `players_steams`
--

DROP TABLE IF EXISTS `players_steams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `players_steams` (
  `steamid` varchar(255) NOT NULL,
  `name` tinyblob NOT NULL,
  `lastontime` varchar(255) NOT NULL,
  `lastgamemode` int(1) NOT NULL DEFAULT 0,
  `playtime` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Coop',
  `playtime_versus` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Versus',
  `playtime_realism` int(11) NOT NULL DEFAULT 0 COMMENT 'Playtime in Realism',
  `points` int(11) NOT NULL DEFAULT 0,
  `points_realism` int(11) NOT NULL DEFAULT 0,
  `points_survivors` int(11) NOT NULL DEFAULT 0,
  `points_infected` int(11) NOT NULL DEFAULT 0,
  `kills` int(11) NOT NULL DEFAULT 0,
  `headshots` int(11) NOT NULL DEFAULT 0,
  `kill_infected` int(11) NOT NULL DEFAULT 0,
  `kill_hunter` int(11) NOT NULL DEFAULT 0,
  `kill_smoker` int(11) NOT NULL DEFAULT 0,
  `kill_boomer` int(11) NOT NULL DEFAULT 0,
  `kill_spitter` int(11) NOT NULL DEFAULT 0,
  `kill_jockey` int(11) NOT NULL DEFAULT 0,
  `kill_charger` int(11) NOT NULL DEFAULT 0,
  `versus_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `award_pills` int(11) NOT NULL DEFAULT 0,
  `award_adrenaline` int(11) NOT NULL DEFAULT 0,
  `award_fincap` int(11) NOT NULL DEFAULT 0 COMMENT 'Friendly incapacitation',
  `award_medkit` int(11) NOT NULL DEFAULT 0,
  `award_defib` int(11) NOT NULL DEFAULT 0,
  `award_charger` int(11) NOT NULL DEFAULT 0,
  `award_jockey` int(11) NOT NULL DEFAULT 0,
  `award_hunter` int(11) NOT NULL DEFAULT 0,
  `award_smoker` int(11) NOT NULL DEFAULT 0,
  `award_protect` int(11) NOT NULL DEFAULT 0,
  `award_revive` int(11) NOT NULL DEFAULT 0,
  `award_rescue` int(11) NOT NULL DEFAULT 0,
  `award_campaigns` int(11) NOT NULL DEFAULT 0,
  `award_tankkill` int(11) NOT NULL DEFAULT 0,
  `award_tankkillnodeaths` int(11) NOT NULL DEFAULT 0,
  `award_allinsafehouse` int(11) NOT NULL DEFAULT 0,
  `award_friendlyfire` int(11) NOT NULL DEFAULT 0,
  `award_teamkill` int(11) NOT NULL DEFAULT 0,
  `award_left4dead` int(11) NOT NULL DEFAULT 0,
  `award_letinsafehouse` int(11) NOT NULL DEFAULT 0,
  `award_witchdisturb` int(11) NOT NULL DEFAULT 0,
  `award_pounce_perfect` int(11) NOT NULL DEFAULT 0,
  `award_pounce_nice` int(11) NOT NULL DEFAULT 0,
  `award_perfect_blindness` int(11) NOT NULL DEFAULT 0,
  `award_infected_win` int(11) NOT NULL DEFAULT 0,
  `award_bulldozer` int(11) NOT NULL DEFAULT 0,
  `award_survivor_down` int(11) NOT NULL DEFAULT 0,
  `award_ledgegrab` int(11) NOT NULL DEFAULT 0,
  `infected_spawn_1` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Smoker',
  `infected_spawn_2` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Boomer',
  `infected_spawn_3` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Hunter',
  `infected_spawn_4` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Spitter',
  `infected_spawn_5` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Jockey',
  `infected_spawn_6` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Charger',
  `infected_spawn_8` int(11) NOT NULL DEFAULT 0 COMMENT 'Spawned as Tank',
  `infected_boomer_vomits` int(11) NOT NULL DEFAULT 0,
  `infected_boomer_blinded` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_counter` int(11) NOT NULL DEFAULT 0,
  `infected_hunter_pounce_dmg` int(11) NOT NULL DEFAULT 0,
  `infected_smoker_damage` int(11) NOT NULL DEFAULT 0,
  `infected_jockey_damage` int(11) NOT NULL DEFAULT 0,
  `infected_jockey_ridetime` double NOT NULL DEFAULT 0,
  `infected_charger_damage` int(11) NOT NULL DEFAULT 0,
  `infected_tank_damage` int(11) NOT NULL DEFAULT 0,
  `infected_tanksniper` int(11) NOT NULL DEFAULT 0,
  `infected_spitter_damage` int(11) NOT NULL DEFAULT 0,
  `playtime_survival` int(11) NOT NULL DEFAULT 0,
  `playtime_scavenge` int(11) NOT NULL DEFAULT 0,
  `points_scavenge_survivors` int(11) NOT NULL DEFAULT 0,
  `points_scavenge_infected` int(11) NOT NULL DEFAULT 0,
  `points_survival` int(11) NOT NULL DEFAULT 0,
  `scavenge_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `jockey_rides` int(11) NOT NULL DEFAULT 0,
  `award_scavenge_infected_win` int(11) NOT NULL DEFAULT 0,
  `award_matador` int(11) NOT NULL DEFAULT 0,
  `award_witchcrowned` int(11) NOT NULL DEFAULT 0,
  `award_gascans_poured` int(11) NOT NULL DEFAULT 0,
  `award_upgrades_added` int(11) NOT NULL DEFAULT 0,
  `ip` varchar(16) NOT NULL DEFAULT '0.0.0.0',
  `playtime_realismversus` int(11) NOT NULL DEFAULT 0,
  `points_realism_survivors` int(11) NOT NULL DEFAULT 0,
  `points_realism_infected` int(11) NOT NULL DEFAULT 0,
  `realism_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `award_scatteringram` int(11) NOT NULL DEFAULT 0,
  `charger_impacts` int(11) NOT NULL DEFAULT 0,
  `melee_kills` int(11) NOT NULL DEFAULT 0,
  `acharger_impacts` int(11) NOT NULL,
  `mutations_kills_survivors` int(11) NOT NULL DEFAULT 0,
  `playtime_mutations` int(11) NOT NULL DEFAULT 0,
  `points_mutations` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`steamid`),
  KEY `steamid` (`steamid`),
  KEY `steamid_2` (`steamid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `plugins_list`
--

DROP TABLE IF EXISTS `plugins_list`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `plugins_list` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `plugin_name` varchar(255) NOT NULL,
  `status` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=83 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pounces`
--

DROP TABLE IF EXISTS `pounces`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pounces` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `datetime` datetime NOT NULL,
  `pouncer` varchar(64) NOT NULL,
  `pounced` varchar(64) NOT NULL,
  `distance` smallint(5) unsigned NOT NULL,
  `damage` float NOT NULL,
  `map` varchar(64) NOT NULL,
  `steamid` varchar(64) NOT NULL,
  `server` varchar(64) NOT NULL,
  `damage2` float NOT NULL,
  `speed` int(10) NOT NULL,
  `steamid_victim` varchar(64) NOT NULL,
  `isincap` int(10) NOT NULL,
  `human_count` int(10) NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `steamid` (`steamid`),
  KEY `steamid_victim` (`steamid_victim`),
  KEY `isincap` (`isincap`),
  KEY `human_count` (`human_count`),
  KEY `steamid_2` (`steamid`,`steamid_victim`,`isincap`,`human_count`),
  KEY `damage2` (`damage2`),
  KEY `map` (`map`),
  KEY `damage2_2` (`damage2`,`map`,`steamid`,`steamid_victim`,`isincap`,`human_count`)
) ENGINE=InnoDB AUTO_INCREMENT=309878 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `public_logs`
--

DROP TABLE IF EXISTS `public_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `public_logs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `steamid` text NOT NULL,
  `client_name` text NOT NULL,
  `action` text NOT NULL,
  `arg1` text NOT NULL,
  `arg2` text NOT NULL,
  `arg3` text NOT NULL,
  `arg4` text NOT NULL,
  `arg5` text NOT NULL,
  `hostname` text NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `steamid` (`steamid`(333)),
  KEY `client_name` (`client_name`(333)),
  KEY `action` (`action`(333)),
  KEY `arg1` (`arg1`(333)),
  KEY `arg2` (`arg2`(333)),
  KEY `arg3` (`arg3`(333)),
  KEY `arg4` (`arg4`(333)),
  KEY `arg5` (`arg5`(333)),
  KEY `hostname` (`hostname`(333)),
  KEY `insertdt` (`insertdt`)
) ENGINE=MyISAM AUTO_INCREMENT=707181 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reg_css`
--

DROP TABLE IF EXISTS `reg_css`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reg_css` (
  `name` text CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `pass` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `team` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `steam` text CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `skill` tinyint(4) NOT NULL,
  `vip_status` int(11) DEFAULT NULL,
  `zvanie` tinyblob NOT NULL,
  `aftor` tinyblob NOT NULL,
  `steamid` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `entertext` text NOT NULL,
  `realname` tinyblob NOT NULL,
  `icq` tinyblob NOT NULL,
  `skype` tinyblob NOT NULL,
  `login` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci DEFAULT NULL,
  `skillparam` int(11) NOT NULL,
  `connect_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `disconnect_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `reg_name` text CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `start_date_admin` datetime NOT NULL,
  `start_date_vip` datetime NOT NULL,
  `end_date_admin` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `steam_protect` int(11) NOT NULL DEFAULT 0,
  `name_protect` int(11) NOT NULL DEFAULT 0,
  UNIQUE KEY `steamid` (`steamid`),
  UNIQUE KEY `login` (`login`),
  KEY `pass` (`pass`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reg_name`
--

DROP TABLE IF EXISTS `reg_name`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reg_name` (
  `name` text NOT NULL,
  `pass` varchar(255) NOT NULL,
  `team` varchar(255) NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp(),
  `team_name` text NOT NULL,
  `skill` tinyint(4) NOT NULL,
  `status` smallint(6) NOT NULL,
  `zvanie` tinyblob NOT NULL,
  `aftor` tinyblob NOT NULL,
  `steamid` varchar(255) NOT NULL,
  `entertext` text NOT NULL,
  `realname` tinyblob NOT NULL,
  `icq` tinyblob NOT NULL,
  `skype` tinyblob NOT NULL,
  `login` varchar(255) DEFAULT NULL,
  `skillparam` int(11) NOT NULL,
  `connect_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `disconnect_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `status_start` datetime NOT NULL,
  `status_end` datetime NOT NULL,
  `was_status` int(11) NOT NULL,
  `admin_end` datetime NOT NULL,
  `web_status` int(11) NOT NULL,
  `warnings` int(11) NOT NULL,
  `punish` int(11) NOT NULL,
  `mpoints_base` int(11) NOT NULL,
  `mpoints_rank` int(11) NOT NULL,
  `steamid_short` varchar(255) NOT NULL DEFAULT 'SUBSTR(steamid, 9)',
  UNIQUE KEY `steamid` (`steamid`),
  UNIQUE KEY `login` (`login`),
  UNIQUE KEY `login_2` (`login`(100),`pass`(100)),
  KEY `pass` (`pass`),
  KEY `name` (`name`(333)),
  KEY `connect_time` (`connect_time`),
  KEY `steamid_short` (`steamid_short`(100))
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reg_name_was`
--

DROP TABLE IF EXISTS `reg_name_was`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reg_name_was` (
  `name` text NOT NULL,
  `pass` varchar(255) NOT NULL,
  `team` varchar(255) NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp(),
  `team_name` text NOT NULL,
  `skill` tinyint(4) NOT NULL,
  `status` smallint(6) NOT NULL,
  `zvanie` tinyblob NOT NULL,
  `aftor` tinyblob NOT NULL,
  `steamid` varchar(255) NOT NULL,
  `entertext` text NOT NULL,
  `realname` tinyblob NOT NULL,
  `icq` tinyblob NOT NULL,
  `skype` tinyblob NOT NULL,
  `login` varchar(255) DEFAULT NULL,
  `skillparam` int(11) NOT NULL,
  `connect_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `disconnect_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `status_start` datetime NOT NULL,
  `status_end` datetime NOT NULL,
  `was_status` int(11) NOT NULL,
  `admin_end` datetime NOT NULL,
  `web_status` int(11) NOT NULL,
  `warnings` int(11) NOT NULL,
  `punish` int(11) NOT NULL,
  `mpoints_base` int(11) NOT NULL,
  `mpoints_rank` int(11) NOT NULL,
  `steamid_short` varchar(255) NOT NULL DEFAULT 'SUBSTR(steamid, 9)',
  UNIQUE KEY `steamid` (`steamid`),
  UNIQUE KEY `login` (`login`),
  UNIQUE KEY `login_2` (`login`(100),`pass`(100)),
  KEY `pass` (`pass`),
  KEY `name` (`name`(333)),
  KEY `connect_time` (`connect_time`),
  KEY `steamid_short` (`steamid_short`(100))
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `roundstats`
--

DROP TABLE IF EXISTS `roundstats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roundstats` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `mapname` text CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `pname` text CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `pteam` int(11) NOT NULL,
  `zkilled` int(11) NOT NULL,
  `insdate` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `scores`
--

DROP TABLE IF EXISTS `scores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `scores` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `mapname` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `playername` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `points` int(11) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `team` int(11) NOT NULL,
  `hostname` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `server`
--

DROP TABLE IF EXISTS `server`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `server` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `address` varchar(50) NOT NULL DEFAULT '127.0.0.1',
  `groupnumber` int(11) NOT NULL DEFAULT 1,
  `last_update` datetime NOT NULL,
  `display_name` varchar(100) NOT NULL DEFAULT '[new server]',
  `offline_name` varchar(100) NOT NULL DEFAULT '[offline]',
  `maxplayers` int(11) NOT NULL DEFAULT 0,
  `currplayers` int(11) NOT NULL DEFAULT 0,
  `map` varchar(70) NOT NULL DEFAULT '[no map]',
  PRIMARY KEY (`id`),
  KEY `groupnumber` (`groupnumber`),
  KEY `last_update` (`last_update`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `server_console`
--

DROP TABLE IF EXISTS `server_console`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `server_console` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `console_text` varchar(2024) NOT NULL,
  `hostname` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `settings`
--

DROP TABLE IF EXISTS `settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `settings` (
  `steamid` varchar(255) NOT NULL,
  `mute` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`steamid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `signal`
--

DROP TABLE IF EXISTS `signal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `signal` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `destId` varchar(31) NOT NULL,
  `sourceId` varchar(31) NOT NULL,
  `sourceName` varchar(63) NOT NULL,
  `message` varchar(255) NOT NULL,
  `unread` tinyint(1) NOT NULL,
  `time` timestamp NOT NULL DEFAULT current_timestamp(),
  `deleted` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `signal_blocks`
--

DROP TABLE IF EXISTS `signal_blocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `signal_blocks` (
  `userId` varchar(31) NOT NULL,
  `blockedId` varchar(31) NOT NULL,
  `blockedName` varchar(63) NOT NULL,
  UNIQUE KEY `UserBlockPair` (`userId`,`blockedId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `signal_friends`
--

DROP TABLE IF EXISTS `signal_friends`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `signal_friends` (
  `userId` varchar(31) NOT NULL,
  `friendId` varchar(31) NOT NULL,
  `friendName` varchar(63) NOT NULL,
  UNIQUE KEY `UserFriendPair` (`userId`,`friendId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `signal_groupmembers`
--

DROP TABLE IF EXISTS `signal_groupmembers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `signal_groupmembers` (
  `groupId` int(11) NOT NULL,
  `memberId` varchar(31) NOT NULL,
  `memberName` varchar(63) NOT NULL,
  UNIQUE KEY `GroupMemberPair` (`groupId`,`memberId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `signal_groups`
--

DROP TABLE IF EXISTS `signal_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `signal_groups` (
  `groupId` int(11) NOT NULL AUTO_INCREMENT,
  `ownerId` varchar(31) NOT NULL,
  `groupName` varchar(63) NOT NULL,
  PRIMARY KEY (`groupId`),
  UNIQUE KEY `OwnerGroupNamePair` (`ownerId`,`groupName`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `signal_players`
--

DROP TABLE IF EXISTS `signal_players`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `signal_players` (
  `steamId` varchar(31) NOT NULL,
  `lastName` varchar(63) NOT NULL,
  `lastSeen` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`steamId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `skills`
--

DROP TABLE IF EXISTS `skills`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `skills` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `aftor_steamid` varchar(100) NOT NULL,
  `skill_steamid` varchar(100) NOT NULL,
  `skill` int(11) NOT NULL,
  `skilltxt` varchar(255) NOT NULL,
  `isadmin` int(11) NOT NULL,
  `isvip` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `aftor_steamid_2` (`aftor_steamid`,`skill_steamid`),
  KEY `skill_steamid` (`skill_steamid`),
  KEY `aftor_steamid` (`aftor_steamid`)
) ENGINE=MyISAM AUTO_INCREMENT=79294 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_admins`
--

DROP TABLE IF EXISTS `sm_admins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_admins` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `authtype` enum('steam','name','ip') NOT NULL,
  `identity` varchar(65) NOT NULL,
  `password` varchar(65) DEFAULT NULL,
  `flags` varchar(30) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `name` varchar(65) NOT NULL,
  `immunity` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=259 DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_admins_groups`
--

DROP TABLE IF EXISTS `sm_admins_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_admins_groups` (
  `admin_id` int(10) unsigned NOT NULL,
  `group_id` int(10) unsigned NOT NULL,
  `inherit_order` int(10) NOT NULL,
  PRIMARY KEY (`admin_id`,`group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_config`
--

DROP TABLE IF EXISTS `sm_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_config` (
  `cfg_key` varchar(32) NOT NULL,
  `cfg_value` varchar(255) NOT NULL,
  PRIMARY KEY (`cfg_key`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_cookie_cache`
--

DROP TABLE IF EXISTS `sm_cookie_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_cookie_cache` (
  `player` varchar(65) NOT NULL,
  `cookie_id` int(10) NOT NULL,
  `value` varchar(100) DEFAULT NULL,
  `timestamp` int(11) NOT NULL,
  PRIMARY KEY (`player`,`cookie_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_cookies`
--

DROP TABLE IF EXISTS `sm_cookies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_cookies` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `access` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_group_immunity`
--

DROP TABLE IF EXISTS `sm_group_immunity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_group_immunity` (
  `group_id` int(10) unsigned NOT NULL,
  `other_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`group_id`,`other_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_group_overrides`
--

DROP TABLE IF EXISTS `sm_group_overrides`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_group_overrides` (
  `group_id` int(10) unsigned NOT NULL,
  `type` enum('command','group') NOT NULL,
  `name` varchar(32) NOT NULL,
  `access` enum('allow','deny') NOT NULL,
  PRIMARY KEY (`group_id`,`type`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_groups`
--

DROP TABLE IF EXISTS `sm_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_groups` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `flags` varchar(30) NOT NULL,
  `name` varchar(120) NOT NULL,
  `immunity_level` int(1) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_mysql_p_polls`
--

DROP TABLE IF EXISTS `sm_mysql_p_polls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_mysql_p_polls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `title` varchar(128) NOT NULL,
  `time` int(11) NOT NULL,
  `stat` int(1) NOT NULL,
  `server_id` varchar(32) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_mysql_p_variants`
--

DROP TABLE IF EXISTS `sm_mysql_p_variants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_mysql_p_variants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `poll_id` int(11) NOT NULL,
  `name` varchar(128) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_mysql_p_votes`
--

DROP TABLE IF EXISTS `sm_mysql_p_votes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_mysql_p_votes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `poll_id` int(11) NOT NULL,
  `time` int(11) NOT NULL,
  `variant` int(11) NOT NULL,
  `steam` varchar(32) NOT NULL,
  `ip` varchar(15) NOT NULL,
  `name` varchar(128) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=625 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_overrides`
--

DROP TABLE IF EXISTS `sm_overrides`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_overrides` (
  `type` enum('command','group') NOT NULL,
  `name` varchar(32) NOT NULL,
  `flags` varchar(30) NOT NULL,
  PRIMARY KEY (`type`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_servers`
--

DROP TABLE IF EXISTS `sm_servers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_servers` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `ip` varchar(15) NOT NULL DEFAULT '',
  `port` int(10) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ip` (`ip`,`port`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sm_servers_groups`
--

DROP TABLE IF EXISTS `sm_servers_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sm_servers_groups` (
  `server_id` int(10) DEFAULT NULL,
  `group_id` int(10) DEFAULT NULL,
  UNIQUE KEY `server_id` (`server_id`,`group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `smwa_mods`
--

DROP TABLE IF EXISTS `smwa_mods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `smwa_mods` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `folder` varchar(64) NOT NULL DEFAULT '',
  `icon` varchar(128) DEFAULT NULL,
  `advert` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `icon` (`icon`)
) ENGINE=MyISAM AUTO_INCREMENT=18 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `smwa_plugins`
--

DROP TABLE IF EXISTS `smwa_plugins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `smwa_plugins` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(64) NOT NULL DEFAULT '',
  `Systemname` varchar(32) NOT NULL DEFAULT '',
  `MMS` varchar(64) DEFAULT NULL,
  `MMSColum` varchar(64) DEFAULT NULL,
  `Version` varchar(16) DEFAULT NULL,
  `Tablename` varchar(32) NOT NULL DEFAULT '',
  `Author` varchar(64) DEFAULT NULL,
  `Support` varchar(255) NOT NULL DEFAULT '',
  `Authorlink` varchar(255) NOT NULL DEFAULT '',
  `Showplug` int(1) DEFAULT 0,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `Systemname` (`Systemname`),
  UNIQUE KEY `Name` (`Name`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `smwa_server`
--

DROP TABLE IF EXISTS `smwa_server`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `smwa_server` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Ip` varchar(21) NOT NULL DEFAULT '',
  `Name_Short` varchar(24) NOT NULL DEFAULT '',
  `rcon` varchar(255) NOT NULL DEFAULT '',
  `ftp_ip` varchar(255) NOT NULL DEFAULT '',
  `ftp_username` varchar(255) NOT NULL DEFAULT '',
  `ftp_pw` varchar(255) NOT NULL DEFAULT '',
  `ftp_path` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `Ip` (`Ip`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `smwa_server_plugins_mss`
--

DROP TABLE IF EXISTS `smwa_server_plugins_mss`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `smwa_server_plugins_mss` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Interface_Server_ID` int(11) DEFAULT NULL,
  `Plugin_Server_ID` int(11) DEFAULT NULL,
  `Plugin_Systemname` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `Interface_Server_ID` (`Interface_Server_ID`,`Plugin_Systemname`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `smwa_settings`
--

DROP TABLE IF EXISTS `smwa_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `smwa_settings` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(64) NOT NULL DEFAULT '',
  `Value` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `Name` (`Name`)
) ENGINE=MyISAM AUTO_INCREMENT=36 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `smwa_users`
--

DROP TABLE IF EXISTS `smwa_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `smwa_users` (
  `UserID` int(11) NOT NULL AUTO_INCREMENT,
  `UserName` varchar(30) NOT NULL DEFAULT '',
  `UserPass` varchar(32) NOT NULL DEFAULT '',
  `UserMail` varchar(150) NOT NULL DEFAULT '',
  `UserLanguage` varchar(8) NOT NULL DEFAULT '',
  `UserSession` varchar(32) DEFAULT NULL,
  `UserOnline` int(30) DEFAULT NULL,
  `UserEditUsers` int(1) DEFAULT NULL,
  `UserSQLAdmins` int(1) DEFAULT NULL,
  `UserEditPluginsettings` int(1) DEFAULT NULL,
  `UserEditPermissions` int(1) DEFAULT NULL,
  `UserEditInterfacesettings` int(1) DEFAULT NULL,
  `UserEditMods` int(1) DEFAULT NULL,
  `UserServersettings` int(1) DEFAULT NULL,
  `UserOwner` int(1) DEFAULT NULL,
  `UserDatum` varchar(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`UserID`),
  UNIQUE KEY `UserName` (`UserName`),
  UNIQUE KEY `UserMail` (`UserMail`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `spanel_settings`
--

DROP TABLE IF EXISTS `spanel_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `spanel_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `last_date` datetime NOT NULL,
  `upd_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stats_move`
--

DROP TABLE IF EXISTS `stats_move`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_move` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `old_id` text NOT NULL,
  `new_id` text NOT NULL,
  `game` text NOT NULL,
  `status` int(11) NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `old_id` (`old_id`(100),`new_id`(100),`game`(100),`status`),
  KEY `old_id_2` (`old_id`(255)),
  KEY `new_id` (`new_id`(255))
) ENGINE=MyISAM AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `steamid_log`
--

DROP TABLE IF EXISTS `steamid_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `steamid_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `login` text NOT NULL,
  `steamid` text NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `login` (`login`(100),`steamid`(100))
) ENGINE=MyISAM AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `steamid_move`
--

DROP TABLE IF EXISTS `steamid_move`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `steamid_move` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `steamid_old` text NOT NULL,
  `steamid_new` text NOT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `summary`
--

DROP TABLE IF EXISTS `summary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `summary` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `inserdt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `points` bigint(20) NOT NULL,
  `kills` int(11) NOT NULL,
  `map` text CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `host` text CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `pname` text CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci NOT NULL,
  `team` int(11) NOT NULL,
  `round_num` int(11) NOT NULL,
  `zcount` int(11) NOT NULL,
  `incapped` int(11) NOT NULL,
  `ledge` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=63802 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sync_msgs`
--

DROP TABLE IF EXISTS `sync_msgs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sync_msgs` (
  `id` bigint(20) NOT NULL,
  `steamid` varchar(255) NOT NULL,
  `pname` varchar(255) NOT NULL,
  `msg` varchar(2048) NOT NULL,
  `server` varchar(255) NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `szl_con_log`
--

DROP TABLE IF EXISTS `szl_con_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `szl_con_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip` text NOT NULL,
  `user_id` text NOT NULL,
  `last_dt` datetime NOT NULL,
  `sid` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4021 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tank_log`
--

DROP TABLE IF EXISTS `tank_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tank_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tank_name` varchar(255) NOT NULL,
  `attacker_name` varchar(255) NOT NULL,
  `tank_health` int(11) NOT NULL,
  `damage` float NOT NULL,
  `inflictor_name` varchar(255) NOT NULL,
  `damage_type` varchar(255) NOT NULL,
  `weapon_name` varchar(255) NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` int(11) NOT NULL,
  `hostname` varchar(255) NOT NULL,
  `class` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `timedmaps`
--

DROP TABLE IF EXISTS `timedmaps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `timedmaps` (
  `map` varchar(255) NOT NULL,
  `gamemode` int(1) unsigned NOT NULL,
  `difficulty` int(1) unsigned NOT NULL,
  `steamid` varchar(255) NOT NULL,
  `plays` int(11) NOT NULL,
  `time` double NOT NULL,
  `players` int(2) NOT NULL,
  `modified` datetime NOT NULL,
  `created` date NOT NULL,
  `mutation` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`map`,`gamemode`,`difficulty`,`steamid`,`mutation`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_edit_log`
--

DROP TABLE IF EXISTS `user_edit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_edit_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user` text NOT NULL,
  `user_edit` text NOT NULL,
  `sfield` text NOT NULL,
  `old_value` text NOT NULL,
  `new_value` text NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_params`
--

DROP TABLE IF EXISTS `user_params`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_params` (
  `steamid` text NOT NULL,
  `mute_rank` int(11) NOT NULL,
  `mute_info` int(11) NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp(),
  UNIQUE KEY `steamid` (`steamid`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `username` varchar(30) NOT NULL,
  `password` varchar(32) DEFAULT NULL,
  `userid` varchar(32) DEFAULT NULL,
  `userlevel` tinyint(1) unsigned NOT NULL,
  `email` varchar(50) DEFAULT NULL,
  `timestamp` int(11) unsigned NOT NULL,
  PRIMARY KEY (`username`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `warning_logs`
--

DROP TABLE IF EXISTS `warning_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `warning_logs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `client_steamid` text NOT NULL,
  `admin_steamid` text NOT NULL,
  `w_reason` text NOT NULL,
  `w_type` int(11) NOT NULL,
  `server_name` text NOT NULL,
  `insertdt` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=351 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Current Database: `players`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `players` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci */;

USE `players`;

--
-- Table structure for table `player_levels`
--

DROP TABLE IF EXISTS `player_levels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `player_levels` (
  `steamid` varchar(32) NOT NULL,
  `player_name` varchar(128) DEFAULT NULL,
  `current_level` int(11) DEFAULT 0,
  `current_xp` int(11) DEFAULT 0,
  `total_xp` int(11) DEFAULT 0,
  `shoulder_cannon_auto_equip` tinyint(4) DEFAULT 1,
  `unlocked_bloodmoon` tinyint(4) DEFAULT 0,
  `unlocked_hell` tinyint(4) DEFAULT 0,
  `unlocked_inferno` tinyint(4) DEFAULT 0,
  `unlocked_cow` tinyint(4) DEFAULT 0,
  `last_update` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `server_hud_messages`
--

DROP TABLE IF EXISTS `server_hud_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `server_hud_messages` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `message` varchar(128) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-06-11 22:31:49
