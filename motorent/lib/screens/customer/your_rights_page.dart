// FILE: motorent/lib/screens/customer/your_rights_page.dart

import 'package:flutter/material.dart';

class YourRightsPage extends StatelessWidget {
  const YourRightsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Privacy Rights',
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
          _buildIntroSection(),
          const SizedBox(height: 24),
          
          // Individual Rights
          _buildRightCard(
            icon: Icons.search,
            iconColor: Colors.blue,
            number: '1',
            title: 'Right to Access Your Data',
            pdpaReference: 'Section 29, PDPA 2010',
            description: 'You have the right to request access to your personal data that we hold.',
            whatYouCanDo: [
              'Request a copy of all personal data we have about you',
              'Receive information about how we process your data',
              'Know the purposes for which we use your data',
              'Identify who we share your data with',
              'Understand how long we keep your data',
            ],
            howToExercise: 'Go to Privacy Dashboard > My Data > Download my data, or email dpo@motorent.com',
            timeframe: 'We will respond within 21 days as required by PDPA 2010',
            cost: 'First request is free. Subsequent requests may incur an administrative fee of RM10-50',
          ),
          const SizedBox(height: 16),
          
          _buildRightCard(
            icon: Icons.edit,
            iconColor: Colors.orange,
            number: '2',
            title: 'Right to Correction',
            pdpaReference: 'Section 30, PDPA 2010',
            description: 'You have the right to request correction of inaccurate or incomplete personal data.',
            whatYouCanDo: [
              'Update your profile information',
              'Correct any inaccurate personal details',
              'Add missing information to your profile',
              'Request deletion of incorrect data',
            ],
            howToExercise: 'Privacy Dashboard > Request corrections, or contact our DPO',
            timeframe: 'We will respond within 21 days and update records within 14 days after verification',
            exceptions: ['We may refuse correction if it would affect legal proceedings or if data is required by law',]
          ),
          const SizedBox(height: 16),
          
          _buildRightCard(
            icon: Icons.block,
            iconColor: Colors.purple,
            number: '3',
            title: 'Right to Withdraw Consent',
            pdpaReference: 'Section 38, PDPA 2010',
            description: 'You can withdraw your consent for us to process your personal data at any time.',
            whatYouCanDo: [
              'Stop marketing communications',
              'Disable location tracking',
              'Revoke third-party data sharing',
              'Cancel optional features',
            ],
            howToExercise: 'Privacy Dashboard > Privacy Settings > Manage consents',
            timeframe: 'Takes effect immediately, processed within 7 days',
            exceptions: ['Cannot withdraw consent for data processing necessary for contract performance or legal obligations',]
          ),
          const SizedBox(height: 16),
          
          _buildRightCard(
            icon: Icons.swap_horiz,
            iconColor: Colors.teal,
            number: '4',
            title: 'Right to Data Portability',
            pdpaReference: 'Best Practice (not explicitly in PDPA 2010)',
            description: 'You can request to receive your personal data in a structured, commonly used format.',
            whatYouCanDo: [
              'Download your data in JSON or CSV format',
              'Transfer your data to another service provider',
              'Obtain a copy of your rental history',
              'Export your preferences and settings',
            ],
            howToExercise: 'Privacy Dashboard > My Data > Download my data',
            timeframe: 'Data export provided within 7 days',
            format: 'Available in JSON, CSV, or PDF format',
          ),
          const SizedBox(height: 16),
          
          _buildRightCard(
            icon: Icons.pause_circle,
            iconColor: Colors.indigo,
            number: '5',
            title: 'Right to Limit Processing',
            pdpaReference: 'Section 40, PDPA 2010',
            description: 'You can request to limit how we use your personal data in certain circumstances.',
            whatYouCanDo: [
              'Restrict processing while disputing data accuracy',
              'Limit use for specific purposes',
              'Object to certain types of processing',
              'Request suspension pending verification',
            ],
            howToExercise: 'Contact our Data Protection Officer at dpo@motorent.com',
            timeframe: 'Processing limited within 7 days of verification',
            note: 'We may continue processing if we have legal obligations or legitimate interests',
          ),
          const SizedBox(height: 16),
          
