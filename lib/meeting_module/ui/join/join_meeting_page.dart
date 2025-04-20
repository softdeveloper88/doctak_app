import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/meeting/meeting_bloc.dart';
import '../../bloc/meeting/meeting_event.dart';
import '../../bloc/meeting/meeting_state.dart';
import '../../utils/constants.dart';
import '../meeting/meeting_page.dart';

class JoinMeetingPage extends StatefulWidget {
  const JoinMeetingPage({Key? key}) : super(key: key);

  @override
  State<JoinMeetingPage> createState() => _JoinMeetingPageState();
}

class _JoinMeetingPageState extends State<JoinMeetingPage> with SingleTickerProviderStateMixin {
  final TextEditingController _meetingCodeController = TextEditingController();
  final TextEditingController _meetingTitleController = TextEditingController();
  late TabController _tabController;
  bool _showNewMeeting = false;
  bool _isScheduling = false;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = TimeOfDay.now();
  int _durationMinutes = 60;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _meetingCodeController.dispose();
    _meetingTitleController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.videocam), text: 'Join/Create'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Scheduled'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.video_library), text: 'Recordings'),
          ],
        ),
      ),
      body: BlocListener<MeetingBloc, MeetingState>(
        listener: (context, state) {
          if (state is MeetingCreated) {
            // Navigate to the meeting page
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MeetingPage(
                  meetingId: state.meeting.id,
                  userId: state.meeting.userId,
                  meetingCode: state.meeting.meetingChannel,
                  isHost: true,
                ),
              ),
            );
          } else if (state is MeetingJoined) {
            // Navigate to the meeting page
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MeetingPage(
                  meetingId: state.meeting.id,
                  userId: '123', // In a real app, this would be the current user's ID
                  meetingCode: state.meeting.meetingChannel,
                  isHost: state.meeting.userId == '123', // Check if current user is host
                ),
              ),
            );
          } else if (state is MeetingError) {
            // Show error snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: kDangerColor,
              ),
            );
          } else if (state is MeetingJoinRequested) {
            // Show a waiting dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const AlertDialog(
                title: Text('Waiting for Approval'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Waiting for the host to admit you to the meeting...'),
                  ],
                ),
              ),
            );
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            // Join/Create Tab
            _buildJoinCreateTab(),

            // Scheduled Tab
            _buildScheduledTab(),

            // History Tab
            _buildHistoryTab(),

            // Recordings Tab
            _buildRecordingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Join/Create card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _showNewMeeting
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: _buildJoinMeetingView(),
                secondChild: _buildCreateMeetingView(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Feature cards
          const Text(
            'Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildFeatureCard(
                icon: Icons.hd,
                title: 'HD Video',
                description: 'High quality video & audio for clear communication',
              ),
              _buildFeatureCard(
                icon: Icons.people,
                title: 'Unlimited Participants',
                description: 'Host meetings with any number of participants',
              ),
              _buildFeatureCard(
                icon: Icons.screen_share,
                title: 'Screen Sharing',
                description: 'Share your screen with meeting participants',
              ),
              _buildFeatureCard(
                icon: Icons.chat,
                title: 'Group Chat',
                description: 'Send messages to everyone during the meeting',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinMeetingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.login, color: kPrimaryColor),
            const SizedBox(width: 8),
            const Text(
              'Join Meeting',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _showNewMeeting = true;
                });
              },
              child: const Text('Create Instead'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the meeting code provided by the host to join an existing meeting.',
          style: TextStyle(color: kSecondaryColor),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _meetingCodeController,
          decoration: InputDecoration(
            labelText: 'Meeting Code',
            hintText: 'Enter meeting code',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: const Icon(Icons.meeting_room),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final code = _meetingCodeController.text.trim();
            if (code.isNotEmpty) {
              context.read<MeetingBloc>().add(JoinMeetingEvent(code));
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Join Meeting'),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'or',
            style: TextStyle(color: kSecondaryColor),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            // Open camera to scan QR code
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('QR code scanning would be implemented here'),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner),
              SizedBox(width: 8),
              Text('Scan QR Code'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateMeetingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.add_box, color: kPrimaryColor),
            const SizedBox(width: 8),
            const Text(
              'Create Meeting',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _showNewMeeting = false;
                });
              },
              child: const Text('Join Instead'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Create a new meeting and invite participants to join.',
          style: TextStyle(color: kSecondaryColor),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _meetingTitleController,
          decoration: InputDecoration(
            labelText: 'Meeting Title (Optional)',
            hintText: 'Enter meeting title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: const Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isScheduling
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final title = _meetingTitleController.text.trim();
                    context.read<MeetingBloc>().add(CreateMeetingEvent(meetingTitle: title));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Start Instant Meeting'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isScheduling = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Schedule'),
                ),
              ),
            ],
          ),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(
                          '${_scheduledTime.hour}:${_scheduledTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _durationMinutes,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.timelapse),
                ),
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 minutes')),
                  DropdownMenuItem(value: 60, child: Text('1 hour')),
                  DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                  DropdownMenuItem(value: 120, child: Text('2 hours')),
                ],
                onChanged: (value) {
                  setState(() {
                    _durationMinutes = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isScheduling = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Schedule meeting
                        setState(() {
                          _isScheduling = false;
                        });
                        _showScheduleSuccessDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Schedule Meeting'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: kPrimaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: kSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledTab() {
    // Sample scheduled meetings
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Scheduled Meetings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  _showNewMeeting = true;
                  _isScheduling = true;
                  _tabController.animateTo(0); // Switch to first tab
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: true,
                onSelected: (selected) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Today'),
                selected: false,
                onSelected: (selected) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Upcoming'),
                selected: false,
                onSelected: (selected) {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sample upcoming meeting
        _buildMeetingCard(
          title: 'Weekly Team Consultation',
          date: DateTime.now().add(const Duration(days: 1)),
          isActive: false,
          isCompleted: false,
        ),

        // Sample active meeting
        _buildMeetingCard(
          title: 'Emergency Response Planning',
          date: DateTime.now(),
          isActive: true,
          isCompleted: false,
        ),

        // Sample completed meeting
        _buildMeetingCard(
          title: 'Patient Consultation Workshop',
          date: DateTime.now().subtract(const Duration(days: 2)),
          isActive: false,
          isCompleted: true,
        ),
      ],
    );
  }

  Widget _buildMeetingCard({
    required String title,
    required DateTime date,
    required bool isActive,
    required bool isCompleted,
  }) {
    final now = DateTime.now();
    final isUpcoming = date.isAfter(now) && !isActive;

    String status;
    Color statusColor;
    if (isActive) {
      status = 'In Progress';
      statusColor = kSuccessColor;
    } else if (isCompleted) {
      status = 'Completed';
      statusColor = kSecondaryColor;
    } else {
      status = 'Upcoming';
      statusColor = kPrimaryColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (isActive) {
            // Join the active meeting
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Joining active meeting...'),
              ),
            );
          } else if (isUpcoming) {
            // Show meeting details
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Showing upcoming meeting details...'),
              ),
            );
          } else {
            // Show completed meeting details
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Showing completed meeting details...'),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: kSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(color: kSecondaryColor),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 14, color: kSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: kSecondaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (isActive)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Join meeting
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccessColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Join Now'),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // View details
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                  if (!isCompleted)
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 20),
                              SizedBox(width: 8),
                              Text('Share'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, size: 20, color: kDangerColor),
                              SizedBox(width: 8),
                              Text('Cancel Meeting', style: TextStyle(color: kDangerColor)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        // Handle selection
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    // Sample meeting history
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Meeting History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Open search
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Past meetings
        _buildHistoryCard(
          title: 'Quarterly Medical Review',
          date: DateTime.now().subtract(const Duration(days: 15)),
          duration: const Duration(hours: 1, minutes: 30),
          participants: 8,
          hasRecording: true,
        ),

        _buildHistoryCard(
          title: 'Patient Consultation Workshop',
          date: DateTime.now().subtract(const Duration(days: 30)),
          duration: const Duration(hours: 2, minutes: 15),
          participants: 12,
          hasRecording: false,
        ),
      ],
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required DateTime date,
    required Duration duration,
    required int participants,
    required bool hasRecording,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Show meeting details
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Showing meeting details...'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: kSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(color: kSecondaryColor),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 14, color: kSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                    style: const TextStyle(color: kSecondaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people, size: 14, color: kSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '$participants participants',
                    style: const TextStyle(color: kSecondaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  if (hasRecording)
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_circle_outline, size: 16),
                      label: const Text('View Recording'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
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

  Widget _buildRecordingsTab() {
    // Sample recordings
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return _buildRecordingCard(
          title: 'Medical Conference ${index + 1}',
          date: DateTime.now().subtract(Duration(days: (index + 1) * 10)),
          duration: Duration(minutes: 30 + (index * 15)),
        );
      },
    );
  }

  Widget _buildRecordingCard({
    required String title,
    required DateTime date,
    required Duration duration,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with play button
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.black,
                  child: const Icon(
                    Icons.video_library,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 48,
                    ),
                    onPressed: () {
                      // Play recording
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Playing recording...'),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${duration.inHours > 0 ? '${duration.inHours}:' : ''}${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Recording info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: kSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hd, size: 16, color: kPrimaryColor),
                          SizedBox(width: 4),
                          Text(
                            'HD',
                            style: TextStyle(
                              fontSize: 12,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download, size: 20),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, size: 20),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () {},
                        ),
                      ],
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null && picked != _scheduledTime) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  void _showScheduleSuccessDialog() {
    final meetingDate = '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}';
    final meetingTime = '${_scheduledTime.hour}:${_scheduledTime.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: kSuccessColor),
            SizedBox(width: 8),
            Text('Meeting Scheduled'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your meeting has been scheduled successfully.'),
            const SizedBox(height: 16),
            const Text(
              'Meeting Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Title', _meetingTitleController.text),
            _buildDetailRow('Date', meetingDate),
            _buildDetailRow('Time', meetingTime),
            _buildDetailRow('Duration', '$_durationMinutes minutes'),
            const SizedBox(height: 16),
            const Text(
              'Meeting Code:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kLightColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ABC-123-XYZ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: kPrimaryColor),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'ABC-123-XYZ'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Meeting code copied to clipboard'),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Show share options
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing meeting details...'),
                ),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: kSecondaryColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}