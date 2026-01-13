import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

/// Shimmer loader that exactly matches JobDetailsScreen structure
/// Mirrors the actual job details UI components with proper content reflection
class JobDetailsShimmer extends StatelessWidget {
  const JobDetailsShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action buttons shimmer
            _buildActionButtonsShimmer(context),

            // Hero Card - Job Header shimmer
            _buildJobHeaderCardShimmer(context),

            const SizedBox(height: 16),

            // Job Info Card shimmer
            _buildJobInfoCardShimmer(context),

            const SizedBox(height: 16),

            // Job Statistics Card shimmer
            _buildJobStatsCardShimmer(context),

            const SizedBox(height: 16),

            // Specialties Card shimmer
            _buildSpecialtiesCardShimmer(context),

            const SizedBox(height: 16),

            // Description Card shimmer
            _buildDescriptionCardShimmer(context),

            const SizedBox(height: 16),

            // User Info Card shimmer
            _buildUserInfoCardShimmer(context),

            const SizedBox(height: 16),

            // Action Buttons Card shimmer
            _buildActionButtonsCardShimmer(context),
          ],
        ),
      ),
    );
  }

  Color _getBaseColor(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? theme.surfaceVariant.withOpacity(0.3) : Colors.grey[300]!;
  }

  Color _getHighlightColor(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? theme.surfaceVariant.withOpacity(0.5) : Colors.grey[100]!;
  }

  // ignore: unused_element
  Color _getShimmerColor(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? theme.surfaceVariant.withOpacity(0.4) : Colors.grey[300]!;
  }

  Widget _buildActionButtonsShimmer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Shimmer.fromColors(
            baseColor: _getBaseColor(context),
            highlightColor: _getHighlightColor(context),
            child: Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobHeaderCardShimmer(context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[400]!, Colors.grey[500]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.6),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Title Row with Sponsored Badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job Title - Variable width to simulate real titles
                        Container(
                          height: 24,
                          width: 75.w, // Realistic job title width
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Second line for longer titles
                        Container(
                          height: 20,
                          width: 45.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sponsored Badge Placeholder
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 60,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Company Name Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 18,
                      width: 60.w, // Realistic company name width
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Location Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 16,
                      width: 50.w, // Realistic location width
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Salary Range Row (conditional)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 16,
                      width: 40.w, // Realistic salary range width
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobInfoCardShimmer(context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Shimmer.fromColors(
        baseColor: _getBaseColor(context),
        highlightColor: _getHighlightColor(context),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Title - "Job Details"
              Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              // Experience Row
              _buildInfoRowShimmer(
                iconSize: 16,
                titleWidth: 80, // "Experience"
                valueWidth: 65.w, // Realistic experience description
              ),
              const SizedBox(height: 20),
              // Preferred Language Row
              _buildInfoRowShimmer(
                iconSize: 16,
                titleWidth: 120, // "Preferred Language"
                valueWidth: 35.w, // Language name
              ),
              const SizedBox(height: 20),
              // Number of Jobs Row
              _buildInfoRowShimmer(
                iconSize: 16,
                titleWidth: 100, // "Number of Jobs"
                valueWidth: 25.w, // Job count
              ),
              const SizedBox(height: 20),
              // Divider
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 20),
              // Apply Date Section Title
              Container(
                width: 100,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              // Date From & Date To Row
              Row(
                children: [
                  Expanded(child: _buildDateInfoShimmer(isFromDate: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateInfoShimmer(isFromDate: false)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRowShimmer({
    required double iconSize,
    required double titleWidth,
    required double valueWidth,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Circle - matching actual component design
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors
                .grey[200], // Light background like actual blue.withOpacity(0.1)
            shape: BoxShape.circle,
          ),
          child: Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: Colors.grey[400], // Icon placeholder
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title (Experience, Language, etc.)
              Container(
                width: titleWidth,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 4),
              // Value with realistic width variation
              Container(
                width: valueWidth,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfoShimmer({required bool isFromDate}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Label (Date From / Date To)
        Container(
          width: isFromDate ? 70 : 60, // "Date From" vs "Date To"
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // Date Icon with colored background
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isFromDate
                    ? Colors.blue.withOpacity(0.1) // Blue for start date
                    : Colors.red.withOpacity(0.1), // Red for end date (expired)
                shape: BoxShape.circle,
              ),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isFromDate ? Colors.blue[300] : Colors.red[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 14,
                width: isFromDate ? 70 : 65, // Different widths for dates
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJobStatsCardShimmer(context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Shimmer.fromColors(
        baseColor: _getBaseColor(context),
        highlightColor: _getHighlightColor(context),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Job Statistics" title
              Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItemShimmer(
                      color: Colors.blue,
                      value: "120", // Views count simulation
                      label: "Views",
                    ),
                  ),
                  Expanded(
                    child: _buildStatItemShimmer(
                      color: Colors.green,
                      value: "45", // Clicks count simulation
                      label: "Clicks",
                    ),
                  ),
                  Expanded(
                    child: _buildStatItemShimmer(
                      color: Colors.orange,
                      value: "12", // Applicants count simulation
                      label: "Applicants",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItemShimmer({
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(
          0.1,
        ), // Colored background matching actual design
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Circular icon container with color
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color, // Actual color like the real component
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8), // Icon placeholder
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Value (number) with realistic width
          Container(
            width: value.length * 10.0, // Dynamic width based on value length
            height: 18,
            decoration: BoxDecoration(
              color: color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          // Label with realistic width
          Container(
            width: label.length * 6.0, // Dynamic width based on label length
            height: 12,
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesCardShimmer(context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Shimmer.fromColors(
        baseColor: _getBaseColor(context),
        highlightColor: _getHighlightColor(context),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row with Medical Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(
                        0.1,
                      ), // Purple theme for medical
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.purple[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 150, // "Medical Specialties"
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Specialty Chips with realistic medical specialty lengths
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSpecialtyChipShimmer(width: 80), // "Cardiology"
                  _buildSpecialtyChipShimmer(width: 95), // "Neurology"
                  _buildSpecialtyChipShimmer(width: 110), // "Internal Medicine"
                  _buildSpecialtyChipShimmer(width: 75), // "Surgery"
                  _buildSpecialtyChipShimmer(width: 90), // "Pediatrics"
                  _buildSpecialtyChipShimmer(
                    width: 105,
                  ), // "Emergency Medicine"
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyChipShimmer({required double width}) {
    return Container(
      width: width,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1), // Purple theme matching actual
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.5),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildDescriptionCardShimmer(context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Shimmer.fromColors(
        baseColor: _getBaseColor(context),
        highlightColor: _getHighlightColor(context),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row with Description Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(
                        0.1,
                      ), // Teal theme like actual
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.teal[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 100, // "Description"
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description Content - Realistic paragraph structure
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First paragraph
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 75.w, // Partial line
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Second paragraph
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60.w, // Shorter paragraph ending
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Requirements list simulation
                  Container(
                    width: 85.w,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80.w,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Show More/Less Button
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.teal[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 80, // "Show More"
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.teal[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCardShimmer(context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Shimmer.fromColors(
        baseColor: _getBaseColor(context),
        highlightColor: _getHighlightColor(context),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row with Person Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(
                        0.1,
                      ), // Indigo theme like actual
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.indigo[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 80, // "Posted By"
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // User Info Row
              Row(
                children: [
                  // Profile Picture with Border
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.indigo.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Name
                        Container(
                          width: 45.w, // Realistic name width
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // "Job Poster" subtitle
                        Container(
                          width: 80,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtonsCardShimmer(context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Shimmer.fromColors(
        baseColor: _getBaseColor(context),
        highlightColor: _getHighlightColor(context),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row with Action Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(
                        0.1,
                      ), // Green theme like actual
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 80, // "Actions"
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Main Action Buttons Row
              Row(
                children: [
                  // Apply Button
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(
                          0.8,
                        ), // Blue for apply button
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 40, // "Apply"
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Visit Site Button
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 60, // "Visit Site"
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // View Applicants Button (for job owners)
              Container(
                width: double.infinity,
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(
                    0.8,
                  ), // Green for view applicants
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 120, // "View Applicants"
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
