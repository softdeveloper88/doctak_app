import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Memory-optimized drug item widget with performance improvements
class MemoryOptimizedDrugItem extends StatefulWidget {
  final Data drug;
  final Function(BuildContext, String, String) onShowBottomSheet;

  const MemoryOptimizedDrugItem({
    super.key,
    required this.drug,
    required this.onShowBottomSheet,
  });

  @override
  State<MemoryOptimizedDrugItem> createState() => _MemoryOptimizedDrugItemState();
}

class _MemoryOptimizedDrugItemState extends State<MemoryOptimizedDrugItem> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          _showDialog(context, widget.drug.genericName ?? '');
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drug Header
                _buildDrugHeader(),
                
                // Drug Info
                _buildDrugInfo(),
                
                // Action Row
                _buildActionRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Drug header section
  Widget _buildDrugHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/docktak_ai_light.png',
                height: 30,
                width: 30,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.drug.genericName ?? "",
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.drug.tradeName ?? translation(context).lbl_not_available,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.drug.strength ?? '',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.drug.packageSize ?? '',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Drug info section
  Widget _buildDrugInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Manufacturer Info
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translation(context).lbl_manufacturer_name,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        widget.drug.manufacturerName ?? '',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Price Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.drug.mrp ?? '0',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action row section
  Widget _buildActionRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            translation(context).lbl_tap_for_details,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.blue[600],
          ),
        ],
      ),
    );
  }

  // Show dialog for drug details
  void _showDialog(BuildContext context, String genericName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildDialog(context, genericName);
      },
    );
  }

  // Build dialog widget
  Widget _buildDialog(BuildContext context, String genericName) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header
            _buildDialogHeader(context, genericName),
            
            // Dialog Content
            _buildDialogContent(context, genericName),
            
            // Dialog Footer
            _buildDialogFooter(context),
          ],
        ),
      ),
    );
  }

  // Dialog header
  Widget _buildDialogHeader(BuildContext context, String genericName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication_outlined,
              color: Colors.blue[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              genericName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog content
  Widget _buildDialogContent(BuildContext context, String genericName) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Text(
              translation(context).lbl_select_option_to_learn,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildQuestion(
              context, 
              translation(context).lbl_all_information, 
              genericName,
              "icInfo",
              Icons.info_outline,
              Colors.blue[700]!,
              clickable: true
            ),
            _buildQuestion(
              context, 
              translation(context).lbl_mechanism, 
              genericName,
              "icMechanisam",
              Icons.settings_outlined,
              Colors.purple[700]!,
              clickable: true
            ),
            _buildQuestion(
              context, 
              translation(context).lbl_indications, 
              genericName,
              "icIndication",
              Icons.assignment_outlined,
              Colors.green[700]!,
              clickable: true
            ),
            _buildQuestion(
              context, 
              translation(context).lbl_dosage, 
              genericName,
              "icDosage",
              Icons.access_time_filled_outlined,
              Colors.orange[700]!,
              clickable: true
            ),
            _buildQuestion(
              context, 
              translation(context).lbl_drug_interactions, 
              genericName,
              "icDrug",
              Icons.compare_arrows_outlined,
              Colors.red[700]!,
              clickable: true
            ),
            _buildQuestion(
              context, 
              translation(context).lbl_special_populations, 
              genericName,
              "icSpecial",
              Icons.people_outline,
              Colors.teal[700]!,
              clickable: true
            ),
            _buildQuestion(
              context, 
              translation(context).lbl_side_effects, 
              genericName,
              "icSideEffect",
              Icons.report_problem_outlined,
              Colors.amber[700]!,
              clickable: true
            ),
          ],
        ),
      ),
    );
  }

  // Dialog footer
  Widget _buildDialogFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop('dialog');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.close, size: 18),
            const SizedBox(width: 8),
            Text(
              translation(context).lbl_close,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Question item widget
  Widget _buildQuestion(
    BuildContext context, 
    String question, 
    String genericName, 
    String iconAsset,
    IconData iconData,
    Color iconColor,
    {bool clickable = false}
  ) {
    return GestureDetector(
      onTap: clickable
          ? () {
              widget.onShowBottomSheet(context, genericName, question);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: iconColor,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16.0,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}