import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

class JobCardWidget extends StatelessWidget {
  final dynamic jobData; // Replace 'dynamic' with the actual model type
  final int selectedIndex;
  final VoidCallback onJobTap;
  final VoidCallback onShareTap;
  final Function(String) onApplyTap;
  final Function(Uri) onLaunchLink;

  const JobCardWidget({
    Key? key,
    required this.jobData,
    required this.selectedIndex,
    required this.onJobTap,
    required this.onShareTap,
    required this.onApplyTap,
    required this.onLaunchLink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onJobTap,
      child: Container(
        margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10,),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedIndex == 0 ? "New" : "Expired",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        if (jobData.promoted != 0)
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.orangeAccent,
                            ),
                            child: const Text(
                              'Sponsored',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        const SizedBox(width: 10),
                        if (jobData.user?.id != null)
                          MaterialButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            color: Colors.blue,
                            splashColor: Colors.blue,
                            highlightColor: Colors.green,
                            onPressed: () => onApplyTap(jobData.id.toString()),
                            child: const Text(
                              "Apply",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        const SizedBox(width: 20),
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: onShareTap,
                          child: Icon(
                            Icons.share_sharp,
                            size: 22,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  jobData.jobTitle ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  jobData.companyName ?? 'N/A',
                  style: const TextStyle(color: Colors.black,fontSize: 18),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 20,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        jobData.location ?? 'N/A',
                        style: const TextStyle(color: Colors.black,fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Apply Date',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildDateColumn(
                      title: 'Date From',
                      date: jobData.createdAt,
                    ),
                    const SizedBox(width: 20),
                    _buildDateColumn(
                      title: 'Date To',
                      date: jobData.lastDate,
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Text(
                  'Experience: ${jobData.experience ?? 'N/A'}',
                  style: const TextStyle(color: Colors.black,fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  'Preferred Language: ${jobData.preferredLanguage ?? 'N/A'}',
                  style: const TextStyle(color: Colors.black,fontSize: 16),
                ),
                const SizedBox(height: 5),
                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: HtmlWidget('<p>${jobData.description}</p>'),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: () async {
                      final Uri url = Uri.parse(jobData.link ?? '');
                      final shouldLeave = await _showConfirmationDialog(context);
                      if (shouldLeave == true) {
                        onLaunchLink(url);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Leaving the app canceled.'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Visit Site',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateColumn({required String title, required String? date}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
        Row(
          children: [
            const Icon(Icons.date_range_outlined, size: 20, color: Colors.black),
            const SizedBox(width: 5),
            Text(
              date != null
                  ? DateFormat('MMM dd, yyyy').format(DateTime.parse(date))
                  : 'N/A',
              style: const TextStyle(color: Colors.black,fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave App'),
        content: const Text('Would you like to leave the app to view this content?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
