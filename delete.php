<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Delete MaskedParty Account</title>

    <meta
        name="description"
        content="Request deletion of your MaskedParty – Live Chat & Call account."
    >

    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        :root {
            --background: #0b0b12;
            --card: #151520;
            --border: rgba(255, 255, 255, 0.08);
            --text: #ffffff;
            --muted: #a7a7b5;
            --primary: #8b5cf6;
            --primary-hover: #7442df;
        }

        body {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;

            font-family:
                Inter,
                -apple-system,
                BlinkMacSystemFont,
                "Segoe UI",
                Roboto,
                Arial,
                sans-serif;

            background:
                radial-gradient(
                    circle at top right,
                    rgba(139, 92, 246, 0.18),
                    transparent 40%
                ),
                var(--background);

            color: var(--text);
        }

        .container {
            width: 100%;
            max-width: 560px;
        }

        .card {
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 24px;
            padding: 40px 32px;
            text-align: center;
            box-shadow:
                0 20px 60px rgba(0, 0, 0, 0.35);
        }

        .logo {
            width: 72px;
            height: 72px;
            margin: 0 auto 24px;

            display: flex;
            align-items: center;
            justify-content: center;

            border-radius: 20px;

            background: linear-gradient(
                135deg,
                #8b5cf6,
                #ec4899
            );

            color: #ffffff;
            font-size: 30px;
            font-weight: 800;

            box-shadow:
                0 12px 35px rgba(139, 92, 246, 0.3);
        }

        h1 {
            font-size: 30px;
            line-height: 1.2;
            margin-bottom: 14px;
        }

        .subtitle {
            color: var(--muted);
            font-size: 16px;
            line-height: 1.7;
            margin-bottom: 28px;
        }

        .info {
            text-align: left;
            padding: 20px;
            margin-bottom: 28px;

            border: 1px solid var(--border);
            border-radius: 16px;

            background: rgba(255, 255, 255, 0.025);
        }

        .info h2 {
            font-size: 17px;
            margin-bottom: 10px;
        }

        .info p {
            color: var(--muted);
            font-size: 14px;
            line-height: 1.7;
        }

        .delete-button {
            display: inline-flex;
            align-items: center;
            justify-content: center;

            width: 100%;
            min-height: 52px;

            padding: 14px 22px;

            background: var(--primary);
            color: #ffffff;

            border-radius: 12px;

            font-size: 16px;
            font-weight: 700;

            text-decoration: none;

            transition:
                background 0.2s ease,
                transform 0.2s ease,
                box-shadow 0.2s ease;

            box-shadow:
                0 10px 25px rgba(139, 92, 246, 0.25);
        }

        .delete-button:hover {
            background: var(--primary-hover);
            transform: translateY(-1px);
            text-decoration: none;
            box-shadow:
                0 14px 30px rgba(139, 92, 246, 0.35);
        }

        .delete-button:active {
            transform: translateY(0);
        }

        .email {
            margin-top: 18px;
            color: var(--muted);
            font-size: 13px;
            line-height: 1.6;
        }

        .email a {
            color: #b794ff;
            text-decoration: none;
        }

        .email a:hover {
            text-decoration: underline;
        }

        footer {
            margin-top: 28px;
            color: #777786;
            font-size: 12px;
            text-align: center;
        }

        @media (max-width: 480px) {
            body {
                padding: 16px;
            }

            .card {
                padding: 32px 22px;
                border-radius: 20px;
            }

            h1 {
                font-size: 26px;
            }

            .logo {
                width: 64px;
                height: 64px;
                font-size: 26px;
            }
        }
    </style>
</head>

<body>

    <main class="container">

        <div class="card">

            <div class="logo">
                M
            </div>

            <h1>Delete Your MaskedParty Account</h1>

            <p class="subtitle">
                Request the deletion of your MaskedParty – Live Chat & Call
                account and associated account information.
            </p>

            <div class="info">

                <h2>Before you continue</h2>

                <p>
                    Account deletion may permanently remove your MaskedParty
                    profile, account information, messages, connections, and
                    other data associated with your account.
                </p>

                <br>

                <p>
                    Some information may be retained where necessary for
                    security, fraud prevention, spam prevention, legal
                    compliance, or other legitimate purposes described in the
                    MaskedParty Privacy Policy.
                </p>

            </div>

            <a
                class="delete-button"
                href="mailto:careerkingsconsult@gmail.com?subject=Help%20me%20delete%20my%20account&body=Hi%2C%20I%27m%20requesting%20for%20my%20account%20to%20be%20deleted%20from%20the%20MaskedParty%20app."
            >
                Request Account Deletion
            </a>

            <p class="email">
                Your email application will open with a pre-filled
                account-deletion request.
            </p>

            <p class="email">
                Direct email:
                <a href="mailto:careerkingsconsult@gmail.com">
                    careerkingsconsult@gmail.com
                </a>
            </p>

        </div>

        <footer>
            © 2026 MaskedParty – Live Chat & Call
        </footer>

    </main>

</body>
</html>