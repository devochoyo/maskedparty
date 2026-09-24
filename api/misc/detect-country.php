<?php
/**
 * FILE LOCATION: /api/misc/detect-country.php
 *
 * Public endpoint. Looks up the requester's country using the local
 * geoip.sqlite built by import_geoip.php — no external API, no rate limit.
 *
 * Response shape matches the rest of this API's envelope:
 *   { "success": true, "data": { "country_name": "...", "country_code": "..." } }
 */

header('Content-Type: application/json');

function sendError(string $message, int $status = 400): void {
    http_response_code($status);
    echo json_encode(['success' => false, 'message' => $message]);
    exit;
}

function sendSuccess($data, string $message = 'OK'): void {
    echo json_encode(['success' => true, 'message' => $message, 'data' => $data]);
    exit;
}

/**
 * Best-effort real client IP. If you're behind Cloudflare, nginx, or
 * another reverse proxy, REMOTE_ADDR will be the proxy's IP, not the
 * user's — Cloudflare uses CF-Connecting-IP; a bare reverse proxy
 * typically uses X-Forwarded-For. Check your host's setup if results
 * look wrong (e.g. everyone showing as the same country).
 */
function getClientIp(): string {
    $headerCandidates = ['HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR'];

    foreach ($headerCandidates as $header) {
        if (!empty($_SERVER[$header])) {
            $value = $_SERVER[$header];
            $parts = explode(',', $value);
            $ip = trim($parts[0]);
            if (filter_var($ip, FILTER_VALIDATE_IP)) {
                return $ip;
            }
        }
    }

    return '0.0.0.0';
}

