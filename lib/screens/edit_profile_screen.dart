import 'dart:io';
import 'package:cublink/providers/student_provider.dart'; // Make sure this path is correct
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers for text fields
  late TextEditingController _nameController;
  late TextEditingController _guardianController;
  late TextEditingController _phoneController;
  
  File? _pickedImage; // To store the image locally before uploading
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. Grab current data from Provider to pre-fill the fields
    final provider = Provider.of<StudentProvider>(context, listen: false);
    _nameController = TextEditingController(text: provider.studentName);
    _guardianController = TextEditingController(text: provider.guardianName);
    _phoneController = TextEditingController(text: provider.emergencyContact);
  }

  // --- NEW: THE BOTTOM SHEET OPTION ---
  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              
              // ONLY SHOW REMOVE IF THERE IS AN IMAGE
              Consumer<StudentProvider>(
                builder: (context, student, child) {
                  // Show remove if local image exists OR cloud image exists
                  if (_pickedImage != null || student.profileImageUrl.isNotEmpty) {
                    return ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Remove Photo'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _removePhoto();
                      },
                    );
                  }
                  return const SizedBox.shrink(); 
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Updated Pick Function to accept Source (Camera vs Gallery)
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 800
    );

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  // New Function to Remove Photo
  Future<void> _removePhoto() async {
    // 1. Clear local selection
    setState(() {
      _pickedImage = null;
    });

    // 2. Clear cloud selection via Provider
    // We wrap this in a try-catch just in case
    try {
      await Provider.of<StudentProvider>(context, listen: false).removeProfileImage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile photo removed")),
        );
      }
    } catch (e) {
      print("Error removing photo: $e");
    }
  }

  // Function to Save Changes
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    // Call the Provider to handle the backend logic
    await Provider.of<StudentProvider>(context, listen: false).updateProfile(
      newName: _nameController.text.trim(),
      newGuardian: _guardianController.text.trim(),
      newPhone: _phoneController.text.trim(),
      newImageFile: _pickedImage,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully!")),
      );
      Navigator.pop(context); // Go back to Home
    }
  }

  @override
  Widget build(BuildContext context) {
    // We listen to the provider to show the current profile pic
    final provider = Provider.of<StudentProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- PROFILE IMAGE AVATAR ---
            GestureDetector(
              onTap: () => _showImagePickerOptions(context), // Changed to open options!
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    // LOGIC: Local File -> Cloud URL -> Default Icon
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (provider.profileImageUrl.isNotEmpty
                            ? NetworkImage(provider.profileImageUrl) as ImageProvider
                            : null),
                    child: (_pickedImage == null && provider.profileImageUrl.isEmpty)
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // --- TEXT FIELDS ---
            _buildTextField("Student Name", _nameController, Icons.person),
            const SizedBox(height: 15),
            _buildTextField("Guardian Name", _guardianController, Icons.family_restroom),
            const SizedBox(height: 15),
            _buildTextField("Emergency Phone", _phoneController, Icons.phone),
            
            const SizedBox(height: 40),

            // --- SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}