# DocTak.net - Google Play Video Demonstration Guide

## App Overview
**DocTak.net** is a comprehensive medical professional social networking and communication platform that enables healthcare professionals worldwide to connect, collaborate, learn, and advance their medical practice through real-time communication and knowledge sharing.

---

## 🎯 Core Features to Demonstrate

### 1. **Social Networking & Posts**
**What it does:** Medical professionals share clinical updates, research findings, case experiences, and professional insights.

**Key Capabilities:**
- Create rich media posts with text, images, videos, and attachments
- Like, comment, and share posts within the medical community
- Tag colleagues and healthcare facilities  
- React to posts with professional engagement
- Share posts via deep links
- View detailed post analytics and engagement

**Demo Script:**
```
1. Open the app → Show News Feed with medical posts
2. Scroll through various post types (text, images, videos)
3. Tap Like/Comment on a post
4. Show comment thread with replies
5. Create a new post with image attachment
6. Tag a colleague in the post
```

---

### 2. **Real-Time Voice & Video Calling (VoIP)** 🔴 **CRITICAL FOR GOOGLE PLAY**
**What it does:** Enables secure, HIPAA-compliant voice and video consultations between medical professionals using VoIP technology.

**Technical Implementation:**
- **Agora RTC SDK** for high-quality real-time communication
- **Flutter CallKit Integration** for native iOS/Android call experience
- **Foreground Service** with persistent notification during active calls
- **Background call handling** when app is locked or minimized
- **Push notifications** for incoming calls via Firebase/Pusher

**Google Play Requirements - MUST DEMONSTRATE:**
```
✅ Foreground Service with Persistent Notification
✅ Active call continues when app is backgrounded
✅ Notification shows "Ongoing call - DocTak"
✅ Tap notification to return to active call
✅ Notification disappears when call ends
```

**Demo Script for Video Submission:**
```
1. Open DocTak app
2. Navigate to Messages/Contacts
3. Initiate a video call to another user
4. SHOW: Incoming call notification appears (full screen)
5. Accept the call
6. CRITICAL: Pull down notification shade
   → Show persistent notification: "Ongoing call - DocTak.net"
7. Press Home button or switch to another app
8. CRITICAL: Pull notification shade again  
   → Notification still visible
9. Tap the notification
   → Returns to active call screen
10. End the call
11. Pull notification shade
    → Notification is gone
```

**Why This Matters:**
- Google requires proof that `FOREGROUND_SERVICE_PHONE_CALL` permission is essential
- Video must clearly show the persistent notification during calls
- Demonstrates the service runs properly in foreground with user awareness

---

### 3. **Messaging & Chat**
**What it does:** Direct messaging between healthcare professionals with rich media support.

**Key Capabilities:**
- One-on-one text conversations
- Voice message recording and playback
- Photo/video/document sharing
- WhatsApp-style attachment picker with gallery grid
- Message read receipts and typing indicators
- Message search and filtering
- Voice message waveform visualization

**Demo Script:**
```
1. Open Messages tab
2. Select a conversation
3. Send text message
4. Record and send voice message
5. Share photo from gallery with preview
6. Show document sharing capability
7. Show message read status
```

---

### 4. **Professional Groups**
**What it does:** Medical specialty-focused group discussions for knowledge sharing and collaboration.

**Key Capabilities:**
- Create public/private medical specialty groups
- Group messaging and discussions
- Member management (admins, moderators, members)
- Group announcements and pinned messages
- Join groups by specialty or interest area
- Group member directory

**Demo Script:**
```
1. Navigate to Groups section
2. Show list of joined groups (Cardiology, Surgery, etc.)
3. Open a group → Show discussion threads
4. Post a question to the group
5. View group members and their specialties
```

---

### 5. **Case Discussions**
**What it does:** Collaborative clinical case discussions where doctors can present cases, seek opinions, and share expertise.

