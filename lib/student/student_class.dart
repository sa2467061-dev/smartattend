import 'package:flutter/material.dart';

class StudentClassScreen extends StatefulWidget {
  final VoidCallback? onProfilePressed; // Pass this from your parent dashboard if needed

  const StudentClassScreen({super.key, this.onProfilePressed});

  @override
  State<StudentClassScreen> createState() => _StudentClassScreenState();
}

class _StudentClassScreenState extends State<StudentClassScreen> {
  // 0 for PIN, 1 for Link
  int _selectedJoinType = 0; 
  final TextEditingController _inputController = TextEditingController();

  void _showAddClassBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to push up when keyboard opens
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add New Class',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Toggle Slider between PIN and Link
                  Center(
                    child: ToggleButtons(
                      direction: Axis.horizontal,
                      onPressed: (int index) {
                        setModalState(() {
                          _selectedJoinType = index;
                          _inputController.clear(); // Clear input on switch
                        });
                      },
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      selectedBorderColor: const Color(0xff004ce6),
                      selectedColor: Colors.white,
                      fillColor: const Color(0xff004ce6),
                      color: Colors.grey.shade700,
                      constraints: BoxConstraints(
                        minWidth: (MediaQuery.of(context).size.width - 64) / 2,
                        minHeight: 40.0,
                      ),
                      isSelected: [_selectedJoinType == 0, _selectedJoinType == 1],
                      children: const [
                        Text('Use PIN', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('Use Link', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Conditional Input field based on choice
                  TextField(
                    controller: _inputController,
                    keyboardType: _selectedJoinType == 0 ? TextInputType.number : TextInputType.url,
                    decoration: InputDecoration(
                      labelText: _selectedJoinType == 0 ? 'Enter Class PIN' : 'Enter Class Invite Link',
                      hintText: _selectedJoinType == 0 ? 'e.g., 123456' : 'https://smartattend.com/join/...',
                      prefixIcon: Icon(_selectedJoinType == 0 ? Icons.pin : Icons.link),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xff004ce6), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Button
                  ElevatedButton(
                    onPressed: () {
                      // Handle joining logic here
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff004ce6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Join Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: Row(
          children: const [
            Icon(Icons.domain_verification, color: Color(0xff004ce6), size: 28),
            SizedBox(width: 8),
            Text(
              'SMARTATTEND',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: widget.onProfilePressed,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xff004ce6),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 3, 
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            elevation: 0,
            color: const Color(0xfff9fafb),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xff004ce6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.class_outlined, color: Color(0xff004ce6)),
              ),
              title: Text(
                index == 0 
                    ? 'Mobile Application Development' 
                    : index == 1 
                        ? 'Data Science Fundamental' 
                        : 'Object-Oriented Programming',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text('Room 302 • Mon & Wed (10:00 AM)', style: TextStyle(fontSize: 13)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            ),
          );
        },
      ),
      
      // Floating Action Button positioned at the bottom left corner
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassBottomSheet,
        backgroundColor: const Color(0xff004ce6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
    );
  }
}