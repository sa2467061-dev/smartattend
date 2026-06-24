import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard functionality
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

String generateClassPin() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; 
  Random random = Random.secure();
  return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
}

class AddClassScreen extends StatefulWidget {
  final String? userId; // Optional parameter to pass user ID if needed
  const AddClassScreen({super.key, this.userId});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _classNameController = TextEditingController();
  bool _isLoading = false;
  String? _uploadedFileName;

  // State variables to hold generated details after successful creation
  String? _generatedCode;
  bool _isSuccess = false;

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  void _simulateFilePick() {
    setState(() {
      _uploadedFileName = 'student_list_2026.xlsx'; 
    });
  }

 Future<void> _handleConfirm() async {
    final className = _classNameController.text.trim();

    if (className.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class name!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String generatedCode = generateClassPin();
      
      // Cleanly resolve the logged-in lecturer ID with a fallback
      String currentLectId = widget.userId ?? 'DEV_LECT_TEST_ID';
      
      if (currentLectId.isEmpty) {
        currentLectId = 'DEV_LECT_TEST_ID';
      }

      // Save to your Firestore 'classes' collection
      await FirebaseFirestore.instance.collection('classes').add({
        'name': className,
        'class_code': generatedCode,
        'lect_id': currentLectId,
        'student_count': 0,
        'enrolled_stud': [], 
      });

      setState(() {
        _generatedCode = generatedCode;
        _isSuccess = true;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save class: $e'), backgroundColor: Colors.red),
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

  // Clipboard copy action function
  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xff10b981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xff111827);

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: themeColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isSuccess ? 'Class Created' : 'Add New Class',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: themeColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isSuccess ? _buildSuccessView(themeColor) : _buildFormView(themeColor),
              ),
            ),
      ),
    );
  }

  // VIEW 1: Input Setup Form
  Widget _buildFormView(Color themeColor) {
    return Column(
      key: const ValueKey('FormView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff004ce6), width: 1.5)),
          ),
        ),
        const SizedBox(height: 24),

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
                  _uploadedFileName ?? 'Upload Excel file (.xlsx)',
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
        const SizedBox(height: 40),

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
    );
  }

  // VIEW 2: Success Credentials Presentation Sheet
  Widget _buildSuccessView(Color themeColor) {
    final String fullInviteLink = "https://smartattend.com/join?code=$_generatedCode";

    return Column(
      key: const ValueKey('SuccessView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(Icons.check_circle, color: Color(0xff10b981), size: 64),
        ),
        const SizedBox(height: 16),
        Text(
          '${_classNameController.text} Has Been Created!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff004ce6)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Share the credentials below with your students so they can join this room.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 32),

        // PIN Code Display Group
        const Text(
          'Class Join PIN Code',
          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Text(
                _generatedCode ?? '',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xff004ce6)),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.grey),
                onPressed: () => _copyToClipboard(_generatedCode ?? '', 'PIN copied to clipboard!'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Universal Share Link Display Group
        const Text(
          'Direct Invite Link',
          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  fullInviteLink,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.grey),
                onPressed: () => _copyToClipboard(fullInviteLink, 'Invite link copied to clipboard!'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),

        // Master manual dismiss CTA action
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Done & Close',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}