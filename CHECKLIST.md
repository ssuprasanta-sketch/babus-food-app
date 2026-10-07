# Babu's Food - Deployment Checklist

## ✅ Before You Start

- [ ] Read SETUP_GUIDE.md completely
- [ ] Have Flutter installed
- [ ] Have Python 3.8+ installed
- [ ] Have PostgreSQL installed
- [ ] Have GitHub account (optional, for easier deployment)

---

## ✅ Phase 1: Local Setup

### Backend Setup
- [ ] Navigate to `backend` folder
- [ ] Copy `.env.example` to `.env`
- [ ] Install requirements: `pip install -r requirements.txt`
- [ ] Create PostgreSQL database: `createdb babus_food`
- [ ] Update DATABASE_URL in `.env`
- [ ] Run backend: `python app.py`
- [ ] Verify at: http://localhost:5000/health (should return `{"status": "ok"}`)

### App Setup
- [ ] Run: `flutter pub get`
- [ ] Run: `flutter run` (on emulator or device)
- [ ] Verify app loads and shows products

### Admin Dashboard
- [ ] Open `admin/dashboard.html` in browser
- [ ] Verify products list appears
- [ ] Try adding a new product
- [ ] Try updating order status

---

## ✅ Phase 2: Get Accounts Ready

### Razorpay (UPI Payments)
- [ ] Go to https://razorpay.com
- [ ] Create free account
- [ ] Verify email & phone
- [ ] Get API Key and Secret
- [ ] Add to `.env`:
  ```
  RAZORPAY_KEY_ID=xxx
  RAZORPAY_KEY_SECRET=xxx
  ```

### Google Play Developer
- [ ] Go to https://play.google.com/console
- [ ] Pay ₹2,500 registration fee
- [ ] Verify phone number
- [ ] Accept terms & conditions
- [ ] Setup account is complete

---

## ✅ Phase 3: Prepare for Deployment

### Build APK
- [ ] Update backend URL in `lib/main.dart` (change localhost to your Railway URL)
- [ ] Run: `flutter build apk --release`
- [ ] Wait for build to complete
- [ ] Verify file: `build/app/outputs/app-release.apk`

### Prepare Backend for Cloud
- [ ] Commit all code to GitHub (if using Railway)
- [ ] Verify `.env` file has all required variables:
  - [ ] DATABASE_URL
  - [ ] RAZORPAY_KEY_ID
  - [ ] RAZORPAY_KEY_SECRET
- [ ] Test locally one more time

---

## ✅ Phase 4: Deploy Backend

### Using Railway
- [ ] Go to https://railway.app
- [ ] Sign up with GitHub
- [ ] Create new project
- [ ] Connect GitHub repo (or upload files manually)
- [ ] Select `backend` folder as root
- [ ] Add environment variables from `.env`
- [ ] Deploy
- [ ] Copy your Railway URL (e.g., `https://babus-food.railway.app`)
- [ ] Update URL in Flutter app

### Alternative: Using Render
- [ ] Go to https://render.com
- [ ] Create web service
- [ ] Connect GitHub
- [ ] Set environment variables
- [ ] Deploy
- [ ] Get your URL

---

## ✅ Phase 5: Upload to Play Store

### Create App Listing
- [ ] Open Google Play Console
- [ ] Click "Create new app"
- [ ] Name: "Babu's Food"
- [ ] Select category: "Food & Drink"
- [ ] Accept declaration

### Fill App Details
- [ ] App title: "Babu's Food"
- [ ] Short description (80 chars): "Order delicious food online with UPI payment"
- [ ] Full description: Describe your food items and services
- [ ] Upload app icon (512x512 PNG)
- [ ] Upload screenshots (at least 2)
- [ ] Add privacy policy (required)

### Upload APK
- [ ] Go to "Releases" → "Production"
- [ ] Click "Create new release"
- [ ] Upload APK file (`app-release.apk`)
- [ ] Set version code and name
- [ ] Add release notes

### Review & Submit
- [ ] Complete all sections marked with red *
- [ ] Review content rating questionnaire
- [ ] Set pricing (Free)
- [ ] Accept Play Policies
- [ ] Click "Submit for Review"

### Monitor Review
- [ ] Check email for status updates
- [ ] Review usually takes 24-48 hours
- [ ] Once approved, app goes live! 🎉

---

## ✅ Phase 6: After Launch

### Monitor Performance
- [ ] Check Google Play Console daily for first week
- [ ] Monitor crashes and errors
- [ ] Review user ratings and feedback

### Manage Products
- [ ] Login to admin dashboard
- [ ] Add more food items as needed
- [ ] Update prices when needed
- [ ] Mark items as unavailable when out of stock

### Process Orders
- [ ] Check admin dashboard regularly
- [ ] View new orders
- [ ] Update order status (pending → confirmed → delivered)
- [ ] Monitor payment status

### Collect Payments
- [ ] Razorpay automatically deposits to your bank
- [ ] Check Razorpay dashboard for payment details
- [ ] Monitor daily revenue

---

## ⚠️ Important Notes

1. **Backup Your Data:** Regularly backup your database
2. **Security:** Use strong passwords for admin panel
3. **Customer Support:** Add email/phone for customer inquiries
4. **Updates:** When you update app, create new APK and upload to Play Store
5. **Monitoring:** Keep an eye on server logs for errors

---

## 🆘 Stuck? Here's Help

### Error: "Can't connect to database"
- [ ] Verify PostgreSQL is running
- [ ] Check DATABASE_URL in `.env` is correct
- [ ] Verify database exists: `psql -l`

### Error: "Flutter can't connect to backend"
- [ ] Verify backend is running
- [ ] Check URL in `lib/main.dart` is correct
- [ ] For production, use Railway URL (not localhost)

### Error: "APK build failed"
- [ ] Run: `flutter clean`
- [ ] Run: `flutter pub get`
- [ ] Try again: `flutter build apk --release`

### Google Play rejects app
- [ ] Check rejection reason in email
- [ ] Usually: missing privacy policy or misleading content
- [ ] Fix issues and resubmit

---

## 📞 When to Ask for Help

- [ ] Backend error 500
- [ ] Database connection fails
- [ ] APK won't build
- [ ] Play Store rejects app
- [ ] Users report crashes
- [ ] Payment not working

---

## ✨ You're Ready!

Follow this checklist step by step, and your Babu's Food app will be live in 2-3 weeks! 🚀

Good luck! 🍛
