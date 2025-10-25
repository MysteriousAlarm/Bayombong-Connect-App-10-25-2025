import 'package:flutter/material.dart';
// Import this package after adding it to your pubspec.yaml
import 'package:url_launcher/url_launcher.dart';

// Add these new imports for Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For auth
// We've removed google_sign_in as it's no longer the primary method
import 'firebase_options.dart'; // This file was created in Step 2

// Note: For a real app, you would add packages for:
// - firebase_auth: for Gmail/Phone login
// - cloud_firestore: for database
// - permission_handler: to request SMS permissions

// --- Main Application ---

void main() async { // Make this function 'async'
  // This is required to initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BayombongConnectApp());
}

class BayombongConnectApp extends StatelessWidget {
  const BayombongConnectApp({super.key}); // FIX: Use super.key

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bayombong Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF00796B), // A teal/green for government
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light grey background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00796B),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(
              secondary: const Color(0xFF004D40), // Darker teal
              brightness: Brightness.light,
            ),
        cardTheme: CardThemeData( // FIX: Changed CardTheme to CardThemeData
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00796B), // Button color
            foregroundColor: Colors.white, // Text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF333333),
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF555555)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF777777)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF00796B)),
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/report': (context) => const ReportProblemScreen(),
        '/status': (context) => const ReportStatusScreen(),
        '/contacts': (context) => const EmergencyContactsScreen(),
        '/announcements': (context) => const AnnouncementsScreen(),
        '/support': (context) => const SupportScreen(),
      },
    );
  }
}

// --- Data Models ---

// Represents a user's problem report
class ProblemReport {
  final String id;
  final String category;
  final String description;
  final String location;
  final ReportStatus status;
  final DateTime reportedAt;

  ProblemReport({
    required this.id,
    required this.category,
    required this.description,
    required this.location,
    required this.status,
    required this.reportedAt,
  });
}

// Enum for report status
enum ReportStatus { reported, ongoing, solved }

// Represents an emergency contact
class EmergencyContact {
  final String name;
  final String number;
  final IconData icon;

  EmergencyContact({required this.name, required this.number, required this.icon});
}

// --- Screens ---

