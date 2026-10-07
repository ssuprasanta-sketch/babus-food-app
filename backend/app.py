from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import inspect, text
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import os
import secrets
from dotenv import load_dotenv
import requests
import razorpay

load_dotenv()

app = Flask(__name__)
CORS(app)

# Razorpay setup — RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET are set as
# environment variables in Railway. If they're missing, payment routes
# return a clear error instead of crashing the whole server.
RAZORPAY_KEY_ID = os.getenv('RAZORPAY_KEY_ID')
RAZORPAY_KEY_SECRET = os.getenv('RAZORPAY_KEY_SECRET')
razorpay_client = (
    razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))
    if RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET else None
)

# Database Configuration
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv(
    'DATABASE_URL',
    'postgresql://user:password@localhost:5432/babus_food'
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Models
class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    auth_token = db.Column(db.String(64), unique=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'token': self.auth_token,
        }

class Product(db.Model):
    __tablename__ = 'products'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(500))
    price = db.Column(db.Float, nullable=False)
    image_url = db.Column(db.String(500))
    category = db.Column(db.String(20), default='veg')  # 'veg', 'non-veg', or 'meals'
    is_available = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'price': self.price,
            'image_url': self.image_url,
            'category': self.category or 'veg',
            'is_available': self.is_available,
        }

class Order(db.Model):
    __tablename__ = 'orders'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    customer_name = db.Column(db.String(100), nullable=False)
    customer_phone = db.Column(db.String(20), nullable=False)
    customer_address = db.Column(db.Text, nullable=False)
    house_details = db.Column(db.String(200))  # House/Flat/Plot No.
    area_details = db.Column(db.String(300))   # Area / full address
    latitude = db.Column(db.Float)
    longitude = db.Column(db.Float)
    coupon_code = db.Column(db.String(50))
    discount_amount = db.Column(db.Float, default=0)
    total_amount = db.Column(db.Float, nullable=False)
    items = db.Column(db.Text, nullable=False)  # JSON string
    status = db.Column(db.String(50), default='pending')  # pending, confirmed, delivered
    payment_status = db.Column(db.String(50), default='pending')  # pending, completed, failed
    payment_id = db.Column(db.String(100))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'customer_name': self.customer_name,
            'customer_phone': self.customer_phone,
            'customer_address': self.customer_address,
            'house_details': self.house_details,
            'area_details': self.area_details,
            'latitude': self.latitude,
            'longitude': self.longitude,
            'coupon_code': self.coupon_code,
            'discount_amount': self.discount_amount or 0,
            'total_amount': self.total_amount,
            'items': self.items,
            'status': self.status,
            'payment_status': self.payment_status,
            # Append 'Z' so clients correctly read this as UTC and convert to local time
            'created_at': self.created_at.isoformat() + 'Z',
        }

class Coupon(db.Model):
    __tablename__ = 'coupons'

    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(50), unique=True, nullable=False)
    discount_percent = db.Column(db.Float, nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'code': self.code,
            'discount_percent': self.discount_percent,
            'is_active': self.is_active,
        }

