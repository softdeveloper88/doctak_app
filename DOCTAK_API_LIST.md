# Doctak App — API Reference

Generated: 2026-04-28  
Updated: All versions migrated to Node.js Cloudflare Workers backend (v1)

---

## Base URLs

| Purpose | URL |
|---------|-----|
| All API (v1) | `https://doctak.net/api/v1` |
| CME module | `https://doctak.net/api/v1/cme` |
| Chat module | `https://doctak.net/api/v1/chat` |
| Media (R2 via Node proxy) | `https://doctak.net/r2-media/` |

> **Dev mode** (local server via `--dart-define=ENV=development`): still uses local IP/port.

> All endpoints use `Authorization: Bearer <token>` header.

---

## Auth

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/login` | Email/password login |
| POST | `/api/v1/social-login` | Social login (Google/Apple/Facebook) |
| POST | `/api/v1/register` | Register new user |
| POST | `/api/v1/complete-profile` | Complete registration profile |
| GET | `/api/v1/me` | Fetch current user + subscription info |
| POST | `/api/v1/forgot_password` | Request password reset |
| GET | `/api/v1/country-list` | Countries list |
| GET | `/api/v1/get-states?country_id=` | States by country |
| GET | `/api/v1/specialty` | Specialties list |
| GET | `/api/v1/universities/state/{stateId}` | Universities by state |

---

## Profile

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/profile?user_id=` | Get user profile |
| POST | `/api/v1/profile/update` | Update profile |
| POST | `/api/v1/upload-profile-pic` | Upload profile picture (multipart) |
| POST | `/api/v1/upload-cover-pic` | Upload cover photo (multipart) |
| GET | `/api/v1/interests?user_id=` | Get interests |
| POST | `/api/v1/interests/update` | Update interests |
| GET | `/api/v1/work-and-education?user_id=` | Work & education |
| GET | `/api/v1/full-profile?user_id=` | Full profile (mobile single-call) |
| POST | `/api/v1/about-me/update` | Update about me/address |
| GET | `/api/v1/privacy-settings` | Get privacy settings |
| POST | `/api/v1/privacy-settings` | Bulk update privacy settings |
| GET | `/api/v1/experiences?user_id=` | Work experiences |
| POST | `/api/v1/experiences` | Add experience |
| PUT | `/api/v1/experiences/{id}` | Update experience |
| DELETE | `/api/v1/experiences/{id}` | Delete experience |
| GET | `/api/v1/education?user_id=` | Education |
| GET | `/api/v1/publications?user_id=` | Publications |
| GET | `/api/v1/awards?user_id=` | Awards |
| GET | `/api/v1/medical-licenses?user_id=` | Medical licenses |
| GET | `/api/v1/social-profiles?user_id=` | Social profiles |
| GET | `/api/v1/business-hours?user_id=` | Business hours |

---

## Posts

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/posts?page=` | Posts feed |
| GET | `/api/v1/post-by-comment/{postId}` | Post details + comments |
| GET | `/api/v1/posts/{postId}` | Post detail with likes |
| POST | `/api/v1/user-profile-post?page=&user_id=` | User's profile posts |
| POST | `/api/v1/new_post` | Create post (multipart) |
| POST | `/api/v1/like?post_id=` | Like / unlike post |
| GET | `/api/v1/getPostLikes?postId=` | Users who liked a post |
| POST | `/api/v1/delete_post?post_id=` | Delete post |
| GET | `/api/v1/search-post?page=&search=` | Search posts |
| POST | `/api/v1/comment` | Add comment / reply |
| GET | `/api/v1/advertisement-setting` | Ad settings |
| GET | `/api/v1/advertisement-types` | Ad types |

---

## Stories

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/stories` | Story feed |
| POST | `/api/v1/stories` | Create story (multipart) |
| GET | `/api/v1/stories/user/{userId}` | User's stories |
| POST | `/api/v1/stories/{storyId}/view` | Mark story viewed |
| GET | `/api/v1/stories/{storyId}/viewers` | Story viewers |
| DELETE | `/api/v1/stories/{storyId}` | Delete own story |

---