**Key Capabilities:**
- Create detailed case presentations with patient history (de-identified)
- Upload diagnostic images (X-rays, CT scans, lab reports)
- Specialty-specific case categorization
- Comment threads with expert opinions
- Like/bookmark cases for reference
- Filter cases by specialty, date, or engagement
- Follow case updates

**Demo Script:**
```
1. Open Case Discussions
2. Browse cases by specialty
3. Open a case → Show images, description, comments
4. Add a clinical opinion/comment
5. Like/save the case for later reference
6. Create a new case discussion
```

---

### 6. **Medical Jobs Board**
**What it does:** Healthcare job opportunities worldwide with application tracking.

**Key Capabilities:**
- Search jobs by specialty, location, or keywords
- Filter by country, experience level, job type
- View detailed job descriptions with requirements
- Apply directly with CV/resume upload
- Save jobs for later review
- Track application status
- Share job postings with colleagues

**Demo Script:**
```
1. Navigate to Jobs section
2. Search for "Cardiologist" jobs
3. Filter by country (e.g., UAE, USA)
4. Open job details → Show salary, requirements
5. Upload CV and apply for a position
6. Show saved jobs list
```

---

### 7. **AI Medical Assistant (DocTak AI)**
**What it does:** ChatGPT-powered AI assistant specialized for medical queries and clinical decision support.

**Key Capabilities:**
- Natural language medical queries
- Drug interaction checks
- Clinical guideline summaries
- Differential diagnosis suggestions
- Medical literature references
- Session-based conversations with history
- Export conversation transcripts

**Demo Script:**
```
1. Open AI Assistant
2. Ask: "What are the drug interactions with Warfarin?"
3. Show AI response with detailed information
4. Follow-up question: "What about with NSAIDs?"
5. Show conversation history
6. Start new session for different topic
```

---

### 8. **Drugs Database**
**What it does:** Comprehensive medication reference with dosing, interactions, and prescribing information.

**Key Capabilities:**
- Search by brand or generic name
- Detailed drug information (mechanism, indications, dosing)
- Drug-drug interaction checker
- Side effects and contraindications
- Pediatric/geriatric dosing adjustments
- Pricing information by region
- Bookmark frequently prescribed medications

**Demo Script:**
```
1. Open Drugs section
2. Search for "Metformin"
3. View drug details: mechanism, dosing, interactions
4. Check interaction with another drug
5. Show pricing information
6. Bookmark the drug for quick access
```

---

### 9. **Medical News Feed**
**What it does:** Curated medical news from trusted sources (BBC Health, CNN Health) with real-time updates.

**Key Capabilities:**
- Tabs for BBC News and CNN News
- Latest healthcare industry updates
- Clinical research breakthroughs
- Public health alerts
- Share articles with colleagues
- Open full articles in-app browser

**Demo Script:**
```
1. Navigate to News section
2. Show BBC News tab with latest articles
3. Switch to CNN News tab
4. Tap an article to read full content
5. Share article via app or external messaging
```

---

### 10. **Clinical Guidelines**
**What it does:** Evidence-based medical protocols and treatment guidelines for various conditions.

**Key Capabilities:**
- Searchable guideline database
- Specialty-specific protocols
- Step-by-step treatment algorithms
- References to medical literature
- Downloadable PDF guidelines
- Bookmark frequently used guidelines

**Demo Script:**
```
1. Open Guidelines section
2. Search for "Hypertension management"
3. View detailed protocol
4. Show treatment flowchart
5. Download PDF for offline reference
```

---

### 11. **Medical Conferences**
**What it does:** Global medical conference listings with registration and event details.

**Key Capabilities:**
- Browse upcoming conferences by specialty
- Filter by country, date, or topic
- View conference schedules and speakers
- Register for events within the app
- Add conferences to calendar
- Share conference details with colleagues
- Receive notifications for deadlines

**Demo Script:**
```
1. Navigate to Conferences
2. Search for "Cardiology conferences"
3. Filter by country (e.g., Europe)
4. View conference details: dates, venue, agenda
5. Register for a conference
6. Add to device calendar
```

---

