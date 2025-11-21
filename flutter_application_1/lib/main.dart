import 'package:flutter/material.dart';
// Import this package after adding it to your pubspec.yaml
import 'package:url_launcher/url_launcher.dart';

// Add these new imports for Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For auth
// We've removed google_sign_in as it's no longer the primary method
import 'firebase_options.dart'; // This file was created in Step 2

import 'package:cloud_firestore/cloud_firestore.dart';

// Note: For a real app, you would add packages for:
// - firebase_auth: for Gmail/Phone login
// - cloud_firestore: for database
// - permission_handler: to request SMS permissions

// --- Main Application ---

void main() async {
  // Make this function 'async'
  // This is required to initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        scaffoldBackgroundColor: const Color(
          0xFFF5F5F5,
        ), // Light grey background
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
        cardTheme: CardThemeData(
          // FIX: Changed CardTheme to CardThemeData
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

  EmergencyContact({
    required this.name,
    required this.number,
    required this.icon,
  });
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
                builder: (context) =>
                    PhoneVerificationScreen(verificationId: verificationId),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 12),
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

  const PhoneVerificationScreen({super.key, required this.verificationId});

  @override
  _PhoneVerificationScreenState createState() =>
      _PhoneVerificationScreenState();
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
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to verify code: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Verification Code')),
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
              // FIXED: Navigate to Notifications
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // FIXED: Navigate to Profile
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
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
          HomeGridItem(
            // FIX: Renamed to public class
            title: 'Report a Problem',
            icon: Icons.report_problem,
            onTap: () => Navigator.of(context).pushNamed('/report'),
          ),
          HomeGridItem(
            // FIX: Renamed to public class
            title: 'My Reports Status',
            icon: Icons.history,
            onTap: () => Navigator.of(context).pushNamed('/status'),
          ),
          HomeGridItem(
            // FIX: Renamed to public class
            title: 'Emergency Contacts',
            icon: Icons.local_hospital,
            onTap: () => Navigator.of(context).pushNamed('/contacts'),
          ),
          HomeGridItem(
            // FIX: Renamed to public class
            title: 'Announcements',
            icon: Icons.campaign,
            onTap: () => Navigator.of(context).pushNamed('/announcements'),
          ),
          HomeGridItem(
            // FIX: Renamed to public class
            title: 'Support & FAQs',
            icon: Icons.help_outline,
            onTap: () => Navigator.of(context).pushNamed('/support'),
          ),
          HomeGridItem(
            // FIX: Renamed to public class
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

class HomeGridItem extends StatelessWidget {
  // FIX: Renamed to public class
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const HomeGridItem({
    // FIX: Renamed to public class
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
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
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
    final String smsUri =
        'sms:+639170000000?body=${Uri.encodeComponent(details)}';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open SMS app: $e')));
    }
  }

  Future<void> _sendOnlineReport(String details) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Get the current user (to know WHO reported it)
      final user = FirebaseAuth.instance.currentUser;
      final String userId = user?.uid ?? 'anonymous';
      final String userPhone = user?.phoneNumber ?? 'No number';

      // 2. Create the data object
      // We use 'FieldValue.serverTimestamp()' to let the server decide the time
      final Map<String, dynamic> reportData = {
        'userId': userId,
        'userPhone': userPhone,
        'category': _selectedCategory,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'status': 'reported', // Default status
        'reportedAt': FieldValue.serverTimestamp(),
      };

      // 3. Send to Firestore collection named 'reports'
      await FirebaseFirestore.instance.collection('reports').add(reportData);

      // 4. Success!
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Clear the form
      _locationController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedCategory = null;
      });

      _showConfirmationDialog(
        title: 'Report Submitted',
        content:
            'Your report has been successfully sent to the municipality database.',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting report: $e')));
    }
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
  }) {
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
      appBar: AppBar(title: const Text('Report a Problem')),
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
                  _isOffline
                      ? 'Report via SMS (Offline)'
                      : 'Report via App (Online)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _isOffline
                      ? 'Uses your phone\'s SMS plan. Standard rates may apply.'
                      : 'Uses mobile data or Wi-Fi.',
                ),
                value: _isOffline,
                onChanged: (value) {
                  setState(() {
                    _isOffline = value;
                  });
                },
                activeThumbColor: Theme.of(
                  context,
                ).primaryColor, // FIX: Was activeColor
              ),
              const SizedBox(height: 24),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value:
                    _selectedCategory, // This is correct, do not change to initialValue
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
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
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
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a location'
                    : null,
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
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16),

              // TODO: Add "Attach Photo" button
              // This would require image_picker package
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Attach Photo (Optional)'),
                onPressed: _isOffline
                    ? null
                    : () {
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
  const ReportStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // If not logged in (shouldn't happen, but good for safety)
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view reports.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports Status')),
      // StreamBuilder listens to the database and updates the UI automatically
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: user.uid) // Only show MY reports
            .orderBy('reportedAt', descending: true) // Newest first
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Handle Error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 2. Handle Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. Handle Empty Data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No reports submitted yet.'),
                ],
              ),
            );
          }

          // 4. Show List of Reports
          final reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final doc = reports[index];
              final data = doc.data() as Map<String, dynamic>;

              // Convert the data into our ProblemReport object
              // Note: We handle cases where data might be missing
              final report = ProblemReport(
                id: doc.id,
                category: data['category'] ?? 'Unknown',
                description: data['description'] ?? '',
                location: data['location'] ?? '',
                status: _parseStatus(data['status']),
                reportedAt:
                    (data['reportedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              );

              return ReportStatusCard(report: report);
            },
          );
        },
      ),
    );
  }

  // Helper to convert string status from DB to Enum
  ReportStatus _parseStatus(String? status) {
    switch (status) {
      case 'ongoing':
        return ReportStatus.ongoing;
      case 'solved':
        return ReportStatus.solved;
      default:
        return ReportStatus.reported;
    }
  }
}