## Network / Connections

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/network-stats` | Connection stats |
| GET | `/api/v1/connections?search=&page=` | My connections |
| GET | `/api/v1/friend-requests?type=&status=&page=` | Friend requests |
| POST | `/api/v1/friend-request/send/{userId}` | Send friend request |
| POST | `/api/v1/friend-request/accept/{requestId}` | Accept request |
| POST | `/api/v1/friend-request/reject/{requestId}` | Reject request |
| POST | `/api/v1/friend-request/cancel/{requestId}` | Cancel sent request |
| POST | `/api/v1/remove-connection` | Remove connection |
| GET | `/api/v1/people-you-may-know?page=` | People you may know |
| GET | `/api/v1/network-search?q=&specialty=&country=` | Network search |
| GET | `/api/v1/search-suggestions?q=&limit=` | Typeahead suggestions |

---

## Groups

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/groups?page=` | All groups |
| POST | `/api/v1/my-groups?page=` | My joined groups |
| GET | `/api/v1/group-details/{groupId}` | Group details |
| GET | `/api/v1/groups/search?page=&keyword=` | Search groups |
| POST | `/api/v1/groups/{groupId}/join` | Join group |
| POST | `/api/v1/groups/{groupId}/leave` | Leave group |
| POST | `/api/v1/groups/create` | Create group |
| POST | `/api/v1/groups/update` | Update group |
| DELETE | `/api/v1/groups/{groupId}/delete` | Delete group |
| GET | `/api/v1/groups/{groupId}/members?page=` | Group members |
| POST | `/api/v1/groups/{groupId}/add-member` | Add member |
| POST | `/api/v1/groups/{groupId}/remove-member` | Remove member |
| POST | `/api/v1/groups/{groupId}/promote-admin` | Promote admin |
| POST | `/api/v1/groups/{groupId}/demote-admin` | Demote admin |

---

## Jobs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/jobs?page=` | Jobs list |
| GET | `/api/v1/search-job?page=&keyword=` | Search jobs |
| GET | `/api/v1/jobs-speciality` | Job specialties |
| GET | `/api/v1/jobs/{jobId}` | Job details |
| POST | `/api/v1/jobs/apply` | Apply for job |
| POST | `/api/v1/jobs/save` | Save/bookmark job |
| POST | `/api/v1/jobs/unsave` | Remove bookmark |
| GET | `/api/v1/jobs/saved?page=` | Saved jobs |
| GET | `/api/v1/jobs/applied?page=` | Applied jobs |
| GET | `/api/v1/jobs/recommended?page=` | Recommended jobs |
| GET | `/api/v1/jobs/location?page=&location=` | Jobs by location |
| GET | `/api/v1/jobs/specialty?page=&specialty_id=` | Jobs by specialty |
| POST | `/api/v1/jobs-applicants/{jobId}/withdraw-application` | Withdraw application |
| GET | `/api/v1/jobs-applicants/{jobId}/applicants` | Job applicants |
| POST | `/api/v1/jobs/post` | Post a job |

---

## Notifications

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/notifications?page=` | All notifications |
| GET | `/api/v1/notifications/{read\|unread}?page=` | Filtered by status |
| POST | `/api/v1/notifications/mark-read` | Mark all read |
| POST | `/api/v1/notifications/{id}/mark-read` | Mark one read |

---

## Meetings (Agora)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/get-schedule-meetings` | Scheduled meetings |
| POST | `/api/v1/create-meeting` | Create meeting |
| GET | `/api/v1/join-meeting?meeting_channel=` | Join by code |
| GET | `/api/v1/ask-to-join?meeting_code=` | Ask to join |
| GET | `/api/v1/allow-join-request?userId=&meetingId=` | Allow join |
| GET | `/api/v1/reject-join-request` | Reject join |
| POST | `/api/v1/close-meeting` | End meeting |
| POST | `/api/v1/send-message-meeting` | Meeting chat message |
| GET | `/api/v1/meeting-update-status` | Change meeting status |
| POST | `/api/v1/send-meeting-invitation` | Send invitation |
| POST | `/api/v1/meeting-settings/update` | Update settings |
| GET | `/api/v1/search/users?query=` | Search users for invite |

---

