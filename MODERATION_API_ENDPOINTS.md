# Moderation API Endpoints

## Apple App Store Guideline 1.2 Compliance

This document describes the API endpoints required for content moderation features to comply with Apple's User-Generated Content guidelines.

---

## 1. Report Endpoints

### 1.1 Report a Post

**Endpoint:** `POST /report/post`

**Headers:**
```
Authorization: Bearer {user_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "post_id": 123,
  "reason": "spam",
  "description": "Optional additional details about the report"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Report submitted successfully. Our team will review it within 24 hours."
}
```

---

### 1.2 Report a Comment

**Endpoint:** `POST /report/comment`

**Headers:**
```
Authorization: Bearer {user_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "comment_id": 456,
  "reason": "harassment",
  "description": "Optional additional details about the report"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Report submitted successfully. Our team will review it within 24 hours."
}
```

---

### 1.3 Report a User

**Endpoint:** `POST /report/user`

**Headers:**
```
Authorization: Bearer {user_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_id": 789,
  "reason": "impersonation",
  "description": "Optional additional details about the report"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Report submitted successfully. Our team will review it within 24 hours."
}
```

---

## 2. Block Endpoints

### 2.1 Block a User

**Endpoint:** `POST /user/block`

**Headers:**
```
Authorization: Bearer {user_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_id": 789
}
```

**Response:**
```json
{
  "success": true,
  "message": "User has been blocked. Their content will no longer appear in your feed."
}
```

**Server-Side Actions:**
- Add entry to `blocked_users` table
- Filter blocked user's posts from blocker's feed
- Prevent messaging between blocked users
- Log the block action for moderation review

---

### 2.2 Unblock a User

**Endpoint:** `POST /user/unblock`

**Headers:**
```
Authorization: Bearer {user_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "user_id": 789
}
```

**Response:**
```json
{
  "success": true,
  "message": "User has been unblocked."
}
```

---

### 2.3 Get Blocked Users List

**Endpoint:** `GET /user/blocked-list`

**Headers:**
```
Authorization: Bearer {user_token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "name": "John Doe",
      "profile_pic": "https://example.com/profile/123.jpg",
      "blocked_at": "2026-02-03T10:30:00Z"
    },
    {
      "id": 456,
      "name": "Jane Smith",
      "profile_pic": "https://example.com/profile/456.jpg",
      "blocked_at": "2026-02-01T15:45:00Z"
    }
  ]
}
```

---

### 2.4 Check if User is Blocked

**Endpoint:** `GET /user/is-blocked/{userId}`

**Headers:**
```
Authorization: Bearer {user_token}
```

**Response:**
```json
{
  "success": true,
  "is_blocked": true
}
```

---

## 3. Report Reason Values

The `reason` field in report endpoints accepts the following values:

| Value | Display Name |
|-------|--------------|
| `spam` | Spam or misleading |
| `harassment` | Harassment or bullying |
| `hate_speech` | Hate speech or discrimination |
| `violence` | Violence or dangerous content |
| `inappropriate_content` | Inappropriate or offensive content |
| `false_information` | False or misleading information |
| `intellectual_property` | Intellectual property violation |
| `impersonation` | Impersonation or fake account |
| `privacy_violation` | Privacy violation |
| `other` | Other |

---

## 4. Database Schema Suggestions

### 4.1 Reports Table

```sql
CREATE TABLE reports (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    reporter_id BIGINT NOT NULL,
    content_type ENUM('post', 'comment', 'user') NOT NULL,
    content_id BIGINT NOT NULL,
    reason VARCHAR(50) NOT NULL,
    description TEXT NULL,
    status ENUM('pending', 'reviewed', 'resolved', 'dismissed') DEFAULT 'pending',
    reviewed_by BIGINT NULL,
    reviewed_at TIMESTAMP NULL,
    action_taken VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (reporter_id) REFERENCES users(id),
    INDEX idx_status (status),
    INDEX idx_content (content_type, content_id),
    INDEX idx_created (created_at)
);
```

### 4.2 Blocked Users Table

```sql
CREATE TABLE blocked_users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    blocker_id BIGINT NOT NULL,
    blocked_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (blocker_id) REFERENCES users(id),
    FOREIGN KEY (blocked_id) REFERENCES users(id),
    UNIQUE KEY unique_block (blocker_id, blocked_id),
    INDEX idx_blocker (blocker_id),
    INDEX idx_blocked (blocked_id)
);
```

---

## 5. Apple Compliance Requirements

### 5.1 Content Moderation (24-Hour Response)

- All reports must be reviewed within **24 hours**
- Objectionable content must be removed promptly
- Offending users must be ejected (account suspended/terminated)

### 5.2 Required Actions on Report

1. **Log the report** with timestamp and reporter info
2. **Notify moderators** via email/push notification
3. **Track report status** (pending → reviewed → resolved)
4. **Document action taken** for audit purposes

### 5.3 Required Actions on Block

1. **Immediately hide** blocked user's content from blocker's feed
2. **Prevent messaging** between blocked users
3. **Log the block** for moderation team review
4. **Notify moderators** if multiple users block the same account

---

## 6. Error Responses

### 6.1 Validation Error

```json
{
  "success": false,
  "message": "Validation error",
  "errors": {
    "reason": ["The reason field is required."],
    "post_id": ["The post_id must be a valid integer."]
  }
}
```

### 6.2 Not Found Error

```json
{
  "success": false,
  "message": "Post not found"
}
```

### 6.3 Already Reported Error

```json
{
  "success": false,
  "message": "You have already reported this content"
}
```

### 6.4 Cannot Block Self Error

```json
{
  "success": false,
  "message": "You cannot block yourself"
}
```

---

## 7. Implementation Checklist

- [ ] Create `reports` database table
- [ ] Create `blocked_users` database table
- [ ] Implement `POST /report/post` endpoint
- [ ] Implement `POST /report/comment` endpoint
- [ ] Implement `POST /report/user` endpoint
- [ ] Implement `POST /user/block` endpoint
- [ ] Implement `POST /user/unblock` endpoint
- [ ] Implement `GET /user/blocked-list` endpoint
- [ ] Implement `GET /user/is-blocked/{userId}` endpoint
- [ ] Set up moderator notifications for new reports
- [ ] Create admin panel for reviewing reports
- [ ] Modify feed queries to exclude blocked users' content
- [ ] Modify messaging to prevent blocked user communication
- [ ] Set up 24-hour report review reminder system

---

## 8. Contact

For questions about these API endpoints, contact the development team.

**Last Updated:** February 2026