// Full ISO 3166-1 alpha-2 -> English short country name table (249 entries).
$countryNames = [
    'AD' => 'Andorra',
    'AE' => 'United Arab Emirates',
    'AF' => 'Afghanistan',
    'AG' => 'Antigua and Barbuda',
    'AI' => 'Anguilla',
    'AL' => 'Albania',
    'AM' => 'Armenia',
    'AO' => 'Angola',
    'AQ' => 'Antarctica',
    'AR' => 'Argentina',
    'AS' => 'American Samoa',
    'AT' => 'Austria',
    'AU' => 'Australia',
    'AW' => 'Aruba',
    'AX' => 'Åland Islands',
    'AZ' => 'Azerbaijan',
    'BA' => 'Bosnia and Herzegovina',
    'BB' => 'Barbados',
    'BD' => 'Bangladesh',
    'BE' => 'Belgium',
    'BF' => 'Burkina Faso',
    'BG' => 'Bulgaria',
    'BH' => 'Bahrain',
    'BI' => 'Burundi',
    'BJ' => 'Benin',
    'BL' => 'Saint Barthélemy',
    'BM' => 'Bermuda',
    'BN' => 'Brunei Darussalam',
    'BO' => 'Bolivia, Plurinational State of',
    'BQ' => 'Bonaire, Sint Eustatius and Saba',
    'BR' => 'Brazil',
    'BS' => 'Bahamas',
    'BT' => 'Bhutan',
    'BV' => 'Bouvet Island',
    'BW' => 'Botswana',
    'BY' => 'Belarus',
    'BZ' => 'Belize',
    'CA' => 'Canada',
    'CC' => 'Cocos (Keeling) Islands',
    'CD' => 'Congo, The Democratic Republic of the',
    'CF' => 'Central African Republic',
    'CG' => 'Congo',
    'CH' => 'Switzerland',
    'CI' => 'Côte d\'Ivoire',
    'CK' => 'Cook Islands',
    'CL' => 'Chile',
    'CM' => 'Cameroon',
    'CN' => 'China',
    'CO' => 'Colombia',
    'CR' => 'Costa Rica',
    'CU' => 'Cuba',
    'CV' => 'Cabo Verde',
    'CW' => 'Curaçao',
    'CX' => 'Christmas Island',
    'CY' => 'Cyprus',
    'CZ' => 'Czechia',
    'DE' => 'Germany',
    'DJ' => 'Djibouti',
    'DK' => 'Denmark',
    'DM' => 'Dominica',
    'DO' => 'Dominican Republic',
    'DZ' => 'Algeria',
    'EC' => 'Ecuador',
    'EE' => 'Estonia',
    'EG' => 'Egypt',
    'EH' => 'Western Sahara',
    'ER' => 'Eritrea',
    'ES' => 'Spain',
    'ET' => 'Ethiopia',
    'FI' => 'Finland',
    'FJ' => 'Fiji',
    'FK' => 'Falkland Islands (Malvinas)',
    'FM' => 'Micronesia, Federated States of',
    'FO' => 'Faroe Islands',
    'FR' => 'France',
    'GA' => 'Gabon',
    'GB' => 'United Kingdom',
    'GD' => 'Grenada',
    'GE' => 'Georgia',
    'GF' => 'French Guiana',
    'GG' => 'Guernsey',
    'GH' => 'Ghana',
    'GI' => 'Gibraltar',
    'GL' => 'Greenland',
    'GM' => 'Gambia',
    'GN' => 'Guinea',
    'GP' => 'Guadeloupe',
    'GQ' => 'Equatorial Guinea',
    'GR' => 'Greece',
    'GS' => 'South Georgia and the South Sandwich Islands',
    'GT' => 'Guatemala',
    'GU' => 'Guam',
    'GW' => 'Guinea-Bissau',
    'GY' => 'Guyana',
    'HK' => 'Hong Kong',
    'HM' => 'Heard Island and McDonald Islands',
    'HN' => 'Honduras',
    'HR' => 'Croatia',
    'HT' => 'Haiti',
    'HU' => 'Hungary',
    'ID' => 'Indonesia',
    'IE' => 'Ireland',
    'IL' => 'Israel',
    'IM' => 'Isle of Man',
    'IN' => 'India',
    'IO' => 'British Indian Ocean Territory',
    'IQ' => 'Iraq',
    'IR' => 'Iran, Islamic Republic of',
    'IS' => 'Iceland',
    'IT' => 'Italy',
    'JE' => 'Jersey',
    'JM' => 'Jamaica',
    'JO' => 'Jordan',
    'JP' => 'Japan',
    'KE' => 'Kenya',
    'KG' => 'Kyrgyzstan',
    'KH' => 'Cambodia',
    'KI' => 'Kiribati',
    'KM' => 'Comoros',
    'KN' => 'Saint Kitts and Nevis',
    'KP' => 'Korea, Democratic People\'s Republic of',
    'KR' => 'Korea, Republic of',
    'KW' => 'Kuwait',
    'KY' => 'Cayman Islands',
    'KZ' => 'Kazakhstan',
    'LA' => 'Lao People\'s Democratic Republic',
    'LB' => 'Lebanon',
    'LC' => 'Saint Lucia',
    'LI' => 'Liechtenstein',
    'LK' => 'Sri Lanka',
    'LR' => 'Liberia',
    'LS' => 'Lesotho',
    'LT' => 'Lithuania',
    'LU' => 'Luxembourg',
    'LV' => 'Latvia',
    'LY' => 'Libya',
    'MA' => 'Morocco',
    'MC' => 'Monaco',
    'MD' => 'Moldova, Republic of',
    'ME' => 'Montenegro',
    'MF' => 'Saint Martin (French part)',
    'MG' => 'Madagascar',
    'MH' => 'Marshall Islands',
    'MK' => 'North Macedonia',
    'ML' => 'Mali',
    'MM' => 'Myanmar',
    'MN' => 'Mongolia',
    'MO' => 'Macao',
    'MP' => 'Northern Mariana Islands',
    'MQ' => 'Martinique',
    'MR' => 'Mauritania',
    'MS' => 'Montserrat',
    'MT' => 'Malta',
    'MU' => 'Mauritius',
    'MV' => 'Maldives',
    'MW' => 'Malawi',
    'MX' => 'Mexico',
    'MY' => 'Malaysia',
    'MZ' => 'Mozambique',
    'NA' => 'Namibia',
    'NC' => 'New Caledonia',
    'NE' => 'Niger',
    'NF' => 'Norfolk Island',
    'NG' => 'Nigeria',
    'NI' => 'Nicaragua',
    'NL' => 'Netherlands',
    'NO' => 'Norway',
    'NP' => 'Nepal',
    'NR' => 'Nauru',
    'NU' => 'Niue',
    'NZ' => 'New Zealand',
    'OM' => 'Oman',
    'PA' => 'Panama',
    'PE' => 'Peru',
    'PF' => 'French Polynesia',
    'PG' => 'Papua New Guinea',
    'PH' => 'Philippines',
    'PK' => 'Pakistan',
    'PL' => 'Poland',
    'PM' => 'Saint Pierre and Miquelon',
    'PN' => 'Pitcairn',
    'PR' => 'Puerto Rico',
    'PS' => 'Palestine, State of',
    'PT' => 'Portugal',
    'PW' => 'Palau',
    'PY' => 'Paraguay',
    'QA' => 'Qatar',
    'RE' => 'Réunion',
    'RO' => 'Romania',
    'RS' => 'Serbia',
    'RU' => 'Russian Federation',
    'RW' => 'Rwanda',
    'SA' => 'Saudi Arabia',
    'SB' => 'Solomon Islands',
    'SC' => 'Seychelles',
    'SD' => 'Sudan',
    'SE' => 'Sweden',
    'SG' => 'Singapore',
    'SH' => 'Saint Helena, Ascension and Tristan da Cunha',
    'SI' => 'Slovenia',
    'SJ' => 'Svalbard and Jan Mayen',
    'SK' => 'Slovakia',
    'SL' => 'Sierra Leone',
    'SM' => 'San Marino',
    'SN' => 'Senegal',
    'SO' => 'Somalia',
    'SR' => 'Suriname',
    'SS' => 'South Sudan',
    'ST' => 'Sao Tome and Principe',
    'SV' => 'El Salvador',
    'SX' => 'Sint Maarten (Dutch part)',
    'SY' => 'Syrian Arab Republic',
    'SZ' => 'Eswatini',
    'TC' => 'Turks and Caicos Islands',
    'TD' => 'Chad',
    'TF' => 'French Southern Territories',
    'TG' => 'Togo',
    'TH' => 'Thailand',
    'TJ' => 'Tajikistan',
    'TK' => 'Tokelau',
    'TL' => 'Timor-Leste',
    'TM' => 'Turkmenistan',
    'TN' => 'Tunisia',
    'TO' => 'Tonga',
    'TR' => 'Türkiye',
    'TT' => 'Trinidad and Tobago',
    'TV' => 'Tuvalu',
    'TW' => 'Taiwan, Province of China',
    'TZ' => 'Tanzania, United Republic of',
    'UA' => 'Ukraine',
    'UG' => 'Uganda',
    'UM' => 'United States Minor Outlying Islands',
    'US' => 'United States',
    'UY' => 'Uruguay',
    'UZ' => 'Uzbekistan',
    'VA' => 'Holy See (Vatican City State)',
    'VC' => 'Saint Vincent and the Grenadines',
    'VE' => 'Venezuela, Bolivarian Republic of',
    'VG' => 'Virgin Islands, British',
    'VI' => 'Virgin Islands, U.S.',
    'VN' => 'Viet Nam',
    'VU' => 'Vanuatu',
    'WF' => 'Wallis and Futuna',
    'WS' => 'Samoa',
    'YE' => 'Yemen',
    'YT' => 'Mayotte',
    'ZA' => 'South Africa',
    'ZM' => 'Zambia',
    'ZW' => 'Zimbabwe',
];

$ip = getClientIp();

if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
    sendError('IPv6 lookup not supported by this endpoint yet.', 501);
}

$ipLong = ip2long($ip);
if ($ipLong === false) {
    sendError('Could not parse client IP.', 400);
}
$ipUnsigned = sprintf('%u', $ipLong);

$dbPath = __DIR__ . '/geoip.sqlite';
if (!file_exists($dbPath)) {
    sendError('GeoIP database not found on server. Run import_geoip.php first.', 500);
}

try {
    $pdo = new PDO('sqlite:' . $dbPath);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $pdo->prepare(
        'SELECT country_code FROM ranges
         WHERE start_ip <= :ip AND end_ip >= :ip
         ORDER BY start_ip DESC
         LIMIT 1'
    );
    $stmt->execute([':ip' => $ipUnsigned]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        sendError('Country not found for this IP.', 404);
    }

    $code = $row['country_code'];
    sendSuccess([
        'country_code' => $code,
        'country_name' => $countryNames[$code] ?? $code,
        'ip' => $ip,
    ]);
} catch (Exception $e) {
    sendError('Lookup failed.', 500);
}