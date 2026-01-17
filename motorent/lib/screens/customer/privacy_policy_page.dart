// FILE: motorent/lib/screens/customer/privacy_policy_page.dart

import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildLastUpdated(),
          const SizedBox(height: 24),
          _buildSection(
            title: '1. Introduction',
            content: '''MotoRent Sdn. Bhd. ("we", "our", "us") is committed to protecting your privacy and personal data in accordance with the Personal Data Protection Act 2010 (PDPA) of Malaysia and regulations issued by the Malaysian Communications and Multimedia Commission (MCMC).

This Privacy Policy explains how we collect, use, disclose, and protect your personal information when you use our vehicle rental platform and services.

By using MotoRent, you agree to the collection and use of information in accordance with this policy.''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '2. Data Controller Information',
            content: '''MotoRent Sdn. Bhd.
Company Registration No: 202401234567 (1234567-X)
Address: Level 12, Menara MotoRent, Jalan Ampang, 50450 Kuala Lumpur, Malaysia
Email: privacy@motorent.com
Phone: +60 3-1234 5678

Data Protection Officer:
Name: Ahmad bin Abdullah
Email: dpo@motorent.com
Phone: +60 3-1234 5679''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '3. Personal Data We Collect',
            content: '''Under the PDPA 2010, we collect the following categories of personal data:

3.1 Identity Information:
• Full name (as per NRIC/Passport)
• NRIC number or Passport number
• Date of birth
• Nationality
• Profile photograph

3.2 Contact Information:
• Mobile phone number
• Email address
• Residential address
• Correspondence address

3.3 Financial Information:
• Credit/debit card details (tokenized)
• Banking information for refunds
• Transaction history
• Payment receipts

3.4 Driver's Information:
• Malaysian Driver's License number and class
• License validity period
• Driving record (if voluntarily provided)
• Previous rental history

3.5 Technical Information:
• IP address
• Device information (model, OS, unique identifiers)
• Browser type and version
• Location data (GPS coordinates when app is active)
• Usage data and app analytics

3.6 Special Categories (with explicit consent):
• Biometric data for identity verification (optional)
• Health information (only for insurance claims if needed)''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '4. How We Collect Your Data',
            content: '''We collect personal data through:

• Direct interactions: When you create an account, make bookings, or contact us
• Automated technologies: Cookies, GPS, and app analytics
• Third parties: Payment processors, identity verification services
• Public sources: Companies Commission of Malaysia (SSM) for business verification
• Vehicle owners: Information shared when listing vehicles''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '5. Legal Basis and Purpose of Processing',
            content: '''Under PDPA 2010, we process your data for the following lawful purposes:

5.1 Contract Performance:
• Process and manage vehicle rentals
• Verify your identity and eligibility to rent
• Facilitate payment transactions
• Provide customer support

5.2 Legal Obligations:
• Comply with Road Transport Act 1987
• Fulfill tax obligations under Income Tax Act 1967
• Comply with Anti-Money Laundering, Anti-Terrorism Financing and Proceeds of Unlawful Activities Act 2001 (AMLA)
• Meet MCMC regulatory requirements

5.3 Legitimate Interests:
• Prevent fraud and ensure platform security
• Improve our services and user experience
• Send service-related notifications
• Resolve disputes

5.4 Consent:
• Marketing communications
• Location tracking for recommendations
• Sharing data with third-party partners
• Biometric verification (optional)''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '6. How We Use Your Personal Data',
            content: '''We use your information to:

• Verify your identity as required by PDPA 2010
• Process rental bookings and payments
• Manage vehicle access and security
• Track vehicle location during rental period (theft prevention)
• Send booking confirmations and reminders
• Provide customer support
• Detect and prevent fraud
• Comply with legal and regulatory requirements
• Improve our services through analytics
• Send marketing communications (with your consent)
• Generate anonymized statistics and reports''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '7. Data Sharing and Disclosure',
            content: '''We may share your personal data with:

7.1 Service Providers (Data Processors):
• Payment gateway providers (iPay88, Stripe)
• Identity verification services (MyEG, JUMIO)
• Cloud storage providers (Amazon Web Services - Singapore region)
• SMS and email service providers
• Map and navigation services

7.2 Vehicle Owners:
• Name, contact number, and rental details
• Location during active rentals (for vehicle tracking)

7.3 Legal and Regulatory Authorities:
• Royal Malaysian Police (PDRM) - in case of theft or accidents
• Road Transport Department (JPJ) - for compliance verification
• Malaysian Communications and Multimedia Commission (MCMC)
• Courts and legal proceedings
• Tax authorities (Lembaga Hasil Dalam Negeri - LHDN)

7.4 Insurance Partners (with consent):
• For optional insurance coverage
• Claims processing

7.5 Business Transfers:
• In event of merger, acquisition, or sale of business

We ensure all third parties comply with PDPA 2010 through data processing agreements.''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '8. International Data Transfers',
            content: '''Your data is primarily stored in Malaysia. However, some service providers may process data in:

• Singapore (AWS cloud infrastructure)
• United States (payment processing, analytics)

We ensure adequate protection through:
• Standard Contractual Clauses (SCCs)
• Data Processing Agreements
• Compliance with PDPA 2010 cross-border transfer requirements
• Encryption in transit and at rest

You have the right to object to international transfers. Contact our DPO for more information.''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '9. Data Security',
            content: '''We implement security measures required by PDPA 2010 including:

Technical Measures:
• 256-bit SSL/TLS encryption
• Tokenization of payment card data (PCI-DSS compliant)
• Multi-factor authentication
• Regular security audits and penetration testing
• Firewall and intrusion detection systems
• Encrypted data storage

Organizational Measures:
• Staff training on data protection
• Access controls and authorization levels
• Confidentiality agreements
• Regular data protection impact assessments
• Incident response procedures

Despite our efforts, no system is 100% secure. We will notify you and the Personal Data Protection Commissioner within 72 hours of any data breach as required by law.''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '10. Data Retention',
            content: '''We retain your personal data for as long as necessary:

• Account information: Until account deletion + 30 days
• Transaction records: 7 years (as required by tax laws)
• Support tickets: 3 years
• Marketing consents: Until withdrawn + 30 days
• CCTV footage: 30 days (unless required for investigation)
• Vehicle tracking data: Duration of rental + 90 days

After retention periods, we securely delete or anonymize data in compliance with PDPA 2010.''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '11. Your Rights Under PDPA 2010',
            content: '''You have the following rights (see "Your Rights" page for details):

1. Right to Access (Section 29)
2. Right to Correction (Section 30)
3. Right to Withdraw Consent
4. Right to Data Portability
5. Right to Limit Processing
6. Right to Object
7. Right to Lodge Complaint

These rights are subject to certain exceptions under PDPA 2010.''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '12. Cookies and Tracking Technologies',
            content: '''We use cookies and similar technologies in compliance with MCMC guidelines:

Essential Cookies:
• Session management
• Security authentication
• Load balancing

Functional Cookies:
• Remember preferences
• Language settings

Analytics Cookies (with consent):
• Google Analytics
• Firebase Analytics
• App usage statistics

Marketing Cookies (with consent):
• Facebook Pixel
• Google Ads

You can manage cookies through:
• App Settings > Privacy > Cookie Preferences
• Browser settings
• Mobile device settings

Blocking cookies may limit functionality.''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '13. Children\'s Privacy',
            content: '''MotoRent is not intended for persons under 18 years old (or 21 for vehicle rental).

We do not knowingly collect data from minors. If you believe we have inadvertently collected data from a minor, please contact us immediately for deletion.

Parents/guardians have the right to request access to and deletion of their child\'s data.''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '14. Marketing Communications',
            content: '''We will only send marketing communications with your explicit consent.

You can opt-out anytime through:
• "Unsubscribe" link in emails
• SMS STOP reply
• App Settings > Privacy > Marketing Preferences
• Contacting our DPO

We will process opt-out requests within 7 working days.

Service-related communications (booking confirmations, payment receipts) are not marketing and cannot be opted out while using our service.''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '15. Third-Party Links',
            content: '''Our app may contain links to third-party websites/services:

• Insurance providers
• Payment gateways
• Social media platforms
• Map services

We are not responsible for their privacy practices. Please review their privacy policies.''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '16. Changes to This Privacy Policy',
            content: '''We may update this Privacy Policy to reflect:

• Changes in law or regulation
• New features or services
• Improvements in data protection practices

We will notify you of material changes through:
• In-app notification
• Email notification
• Prominent notice on homepage

Continued use after changes constitutes acceptance. You can always access the latest version in the app.''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '17. Governing Law',
            content: '''This Privacy Policy is governed by:

• Personal Data Protection Act 2010 (Act 709)
• Communications and Multimedia Act 1998
• Computer Crimes Act 1997
• Copyright Act 1987
• Laws of Malaysia

Disputes will be resolved in accordance with Malaysian law under the jurisdiction of Malaysian courts.''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '18. Contact Us',
            content: '''For privacy-related inquiries or to exercise your rights:

Data Protection Officer:
MotoRent Sdn. Bhd.
Level 12, Menara MotoRent
Jalan Ampang, 50450 Kuala Lumpur
Malaysia

Email: dpo@motorent.com
Phone: +60 3-1234 5679
Operating Hours: Monday-Friday, 9:00 AM - 6:00 PM MYT

We will respond within 21 days as required by PDPA 2010.

To lodge a complaint with the regulator:
Personal Data Protection Department
Ministry of Communications and Digital
Level 4-7, Lot 4G9, Precinct 4
Federal Government Administrative Centre
62100 Putrajaya, Malaysia
Tel: 1-300-88-2400
Email: pdp@kkmm.gov.my
Website: www.pdp.gov.my''',
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '19. Consent',
            content: '''By using MotoRent, you consent to:

• Collection and processing of your personal data as described
• Transfer of data to service providers
• Storage of data in Malaysia and abroad (with safeguards)
• Use of cookies and tracking technologies

You can withdraw consent anytime, but this may limit service availability.

For sensitive data (biometrics, health), we obtain explicit separate consent.''',
          ),
          const SizedBox(height: 24),
          _buildFooter(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '🔒 Privacy Policy',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your privacy is important to us',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: Color(0xFF1E88E5), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Last Updated: January 15, 2026\nEffective Date: January 1, 2026',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: const [
          Icon(Icons.verified_user, color: Color(0xFF1E88E5), size: 40),
          SizedBox(height: 12),
          Text(
            'Protected under Malaysian PDPA 2010',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'We are committed to protecting your personal data in accordance with Malaysian law and international best practices.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}