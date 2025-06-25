import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loader that exactly matches MemoryOptimizedDrugItem structure
class DrugsShimmerLoader extends StatelessWidget {
  const DrugsShimmerLoader({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        final bool hasLongName = index % 2 == 0;
        final bool hasLongManufacturer = index % 2 == 1;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
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
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drug Header
                  _buildDrugHeader(context, hasLongName),
                  
                  // Drug Info
                  _buildDrugInfo(context, hasLongManufacturer),
                  
                  // Action Row
                  _buildActionRow(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Drug header section matching MemoryOptimizedDrugItem
  Widget _buildDrugHeader(BuildContext context, bool hasLongName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drug icon (50x50 with blue background containing DocTak AI image)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Drug names and tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Generic name (maxLines: 2)
                Container(
                  height: 16,
                  width: hasLongName 
                      ? double.infinity 
                      : MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                
                // Trade name (maxLines: 1)
                Container(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Wrap with strength and package size tags
                Row(
                  children: [
                    // Strength tag (blue background)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        width: 40,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Package size tag (green background)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        width: 30,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(2),
                        ),
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

  // Drug info section with manufacturer and price
  Widget _buildDrugInfo(BuildContext context, bool hasLongManufacturer) {
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
          // Manufacturer Info (flex: 6)
          Expanded(
            flex: 6,
            child: Row(
              children: [
                // Business icon
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Manufacturer label
                      Container(
                        height: 12,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Manufacturer name (maxLines: 1)
                      Container(
                        height: 14,
                        width: hasLongManufacturer ? 120 : 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Price Info (blue background with border)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Container(
              width: 30,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action row section
  Widget _buildActionRow(BuildContext context) {
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
          // "Tap for details" text
          Container(
            height: 12,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          // Arrow icon
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}