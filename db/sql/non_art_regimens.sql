-- MySQL dump 10.13  Distrib 5.1.54, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: bart
-- ------------------------------------------------------
-- Server version	5.1.54-1ubuntu4

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `regimen`
--

DROP TABLE IF EXISTS `regimen`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regimen` (
  `regimen_id` int(11) NOT NULL AUTO_INCREMENT,
  `concept_id` int(11) NOT NULL DEFAULT '0',
  `min_weight` int(3) NOT NULL DEFAULT '0',
  `max_weight` int(3) NOT NULL DEFAULT '200',
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL DEFAULT '1900-01-01 00:00:00',
  `retired` smallint(6) NOT NULL DEFAULT '0',
  `retired_by` int(11) DEFAULT NULL,
  `date_retired` datetime DEFAULT NULL,
  `program_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`regimen_id`),
  KEY `map_concept` (`concept_id`),
  CONSTRAINT `map_concept` FOREIGN KEY (`concept_id`) REFERENCES `concept` (`concept_id`)
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `regimen`
--

LOCK TABLES `regimen` WRITE;
/*!40000 ALTER TABLE `regimen` DISABLE KEYS */;
INSERT INTO `regimen` VALUES (11,2984,35,200,1,'2011-06-20 17:59:01',0,NULL,NULL,1),(13,7859,0,6,1,'2011-06-20 19:01:12',0,NULL,NULL,1),(14,7859,6,10,1,'2011-06-20 19:01:54',0,NULL,NULL,1),(15,7859,10,14,1,'2011-06-20 19:02:07',0,NULL,NULL,1),(16,7859,14,20,1,'2011-06-20 19:02:16',0,NULL,NULL,1),(17,7859,20,25,1,'2011-06-20 19:02:24',0,NULL,NULL,1),(18,7859,25,30,1,'2011-06-20 19:02:31',0,NULL,NULL,1),(19,7859,30,35,1,'2011-06-20 19:02:43',0,NULL,NULL,1),(20,794,0,4,1,'2011-06-20 19:12:10',1,NULL,NULL,1),(21,794,4,6,1,'2011-06-20 19:14:20',1,NULL,NULL,1),(22,794,6,14,1,'2011-06-20 19:17:03',1,NULL,NULL,1),(23,794,14,25,1,'2011-06-20 19:19:43',1,NULL,NULL,1),(24,794,25,35,1,'2011-06-20 19:19:59',1,NULL,NULL,1),(25,794,35,200,1,'2011-06-20 19:20:26',1,NULL,NULL,1),(26,792,0,6,1,'2011-06-20 20:09:24',0,NULL,NULL,1),(27,792,6,10,1,'2011-06-20 20:11:43',0,NULL,NULL,1),(28,792,10,14,1,'2011-06-20 20:12:37',0,NULL,NULL,1),(29,792,14,20,1,'2011-06-20 20:12:48',0,NULL,NULL,1),(30,792,20,25,1,'2011-06-20 20:13:22',0,NULL,NULL,1),(31,792,25,200,1,'2011-06-20 20:13:44',0,NULL,NULL,1),(32,1610,0,6,1,'2011-06-20 21:04:35',0,NULL,NULL,1),(33,1610,6,10,1,'2011-06-20 21:04:35',0,NULL,NULL,1),(34,1610,10,14,1,'2011-06-20 21:04:35',0,NULL,NULL,1),(35,1610,14,20,1,'2011-06-20 21:04:36',0,NULL,NULL,1),(36,1610,20,25,1,'2011-06-20 21:04:36',0,NULL,NULL,1),(37,1610,25,200,1,'2011-06-20 21:04:36',0,NULL,NULL,1),(38,7860,10,14,1,'2011-06-20 21:07:38',0,NULL,NULL,1),(39,7860,14,20,1,'2011-06-20 21:07:38',0,NULL,NULL,1),(40,7860,20,25,1,'2011-06-20 21:07:38',0,NULL,NULL,1),(41,7860,25,40,1,'2011-06-20 21:07:38',0,NULL,NULL,1),(42,7860,40,200,1,'2011-06-20 21:07:39',0,NULL,NULL,1),(43,7861,10,14,1,'2011-06-20 21:20:57',0,NULL,NULL,1),(44,7861,14,20,1,'2011-06-20 21:20:57',0,NULL,NULL,1),(45,7861,20,25,1,'2011-06-20 21:20:57',0,NULL,NULL,1),(46,7861,25,40,1,'2011-06-20 21:20:58',0,NULL,NULL,1),(47,7861,40,200,1,'2011-06-20 21:20:58',0,NULL,NULL,1),(48,2985,35,200,1,'2011-06-20 21:47:38',0,NULL,NULL,1),(49,7862,35,200,1,'2011-06-20 21:47:38',0,NULL,NULL,1),(50,2994,35,200,1,'2011-06-20 22:01:12',0,NULL,NULL,1),(51,916,0,200,1,'2011-06-22 17:28:12',0,NULL,NULL,0),(52,656,0,200,1,'2011-06-22 17:28:42',0,NULL,NULL,0);
/*!40000 ALTER TABLE `regimen` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `regimen_drug_order`
--

DROP TABLE IF EXISTS `regimen_drug_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regimen_drug_order` (
  `regimen_drug_order_id` int(11) NOT NULL AUTO_INCREMENT,
  `regimen_id` int(11) NOT NULL DEFAULT '0',
  `drug_inventory_id` int(11) DEFAULT '0',
  `dose` double DEFAULT NULL,
  `equivalent_daily_dose` double DEFAULT NULL,
  `units` varchar(255) DEFAULT NULL,
  `frequency` varchar(255) DEFAULT NULL,
  `prn` tinyint(1) NOT NULL DEFAULT '0',
  `complex` tinyint(1) NOT NULL DEFAULT '0',
  `quantity` int(11) DEFAULT NULL,
  `instructions` text,
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL DEFAULT '1900-01-01 00:00:00',
  `voided` smallint(6) NOT NULL DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(255) DEFAULT NULL,
  `uuid` char(38) NOT NULL,
  PRIMARY KEY (`regimen_drug_order_id`),
  UNIQUE KEY `regimen_drug_order_uuid_index` (`uuid`),
  KEY `regimen_drug_order_creator` (`creator`),
  KEY `user_who_voided_regimen_drug_order` (`voided_by`),
  KEY `map_regimen` (`regimen_id`),
  KEY `map_drug_inventory` (`drug_inventory_id`),
  CONSTRAINT `map_drug_inventory` FOREIGN KEY (`drug_inventory_id`) REFERENCES `drug` (`drug_id`),
  CONSTRAINT `map_regimen` FOREIGN KEY (`regimen_id`) REFERENCES `regimen` (`regimen_id`),
  CONSTRAINT `regimen_drug_order_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_who_voided_regimen_drug_order` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=56 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `regimen_drug_order`
--

LOCK TABLES `regimen_drug_order` WRITE;
/*!40000 ALTER TABLE `regimen_drug_order` DISABLE KEYS */;
INSERT INTO `regimen_drug_order` VALUES (1,11,733,1,1,'tab(s)','ONCE A DAY (OD)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 18:07:06',0,NULL,NULL,NULL,'5871aa8e-9b57-11e0-a2a8-544249e49b14'),(2,11,22,1,1,'tab(s)','ONCE A DAY (OD)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 18:10:03',0,NULL,NULL,NULL,'c1e9841e-9b57-11e0-a2a8-544249e49b14'),(3,13,732,1,1,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:05:42',0,NULL,NULL,NULL,'9cf2dc5c-9b5f-11e0-a2a8-544249e49b14'),(4,14,732,1.5,3,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:06:34',0,NULL,NULL,NULL,'bbdd31da-9b5f-11e0-a2a8-544249e49b14'),(5,15,732,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:06:43',0,NULL,NULL,NULL,'c0be0594-9b5f-11e0-a2a8-544249e49b14'),(6,16,732,2.5,5,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:06:51',0,NULL,NULL,NULL,'c5f6d8ba-9b5f-11e0-a2a8-544249e49b14'),(7,17,732,3,6,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'3 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:07:52',0,NULL,NULL,NULL,'ea47245e-9b5f-11e0-a2a8-544249e49b14'),(8,18,732,4,8,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'4 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:08:26',0,NULL,NULL,NULL,'fe3e09fa-9b5f-11e0-a2a8-544249e49b14'),(9,19,732,4.5,9,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'4.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:08:44',0,NULL,NULL,NULL,'08e77b5c-9b60-11e0-a2a8-544249e49b14'),(10,20,94,1,2,'ml','TWICE A DAY (BD)',0,0,NULL,'1 ml TWICE A DAY (BD)',1,'2011-06-20 19:12:48',0,NULL,NULL,NULL,'9a5311f0-9b60-11e0-a2a8-544249e49b14'),(11,21,94,1.5,3,'ml','TWICE A DAY (BD)',0,0,NULL,'1.5 ml TWICE A DAY (BD)',1,'2011-06-20 19:15:03',0,NULL,NULL,NULL,'eaf9b62c-9b60-11e0-a2a8-544249e49b14'),(12,22,74,1,3,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) IN THE MORNING (QAM); 1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 19:17:46',0,NULL,NULL,NULL,'4be809a2-9b61-11e0-a2a8-544249e49b14'),(13,23,74,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:21:18',0,NULL,NULL,NULL,'cad6992c-9b61-11e0-a2a8-544249e49b14'),(14,24,74,3,6,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'3 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:21:33',0,NULL,NULL,NULL,'d391dfcc-9b61-11e0-a2a8-544249e49b14'),(15,25,73,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 19:21:58',0,NULL,NULL,NULL,'e2a2808e-9b61-11e0-a2a8-544249e49b14'),(17,26,72,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 20:16:15',0,NULL,NULL,NULL,'779820de-9b69-11e0-a2a8-544249e49b14'),(18,27,72,1.5,3,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 20:16:41',0,NULL,NULL,NULL,'87015518-9b69-11e0-a2a8-544249e49b14'),(19,28,72,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 20:16:53',0,NULL,NULL,NULL,'8e870f12-9b69-11e0-a2a8-544249e49b14'),(20,29,72,2.5,5,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 20:17:01',0,NULL,NULL,NULL,'9317b28e-9b69-11e0-a2a8-544249e49b14'),(21,30,72,3,6,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'3 tab(s) TWICE A DAY (BD)',1,'2011-06-20 20:17:10',0,NULL,NULL,NULL,'984b22ea-9b69-11e0-a2a8-544249e49b14'),(22,31,613,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 20:17:19',0,NULL,NULL,NULL,'9e04fc9c-9b69-11e0-a2a8-544249e49b14'),(23,32,731,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:05:02',0,NULL,NULL,NULL,'4849d91a-9b70-11e0-a2a8-544249e49b14'),(24,33,731,1.5,3,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:05:07',0,NULL,NULL,NULL,'4b6e7920-9b70-11e0-a2a8-544249e49b14'),(25,34,731,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:05:14',0,NULL,NULL,NULL,'4f78aab8-9b70-11e0-a2a8-544249e49b14'),(26,35,731,2.5,5,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:05:19',0,NULL,NULL,NULL,'529da662-9b70-11e0-a2a8-544249e49b14'),(27,36,731,3,6,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'3 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:05:24',0,NULL,NULL,NULL,'553b4398-9b70-11e0-a2a8-544249e49b14'),(28,37,730,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:05:29',0,NULL,NULL,NULL,'589e9fb2-9b70-11e0-a2a8-544249e49b14'),(29,38,736,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:08:33',0,NULL,NULL,NULL,'c6413d54-9b70-11e0-a2a8-544249e49b14'),(30,39,736,2.5,5,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:08:48',0,NULL,NULL,NULL,'cf10797c-9b70-11e0-a2a8-544249e49b14'),(31,40,736,3,6,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'3 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:09:02',0,NULL,NULL,NULL,'d73a6360-9b70-11e0-a2a8-544249e49b14'),(32,41,737,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:09:24',0,NULL,NULL,NULL,'e4a77826-9b70-11e0-a2a8-544249e49b14'),(33,42,737,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:09:34',0,NULL,NULL,NULL,'ea6a2952-9b70-11e0-a2a8-544249e49b14'),(34,38,30,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:11:41',0,NULL,NULL,NULL,'3603ba36-9b71-11e0-a2a8-544249e49b14'),(35,39,30,1.5,1.5,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1.5 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:12:46',0,NULL,NULL,NULL,'5d1608ea-9b71-11e0-a2a8-544249e49b14'),(36,40,30,1.5,1.5,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1.5 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:13:07',0,NULL,NULL,NULL,'697cb480-9b71-11e0-a2a8-544249e49b14'),(37,41,30,2,2,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'2 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:13:36',0,NULL,NULL,NULL,'7b016a84-9b71-11e0-a2a8-544249e49b14'),(38,42,11,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:14:55',0,NULL,NULL,NULL,'a99a2674-9b71-11e0-a2a8-544249e49b14'),(39,43,735,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:22:09',0,NULL,NULL,NULL,'ac8b3e80-9b72-11e0-a2a8-544249e49b14'),(40,44,735,2.5,5,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2.5 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:22:59',0,NULL,NULL,NULL,'ca6853f2-9b72-11e0-a2a8-544249e49b14'),(41,45,735,3,6,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'3 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:23:13',0,NULL,NULL,NULL,'d26327bc-9b72-11e0-a2a8-544249e49b14'),(42,46,39,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:23:42',0,NULL,NULL,NULL,'e3e1ee42-9b72-11e0-a2a8-544249e49b14'),(43,47,39,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:23:51',0,NULL,NULL,NULL,'e9921c90-9b72-11e0-a2a8-544249e49b14'),(44,43,30,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:24:34',0,NULL,NULL,NULL,'02b48bd6-9b73-11e0-a2a8-544249e49b14'),(45,44,30,1.5,1.5,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1.5 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:25:03',0,NULL,NULL,NULL,'14415104-9b73-11e0-a2a8-544249e49b14'),(46,45,30,1.5,1.5,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1.5 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:25:14',0,NULL,NULL,NULL,'1ad02608-9b73-11e0-a2a8-544249e49b14'),(47,46,30,2,2,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'2 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:25:26',0,NULL,NULL,NULL,'223af5b2-9b73-11e0-a2a8-544249e49b14'),(48,47,11,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:27:04',0,NULL,NULL,NULL,'5c4d3f62-9b73-11e0-a2a8-544249e49b14'),(49,48,734,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:48:22',0,NULL,NULL,NULL,'56163b8c-9b76-11e0-a2a8-544249e49b14'),(50,49,733,1,1,'tab(s)','IN THE EVENING (QPM)',0,0,NULL,'1 tab(s) IN THE EVENING (QPM)',1,'2011-06-20 21:56:18',0,NULL,NULL,NULL,'71b5c6d6-9b77-11e0-a2a8-544249e49b14'),(51,49,73,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 21:57:01',0,NULL,NULL,NULL,'8b792b62-9b77-11e0-a2a8-544249e49b14'),(52,50,39,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-20 22:01:39',0,NULL,NULL,NULL,'316a6b94-9b78-11e0-a2a8-544249e49b14'),(53,50,73,2,4,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'2 tab(s) TWICE A DAY (BD)',1,'2011-06-20 22:01:51',0,NULL,NULL,NULL,'38797d76-9b78-11e0-a2a8-544249e49b14'),(54,51,297,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-22 17:30:25',0,NULL,NULL,NULL,'8d4a0c18-9ce4-11e0-96f5-544249e49b14'),(55,52,24,1,2,'tab(s)','TWICE A DAY (BD)',0,0,NULL,'1 tab(s) TWICE A DAY (BD)',1,'2011-06-22 17:31:04',0,NULL,NULL,NULL,'a47c7dd0-9ce4-11e0-96f5-544249e49b14');
/*!40000 ALTER TABLE `regimen_drug_order` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-06-22 18:07:48
