<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>MaskedParty — Meet New People. Make Private Video Calls</title>

    <meta name="description" content="MaskedParty is a social connection platform where you can meet new people, make friends, enjoy private video calls, and earn as a creator.">

    <meta name="theme-color" content="#0a0a0a">

    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --black: #090909;
            --black-soft: #111111;
            --white: #ffffff;
            --off-white: #f7f7f5;
            --gray: #777777;
            --gray-light: #e8e8e8;
            --accent: #ff1674;
            --accent-dark: #dc075c;
            --accent-light: #fff0f6;
            --border: rgba(0, 0, 0, 0.08);
            --shadow: 0 20px 60px rgba(0, 0, 0, 0.08);
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI",
                Roboto, Helvetica, Arial, sans-serif;
            background: var(--white);
            color: var(--black);
            overflow-x: hidden;
            line-height: 1.6;
        }

        a {
            color: inherit;
            text-decoration: none;
        }

        button {
            font: inherit;
        }

        /* =========================
           NAVIGATION
        ========================= */

        .navbar {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            z-index: 1000;
            padding: 18px 5%;
            transition: 0.3s ease;
        }

        .navbar.scrolled {
            background: rgba(255, 255, 255, 0.92);
            backdrop-filter: blur(18px);
            box-shadow: 0 1px 0 rgba(0,0,0,0.06);
        }

        .nav-inner {
            max-width: 1250px;
            margin: auto;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            font-weight: 800;
            font-size: 20px;
            letter-spacing: -0.5px;
        }

        .brand-logo {
            width: 44px;
            height: 44px;
            border-radius: 13px;
            object-fit: cover;
            background: var(--black);
            box-shadow: 0 8px 20px rgba(0,0,0,0.12);
        }

        .nav-links {
            display: flex;
            align-items: center;
            gap: 34px;
            font-size: 14px;
            font-weight: 600;
            color: #555;
        }

        .nav-links a {
            transition: 0.2s ease;
        }

        .nav-links a:hover {
            color: var(--accent);
        }

        .nav-download {
            background: var(--black);
            color: white !important;
            padding: 12px 21px;
            border-radius: 100px;
            transition: 0.25s ease;
        }

        .nav-download:hover {
            background: var(--accent);
            transform: translateY(-2px);
        }

        .menu-btn {
            display: none;
            border: none;
            background: transparent;
            font-size: 28px;
            cursor: pointer;
        }

        /* =========================
           HERO
        ========================= */

        .hero {
            min-height: 100vh;
            padding: 150px 5% 90px;
            position: relative;
            overflow: hidden;
            display: flex;
            align-items: center;
        }

        .hero::before {
            content: "";
            position: absolute;
            width: 600px;
            height: 600px;
            background: var(--accent-light);
            border-radius: 50%;
            right: -220px;
            top: 80px;
            filter: blur(2px);
        }

        .hero::after {
            content: "";
            position: absolute;
            width: 350px;
            height: 350px;
            background: #f3f3f3;
            border-radius: 50%;
            left: -180px;
            bottom: -160px;
        }

        .hero-container {
            width: 100%;
            max-width: 1250px;
            margin: auto;
            position: relative;
            z-index: 2;
            display: grid;
            grid-template-columns: 1.05fr 0.95fr;
            align-items: center;
            gap: 80px;
        }

        .hero-content {
            max-width: 650px;
        }

        .hero-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 8px 14px;
            background: #f4f4f4;
            border: 1px solid #e7e7e7;
            border-radius: 100px;
            font-size: 13px;
            font-weight: 700;
            margin-bottom: 25px;
        }

        .badge-dot {
            width: 8px;
            height: 8px;
            background: var(--accent);
            border-radius: 50%;
            box-shadow: 0 0 0 5px rgba(255,22,116,0.1);
        }

        .hero h1 {
            font-size: clamp(52px, 7vw, 88px);
            line-height: 0.98;
            letter-spacing: -5px;
            font-weight: 900;
            margin-bottom: 28px;
        }

        .hero h1 span {
            color: var(--accent);
        }

        .hero-text {
            color: #606060;
            font-size: 19px;
            max-width: 590px;
            margin-bottom: 35px;
            line-height: 1.65;
        }

        .hero-buttons {
            display: flex;
            align-items: center;
            gap: 14px;
            flex-wrap: wrap;
        }

        .btn {
            display: inline-flex;
            justify-content: center;
            align-items: center;
            gap: 10px;
            padding: 16px 25px;
            border-radius: 100px;
            font-weight: 800;
            font-size: 15px;
            cursor: pointer;
            border: none;
            transition: 0.25s ease;
        }

        .btn-primary {
            color: white;
            background: var(--black);
            box-shadow: 0 12px 30px rgba(0,0,0,0.15);
        }

        .btn-primary:hover {
            background: var(--accent);
            transform: translateY(-3px);
            box-shadow: 0 15px 35px rgba(255,22,116,0.25);
        }

        .btn-secondary {
            background: white;
            color: var(--black);
            border: 1px solid #dedede;
        }

        .btn-secondary:hover {
            border-color: var(--black);
            transform: translateY(-3px);
        }

        .hero-note {
            margin-top: 22px;
            font-size: 12px;
            color: #999;
        }

        /* HERO VISUAL */

        .hero-visual {
            position: relative;
            min-height: 590px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .phone-card {
            width: min(390px, 85%);
            min-height: 560px;
            border-radius: 42px;
            background: var(--black);
            padding: 12px;
            position: relative;
            transform: rotate(4deg);
            box-shadow:
                0 45px 90px rgba(0,0,0,0.20),
                0 0 0 1px rgba(255,255,255,0.08);
            z-index: 2;
        }

        .phone-screen {
            width: 100%;
            height: 100%;
            min-height: 536px;
            border-radius: 33px;
            background: linear-gradient(145deg, #fff, #f5f5f5);
            padding: 28px 20px;
            overflow: hidden;
        }

        .phone-top {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
        }

        .phone-brand {
            display: flex;
            align-items: center;
            gap: 8px;
            font-weight: 900;
            font-size: 17px;
        }

        .mini-logo {
            width: 32px;
            height: 32px;
            object-fit: cover;
            border-radius: 10px;
            background: var(--black);
        }

        .phone-icon {
            width: 35px;
            height: 35px;
            border-radius: 50%;
            background: white;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 5px 15px rgba(0,0,0,0.07);
        }

        .phone-title {
            font-size: 29px;
            line-height: 1.05;
            font-weight: 900;
            letter-spacing: -1.5px;
            margin-bottom: 7px;
        }

        .phone-subtitle {
            color: #777;
            font-size: 13px;
            margin-bottom: 20px;
        }

        .profile-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 11px;
        }

        .profile {
            height: 150px;
            border-radius: 20px;
            background: linear-gradient(135deg, #ededed, #fafafa);
            border: 1px solid #e4e4e4;
            padding: 13px;
            display: flex;
            flex-direction: column;
            justify-content: flex-end;
            position: relative;
            overflow: hidden;
        }

        .profile::before {
            content: "";
            position: absolute;
            width: 90px;
            height: 90px;
            border-radius: 50%;
            background: var(--accent-light);
            right: -15px;
            top: -20px;
        }

        .profile-avatar {
            width: 45px;
            height: 45px;
            border-radius: 50%;
            background: #d5d5d5;
            margin-bottom: auto;
            position: relative;
        }

        .profile-avatar::after {
            content: "";
            position: absolute;
            width: 11px;
            height: 11px;
            background: #29c76f;
            border: 3px solid white;
            border-radius: 50%;
            right: -2px;
            bottom: 1px;
        }

        .profile-name {
            font-weight: 800;
            font-size: 13px;
        }

        .profile-location {
            font-size: 10px;
            color: #888;
        }

        .call-button {
            position: absolute;
            right: 10px;
            bottom: 11px;
            width: 34px;
            height: 34px;
            border-radius: 50%;
            background: var(--accent);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            font-size: 14px;
        }

        .earn-card {
            margin-top: 14px;
            padding: 18px;
            border-radius: 20px;
            background: var(--black);
            color: white;
        }

        .earn-label {
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            opacity: 0.55;
        }

        .earn-title {
            font-size: 19px;
            font-weight: 800;
            margin-top: 4px;
        }

        .earn-row {
            display: flex;
            justify-content: space-between;
            align-items: end;
            margin-top: 15px;
        }

        .earn-money {
            color: #fff;
            font-size: 25px;
            font-weight: 900;
        }

        .earn-status {
            font-size: 10px;
            color: #bbb;
        }

        .floating-card {
            position: absolute;
            z-index: 4;
            background: white;
            border-radius: 18px;
            padding: 15px 17px;
            box-shadow: 0 20px 50px rgba(0,0,0,0.12);
            display: flex;
            align-items: center;
            gap: 12px;
            animation: float 4s ease-in-out infinite;
        }

        .floating-one {
            top: 75px;
            left: 0;
        }

        .floating-two {
            right: -10px;
            bottom: 65px;
            animation-delay: 1.3s;
        }

        .float-icon {
            width: 42px;
            height: 42px;
            border-radius: 13px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: var(--accent-light);
            color: var(--accent);
            font-size: 18px;
        }

        .float-title {
            font-size: 12px;
            font-weight: 900;
        }

        .float-text {
            font-size: 10px;
            color: #888;
        }

        @keyframes float {
            0%, 100% {
                transform: translateY(0);
            }
            50% {
                transform: translateY(-12px);
            }
        }

        /* =========================
           TRUST BAR
        ========================= */

        .trust-bar {
            border-top: 1px solid #ededed;
            border-bottom: 1px solid #ededed;
            padding: 23px 5%;
            background: #fafafa;
        }

        .trust-inner {
            max-width: 1100px;
            margin: auto;
            display: flex;
            justify-content: center;
            gap: 55px;
            flex-wrap: wrap;
            color: #777;
            font-size: 13px;
            font-weight: 700;
        }

        .trust-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .trust-item strong {
            color: var(--black);
        }

        /* =========================
           SECTIONS
        ========================= */

        section {
            padding: 110px 5%;
        }

        .section-container {
            max-width: 1150px;
            margin: auto;
        }

        .section-heading {
            max-width: 680px;
            margin-bottom: 60px;
        }

        .eyebrow {
            color: var(--accent);
            font-size: 12px;
            font-weight: 900;
            letter-spacing: 2px;
            text-transform: uppercase;
            margin-bottom: 14px;
        }

        .section-heading h2 {
            font-size: clamp(38px, 5vw, 62px);
            line-height: 1;
            letter-spacing: -3px;
            font-weight: 900;
            margin-bottom: 20px;
        }

        .section-heading p {
            color: #777;
            font-size: 17px;
            line-height: 1.7;
        }

        /* =========================
           FEATURES
        ========================= */

        .features {
            background: var(--off-white);
        }

        .feature-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 18px;
        }

        .feature-card {
            background: white;
            border: 1px solid #e9e9e9;
            border-radius: 27px;
            padding: 32px;
            min-height: 260px;
            transition: 0.3s ease;
        }

        .feature-card:hover {
            transform: translateY(-7px);
            box-shadow: var(--shadow);
        }

        .feature-number {
            color: #d0d0d0;
            font-size: 13px;
            font-weight: 900;
            margin-bottom: 35px;
        }

        .feature-icon {
            width: 53px;
            height: 53px;
            border-radius: 16px;
            background: var(--black);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            margin-bottom: 22px;
            font-size: 21px;
        }

        .feature-card h3 {
            font-size: 21px;
            letter-spacing: -0.5px;
            margin-bottom: 9px;
        }

        .feature-card p {
            color: #777;
            font-size: 14px;
            line-height: 1.65;
        }

        /* =========================
           CREATOR SECTION
        ========================= */

        .creator-section {
            background: var(--black);
            color: white;
            overflow: hidden;
        }

        .creator-grid {
            display: grid;
            grid-template-columns: 0.9fr 1.1fr;
            gap: 90px;
            align-items: center;
        }

        .creator-section .eyebrow {
            color: #ff4b96;
        }

        .creator-section h2 {
            font-size: clamp(40px, 5vw, 64px);
            line-height: 1;
            letter-spacing: -3px;
            margin-bottom: 23px;
        }

        .creator-section .creator-description {
            color: #aaa;
            font-size: 17px;
            line-height: 1.7;
            max-width: 520px;
            margin-bottom: 30px;
        }

        .creator-list {
            display: flex;
            flex-direction: column;
            gap: 15px;
        }

        .creator-item {
            display: flex;
            gap: 15px;
            align-items: flex-start;
            padding: 17px;
            border-radius: 17px;
            background: #151515;
            border: 1px solid #252525;
        }

        .creator-check {
            flex: 0 0 auto;
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background: var(--accent);
            display: flex;
            justify-content: center;
            align-items: center;
            font-size: 13px;
        }

        .creator-item h4 {
            font-size: 14px;
            margin-bottom: 2px;
        }

        .creator-item p {
            font-size: 12px;
            color: #888;
        }

        .creator-visual {
            position: relative;
            min-height: 500px;
        }

        .income-card {
            position: absolute;
            width: 390px;
            max-width: 90%;
            background: #161616;
            border: 1px solid #292929;
            border-radius: 30px;
            padding: 30px;
            right: 30px;
            top: 30px;
            transform: rotate(-4deg);
            box-shadow: 0 30px 80px rgba(0,0,0,0.35);
        }

        .income-top {
            display: flex;
            justify-content: space-between;
            color: #aaa;
            font-size: 12px;
            margin-bottom: 25px;
        }

        .income-amount {
            font-size: 50px;
            font-weight: 900;
            letter-spacing: -3px;
            margin-bottom: 5px;
        }

        .income-positive {
            color: #45d889;
            font-size: 12px;
            font-weight: 800;
        }

        .chart {
            height: 125px;
            display: flex;
            align-items: end;
            gap: 8px;
            margin-top: 30px;
            border-bottom: 1px solid #2c2c2c;
        }

        .bar {
            flex: 1;
            background: linear-gradient(to top, var(--accent), #ff70ab);
            border-radius: 6px 6px 0 0;
            opacity: 0.9;
        }

        .bar:nth-child(1) { height: 28%; }
        .bar:nth-child(2) { height: 42%; }
        .bar:nth-child(3) { height: 35%; }
        .bar:nth-child(4) { height: 56%; }
        .bar:nth-child(5) { height: 50%; }
        .bar:nth-child(6) { height: 73%; }
        .bar:nth-child(7) { height: 67%; }
        .bar:nth-child(8) { height: 91%; }

        .income-bottom {
            display: flex;
            justify-content: space-between;
            margin-top: 20px;
            color: #777;
            font-size: 11px;
        }

        .earning-tag {
            position: absolute;
            bottom: 45px;
            left: 20px;
            padding: 15px 18px;
            background: white;
            color: var(--black);
            border-radius: 18px;
            box-shadow: 0 20px 50px rgba(0,0,0,0.3);
        }

        .earning-tag strong {
            display: block;
            font-size: 14px;
        }

        .earning-tag span {
            color: #888;
            font-size: 10px;
        }

        /* =========================
           HOW IT WORKS
        ========================= */

        .steps {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 15px;
        }

        .step {
            position: relative;
            padding: 27px 22px;
            border: 1px solid #e7e7e7;
            border-radius: 22px;
            background: white;
        }

        .step-number {
            width: 39px;
            height: 39px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: var(--black);
            color: white;
            border-radius: 50%;
            font-size: 13px;
            font-weight: 900;
            margin-bottom: 30px;
        }

        .step h3 {
            font-size: 17px;
            margin-bottom: 9px;
        }

        .step p {
            color: #777;
            font-size: 12px;
            line-height: 1.6;
        }

        /* =========================
           CTA
        ========================= */

        .download-section {
            padding-top: 70px;
            padding-bottom: 110px;
        }

        .download-box {
            max-width: 1150px;
            margin: auto;
            background: var(--off-white);
            border-radius: 35px;
            padding: 75px 8%;
            text-align: center;
            border: 1px solid #ededed;
            position: relative;
            overflow: hidden;
        }

        .download-box::before {
            content: "";
            position: absolute;
            width: 300px;
            height: 300px;
            border-radius: 50%;
            background: var(--accent-light);
            top: -180px;
            left: -100px;
        }

        .download-box::after {
            content: "";
            position: absolute;
            width: 300px;
            height: 300px;
            border-radius: 50%;
            background: #eaeaea;
            right: -130px;
            bottom: -190px;
        }

        .download-content {
            position: relative;
            z-index: 2;
        }

        .download-logo {
            width: 78px;
            height: 78px;
            object-fit: cover;
            border-radius: 22px;
            margin-bottom: 22px;
            box-shadow: 0 15px 30px rgba(0,0,0,0.12);
        }

        .download-box h2 {
            font-size: clamp(38px, 5vw, 58px);
            letter-spacing: -3px;
            line-height: 1;
            margin-bottom: 18px;
            font-weight: 900;
        }

        .download-box p {
            max-width: 570px;
            margin: 0 auto 30px;
            color: #777;
            font-size: 16px;
        }

        .download-button {
            min-width: 210px;
            font-size: 15px;
        }

        /* =========================
           FOOTER
        ========================= */

        footer {
            background: var(--black);
            color: white;
            padding: 55px 5% 30px;
        }

        .footer-inner {
            max-width: 1150px;
            margin: auto;
        }

        .footer-top {
            display: flex;
            justify-content: space-between;
            gap: 40px;
            padding-bottom: 45px;
            border-bottom: 1px solid #252525;
        }

        .footer-brand {
            max-width: 340px;
        }

        .footer-brand .brand {
            margin-bottom: 15px;
        }

        .footer-brand p {
            color: #777;
            font-size: 13px;
            line-height: 1.7;
        }

        .footer-links {
            display: flex;
            gap: 50px;
        }

        .footer-column h4 {
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            color: #888;
            margin-bottom: 15px;
        }

        .footer-column a {
            display: block;
            color: #ccc;
            font-size: 13px;
            margin-bottom: 10px;
            transition: 0.2s ease;
        }

        .footer-column a:hover {
            color: var(--accent);
        }

        .footer-bottom {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding-top: 25px;
            color: #666;
            font-size: 11px;
        }

        /* =========================
           SCROLL REVEAL
        ========================= */

        .reveal {
            opacity: 0;
            transform: translateY(30px);
            transition: 0.7s ease;
        }

        .reveal.visible {
            opacity: 1;
            transform: translateY(0);
        }

        /* =========================
           RESPONSIVE
        ========================= */

        @media (max-width: 1050px) {
            .hero-container {
                gap: 40px;
            }

            .hero h1 {
                font-size: clamp(48px, 7vw, 70px);
            }

            .feature-grid {
                grid-template-columns: repeat(2, 1fr);
            }

            .steps {
                grid-template-columns: repeat(3, 1fr);
            }

            .creator-grid {
                gap: 40px;
            }
        }

        @media (max-width: 800px) {
            .navbar {
                padding: 14px 5%;
            }

            .nav-links {
                position: absolute;
                top: 76px;
                left: 5%;
                right: 5%;
                background: white;
                padding: 20px;
                border-radius: 20px;
                box-shadow: 0 20px 50px rgba(0,0,0,0.1);
                display: none;
                flex-direction: column;
                align-items: stretch;
                gap: 5px;
            }

            .nav-links.active {
                display: flex;
            }

            .nav-links a {
                padding: 13px;
            }

            .nav-download {
                text-align: center;
            }

            .menu-btn {
                display: block;
            }

            .hero {
                padding-top: 125px;
                padding-bottom: 70px;
            }

            .hero-container {
                grid-template-columns: 1fr;
                text-align: center;
            }

            .hero-content {
                margin: auto;
            }

            .hero-text {
                margin-left: auto;
                margin-right: auto;
            }

            .hero-buttons {
                justify-content: center;
            }

            .hero-visual {
                min-height: 560px;
            }

            .phone-card {
                width: min(350px, 82%);
            }

            .floating-one {
                left: 2%;
            }

            .floating-two {
                right: 0;
            }

            .creator-grid {
                grid-template-columns: 1fr;
            }

            .creator-content {
                text-align: center;
            }

            .creator-description {
                margin-left: auto;
                margin-right: auto;
            }

            .creator-list {
                text-align: left;
            }

            .creator-visual {
                min-height: 470px;
            }

            .income-card {
                right: 50%;
                transform: translateX(50%) rotate(-3deg);
            }

            .earning-tag {
                left: 5%;
            }
        }

        @media (max-width: 600px) {
            section {
                padding: 80px 5%;
            }

            .brand {
                font-size: 17px;
            }

            .brand-logo {
                width: 39px;
                height: 39px;
                border-radius: 11px;
            }

            .hero h1 {
                font-size: 49px;
                letter-spacing: -3px;
            }

            .hero-text {
                font-size: 16px;
            }

            .hero-visual {
                min-height: 510px;
            }

            .phone-card {
                min-height: 485px;
                border-radius: 32px;
            }

            .phone-screen {
                min-height: 461px;
                border-radius: 25px;
                padding: 20px 14px;
            }

            .phone-title {
                font-size: 24px;
            }

            .profile {
                height: 125px;
            }

            .floating-card {
                transform: scale(0.82);
            }

            .floating-one {
                left: -8%;
            }

            .floating-two {
                right: -9%;
            }

            .trust-inner {
                gap: 20px;
            }

            .section-heading {
                margin-bottom: 40px;
            }

            .section-heading h2,
            .creator-section h2,
            .download-box h2 {
                letter-spacing: -2px;
            }

            .feature-grid {
                grid-template-columns: 1fr;
            }

            .steps {
                grid-template-columns: 1fr;
            }

            .step {
                min-height: 155px;
            }

            .creator-visual {
                min-height: 410px;
            }

            .income-card {
                width: 330px;
                padding: 23px;
            }

            .income-amount {
                font-size: 42px;
            }

            .footer-top {
                flex-direction: column;
            }

            .footer-links {
                gap: 35px;
                flex-wrap: wrap;
            }

            .footer-bottom {
                flex-direction: column;
                gap: 10px;
                align-items: flex-start;
            }

            .download-box {
                padding: 55px 20px;
                border-radius: 27px;
            }
        }
    </style>
</head>

<body>

    <!-- =========================
         NAVIGATION
    ========================== -->

    <header class="navbar" id="navbar">
        <div class="nav-inner">

            <a href="#" class="brand">
                <img src="logo.png" alt="MaskedParty Logo" class="brand-logo">
                <span>MaskedParty</span>
            </a>

            <nav class="nav-links" id="navLinks">
                <a href="#features">Features</a>
                <a href="#creators">For Creators</a>
                <a href="#how-it-works">How It Works</a>
                <a href="#download" class="nav-download">Download App</a>
            </nav>

            <button class="menu-btn" id="menuBtn" aria-label="Open menu">
                ☰
            </button>

        </div>
    </header>


    <!-- =========================
         HERO
    ========================== -->

    <main>

        <section class="hero">

            <div class="hero-container">

                <div class="hero-content reveal">

                    <div class="hero-badge">
                        <span class="badge-dot"></span>
                        Meet people. Connect. Earn.
                    </div>

                    <h1>
                        Meet new people.<br>
                        <span>Make Private Video Calls</span>
                    </h1>

                    <p class="hero-text">
                        MaskedParty makes it easy to discover interesting people,
                        make new friends and connect through private video calls.
                        Creators can turn their time and conversations into earnings.
                    </p>

                    <div class="hero-buttons">

                        <a href="https://github.com/devochoyo/maskedparty/releases/download/v1/maskedparty.apk"
                           class="btn btn-primary"
                           download="https://github.com/devochoyo/maskedparty/releases/download/v1/maskedparty.apk">
                            ↓ &nbsp; Download MaskedParty
                        </a>

                        <a href="#how-it-works"
                           class="btn btn-secondary">
                            How it works
                        </a>

                    </div>

                    <div class="hero-note">
                        Android app • Quick registration • Simple to use
                    </div>

                </div>


                <!-- APP MOCKUP -->

                <div class="hero-visual reveal">

                    <div class="floating-card floating-one">

                        <div class="float-icon">✦</div>

                        <div>
                            <div class="float-title">
                                New connections
                            </div>

                            <div class="float-text">
                                Discover people around you
                            </div>
                        </div>

                    </div>


                    <div class="phone-card">

                        <div class="phone-screen">

                            <div class="phone-top">

                                <div class="phone-brand">

                                    <img src="logo.png"
                                         class="mini-logo"
                                         alt="MaskedParty">

                                    <span>MaskedParty</span>

                                </div>

                                <div class="phone-icon">
                                    ♡
                                </div>

                            </div>


                            <div class="phone-title">
                                Discover<br>
                                new people.
                            </div>

                            <div class="phone-subtitle">
                                Find someone interesting and start a conversation.
                            </div>


                            <div class="profile-grid">

                                <div class="profile">

                                    <div class="profile-avatar"></div>

                                    <div class="profile-name">
                                        Discover
                                    </div>

                                    <div class="profile-location">
                                        New people
                                    </div>

                                    <div class="call-button">
                                        ☎
                                    </div>

                                </div>


                                <div class="profile">

                                    <div class="profile-avatar"></div>

                                    <div class="profile-name">
                                        Connect
                                    </div>

                                    <div class="profile-location">
                                        Make friends
                                    </div>

                                    <div class="call-button">
                                        ☎
                                    </div>

                                </div>


                                <div class="profile">

                                    <div class="profile-avatar"></div>

                                    <div class="profile-name">
                                        Chat
                                    </div>

                                    <div class="profile-location">
                                        Start talking
                                    </div>

                                    <div class="call-button">
                                        ☎
                                    </div>

                                </div>


                                <div class="profile">

                                    <div class="profile-avatar"></div>

                                    <div class="profile-name">
                                        Connect
                                    </div>

                                    <div class="profile-location">
                                        Meet someone
                                    </div>

                                    <div class="call-button">
                                        ☎
                                    </div>

                                </div>

                            </div>


                            <div class="earn-card">

                                <div class="earn-label">
                                    Creator earnings
                                </div>

                                <div class="earn-title">
                                    Earn from video calls
                                </div>

                                <div class="earn-row">

                                    <div class="earn-money">
                                        $0.00
                                    </div>

                                    <div class="earn-status">
                                        Your balance
                                    </div>

                                </div>

                            </div>

                        </div>

                    </div>


                    <div class="floating-card floating-two">

                        <div class="float-icon">$</div>

                        <div>
                            <div class="float-title">
                                Creator earnings
                            </div>

                            <div class="float-text">
                                Earn from eligible video calls
                            </div>
                        </div>

                    </div>

                </div>

            </div>

        </section>


        <!-- =========================
             TRUST BAR
        ========================== -->

        <div class="trust-bar">

            <div class="trust-inner">

                <div class="trust-item">
                    ✓ <strong>Meet new people</strong>
                </div>

                <div class="trust-item">
                    ✓ Private video calls
                </div>

                <div class="trust-item">
                    ✓ Creator opportunities
                </div>

                <div class="trust-item">
                    ✓ Simple experience
                </div>

            </div>

        </div>


        <!-- =========================
             FEATURES
        ========================== -->

        <section class="features" id="features">

            <div class="section-container">

                <div class="section-heading reveal">

                    <div class="eyebrow">
                        Why MaskedParty
                    </div>

                    <h2>
                        More than just another social app.
                    </h2>

                    <p>
                        MaskedParty is designed around genuine connections,
                        simple conversations and opportunities for creators
                        to earn through video calls.
                    </p>

                </div>


                <div class="feature-grid">

                    <div class="feature-card reveal">

                        <div class="feature-number">
                            01
                        </div>

                        <div class="feature-icon">
                            ◎
                        </div>

                        <h3>
                            Meet New People
                        </h3>

                        <p>
                            Discover interesting people and expand your social
                            circle through a simple and engaging experience.
                        </p>

                    </div>


                    <div class="feature-card reveal">

                        <div class="feature-number">
                            02
                        </div>

                        <div class="feature-icon">
                            ♡
                        </div>

                        <h3>
                            Make Connections
                        </h3>

                        <p>
                            Start conversations and build meaningful friendships
                            with people you enjoy talking to.
                        </p>

                    </div>


                    <div class="feature-card reveal">

                        <div class="feature-number">
                            03
                        </div>

                        <div class="feature-icon">
                            ◉
                        </div>

                        <h3>
                            Private Video Calls
                        </h3>

                        <p>
                            Connect face-to-face through private video calls
                            whenever you want to talk more personally.
                        </p>

                    </div>


                    <div class="feature-card reveal">

                        <div class="feature-number">
                            04
                        </div>

                        <div class="feature-icon">
                            $
                        </div>

                        <h3>
                            Earn as a Creator
                        </h3>

                        <p>
                            Eligible creators can earn through video calls
                            with users on the platform.
                        </p>

                    </div>


                    <div class="feature-card reveal">

                        <div class="feature-number">
                            05
                        </div>

                        <div class="feature-icon">
                            +
                        </div>

                        <h3>
                            Build Your Profile
                        </h3>

                        <p>
                            Create your profile, showcase your personality
                            and give people a reason to connect with you.
                        </p>

                    </div>


                    <div class="feature-card reveal">

                        <div class="feature-number">
                            06
                        </div>

                        <div class="feature-icon">
                            ✓
                        </div>

                        <h3>
                            Simple Experience
                        </h3>

                        <p>
                            Register, discover people, connect and start
                            conversations without unnecessary complexity.
                        </p>

                    </div>

                </div>

            </div>

        </section>


        <!-- =========================
             CREATOR SECTION
        ========================== -->

        <section class="creator-section" id="creators">

            <div class="section-container">

                <div class="creator-grid">

                    <div class="creator-content reveal">

                        <div class="eyebrow">
                            For Creators
                        </div>

                        <h2>
                            Turn conversations into opportunity.
                        </h2>

                        <p class="creator-description">
                            Want to become a creator on MaskedParty?
                            Build your profile, connect with users and
                            earn through eligible video calls.
                        </p>


                        <div class="creator-list">

                            <div class="creator-item">

                                <div class="creator-check">
                                    ✓
                                </div>

                                <div>
                                    <h4>
                                        Register as a creator
                                    </h4>

                                    <p>
                                        Set up your creator profile and get started.
                                    </p>
                                </div>

                            </div>


                            <div class="creator-item">

                                <div class="creator-check">
                                    ✓
                                </div>

                                <div>
                                    <h4>
                                        Connect with users
                                    </h4>

                                    <p>
                                        Meet people who want to talk and connect.
                                    </p>
                                </div>

                            </div>


                            <div class="creator-item">

                                <div class="creator-check">
                                    ✓
                                </div>

                                <div>
                                    <h4>
                                        Earn through video calls
                                    </h4>

                                    <p>
                                        Eligible calls can generate earnings for creators.
                                    </p>
                                </div>

                            </div>


                            <div class="creator-item">

                                <div class="creator-check">
                                    ✓
                                </div>

                                <div>
                                    <h4>
                                        Manage your earnings
                                    </h4>

                                    <p>
                                        Track your available balance inside the app.
                                    </p>
                                </div>

                            </div>

                        </div>

                    </div>


                    <div class="creator-visual reveal">

                        <div class="income-card">

                            <div class="income-top">
                                <span>CREATOR DASHBOARD</span>
                                <span>THIS MONTH</span>
                            </div>

                            <div class="income-amount">
                                $24,850
                            </div>

                            <div class="income-positive">
                                ↑ Your creator earnings
                            </div>

                            <div class="chart">

                                <div class="bar"></div>
                                <div class="bar"></div>
                                <div class="bar"></div>
                                <div class="bar"></div>
                                <div class="bar"></div>
                                <div class="bar"></div>
                                <div class="bar"></div>
                                <div class="bar"></div>

                            </div>

                            <div class="income-bottom">

                                <span>Mon</span>
                                <span>Tue</span>
                                <span>Wed</span>
                                <span>Thu</span>
                                <span>Fri</span>
                                <span>Sat</span>
                                <span>Sun</span>

                            </div>

                        </div>


                        <div class="earning-tag">

                            <strong>
                                Earn from video calls
                            </strong>

                            <span>
                                Connect • Talk • Earn
                            </span>

                        </div>

                    </div>

                </div>

            </div>

        </section>


        <!-- =========================
             HOW IT WORKS
        ========================== -->

        <section id="how-it-works">

            <div class="section-container">

                <div class="section-heading reveal">

                    <div class="eyebrow">
                        Simple to get started
                    </div>

                    <h2>
                        Your journey starts in minutes.
                    </h2>

                    <p>
                        Getting started with MaskedParty is simple.
                        Download the app and begin discovering a new
                        way to connect with people.
                    </p>

                </div>


                <div class="steps">

                    <div class="step reveal">

                        <div class="step-number">
                            01
                        </div>

                        <h3>
                            Download
                        </h3>

                        <p>
                            Download the MaskedParty Android application
                            directly from this page.
                        </p>

                    </div>


                    <div class="step reveal">

                        <div class="step-number">
                            02
                        </div>

                        <h3>
                            Register
                        </h3>

                        <p>
                            Create your account and set up your profile.
                            You can register as a user or creator.
                        </p>

                    </div>


                    <div class="step reveal">

                        <div class="step-number">
                            03
                        </div>

                        <h3>
                            Discover
                        </h3>

                        <p>
                            Explore profiles and discover people you
                            would like to meet and talk to.
                        </p>

                    </div>


                    <div class="step reveal">

                        <div class="step-number">
                            04
                        </div>

                        <h3>
                            Connect
                        </h3>

                        <p>
                            Start conversations and enjoy private
                            video calls with your connections.
                        </p>

                    </div>


                    <div class="step reveal">

                        <div class="step-number">
                            05
                        </div>

                        <h3>
                            Earn
                        </h3>

                        <p>
                            Creators can earn from eligible video calls
                            and manage their earnings in the app.
                        </p>

                    </div>

                </div>

            </div>

        </section>


        <!-- =========================
             DOWNLOAD CTA
        ========================== -->

        <section class="download-section" id="download">

            <div class="download-box reveal">

                <div class="download-content">

                    <img src="logo.png"
                         alt="MaskedParty Logo"
                         class="download-logo">

                    <div class="eyebrow">
                        Get started today
                    </div>

                    <h2>
                        Ready to meet<br>
                        someone new?
                    </h2>

                    <p>
                        Download MaskedParty, create your account and
                        start discovering new people. If you're a creator,
                        you can also explore opportunities to earn through
                        video calls.
                    </p>

                    <a href="https://github.com/devochoyo/maskedparty/releases/download/v1/maskedparty.apk"
                       class="btn btn-primary download-button"
                       download="https://github.com/devochoyo/maskedparty/releases/download/v1/maskedparty.apk"
                       id="downloadButton">
                        ↓ &nbsp; Download MaskedParty
                    </a>

                    <div class="hero-note">
                        Android application • MaskedParty.apk
                    </div>

                </div>

            </div>

        </section>

    </main>


    <!-- =========================
         FOOTER
    ========================== -->

    <footer>

        <div class="footer-inner">

            <div class="footer-top">

                <div class="footer-brand">

                    <a href="#" class="brand">

                        <img src="logo.png"
                             alt="MaskedParty Logo"
                             class="brand-logo">

                        <span>MaskedParty</span>

                    </a>

                    <p>
                        Meet new people, make real connections and
                        discover opportunities through private video calls.
                    </p>

                </div>


                <div class="footer-links">

                    <div class="footer-column">

                        <h4>
                            Explore
                        </h4>

                        <a href="#features">
                            Features
                        </a>

                        <a href="#creators">
                            For Creators
                        </a>

                        <a href="#how-it-works">
                            How It Works
                        </a>

                    </div>


                    <div class="footer-column">

                        <h4>
                            Get the App
                        </h4>

                        <a href="#download">
                            Download
                        </a>

                        <a href="#download">
                            Android App
                        </a>

                    </div>

                </div>

            </div>


            <div class="footer-bottom">

                <span>
                    © <span id="year"></span> MaskedParty. All rights reserved.
                </span>

                <span>
                    Connect. Discover. Earn.
                </span>

            </div>

        </div>

    </footer>


    <!-- =========================
         JAVASCRIPT
    ========================== -->

    <script>

        /* =========================
           NAVBAR SCROLL EFFECT
        ========================== */

        const navbar = document.getElementById("navbar");

        window.addEventListener("scroll", function () {

            if (window.scrollY > 40) {
                navbar.classList.add("scrolled");
            } else {
                navbar.classList.remove("scrolled");
            }

        });


        /* =========================
           MOBILE MENU
        ========================== */

        const menuBtn = document.getElementById("menuBtn");
        const navLinks = document.getElementById("navLinks");

        menuBtn.addEventListener("click", function () {

            navLinks.classList.toggle("active");

            if (navLinks.classList.contains("active")) {
                menuBtn.textContent = "×";
            } else {
                menuBtn.textContent = "☰";
            }

        });


        /* Close mobile menu after clicking a link */

        document.querySelectorAll(".nav-links a").forEach(function (link) {

            link.addEventListener("click", function () {

                navLinks.classList.remove("active");
                menuBtn.textContent = "☰";

            });

        });


        /* =========================
           SCROLL REVEAL
        ========================== */

        const revealElements =
            document.querySelectorAll(".reveal");

        const revealObserver =
            new IntersectionObserver(

                function (entries) {

                    entries.forEach(function (entry) {

                        if (entry.isIntersecting) {

                            entry.target.classList.add("visible");

                            revealObserver.unobserve(entry.target);

                        }

                    });

                },

                {
                    threshold: 0.12
                }

            );


        revealElements.forEach(function (element) {

            revealObserver.observe(element);

        });


        /* =========================
           DOWNLOAD BUTTON
        ========================== */

        const downloadButton =
            document.getElementById("downloadButton");

        downloadButton.addEventListener("click", function () {

            /*
             * The APK must be named:
             *
             * MaskedParty.apk
             *
             * and must be located in the same root folder
             * as this index.html file.
             */

            console.log("Starting MaskedParty APK download...");

        });


        /* =========================
           CURRENT YEAR
        ========================== */

        document.getElementById("year").textContent =
            new Date().getFullYear();


        /* =========================
           SMOOTH ANCHOR SCROLL
        ========================== */

        document.querySelectorAll('a[href^="#"]').forEach(function (anchor) {

            anchor.addEventListener("click", function (event) {

                const targetId =
                    this.getAttribute("href");

                if (targetId === "#") {
                    return;
                }

                const target =
                    document.querySelector(targetId);

                if (target) {

                    event.preventDefault();

                    const navbarHeight =
                        navbar.offsetHeight;

                    const targetPosition =
                        target.getBoundingClientRect().top +
                        window.pageYOffset -
                        navbarHeight -
                        15;

                    window.scrollTo({
                        top: targetPosition,
                        behavior: "smooth"
                    });

                }

            });

        });

    </script>

</body>
</html>