### 12. **Meeting Scheduler**
**What it does:** Schedule and manage virtual meetings with colleagues.

**Key Capabilities:**
- Create meeting invitations with date/time
- Add participants from contacts
- Send meeting reminders
- Integrate with video calling
- View upcoming meeting calendar
- Cancel or reschedule meetings

**Demo Script:**
```
1. Open Meetings section
2. Create new meeting
3. Select participants and date/time
4. Send invitations
5. View upcoming meetings
6. Join a scheduled meeting (launches video call)
```

---

### 13. **User Profiles & Networking**
**What it does:** Professional profiles showcasing medical credentials, experience, and activity.

**Key Capabilities:**
- Detailed professional profiles (specialty, location, experience)
- Profile photo and cover image
- Work history and education credentials
- Published posts and activity feed
- Follow/connect with other professionals
- View profile statistics (posts, followers, connections)
- Privacy settings for profile visibility

**Demo Script:**
```
1. Navigate to Profile
2. Show personal information, specialty, location
3. View posts and activity
4. Show work experience and credentials
5. Edit profile information
6. Adjust privacy settings
```

---

### 14. **Search & Discovery**
**What it does:** Powerful search to find people, posts, groups, jobs, and content across the platform.

**Key Capabilities:**
- Search by name, specialty, or keyword
- Filter results by type (People, Posts, Groups, Jobs)
- Advanced filters (location, specialty, date)
- Recent searches history
- Suggested connections based on specialty
- Save searches for quick access

**Demo Script:**
```
1. Tap Search icon
2. Search for "Cardiologist in UAE"
3. Filter results by People
4. View suggested profiles
5. Search for posts about "COVID-19"
6. Show filtered post results
```

---

### 15. **Notifications & Engagement**
**What it does:** Real-time alerts for all platform activities and interactions.

**Key Capabilities:**
- Push notifications for calls, messages, comments
- Notification badges on tabs (unread counts)
- In-app notification center
- Notification preferences and settings
- Mark as read/unread
- Clear all notifications
- Deep links to content from notifications

**Demo Script:**
```
1. Show notification badge on bell icon
2. Open notification center
3. Tap a notification → Navigate to related content
4. Show different notification types (like, comment, call missed)
5. Adjust notification settings
```

---

### 16. **Multi-Language Support**
**What it does:** Full app localization for international medical community.

**Key Capabilities:**
- Supported languages: English, Arabic, French, Spanish, Urdu
- RTL (Right-to-Left) support for Arabic/Urdu
- Language selection in settings
- Automatic locale detection
- Translated UI and content

**Demo Script:**
```
1. Open Settings
2. Navigate to Language Settings
3. Switch to Arabic → Show RTL interface
4. Switch to French → Show translated UI
5. Return to English
```

---

### 17. **Privacy & Security**
**What it does:** HIPAA-compliant data protection with granular privacy controls.

**Key Capabilities:**
- Privacy policy and terms of service
- Data encryption for messages and calls
- Profile visibility settings
- Block/report users
- Account deactivation/deletion
- Two-factor authentication (if implemented)
- Session management

**Demo Script:**
```
1. Navigate to Settings → Privacy
2. Show privacy settings (profile visibility, message privacy)
3. View terms of service
4. Show block/report user option
5. Account management (logout, delete account)
```

---

## 📱 Technical Stack

### Frontend
- **Flutter** (Dart) - Cross-platform mobile framework
- **BLoC Pattern** - State management
- **Material Design** - UI components
- **RTL Support** - Arabic/Urdu language support

### Real-Time Communication
- **Agora RTC SDK** - Video/audio calling
- **Flutter CallKit** - Native call experience
- **Pusher Channels** - Real-time events
- **Firebase Cloud Messaging** - Push notifications

### Backend Integration
- **REST API** - Laravel backend
- **Dio** - HTTP client
- **Shared Preferences** - Local storage
- **Cached Network Images** - Image optimization