          _buildRightCard(
            icon: Icons.cancel,
            iconColor: Colors.red[700]!,
            number: '6',
            title: 'Right to Object',
            pdpaReference: 'Best Practice under PDPA 2010',
            description: 'You have the right to object to certain types of processing of your personal data.',
            whatYouCanDo: [
              'Object to direct marketing',
              'Object to automated decision-making',
              'Object to profiling',
              'Object to processing based on legitimate interests',
            ],
            howToExercise: 'Privacy Dashboard > Privacy Settings, or email dpo@motorent.com',
            timeframe: 'Objections processed within 14 days',
            note: 'We must cease processing unless we can demonstrate compelling legitimate grounds',
          ),
          const SizedBox(height: 16),
          
          _buildRightCard(
            icon: Icons.delete_forever,
            iconColor: Colors.red,
            number: '7',
            title: 'Right to Erasure ("Right to be Forgotten")',
            pdpaReference: 'Best Practice (limited scope in PDPA 2010)',
            description: 'You can request deletion of your personal data in certain circumstances.',
            whatYouCanDo: [
              'Delete your MotoRent account',
              'Request removal of specific data',
              'Erase data no longer needed for original purpose',
              'Remove data processed unlawfully',
            ],
            howToExercise: 'Privacy Dashboard > Manage My Data > Delete my account',
            timeframe: 'Account deleted within 30 days',
            exceptions: [
              'Transaction records kept for 7 years (tax law requirements)',
              'Legal compliance and dispute resolution',
              'Exercise or defense of legal claims',
              'Public interest or official authority',
            ],
          ),
          const SizedBox(height: 16),
          
          _buildRightCard(
            icon: Icons.report_problem,
            iconColor: Colors.amber[700]!,
            number: '8',
            title: 'Right to Lodge a Complaint',
            pdpaReference: 'Section 101-103, PDPA 2010',
            description: 'You have the right to lodge a complaint with the Personal Data Protection Commissioner.',
            whatYouCanDo: [
              'File a complaint if you believe your rights are violated',
              'Report data breaches or misuse',
              'Escalate unresolved privacy concerns',
              'Seek enforcement action',
            ],
            howToExercise: '''Contact the Personal Data Protection Department:

Ministry of Communications and Digital
Level 4-7, Lot 4G9, Precinct 4
Federal Government Administrative Centre
62100 Putrajaya, Malaysia

Hotline: 1-300-88-2400
Email: pdp@kkmm.gov.my
Website: www.pdp.gov.my
Online Complaint Form: Available on website

You should attempt to resolve concerns with our DPO first, but you can file a complaint at any time.''',
            timeframe: 'Commissioner will respond according to PDPA procedures',
          ),
          const SizedBox(height: 24),
          
          _buildLimitationsSection(),
          const SizedBox(height: 24),
          
          _buildHowToExerciseRights(),
          const SizedBox(height: 24),
          
