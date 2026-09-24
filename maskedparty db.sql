-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Sep 24, 2026 at 10:17 AM
-- Server version: 8.0.42-cll-lve
-- PHP Version: 8.4.22

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `maskedpa_maskedparty`
--

-- --------------------------------------------------------

--
-- Table structure for table `call_minute_costs`
--

CREATE TABLE `call_minute_costs` (
  `id` int NOT NULL,
  `minutes` int NOT NULL,
  `coin_cost` decimal(10,2) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `display_order` int NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `call_minute_costs`
--

INSERT INTO `call_minute_costs` (`id`, `minutes`, `coin_cost`, `is_active`, `display_order`, `created_at`, `updated_at`) VALUES
(1, 5, 30.00, 1, 0, '2026-08-03 09:26:14', '2026-08-03 09:28:50'),
(2, 10, 60.00, 1, 0, '2026-08-03 09:29:26', '2026-08-03 09:29:26'),
(3, 15, 90.00, 1, 0, '2026-08-03 09:29:40', '2026-08-03 09:29:40'),
(4, 20, 120.00, 1, 0, '2026-08-03 09:29:55', '2026-08-03 09:29:55');

-- --------------------------------------------------------

--
-- Table structure for table `call_requests`
--

CREATE TABLE `call_requests` (
  `id` int NOT NULL,
  `client_id` int NOT NULL,
  `influencer_id` int NOT NULL,
  `status` enum('pending','accepted','rejected','expired') DEFAULT 'pending',
  `billing_mode` enum('standard','payg_minute','payg_second') NOT NULL DEFAULT 'standard',
  `meeting_id` varchar(255) DEFAULT NULL,
  `meeting_token` text,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `call_requests`
--

INSERT INTO `call_requests` (`id`, `client_id`, `influencer_id`, `status`, `billing_mode`, `meeting_id`, `meeting_token`, `expires_at`, `created_at`) VALUES
(1, 2, 1, 'expired', 'standard', NULL, NULL, '2026-07-24 03:14:39', '2026-07-24 07:13:39'),
(2, 2, 1, 'expired', 'standard', NULL, NULL, '2026-07-24 03:15:01', '2026-07-24 07:14:01'),
(3, 2, 1, 'expired', 'standard', NULL, NULL, '2026-07-24 03:27:53', '2026-07-24 07:26:53'),
(4, 2, 1, 'expired', 'standard', NULL, NULL, '2026-07-24 03:28:58', '2026-07-24 07:27:58'),
(5, 2, 1, 'expired', 'standard', NULL, NULL, '2026-07-24 03:30:07', '2026-07-24 07:29:07'),
(6, 2, 1, 'expired', 'standard', 'mock_meeting_6a63186098320', 'mock_token_00d7a9af8025c90c48d871bbd6c74107', '2026-07-24 07:48:33', '2026-07-24 07:46:33'),
(7, 2, 1, 'rejected', 'standard', NULL, NULL, '2026-07-24 09:04:56', '2026-07-24 09:02:56'),
(8, 2, 1, 'expired', 'standard', 'mock_meeting_6a632a70e7b54', 'mock_token_1e840c7d2253b0aded6fe3e470e8649c', '2026-07-24 09:05:36', '2026-07-24 09:03:36'),
(9, 2, 1, 'accepted', 'standard', 'mock_meeting_6a632d7353bec', 'mock_token_51006523c61401ab489e430b13d68d4b', '2026-07-24 09:18:12', '2026-07-24 09:16:12'),
(10, 2, 1, 'rejected', 'standard', NULL, NULL, '2026-07-24 09:20:24', '2026-07-24 09:18:24'),
(11, 2, 1, 'accepted', 'standard', 'mock_meeting_6a6330af8bc1b', 'mock_token_a2019ae6a2481642208ee9b9ca2c1cad', '2026-07-24 09:32:14', '2026-07-24 09:30:14'),
(12, 2, 1, 'pending', 'standard', NULL, NULL, '2026-07-24 09:49:46', '2026-07-24 09:47:46'),
(13, 2, 1, 'pending', 'standard', NULL, NULL, '2026-07-24 10:07:20', '2026-07-24 10:05:20'),
(14, 2, 1, 'accepted', 'standard', '2gew-b7uc-0tab', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjJnZXctYjd1Yy0wdGFiIiwicGFydGljaXBhbnRJZCI6IjZhNjMzYWY0ZWZkYWIiLCJpYXQiOjE3ODQ4ODgwNTIsImV4cCI6MTc4NDk3NDQ1Mn0.wPycVlzENfiuXlI-O-5tHfJN7oPQ3unuThCEdU0RWmc', '2026-07-24 10:14:31', '2026-07-24 10:12:31'),
(15, 2, 1, 'accepted', 'standard', 'sw76-dmk3-tulm', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InN3NzYtZG1rMy10dWxtIiwicGFydGljaXBhbnRJZCI6IjZhNjMzYjA1ODliZjQiLCJpYXQiOjE3ODQ4ODgwNjksImV4cCI6MTc4NDk3NDQ2OX0.IJi2bI0x9HAPcY676c82kHEv3Hb4fPLiK9xImVBWTTA', '2026-07-24 10:16:21', '2026-07-24 10:14:21'),
(16, 2, 1, 'accepted', 'standard', 'mijy-g0n5-sgl9', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Im1panktZzBuNS1zZ2w5IiwicGFydGljaXBhbnRJZCI6IjZhNjMzYjMzZGQ2NTIiLCJpYXQiOjE3ODQ4ODgxMTUsImV4cCI6MTc4NDk3NDUxNX0.IhFJpx4CCf1e7NY-cefabtyggdshISsul74OITLUlHM', '2026-07-24 10:17:07', '2026-07-24 10:15:07'),
(17, 2, 1, 'accepted', 'standard', '2ncb-z1gw-6uka', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjJuY2ItejFndy02dWthIiwicGFydGljaXBhbnRJZCI6IjZhNjMzYmQ2ZDUyM2EiLCJpYXQiOjE3ODQ4ODgyNzgsImV4cCI6MTc4NDk3NDY3OH0.VDGektJczrxwpbFeS0R6WVhpPH2PiizaFvxohBWinh0', '2026-07-24 10:19:50', '2026-07-24 10:17:50'),
(18, 2, 1, 'accepted', 'standard', 'j8j1-xmlm-7baj', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Imo4ajEteG1sbS03YmFqIiwiaWF0IjoxNzg0ODg4NTYzLCJleHAiOjE3ODQ5NzQ5NjN9.in1TbHNeBU8Kg8RLiFXruRm0xQ9AtDioK5D2a0bcR_U', '2026-07-24 10:24:38', '2026-07-24 10:22:38'),
(19, 2, 1, 'accepted', 'standard', 'y9xo-0xfx-f4lp', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Ink5eG8tMHhmeC1mNGxwIiwiaWF0IjoxNzg0ODg5MzE4LCJleHAiOjE3ODQ5NzU3MTh9.134NNY7dHXWlqiJEcpJC9Cr_uvO7zbH-tQiSDQZ-SKA', '2026-07-24 10:37:11', '2026-07-24 10:35:11'),
(20, 2, 1, 'accepted', 'standard', '2v2o-xmz9-cnmh', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjJ2Mm8teG16OS1jbm1oIiwiaWF0IjoxNzg0ODk0ODQ4LCJleHAiOjE3ODQ5ODEyNDh9.JuL5EKA6WUt9azqp6AI6pkkJ_seaAPVisMUWM9tUha4', '2026-07-24 12:09:20', '2026-07-24 12:07:20'),
(21, 2, 1, 'accepted', 'standard', 'jijv-84ig-hgej', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImppanYtODRpZy1oZ2VqIiwiaWF0IjoxNzg0ODk1MDEzLCJleHAiOjE3ODQ5ODE0MTN9.Al6VntGO7J9xMJfZRUKgR96gdmgJ1lutpoPwRwGQjnY', '2026-07-24 12:12:05', '2026-07-24 12:10:05'),
(22, 2, 1, 'accepted', 'standard', 'koey-z7z4-p5y1', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImtvZXktejd6NC1wNXkxIiwiaWF0IjoxNzg0ODk1MTI2LCJleHAiOjE3ODQ5ODE1MjZ9.misnqZj1LS7qpPSKxI210K3vRgU4N4F8Wk0-DYVsmsM', '2026-07-24 12:14:00', '2026-07-24 12:12:00'),
(23, 2, 1, 'accepted', 'standard', '8djx-nltr-7hky', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Ijhkangtbmx0ci03aGt5IiwiaWF0IjoxNzg0ODk1OTA3LCJleHAiOjE3ODQ5ODIzMDd9.hJCEiTPjFTwPcEjczYF2FWe0e9gpvBetq4HcmlRs2Mg', '2026-07-24 12:26:53', '2026-07-24 12:24:53'),
(24, 2, 1, 'accepted', 'standard', 'gb2j-q4cv-ec5s', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImdiMmotcTRjdi1lYzVzIiwiaWF0IjoxNzg0ODk2MDg0LCJleHAiOjE3ODQ5ODI0ODR9.8JJR38gM7JtjAiHB-HkwVLbTSBxvQE2E9PayY0a03OQ', '2026-07-24 12:29:34', '2026-07-24 12:27:34'),
(25, 2, 1, 'accepted', 'standard', 'cbqw-ycd0-12i8', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImNicXcteWNkMC0xMmk4IiwiaWF0IjoxNzg0ODk4MDU2LCJleHAiOjE3ODQ5ODQ0NTZ9.ATqmTrqSoCgA32dJiSsPVN_DsKNfsd584nr2ef2gIDI', '2026-07-24 13:02:40', '2026-07-24 13:00:40'),
(26, 2, 1, 'accepted', 'standard', 'jyy4-qm3k-xiyv', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Imp5eTQtcW0zay14aXl2IiwiaWF0IjoxNzg0ODk4MTUyLCJleHAiOjE3ODQ5ODQ1NTJ9.VomtBfMtAUGkfVlK0MAsI5GdERE_Eqsb8aKJr9BM9Ao', '2026-07-24 13:04:26', '2026-07-24 13:02:26'),
(27, 2, 1, 'accepted', 'standard', '62gh-1qm4-zhln', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjYyZ2gtMXFtNC16aGxuIiwiaWF0IjoxNzg0ODk4MjQyLCJleHAiOjE3ODQ5ODQ2NDJ9.VifXPs6snP5iSxYOwTDNs-WJGFcBzt_x0oqEH2A5zaU', '2026-07-24 13:05:58', '2026-07-24 13:03:58'),
(28, 2, 1, 'accepted', 'standard', 'k8bm-xh59-a53j', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Ims4Ym0teGg1OS1hNTNqIiwiaWF0IjoxNzg0ODk4Mzg3LCJleHAiOjE3ODQ5ODQ3ODd9.IJ24Sald7RQH-_jwYhXxmadaWSOkWy7zhhxXjNSr6zA', '2026-07-24 13:08:20', '2026-07-24 13:06:20'),
(29, 2, 1, 'accepted', 'standard', 'fm96-x8bp-ypql', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImZtOTYteDhicC15cHFsIiwiaWF0IjoxNzg0ODk5MjUyLCJleHAiOjE3ODQ5ODU2NTJ9.kQyrVmWSr0g1Fw5jLSEJDbM1YSGi7MOtUkqpJyEnS58', '2026-07-24 13:22:35', '2026-07-24 13:20:35'),
(30, 2, 1, 'accepted', 'standard', 'w0ba-1ig9-l5q1', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IncwYmEtMWlnOS1sNXExIiwiaWF0IjoxNzg1MTQyMDQ3LCJleHAiOjE3ODUyMjg0NDd9.bWbd43cDE-9PuDY9nuzSDmFOcXQTkQksyHK7R9oMg6U', '2026-07-27 08:49:05', '2026-07-27 08:47:05'),
(31, 2, 1, 'accepted', 'standard', 'k2g7-ud11-fd30', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImsyZzctdWQxMS1mZDMwIiwiaWF0IjoxNzg1MTQyMzE5LCJleHAiOjE3ODUyMjg3MTl9.Kg1uXT-wJB1IxJYzW6kWLf9ToikJ6lpKQ6_EfVxuxOw', '2026-07-27 08:52:38', '2026-07-27 08:50:38'),
(32, 2, 1, 'accepted', 'standard', '2fdq-c41l-iium', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjJmZHEtYzQxbC1paXVtIiwiaWF0IjoxNzg1MTQ1MDY0LCJleHAiOjE3ODUyMzE0NjR9.wSWLANVZ3Ut9sIda6SR-sfLdajRW-twlVncVmUQ6dxU', '2026-07-27 09:39:35', '2026-07-27 09:37:35'),
(33, 2, 1, 'accepted', 'standard', 'flon-3pvb-h5co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImZsb24tM3B2Yi1oNWNvIiwiaWF0IjoxNzg1MTQ1OTUyLCJleHAiOjE3ODUyMzIzNTJ9.NAzbtdmtWxKg1SFMI-zEVcz34sArEp1kYw4XYNurMBQ', '2026-07-27 09:54:19', '2026-07-27 09:52:19'),
(34, 2, 1, 'accepted', 'standard', 'hkgi-sy4i-su7v', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImhrZ2ktc3k0aS1zdTd2IiwiaWF0IjoxNzg1MTUwODU4LCJleHAiOjE3ODUyMzcyNTh9.swhk0my7jnEj1-NRZAtc8pJYPTVdBqfEJm-TXHoCKGI', '2026-07-27 11:16:10', '2026-07-27 11:14:10'),
(35, 2, 1, 'accepted', 'standard', 'y40m-ie7h-cbt4', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Ink0MG0taWU3aC1jYnQ0IiwiaWF0IjoxNzg1MTUxNTIyLCJleHAiOjE3ODUyMzc5MjJ9.RAGIXWokOK-y4EOY-zs3AlsKHgpiQTybdQRjj1kep9E', '2026-07-27 11:27:11', '2026-07-27 11:25:11'),
(36, 2, 1, 'accepted', 'standard', 'aolu-yve5-26cg', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImFvbHUteXZlNS0yNmNnIiwiaWF0IjoxNzg1MTUyMzIzLCJleHAiOjE3ODUyMzg3MjN9.3pRga_o_wcvsLJD1Fs6rezTTStK1dgZFagKLmPLN7jk', '2026-07-27 11:40:35', '2026-07-27 11:38:35'),
(37, 2, 1, 'accepted', 'standard', 'pl4s-lglq-2ydb', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InBsNHMtbGdscS0yeWRiIiwiaWF0IjoxNzg1MTUyNTg5LCJleHAiOjE3ODUyMzg5ODl9.yGz6Y-skSAsn98KJMyKM6gMDhVuw8XcLYdNTBtfbG3o', '2026-07-27 11:44:50', '2026-07-27 11:42:50'),
(38, 2, 1, 'accepted', 'standard', 'tfa6-f0gr-l1ct', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InRmYTYtZjBnci1sMWN0IiwiaWF0IjoxNzg1NTMwNjI5LCJleHAiOjE3ODU2MTcwMjl9.8COoyQ-dGtZEc8senNXyd16Dbz4E0Dxod1QmwSkU9eQ', '2026-07-31 20:45:20', '2026-07-31 20:43:20'),
(39, 2, 1, 'accepted', 'standard', '78kf-j0wf-egrw', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Ijc4a2YtajB3Zi1lZ3J3IiwiaWF0IjoxNzg1NTMyNDU2LCJleHAiOjE3ODU2MTg4NTZ9.mq8lLaYjzPF_XPH4R1mxVI1QQEsevw_rO8yJrRl3S1Q', '2026-07-31 21:16:09', '2026-07-31 21:14:09'),
(40, 2, 1, 'accepted', 'standard', 'z774-kfmc-2mkd', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Ino3NzQta2ZtYy0ybWtkIiwiaWF0IjoxNzg1NTMzODQzLCJleHAiOjE3ODU2MjAyNDN9.Gsq-CHdQow2Ra4akhWoJgt7-_GeYRWuNFXAEygpZNeE', '2026-07-31 21:39:16', '2026-07-31 21:37:16'),
(41, 2, 1, 'accepted', 'standard', 'n6pt-1jtf-a2jg', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Im42cHQtMWp0Zi1hMmpnIiwiaWF0IjoxNzg1NTM1NDU0LCJleHAiOjE3ODU2MjE4NTR9._Wpq_ViBsvzEOc7WRrtUFGMBi2xp-FygsNbLhIK2Ztc', '2026-07-31 22:06:06', '2026-07-31 22:04:06'),
(42, 2, 1, 'accepted', 'standard', 'v7xb-wqc1-ddkj', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InY3eGItd3FjMS1kZGtqIiwiaWF0IjoxNzg1NTM4MjUwLCJleHAiOjE3ODU2MjQ2NTB9.wVG4C-MeOsk6x1fxOvrlZ_3mlffdZlOIAR9u7d2vQ84', '2026-07-31 22:52:40', '2026-07-31 22:50:40'),
(43, 2, 1, 'accepted', 'standard', 'waqb-tgi1-mc5a', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IndhcWItdGdpMS1tYzVhIiwiaWF0IjoxNzg1NTM5NDIxLCJleHAiOjE3ODU2MjU4MjF9.vyJAo8prq3F_vgnO-KPhX0MyJu3Z_MbDXOT8Qt9fOns', '2026-07-31 23:12:17', '2026-07-31 23:10:17'),
(44, 2, 1, 'accepted', 'standard', 'rhnc-ed3i-tjc2', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InJobmMtZWQzaS10amMyIiwiaWF0IjoxNzg1NTM5NzUyLCJleHAiOjE3ODU2MjYxNTJ9.GTGoKoUfNXm5eDvwM6_h73n3tOpfdZ66AhpeXGPqTWk', '2026-07-31 23:17:45', '2026-07-31 23:15:45'),
(45, 2, 1, 'accepted', 'standard', 'vguy-o0bu-9or4', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InZndXktbzBidS05b3I0IiwiaWF0IjoxNzg1NTQwNDQyLCJleHAiOjE3ODU2MjY4NDJ9.G-0Rlu_angCI8lADoZrVzuEVTu5RbyZQW4KFnomBJs8', '2026-07-31 23:29:05', '2026-07-31 23:27:05'),
(46, 2, 1, 'accepted', 'standard', 'su5p-52u8-337v', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InN1NXAtNTJ1OC0zMzd2IiwiaWF0IjoxNzg1NTQwNjk0LCJleHAiOjE3ODU2MjcwOTR9.BFrC_NBYLBbn5tQZnWWplnZaDBCOCrrY-PMUcHPWxE4', '2026-07-31 23:33:29', '2026-07-31 23:31:29'),
(47, 2, 1, 'accepted', 'standard', '658y-6swo-f6x7', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjY1OHktNnN3by1mNng3IiwiaWF0IjoxNzg1NTQxNzE3LCJleHAiOjE3ODU2MjgxMTd9.GQjJpUX6rsA7DLC0rCAZ1THdRjnq8ZpzKa1K_1nYnyI', '2026-07-31 23:50:21', '2026-07-31 23:48:21'),
(48, 2, 1, 'accepted', 'standard', '34sv-dq2n-le6e', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjM0c3YtZHEybi1sZTZlIiwiaWF0IjoxNzg1NTQyMDM2LCJleHAiOjE3ODU2Mjg0MzZ9.Fsg_a20Jlkec-P8ugGvSs2xAbbixbXOHclk1WH_6-mk', '2026-07-31 23:55:30', '2026-07-31 23:53:30'),
(49, 2, 1, 'accepted', 'standard', '39qi-fipq-56zl', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjM5cWktZmlwcS01NnpsIiwiaWF0IjoxNzg1NTQyNjE5LCJleHAiOjE3ODU2MjkwMTl9.jmxWNQPvrVdoP_gsVMlCI_AysoRVvtPllSjVWvLvdhA', '2026-08-01 00:05:35', '2026-08-01 00:03:35'),
(50, 2, 1, 'accepted', 'standard', 'six7-y9qv-t2v3', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InNpeDcteTlxdi10MnYzIiwiaWF0IjoxNzg1NTQzMDA1LCJleHAiOjE3ODU2Mjk0MDV9.6AK7rlJkAh1brM0Tw6tGMrwo52apbALg7Ht3Eks5U9U', '2026-08-01 00:11:56', '2026-08-01 00:09:56'),
(51, 2, 1, 'accepted', 'standard', 'ennx-bqxl-i7am', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImVubngtYnF4bC1pN2FtIiwiaWF0IjoxNzg1NTQ1OTYzLCJleHAiOjE3ODU2MzIzNjN9.scmYxZP06EFH6K5qkF4zRHZokE5SCFzIquaRdpPW33o', '2026-08-01 01:01:13', '2026-08-01 00:59:13'),
(52, 2, 1, 'accepted', 'standard', 'q4mr-3unk-kkf0', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InE0bXItM3Vuay1ra2YwIiwiaWF0IjoxNzg1NzUwNTA0LCJleHAiOjE3ODU4MzY5MDR9.Ejbg5BacU9IlDN0XPyzbyPeDS3hLkvhDhQp8LafWo6E', '2026-08-03 09:49:44', '2026-08-03 09:47:44'),
(53, 2, 1, 'rejected', 'standard', NULL, NULL, '2026-08-03 13:14:18', '2026-08-03 13:12:18'),
(54, 2, 1, 'accepted', 'standard', 'r2k7-h62j-974n', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InIyazctaDYyai05NzRuIiwiaWF0IjoxNzg1NzYzNDYyLCJleHAiOjE3ODU4NDk4NjJ9.ji-X_kE54gAvui0ox7Yeun9f40bscZ9WC_4yKlIeua4', '2026-08-03 13:24:25', '2026-08-03 13:22:25'),
(55, 2, 1, 'accepted', 'standard', 'ry62-xora-tkh4', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InJ5NjIteG9yYS10a2g0IiwiaWF0IjoxNzg1NzkyNzAwLCJleHAiOjE3ODU4NzkxMDB9.8Dr_cQDWrNts36by_goMH3Mpcdm-oZULey--hAb4iZo', '2026-08-03 21:32:41', '2026-08-03 21:30:41'),
(56, 2, 1, 'rejected', 'standard', NULL, NULL, '2026-08-03 21:51:41', '2026-08-03 21:49:41'),
(57, 2, 1, 'pending', 'standard', NULL, NULL, '2026-08-03 21:53:49', '2026-08-03 21:51:49'),
(58, 2, 1, 'rejected', 'standard', NULL, NULL, '2026-08-04 16:30:32', '2026-08-04 16:28:32'),
(59, 2, 1, 'rejected', 'standard', NULL, NULL, '2026-08-04 16:34:11', '2026-08-04 16:32:11'),
(60, 2, 1, 'rejected', 'standard', NULL, NULL, '2026-08-04 16:36:57', '2026-08-04 16:34:57'),
(61, 2, 1, 'rejected', 'standard', NULL, NULL, '2026-08-04 17:08:19', '2026-08-04 17:06:19'),
(62, 2, 1, 'accepted', 'standard', 'jiu3-mpa3-scas', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImppdTMtbXBhMy1zY2FzIiwiaWF0IjoxNzg2MTAxNTYxLCJleHAiOjE3ODYxODc5NjF9.fYJuOEwjSVJc4N8zOU7U5svzRNyZjqoRZUZMEUpstPQ', '2026-08-07 11:21:02', '2026-08-07 11:19:02'),
(63, 2, 1, 'accepted', 'standard', 'gftz-74qv-z59h', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImdmdHotNzRxdi16NTloIiwiaWF0IjoxNzg2MTA0NjE4LCJleHAiOjE3ODYxOTEwMTh9.U1Bi4iAag2tC8pWVAS9_tAz5Yhn1AZpHACGcI1NVUU4', '2026-08-07 12:12:00', '2026-08-07 12:10:00'),
(64, 2, 1, 'accepted', 'standard', 'ysbk-ezu3-j1jd', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InlzYmstZXp1My1qMWpkIiwiaWF0IjoxNzg2MTA2MzgzLCJleHAiOjE3ODYxOTI3ODN9.eFnW346r8qrVuwJaNh4eylMLl9czL56M3RXAlciTndA', '2026-08-07 12:41:34', '2026-08-07 12:39:34'),
(65, 2, 1, 'accepted', 'standard', 'dx2t-721b-e9my', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImR4MnQtNzIxYi1lOW15IiwiaWF0IjoxNzg3NTc1NjE5LCJleHAiOjE3ODc2NjIwMTl9.AbiKtzjDHlDSs0CXliQV-O9dTA7Rtl_gfDbBfzrhWqE', '2026-08-24 12:48:46', '2026-08-24 12:46:46'),
(66, 2, 1, 'accepted', 'payg_minute', 'n6g6-bjg3-lsfc', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Im42ZzYtYmpnMy1sc2ZjIiwiaWF0IjoxNzg3NTc2NTY5LCJleHAiOjE3ODc2NjI5Njl9.Ud5Hp2kS3E7gmnSCyf3dd2fNrsNuGWv6iHGcPACOnqY', '2026-08-24 13:04:38', '2026-08-24 13:02:38'),
(67, 2, 1, 'accepted', 'payg_second', 'ke82-apfq-v7lo', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImtlODItYXBmcS12N2xvIiwiaWF0IjoxNzg3NjE5OTQwLCJleHAiOjE3ODc3MDYzNDB9.65MkyCzw6WFWT9MdZWpJ99dTNudsnC5Hg1KM2iOlE1c', '2026-08-25 01:07:28', '2026-08-25 01:05:28'),
(68, 2, 1, 'accepted', 'payg_minute', 'pu3j-favc-wdrz', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InB1M2otZmF2Yy13ZHJ6IiwiaWF0IjoxNzg3NjIwMTA4LCJleHAiOjE3ODc3MDY1MDh9.jdV7dyUIU3MquEKF6nF3Hs2LsxqMP8bgtoDS-YOO_hA', '2026-08-25 01:10:21', '2026-08-25 01:08:21'),
(69, 2, 1, 'accepted', 'payg_second', 'np0f-57i5-kx11', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Im5wMGYtNTdpNS1reDExIiwiaWF0IjoxNzg3NjIwNTU0LCJleHAiOjE3ODc3MDY5NTR9.lDP3OoAQ1w_aK8jXzneRmBVI3Sgi8F-q_OpHSe2jFmE', '2026-08-25 01:17:43', '2026-08-25 01:15:43'),
(70, 2, 9, 'accepted', 'payg_second', 'ba7v-gg1t-mhpu', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImJhN3YtZ2cxdC1taHB1IiwiaWF0IjoxNzg4NTk5ODQ3LCJleHAiOjE3ODg2ODYyNDd9.eoFUifnHNR_JZsgk-2EbhGZN_zdwy1uorQXLsxjbgOM', '2026-09-05 09:19:04', '2026-09-05 09:17:04');

-- --------------------------------------------------------

--
-- Table structure for table `call_tracking`
--

CREATE TABLE `call_tracking` (
  `id` int UNSIGNED NOT NULL,
  `call_id` int NOT NULL,
  `influencer_id` int NOT NULL,
  `influencer_name` varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `client_id` int NOT NULL,
  `client_name` varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `ended_by_role` enum('client','influencer','system') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `ended_by_user_id` int DEFAULT NULL,
  `ended_by_name` varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `duration_seconds` int UNSIGNED NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `call_tracking`
--

INSERT INTO `call_tracking` (`id`, `call_id`, `influencer_id`, `influencer_name`, `client_id`, `client_name`, `ended_by_role`, `ended_by_user_id`, `ended_by_name`, `duration_seconds`, `created_at`) VALUES
(1, 26, 1, 'Ochoyo Moses', 2, 'James', 'client', 2, 'James', 76, '2026-07-31 20:45:05'),
(2, 27, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 140, '2026-07-31 21:16:36'),
(3, 28, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 71, '2026-07-31 21:38:35'),
(4, 29, 1, 'Ochoyo Moses', 2, 'James', 'client', 2, 'James', 52, '2026-07-31 22:05:07'),
(5, 30, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 109, '2026-07-31 22:52:39'),
(6, 31, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 39, '2026-07-31 23:11:00'),
(7, 32, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 104, '2026-07-31 23:17:37'),
(8, 33, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 76, '2026-07-31 23:28:40'),
(9, 34, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 46, '2026-07-31 23:32:20'),
(10, 35, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 63, '2026-07-31 23:49:40'),
(11, 36, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 60, '2026-07-31 23:54:56'),
(12, 37, 1, 'Ochoyo Moses', 2, 'James', 'client', 2, 'James', 30, '2026-08-01 00:04:10'),
(13, 38, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 146, '2026-08-01 00:12:33'),
(14, 39, 1, 'Ochoyo Moses', 2, 'James', 'client', 2, 'James', 27, '2026-08-01 00:59:51'),
(15, 40, 1, 'Ochoyo Moses', 2, 'James', 'client', 2, 'James', 108, '2026-08-03 09:50:14'),
(16, 41, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 49, '2026-08-03 13:25:12'),
(17, 42, 1, 'Ochoyo Moses', 2, 'James', 'system', NULL, 'System (call time expired)', 72, '2026-08-03 21:32:54'),
(18, 43, 1, 'Ochoyo Moses', 2, 'James', 'client', 2, 'James', 150, '2026-08-07 11:21:51'),
(19, 44, 1, 'Ochoyo Moses', 2, 'James', 'client', 2, 'James', 82, '2026-08-07 12:11:41'),
(20, 45, 1, 'Ochoyo Moses', 2, 'James', 'client', 2, 'James', 45, '2026-08-07 12:40:29'),
(21, 46, 1, 'Ochoyo Moses', 2, 'James', 'client', 2, 'James', 114, '2026-08-24 12:48:53'),
(22, 47, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 80, '2026-08-24 13:04:10'),
(23, 48, 1, 'Ochoyo Moses', 2, 'James', 'influencer', 1, 'Ochoyo Moses', 95, '2026-08-25 01:07:16'),
(24, 49, 1, 'Ochoyo Moses', 2, 'James', 'client', 2, 'James', 62, '2026-08-25 01:09:30'),
(25, 50, 1, 'Ochoyo Moses', 2, 'James', 'client', 2, 'James', 61, '2026-08-25 01:16:56'),
(26, 51, 9, 'Amelia Lee', 2, 'James', 'influencer', 9, 'Amelia Lee', 141, '2026-09-05 09:19:48');

-- --------------------------------------------------------

--
-- Table structure for table `chat_messages`
--

CREATE TABLE `chat_messages` (
  `id` int NOT NULL,
  `sender_id` int NOT NULL,
  `receiver_id` int NOT NULL,
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `chat_messages`
--

INSERT INTO `chat_messages` (`id`, `sender_id`, `receiver_id`, `message`, `is_read`, `created_at`) VALUES
(1, 2, 1, 'hi', 1, '2026-08-01 01:16:13'),
(2, 1, 2, 'how are you doing', 1, '2026-08-01 01:19:12'),
(3, 2, 1, 'fine', 1, '2026-08-01 01:21:30'),
(4, 1, 2, 'good', 1, '2026-08-01 01:21:47'),
(5, 1, 2, '💪', 1, '2026-08-01 01:24:01'),
(6, 2, 1, '🥰', 1, '2026-08-01 01:24:11'),
(7, 1, 2, 'nice', 1, '2026-08-01 01:26:10'),
(8, 2, 1, '😂', 1, '2026-08-01 01:26:24'),
(9, 1, 2, 'amazing', 1, '2026-08-01 01:26:36'),
(10, 1, 2, '[BLOCKED]', 1, '2026-08-01 01:34:08'),
(11, 1, 2, '[BLOCKED]', 1, '2026-08-01 01:34:20'),
(12, 1, 2, 'zero nine zero', 1, '2026-08-01 01:34:38'),
(13, 2, 1, 'good', 1, '2026-08-01 01:41:52'),
(14, 1, 2, 'thank you', 1, '2026-08-22 07:32:43');

-- --------------------------------------------------------

--
-- Table structure for table `coin_packages`
--

CREATE TABLE `coin_packages` (
  `id` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `currency` varchar(10) DEFAULT 'GBP',
  `coins` int NOT NULL,
  `minutes` int NOT NULL,
  `is_popular` tinyint(1) DEFAULT '0',
  `is_best_value` tinyint(1) DEFAULT '0',
  `display_order` int DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `coin_packages`
--

INSERT INTO `coin_packages` (`id`, `name`, `price`, `currency`, `coins`, `minutes`, `is_popular`, `is_best_value`, `display_order`, `is_active`) VALUES
(1, '5 Coins', 10.00, 'GBP', 5, 5, 0, 0, 1, 1),
(2, '10 Coins', 20.00, 'GBP', 10, 10, 0, 0, 2, 1),
(3, '25 Coins', 40.00, 'GBP', 25, 15, 0, 0, 3, 1),
(4, '40 Coins', 60.00, 'GBP', 40, 20, 0, 0, 4, 1),
(5, '65 Coins', 80.00, 'GBP', 65, 25, 0, 0, 5, 1),
(6, '90 Coins', 100.00, 'GBP', 90, 30, 0, 0, 6, 1),
(7, '110 Coins', 120.00, 'GBP', 110, 35, 0, 0, 7, 1),
(8, '135 Coins', 140.00, 'GBP', 135, 40, 0, 0, 8, 1),
(9, '150 Coins', 160.00, 'GBP', 150, 45, 0, 0, 9, 1),
(10, '175 Coins', 180.00, 'GBP', 175, 50, 0, 0, 10, 1),
(11, '200 Coins', 200.00, 'GBP', 200, 60, 0, 0, 11, 1);

-- --------------------------------------------------------

--
-- Table structure for table `email_verification_tokens`
--

CREATE TABLE `email_verification_tokens` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `code` char(6) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'email_verify',
  `used` tinyint(1) NOT NULL DEFAULT '0',
  `attempts` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `expires_at` datetime NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `email_verification_tokens`
--

INSERT INTO `email_verification_tokens` (`id`, `user_id`, `code`, `type`, `used`, `attempts`, `expires_at`, `created_at`) VALUES
(1, 1, '483675', 'email_verify', 1, 0, '2026-07-29 21:34:48', '2026-07-29 21:28:48'),
(2, 1, '147199', 'email_verify', 1, 0, '2026-07-29 21:42:37', '2026-07-29 21:36:37'),
(3, 1, '879491', 'email_verify', 1, 0, '2026-07-30 07:31:18', '2026-07-30 07:25:18'),
(4, 2, '564730', 'email_verify', 1, 0, '2026-07-30 21:14:56', '2026-07-30 21:08:56'),
(5, 2, '324556', 'email_verify', 1, 0, '2026-07-30 21:19:03', '2026-07-30 21:13:03'),
(6, 2, '079465', 'email_verify', 1, 0, '2026-07-30 21:20:35', '2026-07-30 21:14:35'),
(7, 2, '310433', 'email_verify', 1, 0, '2026-07-30 21:22:03', '2026-07-30 21:16:03'),
(8, 1, '532645', 'password_reset', 0, 0, '2026-07-31 13:39:58', '2026-07-31 13:33:58'),
(9, 1, '079086', 'email_verify', 1, 0, '2026-07-31 13:45:04', '2026-07-31 13:39:04'),
(10, 1, '374939', 'email_verify', 1, 0, '2026-07-31 13:47:45', '2026-07-31 13:41:45'),
(11, 1, '579171', 'email_verify', 1, 0, '2026-07-31 13:49:02', '2026-07-31 13:43:02'),
(12, 1, '989273', 'email_verify', 1, 0, '2026-07-31 13:51:29', '2026-07-31 13:45:29'),
(13, 1, '476794', 'email_verify', 1, 0, '2026-07-31 13:57:27', '2026-07-31 13:51:27'),
(14, 1, '596045', 'email_verify', 1, 0, '2026-07-31 14:18:55', '2026-07-31 14:12:55'),
(15, 1, '169398', 'email_verify', 1, 0, '2026-07-31 14:21:13', '2026-07-31 14:15:13'),
(16, 4, '491439', 'email_verify', 1, 0, '2026-07-31 16:19:12', '2026-07-31 16:13:12'),
(17, 4, '438175', 'email_verify', 1, 0, '2026-07-31 16:24:30', '2026-07-31 16:18:30'),
(18, 4, '438677', 'email_verify', 1, 0, '2026-07-31 16:32:06', '2026-07-31 16:26:06'),
(19, 4, '568511', 'email_verify', 1, 0, '2026-07-31 16:33:09', '2026-07-31 16:27:09'),
(20, 1, '875638', 'email_verify', 1, 0, '2026-07-31 16:33:41', '2026-07-31 16:27:41'),
(21, 4, '200806', 'email_verify', 1, 0, '2026-07-31 16:34:55', '2026-07-31 16:28:55'),
(22, 1, '934196', 'email_verify', 1, 0, '2026-07-31 16:37:01', '2026-07-31 16:31:01'),
(23, 1, '353125', 'email_verify', 1, 0, '2026-07-31 16:41:17', '2026-07-31 16:35:17'),
(24, 4, '300191', 'email_verify', 0, 1, '2026-07-31 16:41:38', '2026-07-31 16:35:38'),
(25, 1, '510580', 'email_verify', 1, 0, '2026-07-31 19:28:46', '2026-07-31 19:22:46'),
(26, 2, '099280', 'email_verify', 0, 0, '2026-07-31 20:47:35', '2026-07-31 20:41:35'),
(27, 1, '113215', 'email_verify', 1, 0, '2026-08-03 18:52:20', '2026-08-03 18:46:20'),
(28, 1, '773605', 'email_verify', 1, 0, '2026-08-03 18:55:11', '2026-08-03 18:49:11'),
(29, 1, '086253', 'email_verify', 1, 0, '2026-08-03 19:30:23', '2026-08-03 19:24:23'),
(30, 1, '084067', 'email_verify', 1, 0, '2026-08-03 19:33:07', '2026-08-03 19:27:07'),
(31, 1, '024344', 'email_verify', 1, 0, '2026-08-03 19:35:45', '2026-08-03 19:29:45'),
(32, 1, '025827', 'email_verify', 1, 0, '2026-08-03 19:54:39', '2026-08-03 19:48:39'),
(33, 1, '210272', 'email_verify', 1, 0, '2026-08-03 20:28:00', '2026-08-03 20:22:00'),
(34, 1, '493403', 'email_verify', 1, 0, '2026-08-03 20:47:43', '2026-08-03 20:41:43'),
(35, 1, '944401', 'email_verify', 1, 0, '2026-08-04 07:55:24', '2026-08-04 07:49:24'),
(36, 1, '788657', 'email_verify', 1, 0, '2026-08-04 13:11:09', '2026-08-04 13:05:09'),
(37, 1, '466720', 'email_verify', 1, 0, '2026-08-04 13:12:32', '2026-08-04 13:06:32'),
(38, 1, '828644', 'email_verify', 1, 0, '2026-08-04 13:36:13', '2026-08-04 13:30:13'),
(39, 1, '301742', 'email_verify', 1, 0, '2026-08-04 13:49:49', '2026-08-04 13:43:49'),
(40, 1, '206054', 'email_verify', 1, 0, '2026-08-04 13:52:07', '2026-08-04 13:46:07'),
(41, 1, '543647', 'email_verify', 1, 0, '2026-08-04 13:55:24', '2026-08-04 13:49:24'),
(42, 1, '200881', 'email_verify', 0, 0, '2026-08-04 14:22:13', '2026-08-04 14:16:13'),
(48, 8, '009268', 'email_verify', 1, 0, '2026-08-05 01:28:33', '2026-08-05 01:22:33'),
(49, 8, '135332', 'email_verify', 1, 0, '2026-08-05 01:34:45', '2026-08-05 01:28:45'),
(50, 8, '784363', 'email_verify', 1, 0, '2026-08-05 01:37:00', '2026-08-05 01:31:00'),
(51, 8, '951063', 'email_verify', 1, 0, '2026-08-05 01:44:36', '2026-08-05 01:38:36'),
(52, 9, '449639', 'email_verify', 1, 0, '2026-09-05 08:45:45', '2026-09-05 08:39:45'),
(53, 9, '044568', 'email_verify', 1, 0, '2026-09-05 08:49:52', '2026-09-05 08:43:52'),
(54, 9, '903800', 'email_verify', 1, 0, '2026-09-05 08:53:06', '2026-09-05 08:47:06'),
(55, 9, '020193', 'email_verify', 1, 0, '2026-09-05 08:58:07', '2026-09-05 08:52:07'),
(56, 9, '124245', 'email_verify', 1, 0, '2026-09-05 09:00:44', '2026-09-05 08:54:44');

-- --------------------------------------------------------

--
-- Table structure for table `follows`
--

CREATE TABLE `follows` (
  `id` int NOT NULL,
  `follower_id` int NOT NULL COMMENT 'client user id',
  `following_id` int NOT NULL COMMENT 'influencer user id',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `follows`
--

INSERT INTO `follows` (`id`, `follower_id`, `following_id`, `created_at`) VALUES
(3, 2, 9, '2026-09-05 09:16:30');

-- --------------------------------------------------------

--
-- Table structure for table `influencer_gallery`
--

CREATE TABLE `influencer_gallery` (
  `id` int NOT NULL,
  `influencer_id` int NOT NULL,
  `image_url` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `influencer_gallery`
--

INSERT INTO `influencer_gallery` (`id`, `influencer_id`, `image_url`, `created_at`) VALUES
(1, 3, 'gallery/user_3/img_f0a02babf05b4d9f4206f00a6bb3ef69.jpg', '2026-07-22 15:01:04'),
(2, 3, 'gallery/user_3/img_d648ceaa1489b0420ad5129787cfae9c.jpg', '2026-07-22 15:01:41'),
(3, 1, 'gallery/user_1/img_27a4563ec845c717fdd114b4e3cc9396.jpg', '2026-07-31 21:34:24'),
(4, 1, 'gallery/user_1/img_7d8d11082349218d2d4cce089bfac486.jpg', '2026-07-31 21:34:47');

-- --------------------------------------------------------

--
-- Table structure for table `influencer_profiles`
--

CREATE TABLE `influencer_profiles` (
  `user_id` int NOT NULL,
  `profile_completed` tinyint(1) NOT NULL DEFAULT '0',
  `biography` text,
  `age` int DEFAULT NULL,
  `complexion` varchar(50) DEFAULT NULL,
  `favourite_food` varchar(100) DEFAULT NULL,
  `hobby` varchar(100) DEFAULT NULL,
  `aspiration` varchar(255) DEFAULT NULL,
  `financial_target` decimal(15,2) DEFAULT NULL,
  `what_offer` text,
  `what_offer_status` tinyint(1) NOT NULL DEFAULT '0',
  `price_per_minute` decimal(10,2) NOT NULL DEFAULT '1.00',
  `mask_status` enum('masked','unmasked') DEFAULT 'masked',
  `willing_to_remove_mask` tinyint(1) DEFAULT '0',
  `intro_video` varchar(255) DEFAULT NULL,
  `average_rating` decimal(3,2) DEFAULT '0.00',
  `bad_rating_count` int NOT NULL DEFAULT '0',
  `total_calls` int DEFAULT '0',
  `total_earnings` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `online_status` enum('online','offline','busy','unavailable') DEFAULT 'offline',
  `verification_status` enum('pending','approved','rejected') DEFAULT 'pending',
  `government_id_url` varchar(255) DEFAULT NULL,
  `selfie_url` varchar(255) DEFAULT NULL,
  `verification_video_url` varchar(255) DEFAULT NULL,
  `admin_note` text,
  `last_seen` timestamp NULL DEFAULT NULL,
  `last_active_ping` timestamp NULL DEFAULT NULL COMMENT 'Set by client heartbeat every ~15 s. NULL = never pinged.'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `influencer_profiles`
--

INSERT INTO `influencer_profiles` (`user_id`, `profile_completed`, `biography`, `age`, `complexion`, `favourite_food`, `hobby`, `aspiration`, `financial_target`, `what_offer`, `what_offer_status`, `price_per_minute`, `mask_status`, `willing_to_remove_mask`, `intro_video`, `average_rating`, `bad_rating_count`, `total_calls`, `total_earnings`, `online_status`, `verification_status`, `government_id_url`, `selfie_url`, `verification_video_url`, `admin_note`, `last_seen`, `last_active_ping`) VALUES
(1, 1, 'Im an Influencer', 20, 'Chocolate', 'Chicken', 'coding', 'Successful Developer', 1000.00, 'I will be doing anything the client requested for on the video call.', 1, 100.00, 'unmasked', 0, NULL, 5.00, 0, 47, 3524.7200, 'offline', 'approved', 'verification/user_1/id_front.jpg', 'verification/user_1/selfie.jpg', 'verification/user_1/video.mp4', '', '2026-09-04 09:23:11', '2026-09-04 09:20:49'),
(3, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1.00, 'masked', 0, NULL, 5.00, 0, 0, 0.0000, 'online', 'rejected', NULL, NULL, NULL, '', '2026-07-22 14:55:03', '2026-07-22 14:55:03'),
(4, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1.00, 'masked', 0, NULL, 5.00, 0, 0, 0.0000, 'online', 'rejected', NULL, NULL, NULL, '', '2026-07-31 16:13:09', '2026-07-31 16:13:09'),
(8, 0, 'I\'m a professional web and mobile app developer who build high quality softwares for people.', 20, 'dark', 'Meat', 'Coding', 'Becoming the best software Enginner', 100000.00, NULL, 0, 1.00, 'unmasked', 1, NULL, 5.00, 0, 0, 0.0000, 'offline', 'rejected', NULL, NULL, NULL, '', '2026-08-07 11:18:24', '2026-08-07 11:18:17'),
(9, 0, 'I\'am an influencer from the united kingdom', 21, 'fair', 'pizza', 'music', 'popularity', 999.00, 'Anything that will make the client happy', 1, 1.00, 'unmasked', 1, NULL, 5.00, 0, 1, 16.9200, 'online', 'approved', 'verification/user_9/id_front.png', 'verification/user_9/selfie.jpg', 'verification/user_9/video.webm', '', '2026-09-18 04:37:03', '2026-09-18 04:37:03');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `support_agent_id` int DEFAULT NULL,
  `recipient_type` enum('user','support') NOT NULL DEFAULT 'user',
  `title` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `type` varchar(60) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `support_agent_id`, `recipient_type`, `title`, `body`, `type`, `is_read`, `created_at`) VALUES
(1, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 07:13:39'),
(2, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 07:14:01'),
(3, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 07:26:53'),
(4, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 07:27:58'),
(5, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 07:29:07'),
(6, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 07:46:33'),
(7, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 07:46:40'),
(8, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 07:46:41'),
(9, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 07:46:41'),
(10, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 09:02:56'),
(11, 2, NULL, 'user', 'Call Request Rejected', 'Your call request to mozel has been rejected.', 'call_rejected', 0, '2026-07-24 09:03:21'),
(12, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 09:03:36'),
(13, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 09:03:44'),
(14, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 09:03:46'),
(15, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 09:03:46'),
(16, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 09:16:12'),
(17, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 09:16:35'),
(18, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 09:16:35'),
(19, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 09:16:35'),
(20, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 09:17:38'),
(21, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 09:17:38'),
(22, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 09:18:24'),
(23, 2, NULL, 'user', 'Call Request Rejected', 'Your call request to mozel has been rejected.', 'call_rejected', 0, '2026-07-24 09:18:41'),
(24, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 09:30:14'),
(25, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 09:30:23'),
(26, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 09:30:25'),
(27, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 09:30:25'),
(28, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 09:31:25'),
(29, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 09:31:25'),
(30, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 09:47:46'),
(31, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 10:05:20'),
(32, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 10:12:31'),
(33, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 10:14:13'),
(34, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 10:14:21'),
(35, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 10:14:29'),
(36, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 10:15:07'),
(37, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 10:15:16'),
(38, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 10:17:50'),
(39, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 10:17:58'),
(40, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 10:17:59'),
(41, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 10:17:59'),
(42, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 10:19:01'),
(43, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 10:19:01'),
(44, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 10:22:38'),
(45, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 10:22:43'),
(46, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 10:22:43'),
(47, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 10:22:43'),
(48, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 10:23:44'),
(49, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 10:23:44'),
(50, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 10:35:12'),
(51, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 10:35:18'),
(52, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 10:35:20'),
(53, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 10:35:20'),
(54, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-24 10:35:56'),
(55, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-24 10:35:56'),
(56, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 12:07:20'),
(57, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 12:07:28'),
(58, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 12:07:28'),
(59, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 12:07:28'),
(60, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 12:08:35'),
(61, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 12:08:35'),
(62, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 12:10:06'),
(63, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 12:10:13'),
(64, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 12:10:13'),
(65, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 12:10:13'),
(66, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 12:11:28'),
(67, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 12:11:28'),
(68, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 12:12:00'),
(69, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 12:12:07'),
(70, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 12:12:09'),
(71, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 12:12:09'),
(72, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 12:13:11'),
(73, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 12:13:11'),
(74, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #10 has been released to your wallet.', 'escrow_released', 1, '2026-07-24 12:14:33'),
(75, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 12:24:53'),
(76, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 12:25:07'),
(77, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 12:25:07'),
(78, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 12:25:07'),
(79, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 12:26:15'),
(80, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 12:26:15'),
(81, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 12:27:34'),
(82, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 12:28:04'),
(83, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 12:28:04'),
(84, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 12:28:04'),
(85, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 12:29:14'),
(86, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 12:29:14'),
(87, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 13:00:40'),
(88, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 13:00:56'),
(89, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 13:00:56'),
(90, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 13:00:56'),
(91, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 13:01:59'),
(92, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 13:01:59'),
(93, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 13:02:26'),
(94, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 13:02:32'),
(95, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 13:02:33'),
(96, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 13:02:33'),
(97, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 13:03:33'),
(98, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 13:03:33'),
(99, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 13:03:58'),
(100, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 13:04:02'),
(101, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 13:04:02'),
(102, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 13:04:02'),
(103, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 13:05:11'),
(104, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 13:05:11'),
(105, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 13:06:20'),
(106, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 13:06:27'),
(107, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 13:06:28'),
(108, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 13:06:28'),
(109, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 13:07:30'),
(110, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 13:07:30'),
(111, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-24 13:20:35'),
(112, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-24 13:20:52'),
(113, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-24 13:20:52'),
(114, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-24 13:20:52'),
(115, 1, NULL, 'user', 'Call Extended', 'The client purchased 15 additional minute(s).', 'call_status', 1, '2026-07-24 13:21:16'),
(116, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-24 13:36:55'),
(117, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-24 13:36:55'),
(118, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-27 08:47:05'),
(119, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-27 08:47:27'),
(120, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-27 08:47:28'),
(121, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-27 08:47:28'),
(122, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-27 08:48:31'),
(123, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-27 08:48:31'),
(124, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-27 08:50:38'),
(125, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-27 08:51:59'),
(126, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-27 08:52:01'),
(127, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-27 08:52:01'),
(128, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-27 08:53:04'),
(129, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-27 08:53:04'),
(130, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-27 09:37:35'),
(131, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-27 09:37:44'),
(132, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-27 09:37:46'),
(133, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-27 09:37:46'),
(134, 1, NULL, 'user', 'Call Extended', 'The client purchased 5 additional minute(s).', 'call_status', 1, '2026-07-27 09:38:45'),
(135, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-07-27 09:43:48'),
(136, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-07-27 09:43:48'),
(137, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-27 09:52:19'),
(138, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-27 09:52:32'),
(139, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-27 09:52:33'),
(140, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-27 09:52:33'),
(141, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-27 09:52:38'),
(142, 1, NULL, 'user', 'Call Extended', 'The client purchased 5 additional minute(s).', 'call_status', 1, '2026-07-27 09:56:53'),
(143, 1, NULL, 'user', 'Call Extended', 'The client purchased 5 additional minute(s).', 'call_status', 1, '2026-07-27 10:01:46'),
(144, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-27 11:14:10'),
(145, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-27 11:14:18'),
(146, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-27 11:14:18'),
(147, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-27 11:14:18'),
(148, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-27 11:14:27'),
(149, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-27 11:15:00'),
(150, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-27 11:15:00'),
(151, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #22 has been released to your wallet.', 'escrow_released', 1, '2026-07-27 11:17:19'),
(152, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-27 11:25:11'),
(153, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-27 11:25:22'),
(154, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-27 11:25:23'),
(155, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-27 11:25:23'),
(156, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-27 11:25:26'),
(157, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-27 11:26:29'),
(158, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-27 11:26:29'),
(159, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #23 has been released to your wallet.', 'escrow_released', 1, '2026-07-27 11:26:46'),
(160, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-27 11:38:35'),
(161, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-27 11:38:43'),
(162, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-27 11:38:43'),
(163, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-27 11:38:43'),
(164, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-27 11:38:46'),
(165, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-27 11:40:17'),
(166, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-27 11:40:17'),
(167, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-27 11:42:50'),
(168, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-27 11:43:09'),
(169, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-27 11:43:09'),
(170, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-27 11:43:09'),
(171, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-27 11:43:12'),
(172, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-27 11:44:16'),
(173, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-27 11:44:16'),
(174, 2, NULL, 'user', 'Wallet Funded', 'Your wallet has been topped up with 5 coins.', 'wallet_funded', 0, '2026-07-28 16:40:23'),
(175, 2, NULL, 'user', 'Wallet Funded', 'Your wallet has been topped up with 200 coins.', 'wallet_funded', 0, '2026-07-28 16:42:14'),
(176, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #3 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:13'),
(177, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #4 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:14'),
(178, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #5 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:14'),
(179, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #6 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:14'),
(180, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #7 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:15'),
(181, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #8 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:15'),
(182, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #9 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:15'),
(183, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #11 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:16'),
(184, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #12 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:16'),
(185, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #13 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:16'),
(186, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #14 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:16'),
(187, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #15 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:17'),
(188, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #16 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:17'),
(189, 1, NULL, 'user', 'Escrow Released', 'Payment of 1,600.00 for call #17 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:17'),
(190, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #18 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:17'),
(191, 1, NULL, 'user', 'Escrow Released', 'Payment of 100.00 for call #19 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:17'),
(192, 1, NULL, 'user', 'Escrow Released', 'Payment of 6.00 for call #20 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:17'),
(193, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #24 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:17'),
(194, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #25 has been released to your wallet.', 'escrow_released', 1, '2026-07-28 17:15:17'),
(195, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-31 20:43:20'),
(196, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-31 20:43:49'),
(197, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-31 20:43:49'),
(198, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-31 20:43:49'),
(199, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-31 20:43:54'),
(200, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-31 20:45:05'),
(201, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-31 20:45:05'),
(202, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #26 has been released to your wallet.', 'escrow_released', 1, '2026-07-31 20:57:41'),
(203, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-31 21:14:09'),
(204, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-31 21:14:16'),
(205, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-31 21:14:17'),
(206, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-31 21:14:17'),
(207, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-31 21:14:27'),
(208, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-31 21:16:36'),
(209, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-31 21:16:36'),
(210, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #27 has been released to your wallet.', 'escrow_released', 1, '2026-07-31 21:17:03'),
(211, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-31 21:37:16'),
(212, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-31 21:37:23'),
(213, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-31 21:37:24'),
(214, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-31 21:37:24'),
(215, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-31 21:37:27'),
(216, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-31 21:38:35'),
(217, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-31 21:38:35'),
(218, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-31 22:04:06'),
(219, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-31 22:04:14'),
(220, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-31 22:04:15'),
(221, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-31 22:04:15'),
(222, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-31 22:04:19'),
(223, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-31 22:05:07'),
(224, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-31 22:05:07'),
(225, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #29 has been released to your wallet.', 'escrow_released', 1, '2026-07-31 22:05:22'),
(226, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #28 has been released to your wallet.', 'escrow_released', 1, '2026-07-31 22:10:09'),
(227, 4, NULL, 'user', 'Verification Resubmission Requested', 'Your influencer verification requires resubmission. Reason: ', 'verification_status', 0, '2026-07-31 22:10:37'),
(228, 3, NULL, 'user', 'Verification Resubmission Requested', 'Your influencer verification requires resubmission. Reason: ', 'verification_status', 0, '2026-07-31 22:10:42'),
(229, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-31 22:50:40'),
(230, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-31 22:50:50'),
(231, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-31 22:50:50'),
(232, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-31 22:50:50'),
(233, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-31 22:50:55'),
(234, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-31 22:52:39'),
(235, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-31 22:52:39'),
(236, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #30 has been released to your wallet.', 'escrow_released', 1, '2026-07-31 22:52:56'),
(237, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-31 23:10:17'),
(238, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-31 23:10:21'),
(239, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-31 23:10:21'),
(240, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-31 23:10:21'),
(241, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-31 23:10:25'),
(242, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-31 23:11:00'),
(243, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-31 23:11:00'),
(244, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #31 has been released to your wallet.', 'escrow_released', 1, '2026-07-31 23:11:17'),
(245, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-31 23:15:45'),
(246, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-31 23:15:52'),
(247, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-31 23:15:53'),
(248, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-31 23:15:53'),
(249, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-31 23:15:55'),
(250, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-31 23:17:37'),
(251, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-31 23:17:37'),
(252, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #32 has been released to your wallet.', 'escrow_released', 1, '2026-07-31 23:17:52'),
(253, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-31 23:27:05'),
(254, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-31 23:27:22'),
(255, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-31 23:27:24'),
(256, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-31 23:27:24'),
(257, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-31 23:27:26'),
(258, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-31 23:28:40'),
(259, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-31 23:28:40'),
(260, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #33 has been released to your wallet.', 'escrow_released', 1, '2026-07-31 23:28:52'),
(261, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-31 23:31:29'),
(262, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-31 23:31:34'),
(263, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-31 23:31:34'),
(264, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-31 23:31:34'),
(265, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-31 23:31:37'),
(266, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-31 23:32:20'),
(267, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-31 23:32:20'),
(268, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #34 has been released to your wallet.', 'escrow_released', 1, '2026-07-31 23:32:28'),
(269, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-31 23:48:21'),
(270, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-31 23:48:37'),
(271, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-31 23:48:37'),
(272, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-31 23:48:37'),
(273, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-31 23:48:42'),
(274, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-31 23:49:40'),
(275, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-31 23:49:40'),
(276, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #35 has been released to your wallet.', 'escrow_released', 1, '2026-07-31 23:49:54'),
(277, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-07-31 23:53:30'),
(278, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-07-31 23:53:56'),
(279, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-07-31 23:53:56'),
(280, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-07-31 23:53:56'),
(281, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-07-31 23:53:58'),
(282, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-07-31 23:54:56'),
(283, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-07-31 23:54:56'),
(284, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #36 has been released to your wallet.', 'escrow_released', 1, '2026-07-31 23:55:07'),
(285, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-01 00:03:35'),
(286, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-08-01 00:03:40'),
(287, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-01 00:03:40'),
(288, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-08-01 00:03:40'),
(289, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-08-01 00:03:42'),
(290, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-01 00:04:10'),
(291, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-08-01 00:04:10'),
(292, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #37 has been released to your wallet.', 'escrow_released', 1, '2026-08-01 00:04:40'),
(293, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-01 00:09:56'),
(294, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-08-01 00:10:05'),
(295, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-01 00:10:07'),
(296, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-08-01 00:10:07'),
(297, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-08-01 00:10:13'),
(298, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-01 00:12:33'),
(299, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-08-01 00:12:33'),
(300, 1, NULL, 'user', 'Escrow Released', 'Payment of 5.00 for call #38 has been released to your wallet.', 'escrow_released', 1, '2026-08-01 00:13:26'),
(301, 1, NULL, 'user', 'New Rating Received', 'You received a 5-star rating from a client.', 'rating', 1, '2026-08-01 00:15:54'),
(302, 4, NULL, 'user', 'New Withdrawal Request', 'Influencer mozel (#1) requested a withdrawal of 50.00.', 'withdrawal_requested', 0, '2026-08-01 00:25:54'),
(303, 1, NULL, 'user', 'Withdrawal Requested', 'Your withdrawal request for 50.00 has been submitted and is pending admin review.', 'withdrawal_requested', 1, '2026-08-01 00:25:54'),
(304, 1, NULL, 'user', 'Withdrawal Approved', 'Your withdrawal request for 50.00 has been approved.', 'withdrawal_approved', 1, '2026-08-01 00:28:09'),
(305, 4, NULL, 'user', 'New Withdrawal Request', 'Influencer mozel (#1) requested a withdrawal of 50.00.', 'withdrawal_requested', 0, '2026-08-01 00:36:07'),
(306, 1, NULL, 'user', 'Withdrawal Requested', 'Your withdrawal request for 50.00 has been submitted and is pending admin review.', 'withdrawal_requested', 1, '2026-08-01 00:36:07'),
(307, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-01 00:59:13'),
(308, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-08-01 00:59:23'),
(309, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-01 00:59:24'),
(310, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-08-01 00:59:24'),
(311, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-08-01 00:59:25'),
(312, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-01 00:59:51'),
(313, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-08-01 00:59:51'),
(314, 1, NULL, 'user', 'Payment Received', 'You received 5.00 coins from James for call #39.', 'escrow_released', 1, '2026-08-01 01:00:15'),
(315, 1, NULL, 'user', 'New Message', 'You have a new message from James', 'chat', 1, '2026-08-01 01:16:13'),
(316, 2, NULL, 'user', 'New Message', 'You have a new message from mozel', 'chat', 0, '2026-08-01 01:19:12'),
(317, 1, NULL, 'user', 'New Message', 'You have a new message from James', 'chat', 1, '2026-08-01 01:21:30'),
(318, 2, NULL, 'user', 'New Message', 'You have a new message from mozel', 'chat', 0, '2026-08-01 01:21:47'),
(319, 2, NULL, 'user', 'New Message', 'You have a new message from mozel', 'chat', 0, '2026-08-01 01:24:01'),
(320, 1, NULL, 'user', 'New Message', 'You have a new message from James', 'chat', 1, '2026-08-01 01:24:11'),
(321, 2, NULL, 'user', 'New Message', 'You have a new message from mozel', 'chat', 0, '2026-08-01 01:26:10'),
(322, 1, NULL, 'user', 'New Message', 'You have a new message from James', 'chat', 1, '2026-08-01 01:26:24'),
(323, 2, NULL, 'user', 'New Message', 'You have a new message from mozel', 'chat', 0, '2026-08-01 01:26:36'),
(324, 2, NULL, 'user', 'New Message', 'You have a new message from mozel', 'chat', 0, '2026-08-01 01:34:08'),
(325, 2, NULL, 'user', 'New Message', 'You have a new message from mozel', 'chat', 0, '2026-08-01 01:34:20'),
(326, 2, NULL, 'user', 'New Message', 'You have a new message from mozel', 'chat', 0, '2026-08-01 01:34:38'),
(327, 1, NULL, 'user', 'New Message', 'You have a new message from James', 'chat', 1, '2026-08-01 01:41:52'),
(328, 2, NULL, 'user', 'Wallet Funded', 'Your wallet has been topped up with 5 coins.', 'wallet_funded', 0, '2026-08-01 14:17:08'),
(329, 2, NULL, 'user', 'Wallet Funded', 'Your wallet has been topped up with 10 coins.', 'wallet_funded', 0, '2026-08-01 14:19:47'),
(330, 2, NULL, 'user', 'Wallet Funded', 'Your wallet has been topped up with 5 coins.', 'wallet_funded', 0, '2026-08-01 14:27:18'),
(331, 2, NULL, 'user', 'Wallet Funded', 'Your wallet has been topped up with 5 coins.', 'wallet_funded', 0, '2026-08-01 14:29:54'),
(332, 2, NULL, 'user', 'Wallet Funded', 'Your wallet has been topped up with 5 coins.', 'wallet_funded', 0, '2026-08-01 14:57:20'),
(333, 2, NULL, 'user', 'Wallet Funded', 'Your wallet has been topped up with 5 coins.', 'wallet_funded', 0, '2026-08-01 15:07:42'),
(334, 2, NULL, 'user', 'Wallet Funded', 'Your wallet has been topped up with 5 coins.', 'wallet_funded', 0, '2026-08-01 19:52:45'),
(335, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-03 09:47:44'),
(336, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-08-03 09:48:24'),
(337, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-03 09:48:24'),
(338, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-08-03 09:48:24'),
(339, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-08-03 09:48:41'),
(340, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-03 09:50:13'),
(341, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-08-03 09:50:13'),
(342, 1, NULL, 'user', 'Payment Received', 'You received 30.00 coins from James for call #40.', 'escrow_released', 1, '2026-08-03 09:50:30'),
(343, 1, NULL, 'user', 'New Rating Received', 'You received a 5-star rating from a client.', 'rating', 1, '2026-08-03 09:51:01'),
(344, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-03 13:12:18'),
(345, 2, NULL, 'user', 'Call Request Rejected', 'Your call request to mozel has been rejected.', 'call_rejected', 0, '2026-08-03 13:12:48'),
(346, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-03 13:22:25'),
(347, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-08-03 13:24:22'),
(348, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-03 13:24:23'),
(349, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-08-03 13:24:23'),
(350, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-08-03 13:24:56'),
(351, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-03 13:25:12'),
(352, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-08-03 13:25:12'),
(353, 1, NULL, 'user', 'Payment Received', 'You received 30.00 coins from James for call #41.', 'escrow_released', 1, '2026-08-03 13:25:24'),
(354, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-03 21:30:41'),
(355, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-08-03 21:31:40'),
(356, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-03 21:31:42'),
(357, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-08-03 21:31:42'),
(358, 2, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 0, '2026-08-03 21:32:54'),
(359, 1, NULL, 'user', 'Call Ended', 'Your call has ended because the paid time ran out.', 'call_status', 1, '2026-08-03 21:32:54'),
(360, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-03 21:49:41'),
(361, 2, NULL, 'user', 'Call Request Rejected', 'Your call request to mozel has been rejected.', 'call_rejected', 0, '2026-08-03 21:51:35'),
(362, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-03 21:51:49'),
(363, 1, NULL, 'user', 'Payment Received', 'You received 6.00 coins from James for call #42.', 'escrow_released', 1, '2026-08-03 22:05:12'),
(364, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-04 16:28:32'),
(365, 2, NULL, 'user', 'Call Request Rejected', 'Your call request to mozel has been rejected.', 'call_rejected', 0, '2026-08-04 16:29:08'),
(366, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-04 16:32:11'),
(367, 2, NULL, 'user', 'Call Request Rejected', 'Your call request to mozel has been rejected.', 'call_rejected', 0, '2026-08-04 16:32:26'),
(368, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-04 16:34:57'),
(369, 2, NULL, 'user', 'Call Request Rejected', 'Your call request to mozel has been rejected.', 'call_rejected', 0, '2026-08-04 16:35:14'),
(370, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-04 17:06:19'),
(371, 2, NULL, 'user', 'Call Request Rejected', 'Your call request to mozel has been rejected.', 'call_rejected', 0, '2026-08-04 17:07:47'),
(372, 3, NULL, 'user', 'Verification Rejected', 'Unfortunately, your influencer verification request has been rejected. Reason: ', 'verification_status', 0, '2026-08-04 17:33:38'),
(373, 4, NULL, 'user', 'Verification Rejected', 'Unfortunately, your influencer verification request has been rejected. Reason: ', 'verification_status', 0, '2026-08-04 17:33:43'),
(374, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-07 11:19:02'),
(375, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-08-07 11:19:21'),
(376, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-07 11:19:21'),
(377, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-08-07 11:19:21'),
(378, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-08-07 11:19:33'),
(379, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-07 11:21:51'),
(380, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-08-07 11:21:51'),
(381, 1, NULL, 'user', 'Payment Received', 'You received 30.00 coins from James for call #43.', 'escrow_released', 1, '2026-08-07 11:21:59'),
(382, 1, NULL, 'user', 'New Rating Received', 'You received a 5-star rating from a client.', 'rating', 1, '2026-08-07 11:24:29'),
(383, NULL, 1, 'support', 'New Support Ticket', 'New ticket from James: hello', 'support_new_ticket', 0, '2026-08-07 11:24:48'),
(384, NULL, 1, 'support', 'New Support Ticket', 'New ticket from James: hello', 'support_new_ticket', 0, '2026-08-07 12:01:27'),
(385, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-07 12:10:00'),
(386, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-08-07 12:10:18'),
(387, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-07 12:10:19'),
(388, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-08-07 12:10:19'),
(389, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-08-07 12:10:41'),
(390, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-07 12:11:41'),
(391, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-08-07 12:11:41'),
(392, 1, NULL, 'user', 'Payment Received', 'You received 30.00 coins from James for call #44.', 'escrow_released', 1, '2026-08-07 12:11:50'),
(393, 1, NULL, 'user', 'New Rating Received', 'You received a 5-star rating from a client.', 'rating', 1, '2026-08-07 12:12:16'),
(394, NULL, 1, 'support', 'New Support Ticket', 'New ticket from James: Hi, the influencer didn\'t deliver well on the video call and he ended the call', 'support_new_ticket', 0, '2026-08-07 12:13:56'),
(395, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-08-07 12:39:35'),
(396, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-08-07 12:39:43'),
(397, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-07 12:39:44'),
(398, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-08-07 12:39:44'),
(399, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 1, '2026-08-07 12:39:54'),
(400, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-08-07 12:40:29'),
(401, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-08-07 12:40:29');
INSERT INTO `notifications` (`id`, `user_id`, `support_agent_id`, `recipient_type`, `title`, `body`, `type`, `is_read`, `created_at`) VALUES
(402, 1, NULL, 'user', 'Payment Received', 'You received 30.00 coins from James for call #45.', 'escrow_released', 1, '2026-08-07 12:40:46'),
(403, 1, NULL, 'user', 'New Rating Received', 'You received a 5-star rating from a client.', 'rating', 1, '2026-08-07 12:41:26'),
(404, 1, NULL, 'user', 'Withdrawal Approved', 'Your withdrawal request for 50.00 has been approved.', 'withdrawal_approved', 1, '2026-08-07 13:00:14'),
(405, 2, NULL, 'user', 'Wallet Funded', 'Your wallet has been topped up with 5 coins.', 'wallet_funded', 0, '2026-08-20 11:52:17'),
(406, 2, NULL, 'user', 'New Message', 'You have a new message from mozel', 'chat', 0, '2026-08-22 07:32:43'),
(407, 8, NULL, 'user', 'Verification Rejected', 'Unfortunately, your influencer verification request has been rejected. Reason: ', 'verification_status', 0, '2026-08-24 11:27:10'),
(408, 1, NULL, 'user', 'Verification Approved', 'Congratulations! Your influencer profile has been approved.', 'verification_status', 0, '2026-08-24 11:27:14'),
(409, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 0, '2026-08-24 12:46:46'),
(410, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-08-24 12:46:59'),
(411, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-24 12:46:59'),
(412, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-24 12:46:59'),
(413, 1, NULL, 'user', 'Call Extended', 'The client purchased 4 additional minute(s).', 'call_status', 0, '2026-08-24 12:47:04'),
(414, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-24 12:48:53'),
(415, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-24 12:48:53'),
(416, 1, NULL, 'user', 'Payment Received', 'You received 30.00 coins from James for call #46.', 'escrow_released', 0, '2026-08-24 12:49:10'),
(417, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 0, '2026-08-24 13:02:39'),
(418, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-08-24 13:02:50'),
(419, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-24 13:02:50'),
(420, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-24 13:02:50'),
(421, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-24 13:04:10'),
(422, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-24 13:04:10'),
(423, 1, NULL, 'user', 'Payment Received', 'You received 12.00 coins from James for call #47.', 'escrow_released', 0, '2026-08-24 13:04:21'),
(424, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 0, '2026-08-25 01:05:28'),
(425, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 0, '2026-08-25 01:05:40'),
(426, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-25 01:05:41'),
(427, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-25 01:05:41'),
(428, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-08-25 01:07:16'),
(429, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-25 01:07:16'),
(430, 1, NULL, 'user', 'Payment Received', 'You received 11.40 coins from James for call #48.', 'escrow_released', 0, '2026-08-25 01:07:19'),
(431, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 0, '2026-08-25 01:08:21'),
(432, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 1, '2026-08-25 01:08:28'),
(433, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-08-25 01:08:28'),
(434, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-25 01:08:28'),
(435, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 1, '2026-08-25 01:09:30'),
(436, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-25 01:09:30'),
(437, 1, NULL, 'user', 'Payment Received', 'You received 12.00 coins from James for call #49.', 'escrow_released', 0, '2026-08-25 01:09:34'),
(438, 1, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 0, '2026-08-25 01:15:43'),
(439, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to mozel has been accepted.', 'call_accepted', 1, '2026-08-25 01:15:54'),
(440, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-08-25 01:15:54'),
(441, 1, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-08-25 01:15:54'),
(442, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-25 01:16:56'),
(443, 1, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-08-25 01:16:56'),
(444, 1, NULL, 'user', 'Payment Received', 'You received 7.32 coins from James for call #50.', 'escrow_released', 0, '2026-08-25 01:17:03'),
(445, 9, NULL, 'user', 'Verification Approved', 'Congratulations! Your influencer profile has been approved.', 'verification_status', 1, '2026-09-05 08:58:47'),
(446, 9, NULL, 'user', 'New Call Request', 'You have a new call request from James.', 'call_requested', 1, '2026-09-05 09:17:04'),
(447, 2, NULL, 'user', 'Call Request Accepted', 'Your call request to Amelia has been accepted.', 'call_accepted', 0, '2026-09-05 09:17:27'),
(448, 2, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 0, '2026-09-05 09:17:27'),
(449, 9, NULL, 'user', 'Call Started', 'Your call has started.', 'call_status', 1, '2026-09-05 09:17:27'),
(450, 2, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-09-05 09:19:48'),
(451, 9, NULL, 'user', 'Call Ended', 'Your call has ended.', 'call_status', 0, '2026-09-05 09:19:48'),
(452, 9, NULL, 'user', 'Payment Received', 'You received 16.92 coins from James for call #51.', 'escrow_released', 1, '2026-09-05 09:20:01');

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `token` varchar(255) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `password_resets`
--

INSERT INTO `password_resets` (`id`, `user_id`, `token`, `expires_at`, `created_at`) VALUES
(1, 2, 'f950e5943019f0f882fec45a5364d1e143acce5d20e6b3ae2484a5bf5a36dff2', '2026-07-21 13:43:26', '2026-07-21 12:43:26'),
(3, 1, 'f65ae6d6af8637e9054e8d9a8c427140c5768153120777e0a500ad3008046df1', '2026-07-30 22:30:52', '2026-07-30 21:30:52');

-- --------------------------------------------------------

--
-- Table structure for table `payg_call_pricing`
--

CREATE TABLE `payg_call_pricing` (
  `id` tinyint UNSIGNED NOT NULL,
  `per_minute` decimal(15,4) NOT NULL DEFAULT '1.0000',
  `per_second` decimal(15,6) NOT NULL DEFAULT '0.016667',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `payg_call_pricing`
--

INSERT INTO `payg_call_pricing` (`id`, `per_minute`, `per_second`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 6.0000, 0.120000, 1, '2026-08-24 12:31:22', '2026-08-24 13:02:05');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `package_id` int NOT NULL,
  `payment_reference` varchar(255) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'GBP',
  `coins` int NOT NULL,
  `status` enum('pending','completed','failed') DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `user_id`, `package_id`, `payment_reference`, `amount`, `currency`, `coins`, `status`, `created_at`) VALUES
(1, 2, 1, NULL, 10.00, 'GBP', 5, 'pending', '2026-07-28 16:19:18'),
(2, 2, 1, NULL, 10.00, 'GBP', 5, 'pending', '2026-07-28 16:20:50'),
(3, 2, 1, NULL, 10.00, 'GBP', 5, 'completed', '2026-07-28 16:34:08'),
(4, 2, 11, NULL, 200.00, 'GBP', 200, 'completed', '2026-07-28 16:41:17'),
(5, 2, 1, NULL, 10.00, 'GBP', 5, 'pending', '2026-08-01 13:57:07'),
(6, 2, 2, NULL, 20.00, 'GBP', 10, 'pending', '2026-08-01 13:57:28'),
(7, 2, 1, NULL, 10.00, 'GBP', 5, 'pending', '2026-08-01 13:59:58'),
(8, 2, 1, '7pv7sk40yu', 10.00, 'GBP', 5, 'completed', '2026-08-01 14:16:20'),
(9, 2, 2, '6oabf1m7zl', 20.00, 'GBP', 10, 'completed', '2026-08-01 14:19:31'),
(10, 2, 1, '4lefeef1jd', 10.00, 'GBP', 5, 'completed', '2026-08-01 14:27:04'),
(11, 2, 1, 'k78cc7mj1j', 10.00, 'GBP', 5, 'completed', '2026-08-01 14:29:36'),
(12, 2, 1, 'tgxaiphw5r', 10.00, 'GBP', 5, 'completed', '2026-08-01 14:53:49'),
(13, 2, 1, 'tzed2787jz', 10.00, 'GBP', 5, 'completed', '2026-08-01 15:07:19'),
(14, 2, 2, 'nj3bo9zoh3', 20.00, 'GBP', 10, 'pending', '2026-08-01 15:09:05'),
(15, 2, 1, 'dlsnj0gthq', 10.00, 'GBP', 5, 'completed', '2026-08-01 19:52:06'),
(16, 2, 1, 'fysaaprkt8', 10.00, 'GBP', 5, 'pending', '2026-08-01 23:12:25'),
(17, 2, 1, NULL, 10.00, 'GBP', 5, 'pending', '2026-08-02 08:18:50'),
(18, 2, 1, NULL, 10.00, 'GBP', 5, 'pending', '2026-08-02 08:18:54'),
(19, 2, 1, NULL, 10.00, 'GBP', 5, 'pending', '2026-08-02 08:20:11'),
(20, 2, 1, NULL, 10.00, 'GBP', 5, 'pending', '2026-08-03 10:13:01'),
(21, 2, 1, NULL, 10.00, 'GBP', 5, 'pending', '2026-08-20 10:32:58'),
(22, 2, 1, NULL, 10.00, 'GBP', 5, 'failed', '2026-08-20 11:16:59'),
(23, 2, 1, 'mp_23_41fb0574811a3470', 10.00, 'GBP', 5, 'pending', '2026-08-20 11:24:17'),
(24, 2, 1, 'mp_24_2eface904975ec01', 10.00, 'GBP', 5, 'completed', '2026-08-20 11:50:33'),
(25, 2, 1, 'mp_25_6d444a7c57f28f14', 10.00, 'GBP', 5, 'pending', '2026-08-22 09:45:10'),
(26, 2, 1, 'mp_26_1cdf11a2ca2451b6', 10.00, 'GBP', 5, 'pending', '2026-08-24 13:05:05'),
(27, 2, 1, 'mp_27_3d1e70162ded13f0', 10.00, 'GBP', 5, 'pending', '2026-09-05 09:23:03');

-- --------------------------------------------------------

--
-- Table structure for table `posts`
--

CREATE TABLE `posts` (
  `id` int NOT NULL,
  `influencer_id` int NOT NULL,
  `caption` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `body` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `posts`
--

INSERT INTO `posts` (`id`, `influencer_id`, `caption`, `body`, `created_at`, `updated_at`) VALUES
(1, 1, 'Am available for calls', 'I\'m always active for calls all the time. kindly hit me up in my DM so we can proceed.', '2026-08-24 11:54:33', '2026-08-24 11:54:33'),
(2, 9, 'Hey everyone, I\'m Amelia from the United Kingdom', NULL, '2026-09-05 09:05:16', '2026-09-05 09:05:16');

-- --------------------------------------------------------

--
-- Table structure for table `post_comments`
--

CREATE TABLE `post_comments` (
  `id` int NOT NULL,
  `post_id` int NOT NULL,
  `user_id` int NOT NULL,
  `comment` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `post_comments`
--

INSERT INTO `post_comments` (`id`, `post_id`, `user_id`, `comment`, `created_at`) VALUES
(1, 1, 2, 'james@example.com', '2026-08-26 19:28:11'),
(2, 1, 2, 'james@example.com', '2026-08-26 19:30:04');

-- --------------------------------------------------------

--
-- Table structure for table `post_images`
--

CREATE TABLE `post_images` (
  `id` int NOT NULL,
  `post_id` int NOT NULL,
  `image_url` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_order` int NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `post_images`
--

INSERT INTO `post_images` (`id`, `post_id`, `image_url`, `display_order`, `created_at`) VALUES
(1, 1, 'gallery/user_1/img_cfd171b1e5d6e9c8b5b918282525ce06.jpg', 0, '2026-08-24 11:54:34'),
(2, 2, 'gallery/user_9/img_e779ee4b9d1bd6f1cb5f17454bcd2e8a.jpg', 0, '2026-09-05 09:05:16');

-- --------------------------------------------------------

--
-- Table structure for table `post_likes`
--

CREATE TABLE `post_likes` (
  `id` int NOT NULL,
  `post_id` int NOT NULL,
  `user_id` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `referral_commissions`
--

CREATE TABLE `referral_commissions` (
  `id` int NOT NULL,
  `referrer_id` int NOT NULL,
  `referred_user_id` int NOT NULL,
  `payment_id` int NOT NULL,
  `deposit_amount` decimal(12,2) NOT NULL,
  `coins_purchased` decimal(12,2) NOT NULL,
  `commission_rate` decimal(6,4) NOT NULL DEFAULT '0.0500',
  `commission_coins` decimal(12,2) NOT NULL,
  `status` enum('completed') NOT NULL DEFAULT 'completed',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE `reports` (
  `id` int NOT NULL,
  `reporter_id` int NOT NULL,
  `reported_user_id` int NOT NULL,
  `call_id` int NOT NULL,
  `reason` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `status` enum('pending','resolved','dismissed') DEFAULT 'pending',
  `admin_note` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `id` int NOT NULL,
  `call_id` int NOT NULL,
  `client_id` int NOT NULL,
  `influencer_id` int NOT NULL,
  `rating` int NOT NULL,
  `experience_text` text NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `reviews`
--

INSERT INTO `reviews` (`id`, `call_id`, `client_id`, `influencer_id`, `rating`, `experience_text`, `created_at`) VALUES
(1, 38, 2, 1, 5, 'udkugjfhxzhcjkvh', '2026-08-01 00:15:54'),
(2, 40, 2, 1, 5, 'Amamxzing', '2026-08-03 09:51:01'),
(3, 43, 2, 1, 5, 'great', '2026-08-07 11:24:29'),
(4, 44, 2, 1, 5, 'god', '2026-08-07 12:12:16'),
(5, 45, 2, 1, 5, 'nice', '2026-08-07 12:41:26');

-- --------------------------------------------------------

--
-- Table structure for table `saved_influencers`
--

CREATE TABLE `saved_influencers` (
  `id` int NOT NULL,
  `client_id` int NOT NULL,
  `influencer_id` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `saved_influencers`
--

INSERT INTO `saved_influencers` (`id`, `client_id`, `influencer_id`, `created_at`) VALUES
(3, 2, 1, '2026-08-03 21:58:29');

-- --------------------------------------------------------

--
-- Table structure for table `support_agents`
--

CREATE TABLE `support_agents` (
  `id` int NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `password_encrypted` varchar(255) NOT NULL COMMENT 'Reversible (AES) copy so admin can view the generated password',
  `password_checksum` char(64) NOT NULL COMMENT 'SHA-256 of the plaintext password, enforces global password uniqueness',
  `status` enum('active','suspended') NOT NULL DEFAULT 'active',
  `good_feedback_count` int NOT NULL DEFAULT '0',
  `bad_feedback_count` int NOT NULL DEFAULT '0',
  `added_by` int DEFAULT NULL COMMENT 'admin users.id who added this agent',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `support_agents`
--

INSERT INTO `support_agents` (`id`, `first_name`, `last_name`, `email`, `password_hash`, `password_encrypted`, `password_checksum`, `status`, `good_feedback_count`, `bad_feedback_count`, `added_by`, `created_at`) VALUES
(1, 'Ochoyo', 'Moses', 'ochoyomoses@gmail.com', '$2y$10$9IadrJAZ66tyQ15pSN/j5eG33rHgL70PQOA8Z1HJ.P8Z6yflAF16K', 'DuomAksVuMkZJ7iLKJWPbawvR/P6or+UcCla1rrQB0U=', 'af25128dc9fd9938e0637f202268e6178348172d53b54c104b523be44fcfa2ab', 'active', 1, 0, 4, '2026-08-07 09:58:23');

-- --------------------------------------------------------

--
-- Table structure for table `support_conversations`
--

CREATE TABLE `support_conversations` (
  `id` int NOT NULL,
  `customer_id` int NOT NULL COMMENT 'users.id — client or influencer',
  `support_agent_id` int DEFAULT NULL COMMENT 'set once an agent clicks Yes to attend',
  `status` enum('pending','active','ended') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `attended_at` timestamp NULL DEFAULT NULL,
  `ended_at` timestamp NULL DEFAULT NULL,
  `survey_submitted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `support_conversations`
--

INSERT INTO `support_conversations` (`id`, `customer_id`, `support_agent_id`, `status`, `created_at`, `attended_at`, `ended_at`, `survey_submitted`) VALUES
(1, 2, 1, 'ended', '2026-08-07 11:24:48', '2026-08-07 11:57:01', '2026-08-07 11:57:51', 0),
(2, 2, 1, 'ended', '2026-08-07 12:01:27', '2026-08-07 12:01:41', '2026-08-07 12:08:03', 0),
(3, 2, 1, 'ended', '2026-08-07 12:13:56', '2026-08-07 12:14:18', '2026-08-07 12:17:09', 1);

-- --------------------------------------------------------

--
-- Table structure for table `support_feedback`
--

CREATE TABLE `support_feedback` (
  `id` int NOT NULL,
  `conversation_id` int NOT NULL,
  `support_agent_id` int NOT NULL,
  `customer_id` int NOT NULL,
  `satisfied` tinyint(1) NOT NULL COMMENT 'Are you satisfied with our customer care response?',
  `issue_resolved` tinyint(1) NOT NULL COMMENT 'Is your issue resolved?',
  `professional` tinyint(1) NOT NULL COMMENT 'Was the customer care representative professional?',
  `feedback_text` text COMMENT 'Optional manually-entered feedback',
  `is_bad` tinyint(1) NOT NULL COMMENT 'Computed: 1 if satisfied=0 OR issue_resolved=0 OR professional=0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `support_feedback`
--

INSERT INTO `support_feedback` (`id`, `conversation_id`, `support_agent_id`, `customer_id`, `satisfied`, `issue_resolved`, `professional`, `feedback_text`, `is_bad`, `created_at`) VALUES
(1, 3, 1, 2, 1, 1, 1, 'He did excellently amazing and my issues are resolved', 0, '2026-08-07 12:44:05');

-- --------------------------------------------------------

--
-- Table structure for table `support_messages`
--

CREATE TABLE `support_messages` (
  `id` int NOT NULL,
  `conversation_id` int NOT NULL,
  `sender_type` enum('customer','support') NOT NULL,
  `sender_id` int NOT NULL COMMENT 'users.id when sender_type=customer, support_agents.id when sender_type=support',
  `message` text NOT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `support_messages`
--

INSERT INTO `support_messages` (`id`, `conversation_id`, `sender_type`, `sender_id`, `message`, `is_read`, `created_at`) VALUES
(1, 1, 'customer', 2, 'hello', 0, '2026-08-07 11:24:48'),
(2, 1, 'customer', 2, 'good day', 0, '2026-08-07 11:25:49'),
(3, 1, 'support', 1, 'good day, how may we be of help to you', 0, '2026-08-07 11:57:29'),
(4, 2, 'customer', 2, 'hello', 0, '2026-08-07 12:01:27'),
(5, 2, 'support', 1, 'hi, thanks for contacting us, how many we help you.', 0, '2026-08-07 12:03:23'),
(6, 2, 'support', 1, 'please', 0, '2026-08-07 12:03:57'),
(7, 2, 'customer', 2, 'okay', 0, '2026-08-07 12:04:07'),
(8, 3, 'customer', 2, 'Hi, the influencer didn\'t deliver well on the video call and he ended the call', 0, '2026-08-07 12:13:56'),
(9, 3, 'support', 1, 'Hi, thanks for contacting masked party support team. can you please give provide your email address for further assistance.', 0, '2026-08-07 12:15:05'),
(10, 3, 'customer', 2, 'james234@gmail.com', 0, '2026-08-07 12:15:32'),
(11, 3, 'support', 1, 'kindly hold let me check please, we\'ll get back to you shortly', 0, '2026-08-07 12:16:12'),
(12, 3, 'customer', 2, 'alright please', 0, '2026-08-07 12:16:39');

-- --------------------------------------------------------

--
-- Table structure for table `support_tokens`
--

CREATE TABLE `support_tokens` (
  `id` int NOT NULL,
  `support_agent_id` int NOT NULL,
  `token` varchar(255) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `support_tokens`
--

INSERT INTO `support_tokens` (`id`, `support_agent_id`, `token`, `expires_at`, `created_at`) VALUES
(1, 1, '2e2d5d8fe389b4e52954c56860afb9b6094d29ab9fd1fe6a69d38dfef8375554', '2026-09-06 09:58:45', '2026-08-07 09:58:45'),
(2, 1, '1627fd438dae41fc5e705d81c49e61f22a5b7a99766acffbe49905cfa009770a', '2026-09-06 10:00:19', '2026-08-07 10:00:19'),
(3, 1, '88245d0e12b6da34f1a33b04c2ce6b5ab628235c4cb096774b6c487ad06c8cf4', '2026-09-06 10:01:59', '2026-08-07 10:01:59'),
(4, 1, 'd757dc8ed93ec046620f85396177bd2d9f649f91164d595720d1ab121bb6ae14', '2026-09-06 10:04:40', '2026-08-07 10:04:40'),
(5, 1, 'f9008e4021ca8de1e22808ecaafaf8397afced22dc189aae6b3f5493e3a13303', '2026-09-06 10:04:44', '2026-08-07 10:04:44'),
(6, 1, '7ffa35b5f716a02eee664cf7c5b312a2b00fdcf1f80e473ce5417344c3a3468f', '2026-09-06 10:04:47', '2026-08-07 10:04:47'),
(7, 1, '085e2f2efd1e9554a19427b383a07e3a454c2bd3c37c03b199abf9e51586c90b', '2026-09-06 10:04:50', '2026-08-07 10:04:50'),
(8, 1, '1862e174aa72202115a0acaa984ec574f5a786a04175f57f7e52641f8625a20d', '2026-09-06 10:07:50', '2026-08-07 10:07:50'),
(9, 1, '52d3ef6f8ced4d5f343a9258a385cd5bb027dae8255b93c6582a8d2b93354334', '2026-09-06 10:18:58', '2026-08-07 10:18:58'),
(10, 1, '6d7b9f35ff201033058e5b66269c298e69cc5392022cc335e0a19cc98ce27b64', '2026-09-06 13:43:42', '2026-08-07 13:43:42');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `mystery_name` varchar(100) NOT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `role` enum('client','influencer','admin') NOT NULL,
  `referral_code` varchar(20) DEFAULT NULL,
  `referred_by` int DEFAULT NULL,
  `country_name` varchar(100) DEFAULT NULL,
  `country_code` varchar(10) DEFAULT NULL,
  `bank_name` varchar(255) DEFAULT NULL,
  `account_number` varchar(100) DEFAULT NULL,
  `profile_photo` varchar(255) DEFAULT NULL,
  `status` enum('active','pending_verification','suspended','banned') DEFAULT 'active',
  `authenticated` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `bank_code_type` varchar(50) DEFAULT NULL,
  `bank_code_value` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `email`, `password`, `mystery_name`, `full_name`, `role`, `referral_code`, `referred_by`, `country_name`, `country_code`, `bank_name`, `account_number`, `profile_photo`, `status`, `authenticated`, `created_at`, `bank_code_type`, `bank_code_value`) VALUES
(1, 'ochoyomoses@gmail.com', '$2y$10$16AhADW/xc4gDA803.2Og.MfzWfyJVHdTM.Q7Qt7i.KjcE8lX/4Tu', 'Jane', 'Ochoyo Moses', 'influencer', 'GTAT52DA', NULL, 'Australia', '', 'Opay', '9052213694', 'chat/images/c22a107c874f1f71d1183e2685100f0d.jpg', 'active', 1, '2026-07-20 20:21:11', NULL, NULL),
(2, 'james@example.com', '$2y$10$exFMzyrqSoM7UWZoatDlbeTcvCtfw.3k7i30Q9WPTtSpnM2nxMEUi', 'James', '', 'client', '6HB5G4HU', NULL, 'Nigeria', '', '', '', 'chat/images/039e2038985d020ddd625defc005cc5a.jpg', 'active', 1, '2026-07-20 20:28:19', NULL, NULL),
(3, 'moses@gmail.com', '$2y$10$oZtvXJbjk2cDXSjALB/rbe5wr3bMh8syxfqCJyRNf9DEBSIXIGU2u', 'Ochoyo', 'Ochoyo Moses', 'influencer', NULL, NULL, 'Canada', '', 'Ochoyo Moses', '9052213694', NULL, 'active', 0, '2026-07-22 14:54:46', NULL, NULL),
(4, 'mosesalidu18@gmail.com', '$2y$10$QkNiwoEUqO3h.RXseTlETuJ17sD.OueyACrDBVOJCSplDsqQpLTHq', 'Emmizzy', 'Emmanuel James', 'admin', 'ME4EK355', NULL, 'Nigeria', '', 'Opay', '9052213694', NULL, 'pending_verification', 0, '2026-07-31 16:12:54', NULL, NULL),
(8, 'devochoyo@gmail.com', '$2y$10$NYaOL62VAT3DwZoo/lM7uey8EE6sdPlLmqOAryB/JYe7KLIyZ/1Zq', 'Ochizzy', 'Oche Moses', 'influencer', 'UTNE4P5S', NULL, 'Nigeria', '', 'First Bank Of Nigeria', '3213170382', NULL, 'active', 1, '2026-08-05 01:22:32', 'SWIFT', 'FBNGLA72424234'),
(9, 'jobstreamcustomer@gmail.com', '$2y$10$l7ITjQ1hBMW/qMDW/UoDu.PgUt64GtIl0Vbvxom14rTN/HKvo7V.a', 'Amelia', 'Amelia Lee', 'influencer', 'A896S9EZ', NULL, 'United Kingdom', '', 'Opay', '9052213694', 'chat/images/054d00aefd4bec37fc712810bebbf551.jpg', 'active', 1, '2026-09-05 08:39:45', 'SWIFT', 'FGNLA92422');

-- --------------------------------------------------------

--
-- Table structure for table `user_tokens`
--

CREATE TABLE `user_tokens` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `token` varchar(255) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `user_tokens`
--

INSERT INTO `user_tokens` (`id`, `user_id`, `token`, `expires_at`, `created_at`) VALUES
(1, 1, '6dd452024ee6b29136bd655daf231194ce0f0828804611b296a997d93a3cdfc0', '2026-08-19 20:21:11', '2026-07-20 20:21:11'),
(2, 1, '94f2fe2e2712f972af10297e65f6ca007f4d41548779b6d08f8a008a9536a161', '2026-08-19 20:25:54', '2026-07-20 20:25:54'),
(3, 2, 'f3634087028ac92ecc8bf41bf13c6391f287c766249f2a34cf14d66a081e73aa', '2026-08-19 20:28:19', '2026-07-20 20:28:19'),
(4, 2, '06f627bb078459aa7a7c85f057d43f70ca200b8e8c86201ebe4cc324b2f991d4', '2026-08-19 20:28:33', '2026-07-20 20:28:33'),
(5, 2, 'eaf7c62253b79f1e5e6b355cbe9619a05f7db0be868ad51d0f61bc08f6f5d5eb', '2026-08-19 20:55:58', '2026-07-20 20:55:58'),
(6, 2, 'b493097635c7202670e002d648c1ae3cd34199ee15702376d1abeb14708a5f2e', '2026-08-19 21:17:12', '2026-07-20 21:17:12'),
(7, 2, '24b51bd026cd2a97e22e0f363878605eae4336f4a3dd105dd6582156635cf5d4', '2026-08-20 08:17:11', '2026-07-21 08:17:11'),
(8, 2, '25ba13d0debb3100d6198b6e5ff81339f74d2f431f6cb4a76001ee2e7c58fdcf', '2026-08-20 08:19:39', '2026-07-21 08:19:39'),
(9, 2, 'e7f06c03c53bd36df14600ad273ca4280cf567b9d5e82385ed1184fc4c871f29', '2026-08-20 12:39:40', '2026-07-21 12:39:40'),
(11, 2, 'f0c8b2495e3e8da59e6bbddf7fd6065507f3d95a4e9673b2b09f20e51be0ad3a', '2026-08-21 14:25:26', '2026-07-22 14:25:26'),
(12, 3, '1e38881115739d5b5643cbb76286737e220b8102319d9e4ba0911b8bb540e9fd', '2026-08-21 14:54:46', '2026-07-22 14:54:46'),
(13, 3, 'e5c1662ce8354d25e9b184d2488ffe85392c204036e04437b50c44f13ab89578', '2026-08-21 14:55:03', '2026-07-22 14:55:03'),
(14, 2, 'c21ebf135b7979d0633879a853a3bceec5ac7bd1fc377ab47ec85728823ef3a8', '2026-08-21 15:56:01', '2026-07-22 15:56:01'),
(15, 2, '8b45662818cfcb563e29e07799ddcb34a22f160cc6a70818dd1c159d17b8d84e', '2026-08-23 06:52:47', '2026-07-24 06:52:47'),
(21, 1, '6baf52917bba467aca0453e718aea9b7b86e216bd821c629266130a45b36eba6', '2026-08-23 08:20:47', '2026-07-24 08:20:47'),
(22, 1, '2c354a1d0582bc03076c9a758a49456cd4dd68a2f22dfe895a176442d3f5ed2e', '2026-08-23 08:24:25', '2026-07-24 08:24:25'),
(23, 1, 'b1c2f16b14619abe719637e241ef95411219567e9d7492cf58e4a8bd1c4cc4a1', '2026-08-23 08:51:19', '2026-07-24 08:51:19'),
(24, 1, '2dda00b8797b28f312e66a6804cbee4aad7a8bf00cc06b7a58317b30bbbdc02b', '2026-08-23 16:43:03', '2026-07-24 16:43:03'),
(25, 1, 'd6fe5bfe1c77e90942caa74a622e43dbd9566a641add4f688b30bfcceac2e802', '2026-08-23 21:58:09', '2026-07-24 21:58:09'),
(28, 2, '15c3d92c81da1d7c848249e5c12ca5f08e1d408a752592d8938241f4a7428173', '2026-08-26 09:34:04', '2026-07-27 09:34:04'),
(29, 1, '538e6fb1a8472d012130e2cd5649d1783bd7dc82162ad5ebe4aa6d2fcc95c26c', '2026-08-26 09:36:06', '2026-07-27 09:36:06'),
(30, 2, 'a75df7628eb89dd4d17b576b98dcd985a115f9f57efc83cb6276e89fb4c7c903', '2026-08-28 22:10:17', '2026-07-29 22:10:17'),
(31, 2, '7572eae931eeb4fbcc361193f87a90abef092620ee6d8f18eef3ba9bad7d520c', '2026-08-28 22:28:57', '2026-07-29 22:28:57'),
(33, 4, 'b016b8941ba4ac4b83207c3cdba6cd612124ac2f11be15456bfffd3c8a19c487', '2026-08-30 16:12:54', '2026-07-31 16:12:54'),
(34, 4, '88115b28f51af756d01c1d8ae1347792358749c3b8f1a19e710baccf3f733aaf', '2026-08-30 16:13:09', '2026-07-31 16:13:09'),
(36, 4, '1c67b35fc939702d1fb275b310031483e897a209a26246458547604e0fa163b8', '2026-08-30 20:19:51', '2026-07-31 20:19:51'),
(37, 1, '2183a6efaf54d2bc6ca43c7ac5e121bc7ce93c937f63435bec487d02e9afa4d3', '2026-08-30 20:20:55', '2026-07-31 20:20:55'),
(39, 4, '186f10eed4e28bb5d41bdba38c57b6fa768d0e47f5f741cf6d6b2a8881a350f8', '2026-08-30 23:13:45', '2026-07-31 23:13:45'),
(40, 4, 'be91a7cdfde69ef286fccc9a2e21a6f89f0d55b771976e2675896984c4b1260f', '2026-08-31 00:26:16', '2026-08-01 00:26:16'),
(42, 4, '90c1949b701ae2c4020e2886a1efb28ca3554970d5a0d50a96b8fc8ac5292748', '2026-09-02 09:28:04', '2026-08-03 09:28:04'),
(43, 2, '82558f673bab7dc991492d4461387e1be8f87e623ba6494adc51bf844d0118d0', '2026-09-02 09:41:54', '2026-08-03 09:41:54'),
(46, 1, 'c2058cbca1202f364656e9d3e8c117412e0f8cbc1cd8b73cdb4424d6e94c975a', '2026-09-02 13:03:52', '2026-08-03 13:03:52'),
(47, 1, '09fe409305500cf87d26102fb298d39092ccdccf906d2d98a9a47afe0593845b', '2026-09-02 19:18:37', '2026-08-03 19:18:37'),
(50, 2, '0d137981983620d156e888a5e780e2cd3a73ffe5b08ef0154e1aacd6988f184c', '2026-09-03 16:08:50', '2026-08-04 16:08:50'),
(51, 1, 'b6af1e07abf544e630fc0d26af37053d7e804e3e218aa9569dc223685a45a45a', '2026-09-03 16:27:40', '2026-08-04 16:27:40'),
(53, 4, '7bd05c46fbb486f715178c15ee50721a47ec1477497a3dbea9a74b83b63dfde1', '2026-09-03 17:28:26', '2026-08-04 17:28:26'),
(58, 4, '8e47185e53cf7f2922e0331a8a77be59303b8b354e520b799d820f3938a299ed', '2026-09-03 20:25:03', '2026-08-04 20:25:03'),
(60, 8, '6ec99b26c309f39a283c8f1c9661da5a2fbbfc56d9e36b4a2d43750fb4d4e151', '2026-09-04 01:22:32', '2026-08-05 01:22:32'),
(62, 8, 'a07b5a8fe954cc9fcfed008bf7c4cdd4960c9576fe4d69f7b999d88cc3a5e859', '2026-09-05 17:35:56', '2026-08-06 17:35:56'),
(63, 4, '7552d70378a20ff3d437100a0eb984daabb248d83f8de69b730aed3380cabb70', '2026-09-06 09:57:39', '2026-08-07 09:57:39'),
(64, 2, '7f356aa37f859a941561a272ba18e41a3c7c27aa524d72a1249d89736140c2a7', '2026-09-06 11:18:18', '2026-08-07 11:18:18'),
(66, 4, '1840bf6c9f591e6f5dd843bbddba03df36d6fa6ad52e0ff72ea6f823ff173bb5', '2026-09-06 11:40:41', '2026-08-07 11:40:41'),
(67, 4, '66deddaba57c6ffddd60417cb65a3339a34a573850e2b5f6531588987808fccf', '2026-09-06 12:58:49', '2026-08-07 12:58:49'),
(68, 4, '77ac8a6ab86cb40e2f8c345d3acc8e603dc80ac9dd81e22fe5cb940f55cbc093', '2026-09-13 06:41:13', '2026-08-14 06:41:13'),
(71, 1, '228e36ffcc4fd8243597857eb694208d8a3b2a35cd97b0b0e19d494f8f12719d', '2026-09-19 10:22:49', '2026-08-20 10:22:49'),
(72, 4, '67ad59c36a5ddca8c81beb7eb6a0f7f766518d63e8a5b286d73e30a9693187c7', '2026-09-19 10:23:09', '2026-08-20 10:23:09'),
(73, 2, 'cf04a1b10066aa8b539f6b2cf50bb7593197cbd6c9a42e9f66cf4785e32c929a', '2026-09-19 10:32:37', '2026-08-20 10:32:37'),
(78, 2, 'e750baf23d579edc0cd7823bae08dfc7cb11a660f7c74d161b222c1d74ede173', '2026-09-21 09:27:19', '2026-08-22 09:27:19'),
(80, 1, '39e3c3acef5b15b79ded4a84549567bccf05047f2f0fcf0ca8f58fff1468363d', '2026-09-23 10:48:49', '2026-08-24 10:48:49'),
(81, 4, '6c6e863d7500fe6d1035bf006010ed3d3ce227b46dc0138ace395f5f2c6b3a14', '2026-09-23 11:26:44', '2026-08-24 11:26:44'),
(82, 4, 'cfc53947dbf4ec6e22ea0e5074e8e6b5da7a81cb068cb31946417c0640582816', '2026-09-23 12:35:02', '2026-08-24 12:35:02'),
(84, 1, '6561d94a746bf1c0a8582e4ff4ecc14ba00bf39b0ea6ccd47bb35695ff8c1850', '2026-09-23 12:42:20', '2026-08-24 12:42:20'),
(85, 2, 'a85e5acf21eb93d1b591f38222cdc64b43152f1aa834848b999ee5f971fbddc7', '2026-09-24 01:02:08', '2026-08-25 01:02:08'),
(86, 1, 'be3130c18ff189fff7ef208d4c15a42190a002d24f92f38de64717f4d97f3f0b', '2026-09-24 01:04:39', '2026-08-25 01:04:39'),
(87, 2, 'ed4358e25037638150db841ef5f208b9811d571e755a08df02575d97b8bdc63e', '2026-09-25 19:26:31', '2026-08-26 19:26:31'),
(89, 9, '1b3dcccda38224758de99818213c88a64c314a2b97f009f58351c10dc5e6e43c', '2026-10-05 08:39:45', '2026-09-05 08:39:45'),
(90, 9, '8a6a4f6a83c05de9ad2c79fece9ca9bade34de66791459f005a1fdc47c7c8ebf', '2026-10-05 08:58:19', '2026-09-05 08:58:19'),
(91, 4, '70fc8957a990563e9de0e80c02d63050b57bf64789384d37c932fb7c68813dcf', '2026-10-05 08:58:24', '2026-09-05 08:58:24'),
(92, 2, 'e7b4760c0ac474a873369097431187ce73889c83953e45e1033551d8fdb1a87e', '2026-10-05 09:16:06', '2026-09-05 09:16:06'),
(93, 4, '1cee397da4bb3bdd7979edaea80c123c21180de280474494c5d77ee352a4a958', '2026-10-05 09:33:00', '2026-09-05 09:33:00'),
(94, 4, 'ef0bc9525b60503f02f215ab2472667c8654535979c30b81164cf6b97fd77c04', '2026-10-05 09:39:12', '2026-09-05 09:39:12'),
(97, 9, '8831a5595ef37afa4ae88c74d41dd27979df7d8b7d99e2dbad2d59066aec2f18', '2026-10-18 04:32:17', '2026-09-18 04:32:17');

-- --------------------------------------------------------

--
-- Table structure for table `video_calls`
--

CREATE TABLE `video_calls` (
  `id` int NOT NULL,
  `call_request_id` int DEFAULT NULL,
  `client_id` int NOT NULL,
  `influencer_id` int NOT NULL,
  `billing_mode` enum('standard','payg_minute','payg_second') NOT NULL DEFAULT 'standard',
  `meeting_id` varchar(255) DEFAULT NULL,
  `meeting_token` text,
  `coins_spent` decimal(20,4) NOT NULL DEFAULT '0.0000',
  `price_per_minute` decimal(15,4) NOT NULL DEFAULT '0.0000',
  `price_per_second` decimal(15,6) NOT NULL DEFAULT '0.000000',
  `duration_minutes` int NOT NULL,
  `paid_duration_seconds` int NOT NULL DEFAULT '0',
  `actual_duration_seconds` int DEFAULT '0',
  `last_extended_at` timestamp NULL DEFAULT NULL,
  `escrow_status` enum('held','released','refunded') DEFAULT 'held',
  `status` enum('active','completed','cancelled') DEFAULT 'active',
  `start_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `end_time` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `video_calls`
--

INSERT INTO `video_calls` (`id`, `call_request_id`, `client_id`, `influencer_id`, `billing_mode`, `meeting_id`, `meeting_token`, `coins_spent`, `price_per_minute`, `price_per_second`, `duration_minutes`, `paid_duration_seconds`, `actual_duration_seconds`, `last_extended_at`, `escrow_status`, `status`, `start_time`, `end_time`) VALUES
(3, 9, 2, 1, 'standard', 'mock_meeting_6a632d7353bec', 'mock_token_51006523c61401ab489e430b13d68d4b', 100.0000, 100.0000, 0.000000, 1, 60, 63, NULL, 'released', 'completed', '2026-07-24 09:16:35', '2026-07-24 09:17:38'),
(4, 11, 2, 1, 'standard', 'mock_meeting_6a6330af8bc1b', 'mock_token_a2019ae6a2481642208ee9b9ca2c1cad', 100.0000, 100.0000, 0.000000, 1, 60, 60, NULL, 'released', 'completed', '2026-07-24 09:30:25', '2026-07-24 09:31:25'),
(5, 17, 2, 1, 'standard', '2ncb-z1gw-6uka', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjJuY2ItejFndy02dWthIiwicGFydGljaXBhbnRJZCI6IjZhNjMzYmQ2ZDUyM2EiLCJpYXQiOjE3ODQ4ODgyNzgsImV4cCI6MTc4NDk3NDY3OH0.VDGektJczrxwpbFeS0R6WVhpPH2PiizaFvxohBWinh0', 100.0000, 100.0000, 0.000000, 1, 60, 62, NULL, 'released', 'completed', '2026-07-24 10:17:59', '2026-07-24 10:19:01'),
(6, 18, 2, 1, 'standard', 'j8j1-xmlm-7baj', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Imo4ajEteG1sbS03YmFqIiwiaWF0IjoxNzg0ODg4NTYzLCJleHAiOjE3ODQ5NzQ5NjN9.in1TbHNeBU8Kg8RLiFXruRm0xQ9AtDioK5D2a0bcR_U', 100.0000, 100.0000, 0.000000, 1, 60, 61, NULL, 'released', 'completed', '2026-07-24 10:22:43', '2026-07-24 10:23:44'),
(7, 19, 2, 1, 'standard', 'y9xo-0xfx-f4lp', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Ink5eG8tMHhmeC1mNGxwIiwiaWF0IjoxNzg0ODg5MzE4LCJleHAiOjE3ODQ5NzU3MTh9.134NNY7dHXWlqiJEcpJC9Cr_uvO7zbH-tQiSDQZ-SKA', 100.0000, 100.0000, 0.000000, 1, 60, 36, NULL, 'released', 'completed', '2026-07-24 10:35:20', '2026-07-24 10:35:56'),
(8, 20, 2, 1, 'standard', '2v2o-xmz9-cnmh', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjJ2Mm8teG16OS1jbm1oIiwiaWF0IjoxNzg0ODk0ODQ4LCJleHAiOjE3ODQ5ODEyNDh9.JuL5EKA6WUt9azqp6AI6pkkJ_seaAPVisMUWM9tUha4', 100.0000, 100.0000, 0.000000, 1, 60, 67, NULL, 'released', 'completed', '2026-07-24 12:07:28', '2026-07-24 12:08:35'),
(9, 21, 2, 1, 'standard', 'jijv-84ig-hgej', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImppanYtODRpZy1oZ2VqIiwiaWF0IjoxNzg0ODk1MDEzLCJleHAiOjE3ODQ5ODE0MTN9.Al6VntGO7J9xMJfZRUKgR96gdmgJ1lutpoPwRwGQjnY', 100.0000, 100.0000, 0.000000, 1, 60, 75, NULL, 'released', 'completed', '2026-07-24 12:10:13', '2026-07-24 12:11:28'),
(10, 22, 2, 1, 'standard', 'koey-z7z4-p5y1', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImtvZXktejd6NC1wNXkxIiwiaWF0IjoxNzg0ODk1MTI2LCJleHAiOjE3ODQ5ODE1MjZ9.misnqZj1LS7qpPSKxI210K3vRgU4N4F8Wk0-DYVsmsM', 100.0000, 100.0000, 0.000000, 1, 60, 62, NULL, 'released', 'completed', '2026-07-24 12:12:09', '2026-07-24 12:13:11'),
(11, 23, 2, 1, 'standard', '8djx-nltr-7hky', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Ijhkangtbmx0ci03aGt5IiwiaWF0IjoxNzg0ODk1OTA3LCJleHAiOjE3ODQ5ODIzMDd9.hJCEiTPjFTwPcEjczYF2FWe0e9gpvBetq4HcmlRs2Mg', 100.0000, 100.0000, 0.000000, 1, 60, 68, NULL, 'released', 'completed', '2026-07-24 12:25:07', '2026-07-24 12:26:15'),
(12, 24, 2, 1, 'standard', 'gb2j-q4cv-ec5s', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImdiMmotcTRjdi1lYzVzIiwiaWF0IjoxNzg0ODk2MDg0LCJleHAiOjE3ODQ5ODI0ODR9.8JJR38gM7JtjAiHB-HkwVLbTSBxvQE2E9PayY0a03OQ', 100.0000, 100.0000, 0.000000, 1, 60, 70, NULL, 'released', 'completed', '2026-07-24 12:28:04', '2026-07-24 12:29:14'),
(13, 25, 2, 1, 'standard', 'cbqw-ycd0-12i8', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImNicXcteWNkMC0xMmk4IiwiaWF0IjoxNzg0ODk4MDU2LCJleHAiOjE3ODQ5ODQ0NTZ9.ATqmTrqSoCgA32dJiSsPVN_DsKNfsd584nr2ef2gIDI', 100.0000, 100.0000, 0.000000, 1, 60, 63, NULL, 'released', 'completed', '2026-07-24 13:00:56', '2026-07-24 13:01:59'),
(14, 26, 2, 1, 'standard', 'jyy4-qm3k-xiyv', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Imp5eTQtcW0zay14aXl2IiwiaWF0IjoxNzg0ODk4MTUyLCJleHAiOjE3ODQ5ODQ1NTJ9.VomtBfMtAUGkfVlK0MAsI5GdERE_Eqsb8aKJr9BM9Ao', 100.0000, 100.0000, 0.000000, 1, 60, 60, NULL, 'released', 'completed', '2026-07-24 13:02:33', '2026-07-24 13:03:33'),
(15, 27, 2, 1, 'standard', '62gh-1qm4-zhln', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjYyZ2gtMXFtNC16aGxuIiwiaWF0IjoxNzg0ODk4MjQyLCJleHAiOjE3ODQ5ODQ2NDJ9.VifXPs6snP5iSxYOwTDNs-WJGFcBzt_x0oqEH2A5zaU', 100.0000, 100.0000, 0.000000, 1, 60, 69, NULL, 'released', 'completed', '2026-07-24 13:04:02', '2026-07-24 13:05:11'),
(16, 28, 2, 1, 'standard', 'k8bm-xh59-a53j', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Ims4Ym0teGg1OS1hNTNqIiwiaWF0IjoxNzg0ODk4Mzg3LCJleHAiOjE3ODQ5ODQ3ODd9.IJ24Sald7RQH-_jwYhXxmadaWSOkWy7zhhxXjNSr6zA', 100.0000, 100.0000, 0.000000, 1, 60, 62, NULL, 'released', 'completed', '2026-07-24 13:06:28', '2026-07-24 13:07:30'),
(17, 29, 2, 1, 'standard', 'fm96-x8bp-ypql', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImZtOTYteDhicC15cHFsIiwiaWF0IjoxNzg0ODk5MjUyLCJleHAiOjE3ODQ5ODU2NTJ9.kQyrVmWSr0g1Fw5jLSEJDbM1YSGi7MOtUkqpJyEnS58', 1600.0000, 100.0000, 0.000000, 16, 960, 963, '2026-07-24 13:21:16', 'released', 'completed', '2026-07-24 13:20:52', '2026-07-24 13:36:55'),
(18, 30, 2, 1, 'standard', 'w0ba-1ig9-l5q1', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IncwYmEtMWlnOS1sNXExIiwiaWF0IjoxNzg1MTQyMDQ3LCJleHAiOjE3ODUyMjg0NDd9.bWbd43cDE-9PuDY9nuzSDmFOcXQTkQksyHK7R9oMg6U', 100.0000, 100.0000, 0.000000, 1, 60, 63, NULL, 'released', 'completed', '2026-07-27 08:47:28', '2026-07-27 08:48:31'),
(19, 31, 2, 1, 'standard', 'k2g7-ud11-fd30', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImsyZzctdWQxMS1mZDMwIiwiaWF0IjoxNzg1MTQyMzE5LCJleHAiOjE3ODUyMjg3MTl9.Kg1uXT-wJB1IxJYzW6kWLf9ToikJ6lpKQ6_EfVxuxOw', 100.0000, 100.0000, 0.000000, 1, 60, 62, NULL, 'released', 'completed', '2026-07-27 08:52:01', '2026-07-27 08:53:03'),
(20, 32, 2, 1, 'standard', '2fdq-c41l-iium', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjJmZHEtYzQxbC1paXVtIiwiaWF0IjoxNzg1MTQ1MDY0LCJleHAiOjE3ODUyMzE0NjR9.wSWLANVZ3Ut9sIda6SR-sfLdajRW-twlVncVmUQ6dxU', 6.0000, 1.0000, 0.000000, 6, 360, 361, '2026-07-27 09:38:45', 'released', 'completed', '2026-07-27 09:37:46', '2026-07-27 09:43:48'),
(21, 33, 2, 1, 'standard', 'flon-3pvb-h5co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImZsb24tM3B2Yi1oNWNvIiwiaWF0IjoxNzg1MTQ1OTUyLCJleHAiOjE3ODUyMzIzNTJ9.NAzbtdmtWxKg1SFMI-zEVcz34sArEp1kYw4XYNurMBQ', 15.0000, 1.0000, 0.000000, 15, 900, 0, '2026-07-27 10:01:46', 'released', 'completed', '2026-07-27 09:52:33', NULL),
(22, 34, 2, 1, 'standard', 'hkgi-sy4i-su7v', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImhrZ2ktc3k0aS1zdTd2IiwiaWF0IjoxNzg1MTUwODU4LCJleHAiOjE3ODUyMzcyNTh9.swhk0my7jnEj1-NRZAtc8pJYPTVdBqfEJm-TXHoCKGI', 5.0000, 1.0000, 0.000000, 5, 300, 42, '2026-07-27 11:14:27', 'released', 'completed', '2026-07-27 11:14:18', '2026-07-27 11:15:00'),
(23, 35, 2, 1, 'standard', 'y40m-ie7h-cbt4', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Ink0MG0taWU3aC1jYnQ0IiwiaWF0IjoxNzg1MTUxNTIyLCJleHAiOjE3ODUyMzc5MjJ9.RAGIXWokOK-y4EOY-zs3AlsKHgpiQTybdQRjj1kep9E', 5.0000, 1.0000, 0.000000, 5, 300, 66, '2026-07-27 11:25:26', 'released', 'completed', '2026-07-27 11:25:23', '2026-07-27 11:26:29'),
(24, 36, 2, 1, 'standard', 'aolu-yve5-26cg', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImFvbHUteXZlNS0yNmNnIiwiaWF0IjoxNzg1MTUyMzIzLCJleHAiOjE3ODUyMzg3MjN9.3pRga_o_wcvsLJD1Fs6rezTTStK1dgZFagKLmPLN7jk', 5.0000, 1.0000, 0.000000, 5, 300, 94, '2026-07-27 11:38:46', 'released', 'completed', '2026-07-27 11:38:43', '2026-07-27 11:40:17'),
(25, 37, 2, 1, 'standard', 'pl4s-lglq-2ydb', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InBsNHMtbGdscS0yeWRiIiwiaWF0IjoxNzg1MTUyNTg5LCJleHAiOjE3ODUyMzg5ODl9.yGz6Y-skSAsn98KJMyKM6gMDhVuw8XcLYdNTBtfbG3o', 5.0000, 1.0000, 0.000000, 5, 300, 67, '2026-07-27 11:43:12', 'released', 'completed', '2026-07-27 11:43:09', '2026-07-27 11:44:16'),
(26, 38, 2, 1, 'standard', 'tfa6-f0gr-l1ct', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InRmYTYtZjBnci1sMWN0IiwiaWF0IjoxNzg1NTMwNjI5LCJleHAiOjE3ODU2MTcwMjl9.8COoyQ-dGtZEc8senNXyd16Dbz4E0Dxod1QmwSkU9eQ', 5.0000, 1.0000, 0.000000, 5, 300, 76, '2026-07-31 20:43:54', 'released', 'completed', '2026-07-31 20:43:49', '2026-07-31 20:45:05'),
(27, 39, 2, 1, 'standard', '78kf-j0wf-egrw', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Ijc4a2YtajB3Zi1lZ3J3IiwiaWF0IjoxNzg1NTMyNDU2LCJleHAiOjE3ODU2MTg4NTZ9.mq8lLaYjzPF_XPH4R1mxVI1QQEsevw_rO8yJrRl3S1Q', 5.0000, 1.0000, 0.000000, 5, 300, 140, '2026-07-31 21:14:27', 'released', 'completed', '2026-07-31 21:14:16', '2026-07-31 21:16:36'),
(28, 40, 2, 1, 'standard', 'z774-kfmc-2mkd', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Ino3NzQta2ZtYy0ybWtkIiwiaWF0IjoxNzg1NTMzODQzLCJleHAiOjE3ODU2MjAyNDN9.Gsq-CHdQow2Ra4akhWoJgt7-_GeYRWuNFXAEygpZNeE', 5.0000, 1.0000, 0.000000, 5, 300, 71, '2026-07-31 21:37:27', 'released', 'completed', '2026-07-31 21:37:24', '2026-07-31 21:38:35'),
(29, 41, 2, 1, 'standard', 'n6pt-1jtf-a2jg', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Im42cHQtMWp0Zi1hMmpnIiwiaWF0IjoxNzg1NTM1NDU0LCJleHAiOjE3ODU2MjE4NTR9._Wpq_ViBsvzEOc7WRrtUFGMBi2xp-FygsNbLhIK2Ztc', 5.0000, 1.0000, 0.000000, 5, 300, 52, '2026-07-31 22:04:19', 'released', 'completed', '2026-07-31 22:04:15', '2026-07-31 22:05:07'),
(30, 42, 2, 1, 'standard', 'v7xb-wqc1-ddkj', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InY3eGItd3FjMS1kZGtqIiwiaWF0IjoxNzg1NTM4MjUwLCJleHAiOjE3ODU2MjQ2NTB9.wVG4C-MeOsk6x1fxOvrlZ_3mlffdZlOIAR9u7d2vQ84', 5.0000, 1.0000, 0.000000, 5, 300, 109, '2026-07-31 22:50:55', 'released', 'completed', '2026-07-31 22:50:50', '2026-07-31 22:52:39'),
(31, 43, 2, 1, 'standard', 'waqb-tgi1-mc5a', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IndhcWItdGdpMS1tYzVhIiwiaWF0IjoxNzg1NTM5NDIxLCJleHAiOjE3ODU2MjU4MjF9.vyJAo8prq3F_vgnO-KPhX0MyJu3Z_MbDXOT8Qt9fOns', 5.0000, 1.0000, 0.000000, 5, 300, 39, '2026-07-31 23:10:25', 'released', 'completed', '2026-07-31 23:10:21', '2026-07-31 23:11:00'),
(32, 44, 2, 1, 'standard', 'rhnc-ed3i-tjc2', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InJobmMtZWQzaS10amMyIiwiaWF0IjoxNzg1NTM5NzUyLCJleHAiOjE3ODU2MjYxNTJ9.GTGoKoUfNXm5eDvwM6_h73n3tOpfdZ66AhpeXGPqTWk', 5.0000, 1.0000, 0.000000, 5, 300, 104, '2026-07-31 23:15:55', 'released', 'completed', '2026-07-31 23:15:53', '2026-07-31 23:17:37'),
(33, 45, 2, 1, 'standard', 'vguy-o0bu-9or4', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InZndXktbzBidS05b3I0IiwiaWF0IjoxNzg1NTQwNDQyLCJleHAiOjE3ODU2MjY4NDJ9.G-0Rlu_angCI8lADoZrVzuEVTu5RbyZQW4KFnomBJs8', 5.0000, 1.0000, 0.000000, 5, 300, 76, '2026-07-31 23:27:26', 'released', 'completed', '2026-07-31 23:27:24', '2026-07-31 23:28:40'),
(34, 46, 2, 1, 'standard', 'su5p-52u8-337v', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InN1NXAtNTJ1OC0zMzd2IiwiaWF0IjoxNzg1NTQwNjk0LCJleHAiOjE3ODU2MjcwOTR9.BFrC_NBYLBbn5tQZnWWplnZaDBCOCrrY-PMUcHPWxE4', 5.0000, 1.0000, 0.000000, 5, 300, 46, '2026-07-31 23:31:37', 'released', 'completed', '2026-07-31 23:31:34', '2026-07-31 23:32:20'),
(35, 47, 2, 1, 'standard', '658y-6swo-f6x7', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjY1OHktNnN3by1mNng3IiwiaWF0IjoxNzg1NTQxNzE3LCJleHAiOjE3ODU2MjgxMTd9.GQjJpUX6rsA7DLC0rCAZ1THdRjnq8ZpzKa1K_1nYnyI', 5.0000, 1.0000, 0.000000, 5, 300, 63, '2026-07-31 23:48:42', 'released', 'completed', '2026-07-31 23:48:37', '2026-07-31 23:49:40'),
(36, 48, 2, 1, 'standard', '34sv-dq2n-le6e', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjM0c3YtZHEybi1sZTZlIiwiaWF0IjoxNzg1NTQyMDM2LCJleHAiOjE3ODU2Mjg0MzZ9.Fsg_a20Jlkec-P8ugGvSs2xAbbixbXOHclk1WH_6-mk', 5.0000, 1.0000, 0.000000, 5, 300, 60, '2026-07-31 23:53:58', 'released', 'completed', '2026-07-31 23:53:56', '2026-07-31 23:54:56'),
(37, 49, 2, 1, 'standard', '39qi-fipq-56zl', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6IjM5cWktZmlwcS01NnpsIiwiaWF0IjoxNzg1NTQyNjE5LCJleHAiOjE3ODU2MjkwMTl9.jmxWNQPvrVdoP_gsVMlCI_AysoRVvtPllSjVWvLvdhA', 5.0000, 1.0000, 0.000000, 5, 300, 30, '2026-08-01 00:03:42', 'released', 'completed', '2026-08-01 00:03:40', '2026-08-01 00:04:10'),
(38, 50, 2, 1, 'standard', 'six7-y9qv-t2v3', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InNpeDcteTlxdi10MnYzIiwiaWF0IjoxNzg1NTQzMDA1LCJleHAiOjE3ODU2Mjk0MDV9.6AK7rlJkAh1brM0Tw6tGMrwo52apbALg7Ht3Eks5U9U', 5.0000, 1.0000, 0.000000, 5, 300, 146, '2026-08-01 00:10:13', 'released', 'completed', '2026-08-01 00:10:07', '2026-08-01 00:12:33'),
(39, 51, 2, 1, 'standard', 'ennx-bqxl-i7am', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImVubngtYnF4bC1pN2FtIiwiaWF0IjoxNzg1NTQ1OTYzLCJleHAiOjE3ODU2MzIzNjN9.scmYxZP06EFH6K5qkF4zRHZokE5SCFzIquaRdpPW33o', 5.0000, 1.0000, 0.000000, 5, 300, 27, '2026-08-01 00:59:25', 'released', 'completed', '2026-08-01 00:59:24', '2026-08-01 00:59:51'),
(40, 52, 2, 1, 'standard', 'q4mr-3unk-kkf0', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InE0bXItM3Vuay1ra2YwIiwiaWF0IjoxNzg1NzUwNTA0LCJleHAiOjE3ODU4MzY5MDR9.Ejbg5BacU9IlDN0XPyzbyPeDS3hLkvhDhQp8LafWo6E', 30.0000, 6.0000, 0.000000, 5, 300, 108, '2026-08-03 09:48:41', 'released', 'completed', '2026-08-03 09:48:24', '2026-08-03 09:50:12'),
(41, 54, 2, 1, 'standard', 'r2k7-h62j-974n', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InIyazctaDYyai05NzRuIiwiaWF0IjoxNzg1NzYzNDYyLCJleHAiOjE3ODU4NDk4NjJ9.ji-X_kE54gAvui0ox7Yeun9f40bscZ9WC_4yKlIeua4', 30.0000, 6.0000, 0.000000, 5, 300, 49, '2026-08-03 13:24:56', 'released', 'completed', '2026-08-03 13:24:23', '2026-08-03 13:25:12'),
(42, 55, 2, 1, 'standard', 'ry62-xora-tkh4', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InJ5NjIteG9yYS10a2g0IiwiaWF0IjoxNzg1NzkyNzAwLCJleHAiOjE3ODU4NzkxMDB9.8Dr_cQDWrNts36by_goMH3Mpcdm-oZULey--hAb4iZo', 6.0000, 6.0000, 0.000000, 1, 60, 72, NULL, 'released', 'completed', '2026-08-03 21:31:42', '2026-08-03 21:32:54'),
(43, 62, 2, 1, 'standard', 'jiu3-mpa3-scas', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImppdTMtbXBhMy1zY2FzIiwiaWF0IjoxNzg2MTAxNTYxLCJleHAiOjE3ODYxODc5NjF9.fYJuOEwjSVJc4N8zOU7U5svzRNyZjqoRZUZMEUpstPQ', 30.0000, 6.0000, 0.000000, 5, 300, 150, '2026-08-07 11:19:33', 'released', 'completed', '2026-08-07 11:19:21', '2026-08-07 11:21:51'),
(44, 63, 2, 1, 'standard', 'gftz-74qv-z59h', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImdmdHotNzRxdi16NTloIiwiaWF0IjoxNzg2MTA0NjE4LCJleHAiOjE3ODYxOTEwMTh9.U1Bi4iAag2tC8pWVAS9_tAz5Yhn1AZpHACGcI1NVUU4', 30.0000, 6.0000, 0.000000, 5, 300, 82, '2026-08-07 12:10:41', 'released', 'completed', '2026-08-07 12:10:19', '2026-08-07 12:11:41'),
(45, 64, 2, 1, 'standard', 'ysbk-ezu3-j1jd', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InlzYmstZXp1My1qMWpkIiwiaWF0IjoxNzg2MTA2MzgzLCJleHAiOjE3ODYxOTI3ODN9.eFnW346r8qrVuwJaNh4eylMLl9czL56M3RXAlciTndA', 30.0000, 6.0000, 0.000000, 5, 300, 45, '2026-08-07 12:39:54', 'released', 'completed', '2026-08-07 12:39:44', '2026-08-07 12:40:29'),
(46, 65, 2, 1, 'standard', 'dx2t-721b-e9my', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImR4MnQtNzIxYi1lOW15IiwiaWF0IjoxNzg3NTc1NjE5LCJleHAiOjE3ODc2NjIwMTl9.AbiKtzjDHlDSs0CXliQV-O9dTA7Rtl_gfDbBfzrhWqE', 30.0000, 6.0000, 0.000000, 5, 300, 114, '2026-08-24 12:47:04', 'released', 'completed', '2026-08-24 12:46:59', '2026-08-24 12:48:53'),
(47, 66, 2, 1, 'payg_minute', 'n6g6-bjg3-lsfc', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Im42ZzYtYmpnMy1sc2ZjIiwiaWF0IjoxNzg3NTc2NTY5LCJleHAiOjE3ODc2NjI5Njl9.Ud5Hp2kS3E7gmnSCyf3dd2fNrsNuGWv6iHGcPACOnqY', 12.0000, 6.0000, 0.120000, 2, 120, 80, NULL, 'released', 'completed', '2026-08-24 13:02:50', '2026-08-24 13:04:10'),
(48, 67, 2, 1, 'payg_second', 'ke82-apfq-v7lo', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImtlODItYXBmcS12N2xvIiwiaWF0IjoxNzg3NjE5OTQwLCJleHAiOjE3ODc3MDYzNDB9.65MkyCzw6WFWT9MdZWpJ99dTNudsnC5Hg1KM2iOlE1c', 11.4000, 6.0000, 0.120000, 2, 93, 95, NULL, 'released', 'completed', '2026-08-25 01:05:41', '2026-08-25 01:07:16'),
(49, 68, 2, 1, 'payg_minute', 'pu3j-favc-wdrz', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6InB1M2otZmF2Yy13ZHJ6IiwiaWF0IjoxNzg3NjIwMTA4LCJleHAiOjE3ODc3MDY1MDh9.jdV7dyUIU3MquEKF6nF3Hs2LsxqMP8bgtoDS-YOO_hA', 12.0000, 6.0000, 0.120000, 2, 120, 62, NULL, 'released', 'completed', '2026-08-25 01:08:28', '2026-08-25 01:09:30'),
(50, 69, 2, 1, 'payg_second', 'np0f-57i5-kx11', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6Im5wMGYtNTdpNS1reDExIiwiaWF0IjoxNzg3NjIwNTU0LCJleHAiOjE3ODc3MDY5NTR9.lDP3OoAQ1w_aK8jXzneRmBVI3Sgi8F-q_OpHSe2jFmE', 7.3200, 6.0000, 0.120000, 2, 61, 61, NULL, 'released', 'completed', '2026-08-25 01:15:54', '2026-08-25 01:16:55'),
(51, 70, 2, 9, 'payg_second', 'ba7v-gg1t-mhpu', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIzZjNkNGY3NS03NmI3LTQzM2EtOTIyYi1kNmZjNjY0YzY2OTEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIiwiYWxsb3dfbW9kIl0sInJvb21JZCI6ImJhN3YtZ2cxdC1taHB1IiwiaWF0IjoxNzg4NTk5ODQ3LCJleHAiOjE3ODg2ODYyNDd9.eoFUifnHNR_JZsgk-2EbhGZN_zdwy1uorQXLsxjbgOM', 16.9200, 6.0000, 0.120000, 3, 140, 141, NULL, 'released', 'completed', '2026-09-05 09:17:27', '2026-09-05 09:19:48');

-- --------------------------------------------------------

--
-- Table structure for table `wallets`
--

CREATE TABLE `wallets` (
  `user_id` int NOT NULL,
  `balance` decimal(20,4) DEFAULT '0.0000',
  `total_purchased` decimal(20,4) DEFAULT '0.0000',
  `total_spent` decimal(20,4) DEFAULT '0.0000',
  `escrow_balance` decimal(20,4) DEFAULT '0.0000',
  `referral_earnings` decimal(20,4) NOT NULL DEFAULT '0.0000'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `wallets`
--

INSERT INTO `wallets` (`user_id`, `balance`, `total_purchased`, `total_spent`, `escrow_balance`, `referral_earnings`) VALUES
(1, 3324.7200, 0.0000, 0.0000, 0.0000, 0.0000),
(2, 6990.1200, 250.0000, 0.0000, 218.2400, 0.0000),
(3, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000),
(4, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000),
(8, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000),
(9, 16.9200, 0.0000, 0.0000, 0.0000, 0.0000);

-- --------------------------------------------------------

--
-- Table structure for table `wallet_transactions`
--

CREATE TABLE `wallet_transactions` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `type` enum('purchase','coin_purchase','spent','received','escrow_hold','escrow_release','withdrawal_request','withdrawal_approved','withdrawal_rejected','refund','admin_adjustment','wallet_funding','manual_adjustment') NOT NULL,
  `coins_change` decimal(20,4) DEFAULT '0.0000',
  `amount_change` decimal(20,4) DEFAULT '0.0000',
  `balance_before` decimal(20,4) DEFAULT NULL,
  `balance_after` decimal(20,4) DEFAULT NULL,
  `reference` varchar(255) DEFAULT NULL,
  `description` text,
  `status` enum('pending','completed','failed') DEFAULT 'completed',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `wallet_transactions`
--

INSERT INTO `wallet_transactions` (`id`, `user_id`, `type`, `coins_change`, `amount_change`, `balance_before`, `balance_after`, `reference`, `description`, `status`, `created_at`) VALUES
(1, 2, 'escrow_hold', -100.0000, -100.0000, 500.0000, 400.0000, 'Call escrow hold — request #6', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 07:46:41'),
(2, 2, 'escrow_hold', -100.0000, -100.0000, 400.0000, 300.0000, 'Call escrow hold — request #8', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 09:03:46'),
(3, 2, 'escrow_hold', -100.0000, -100.0000, 300.0000, 200.0000, 'Call escrow hold — request #9', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 09:16:35'),
(4, 2, 'escrow_hold', -100.0000, -100.0000, 200.0000, 100.0000, 'Call escrow hold — request #11', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 09:30:25'),
(31, 2, 'escrow_hold', -100.0000, -100.0000, 100.0000, 0.0000, 'Call escrow hold — request #17', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 10:17:59'),
(32, 2, 'escrow_hold', -100.0000, -100.0000, 10000.0000, 9900.0000, 'Call escrow hold — request #18', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 10:22:43'),
(33, 2, 'escrow_hold', -100.0000, -100.0000, 9900.0000, 9800.0000, 'Call escrow hold — request #19', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 10:35:20'),
(34, 2, 'escrow_hold', -100.0000, -100.0000, 9800.0000, 9700.0000, 'Call escrow hold — request #20', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 12:07:28'),
(35, 2, 'escrow_hold', -100.0000, -100.0000, 9700.0000, 9600.0000, 'Call escrow hold — request #21', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 12:10:13'),
(36, 2, 'escrow_hold', -100.0000, -100.0000, 9600.0000, 9500.0000, 'Call escrow hold — request #22', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 12:12:09'),
(37, 2, 'escrow_release', 0.0000, -100.0000, 1000.0000, 900.0000, 'Escrow released — call #10', 'Escrow of 100.00 released to influencer for call #10.', 'completed', '2026-07-24 12:14:33'),
(38, 1, 'escrow_release', 0.0000, 100.0000, 0.0000, 100.0000, 'Escrow received — call #10', 'Call earnings of 100.00 credited from escrow for call #10.', 'completed', '2026-07-24 12:14:33'),
(39, 2, 'escrow_hold', -100.0000, -100.0000, 9500.0000, 9400.0000, 'Call escrow hold — request #23', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 12:25:07'),
(40, 2, 'escrow_hold', -100.0000, -100.0000, 9400.0000, 9300.0000, 'Call escrow hold — request #24', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 12:28:04'),
(41, 2, 'escrow_hold', -100.0000, -100.0000, 9300.0000, 9200.0000, 'Call escrow hold — request #25', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 13:00:56'),
(42, 2, 'escrow_hold', -100.0000, -100.0000, 9200.0000, 9100.0000, 'Call escrow hold — request #26', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 13:02:33'),
(43, 2, 'escrow_hold', -100.0000, -100.0000, 9100.0000, 9000.0000, 'Call escrow hold — request #27', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 13:04:02'),
(44, 2, 'escrow_hold', -100.0000, -100.0000, 9000.0000, 8900.0000, 'Call escrow hold — request #28', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 13:06:28'),
(45, 2, 'escrow_hold', -100.0000, -100.0000, 8900.0000, 8800.0000, 'Call escrow hold — request #29', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-24 13:20:52'),
(46, 2, 'escrow_hold', -1500.0000, -1500.0000, 8800.0000, 7300.0000, 'Call extension — call #17', 'Escrow hold of 1,500.00 coins for 15 additional minute(s).', 'completed', '2026-07-24 13:21:16'),
(47, 2, 'escrow_hold', -100.0000, -100.0000, 7300.0000, 7200.0000, 'Call escrow hold — request #30', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-27 08:47:28'),
(48, 2, 'escrow_hold', -100.0000, -100.0000, 7200.0000, 7100.0000, 'Call escrow hold — request #31', 'Escrow hold of 100.00 coins for call with influencer #1.', 'completed', '2026-07-27 08:52:01'),
(49, 2, 'escrow_hold', -1.0000, -1.0000, 7100.0000, 7099.0000, 'Call escrow hold — request #32', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-27 09:37:46'),
(50, 2, 'escrow_hold', -5.0000, -5.0000, 7099.0000, 7094.0000, 'Call extension — call #20', 'Escrow hold of 5.00 coins for 5 additional minute(s).', 'completed', '2026-07-27 09:38:45'),
(51, 2, 'escrow_hold', -1.0000, -1.0000, 7094.0000, 7093.0000, 'Call escrow hold — request #33', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-27 09:52:33'),
(52, 2, 'escrow_hold', -4.0000, -4.0000, 7093.0000, 7089.0000, 'Call extension — call #21', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-27 09:52:38'),
(53, 2, 'escrow_hold', -5.0000, -5.0000, 7089.0000, 7084.0000, 'Call extension — call #21', 'Escrow hold of 5.00 coins for 5 additional minute(s).', 'completed', '2026-07-27 09:56:53'),
(54, 2, 'escrow_hold', -5.0000, -5.0000, 7084.0000, 7079.0000, 'Call extension — call #21', 'Escrow hold of 5.00 coins for 5 additional minute(s).', 'completed', '2026-07-27 10:01:46'),
(55, 2, 'escrow_hold', -1.0000, -1.0000, 7079.0000, 7078.0000, 'Call escrow hold — request #34', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-27 11:14:18'),
(56, 2, 'escrow_hold', -4.0000, -4.0000, 7078.0000, 7074.0000, 'Call extension — call #22', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-27 11:14:27'),
(57, 2, 'escrow_release', 0.0000, -5.0000, 3326.0000, 3321.0000, 'Escrow released — call #22', 'Escrow of 5.00 released to influencer for call #22.', 'completed', '2026-07-27 11:17:19'),
(58, 1, 'escrow_release', 0.0000, 5.0000, 100.0000, 105.0000, 'Escrow received — call #22', 'Call earnings of 5.00 credited from escrow for call #22.', 'completed', '2026-07-27 11:17:19'),
(59, 2, 'escrow_hold', -1.0000, -1.0000, 7074.0000, 7073.0000, 'Call escrow hold — request #35', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-27 11:25:22'),
(60, 2, 'escrow_hold', -4.0000, -4.0000, 7073.0000, 7069.0000, 'Call extension — call #23', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-27 11:25:26'),
(61, 2, 'escrow_release', 0.0000, -5.0000, 3326.0000, 3321.0000, 'Escrow released — call #23', 'Escrow of 5.00 released to influencer for call #23.', 'completed', '2026-07-27 11:26:46'),
(62, 1, 'escrow_release', 0.0000, 5.0000, 105.0000, 110.0000, 'Escrow received — call #23', 'Call earnings of 5.00 credited from escrow for call #23.', 'completed', '2026-07-27 11:26:46'),
(63, 2, 'escrow_hold', -1.0000, -1.0000, 7069.0000, 7068.0000, 'Call escrow hold — request #36', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-27 11:38:43'),
(64, 2, 'escrow_hold', -4.0000, -4.0000, 7068.0000, 7064.0000, 'Call extension — call #24', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-27 11:38:46'),
(65, 2, 'escrow_hold', -1.0000, -1.0000, 7064.0000, 7063.0000, 'Call escrow hold — request #37', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-27 11:43:09'),
(66, 2, 'escrow_hold', -4.0000, -4.0000, 7063.0000, 7059.0000, 'Call extension — call #25', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-27 11:43:12'),
(67, 2, 'coin_purchase', 5.0000, 10.0000, 7059.0000, 7064.0000, 'Stripe Payment Intent: pi_3TyDxEEluYzEaEbb0yekyUWd', 'Coin purchase: 5 coins for 10.00.', 'completed', '2026-07-28 16:40:23'),
(68, 2, 'coin_purchase', 200.0000, 200.0000, 7064.0000, 7264.0000, 'Stripe Payment Intent: pi_3TyE4AEluYzEaEbb1q2tkz8T', 'Coin purchase: 200 coins for 200.00.', 'completed', '2026-07-28 16:42:14'),
(69, 2, 'escrow_release', 0.0000, -100.0000, 3331.0000, 3231.0000, 'Escrow released — call #3', 'Escrow of 100.00 released to influencer for call #3.', 'completed', '2026-07-28 17:15:13'),
(70, 1, 'escrow_release', 0.0000, 100.0000, 110.0000, 210.0000, 'Escrow received — call #3', 'Call earnings of 100.00 credited from escrow for call #3.', 'completed', '2026-07-28 17:15:13'),
(71, 2, 'escrow_release', 0.0000, -100.0000, 3231.0000, 3131.0000, 'Escrow released — call #4', 'Escrow of 100.00 released to influencer for call #4.', 'completed', '2026-07-28 17:15:14'),
(72, 1, 'escrow_release', 0.0000, 100.0000, 210.0000, 310.0000, 'Escrow received — call #4', 'Call earnings of 100.00 credited from escrow for call #4.', 'completed', '2026-07-28 17:15:14'),
(73, 2, 'escrow_release', 0.0000, -100.0000, 3131.0000, 3031.0000, 'Escrow released — call #5', 'Escrow of 100.00 released to influencer for call #5.', 'completed', '2026-07-28 17:15:14'),
(74, 1, 'escrow_release', 0.0000, 100.0000, 310.0000, 410.0000, 'Escrow received — call #5', 'Call earnings of 100.00 credited from escrow for call #5.', 'completed', '2026-07-28 17:15:14'),
(75, 2, 'escrow_release', 0.0000, -100.0000, 3031.0000, 2931.0000, 'Escrow released — call #6', 'Escrow of 100.00 released to influencer for call #6.', 'completed', '2026-07-28 17:15:14'),
(76, 1, 'escrow_release', 0.0000, 100.0000, 410.0000, 510.0000, 'Escrow received — call #6', 'Call earnings of 100.00 credited from escrow for call #6.', 'completed', '2026-07-28 17:15:14'),
(77, 2, 'escrow_release', 0.0000, -100.0000, 2931.0000, 2831.0000, 'Escrow released — call #7', 'Escrow of 100.00 released to influencer for call #7.', 'completed', '2026-07-28 17:15:15'),
(78, 1, 'escrow_release', 0.0000, 100.0000, 510.0000, 610.0000, 'Escrow received — call #7', 'Call earnings of 100.00 credited from escrow for call #7.', 'completed', '2026-07-28 17:15:15'),
(79, 2, 'escrow_release', 0.0000, -100.0000, 2831.0000, 2731.0000, 'Escrow released — call #8', 'Escrow of 100.00 released to influencer for call #8.', 'completed', '2026-07-28 17:15:15'),
(80, 1, 'escrow_release', 0.0000, 100.0000, 610.0000, 710.0000, 'Escrow received — call #8', 'Call earnings of 100.00 credited from escrow for call #8.', 'completed', '2026-07-28 17:15:15'),
(81, 2, 'escrow_release', 0.0000, -100.0000, 2731.0000, 2631.0000, 'Escrow released — call #9', 'Escrow of 100.00 released to influencer for call #9.', 'completed', '2026-07-28 17:15:15'),
(82, 1, 'escrow_release', 0.0000, 100.0000, 710.0000, 810.0000, 'Escrow received — call #9', 'Call earnings of 100.00 credited from escrow for call #9.', 'completed', '2026-07-28 17:15:15'),
(83, 2, 'escrow_release', 0.0000, -100.0000, 2631.0000, 2531.0000, 'Escrow released — call #11', 'Escrow of 100.00 released to influencer for call #11.', 'completed', '2026-07-28 17:15:16'),
(84, 1, 'escrow_release', 0.0000, 100.0000, 810.0000, 910.0000, 'Escrow received — call #11', 'Call earnings of 100.00 credited from escrow for call #11.', 'completed', '2026-07-28 17:15:16'),
(85, 2, 'escrow_release', 0.0000, -100.0000, 2531.0000, 2431.0000, 'Escrow released — call #12', 'Escrow of 100.00 released to influencer for call #12.', 'completed', '2026-07-28 17:15:16'),
(86, 1, 'escrow_release', 0.0000, 100.0000, 910.0000, 1010.0000, 'Escrow received — call #12', 'Call earnings of 100.00 credited from escrow for call #12.', 'completed', '2026-07-28 17:15:16'),
(87, 2, 'escrow_release', 0.0000, -100.0000, 2431.0000, 2331.0000, 'Escrow released — call #13', 'Escrow of 100.00 released to influencer for call #13.', 'completed', '2026-07-28 17:15:16'),
(88, 1, 'escrow_release', 0.0000, 100.0000, 1010.0000, 1110.0000, 'Escrow received — call #13', 'Call earnings of 100.00 credited from escrow for call #13.', 'completed', '2026-07-28 17:15:16'),
(89, 2, 'escrow_release', 0.0000, -100.0000, 2331.0000, 2231.0000, 'Escrow released — call #14', 'Escrow of 100.00 released to influencer for call #14.', 'completed', '2026-07-28 17:15:16'),
(90, 1, 'escrow_release', 0.0000, 100.0000, 1110.0000, 1210.0000, 'Escrow received — call #14', 'Call earnings of 100.00 credited from escrow for call #14.', 'completed', '2026-07-28 17:15:16'),
(91, 2, 'escrow_release', 0.0000, -100.0000, 2231.0000, 2131.0000, 'Escrow released — call #15', 'Escrow of 100.00 released to influencer for call #15.', 'completed', '2026-07-28 17:15:17'),
(92, 1, 'escrow_release', 0.0000, 100.0000, 1210.0000, 1310.0000, 'Escrow received — call #15', 'Call earnings of 100.00 credited from escrow for call #15.', 'completed', '2026-07-28 17:15:17'),
(93, 2, 'escrow_release', 0.0000, -100.0000, 2131.0000, 2031.0000, 'Escrow released — call #16', 'Escrow of 100.00 released to influencer for call #16.', 'completed', '2026-07-28 17:15:17'),
(94, 1, 'escrow_release', 0.0000, 100.0000, 1310.0000, 1410.0000, 'Escrow received — call #16', 'Call earnings of 100.00 credited from escrow for call #16.', 'completed', '2026-07-28 17:15:17'),
(95, 2, 'escrow_release', 0.0000, -1600.0000, 2031.0000, 431.0000, 'Escrow released — call #17', 'Escrow of 1,600.00 released to influencer for call #17.', 'completed', '2026-07-28 17:15:17'),
(96, 1, 'escrow_release', 0.0000, 1600.0000, 1410.0000, 3010.0000, 'Escrow received — call #17', 'Call earnings of 1,600.00 credited from escrow for call #17.', 'completed', '2026-07-28 17:15:17'),
(97, 2, 'escrow_release', 0.0000, -100.0000, 431.0000, 331.0000, 'Escrow released — call #18', 'Escrow of 100.00 released to influencer for call #18.', 'completed', '2026-07-28 17:15:17'),
(98, 1, 'escrow_release', 0.0000, 100.0000, 3010.0000, 3110.0000, 'Escrow received — call #18', 'Call earnings of 100.00 credited from escrow for call #18.', 'completed', '2026-07-28 17:15:17'),
(99, 2, 'escrow_release', 0.0000, -100.0000, 331.0000, 231.0000, 'Escrow released — call #19', 'Escrow of 100.00 released to influencer for call #19.', 'completed', '2026-07-28 17:15:17'),
(100, 1, 'escrow_release', 0.0000, 100.0000, 3110.0000, 3210.0000, 'Escrow received — call #19', 'Call earnings of 100.00 credited from escrow for call #19.', 'completed', '2026-07-28 17:15:17'),
(101, 2, 'escrow_release', 0.0000, -6.0000, 231.0000, 225.0000, 'Escrow released — call #20', 'Escrow of 6.00 released to influencer for call #20.', 'completed', '2026-07-28 17:15:17'),
(102, 1, 'escrow_release', 0.0000, 6.0000, 3210.0000, 3216.0000, 'Escrow received — call #20', 'Call earnings of 6.00 credited from escrow for call #20.', 'completed', '2026-07-28 17:15:17'),
(103, 2, 'escrow_release', 0.0000, -5.0000, 225.0000, 220.0000, 'Escrow released — call #24', 'Escrow of 5.00 released to influencer for call #24.', 'completed', '2026-07-28 17:15:17'),
(104, 1, 'escrow_release', 0.0000, 5.0000, 3216.0000, 3221.0000, 'Escrow received — call #24', 'Call earnings of 5.00 credited from escrow for call #24.', 'completed', '2026-07-28 17:15:17'),
(105, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #25', 'Escrow of 5.00 released to influencer for call #25.', 'completed', '2026-07-28 17:15:17'),
(106, 1, 'escrow_release', 0.0000, 5.0000, 3221.0000, 3226.0000, 'Escrow received — call #25', 'Call earnings of 5.00 credited from escrow for call #25.', 'completed', '2026-07-28 17:15:17'),
(107, 2, 'escrow_hold', -1.0000, -1.0000, 7264.0000, 7263.0000, 'Call escrow hold — request #38', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-31 20:43:49'),
(108, 2, 'escrow_hold', -4.0000, -4.0000, 7263.0000, 7259.0000, 'Call extension — call #26', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-31 20:43:53'),
(109, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #26', 'Escrow of 5.00 released to influencer for call #26.', 'completed', '2026-07-31 20:57:41'),
(110, 1, 'escrow_release', 0.0000, 5.0000, 3226.0000, 3231.0000, 'Escrow received — call #26', 'Call earnings of 5.00 credited from escrow for call #26.', 'completed', '2026-07-31 20:57:41'),
(111, 2, 'escrow_hold', -1.0000, -1.0000, 7259.0000, 7258.0000, 'Call escrow hold — request #39', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-31 21:14:16'),
(112, 2, 'escrow_hold', -4.0000, -4.0000, 7258.0000, 7254.0000, 'Call extension — call #27', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-31 21:14:26'),
(113, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #27', 'Escrow of 5.00 released to influencer for call #27.', 'completed', '2026-07-31 21:17:03'),
(114, 1, 'escrow_release', 0.0000, 5.0000, 3231.0000, 3236.0000, 'Escrow received — call #27', 'Call earnings of 5.00 credited from escrow for call #27.', 'completed', '2026-07-31 21:17:03'),
(115, 2, 'escrow_hold', -1.0000, -1.0000, 7254.0000, 7253.0000, 'Call escrow hold — request #40', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-31 21:37:24'),
(116, 2, 'escrow_hold', -4.0000, -4.0000, 7253.0000, 7249.0000, 'Call extension — call #28', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-31 21:37:27'),
(117, 2, 'escrow_hold', -1.0000, -1.0000, 7249.0000, 7248.0000, 'Call escrow hold — request #41', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-31 22:04:15'),
(118, 2, 'escrow_hold', -4.0000, -4.0000, 7248.0000, 7244.0000, 'Call extension — call #29', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-31 22:04:19'),
(119, 2, 'escrow_release', 0.0000, -5.0000, 225.0000, 220.0000, 'Escrow released — call #29', 'Escrow of 5.00 released to influencer for call #29.', 'completed', '2026-07-31 22:05:22'),
(120, 1, 'escrow_release', 0.0000, 5.0000, 3236.0000, 3241.0000, 'Escrow received — call #29', 'Call earnings of 5.00 credited from escrow for call #29.', 'completed', '2026-07-31 22:05:22'),
(121, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #28', 'Escrow of 5.00 released to influencer for call #28.', 'completed', '2026-07-31 22:10:09'),
(122, 1, 'escrow_release', 0.0000, 5.0000, 3241.0000, 3246.0000, 'Escrow received — call #28', 'Call earnings of 5.00 credited from escrow for call #28.', 'completed', '2026-07-31 22:10:09'),
(123, 2, 'escrow_hold', -1.0000, -1.0000, 7244.0000, 7243.0000, 'Call escrow hold — request #42', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-31 22:50:50'),
(124, 2, 'escrow_hold', -4.0000, -4.0000, 7243.0000, 7239.0000, 'Call extension — call #30', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-31 22:50:55'),
(125, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #30', 'Escrow of 5.00 released to influencer for call #30.', 'completed', '2026-07-31 22:52:56'),
(126, 1, 'escrow_release', 0.0000, 5.0000, 3246.0000, 3251.0000, 'Escrow received — call #30', 'Call earnings of 5.00 credited from escrow for call #30.', 'completed', '2026-07-31 22:52:56'),
(127, 2, 'escrow_hold', -1.0000, -1.0000, 7239.0000, 7238.0000, 'Call escrow hold — request #43', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-31 23:10:21'),
(128, 2, 'escrow_hold', -4.0000, -4.0000, 7238.0000, 7234.0000, 'Call extension — call #31', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-31 23:10:25'),
(129, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #31', 'Escrow of 5.00 released to influencer for call #31.', 'completed', '2026-07-31 23:11:17'),
(130, 1, 'escrow_release', 0.0000, 5.0000, 3251.0000, 3256.0000, 'Escrow received — call #31', 'Call earnings of 5.00 credited from escrow for call #31.', 'completed', '2026-07-31 23:11:17'),
(131, 2, 'escrow_hold', -1.0000, -1.0000, 7234.0000, 7233.0000, 'Call escrow hold — request #44', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-31 23:15:53'),
(132, 2, 'escrow_hold', -4.0000, -4.0000, 7233.0000, 7229.0000, 'Call extension — call #32', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-31 23:15:55'),
(133, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #32', 'Escrow of 5.00 released to influencer for call #32.', 'completed', '2026-07-31 23:17:52'),
(134, 1, 'escrow_release', 0.0000, 5.0000, 3256.0000, 3261.0000, 'Escrow received — call #32', 'Call earnings of 5.00 credited from escrow for call #32.', 'completed', '2026-07-31 23:17:52'),
(135, 2, 'escrow_hold', -1.0000, -1.0000, 7229.0000, 7228.0000, 'Call escrow hold — request #45', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-31 23:27:24'),
(136, 2, 'escrow_hold', -4.0000, -4.0000, 7228.0000, 7224.0000, 'Call extension — call #33', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-31 23:27:26'),
(137, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #33', 'Escrow of 5.00 released to influencer for call #33.', 'completed', '2026-07-31 23:28:52'),
(138, 1, 'escrow_release', 0.0000, 5.0000, 3261.0000, 3266.0000, 'Escrow received — call #33', 'Call earnings of 5.00 credited from escrow for call #33.', 'completed', '2026-07-31 23:28:52'),
(139, 2, 'escrow_hold', -1.0000, -1.0000, 7224.0000, 7223.0000, 'Call escrow hold — request #46', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-31 23:31:34'),
(140, 2, 'escrow_hold', -4.0000, -4.0000, 7223.0000, 7219.0000, 'Call extension — call #34', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-31 23:31:37'),
(141, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #34', 'Escrow of 5.00 released to influencer for call #34.', 'completed', '2026-07-31 23:32:28'),
(142, 1, 'escrow_release', 0.0000, 5.0000, 3266.0000, 3271.0000, 'Escrow received — call #34', 'Call earnings of 5.00 credited from escrow for call #34.', 'completed', '2026-07-31 23:32:28'),
(143, 2, 'escrow_hold', -1.0000, -1.0000, 7219.0000, 7218.0000, 'Call escrow hold — request #47', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-31 23:48:37'),
(144, 2, 'escrow_hold', -4.0000, -4.0000, 7218.0000, 7214.0000, 'Call extension — call #35', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-31 23:48:42'),
(145, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #35', 'Escrow of 5.00 released to influencer for call #35.', 'completed', '2026-07-31 23:49:54'),
(146, 1, 'escrow_release', 0.0000, 5.0000, 3271.0000, 3276.0000, 'Escrow received — call #35', 'Call earnings of 5.00 credited from escrow for call #35.', 'completed', '2026-07-31 23:49:54'),
(147, 2, 'escrow_hold', -1.0000, -1.0000, 7214.0000, 7213.0000, 'Call escrow hold — request #48', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-07-31 23:53:56'),
(148, 2, 'escrow_hold', -4.0000, -4.0000, 7213.0000, 7209.0000, 'Call extension — call #36', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-07-31 23:53:58'),
(149, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #36', 'Escrow of 5.00 released to influencer for call #36.', 'completed', '2026-07-31 23:55:07'),
(150, 1, 'escrow_release', 0.0000, 5.0000, 3276.0000, 3281.0000, 'Escrow received — call #36', 'Call earnings of 5.00 credited from escrow for call #36.', 'completed', '2026-07-31 23:55:07'),
(151, 2, 'escrow_hold', -1.0000, -1.0000, 7209.0000, 7208.0000, 'Call escrow hold — request #49', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-08-01 00:03:40'),
(152, 2, 'escrow_hold', -4.0000, -4.0000, 7208.0000, 7204.0000, 'Call extension — call #37', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-08-01 00:03:42'),
(153, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #37', 'Escrow of 5.00 released to influencer for call #37.', 'completed', '2026-08-01 00:04:40'),
(154, 1, 'escrow_release', 0.0000, 5.0000, 3281.0000, 3286.0000, 'Escrow received — call #37', 'Call earnings of 5.00 credited from escrow for call #37.', 'completed', '2026-08-01 00:04:40'),
(155, 2, 'escrow_hold', -1.0000, -1.0000, 7204.0000, 7203.0000, 'Call escrow hold — request #50', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-08-01 00:10:07'),
(156, 2, 'escrow_hold', -4.0000, -4.0000, 7203.0000, 7199.0000, 'Call extension — call #38', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-08-01 00:10:13'),
(157, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Escrow released — call #38', 'Escrow of 5.00 released to influencer for call #38.', 'completed', '2026-08-01 00:13:26'),
(158, 1, 'escrow_release', 0.0000, 5.0000, 3286.0000, 3291.0000, 'Escrow received — call #38', 'Call earnings of 5.00 credited from escrow for call #38.', 'completed', '2026-08-01 00:13:26'),
(159, 1, 'withdrawal_request', 0.0000, -50.0000, 3291.0000, 3241.0000, 'Withdrawal Request #1', 'Withdrawal request submitted for 50.00. Awaiting admin approval.', 'pending', '2026-08-01 00:25:54'),
(160, 1, 'withdrawal_approved', 0.0000, -50.0000, 3241.0000, 3191.0000, 'Withdrawal Approved #1', 'Withdrawal of 50.00 approved by admin.', 'completed', '2026-08-01 00:28:09'),
(161, 1, 'withdrawal_request', 0.0000, -50.0000, 3191.0000, 3141.0000, 'Withdrawal Request #2', 'Withdrawal request submitted for 50.00. Awaiting admin approval.', 'pending', '2026-08-01 00:36:07'),
(162, 2, 'escrow_hold', -1.0000, -1.0000, 7199.0000, 7198.0000, 'Call escrow hold — request #51', 'Escrow hold of 1.00 coins for call with influencer #1.', 'completed', '2026-08-01 00:59:24'),
(163, 2, 'escrow_hold', -4.0000, -4.0000, 7198.0000, 7194.0000, 'Call extension — call #39', 'Escrow hold of 4.00 coins for 4 additional minute(s).', 'completed', '2026-08-01 00:59:25'),
(164, 2, 'escrow_release', 0.0000, -5.0000, 220.0000, 215.0000, 'Payment to mozel — Call #39', 'Payment of 5.00 released to mozel for call #39.', 'completed', '2026-08-01 01:00:15'),
(165, 1, 'escrow_release', 0.0000, 5.0000, 3141.0000, 3146.0000, 'Payment from James — Call #39', 'Call earnings of 5.00 received from James for call #39.', 'completed', '2026-08-01 01:00:15'),
(166, 2, 'coin_purchase', 5.0000, 10.0000, 7194.0000, 7199.0000, 'Paystack Reference: 7pv7sk40yu', 'Coin purchase: 5 coins for 10.00.', 'completed', '2026-08-01 14:17:08'),
(167, 2, 'coin_purchase', 10.0000, 20.0000, 7199.0000, 7209.0000, 'Paystack Reference: 6oabf1m7zl', 'Coin purchase: 10 coins for 20.00.', 'completed', '2026-08-01 14:19:47'),
(168, 2, 'coin_purchase', 5.0000, 10.0000, 7209.0000, 7214.0000, 'Paystack Reference: 4lefeef1jd', 'Coin purchase: 5 coins for 10.00.', 'completed', '2026-08-01 14:27:18'),
(169, 2, 'coin_purchase', 5.0000, 10.0000, 7214.0000, 7219.0000, 'Paystack Reference: k78cc7mj1j', 'Coin purchase: 5 coins for 10.00.', 'completed', '2026-08-01 14:29:54'),
(170, 2, 'coin_purchase', 5.0000, 10.0000, 7219.0000, 7224.0000, 'Paystack Reference: tgxaiphw5r', 'Coin purchase: 5 coins for 10.00.', 'completed', '2026-08-01 14:57:20'),
(171, 2, 'coin_purchase', 5.0000, 10.0000, 7224.0000, 7229.0000, 'Paystack Reference: tzed2787jz', 'Coin purchase: 5 coins for 10.00.', 'completed', '2026-08-01 15:07:41'),
(172, 2, 'coin_purchase', 5.0000, 10.0000, 7229.0000, 7234.0000, 'Paystack Reference: dlsnj0gthq', 'Coin purchase: 5 coins for 10.00.', 'completed', '2026-08-01 19:52:45'),
(173, 2, 'escrow_hold', -6.0000, -6.0000, 7234.0000, 7228.0000, 'Call escrow hold — request #52', 'Escrow hold of 6.00 coins for call with influencer #1.', 'completed', '2026-08-03 09:48:24'),
(174, 2, 'escrow_hold', -24.0000, -24.0000, 7228.0000, 7204.0000, 'Call extension — call #40', 'Escrow hold of 24.00 coins for 4 additional minute(s).', 'completed', '2026-08-03 09:48:41'),
(175, 2, 'escrow_release', 0.0000, -30.0000, 245.0000, 215.0000, 'Payment to mozel — Call #40', 'Payment of 30.00 released to mozel for call #40.', 'completed', '2026-08-03 09:50:30'),
(176, 1, 'escrow_release', 0.0000, 30.0000, 3146.0000, 3176.0000, 'Payment from James — Call #40', 'Call earnings of 30.00 received from James for call #40.', 'completed', '2026-08-03 09:50:30'),
(177, 2, 'escrow_hold', -6.0000, -6.0000, 7204.0000, 7198.0000, 'Call escrow hold — request #54', 'Escrow hold of 6.00 coins for call with influencer #1.', 'completed', '2026-08-03 13:24:23'),
(178, 2, 'escrow_hold', -24.0000, -24.0000, 7198.0000, 7174.0000, 'Call extension — call #41', 'Escrow hold of 24.00 coins for 4 additional minute(s).', 'completed', '2026-08-03 13:24:56'),
(179, 2, 'escrow_release', 0.0000, -30.0000, 245.0000, 215.0000, 'Payment to mozel — Call #41', 'Payment of 30.00 released to mozel for call #41.', 'completed', '2026-08-03 13:25:24'),
(180, 1, 'escrow_release', 0.0000, 30.0000, 3176.0000, 3206.0000, 'Payment from James — Call #41', 'Call earnings of 30.00 received from James for call #41.', 'completed', '2026-08-03 13:25:24'),
(181, 2, 'escrow_hold', -6.0000, -6.0000, 7174.0000, 7168.0000, 'Call escrow hold — request #55', 'Escrow hold of 6.00 coins for call with influencer #1.', 'completed', '2026-08-03 21:31:42'),
(182, 2, 'escrow_release', 0.0000, -6.0000, 221.0000, 215.0000, 'Payment to mozel — Call #42', 'Payment of 6.00 released to mozel for call #42.', 'completed', '2026-08-03 22:05:12'),
(183, 1, 'escrow_release', 0.0000, 6.0000, 3206.0000, 3212.0000, 'Payment from James — Call #42', 'Call earnings of 6.00 received from James for call #42.', 'completed', '2026-08-03 22:05:12'),
(184, 2, 'escrow_hold', -6.0000, -6.0000, 7168.0000, 7162.0000, 'Call escrow hold — request #62', 'Escrow hold of 6.00 coins for call with influencer #1.', 'completed', '2026-08-07 11:19:21'),
(185, 2, 'escrow_hold', -24.0000, -24.0000, 7162.0000, 7138.0000, 'Call extension — call #43', 'Escrow hold of 24.00 coins for 4 additional minute(s).', 'completed', '2026-08-07 11:19:33'),
(186, 2, 'escrow_release', 0.0000, -30.0000, 245.0000, 215.0000, 'Payment to mozel — Call #43', 'Payment of 30.00 released to mozel for call #43.', 'completed', '2026-08-07 11:21:59'),
(187, 1, 'escrow_release', 0.0000, 30.0000, 3212.0000, 3242.0000, 'Payment from James — Call #43', 'Call earnings of 30.00 received from James for call #43.', 'completed', '2026-08-07 11:21:59'),
(188, 2, 'escrow_hold', -6.0000, -6.0000, 7138.0000, 7132.0000, 'Call escrow hold — request #63', 'Escrow hold of 6.00 coins for call with influencer #1.', 'completed', '2026-08-07 12:10:18'),
(189, 2, 'escrow_hold', -24.0000, -24.0000, 7132.0000, 7108.0000, 'Call extension — call #44', 'Escrow hold of 24.00 coins for 4 additional minute(s).', 'completed', '2026-08-07 12:10:41'),
(190, 2, 'escrow_release', 0.0000, -30.0000, 245.0000, 215.0000, 'Payment to mozel — Call #44', 'Payment of 30.00 released to mozel for call #44.', 'completed', '2026-08-07 12:11:50'),
(191, 1, 'escrow_release', 0.0000, 30.0000, 3242.0000, 3272.0000, 'Payment from James — Call #44', 'Call earnings of 30.00 received from James for call #44.', 'completed', '2026-08-07 12:11:50'),
(192, 2, 'escrow_hold', -6.0000, -6.0000, 7108.0000, 7102.0000, 'Call escrow hold — request #64', 'Escrow hold of 6.00 coins for call with influencer #1.', 'completed', '2026-08-07 12:39:44'),
(193, 2, 'escrow_hold', -24.0000, -24.0000, 7102.0000, 7078.0000, 'Call extension — call #45', 'Escrow hold of 24.00 coins for 4 additional minute(s).', 'completed', '2026-08-07 12:39:54'),
(194, 2, 'escrow_release', 0.0000, -30.0000, 245.0000, 215.0000, 'Payment to mozel — Call #45', 'Payment of 30.00 released to mozel for call #45.', 'completed', '2026-08-07 12:40:46'),
(195, 1, 'escrow_release', 0.0000, 30.0000, 3272.0000, 3302.0000, 'Payment from James — Call #45', 'Call earnings of 30.00 received from James for call #45.', 'completed', '2026-08-07 12:40:46'),
(196, 1, 'withdrawal_approved', 0.0000, -50.0000, 3302.0000, 3252.0000, 'Withdrawal Approved #2', 'Withdrawal of 50.00 approved by admin.', 'completed', '2026-08-07 13:00:14'),
(197, 2, 'coin_purchase', 5.0000, 10.0000, 7078.0000, 7083.0000, 'Flutterwave Reference: mp_24_2eface904975ec01', 'Coin purchase: 5 coins for 10.00.', 'completed', '2026-08-20 11:52:17'),
(198, 2, 'escrow_hold', -6.0000, -6.0000, 7083.0000, 7077.0000, 'Call escrow hold — request #65', 'Escrow hold of 6.0000 coins for call with influencer #1.', 'completed', '2026-08-24 12:46:59'),
(199, 2, 'escrow_hold', -24.0000, -24.0000, 7077.0000, 7053.0000, 'Call extension — call #46', 'Escrow hold of 24.00 coins for 4 additional minute(s).', 'completed', '2026-08-24 12:47:04'),
(200, 2, 'escrow_release', 0.0000, -30.0000, 245.0000, 215.0000, 'Payment to mozel — Call #46', 'Payment of 30.00 released to mozel for call #46.', 'completed', '2026-08-24 12:49:10'),
(201, 1, 'escrow_release', 0.0000, 30.0000, 3252.0000, 3282.0000, 'Payment from James — Call #46', 'Call earnings of 30.00 received from James for call #46.', 'completed', '2026-08-24 12:49:10'),
(202, 2, 'escrow_hold', -6.0000, -6.0000, 7053.0000, 7047.0000, 'Call escrow hold — request #66', 'Escrow hold of 6.0000 coins for call with influencer #1.', 'completed', '2026-08-24 13:02:50'),
(203, 2, 'escrow_hold', -6.0000, -6.0000, 7047.0000, 7041.0000, 'Pay As You Go escrow — call #47', 'Pay As You Go escrow top-up of 6.0000 coins.', 'completed', '2026-08-24 13:03:53'),
(204, 2, 'escrow_release', 0.0000, -12.0000, 227.0000, 215.0000, 'Payment to mozel — Call #47', 'Payment of 12.00 released to mozel for call #47.', 'completed', '2026-08-24 13:04:21'),
(205, 1, 'escrow_release', 0.0000, 12.0000, 3282.0000, 3294.0000, 'Payment from James — Call #47', 'Call earnings of 12.00 received from James for call #47.', 'completed', '2026-08-24 13:04:21'),
(206, 2, 'escrow_hold', -0.1200, -0.1200, 7041.0000, 7040.8800, 'Call escrow hold — request #67', 'Escrow hold of 0.1200 coins for call with influencer #1.', 'completed', '2026-08-25 01:05:41'),
(207, 2, 'escrow_hold', -0.2400, -0.2400, 7040.8800, 7040.6400, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-08-25 01:05:43'),
(208, 2, 'escrow_hold', -1.2000, -1.2000, 7040.6400, 7039.4400, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 1.2000 coins.', 'completed', '2026-08-25 01:05:53'),
(209, 2, 'escrow_hold', -1.2000, -1.2000, 7039.4400, 7038.2400, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 1.2000 coins.', 'completed', '2026-08-25 01:06:03'),
(210, 2, 'escrow_hold', -0.2400, -0.2400, 7038.2400, 7038.0000, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-08-25 01:06:05'),
(211, 2, 'escrow_hold', -0.2400, -0.2400, 7038.0000, 7037.7600, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-08-25 01:06:07'),
(212, 2, 'escrow_hold', -0.3600, -0.3600, 7037.7600, 7037.4000, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:06:10'),
(213, 2, 'escrow_hold', -0.3600, -0.3600, 7037.4000, 7037.0400, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:06:13'),
(214, 2, 'escrow_hold', -0.3600, -0.3600, 7037.0400, 7036.6800, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:06:16'),
(215, 2, 'escrow_hold', -0.3600, -0.3600, 7036.6800, 7036.3200, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:06:19'),
(216, 2, 'escrow_hold', -0.3600, -0.3600, 7036.3200, 7035.9600, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:06:22'),
(217, 2, 'escrow_hold', -0.1200, -0.1200, 7035.9600, 7035.8400, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.1200 coins.', 'completed', '2026-08-25 01:06:23'),
(218, 2, 'escrow_hold', -0.2400, -0.2400, 7035.8400, 7035.6000, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-08-25 01:06:25'),
(219, 2, 'escrow_hold', -0.3600, -0.3600, 7035.6000, 7035.2400, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:06:28'),
(220, 2, 'escrow_hold', -0.3600, -0.3600, 7035.2400, 7034.8800, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:06:32'),
(221, 2, 'escrow_hold', -0.2400, -0.2400, 7034.8800, 7034.6400, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-08-25 01:06:33'),
(222, 2, 'escrow_hold', -0.1200, -0.1200, 7034.6400, 7034.5200, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.1200 coins.', 'completed', '2026-08-25 01:06:34'),
(223, 2, 'escrow_hold', -0.6000, -0.6000, 7034.5200, 7033.9200, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.6000 coins.', 'completed', '2026-08-25 01:06:39'),
(224, 2, 'escrow_hold', -0.1200, -0.1200, 7033.9200, 7033.8000, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.1200 coins.', 'completed', '2026-08-25 01:06:40'),
(225, 2, 'escrow_hold', -0.3600, -0.3600, 7033.8000, 7033.4400, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:06:43'),
(226, 2, 'escrow_hold', -0.4800, -0.4800, 7033.4400, 7032.9600, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.4800 coins.', 'completed', '2026-08-25 01:06:47'),
(227, 2, 'escrow_hold', -0.3600, -0.3600, 7032.9600, 7032.6000, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:06:50'),
(228, 2, 'escrow_hold', -0.2400, -0.2400, 7032.6000, 7032.3600, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-08-25 01:06:52'),
(229, 2, 'escrow_hold', -0.1200, -0.1200, 7032.3600, 7032.2400, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.1200 coins.', 'completed', '2026-08-25 01:06:53'),
(230, 2, 'escrow_hold', -0.2400, -0.2400, 7032.2400, 7032.0000, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-08-25 01:06:55'),
(231, 2, 'escrow_hold', -0.3600, -0.3600, 7032.0000, 7031.6400, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:06:58'),
(232, 2, 'escrow_hold', -0.3600, -0.3600, 7031.6400, 7031.2800, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:07:01'),
(233, 2, 'escrow_hold', -0.2400, -0.2400, 7031.2800, 7031.0400, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-08-25 01:07:03'),
(234, 2, 'escrow_hold', -0.1200, -0.1200, 7031.0400, 7030.9200, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.1200 coins.', 'completed', '2026-08-25 01:07:04'),
(235, 2, 'escrow_hold', -0.3600, -0.3600, 7030.9200, 7030.5600, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:07:07'),
(236, 2, 'escrow_hold', -0.3600, -0.3600, 7030.5600, 7030.2000, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:07:10'),
(237, 2, 'escrow_hold', -0.3600, -0.3600, 7030.2000, 7029.8400, 'Pay As You Go escrow — call #48', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:07:13'),
(238, 2, 'escrow_hold', -0.2400, -0.2400, 7029.8400, 7029.6000, 'Pay As You Go final escrow — call #48', 'Final Pay As You Go escrow adjustment of 0.2400 coins.', 'completed', '2026-08-25 01:07:16'),
(239, 2, 'escrow_release', 0.0000, -11.4000, 226.4000, 215.0000, 'Payment to mozel — Call #48', 'Payment of 11.40 released to mozel for call #48.', 'completed', '2026-08-25 01:07:19'),
(240, 1, 'escrow_release', 0.0000, 11.4000, 3294.0000, 3305.4000, 'Payment from James — Call #48', 'Call earnings of 11.40 received from James for call #48.', 'completed', '2026-08-25 01:07:19'),
(241, 2, 'escrow_hold', -6.0000, -6.0000, 7029.6000, 7023.6000, 'Call escrow hold — request #68', 'Escrow hold of 6.0000 coins for call with influencer #1.', 'completed', '2026-08-25 01:08:28'),
(242, 2, 'escrow_hold', -6.0000, -6.0000, 7023.6000, 7017.6000, 'Pay As You Go escrow — call #49', 'Pay As You Go escrow top-up of 6.0000 coins.', 'completed', '2026-08-25 01:09:28'),
(243, 2, 'escrow_release', 0.0000, -12.0000, 227.0000, 215.0000, 'Payment to mozel — Call #49', 'Payment of 12.00 released to mozel for call #49.', 'completed', '2026-08-25 01:09:34'),
(244, 1, 'escrow_release', 0.0000, 12.0000, 3305.4000, 3317.4000, 'Payment from James — Call #49', 'Call earnings of 12.00 received from James for call #49.', 'completed', '2026-08-25 01:09:34'),
(245, 2, 'escrow_hold', -0.1200, -0.1200, 7017.6000, 7017.4800, 'Call escrow hold — request #69', 'Escrow hold of 0.1200 coins for call with influencer #1.', 'completed', '2026-08-25 01:15:54'),
(246, 2, 'escrow_hold', -0.3600, -0.3600, 7017.4800, 7017.1200, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:15:57'),
(247, 2, 'escrow_hold', -0.3600, -0.3600, 7017.1200, 7016.7600, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:00'),
(248, 2, 'escrow_hold', -0.3600, -0.3600, 7016.7600, 7016.4000, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:03'),
(249, 2, 'escrow_hold', -0.3600, -0.3600, 7016.4000, 7016.0400, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:06'),
(250, 2, 'escrow_hold', -0.3600, -0.3600, 7016.0400, 7015.6800, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:06'),
(251, 2, 'escrow_hold', -0.3600, -0.3600, 7015.6800, 7015.3200, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:09'),
(252, 2, 'escrow_hold', -0.3600, -0.3600, 7015.3200, 7014.9600, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:12'),
(253, 2, 'escrow_hold', -0.3600, -0.3600, 7014.9600, 7014.6000, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:15'),
(254, 2, 'escrow_hold', -0.3600, -0.3600, 7014.6000, 7014.2400, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:18'),
(255, 2, 'escrow_hold', -0.3600, -0.3600, 7014.2400, 7013.8800, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:21'),
(256, 2, 'escrow_hold', -0.3600, -0.3600, 7013.8800, 7013.5200, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:24'),
(257, 2, 'escrow_hold', -0.3600, -0.3600, 7013.5200, 7013.1600, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:27'),
(258, 2, 'escrow_hold', -0.3600, -0.3600, 7013.1600, 7012.8000, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:30'),
(259, 2, 'escrow_hold', -0.1200, -0.1200, 7012.8000, 7012.6800, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.1200 coins.', 'completed', '2026-08-25 01:16:31'),
(260, 2, 'escrow_hold', -0.2400, -0.2400, 7012.6800, 7012.4400, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-08-25 01:16:33'),
(261, 2, 'escrow_hold', -0.3600, -0.3600, 7012.4400, 7012.0800, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:36'),
(262, 2, 'escrow_hold', -0.3600, -0.3600, 7012.0800, 7011.7200, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:39'),
(263, 2, 'escrow_hold', -0.3600, -0.3600, 7011.7200, 7011.3600, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:42'),
(264, 2, 'escrow_hold', -0.3600, -0.3600, 7011.3600, 7011.0000, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:45'),
(265, 2, 'escrow_hold', -0.3600, -0.3600, 7011.0000, 7010.6400, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:48'),
(266, 2, 'escrow_hold', -0.3600, -0.3600, 7010.6400, 7010.2800, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:51'),
(267, 2, 'escrow_hold', -0.3600, -0.3600, 7010.2800, 7009.9200, 'Pay As You Go escrow — call #50', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-08-25 01:16:54'),
(268, 2, 'escrow_release', 0.0000, -7.3200, 222.6800, 215.3600, 'Payment to mozel — Call #50', 'Payment of 7.32 released to mozel for call #50.', 'completed', '2026-08-25 01:17:03'),
(269, 1, 'escrow_release', 0.0000, 7.3200, 3317.4000, 3324.7200, 'Payment from James — Call #50', 'Call earnings of 7.32 received from James for call #50.', 'completed', '2026-08-25 01:17:03'),
(270, 2, 'escrow_hold', -0.1200, -0.1200, 7009.9200, 7009.8000, 'Call escrow hold — request #70', 'Escrow hold of 0.1200 coins for call with influencer #9.', 'completed', '2026-09-05 09:17:27'),
(271, 2, 'escrow_hold', -0.9600, -0.9600, 7009.8000, 7008.8400, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.9600 coins.', 'completed', '2026-09-05 09:17:35'),
(272, 2, 'escrow_hold', -0.2400, -0.2400, 7008.8400, 7008.6000, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-09-05 09:17:37'),
(273, 2, 'escrow_hold', -0.2400, -0.2400, 7008.6000, 7008.3600, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-09-05 09:17:37'),
(274, 2, 'escrow_hold', -0.3600, -0.3600, 7008.3600, 7008.0000, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:17:40'),
(275, 2, 'escrow_hold', -0.3600, -0.3600, 7008.0000, 7007.6400, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:17:43'),
(276, 2, 'escrow_hold', -0.3600, -0.3600, 7007.6400, 7007.2800, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:17:46'),
(277, 2, 'escrow_hold', -0.3600, -0.3600, 7007.2800, 7006.9200, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:17:49'),
(278, 2, 'escrow_hold', -0.3600, -0.3600, 7006.9200, 7006.5600, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:17:52'),
(279, 2, 'escrow_hold', -0.4800, -0.4800, 7006.5600, 7006.0800, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.4800 coins.', 'completed', '2026-09-05 09:17:56'),
(280, 2, 'escrow_hold', -0.4800, -0.4800, 7006.0800, 7005.6000, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.4800 coins.', 'completed', '2026-09-05 09:17:56'),
(281, 2, 'escrow_hold', -0.2400, -0.2400, 7005.6000, 7005.3600, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-09-05 09:17:58'),
(282, 2, 'escrow_hold', -0.3600, -0.3600, 7005.3600, 7005.0000, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:01'),
(283, 2, 'escrow_hold', -0.3600, -0.3600, 7005.0000, 7004.6400, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:04'),
(284, 2, 'escrow_hold', -0.3600, -0.3600, 7004.6400, 7004.2800, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:07'),
(285, 2, 'escrow_hold', -0.3600, -0.3600, 7004.2800, 7003.9200, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:10'),
(286, 2, 'escrow_hold', -0.3600, -0.3600, 7003.9200, 7003.5600, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:13'),
(287, 2, 'escrow_hold', -0.3600, -0.3600, 7003.5600, 7003.2000, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:16'),
(288, 2, 'escrow_hold', -0.4800, -0.4800, 7003.2000, 7002.7200, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.4800 coins.', 'completed', '2026-09-05 09:18:20'),
(289, 2, 'escrow_hold', -0.2400, -0.2400, 7002.7200, 7002.4800, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-09-05 09:18:22'),
(290, 2, 'escrow_hold', -0.3600, -0.3600, 7002.4800, 7002.1200, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:25'),
(291, 2, 'escrow_hold', -0.3600, -0.3600, 7002.1200, 7001.7600, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:25'),
(292, 2, 'escrow_hold', -0.3600, -0.3600, 7001.7600, 7001.4000, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:28'),
(293, 2, 'escrow_hold', -0.3600, -0.3600, 7001.4000, 7001.0400, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:31');
INSERT INTO `wallet_transactions` (`id`, `user_id`, `type`, `coins_change`, `amount_change`, `balance_before`, `balance_after`, `reference`, `description`, `status`, `created_at`) VALUES
(294, 2, 'escrow_hold', -0.3600, -0.3600, 7001.0400, 7000.6800, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:34'),
(295, 2, 'escrow_hold', -0.3600, -0.3600, 7000.6800, 7000.3200, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:37'),
(296, 2, 'escrow_hold', -0.3600, -0.3600, 7000.3200, 6999.9600, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:40'),
(297, 2, 'escrow_hold', -0.3600, -0.3600, 6999.9600, 6999.6000, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:43'),
(298, 2, 'escrow_hold', -0.3600, -0.3600, 6999.6000, 6999.2400, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:46'),
(299, 2, 'escrow_hold', -0.3600, -0.3600, 6999.2400, 6998.8800, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:49'),
(300, 2, 'escrow_hold', -0.3600, -0.3600, 6998.8800, 6998.5200, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:52'),
(301, 2, 'escrow_hold', -0.3600, -0.3600, 6998.5200, 6998.1600, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:55'),
(302, 2, 'escrow_hold', -0.3600, -0.3600, 6998.1600, 6997.8000, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:18:58'),
(303, 2, 'escrow_hold', -0.3600, -0.3600, 6997.8000, 6997.4400, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:01'),
(304, 2, 'escrow_hold', -0.3600, -0.3600, 6997.4400, 6997.0800, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:04'),
(305, 2, 'escrow_hold', -0.3600, -0.3600, 6997.0800, 6996.7200, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:07'),
(306, 2, 'escrow_hold', -0.3600, -0.3600, 6996.7200, 6996.3600, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:10'),
(307, 2, 'escrow_hold', -0.3600, -0.3600, 6996.3600, 6996.0000, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:13'),
(308, 2, 'escrow_hold', -0.3600, -0.3600, 6996.0000, 6995.6400, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:16'),
(309, 2, 'escrow_hold', -0.3600, -0.3600, 6995.6400, 6995.2800, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:19'),
(310, 2, 'escrow_hold', -0.3600, -0.3600, 6995.2800, 6994.9200, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:22'),
(311, 2, 'escrow_hold', -0.3600, -0.3600, 6994.9200, 6994.5600, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:25'),
(312, 2, 'escrow_hold', -0.3600, -0.3600, 6994.5600, 6994.2000, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:25'),
(313, 2, 'escrow_hold', -0.3600, -0.3600, 6994.2000, 6993.8400, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:28'),
(314, 2, 'escrow_hold', -0.3600, -0.3600, 6993.8400, 6993.4800, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:29'),
(315, 2, 'escrow_hold', -0.3600, -0.3600, 6993.4800, 6993.1200, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:31'),
(316, 2, 'escrow_hold', -0.3600, -0.3600, 6993.1200, 6992.7600, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:31'),
(317, 2, 'escrow_hold', -0.4800, -0.4800, 6992.7600, 6992.2800, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.4800 coins.', 'completed', '2026-09-05 09:19:35'),
(318, 2, 'escrow_hold', -0.4800, -0.4800, 6992.2800, 6991.8000, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.4800 coins.', 'completed', '2026-09-05 09:19:35'),
(319, 2, 'escrow_hold', -0.2400, -0.2400, 6991.8000, 6991.5600, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-09-05 09:19:37'),
(320, 2, 'escrow_hold', -0.2400, -0.2400, 6991.5600, 6991.3200, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-09-05 09:19:37'),
(321, 2, 'escrow_hold', -0.3600, -0.3600, 6991.3200, 6990.9600, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:40'),
(322, 2, 'escrow_hold', -0.3600, -0.3600, 6990.9600, 6990.6000, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.3600 coins.', 'completed', '2026-09-05 09:19:43'),
(323, 2, 'escrow_hold', -0.1200, -0.1200, 6990.6000, 6990.4800, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.1200 coins.', 'completed', '2026-09-05 09:19:44'),
(324, 2, 'escrow_hold', -0.2400, -0.2400, 6990.4800, 6990.2400, 'Pay As You Go escrow — call #51', 'Pay As You Go escrow top-up of 0.2400 coins.', 'completed', '2026-09-05 09:19:46'),
(325, 2, 'escrow_hold', -0.1200, -0.1200, 6990.2400, 6990.1200, 'Pay As You Go final escrow — call #51', 'Final Pay As You Go escrow adjustment of 0.1200 coins.', 'completed', '2026-09-05 09:19:48'),
(326, 2, 'escrow_release', 0.0000, -16.9200, 235.1600, 218.2400, 'Payment to Amelia — Call #51', 'Payment of 16.92 released to Amelia for call #51.', 'completed', '2026-09-05 09:20:01'),
(327, 9, 'escrow_release', 0.0000, 16.9200, 0.0000, 16.9200, 'Payment from James — Call #51', 'Call earnings of 16.92 received from James for call #51.', 'completed', '2026-09-05 09:20:01');

-- --------------------------------------------------------

--
-- Table structure for table `withdrawal_requests`
--

CREATE TABLE `withdrawal_requests` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `fee` decimal(15,2) DEFAULT '0.00',
  `net_amount` decimal(15,2) NOT NULL,
  `status` enum('pending','completed','rejected') DEFAULT 'pending',
  `reference` varchar(100) DEFAULT NULL,
  `admin_note` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `withdrawal_requests`
--

INSERT INTO `withdrawal_requests` (`id`, `user_id`, `amount`, `fee`, `net_amount`, `status`, `reference`, `admin_note`, `created_at`, `completed_at`) VALUES
(1, 1, 50.00, 0.00, 50.00, 'completed', NULL, '', '2026-08-01 00:25:54', '2026-08-01 00:28:09'),
(2, 1, 50.00, 0.00, 50.00, 'completed', NULL, '', '2026-08-01 00:36:07', '2026-08-07 13:00:14');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `call_minute_costs`
--
ALTER TABLE `call_minute_costs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_minutes` (`minutes`);

--
-- Indexes for table `call_requests`
--
ALTER TABLE `call_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `influencer_id` (`influencer_id`);

--
-- Indexes for table `call_tracking`
--
ALTER TABLE `call_tracking`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_call_tracking_call_id` (`call_id`),
  ADD KEY `idx_call_tracking_influencer` (`influencer_id`),
  ADD KEY `idx_call_tracking_client` (`client_id`),
  ADD KEY `idx_call_tracking_created_at` (`created_at`);

--
-- Indexes for table `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sender_id` (`sender_id`),
  ADD KEY `receiver_id` (`receiver_id`);

--
-- Indexes for table `coin_packages`
--
ALTER TABLE `coin_packages`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `email_verification_tokens`
--
ALTER TABLE `email_verification_tokens`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_type_used` (`user_id`,`type`,`used`);

--
-- Indexes for table `follows`
--
ALTER TABLE `follows`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_follow` (`follower_id`,`following_id`),
  ADD KEY `idx_follows_following` (`following_id`),
  ADD KEY `idx_follows_follower` (`follower_id`);

--
-- Indexes for table `influencer_gallery`
--
ALTER TABLE `influencer_gallery`
  ADD PRIMARY KEY (`id`),
  ADD KEY `influencer_id` (`influencer_id`);

--
-- Indexes for table `influencer_profiles`
--
ALTER TABLE `influencer_profiles`
  ADD PRIMARY KEY (`user_id`),
  ADD KEY `idx_influencer_profiles_completed` (`profile_completed`),
  ADD KEY `idx_influencer_last_active_ping` (`last_active_ping`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_notifications_user_read` (`user_id`,`is_read`),
  ADD KEY `idx_notifications_support_agent` (`support_agent_id`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `payg_call_pricing`
--
ALTER TABLE `payg_call_pricing`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `package_id` (`package_id`),
  ADD KEY `idx_payments_user_status` (`user_id`,`status`),
  ADD KEY `idx_payments_paystack_reference` (`payment_reference`),
  ADD KEY `idx_payments_payment_reference` (`payment_reference`);

--
-- Indexes for table `posts`
--
ALTER TABLE `posts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_posts_influencer` (`influencer_id`),
  ADD KEY `idx_posts_created` (`created_at` DESC);

--
-- Indexes for table `post_comments`
--
ALTER TABLE `post_comments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_post_comments_post` (`post_id`),
  ADD KEY `idx_post_comments_user` (`user_id`);

--
-- Indexes for table `post_images`
--
ALTER TABLE `post_images`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_post_images_post` (`post_id`);

--
-- Indexes for table `post_likes`
--
ALTER TABLE `post_likes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_post_like` (`post_id`,`user_id`),
  ADD KEY `idx_post_likes_user` (`user_id`);

--
-- Indexes for table `referral_commissions`
--
ALTER TABLE `referral_commissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_referral_commission_payment` (`payment_id`),
  ADD KEY `idx_referral_commissions_referrer` (`referrer_id`),
  ADD KEY `idx_referral_commissions_referred` (`referred_user_id`);

--
-- Indexes for table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reported_user_id` (`reported_user_id`),
  ADD KEY `call_id` (`call_id`),
  ADD KEY `idx_reports_reporter_call` (`reporter_id`,`call_id`),
  ADD KEY `idx_reports_status_created` (`status`,`created_at` DESC);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idx_reviews_call_id_unique` (`call_id`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `influencer_id` (`influencer_id`);

--
-- Indexes for table `saved_influencers`
--
ALTER TABLE `saved_influencers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_saved_influencers` (`client_id`,`influencer_id`),
  ADD KEY `influencer_id` (`influencer_id`),
  ADD KEY `idx_saved_influencers_client` (`client_id`);

--
-- Indexes for table `support_agents`
--
ALTER TABLE `support_agents`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_support_email` (`email`),
  ADD UNIQUE KEY `uniq_support_password_checksum` (`password_checksum`);

--
-- Indexes for table `support_conversations`
--
ALTER TABLE `support_conversations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_support_conv_customer` (`customer_id`),
  ADD KEY `idx_support_conv_agent` (`support_agent_id`),
  ADD KEY `idx_support_conv_status` (`status`);

--
-- Indexes for table `support_feedback`
--
ALTER TABLE `support_feedback`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_support_feedback_conv` (`conversation_id`),
  ADD KEY `idx_support_feedback_agent` (`support_agent_id`),
  ADD KEY `fk_support_feedback_customer` (`customer_id`);

--
-- Indexes for table `support_messages`
--
ALTER TABLE `support_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_support_msg_conv` (`conversation_id`);

--
-- Indexes for table `support_tokens`
--
ALTER TABLE `support_tokens`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_support_tokens_token` (`token`),
  ADD KEY `idx_support_tokens_agent` (`support_agent_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `referral_code` (`referral_code`),
  ADD KEY `idx_users_referred_by` (`referred_by`);

--
-- Indexes for table `user_tokens`
--
ALTER TABLE `user_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `video_calls`
--
ALTER TABLE `video_calls`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `influencer_id` (`influencer_id`),
  ADD KEY `idx_video_calls_escrow_lookup` (`escrow_status`,`end_time`),
  ADD KEY `idx_video_calls_call_request_id` (`call_request_id`);

--
-- Indexes for table `wallets`
--
ALTER TABLE `wallets`
  ADD PRIMARY KEY (`user_id`);

--
-- Indexes for table `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_wallet_transactions_user_created` (`user_id`,`created_at` DESC);

--
-- Indexes for table `withdrawal_requests`
--
ALTER TABLE `withdrawal_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_withdrawal_requests_user_status` (`user_id`,`status`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `call_minute_costs`
--
ALTER TABLE `call_minute_costs`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `call_requests`
--
ALTER TABLE `call_requests`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

--
-- AUTO_INCREMENT for table `call_tracking`
--
ALTER TABLE `call_tracking`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `chat_messages`
--
ALTER TABLE `chat_messages`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `coin_packages`
--
ALTER TABLE `coin_packages`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `email_verification_tokens`
--
ALTER TABLE `email_verification_tokens`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=57;

--
-- AUTO_INCREMENT for table `follows`
--
ALTER TABLE `follows`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `influencer_gallery`
--
ALTER TABLE `influencer_gallery`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=453;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `posts`
--
ALTER TABLE `posts`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `post_comments`
--
ALTER TABLE `post_comments`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `post_images`
--
ALTER TABLE `post_images`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `post_likes`
--
ALTER TABLE `post_likes`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `referral_commissions`
--
ALTER TABLE `referral_commissions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `saved_influencers`
--
ALTER TABLE `saved_influencers`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `support_agents`
--
ALTER TABLE `support_agents`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `support_conversations`
--
ALTER TABLE `support_conversations`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `support_feedback`
--
ALTER TABLE `support_feedback`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `support_messages`
--
ALTER TABLE `support_messages`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `support_tokens`
--
ALTER TABLE `support_tokens`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `user_tokens`
--
ALTER TABLE `user_tokens`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=98;

--
-- AUTO_INCREMENT for table `video_calls`
--
ALTER TABLE `video_calls`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT for table `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=328;

--
-- AUTO_INCREMENT for table `withdrawal_requests`
--
ALTER TABLE `withdrawal_requests`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `call_requests`
--
ALTER TABLE `call_requests`
  ADD CONSTRAINT `call_requests_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `call_requests_ibfk_2` FOREIGN KEY (`influencer_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD CONSTRAINT `chat_messages_ibfk_1` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `chat_messages_ibfk_2` FOREIGN KEY (`receiver_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `email_verification_tokens`
--
ALTER TABLE `email_verification_tokens`
  ADD CONSTRAINT `fk_evt_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `follows`
--
ALTER TABLE `follows`
  ADD CONSTRAINT `fk_follows_follower` FOREIGN KEY (`follower_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_follows_following` FOREIGN KEY (`following_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `influencer_gallery`
--
ALTER TABLE `influencer_gallery`
  ADD CONSTRAINT `influencer_gallery_ibfk_1` FOREIGN KEY (`influencer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `influencer_profiles`
--
ALTER TABLE `influencer_profiles`
  ADD CONSTRAINT `influencer_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notifications_support_agent` FOREIGN KEY (`support_agent_id`) REFERENCES `support_agents` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD CONSTRAINT `password_resets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `payments_ibfk_2` FOREIGN KEY (`package_id`) REFERENCES `coin_packages` (`id`);

--
-- Constraints for table `posts`
--
ALTER TABLE `posts`
  ADD CONSTRAINT `fk_posts_influencer` FOREIGN KEY (`influencer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `post_comments`
--
ALTER TABLE `post_comments`
  ADD CONSTRAINT `fk_post_comments_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_post_comments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `post_images`
--
ALTER TABLE `post_images`
  ADD CONSTRAINT `fk_post_images_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `post_likes`
--
ALTER TABLE `post_likes`
  ADD CONSTRAINT `fk_post_likes_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_post_likes_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `referral_commissions`
--
ALTER TABLE `referral_commissions`
  ADD CONSTRAINT `fk_referral_commissions_payment` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_referral_commissions_referred` FOREIGN KEY (`referred_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_referral_commissions_referrer` FOREIGN KEY (`referrer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reports`
--
ALTER TABLE `reports`
  ADD CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`reporter_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reports_ibfk_2` FOREIGN KEY (`reported_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reports_ibfk_3` FOREIGN KEY (`call_id`) REFERENCES `video_calls` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`call_id`) REFERENCES `video_calls` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`client_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_3` FOREIGN KEY (`influencer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `saved_influencers`
--
ALTER TABLE `saved_influencers`
  ADD CONSTRAINT `saved_influencers_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `saved_influencers_ibfk_2` FOREIGN KEY (`influencer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `support_conversations`
--
ALTER TABLE `support_conversations`
  ADD CONSTRAINT `fk_support_conv_agent` FOREIGN KEY (`support_agent_id`) REFERENCES `support_agents` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_support_conv_customer` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `support_feedback`
--
ALTER TABLE `support_feedback`
  ADD CONSTRAINT `fk_support_feedback_agent` FOREIGN KEY (`support_agent_id`) REFERENCES `support_agents` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_support_feedback_conv` FOREIGN KEY (`conversation_id`) REFERENCES `support_conversations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_support_feedback_customer` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `support_messages`
--
ALTER TABLE `support_messages`
  ADD CONSTRAINT `fk_support_msg_conv` FOREIGN KEY (`conversation_id`) REFERENCES `support_conversations` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `support_tokens`
--
ALTER TABLE `support_tokens`
  ADD CONSTRAINT `fk_support_tokens_agent` FOREIGN KEY (`support_agent_id`) REFERENCES `support_agents` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_referred_by` FOREIGN KEY (`referred_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `user_tokens`
--
ALTER TABLE `user_tokens`
  ADD CONSTRAINT `user_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `video_calls`
--
ALTER TABLE `video_calls`
  ADD CONSTRAINT `video_calls_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `video_calls_ibfk_2` FOREIGN KEY (`influencer_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `wallets`
--
ALTER TABLE `wallets`
  ADD CONSTRAINT `wallets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  ADD CONSTRAINT `wallet_transactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `withdrawal_requests`
--
ALTER TABLE `withdrawal_requests`
  ADD CONSTRAINT `withdrawal_requests_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
