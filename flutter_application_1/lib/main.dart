import 'dart:io'; // Needed for File handling
import 'package:flutter/material.dart';
// Import this package after adding it to your pubspec.yaml
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart'; // REQUIRED for camera/gallery

// Add these new imports for Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

// --- Main Application ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

// --- ADD THIS BLOCK ---
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  // ---------------------

  runApp(const BayombongConnectApp());
}

class BayombongConnectApp extends StatelessWidget {
  const BayombongConnectApp({super.key});

  // Define your custom color palette
  static const Color primaryGreen = Color(0xFF006B3A); // Dark Green
  static const Color secondaryGreen = Color(0xFF35A551); // Light Green
  static const Color accentYellow = Color(0xFFFFBE26); // Yellow
  static const Color primaryBlue = Color(0xFF004A6D); // Blue
  static const Color white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One Bayombong',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryGreen,
        scaffoldBackgroundColor: white,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: white),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: secondaryGreen,
          surface: white,
          background: white,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: white,
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
            color: primaryGreen,
          ),
          titleMedium: TextStyle(
            color: white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF333333)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF555555)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
          labelStyle: const TextStyle(color: primaryGreen),
          prefixIconColor: primaryGreen,
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

enum ReportStatus { reported, ongoing, solved }

// --- Screens ---

// 1. Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _loginWithPhone() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final phoneNumber = _phoneController.text;
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification failed: ${e.message}')),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
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
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
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
                // Logo Section
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.jpg', 
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.security,
                          size: 100,
                          color: Theme.of(context).primaryColor,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to\nOne Bayombong',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
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
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text('Sign in with Phone Number'),
                    onPressed: _loginWithPhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BayombongConnectApp.secondaryGreen,
                    ),
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

// --- PHONE VERIFICATION SCREEN ---
class PhoneVerificationScreen extends StatefulWidget {
  final String verificationId;
  const PhoneVerificationScreen({super.key, required this.verificationId});