class ReportStatusCard extends StatelessWidget {
  final ProblemReport report;

  const ReportStatusCard({
    super.key,
    required this.report,
  }); // FIX: Use super.key

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(
                      (255 * 0.1).round(),
                    ), // FIX: Replaced withOpacity
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
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
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
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
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
// 5. Emergency Contacts Screen (Connected to Firestore)
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  // Helper to pick icons based on the 'type' field in the database
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'police':
        return Icons.local_police;
      case 'fire':
        return Icons.fire_truck;
      case 'medical':
        return Icons.local_hospital;
      case 'disaster':
        return Icons.warning;
      default:
        return Icons.phone;
    }
  }

  Future<void> _makeCall(String phoneNumber, BuildContext context) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open dialer for $phoneNumber')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_contacts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final contacts = snapshot.data!.docs;

          if (contacts.isEmpty) {
            return const Center(
              child: Text('No contacts available at the moment.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final data = contacts[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Emergency';
              final number = data['number'] ?? '';
              final type = data['type'] ?? 'general';

              return Card(
                margin: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 8.0,
                ),
                child: ListTile(
                  leading: Icon(
                    _getIconForType(type),
                    color: Theme.of(context).primaryColor,
                    size: 36,
                  ),
                  title: Text(
                    name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    number,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 16),
                  ),
                  trailing: const Icon(Icons.call, color: Colors.green),
                  onTap: () => _makeCall(number, context),
                ),
              );
            },
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
      'body':
          'Join us for a community-wide vaccination drive at the Municipal Hall. Free flu shots and COVID-19 boosters will be available from 8 AM to 5 PM.',
    },
    {
      'title': 'Road Closure Notification',
      'date': 'October 28, 2025',
      'body':
          'The National Highway (Brgy. Don Mariano section) will be temporarily closed for repairs from 1 PM to 4 PM. Please take alternate routes.',
    },
    {
      'title': 'Real Property Tax Deadline',
      'date': 'October 25, 2025',
      'body':
          'This is a final reminder that the deadline for Real Property Tax payments is on October 31, 2025. Pay now to avoid penalties.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    announcement['body']!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
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
      appBar: AppBar(title: const Text('Support & FAQs')),
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
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontSize: 20),
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
            subtitle: const Text(
              'https://www.bayombong.gov.ph',
            ), // Use https://
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to launch: $e')));
    }
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ), // FIX: Changed Causetext to context
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            answer,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
          ),
        ),
      ],
    );
  }
}

// --- NEW: Profile Screen ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            Text('Phone Number', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              user?.phoneNumber ?? 'No Number',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'User ID: ${user?.uid.substring(0, 5)}...',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  // Go back to login screen and remove all previous routes
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- NEW: Notifications Screen ---
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No new notifications'),
          ],
        ),
      ),
    );
  }
}