# Routes - Authentication
@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.json
        name = data.get('name', '').strip()
        email = data.get('email', '').strip().lower()
        phone = data.get('phone', '').strip()
        password = data.get('password', '')

        if not name or not email or not phone or not password:
            return jsonify({'success': False, 'error': 'All fields are required'}), 400

        if User.query.filter_by(email=email).first():
            return jsonify({'success': False, 'error': 'An account with this email already exists'}), 409

        user = User(
            name=name,
            email=email,
            phone=phone,
            password_hash=generate_password_hash(password),
            auth_token=secrets.token_hex(24),
        )
        db.session.add(user)
        db.session.commit()

        return jsonify({'success': True, 'user': user.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.json
        # Accept either an 'identifier' (email or phone) or legacy 'email' field
        identifier = data.get('identifier', data.get('email', '')).strip().lower()
        password = data.get('password', '')

        user = User.query.filter(
            (User.email == identifier) | (User.phone == identifier)
        ).first()

        if not user or not check_password_hash(user.password_hash, password):
            return jsonify({'success': False, 'error': 'Invalid email/phone or password'}), 401

        # Issue a fresh token each login
        user.auth_token = secrets.token_hex(24)
        db.session.commit()

        return jsonify({'success': True, 'user': user.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/auth/google', methods=['POST'])
def google_auth():
    """
    Login or sign up using a Google ID token from the app's Google Sign-In flow.
    Requires GOOGLE_CLIENT_ID to be set as an environment variable in Railway,
    matching the OAuth Client ID created in Google Cloud Console.
    """
    try:
        from google.oauth2 import id_token as google_id_token
        from google.auth.transport import requests as google_requests

        data = request.json
        token = data.get('id_token')
        if not token:
            return jsonify({'success': False, 'error': 'Missing Google id_token'}), 400

        client_id = os.getenv('GOOGLE_CLIENT_ID')
        if not client_id:
            return jsonify({
                'success': False,
                'error': 'Google Sign-In is not configured on the server yet (missing GOOGLE_CLIENT_ID).'
            }), 500

        idinfo = google_id_token.verify_oauth2_token(token, google_requests.Request(), client_id)
        email = idinfo.get('email', '').strip().lower()
        name = idinfo.get('name', email.split('@')[0])

        if not email:
            return jsonify({'success': False, 'error': 'Google account has no email'}), 400

        user = User.query.filter_by(email=email).first()
        if not user:
            # First time signing in with Google — create an account automatically
            user = User(
                name=name,
                email=email,
                phone=data.get('phone', ''),
                password_hash=generate_password_hash(secrets.token_hex(16)),  # unusable random password
                auth_token=secrets.token_hex(24),
            )
            db.session.add(user)
        else:
            user.auth_token = secrets.token_hex(24)

        db.session.commit()
        return jsonify({'success': True, 'user': user.to_dict()}), 200
    except ValueError as e:
        return jsonify({'success': False, 'error': f'Invalid Google token: {str(e)}'}), 401
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

# Routes - Products
@app.route('/api/products', methods=['GET'])
def get_products():
    try:
        products = Product.query.filter_by(is_available=True).all()
        return jsonify({
            'success': True,
            'products': [p.to_dict() for p in products]
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/admin/products', methods=['GET'])
def get_all_products_admin():
    """Returns every product, available or not — for the admin dashboard,
    so sold-out items can still be found and re-enabled."""
    try:
        products = Product.query.order_by(Product.created_at.desc()).all()
        return jsonify({
            'success': True,
            'products': [p.to_dict() for p in products]
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/products', methods=['POST'])
def create_product():
    try:
        data = request.json
        product = Product(
            name=data['name'],
            description=data.get('description', ''),
            price=data['price'],
            image_url=data.get('image_url', ''),
            category=data.get('category', 'veg'),
        )
        db.session.add(product)
        db.session.commit()
        return jsonify({
            'success': True,
            'product': product.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/products/<int:product_id>', methods=['PUT'])
def update_product(product_id):
    try:
        product = Product.query.get(product_id)
        if not product:
            return jsonify({'success': False, 'error': 'Product not found'}), 404
        
        data = request.json
        product.name = data.get('name', product.name)
        product.description = data.get('description', product.description)
        product.price = data.get('price', product.price)
        product.image_url = data.get('image_url', product.image_url)
        product.category = data.get('category', product.category)
        product.is_available = data.get('is_available', product.is_available)
        
        db.session.commit()
        return jsonify({
            'success': True,
            'product': product.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/products/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    try:
        product = Product.query.get(product_id)
        if not product:
            return jsonify({'success': False, 'error': 'Product not found'}), 404
        
        db.session.delete(product)
        db.session.commit()
        return jsonify({'success': True}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

# Routes - Coupons
@app.route('/api/coupons', methods=['GET'])
def get_coupons():
    try:
        coupons = Coupon.query.order_by(Coupon.created_at.desc()).all()
        return jsonify({'success': True, 'coupons': [c.to_dict() for c in coupons]}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/coupons', methods=['POST'])
def create_coupon():
    try:
        data = request.json
        code = data.get('code', '').strip().upper()
        discount_percent = data.get('discount_percent')

        if not code or discount_percent is None:
            return jsonify({'success': False, 'error': 'Code and discount percent are required'}), 400

        if Coupon.query.filter_by(code=code).first():
            return jsonify({'success': False, 'error': 'A coupon with this code already exists'}), 409

        coupon = Coupon(code=code, discount_percent=float(discount_percent))
        db.session.add(coupon)
        db.session.commit()
        return jsonify({'success': True, 'coupon': coupon.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/coupons/<int:coupon_id>', methods=['DELETE'])
def delete_coupon(coupon_id):
    try:
        coupon = Coupon.query.get(coupon_id)
        if not coupon:
            return jsonify({'success': False, 'error': 'Coupon not found'}), 404
        db.session.delete(coupon)
        db.session.commit()
        return jsonify({'success': True}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/coupons/validate', methods=['POST'])
def validate_coupon():
    try:
        data = request.json
        code = data.get('code', '').strip().upper()
        coupon = Coupon.query.filter_by(code=code, is_active=True).first()

        if not coupon:
            return jsonify({'success': False, 'error': 'Invalid or expired coupon code'}), 404

        return jsonify({
            'success': True,
            'discount_percent': coupon.discount_percent,
            'code': coupon.code,
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# Routes - Payment (Razorpay)
@app.route('/api/payment/create-order', methods=['POST'])
def create_payment_order():
    try:
        if not razorpay_client:
            return jsonify({'success': False, 'error': 'Payment gateway is not configured on the server yet'}), 500

        data = request.json
        amount = data.get('amount')
        if not amount:
            return jsonify({'success': False, 'error': 'Amount is required'}), 400

        amount_paise = int(round(float(amount) * 100))  # Razorpay expects paise, not rupees
        razorpay_order = razorpay_client.order.create({
            'amount': amount_paise,
            'currency': 'INR',
            'payment_capture': 1,
        })

        return jsonify({
            'success': True,
            'order_id': razorpay_order['id'],
            'amount': amount_paise,
            'key_id': RAZORPAY_KEY_ID,
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/payment/verify', methods=['POST'])
def verify_payment():
    try:
        if not razorpay_client:
            return jsonify({'success': False, 'error': 'Payment gateway is not configured on the server yet'}), 500

        data = request.json
        params = {
            'razorpay_order_id': data.get('razorpay_order_id'),
            'razorpay_payment_id': data.get('razorpay_payment_id'),
            'razorpay_signature': data.get('razorpay_signature'),
        }
        razorpay_client.utility.verify_payment_signature(params)
        return jsonify({'success': True}), 200
    except razorpay.errors.SignatureVerificationError:
        return jsonify({'success': False, 'error': 'Payment verification failed — this payment could not be confirmed as genuine'}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# Routes - Orders
@app.route('/api/orders', methods=['POST'])
def create_order():
    try:
        import json as json_lib
        data = request.json
        order = Order(
            user_id=data.get('user_id'),
            customer_name=data['customer_name'],
            customer_phone=data['customer_phone'],
            customer_address=data['customer_address'],
            house_details=data.get('house_details'),
            area_details=data.get('area_details'),
            latitude=data.get('latitude'),
            longitude=data.get('longitude'),
            coupon_code=data.get('coupon_code'),
            discount_amount=data.get('discount_amount', 0),
            total_amount=data['total'],
            items=json_lib.dumps(data['items']),
            status='pending',
            payment_status=data.get('payment_status', 'pending'),
            payment_id=data.get('payment_id'),
        )
        db.session.add(order)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'order': order.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    """Updates a user's own profile fields — currently just phone number,
    used to fill in a contact number for accounts created via Google Sign-In
    (which don't collect one automatically)."""
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'success': False, 'error': 'User not found'}), 404

        data = request.json
        if data.get('phone'):
            user.phone = data['phone'].strip()

        db.session.commit()
        return jsonify({'success': True, 'user': user.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/users/<int:user_id>/orders', methods=['GET'])
def get_user_orders(user_id):
    try:
        orders = Order.query.filter_by(user_id=user_id).order_by(Order.created_at.desc()).all()
        return jsonify({
            'success': True,
            'orders': [o.to_dict() for o in orders]
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/orders', methods=['GET'])
def get_orders():
    try:
        orders = Order.query.order_by(Order.created_at.desc()).all()
        return jsonify({
            'success': True,
            'orders': [o.to_dict() for o in orders]
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/orders/<int:order_id>', methods=['PUT'])
def update_order(order_id):
    try:
        order = Order.query.get(order_id)
        if not order:
            return jsonify({'success': False, 'error': 'Order not found'}), 404
        
        data = request.json
        if 'status' in data:
            order.status = data['status']
        if 'payment_status' in data:
            order.payment_status = data['payment_status']
        
        db.session.commit()
        return jsonify({
            'success': True,
            'order': order.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

# Health check
@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'}), 200

# Create database tables on startup — runs whether launched via
# `python app.py` locally or via gunicorn in production (Railway).
# Also safely adds any new columns to tables that already exist,
# without deleting existing data.
with app.app_context():
    db.create_all()
    inspector = inspect(db.engine)
    if 'products' in inspector.get_table_names():
        existing_columns = [col['name'] for col in inspector.get_columns('products')]
        if 'category' not in existing_columns:
            with db.engine.connect() as conn:
                conn.execute(text("ALTER TABLE products ADD COLUMN category VARCHAR(20) DEFAULT 'veg'"))
                conn.commit()

    if 'orders' in inspector.get_table_names():
        existing_order_columns = [col['name'] for col in inspector.get_columns('orders')]
        new_order_columns = {
            'house_details': 'VARCHAR(200)',
            'area_details': 'VARCHAR(300)',
            'latitude': 'FLOAT',
            'longitude': 'FLOAT',
            'coupon_code': 'VARCHAR(50)',
            'discount_amount': 'FLOAT DEFAULT 0',
        }
        with db.engine.connect() as conn:
            for col_name, col_type in new_order_columns.items():
                if col_name not in existing_order_columns:
                    conn.execute(text(f"ALTER TABLE orders ADD COLUMN {col_name} {col_type}"))
            conn.commit()

if __name__ == '__main__':
    app.run(debug=True, port=5000)