  @override
  _PhoneVerificationScreenState createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) return;
    setState(() { _isLoading = true; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _codeController.text,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify code: $e')),
        );
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BayombongConnectApp.secondaryGreen,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. Home Screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('One Bayombong'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const NotificationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ProfileScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            HomeGridItem(
              title: 'Report a Problem',
              icon: Icons.report_problem,
              color: BayombongConnectApp.secondaryGreen,
              onTap: () => Navigator.of(context).pushNamed('/report'),
            ),
            HomeGridItem(
              title: 'My Reports Status',
              icon: Icons.history,
              color: BayombongConnectApp.accentYellow,
              onTap: () => Navigator.of(context).pushNamed('/status'),
            ),
            HomeGridItem(
              title: 'Emergency Contacts',
              icon: Icons.local_hospital,
              color: BayombongConnectApp.primaryBlue,
              onTap: () => Navigator.of(context).pushNamed('/contacts'),
            ),
            HomeGridItem(
              title: 'Announcements',
              icon: Icons.campaign,
              color: BayombongConnectApp.primaryGreen,
              onTap: () => Navigator.of(context).pushNamed('/announcements'),
            ),
            HomeGridItem(
              title: 'Support & FAQs',
              icon: Icons.help_outline,
              color: BayombongConnectApp.secondaryGreen,
              onTap: () => Navigator.of(context).pushNamed('/support'),
            ),
            HomeGridItem(
              title: 'Log Out',
              icon: Icons.logout,
              color: BayombongConnectApp.accentYellow,
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomeGridItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const HomeGridItem({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: BayombongConnectApp.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. Report a Problem Screen (UPDATED WITH CAMERA)
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});
  @override
  _ReportProblemScreenState createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isOffline = false;
  
  // New: Variable to hold the selected image
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Waste Management',
    'Broken Streetlight',
    'Pothole/Road Damage',
    'Water Leakage',
    'Noise Complaint',
    'Other',
  ];

  // Function to pick image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Compress image to save data/storage
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Function to show selection dialog
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitReport() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // In a real app with Firebase Storage, you would upload _imageFile here
      // and get a URL to add to reportDetails. 
      // For now, we will just note that an image is attached.

      final reportDetails = 'Category: $_selectedCategory\nLocation: ${_locationController.text}\nDescription: ${_descriptionController.text}';

      if (_isOffline) {
        _sendSmsReport(reportDetails);
      } else {
        _sendOnlineReport(reportDetails);
      }
    }
  }

  Future<void> _sendSmsReport(String details) async {
    final String smsUri = 'sms:+639170000000?body=${Uri.encodeComponent(details)}';
    try {
      if (await canLaunchUrl(Uri.parse(smsUri))) {
        await launchUrl(Uri.parse(smsUri));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open SMS app.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open SMS app: $e')));
    }
  }

  Future<void> _sendOnlineReport(String details) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final user = FirebaseAuth.instance.currentUser;
      final String userId = user?.uid ?? 'anonymous';
      final String userPhone = user?.phoneNumber ?? 'No number';
      final Map<String, dynamic> reportData = {
        'userId': userId,
        'userPhone': userPhone,
        'category': _selectedCategory,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'status': 'reported',
        'reportedAt': FieldValue.serverTimestamp(),
        // Note: We are saving the local path for now. 
        // Real apps need Firebase Storage to upload the actual file to the cloud.
        'localImagePath': _imageFile?.path ?? '', 
      };
      await FirebaseFirestore.instance.collection('reports').add(reportData);
      if (!mounted) return;
      Navigator.of(context).pop();
      _locationController.clear();
      _descriptionController.clear();
      setState(() { 
        _selectedCategory = null; 
        _imageFile = null;
      });
      _showConfirmationDialog(
          title: 'Report Submitted',
          content: 'Your report has been successfully sent to the municipality database.');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting report: $e')));
    }
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
            onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pop(); },
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
              SwitchListTile(
                title: Text(
                  _isOffline ? 'Report via SMS (Offline)' : 'Report via App (Online)',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(_isOffline ? 'Uses your phone\'s SMS plan.' : 'Uses mobile data or Wi-Fi.'),
                value: _isOffline,
                onChanged: (value) { setState(() { _isOffline = value; }); },
                activeThumbColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Select Problem Category'),
                isExpanded: true,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(value: category, child: Text(category));
                }).toList(),
                onChanged: (newValue) { setState(() { _selectedCategory = newValue; }); },
                validator: (value) => value == null ? 'Please select a category' : null,
                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location / Landmark', prefixIcon: Icon(Icons.location_on)),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Brief Description', prefixIcon: Icon(Icons.description)),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              
              // --- IMAGE PREVIEW SECTION ---
              if (_imageFile != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                    )
                  ],
                ),

              // --- IMAGE PICKER BUTTON ---
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Attach Photo (Optional)'),
                onPressed: _isOffline ? null : _showImagePickerOptions, // Opens the dialog
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton(onPressed: _submitReport, child: const Text('Submit Report')),
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
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view reports.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports Status')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: user.uid)
            .orderBy('reportedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No reports submitted yet.'));
          final reports = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final doc = reports[index];
              final data = doc.data() as Map<String, dynamic>;
              final report = ProblemReport(
                id: doc.id,
                category: data['category'] ?? 'Unknown',
                description: data['description'] ?? '',
                location: data['location'] ?? '',
                status: _parseStatus(data['status']),
                reportedAt: (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
              return ReportStatusCard(report: report);
            },
          );
        },
      ),
    );
  }

  ReportStatus _parseStatus(String? status) {
    switch (status) {
      case 'ongoing': return ReportStatus.ongoing;
      case 'solved': return ReportStatus.solved;
      default: return ReportStatus.reported;
    }
  }
}