## Chat — Conversation System

Base: `https://doctak.net/api/v1/chat`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/chat/conversations` | List conversations |
| POST | `/api/v1/chat/conversations/create` | Create/find conversation |
| POST | `/api/v1/chat/conversations/find` | Find conversation |
| POST | `/api/v1/chat/conversations/{id}/read` | Mark read |
| GET | `/api/v1/chat/messages/conversation/{id}` | Get messages |
| POST | `/api/v1/chat/messages/conversation/{id}` | Send text/file/voice |
| POST | `/api/v1/chat/pusher/auth` | Pusher auth |

---

## Drugs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/drugs?page=&country_id=` | Drug list |
| GET | `/api/v1/drugs/{id}` | Drug detail |
| GET | `/api/v1/drugs/search-suggestions?q=&type=` | Suggestions |
| GET | `/api/v1/drugs/countries` | Countries with drug data |
| GET | `/api/v1/drugs/filters?country_id=` | Drug filters |
| GET | `/api/v1/drugs/featured?limit=` | Featured drugs |

---

## CME — Continuing Medical Education

Base: `https://doctak.net/api/v1/cme`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/cme/dashboard` | CME dashboard |
| GET | `/api/v1/cme/stats` | Stats |
| GET | `/api/v1/cme/events?page=&search=&type=&format=` | Browse events |
| GET | `/api/v1/cme/events/{id}` | Event detail |
| POST | `/api/v1/cme/events` | Create event |
| PUT | `/api/v1/cme/events/{id}` | Update event |
| DELETE | `/api/v1/cme/events/{id}` | Delete event |
| GET | `/api/v1/cme/events/my/events` | My events |
| GET | `/api/v1/cme/events/my/upcoming` | Upcoming |
| GET | `/api/v1/cme/events/my/attended` | Attended |
| GET | `/api/v1/cme/events/my/created` | Created |
| POST | `/api/v1/cme/events/{id}/register` | Register |
| DELETE | `/api/v1/cme/events/{id}/unregister` | Unregister |
| GET | `/api/v1/cme/events/{id}/registration-status` | Registration status |
| POST | `/api/v1/cme/events/{id}/join` | Join event |
| POST | `/api/v1/cme/events/{id}/leave` | Leave event |
| POST | `/api/v1/cme/events/{id}/track-participation` | Track participation |
| GET | `/api/v1/cme/events/{id}/participants` | Participants |
| GET | `/api/v1/cme/events/{id}/speakers` | Speakers |
| POST | `/api/v1/cme/events/{id}/agora-token` | Agora token |
| POST | `/api/v1/cme/events/{id}/end-event` | End event (host) |
| POST | `/api/v1/cme/events/{id}/generate-certificates` | Generate certificates (host) |
| POST | `/api/v1/cme/events/{id}/switch-module` | Switch module (host) |
| POST | `/api/v1/cme/events/{id}/polls/create` | Create poll (host) |
| GET | `/api/v1/cme/certificates` | My certificates |
| GET | `/api/v1/cme/certificates/{id}` | Certificate detail |
| GET | `/api/v1/cme/certificates/{id}/download` | Download URL |
| GET | `/api/v1/cme/notifications` | CME notifications |
| GET | `/api/v1/cme/notifications/count` | Unread count |
| POST | `/api/v1/cme/notifications/{id}/read` | Mark read |

---

## Moderation

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/report/post` | Report post |
| POST | `/api/v1/report/comment` | Report comment |
| POST | `/api/v1/report/user` | Report user |
| POST | `/api/v1/user/block` | Block user |
| POST | `/api/v1/user/unblock` | Unblock user |
| GET | `/api/v1/user/blocked-list` | Blocked users |
| GET | `/api/v1/user/is-blocked/{userId}` | Check blocked status |

---

## Verification

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/verification/status` | Verification status |
| POST | `/api/v1/verification/submit` | Submit verification (multipart) |

---

## Subscription

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/subscription/status` | Subscription status |
| GET | `/api/v1/subscription/plans` | Plans |
| GET | `/api/v1/subscription/premium-page` | Premium page |
| GET | `/api/v1/subscription/history` | Subscription history |
