// FILE LOCATION: lib/screens/shared/privacy.dart
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Responsive sizing for compact Android widths, matching the existing screen pattern.
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.6,
      color: Colors.grey[800],
    );
    final headerStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: const Color(0xFF1A1D2E),
    );
    final subHeaderStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1A1D2E),
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: isSmallScreen
            ? const TextScaler.linear(0.92)
            : MediaQuery.of(context).textScaler,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          visualDensity: isSmallScreen
              ? VisualDensity.compact
              : Theme.of(context).visualDensity,
        ),
        child: Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PRIVACY POLICY', style: headerStyle),
            const SizedBox(height: 8),
            Text('Last updated: July 28, 2026', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 24),
            
            _buildSection('1. INTRODUCTION', 
              'Welcome to MaskedParty. We are committed to protecting your privacy and ensuring you have a safe and enjoyable experience on our mobile application. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use MaskedParty.\n\n'
              'By downloading, accessing, or using MaskedParty, you agree to the collection and use of information in accordance with this policy. If you do not agree with the terms of this Privacy Policy, please do not use the App.',
              subHeaderStyle, textStyle),
            
            _buildSection('2. INFORMATION WE COLLECT',
              'We collect several types of information to provide, improve, and protect our services.',
              subHeaderStyle, textStyle),
            
            _buildSubSection('A. Information You Provide Directly',
              'When you create an account, update your profile, or interact with other users, we collect:\n\n'
              '• Username – your chosen display name in the app.\n'
              '• Email Address – used for account creation, login, and communications.\n'
              '• Profile Picture – you may optionally upload a photo to personalize your profile. We store this image and display it to other users according to your privacy settings.\n'
              '• Any other information you voluntarily provide, such as bio, interests, or preferences.',
              textStyle),
            
            _buildSubSection('B. Information Collected Automatically',
              'When you use the App, we automatically collect:\n\n'
              '• Device Information – including IP address, device model, operating system version, unique device identifiers, and mobile network information.\n'
              '• Usage Data – information about how you navigate and interact with the App, such as features used, time spent, session frequency, and interactions with other users.\n'
              '• Location Data – we may collect general location based on your IP address. We will only collect precise geolocation data if you explicitly grant permission.',
              textStyle),
            
            _buildSubSection('C. Information from Third Parties',
              'If you sign in through a third-party service such as Google or Apple, we may receive basic profile information including your email and name from that service, subject to your privacy settings with that provider.',
              textStyle),
            
            const SizedBox(height: 16),
            
            _buildSection('3. HOW WE USE YOUR INFORMATION',
              'We use the information we collect for the following purposes:\n\n'
              '• To create and manage your account.\n'
              '• To provide, maintain, and improve MaskedParty features and functionality.\n'
              '• To personalize your experience, including displaying your profile picture and username.\n'
              '• To communicate with you including sending account updates, security alerts, and promotional messages where permitted.\n'
              '• To monitor and analyze usage trends to enhance user experience.\n'
              '• To detect, prevent, and address technical issues, fraud, or security breaches.\n'
              '• To enforce our Terms of Service and community guidelines.',
              subHeaderStyle, textStyle),
            
            _buildSection('4. HOW WE SHARE YOUR INFORMATION',
              'We do not sell, rent, or trade your personal information. We share your data only in the following limited circumstances:',
              subHeaderStyle, textStyle),
            
            _buildSubSection('A. With Service Providers',
              'We share your information with trusted third-party vendors who perform services on our behalf, including:\n\n'
              '• Cloud hosting and data storage providers.\n'
              '• Analytics services to help us understand app usage.\n'
              '• Customer support and communication platforms.\n\n'
              'These providers are contractually obligated to protect your data and use it only for the services they perform for us.',
              textStyle),
            
            _buildSubSection('B. For Legal Reasons',
              'We disclose your information if required to do so by law or in response to valid requests by public authorities including court orders, subpoenas, or government investigations.',
              textStyle),
            
            _buildSubSection('C. In Connection with Business Transfers',
              'If MaskedParty is involved in a merger, acquisition, or asset sale, your personal information may be transferred. We will notify you before your data is transferred and becomes subject to a different privacy policy.',
              textStyle),
            
            _buildSubSection('D. With Your Consent',
              'We share your information for any other purpose with your explicit consent.',
              textStyle),
            
            const SizedBox(height: 16),
            
            _buildSection('5. PUBLICLY VISIBLE INFORMATION',
              'Your username and profile picture are visible to other users of MaskedParty. Any content you post, messages you send, or interactions you engage in may also be visible to other users depending on the app\'s features. Please be mindful of what you share publicly.',
              subHeaderStyle, textStyle),
            
            _buildSection('6. DATA RETENTION',
              'We retain your personal information only for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law. You may request deletion of your account and associated data at any time.',
              subHeaderStyle, textStyle),
            
            _buildSection('7. DATA SECURITY',
              'We implement appropriate technical and organizational measures to protect your information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet or electronic storage is completely secure. While we strive to protect your data, we cannot guarantee absolute security.',
              subHeaderStyle, textStyle),
            
            _buildSection('8. YOUR RIGHTS AND CHOICES',
              'Depending on your location, you may have the following rights regarding your personal information:\n\n'
              '• Access – request a copy of the data we hold about you.\n'
              '• Correction – update or correct inaccurate information.\n'
              '• Deletion – request deletion of your account and personal data.\n'
              '• Opt-out – withdraw consent for certain data processing including marketing emails.\n'
              '• Data Portability – request a machine-readable copy of your data.\n\n'
              'To exercise these rights, contact us at support@maskedparty.com. We will respond within the timeframes required by applicable law.',
              subHeaderStyle, textStyle),
            
            _buildSection('9. CHILDREN\'S PRIVACY',
              'MaskedParty is not intended for children under the age of 13. We do not knowingly collect personal information from children. If we become aware that we have inadvertently collected such data, we will take steps to delete it promptly. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
              subHeaderStyle, textStyle),
            
            _buildSection('10. INTERNATIONAL DATA TRANSFERS',
              'If you are located outside the country where our servers are hosted, your information may be transferred across international borders. By using MaskedParty, you consent to such transfers, provided they comply with applicable data protection laws.',
              subHeaderStyle, textStyle),
            
            _buildSection('11. THIRD-PARTY LINKS AND SERVICES',
              'The App may contain links to third-party websites or services that are not owned or controlled by us. This Privacy Policy does not apply to those third parties. We recommend reviewing their privacy policies before interacting with them.',
              subHeaderStyle, textStyle),
            
            _buildSection('12. CHANGES TO THIS PRIVACY POLICY',
              'We may update this Privacy Policy from time to time. We will notify you of any material changes by:\n\n'
              '• Posting the updated policy within the App.\n'
              '• Updating the "Last updated" date at the top of this page.\n'
              '• Sending you an email notification where feasible.\n\n'
              'Your continued use of MaskedParty after any changes constitutes your acceptance of the revised policy.',
              subHeaderStyle, textStyle),
            
            _buildSection('13. CONTACT US',
              'If you have any questions, concerns, or requests regarding this Privacy Policy, please contact us at:\n\n'
              'Email: support@maskedparty.com\n'
              'App Name: MaskedParty',
              subHeaderStyle, textStyle),
            
            const SizedBox(height: 40),
            
            Text('DISCLAIMERS', style: headerStyle),
            const SizedBox(height: 20),
            
            _buildSection('1. GENERAL DISCLAIMER',
              'The content, features, and services provided through MaskedParty are for general informational and entertainment purposes only. While we strive to ensure the App operates smoothly and accurately, we make no representations or warranties of any kind, express or implied, about the completeness, accuracy, reliability, suitability, or availability of the App or the information, products, services, or related graphics contained in the App.\n\n'
              'Your use of MaskedParty is at your sole risk. We are not liable for any loss or damage, including but not limited to indirect or consequential loss, arising from your use of the App or reliance on any content provided.',
              subHeaderStyle, textStyle),
            
            _buildSection('2. USER-GENERATED CONTENT DISCLAIMER',
              'MaskedParty allows users to create, post, and interact with content generated by other members of the community. We do not endorse, verify, or guarantee the accuracy, completeness, or reliability of any user-generated content.\n\n'
              'The views and opinions expressed by users are their own and do not necessarily reflect the views of MaskedParty or its operators. We are not responsible for any interactions, disputes, or outcomes arising from user-generated content or communications between users.\n\n'
              'You are solely responsible for your own content and your interactions with others on the platform.',
              subHeaderStyle, textStyle),
            
            _buildSection('3. USE AT YOUR OWN RISK DISCLAIMER',
              'Your interactions with other users on MaskedParty are solely at your own risk. We do not conduct background checks on users and cannot guarantee the identity, intentions, or conduct of any individual you may encounter.\n\n'
              'We encourage you to:\n'
              '• Exercise caution and common sense when sharing personal information.\n'
              '• Report any suspicious or inappropriate behavior to us.\n'
              '• Never share sensitive personal data such as financial information, home address, or passwords with other users.\n\n'
              'We are not liable for any harm, damages, or losses resulting from your interactions with other users.',
              subHeaderStyle, textStyle),
            
            _buildSection('4. NO PROFESSIONAL ADVICE DISCLAIMER',
              'The information provided on MaskedParty is not intended as professional advice of any kind, including but not limited to medical, legal, financial, psychological, or relationship advice.\n\n'
              'You should not rely on any information or content within the App as a substitute for professional consultation. If you require expert advice, please seek the services of a qualified professional in the relevant field.',
              subHeaderStyle, textStyle),
            
            _buildSection('5. THIRD-PARTY LINKS AND ADVERTISING DISCLAIMER',
              'MaskedParty may contain links to third-party websites, services, or advertisements. These links are provided for your convenience and do not signify our endorsement of the content, products, or services offered by those third parties.\n\n'
              'We have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party sites or services. Your interactions with third parties are governed by their own terms and policies.',
              subHeaderStyle, textStyle),
            
            _buildSection('6. NO WARRANTY AND LIMITATION OF LIABILITY',
              'MaskedParty is provided on an "as is" and "as available" basis without any warranties of any kind, either express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, non-infringement, or uninterrupted availability.\n\n'
              'To the fullest extent permitted by applicable law:\n'
              '• We do not warrant that the App will function uninterrupted, be secure, or be error-free.\n'
              '• We are not liable for any direct, indirect, incidental, special, punitive, or consequential damages arising from your use of or inability to use the App, including but not limited to loss of data, profits, or goodwill.\n\n'
              'Some jurisdictions do not allow the exclusion of certain warranties or limitations of liability, so the above limitations may not apply to you.',
              subHeaderStyle, textStyle),
            
            _buildSection('7. FORCE MAJEURE',
              'We are not liable for any failure or delay in performing our obligations under this Disclaimer or our Terms of Service if such failure or delay is caused by events beyond our reasonable control, including but not limited to natural disasters, internet outages, government actions, or cyberattacks.',
              subHeaderStyle, textStyle),
            
            _buildSection('8. CHANGES TO DISCLAIMERS',
              'We reserve the right to update or modify these disclaimers at any time without prior notice. Any changes will be effective immediately upon posting within the App or on our website. Your continued use of MaskedParty constitutes acceptance of the updated disclaimers.',
              subHeaderStyle, textStyle),
            
            _buildSection('9. CONTACT US',
              'For questions about these disclaimers, please reach out to:\n\n'
              'Email: support@maskedparty.com\n'
              'App Name: MaskedParty',
              subHeaderStyle, textStyle),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
      ),
    );
  }

  Widget _buildSection(String title, String content, TextStyle? titleStyle, TextStyle? bodyStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 8),
          Text(content, style: bodyStyle),
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, String content, TextStyle? bodyStyle) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: bodyStyle?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(content, style: bodyStyle),
        ],
      ),
    );
  }
}