class ReportStatusCard extends StatelessWidget {
  final ProblemReport report;
  const ReportStatusCard({super.key, required this.report});

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.reported: return Icons.flag;
      case ReportStatus.ongoing: return Icons.construction;
      case ReportStatus.solved: return Icons.check_circle;
    }
  }

  Color _getStatusColor(ReportStatus status, BuildContext context) {
    switch (status) {
      case ReportStatus.reported: return Colors.blue.shade700;
      case ReportStatus.ongoing: return Colors.orange.shade700;
      case ReportStatus.solved: return Colors.green.shade700;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.reported: return 'Reported';
      case ReportStatus.ongoing: return 'Ongoing Process';
      case ReportStatus.solved: return 'Problem Solved';
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    report.category,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 6),
                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(report.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                const SizedBox(width: 8),
                Expanded(child: Text(report.location, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                const SizedBox(width: 8),
                Text('Reported on: ${_formatDate(report.reportedAt)}', style: Theme.of(context).textTheme.bodyMedium),
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
  const EmergencyContactsScreen({super.key});

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'police': return Icons.local_police;
      case 'fire': return Icons.fire_truck;
      case 'medical': return Icons.local_hospital;
      case 'disaster': return Icons.warning;
      default: return Icons.phone;
    }
  }

  Future<void> _makeCall(String phoneNumber, BuildContext context) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open dialer for $phoneNumber')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to make call: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('emergency_contacts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final contacts = snapshot.data!.docs;
          if (contacts.isEmpty) return const Center(child: Text('No contacts available at the moment.'));
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final data = contacts[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Emergency';
              final number = data['number'] ?? '';
              final type = data['type'] ?? 'general';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                child: ListTile(
                  leading: Icon(_getIconForType(type), color: Theme.of(context).primaryColor, size: 36),
                  title: Text(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(number, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
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

// 6. Announcements Screen (With Social Feed Style)
class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      backgroundColor: Colors.grey[100], // Light background for feed style
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final announcements = snapshot.data!.docs;

          if (announcements.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feed_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No announcements yet.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final data = announcements[index].data() as Map<String, dynamic>;
              
              // Extract fields with fallbacks
              final title = data['title'] ?? 'Announcement';
              final body = data['body'] ?? '';
              final date = data['date'] ?? 'Just now';
              
              // Author details
              final author = data['author'] ?? 'LGU Bayombong';
              final role = data['role'] ?? 'Admin';
              // Simple logic to pick an avatar color based on the name
              final avatarColor = _getAvatarColor(author);

              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header (Author & Role) ---
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: avatarColor.withOpacity(0.1),
                            radius: 20,
                            child: Icon(Icons.person, color: avatarColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  author,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  role,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.verified, size: 16, color: Colors.blue[400]), // "Verified" badge look
                        ],
                      ),
                    ),
                    
                    const Divider(height: 1, thickness: 0.5),

                    // --- Content (Title & Body) ---
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            body,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Footer (Date) ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'Posted on $date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getAvatarColor(String name) {
    if (name.contains('Governor')) return Colors.orange;
    if (name.contains('Mayor')) return Colors.blue;
    return Colors.green;
  }
}

// 7. Support Screen
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support & FAQs')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFAQItem(context, 'How do I report a problem?', 'Go to the Home Screen and tap on "Report a Problem".'),
          _buildFAQItem(context, 'How do I track my report?', 'Tap on "My Reports Status" from the Home Screen.'),
          _buildFAQItem(context, 'What is the difference between Online and Offline reporting?', 'Online uses data. Offline uses SMS.'),
          _buildFAQItem(context, 'Is my data secure?', 'Yes, we take user privacy seriously.'),
          const Divider(height: 32),
          Text('Need more help?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20)),
          const SizedBox(height: 16),
          ListTile(leading: const Icon(Icons.email), title: const Text('Email Support'), subtitle: const Text('support@bayombong.gov.ph'), onTap: () { _launchGenericUrl('mailto:support@bayombong.gov.ph', context); }),
          ListTile(leading: const Icon(Icons.public), title: const Text('Visit our Website'), subtitle: const Text('https://www.bayombong.gov.ph'), onTap: () { _launchGenericUrl('https://www.bayombong.gov.ph', context); }),
        ],
      ),
    );
  }
  Future<void> _launchGenericUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) { await launchUrl(uri); } else { if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $url'))); }
    } catch (e) { if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to launch: $e'))); }
  }
  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      children: [Padding(padding: const EdgeInsets.all(16.0), child: Text(answer, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4)))],
    );
  }
}

// --- Profile Screen ---
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
            Text(user?.phoneNumber ?? 'No Number', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text('User ID: ${user?.uid.substring(0, 5)}...', style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) { Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); }
              },
            )
          ],
        ),
      ),
    );
  }
}

// --- Notifications Screen ---
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_none, size: 80, color: Colors.grey), SizedBox(height: 16), Text('No new notifications')])),
    );
  }
}