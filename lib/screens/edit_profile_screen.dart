import 'dart:io';
import 'package:cublink/providers/student_provider.dart'; 
import 'package:cublink/providers/theme_provider.dart'; // 🔥 NEEDED FOR THEME
import 'package:cublink/widgets/background_wave_painter.dart'; // 🔥 NEEDED FOR WAVES
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _guardianController;
  late TextEditingController _phoneController;
  
  File? _pickedImage; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<StudentProvider>(context, listen: false);
    _nameController = TextEditingController(text: provider.studentName);
    _guardianController = TextEditingController(text: provider.guardianName);
    _phoneController = TextEditingController(text: provider.emergencyContact);
  }

  void _showImagePickerOptions(BuildContext context) {
    // Grab theme for the bottom sheet
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E2D2A) : Colors.white, // DYNAMIC
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: isDark ? const Color(0xFF5BE2AA) : Colors.blue),
                title: Text('Pick from Gallery', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: isDark ? const Color(0xFF5BE2AA) : Colors.green),
                title: Text('Take a Photo', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              Consumer<StudentProvider>(
                builder: (context, student, child) {
                  if (_pickedImage != null || student.profileImageUrl.isNotEmpty) {
                    return ListTile(
                      leading: const Icon(Icons.delete, color: Colors.redAccent),
                      title: Text('Remove Photo', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
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

  Future<void> _removePhoto() async {
    setState(() {
      _pickedImage = null;
    });

    try {
      await Provider.of<StudentProvider>(context, listen: false).removeProfileImage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile photo removed")),
        );
      }
    } catch (e) {
      debugPrint("Error removing photo: $e");
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

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
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true, // 🔥 Let gradient flow behind AppBar
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, // DYNAMIC
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color, // DYNAMIC
      ),
      body: Stack(
        children: [
          // 1. DYNAMIC BACKGROUND GRADIENT
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                  ? [const Color(0xFF121A18), const Color(0xFF1E2D2A)] 
                  : [const Color(0xFFD7FBEA), const Color(0xFFE0F2F1)],
              ),
            ),
          ),
          
          // 2. DYNAMIC WAVES
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundWavePainter(
                waveColor: isDark 
                  ? Colors.white.withOpacity(0.03) 
                  : Colors.white.withOpacity(0.5),
              ),
            )
          ),

          // 3. FOREGROUND CONTENT
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // --- PROFILE IMAGE AVATAR ---
                  GestureDetector(
                    onTap: () => _showImagePickerOptions(context), 
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black45 : Colors.black12,
                                blurRadius: 15,
                                spreadRadius: 5,
                              )
                            ]
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: isDark ? const Color(0xFF121A18) : Colors.white,
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : (provider.profileImageUrl.isNotEmpty
                                    ? NetworkImage(provider.profileImageUrl) as ImageProvider
                                    : null),
                            child: (_pickedImage == null && provider.profileImageUrl.isEmpty)
                                ? Icon(Icons.person, size: 60, color: isDark ? Colors.white54 : Colors.grey)
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? Theme.of(context).colorScheme.primary : Colors.black, // DYNAMIC
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF1E2D2A) : Colors.white, width: 3),
                          ),
                          child: Icon(Icons.camera_alt, color: isDark ? Colors.black : Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // --- TEXT FIELDS ---
                  _buildTextField("Student Name", _nameController, Icons.person, isDark),
                  const SizedBox(height: 20),
                  _buildTextField("Guardian Name", _guardianController, Icons.family_restroom, isDark),
                  const SizedBox(height: 20),
                  _buildTextField("Emergency Phone", _phoneController, Icons.phone, isDark),
                  
                  const SizedBox(height: 50),

                  // --- SAVE BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Theme.of(context).colorScheme.primary : const Color(0xFF5BE2AA), 
                        foregroundColor: Colors.black,
                        elevation: 5,
                        shadowColor: isDark ? Theme.of(context).colorScheme.primary.withOpacity(0.4) : const Color(0xFF5BE2AA).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)
                        )
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Field matched to your Theme Logic
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // DYNAMIC
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5)
          )
        ]
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color), 
        decoration: InputDecoration(
          filled: false,
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontWeight: FontWeight.bold),
          prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}