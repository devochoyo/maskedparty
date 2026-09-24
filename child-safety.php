
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Child Safety Standards | MaskedParty</title>

    <meta
        name="description"
        content="MaskedParty Child Safety Standards covering child sexual abuse and exploitation prevention, reporting, moderation, user safety, and cooperation with authorities."
    >

    <style>
        :root {
            --bg: #0b0b12;
            --card: #151520;
            --card-soft: #1b1b28;
            --text: #f5f5f7;
            --muted: #a7a7b5;
            --primary: #8b5cf6;
            --primary-hover: #7442df;
            --danger: #ef4444;
            --border: rgba(255, 255, 255, 0.09);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            font-family:
                Inter,
                -apple-system,
                BlinkMacSystemFont,
                "Segoe UI",
                Roboto,
                Helvetica,
                Arial,
                sans-serif;

            background:
                radial-gradient(
                    circle at top right,
                    rgba(139, 92, 246, 0.16),
                    transparent 35%
                ),
                var(--bg);

            color: var(--text);
            line-height: 1.75;
        }

        a {
            color: #bd9cff;
            text-decoration: none;
        }

        a:hover {
            text-decoration: underline;
        }

        .container {
            width: min(100% - 32px, 960px);
            margin: 0 auto;
        }

        header {
            padding: 70px 0 45px;
            border-bottom: 1px solid var(--border);
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 25px;
        }

        .logo {
            width: 48px;
            height: 48px;
            border-radius: 14px;

            display: flex;
            align-items: center;
            justify-content: center;

            background: linear-gradient(
                135deg,
                #8b5cf6,
                #ec4899
            );

            color: #fff;
            font-size: 21px;
            font-weight: 800;

            box-shadow:
                0 10px 30px rgba(139, 92, 246, 0.3);
        }

        .brand-name {
            font-size: 19px;
            font-weight: 700;
        }

        h1 {
            font-size: clamp(34px, 6vw, 54px);
            line-height: 1.1;
            letter-spacing: -1.5px;
            margin-bottom: 18px;
        }

        .intro {
            max-width: 780px;
            color: var(--muted);
            font-size: 17px;
        }

        .meta {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 25px;
        }

        .meta span {
            padding: 7px 13px;
            border-radius: 999px;
            border: 1px solid var(--border);
            background: var(--card);
            color: var(--muted);
            font-size: 13px;
        }

        main {
            padding: 45px 0 75px;
        }

        .notice {
            padding: 24px;
            margin-bottom: 40px;

            border: 1px solid rgba(239, 68, 68, 0.28);
            border-radius: 18px;

            background: rgba(239, 68, 68, 0.07);
        }

        .notice strong {
            display: block;
            margin-bottom: 8px;
            color: #fff;
            font-size: 17px;
        }

        .notice p {
            color: #d5d5dc;
        }

        .toc {
            padding: 24px;
            margin-bottom: 45px;

            border: 1px solid var(--border);
            border-radius: 18px;

            background: var(--card);
        }

        .toc-title {
            font-weight: 700;
            margin-bottom: 12px;
        }

        .toc ol {
            padding-left: 22px;
        }

        .toc li {
            margin: 5px 0;
            color: var(--muted);
        }

        section {
            margin-bottom: 45px;
            scroll-margin-top: 20px;
        }

        h2 {
            font-size: 26px;
            line-height: 1.3;
            margin-bottom: 15px;
            letter-spacing: -0.4px;
        }

        h3 {
            font-size: 18px;
            margin: 25px 0 10px;
        }

        p {
            color: #d2d2da;
            margin-bottom: 15px;
        }

        ul {
            padding-left: 25px;
            margin: 12px 0 18px;
        }

        li {
            color: #d2d2da;
            margin: 7px 0;
        }

        .card {
            padding: 23px;
            margin: 20px 0;

            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 18px;
        }

        .card strong {
            color: #fff;
        }

        .contact {
            padding: 28px;
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 20px;
        }

        .contact-email {
            display: inline-block;
            margin-top: 8px;
            font-size: 17px;
            font-weight: 700;
            color: #bd9cff;
        }

        footer {
            border-top: 1px solid var(--border);
            padding: 30px 0 45px;
            color: var(--muted);
            font-size: 13px;
        }

        .footer-inner {
            display: flex;
            justify-content: space-between;
            gap: 15px;
            flex-wrap: wrap;
        }

        @media (max-width: 640px) {
            .container {
                width: min(100% - 24px, 960px);
            }

            header {
                padding: 48px 0 35px;
            }

            h1 {
                font-size: 35px;
            }

            h2 {
                font-size: 23px;
            }
        }
    </style>
</head>

<body>

