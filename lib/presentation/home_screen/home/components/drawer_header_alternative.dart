import 'package:flutter/material.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'dart:math' as math;

/// Alternative drawer header with better positioning control
class DrawerHeaderAlternative extends StatelessWidget {
  const DrawerHeaderAlternative({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280, // Fixed height for better control
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFF), Color(0xFFEEF4FF), Color(0xFFE0ECFF), Color(0xFFD4E5FF)],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4285F4), Color(0xFF1A73E8), Color(0xFF1557B0)]),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: const Color(0xFF4285F4).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: 2)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: AppCachedNetworkImage(
                    imageUrl: AppData.imageUrl + AppData.profile_pic,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF1A73E8)]),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(AppData.name),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF1A73E8)]),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(AppData.name),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // User Name
              Text(
                AppData.userType == 'doctor' ? 'Dr. ${capitalizeWords(AppData.name)}' : capitalizeWords(AppData.name),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A365D), fontFamily: 'Poppins', letterSpacing: 0.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Specialty/Role
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF4285F4).withValues(alpha: 0.3), width: 1),
                  boxShadow: [BoxShadow(color: const Color(0xFF4285F4).withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Text(
                  AppData.userType == 'doctor'
                      ? AppData.specialty
                      : AppData.userType == 'student'
                      ? '${AppData.university} ${translation(context).lbl_student}'
                      : AppData.specialty,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4285F4), fontFamily: 'Poppins', letterSpacing: 0.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, math.min(2, name.length)).toUpperCase();
    }
  }
}
