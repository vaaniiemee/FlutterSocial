# 🔥 Firebase Data Structure Setup Guide

## 📋 **Required Collections & Data Structures**

Based on the code analysis, here are all the Firebase collections and their data structures that need to be set up:

## 1. **`users` Collection** (Main User Profiles)

### Document Structure:
```javascript
{
  // Basic Info
  "name": "John Doe",
  "email": "john@example.com", 
  "username": "johndoe",
  "photoURL": "https://firebasestorage.googleapis.com/...",
  "bannerURL": "https://firebasestorage.googleapis.com/...",
  
  // Profile Details
  "bio": "Software Developer",
  "website": "https://johndoe.com",
  "location": "New York, USA",
  
  // Onboarding
  "hasCompletedOnboarding": true,
  "country": "United States",
  "goal": "Find friends",
  
  // Interests
  "interests": ["Technology", "Music", "Travel"],
  
  // Stats
  "followersCount": 150,
  "followingCount": 75,
  "postsCount": 25,
  
  // Timestamps
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-20T15:45:00Z"
}
```

## 2. **`chats` Collection** (Chat Metadata)

### Document Structure:
```javascript
{
  // Participants
  "participants": ["user1_id", "user2_id"],
  
  // Chat Info
  "lastMessage": "Hey, how are you?",
  "lastMessageTime": "2024-01-20T15:45:00Z",
  
  // Unread Counts
  "unreadCount": {
    "user1_id": 0,
    "user2_id": 3
  },
  
  // Timestamps
  "createdAt": "2024-01-15T10:30:00Z"
}
```

## 3. **`chats/{chatId}/messages` Subcollection** (Individual Messages)

### Document Structure:
```javascript
{
  "senderId": "user1_id",
  "text": "Hey, how are you?",
  "type": "text", // "text", "image", "video"
  "timestamp": "2024-01-20T15:45:00Z",
  
  // For media messages
  "imageUrl": "https://firebasestorage.googleapis.com/...",
  "videoUrl": "https://firebasestorage.googleapis.com/..."
}
```

## 4. **`follows` Collection** (Follow Relationships)

### Document Structure:
```javascript
// Document ID: "{followerId}_{followingId}"
{
  "followerId": "user1_id",
  "followingId": "user2_id", 
  "createdAt": "2024-01-15T10:30:00Z"
}
```

**Note**: Document ID format is `{followerId}_{followingId}` for easy querying.

## 5. **`posts` Collection** (User Posts)

### Document Structure:
```javascript
{
  "userId": "user1_id",
  "caption": "Beautiful sunset today!",
  "imageUrls": [
    "https://firebasestorage.googleapis.com/...",
    "https://firebasestorage.googleapis.com/..."
  ],
  "tags": ["sunset", "nature", "photography"],
  "likesCount": 25,
  "commentsCount": 5,
  "createdAt": "2024-01-20T15:45:00Z"
}
```

## 6. **`interests` Collection** (Available Interests)

### Document Structure:
```javascript
{
  "name": "Technology",
  "category": "Hobbies",
  "icon": "💻",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

## 🚀 **How to Set Up These Collections**

### **Option 1: Automatic Creation (Recommended)**
The app will automatically create these collections when users:
- Sign up (creates `users` document)
- Start chatting (creates `chats` and `messages`)
- Follow someone (creates `follows` document)
- Create posts (creates `posts` document)

### **Option 2: Manual Setup in Firebase Console**

1. **Go to Firebase Console** → Firestore Database → Data
2. **Click "Start collection"** for each collection
3. **Add sample documents** with the structure above

## 📊 **Sample Data to Add Manually**

### **1. Add Sample Interests:**
```javascript
// Document ID: "tech"
{
  "name": "Technology",
  "category": "Hobbies", 
  "icon": "💻"
}

// Document ID: "music"
{
  "name": "Music",
  "category": "Entertainment",
  "icon": "🎵"
}

// Document ID: "travel"
{
  "name": "Travel", 
  "category": "Lifestyle",
  "icon": "✈️"
}

// Document ID: "sports"
{
  "name": "Sports",
  "category": "Fitness", 
  "icon": "⚽"
}

// Document ID: "art"
{
  "name": "Art",
  "category": "Creative",
  "icon": "🎨"
}
```

### **2. Add Sample User (Optional):**
```javascript
// Document ID: "sample_user_id"
{
  "name": "Sample User",
  "email": "sample@example.com",
  "username": "sampleuser",
  "bio": "This is a sample user for testing",
  "interests": ["Technology", "Music"],
  "followersCount": 0,
  "followingCount": 0, 
  "postsCount": 0,
  "hasCompletedOnboarding": true,
  "createdAt": "2024-01-15T10:30:00Z"
}
```

## 🔧 **Firebase Storage Setup**

### **Folder Structure:**
```
/
├── profile_images/
│   └── {userId}/
│       └── profile.jpg
├── banner_images/
│   └── {userId}/
│       └── banner.jpg
└── post_images/
    └── {userId}/
        └── {postId}/
            ├── image1.jpg
            └── image2.jpg
```

## 📱 **Indexes Required**

Firebase will automatically suggest these indexes, but you can create them manually:

### **1. Users Collection:**
- `username` (Ascending)
- `createdAt` (Descending)

### **2. Chats Collection:**
- `participants` (Arrays)
- `lastMessageTime` (Descending)

### **3. Posts Collection:**
- `userId` (Ascending)
- `createdAt` (Descending)

## ✅ **Verification Checklist**

After setup, verify these work:

- [ ] User can sign up and create profile
- [ ] User can search other users
- [ ] User can view other profiles
- [ ] User can follow/unfollow others
- [ ] User can start chats
- [ ] User can send/receive messages
- [ ] User can edit their profile
- [ ] User can upload profile/banner images
- [ ] User can select interests
- [ ] User can create posts

## 🆘 **Troubleshooting**

### **Common Issues:**

1. **Permission Denied**: Update Firestore security rules
2. **Collection Not Found**: Collections are created automatically
3. **Index Missing**: Firebase will prompt you to create indexes
4. **Storage Access Denied**: Update Storage security rules

### **Storage Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 🎯 **Next Steps**

1. **Update Firestore Rules** (from `firestore.rules`)
2. **Update Storage Rules** (above)
3. **Add Sample Interests** (optional)
4. **Test the App** - Everything should work!

The app is designed to create all necessary data structures automatically when users interact with it. You just need to ensure the security rules are properly configured!