<header>
    <div class="container">

        <div class="brand">
            <div class="logo">M</div>
            <div class="brand-name">
                MaskedParty – Live Chat & Call
            </div>
        </div>

        <h1>Child Safety Standards</h1>

        <p class="intro">
            MaskedParty is committed to protecting children and preventing
            child sexual abuse and exploitation (CSAE) across the platform.
            These standards describe MaskedParty's approach to preventing,
            detecting, reporting, and responding to child sexual exploitation
            and child sexual abuse material (CSAM).
        </p>

        <div class="meta">
            <span>Effective: August 26, 2026</span>
            <span>Last Updated: August 26, 2026</span>
        </div>

    </div>
</header>


<main>
    <div class="container">

        <div class="notice">
            <strong>Zero tolerance for child sexual exploitation</strong>

            <p>
                MaskedParty has zero tolerance for child sexual abuse,
                child sexual exploitation, grooming, sexualization of minors,
                or the creation, distribution, solicitation, possession, or
                promotion of child sexual abuse material.
            </p>
        </div>


        <nav class="toc">
            <div class="toc-title">
                Child Safety Standards
            </div>

            <ol>
                <li>
                    <a href="#scope">
                        Scope of These Standards
                    </a>
                </li>

                <li>
                    <a href="#prohibited">
                        Prohibited Child Sexual Exploitation
                    </a>
                </li>

                <li>
                    <a href="#age">
                        Age Safety
                    </a>
                </li>

                <li>
                    <a href="#reporting">
                        Reporting Child Safety Concerns
                    </a>
                </li>

                <li>
                    <a href="#moderation">
                        Detection and Moderation
                    </a>
                </li>

                <li>
                    <a href="#enforcement">
                        Enforcement
                    </a>
                </li>

                <li>
                    <a href="#authorities">
                        Cooperation With Authorities
                    </a>
                </li>

                <li>
                    <a href="#contact">
                        Child Safety Contact
                    </a>
                </li>
            </ol>
        </nav>


        <section id="scope">
            <h2>1. Scope of These Standards</h2>

            <p>
                These Child Safety Standards apply to MaskedParty – Live Chat
                & Call and the social communication features provided through
                the service.
            </p>

            <p>
                MaskedParty provides features that may allow users to create
                profiles, communicate through messages, and participate in
                voice or video calls. Because these features can facilitate
                interaction between users, MaskedParty takes child safety
                seriously and maintains safeguards designed to prevent
                exploitation and abuse.
            </p>
        </section>


        <section id="prohibited">
            <h2>2. Prohibited Child Sexual Exploitation</h2>

            <p>
                MaskedParty strictly prohibits any activity involving the
                sexual exploitation or abuse of children.
            </p>

            <p>
                The following activities are prohibited:
            </p>

            <ul>
                <li>
                    Creating, uploading, requesting, sharing, distributing,
                    storing, or promoting child sexual abuse material (CSAM).
                </li>

                <li>
                    Sexual content involving minors.
                </li>

                <li>
                    Sexual solicitation or sexual communication involving
                    minors.
                </li>

                <li>
                    Grooming or attempting to groom a child for sexual
                    purposes.
                </li>

                <li>
                    Encouraging or facilitating the sexual exploitation of
                    children.
                </li>

                <li>
                    Attempting to obtain sexual images or videos from a minor.
                </li>

                <li>
                    Using MaskedParty to arrange sexual contact with a child.
                </li>

                <li>
                    Promoting, requesting, trading, selling, or distributing
                    CSAM.
                </li>

                <li>
                    Attempting to evade MaskedParty safety systems or account
                    restrictions for the purpose of exploiting children.
                </li>
            </ul>

            <p>
                Any account reasonably believed to be involved in child sexual
                exploitation may be immediately restricted, suspended, or
                permanently removed.
            </p>
        </section>


        <section id="age">
            <h2>3. Age Safety</h2>

            <p>
                MaskedParty is not intended for children who are below the
                minimum age permitted to use the service under applicable law.
            </p>

            <p>
                Users must provide truthful information when creating an
                account and must not misrepresent their age for the purpose of
                accessing the service.
            </p>

            <p>
                MaskedParty may take action when an account is reasonably
                suspected of belonging to a child who is below the permitted
                age or when an account is being used to facilitate the
                exploitation of a child.
            </p>

            <p>
                If you believe a child is using MaskedParty in violation of
                the applicable age requirements, or if you believe a child
                may be at risk, report the concern immediately through the
                available in-app reporting tools or by contacting the
                designated child safety contact.
            </p>
        </section>


        <section id="reporting">
            <h2>4. Reporting Child Safety Concerns</h2>

            <p>
                MaskedParty provides in-app mechanisms that allow users to
                report accounts, content, messages, or behavior that may
                violate child safety standards.
            </p>

            <p>
                Users should report suspected child sexual exploitation,
                grooming, sexual solicitation involving minors, CSAM, or any
                other child safety concern as soon as possible.
            </p>

            <div class="card">
                <strong>
                    If you encounter suspected child sexual exploitation:
                </strong>

                <ul>
                    <li>
                        Use the reporting function available inside the
                        MaskedParty application.
                    </li>

                    <li>
                        Provide enough information for the safety team to
                        identify the account or activity.
                    </li>

                    <li>
                        Do not download, save, forward, or redistribute
                        suspected CSAM.
                    </li>

                    <li>
                        Contact MaskedParty's designated child safety contact
                        when additional assistance is required.
                    </li>
                </ul>
            </div>

            <p>
                Reports are reviewed and handled according to the seriousness
                of the reported conduct and applicable legal requirements.
            </p>
        </section>


        <section id="moderation">
            <h2>5. Detection and Moderation</h2>

            <p>
                MaskedParty uses a combination of safety processes, user
                reports, technical controls, account information, and
                moderation procedures to identify and respond to potentially
                harmful activity.
            </p>

            <p>
                Safety measures may include:
            </p>

            <ul>
                <li>
                    User reporting mechanisms.
                </li>

                <li>
                    Account restrictions and suspension systems.
                </li>

                <li>
                    Spam and abuse detection.
                </li>

                <li>
                    Security monitoring.
                </li>

                <li>
                    Investigation of reported accounts and behavior.
                </li>

                <li>
                    Review of information necessary to investigate safety
                    reports.
                </li>

                <li>
                    Technical controls designed to identify suspicious or
                    abusive account activity.
                </li>
            </ul>

            <p>
                MaskedParty may preserve relevant information when reasonably
                necessary to investigate serious safety incidents, prevent
                repeated abuse, comply with legal obligations, or cooperate
                with lawful investigations.
            </p>
        </section>


        <section id="enforcement">
            <h2>6. Enforcement</h2>

            <p>
                MaskedParty takes reports of child sexual exploitation
                seriously.
            </p>

            <p>
                Depending on the circumstances, enforcement actions may
                include:
            </p>

            <ul>
                <li>
                    Removing prohibited content.
                </li>

                <li>
                    Restricting an account.
                </li>

                <li>
                    Suspending an account.
                </li>

                <li>
                    Permanently terminating an account.
                </li>

                <li>
                    Blocking attempts to create additional abusive accounts.
                </li>

                <li>
                    Preserving relevant information for investigation or legal
                    compliance.
                </li>

                <li>
                    Reporting suspected CSAM or child sexual exploitation to
                    appropriate authorities or reporting organizations where
                    required or appropriate.
                </li>
            </ul>

            <p>
                MaskedParty does not permit users to use the platform to
                facilitate child sexual exploitation, regardless of whether
                the activity occurs through profiles, messages, calls, or
                other communication features.
            </p>
        </section>


        <section id="authorities">
            <h2>7. Cooperation With Authorities</h2>

            <p>
                MaskedParty complies with applicable child safety and
                reporting laws and cooperates with appropriate authorities
                when legally required or otherwise appropriate.
            </p>

            <p>
                Where required by applicable law, MaskedParty may report
                suspected child sexual abuse material, child sexual
                exploitation, or other serious child safety incidents to
                relevant national or regional authorities and appropriate
                reporting organizations.
            </p>

            <p>
                MaskedParty may provide relevant information in response to
                valid legal requests or where disclosure is necessary to
                protect children, users, or the safety of the platform.
            </p>

            <p>
                Information is handled in accordance with applicable privacy
                and data-protection requirements.
            </p>
        </section>


        <section id="contact">
            <h2>8. Child Safety Contact</h2>

            <p>
                MaskedParty has designated a contact for child safety and
                CSAM-related matters.
            </p>

            <div class="contact">

                <strong>
                    MaskedParty – Live Chat & Call
                </strong>

                <p>
                    Child Safety and CSAM Prevention Contact
                </p>

                <a
                    class="contact-email"
                    href="mailto:sirdrey19@gmail.com"
                >
                    sirdrey19@gmail.com
                </a>

                <p style="margin-top: 15px;">
                    This contact is intended for child safety concerns,
                    suspected CSAM, child sexual exploitation reports,
                    questions regarding MaskedParty's child safety practices,
                    and related compliance matters.
                </p>

            </div>
        </section>


        <section>
            <h2>9. Commitment to Child Safety</h2>

            <p>
                MaskedParty is committed to maintaining a safer social
                environment and preventing the platform from being used to
                exploit or harm children.
            </p>

            <p>
                MaskedParty will continue to review its safety practices and
                make reasonable improvements to its reporting, moderation,
                security, and enforcement processes as the service develops
                and applicable requirements change.
            </p>
        </section>


    </div>
</main>


<footer>
    <div class="container">

        <div class="footer-inner">

            <div>
                © 2026 MaskedParty – Live Chat & Call
            </div>

            <div>
                Child Safety Standards · Updated August 26, 2026
            </div>

        </div>

    </div>
</footer>

</body>
</html>
```