### Media & Files
- **Image Picker** - Camera/gallery access
- **File Picker** - Document selection
- **Flutter Sound** - Audio recording
- **Photo Manager** - Gallery management
- **Video Player** - In-app video playback

### Performance
- **Virtualized Lists** - Efficient scrolling
- **Shimmer Loading** - Skeleton screens
- **Image Caching** - Network optimization
- **Memory Management** - Large list handling

---

## 🎥 Video Demo Requirements for Google Play

### Required Length
30-60 seconds (maximum)

### Must Show for FOREGROUND_SERVICE_PHONE_CALL Permission

1. **Launch app** → Navigate to calling feature
2. **Initiate/receive call** → Show incoming call UI
3. **Accept call** → Active call screen
4. **CRITICAL: Pull notification shade** → Show persistent notification
5. **Minimize app** → Switch to home screen or another app
6. **CRITICAL: Pull notification shade again** → Notification still visible
7. **Tap notification** → Return to active call
8. **End call** → Show call screen closes
9. **Pull notification shade** → Notification is gone

### Video Quality
- 720p minimum resolution
- Clear screen recording (no blurriness)
- Stable recording (no shaking)
- Show device model/Android version (optional but helpful)

### Platforms
- Android 14+ recommended (to show latest permissions)
- Show on real device (not emulator)

---

## 📝 Google Play Store Description Template

```
DocTak.net - The Global Medical Professional Network

Connect, collaborate, and advance your medical practice with the world's leading healthcare social platform.

🩺 Core Features:
• Voice & Video Calling - Secure VoIP consultations with colleagues worldwide
• Messaging & Chat - Direct messaging with rich media support
• Case Discussions - Collaborative clinical case reviews and expert opinions
• Medical Groups - Specialty-focused communities for knowledge sharing
• AI Medical Assistant - ChatGPT-powered clinical decision support
• Jobs Board - Healthcare career opportunities globally
• Drugs Database - Comprehensive medication reference
• Medical News - Latest healthcare industry updates from trusted sources
• Clinical Guidelines - Evidence-based treatment protocols
• Conferences - Global medical event listings and registration
• Meeting Scheduler - Virtual meeting management

🔐 Security & Privacy:
HIPAA-compliant data protection with end-to-end encryption for calls and messages. Granular privacy controls for your professional profile.

🌍 Multi-Language Support:
Available in English, Arabic, French, Spanish, and Urdu with full RTL support.

📱 Real-Time Communication:
Active calls run as a foreground service with persistent notifications, ensuring reliable connectivity even when the app is in the background or the screen is locked. Never miss important consultations.

Join thousands of medical professionals worldwide who trust DocTak.net for professional networking, clinical collaboration, and continuous medical education.
```

---

## 🎬 Suggested Video Recording Tools

### Android
- **AZ Screen Recorder** (Free, no watermark)
- **XRecorder** (Free, good quality)
- **Mobizen Screen Recorder** (Free)

### Screen Recording Tips
1. Clear all unnecessary notifications before recording
2. Use "Do Not Disturb" mode
3. Close other apps to prevent interruptions
4. Record in portrait mode (matches phone usage)
5. Speak clearly if adding voiceover (optional)
6. Show clear touch indicators (enable in Developer Options)

---

## ✅ Pre-Submission Checklist

- [ ] Video clearly shows incoming call flow
- [ ] Persistent notification visible during call
- [ ] App backgrounded while call continues
- [ ] Notification tap returns to call
- [ ] Notification disappears after call ends
- [ ] Video is 30-60 seconds long
- [ ] Video uploaded to YouTube (unlisted is fine)
- [ ] Play Console form filled with correct selection: "Voice over Internet Protocol (VoIP), telecom APIs"
- [ ] App description mentions foreground service for calls
- [ ] All permissions justified in Privacy Policy

---

## 📧 Support & Questions

For technical questions or demo assistance:
- Email: support@doctak.net
- Documentation: This guide

**Last Updated:** November 19, 2025  
**App Version:** 3.0.6 (Build 103)
