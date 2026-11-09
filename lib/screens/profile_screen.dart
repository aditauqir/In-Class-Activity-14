import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/phosphor_icons.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService authService;

  ProfileScreen({
    super.key,
    AuthService? authService,
  }) : authService = authService ?? AuthService();

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _newPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _bioController = TextEditingController();

  final _passwordFormKey = GlobalKey<FormState>();

  bool _isUpdatingPassword = false;
  bool _isSavingBio = false;
  bool _obscureNewPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _currentPasswordController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.white,
            ),
          ),
          backgroundColor: isError ? Colors.red.shade700 : Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }}

  Future<void> _handlePasswordUpdate() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final newPassword = _newPasswordController.text;

    setState(() {
      _isUpdatingPassword = true;
    });

    try {
      await widget.authService.changePassword(newPassword);
      _newPasswordController.clear();
      _showSnackBar('Password updated successfully!');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          _promptReauthentication(newPassword);
        }
      } else if (e.code == 'weak-password') {
        _showSnackBar('The new password is too weak (min 6 chars).', isError: true);
      } else {
        _showSnackBar(e.message ?? 'Failed to update password.', isError: true);
      }
    } catch (e) {
      _showSnackBar('An unexpected error occurred while updating password.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
        });
      }
    }
  }

  Future<void> _promptReauthentication(String newPassword) async {
    _currentPasswordController.clear();
    bool obscureCurrent = true;

    final bool? reauthSuccess = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Recent Sign-In Required',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.normal),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For security, verify current password before changing.',
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: obscureCurrent,
                    style: GoogleFonts.outfit(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: GoogleFonts.outfit(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: PhosphorIcon(
                          obscureCurrent ? PhosphorIcon.eyeSlash : PhosphorIcon.eye,
                          size: 22,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureCurrent = !obscureCurrent;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _currentPasswordController.clear();
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: Colors.black54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Confirm & Update',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (reauthSuccess == true) {
      final currentPassword = _currentPasswordController.text;
      _currentPasswordController.clear();

      if (currentPassword.isEmpty) {
        _showSnackBar('Current password required to re-authenticate.', isError: true);
        return;
      }

      setState(() {
        _isUpdatingPassword = true;
      });

      try {
        await widget.authService.reauthenticateAndChangePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        _newPasswordController.clear();
        _showSnackBar('Re-authenticated and password updated successfully!');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _showSnackBar('Incorrect current password. Cancelled.', isError: true);
        } else {
          _showSnackBar(e.message ?? 'Re-authentication failed.', isError: true);
        }
      } catch (e) {
        _showSnackBar('Failed to update password after re-authentication.', isError: true);
      } finally {
        if (mounted) {
          setState(() {
            _isUpdatingPassword = false;
          });
        }
      }
    } else {
      _showSnackBar('Password update cancelled. Recent login required.', isError: true);
    }
  }

  Future<void> _handleSaveBio() async {
    final bio = _bioController.text.trim();
    if (bio.isEmpty) return;

    setState(() {
      _isSavingBio = true;
    });

    try {
      await widget.authService.updateUserBio(bio);
      _bioController.clear();
      _showSnackBar('User profile saved to Firestore (users/{uid})!');
    } catch (e) {
      _showSnackBar('Firestore error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSavingBio = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final email = user?.email ?? 'Unknown Email';
    final uid = user?.uid ?? 'Unknown UID';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const PhosphorIcon(
                        PhosphorIcon.identificationBadge,
                        size: 38,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'My Profile',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.grey.shade100,
                        child: const PhosphorIcon(
                          PhosphorIcon.identificationBadge,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'UID: $uid',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  const SizedBox(height: 24),

                  Form(
                    key: _passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const PhosphorIcon(PhosphorIcon.lock, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Update Password',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter new pass (min 6 chars). Recent sign-in checked automatically.',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            labelStyle: GoogleFonts.outfit(fontSize: 13),
                            hintText: 'Enter new password',
                            hintStyle: GoogleFonts.outfit(fontSize: 13),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: PhosphorIcon(PhosphorIcon.lock, size: 20, color: Colors.black54),
                            ),
                            suffixIcon: IconButton(
                              icon: PhosphorIcon(
                                _obscureNewPassword ? PhosphorIcon.eyeSlash : PhosphorIcon.eye,
                                size: 20,
                                color: Colors.black54,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.black, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'New password is required';
                            } else {
                              if (val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            }},
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isUpdatingPassword ? null : _handlePasswordUpdate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: _isUpdatingPassword
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Update Password',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  const SizedBox(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const PhosphorIcon(PhosphorIcon.shieldCheck, color: Colors.black, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Data Warden: users/{uid}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Protected data layer gated by request.auth.uid == uid.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: widget.authService.getUserDataStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else {
                            final data = snapshot.data?.data();
                            final currentBio = data?['bio'] ?? 'No bio set yet.';
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                'Profile Note: $currentBio',
                                style: GoogleFonts.outfit(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }},
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _bioController,
                              style: GoogleFonts.outfit(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Enter student note...',
                                hintStyle: GoogleFonts.outfit(fontSize: 13),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.black, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _isSavingBio ? null : _handleSaveBio,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              elevation: 0,
                            ),
                            child: _isSavingBio
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Save',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.normal),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await widget.authService.signOut();
                      },
                      icon: const PhosphorIcon(PhosphorIcon.signOut, size: 20, color: Colors.red),
                      label: Text(
                        'Sign Out of Account',
                        style: GoogleFonts.outfit(
                          color: Colors.red,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
