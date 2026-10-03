# Babu's Food - Complete Setup Guide

## 📱 Project Structure

```
babus-food-app/
├── lib/
│   └── main.dart           # Flutter Android app
├── pubspec.yaml            # App dependencies
├── backend/
│   ├── app.py              # Python Flask server
│   ├── requirements.txt     # Python dependencies
│   └── .env.example         # Environment variables
├── admin/
│   └── dashboard.html       # Admin management panel
└── SETUP_GUIDE.md          # This file
```

---

## 🔧 Phase 1: Local Setup (Your Computer)

### Step 1.1: Install Flutter

1. Download Flutter from: https://flutter.dev/docs/get-started/install
2. Follow installation for your OS (Windows/Mac/Linux)
3. Verify installation:
   ```bash
   flutter --version
   ```

### Step 1.2: Install Backend Requirements

1. Navigate to `backend` folder
2. Copy `.env.example` to `.env`:
   ```bash
   cp backend/.env.example backend/.env
   ```
3. Install Python dependencies:
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

### Step 1.3: Setup Database (PostgreSQL)

1. Download PostgreSQL: https://www.postgresql.org/download/
2. Install it
3. Create database:
   ```bash
   createdb babus_food
   ```
4. Update `.env` file with your database URL:
   ```
   DATABASE_URL=postgresql://user:password@localhost:5432/babus_food
   ```

### Step 1.4: Run Backend Locally

```bash
cd backend
python app.py
```

Your backend will be at: `http://localhost:5000`

### Step 1.5: Build Flutter App

```bash
cd ..
flutter pub get
flutter run
```

This will launch the app on Android emulator or connected device.

---

## 🚀 Phase 2: Deploy to Cloud

### Step 2.1: Create Razorpay Account (UPI Payments)

1. Go to: https://razorpay.com
2. Sign up (FREE)
3. Verify your account
4. Get your **API Key** and **API Secret**
5. Add to `.env`:
   ```
   RAZORPAY_KEY_ID=your_key_here
   RAZORPAY_KEY_SECRET=your_secret_here
   ```

### Step 2.2: Deploy Backend to Railway

1. Go to: https://railway.app
2. Sign up with GitHub
3. Create new project
4. Select "Deploy from GitHub"
5. Connect your GitHub repo (or upload files)
6. Select `backend` folder
7. Add environment variables from `.env`
8. Deploy

**Result:** Your backend URL will be like: `https://babus-food.railway.app`

### Step 2.3: Update Flutter App with Backend URL

In `lib/main.dart`, replace:
```dart
Uri.parse('http://localhost:5000/api/...')
```

With your Railway URL:
```dart
Uri.parse('https://your-backend-url/api/...')
```

### Step 2.4: Build APK for Google Play Store

```bash
flutter build apk --release
```

This creates: `build/app/outputs/flutter-app.apk`

---

## 📲 Phase 3: Upload to Google Play Store

### Step 3.1: Create Google Play Developer Account

1. Go to: https://play.google.com/console
2. Click "Create account"
3. Pay ₹2500 (one-time fee)
4. Verify your identity
5. Accept agreements

### Step 3.2: Create App in Play Store

1. In Play Console, click "Create app"
2. Name: "Babu's Food"
3. Category: "Food & Drink"
4. Upload APK file
5. Fill in description, screenshots, etc.

### Step 3.3: Submit for Review

1. Complete all required fields
2. Add screenshots and description
3. Submit for review
4. Google reviews in 24-48 hours
5. ✅ App goes live!

---

## 📊 Admin Dashboard

Your admin panel is at: `admin/dashboard.html`

**Features:**
- ✅ Add/Edit/Delete products
- ✅ View all orders
- ✅ Update order status
- ✅ See analytics (total revenue, orders, etc.)
- ✅ Manage product availability

**How to access:**
1. Open `admin/dashboard.html` in browser
2. Login with your email
3. Manage everything!

---

## 💡 Step-by-Step Quick Start

### For Development (First Time):

```bash
# 1. Install requirements
cd backend
pip install -r requirements.txt

# 2. Setup .env
cp .env.example .env

# 3. Run backend
python app.py

# 4. In new terminal, run app
cd ..
flutter run
```

### For Deployment:

```bash
# 1. Create APK
flutter build apk --release

# 2. Deploy backend to Railway (using their UI)

# 3. Update app URL in code

# 4. Upload APK to Play Store
```

---

## 📝 Initial Products (Pre-loaded)

Your app already has these products:
1. Chicken Thali - ₹200
2. Veg Thali - ₹120
3. Dal Roti - ₹90

**To add more:**
1. Open admin dashboard
2. Click "Add New Product"
3. Enter name, price, description
4. Submit

---

## 🛠 Troubleshooting

### Backend won't start?
- Check PostgreSQL is running
- Verify DATABASE_URL in .env
- Check Python version (3.8+)

### App can't connect to backend?
- Make sure backend is running
- Check URL in `lib/main.dart`
- For production, use Railway URL (not localhost)

### Google Play rejection?
- Ensure app name, description are clear
- Add proper screenshots
- Verify no policy violations
- Contact Google Play support

---

## 📞 Support

For issues:
1. Check backend logs: `python app.py`
2. Check browser console (F12) for app errors
3. Verify all `.env` variables are set

---

## 💰 Cost Breakdown (Year 1)

| Item | Cost |
|------|------|
| Google Play Dev Account | ₹2,500 |
| Railway (Free tier) | ₹0 |
| Razorpay | ₹0 |
| Domain (optional) | ₹0-500 |
| **Total Year 1** | **₹2,500** |

**Year 2+:** ₹800-1500/month (if you upgrade from free Railway tier)

---

## 🎉 You're All Set!

Your complete Babu's Food app is ready:
- ✅ Android app (Google Play Store)
- ✅ Admin dashboard (manage products & orders)
- ✅ Payment integration (UPI via Razorpay)
- ✅ Order tracking system
- ✅ Cloud deployment (Railway)

**Next Steps:**
1. Follow setup guide above
2. Create Google Play account
3. Deploy backend
4. Upload APK to Play Store
5. Start selling! 🍛
