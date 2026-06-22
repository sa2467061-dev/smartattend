import 'package:flutter/material.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _classNameController = TextEditingController();
  
  // State variables for enrollment type toggle
  // true = Create Link, false = Create PIN
  bool _useLinkForEnrollment = true; 
  
  // Track mock uploaded file name string state
  String? _uploadedFileName;

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  void _simulateFilePick() {
    setState(() {
      _uploadedFileName = 'student_list_2026.xlsx'; // Simulates selection
    });
  }

  void _handleConfirm() {
    if (_classNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class name!')),
      );
      return;
    }

    // Success placeholder feedback layout notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Successfully created ${_classNameController.text}! Method: ${_useLinkForEnrollment ? "Link" : "PIN"}'
        ),
        backgroundColor: const Color(0xff10b981),
      ),
    );

    Navigator.pop(context); // Pops back safely to the LecturerClassScreen layout
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xff111827); // Lecturer dark color profile

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: themeColor),
          onPressed: () => Navigator.pop(context), // Pops route straight back to previous class stack tab
        ),
        title: const Text(
          'Add New Class',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Class Name Input ---
              const Text(
                'Class Name / Course Title',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _classNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g., Advanced Mobile Computing',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: themeColor, width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),

              // --- Document File Selection Block (PDF/Excel) ---
              const Text(
                'Import Student Roster (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _simulateFilePick,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _uploadedFileName == null ? Icons.cloud_upload_outlined : Icons.description_outlined,
                        size: 36,
                        color: _uploadedFileName == null ? Colors.grey : const Color(0xff10b981),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _uploadedFileName ?? 'Upload PDF or Excel file (.pdf, .xlsx)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _uploadedFileName == null ? FontWeight.normal : FontWeight.w600,
                          color: _uploadedFileName == null ? Colors.grey.shade600 : themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // --- Enrollment Preference Toggle Switch ---
              const Text(
                'Student Enrollment Security Method',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 14),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      _useLinkForEnrollment ? Icons.link_rounded : Icons.pin_rounded,
                      color: themeColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _useLinkForEnrollment ? 'Invite Link Method' : 'Secure Entry PIN Method',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: themeColor),
                          ),
                          Text(
                            _useLinkForEnrollment 
                                ? 'Generates an automated join URL code.' 
                                : 'Generates a 6-digit verification code.',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _useLinkForEnrollment,
                      activeColor: const Color(0xff004ce6),
                      onChanged: (bool val) {
                        setState(() {
                          _useLinkForEnrollment = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Confirm Creation CTA Button ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _handleConfirm,
                child: const Text(
                  'Confirm and Create',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}