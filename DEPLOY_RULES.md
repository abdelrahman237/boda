# How to Deploy Firestore Security Rules

The permission error you're seeing is because Firestore security rules haven't been deployed yet. Follow these steps:

## Option 1: Using Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `cinemabookingapp-e1573`
3. Click on **Firestore Database** in the left menu
4. Go to the **Rules** tab
5. Copy the contents of `firestore.rules` file
6. Paste it into the rules editor
7. Click **Publish**

## Option 2: Using Firebase CLI

1. Install Firebase CLI (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase (if not already done):
   ```bash
   firebase init firestore
   ```
   - Select your existing project
   - Use the default file name: `firestore.rules`

4. Deploy the rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

## What the Rules Do

The rules allow:
- ✅ **Everyone** to read movies (for browsing)
- ✅ **Everyone** to create bookings (customers can book seats)
- ✅ **Everyone** to read bookings (to check seat availability)
- ✅ **Everyone** to create notifications (when bookings are made)
- ✅ **Everyone** to read/update notifications (vendors can see and mark as read)
- ✅ **Everyone** to read/write users (for registration/login)

**Note:** These rules are permissive for development. In production, you should add authentication checks.

After deploying the rules, try booking again - it should work!