          _buildContactSection(),
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
          colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '⚖️ Your Privacy Rights',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Under Malaysian Personal Data Protection Act 2010',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Your Rights Under PDPA 2010',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7B1FA2),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'The Personal Data Protection Act 2010 (Act 709) grants you specific rights over your personal data. This page explains each right in detail, how to exercise them, and any limitations that may apply.',
            style: TextStyle(fontSize: 14, height: 1.6),
          ),
          SizedBox(height: 12),
          Text(
            'These rights are fundamental to ensuring your privacy and control over your personal information.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7B1FA2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightCard({
    required IconData icon,
    required Color iconColor,
    required String number,
    required String title,
    required String pdpaReference,
    required String description,
    required List<String> whatYouCanDo,
    required String howToExercise,
    required String timeframe,
    String? cost,
    String? format,
    String? note,
    List<String>? exceptions,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RIGHT #$number',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // PDPA Reference
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                pdpaReference,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              description,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // What You Can Do
            _buildSubSection(
              'What You Can Do:',
              whatYouCanDo.map((item) => '• $item').join('\n'),
            ),
            const SizedBox(height: 16),
            
            // How to Exercise
            _buildSubSection(
              'How to Exercise This Right:',
              howToExercise,
            ),
            const SizedBox(height: 16),
            
            // Timeframe
            _buildInfoBox(
              icon: Icons.access_time,
              color: Colors.blue,
              title: 'Response Timeframe',
              content: timeframe,
            ),
            
            if (cost != null) ...[
              const SizedBox(height: 12),
              _buildInfoBox(
                icon: Icons.attach_money,
                color: Colors.green,
                title: 'Cost',
                content: cost,
              ),
            ],
            
            if (format != null) ...[
              const SizedBox(height: 12),
              _buildInfoBox(
                icon: Icons.description,
                color: Colors.orange,
                title: 'Format',
                content: format,
              ),
            ],
            
            if (note != null) ...[
              const SizedBox(height: 12),
              _buildInfoBox(
                icon: Icons.info_outline,
                color: Colors.amber[700]!,
                title: 'Important Note',
                content: note,
              ),
            ],
            
            if (exceptions != null && exceptions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildExceptionsBox(exceptions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 13, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExceptionsBox(List<String> exceptions) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Exceptions & Limitations',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...exceptions.map((exception) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $exception',
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLimitationsSection() {
    return Card(
      elevation: 2,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Text(
                  'General Limitations on Rights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Your rights under PDPA 2010 are not absolute. We may refuse or limit requests in the following situations:',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 12),
            _buildLimitationItem('Legal obligations require us to retain the data'),
            _buildLimitationItem('The request is manifestly unfounded or excessive'),
            _buildLimitationItem('Complying would prejudice legal proceedings'),
            _buildLimitationItem('Data is required for establishing, exercising, or defending legal claims'),
            _buildLimitationItem('Processing is necessary for public interest'),
            _buildLimitationItem('The request conflicts with another person\'s rights'),
            _buildLimitationItem('National security or law enforcement requirements'),
            const SizedBox(height: 12),
            const Text(
              'If we refuse a request, we will explain the reason and inform you of your right to complain to the Commissioner.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToExerciseRights() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 How to Exercise Your Rights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildExerciseStep('1', 'Identify Your Right', 
                'Review the rights above and determine which applies to your request'),
            const Divider(height: 24),
            _buildExerciseStep('2', 'Choose Your Method', 
                'Use Privacy Dashboard in-app, email our DPO, or submit written request'),
            const Divider(height: 24),
            _buildExerciseStep('3', 'Verify Your Identity', 
                'We may ask for ID verification to protect your data (NRIC or Passport)'),
            const Divider(height: 24),
            _buildExerciseStep('4', 'Receive Response', 
                'We will respond within 21 days (PDPA requirement) with action taken'),
            const Divider(height: 24),
            _buildExerciseStep('5', 'Appeal if Needed', 
                'If unsatisfied, contact the Personal Data Protection Commissioner'),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Card(
      elevation: 3,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📞 Contact Our Data Protection Officer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(Icons.person, 'Ahmad bin Abdullah'),
            _buildContactItem(Icons.email, 'dpo@motorent.com'),
            _buildContactItem(Icons.phone, '+60 3-1234 5679'),
            _buildContactItem(Icons.location_on, 
                'Level 12, Menara MotoRent\nJalan Ampang, 50450 Kuala Lumpur'),
            _buildContactItem(Icons.access_time, 
                'Monday-Friday, 9:00 AM - 6:00 PM MYT'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1E88E5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: const [
          Icon(Icons.gavel, color: Colors.white, size: 40),
          SizedBox(height: 12),
          Text(
            'Your Rights Are Protected by Law',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'MotoRent is committed to upholding your rights under the Personal Data Protection Act 2010 and ensuring your personal data is handled with the highest standards of care and security.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}