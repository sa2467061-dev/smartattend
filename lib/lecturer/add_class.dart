import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'roster_parser.dart';
import 'roster_matcher.dart';

String generateClassPin() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  Random random = Random.secure();
  return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
}

class AddClassScreen extends StatefulWidget {
  final String? userId;
  const AddClassScreen({super.key, this.userId});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _classNameController = TextEditingController();
  bool _isLoading = false;
  bool _isParsingFile = false;

  String? _uploadedFileName;
  List<String> _matchedMatrixNumbers = [];
  List<String> _unmatchedMatrixNumbers = [];

  String? _generatedCode;
  bool _isSuccess = false;
  int _enrolledCount = 0;

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  Future<void> _pickRosterFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    setState(() {
      _isParsingFile = true;
      _uploadedFileName = result.files.single.name;
      _matchedMatrixNumbers = [];
      _unmatchedMatrixNumbers = [];
    });

    try {
      final candidates = await RosterParser.extractMatrixNumbers(file);
      final matchResult = await RosterMatcher.matchAgainstStudents(candidates);

      setState(() {
        _matchedMatrixNumbers = matchResult.matched;
        _unmatchedMatrixNumbers = matchResult.unmatched;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read file: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() {
        _uploadedFileName = null;
      });
    } finally {
      if (mounted) setState(() => _isParsingFile = false);
    }
  }

  void _clearRosterFile() {
    setState(() {
      _uploadedFileName = null;
      _matchedMatrixNumbers = [];
      _unmatchedMatrixNumbers = [];
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
      String currentLectId = widget.userId ?? 'DEV_LECT_TEST_ID';
      if (currentLectId.isEmpty) {
        currentLectId = 'DEV_LECT_TEST_ID';
      }

      await FirebaseFirestore.instance.collection('classes').add({
        'name': className,
        'class_code': generatedCode,
        'lect_id': currentLectId,
        'student_count': _matchedMatrixNumbers.length,
        'enrolled_stud': _matchedMatrixNumbers,
      });

      setState(() {
        _generatedCode = generatedCode;
        _enrolledCount = _matchedMatrixNumbers.length;
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
        const SizedBox(height: 4),
        Text(
          'Excel (.xlsx) or CSV file with student matrix numbers. PDF is not supported — please convert to Excel/CSV first.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isParsingFile ? null : _pickRosterFile,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                if (_isParsingFile)
                  const CircularProgressIndicator()
                else
                  Icon(
                    _uploadedFileName == null ? Icons.cloud_upload_outlined : Icons.description_outlined,
                    size: 36,
                    color: _uploadedFileName == null ? Colors.grey : const Color(0xff10b981),
                  ),
                const SizedBox(height: 10),
                Text(
                  _isParsingFile
                      ? 'Reading file...'
                      : _uploadedFileName ?? 'Upload Excel or CSV file',
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

        if (_uploadedFileName != null && !_isParsingFile) ...[
          const SizedBox(height: 12),
          _buildMatchSummary(),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _clearRosterFile,
              child: const Text('Remove file', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],

        const SizedBox(height: 24),

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

  Widget _buildMatchSummary() {
    final matchedCount = _matchedMatrixNumbers.length;
    final unmatchedCount = _unmatchedMatrixNumbers.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.check_circle, size: 16, color: Color(0xff10b981)),
            const SizedBox(width: 6),
            Text('$matchedCount student${matchedCount == 1 ? '' : 's'} will be enrolled',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          if (unmatchedCount > 0) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.error_outline, size: 16, color: Color(0xfff59e0b)),
              const SizedBox(width: 6),
              Text('$unmatchedCount not found / not registered yet',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
            ]),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _unmatchedMatrixNumbers
                  .map((m) => Chip(
                        label: Text(m, style: const TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xfffef3c7),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
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
        Text(
          _enrolledCount > 0
              ? '$_enrolledCount student${_enrolledCount == 1 ? '' : 's'} auto-enrolled from your roster file.'
              : 'Share the credentials below with your students so they can join this room.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 32),

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