// 1. Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // FIX: Use super.key

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _loginWithPhone() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't submit if form is invalid
    }

    setState(() {
      _isLoading = true;
    });

    // Make sure to format the phone number correctly, e.g., +639171234567
    final phoneNumber = _phoneController.text;

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        // (1) Handle Automatic Verification (Android only)
        verificationCompleted: (PhoneAuthCredential credential) async {
          // This can happen if Firebase automatically verifies the code
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        },
        // (2) Handle Failed Verification
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification failed: ${e.message}')),
            );
          }
        },
        // (3) Handle Code Sent
        codeSent: (String verificationId, int? resendToken) {
          // Code was sent, now ask user to type it in
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PhoneVerificationScreen(
                  verificationId: verificationId,
                ),
              ),
            );
          }
        },
        // (4) Handle Code Auto-Retrieval Timeout
        codeAutoRetrievalTimeout: (String verificationId) {
          // You could auto-resend here, or just let the user manually resend
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Placeholder for municipality seal
                Icon(
                  Icons.security,
                  size: 100,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to\nBayombong Connect',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontSize: 28,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your direct line to the municipality.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 48),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Phone Number Input
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+639171234567',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (!value.startsWith('+')) {
                        return 'Please include the country code (e.g., +63)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sign in with Phone Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text('Sign in with Phone Number'),
                    onPressed: _loginWithPhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'We will send a verification code to this number.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// --- NEW SCREEN FOR PHONE VERIFICATION ---

class PhoneVerificationScreen extends StatefulWidget {
  final String verificationId;

  const PhoneVerificationScreen({
    super.key,
    required this.verificationId,
  });

  @override
  _PhoneVerificationScreenState createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a PhoneAuthCredential with the code
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _codeController.text,
      );

      // Sign the user in (or link) with the credential
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Navigate to home screen on success
      if (mounted) {
        // We use pushReplacementNamed to clear the login stack
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify code: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Verification Code'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the 6-digit code sent to your phone.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '123456',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _verifyCode,
                  child: const Text('Verify and Sign In'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


// 2. Home Screen (Dashboard)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key}); // FIX: Use super.key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bayombong Connect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications panel
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // TODO: Navigate to Profile Screen
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          HomeGridItem( // FIX: Renamed to public class
            title: 'Report a Problem',
            icon: Icons.report_problem,
            onTap: () => Navigator.of(context).pushNamed('/report'),
          ),
          HomeGridItem( // FIX: Renamed to public class
            title: 'My Reports Status',
            icon: Icons.history,
            onTap: () => Navigator.of(context).pushNamed('/status'),
          ),
          HomeGridItem( // FIX: Renamed to public class
            title: 'Emergency Contacts',
            icon: Icons.local_hospital,
            onTap: () => Navigator.of(context).pushNamed('/contacts'),
          ),
          HomeGridItem( // FIX: Renamed to public class
            title: 'Announcements',
            icon: Icons.campaign,
            onTap: () => Navigator.of(context).pushNamed('/announcements'),
          ),
          HomeGridItem( // FIX: Renamed to public class
            title: 'Support & FAQs',
            icon: Icons.help_outline,
            onTap: () => Navigator.of(context).pushNamed('/support'),
          ),
          HomeGridItem( // FIX: Renamed to public class
            title: 'Log Out',
            icon: Icons.logout,
            onTap: () {
              // IMPLEMENTED: Actual sign out logic
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class HomeGridItem extends StatelessWidget { // FIX: Renamed to public class
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const HomeGridItem({ // FIX: Renamed to public class
    super.key, // FIX: Use super.key
    required this.title,
    required this.icon,
    required this.onTap,
  }); // Removed extra super(key: key)

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. Report a Problem Screen
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key}); // FIX: Use super.key

  @override
  _ReportProblemScreenState createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isOffline = false; // Mock toggle for offline/online

  final List<String> _categories = [
    'Waste Management',
    'Broken Streetlight',
    'Pothole/Road Damage',
    'Water Leakage',
    'Noise Complaint',
    'Other',
  ];

  void _submitReport() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final reportDetails = 
          'Category: $_selectedCategory\n'
          'Location: ${_locationController.text}\n'
          'Description: ${_descriptionController.text}';

      if (_isOffline) {
        // OFFLINE SMS REPORTING
        _sendSmsReport(reportDetails);
      } else {
        // ONLINE APP REPORTING
        _sendOnlineReport(reportDetails);
      }
    }
  }

  Future<void> _sendSmsReport(String details) async {
    // IMPLEMENTED: This will now try to open the SMS app
    final String smsUri = 'sms:+639170000000?body=${Uri.encodeComponent(details)}';
    try {
      if (await canLaunchUrl(Uri.parse(smsUri))) {
        await launchUrl(Uri.parse(smsUri));
      } else {
        // Show an error snackbar
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open SMS app.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open SMS app: $e')),
      );
    }
  }

  Future<void> _sendOnlineReport(String details) async {
    // TODO: Implement submission to Firestore/Database
    
    // Show mock loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    await Future.delayed(const Duration(seconds: 1)); // Simulate upload
    
    // FIX: Check if the widget is still mounted (in the widget tree)
    // before interacting with the Navigator or showing another dialog.
    if (!mounted) return;

    Navigator.of(context).pop(); // Close loading
    _showConfirmationDialog(
      title: 'Report Submitted',
      content: 'Your report has been successfully submitted online. You can track its status in the "My Reports" section.'
    );
  }

  void _showConfirmationDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back from report screen
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Problem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Offline/Online Toggle
              SwitchListTile(
                title: Text(
                  _isOffline ? 'Report via SMS (Offline)' : 'Report via App (Online)',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(_isOffline 
                  ? 'Uses your phone\'s SMS plan. Standard rates may apply.'
                  : 'Uses mobile data or Wi-Fi.'),
                value: _isOffline,
                onChanged: (value) {
                  setState(() {
                    _isOffline = value;
                  });
                },
                activeThumbColor: Theme.of(context).primaryColor, // FIX: Was activeColor
              ),
              const SizedBox(height: 24),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory, // This is correct, do not change to initialValue
                hint: const Text('Select Problem Category'),
                isExpanded: true,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a category' : null,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location / Landmark',
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'e.g., "In front of St. Dominic\'s Cathedral"',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Brief Description',
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Describe the problem in detail.',
                ),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              
              // TODO: Add "Attach Photo" button
              // This would require image_picker package
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Attach Photo (Optional)'),
                onPressed: _isOffline ? null : () {
                  // Can't attach photos to SMS easily
                  // TODO: Implement image picker
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitReport,
                child: const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

// 4. Report Status Screen
class ReportStatusScreen extends StatelessWidget {
  const ReportStatusScreen({super.key}); // FIX: Use super.key

  // Mock data for report statuses
  static final List<ProblemReport> _mockReports = [
    ProblemReport(
      id: 'RPT-001',
      category: 'Pothole/Road Damage',
      description: 'Large pothole on national highway near bus terminal.',
      location: 'National Highway, Brgy. Don Mariano',
      status: ReportStatus.solved,
      reportedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ProblemReport(
      id: 'RPT-002',
      category: 'Broken Streetlight',
      description: 'Streetlight in front of our house is not working for 3 days.',
      location: 'Magsaysay St., Brgy. La Torre',
      status: ReportStatus.ongoing,
      reportedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ProblemReport(
      id: 'RPT-003',
      category: 'Waste Management',
      description: 'Uncollected garbage accumulating.',
      location: 'Public Market',
      status: ReportStatus.reported,
      reportedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports Status'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _mockReports.length,
        itemBuilder: (context, index) {
          final report = _mockReports[index];
          return ReportStatusCard(report: report);
        },
      ),
    );
  }
}

class ReportStatusCard extends StatelessWidget {
  final ProblemReport report;

  const ReportStatusCard({super.key, required this.report}); // FIX: Use super.key

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.reported:
        return Icons.flag;
      case ReportStatus.ongoing:
        return Icons.construction;
      case ReportStatus.solved:
        return Icons.check_circle;
    }
  }

  Color _getStatusColor(ReportStatus status, BuildContext context) {
    switch (status) {
      case ReportStatus.reported:
        return Colors.blue.shade700;
      case ReportStatus.ongoing:
        return Colors.orange.shade700;
      case ReportStatus.solved:
        return Colors.green.shade700;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.reported:
        return 'Reported';
      case ReportStatus.ongoing:
        return 'Ongoing Process';
      case ReportStatus.solved:
        return 'Problem Solved';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(report.status, context);
    final statusText = _getStatusText(report.status);
    final statusIcon = _getStatusIcon(report.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    report.category,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha((255 * 0.1).round()), // FIX: Replaced withOpacity
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // Details
            Text(
              report.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.location,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                const SizedBox(width: 8),
                Text(
                  'Reported on: ${_formatDate(report.reportedAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 5. Emergency Contacts Screen
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key}); // FIX: Use super.key

  // Mock data for contacts
  // TODO: Move this to a remote config (like Firestore) so it can be updated
  static final List<EmergencyContact> _contacts = [
    EmergencyContact(name: 'Bayombong PNP', number: '09171234567', icon: Icons.local_police),
    EmergencyContact(name: 'Bayombong Fire Station', number: '09177654321', icon: Icons.fire_truck),
    EmergencyContact(name: 'Provincial Hospital', number: '09171112222', icon: Icons.local_hospital),
    EmergencyContact(name: 'MDRRMO', number: '09173334444', icon: Icons.emergency),
  ];
  
  // IMPLEMENTED: This will now try to launch the phone dialer
  Future<void> _makeCall(String phoneNumber, BuildContext context) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // Show an error snackbar
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open dialer for $phoneNumber')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to make call: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _contacts.length,
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: ListTile(
              leading: Icon(
                contact.icon,
                color: Theme.of(context).primaryColor,
                size: 36,
              ),
              title: Text(contact.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(contact.number, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
              trailing: const Icon(Icons.call, color: Colors.green),
              onTap: () => _makeCall(contact.number, context),
            ),
          );
        },
      ),
    );
  }
}

// 6. Announcements Screen
class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key}); // FIX: Use super.key

  // Mock data for announcements
  static final List<Map<String, String>> _announcements = [
    {
      'title': 'Community Vaccination Drive',
      'date': 'October 30, 2025',
      'body': 'Join us for a community-wide vaccination drive at the Municipal Hall. Free flu shots and COVID-19 boosters will be available from 8 AM to 5 PM.'
    },
    {
      'title': 'Road Closure Notification',
      'date': 'October 28, 2025',
      'body': 'The National Highway (Brgy. Don Mariano section) will be temporarily closed for repairs from 1 PM to 4 PM. Please take alternate routes.'
    },
    {
      'title': 'Real Property Tax Deadline',
      'date': 'October 25, 2025',
      'body': 'This is a final reminder that the deadline for Real Property Tax payments is on October 31, 2025. Pay now to avoid penalties.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement['title']!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Posted on: ${announcement['date']!}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    announcement['body']!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 7. Support Screen
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key}); // FIX: Use super.key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & FAQs'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFAQItem(
            context,
            'How do I report a problem?',
            'Go to the Home Screen and tap on "Report a Problem". Fill out the form with all the required details. You can choose to report via the app (Online) or via SMS (Offline).',
          ),
          _buildFAQItem(
            context,
            'How do I track my report?',
            'Tap on "My Reports Status" from the Home Screen. You will see a list of all your submitted reports and their current status (Reported, Ongoing, or Solved).',
          ),
          _buildFAQItem(
            context,
            'What is the difference between Online and Offline reporting?',
            'Online reporting uses your internet connection (Wi-Fi or mobile data) to send the report directly to our system. Offline reporting will open your phone\'s SMS app with a pre-filled message to be sent to a municipal hotline. Standard SMS rates may apply.',
          ),
          _buildFAQItem(
            context,
            'Is my data secure?',
            'Yes, we take user privacy seriously. All data submitted through the app is encrypted. Please see our Privacy Policy for more details.',
          ),
          const Divider(height: 32),
          Text(
            'Need more help?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email Support'),
            subtitle: const Text('support@bayombong.gov.ph'),
            onTap: () {
              // IMPLEMENTED: This will now try to open the email app
              _launchGenericUrl('mailto:support@bayombong.gov.ph', context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Visit our Website'),
            subtitle: const Text('https://www.bayombong.gov.ph'), // Use https://
            onTap: () {
              // IMPLEMENTED: This will now try to open the browser
              _launchGenericUrl('https://www.bayombong.gov.ph', context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchGenericUrl(String url, BuildContext context) async {
    // Helper function for email and web
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch: $e')),
      );
    }
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold), // FIX: Changed Causetext to context
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
          ),
        ),
      ],
    );
  }
}

