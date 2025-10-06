# Firebase Setup Guide

## 🔥 Firebase Firestore Security Rules

To fix the "PERMISSION_DENIED" errors, you need to update your Firestore security rules in the Firebase Console.

### Steps to Update Firestore Rules:

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: Choose your Meetplace project
3. **Navigate to Firestore Database**: Click on "Firestore Database" in the left sidebar
4. **Go to Rules tab**: Click on the "Rules" tab at the top
5. **Replace the rules**: Copy and paste the rules from `firestore.rules` file
6. **Publish the rules**: Click "Publish" button

### Alternative: Quick Test Rules (Development Only)

If you want to test quickly during development, you can use these permissive rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **Warning**: These rules allow any authenticated user to read/write any document. Only use for development!

## 🚀 Firebase Authentication Setup

Make sure you have enabled the following authentication methods in Firebase Console:

1. **Email/Password**: Authentication → Sign-in method → Email/Password
2. **Google Sign-In**: Authentication → Sign-in method → Google
3. **Apple Sign-In**: Authentication → Sign-in method → Apple (iOS only)

## 📱 Firebase Storage Setup

For image uploads to work, you need to set up Firebase Storage:

1. **Go to Storage**: Click on "Storage" in the left sidebar
2. **Get Started**: Click "Get started" if not already set up
3. **Choose Security Rules**: Select "Start in test mode" for development
4. **Update Storage Rules** (optional):

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

## 🔧 Firebase App Check (Optional)

The debug secret shown in the logs can be added to Firebase App Check for additional security:

1. **Go to App Check**: Click on "App Check" in the left sidebar
2. **Add Debug Token**: Add the debug token: `cdb1ac71-1aba-4977-a01e-96f620e18e01`
3. **Enable App Check**: Enable App Check for your app

## ✅ Verification

After updating the rules, your app should work without permission errors. You should see:

- ✅ User search working
- ✅ Chat functionality working
- ✅ Profile viewing working
- ✅ No more "PERMISSION_DENIED" errors in logs

## 🆘 Troubleshooting

If you still see permission errors:

1. **Check Authentication**: Make sure users are properly authenticated
2. **Verify Rules**: Double-check that the rules are published
3. **Check User Data**: Ensure user documents have the correct structure
4. **Test in Firebase Console**: Try reading/writing documents manually

## 📋 Required Firestore Collections

Your Firestore should have these collections:

- `users` - User profiles and data
- `chats` - Chat metadata
- `messages` - Individual chat messages (subcollection of chats)
- `follows` - Follow relationships
- `posts` - User posts
- `interests` - Available interests

## 🔐 Security Best Practices

1. **Use proper rules**: Don't use overly permissive rules in production
2. **Validate data**: Add validation in your app code
3. **Monitor usage**: Check Firebase Console for unusual activity
4. **Regular updates**: Keep security rules updated as your app grows
