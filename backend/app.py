from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
from flask_mail import Mail, Message
from pymongo import MongoClient
from bson import ObjectId
import bcrypt
from datetime import datetime
import os
import google.generativeai as genai
from itsdangerous import URLSafeTimedSerializer, SignatureExpired # For secure tokens

app = Flask(__name__)

# --- CONFIGURATION ---
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)
app.config['SECRET_KEY'] = 'garden_genie_secret_key_123' # Change this for production

# --- Flask-Mail Configuration ---
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'click.umer50@gmail.com' 
app.config['MAIL_PASSWORD'] = 'xhniqpqsunpoicdt' 

# ✅ YEH RAHI WOH LINE JO MISSING THI
app.config['MAIL_DEFAULT_SENDER'] = 'click.umer50@gmail.com' 

mail = Mail(app)

# Token Serializer
s = URLSafeTimedSerializer(app.config['SECRET_KEY'])

# --- Google Gemini Configuration ---
GEMINI_API_KEY = "AIzaSyDjBgIZHmZlr91TGk5mgaJ_r8hovHnDoAM"
genai.configure(api_key=GEMINI_API_KEY)

try:
    model = genai.GenerativeModel('gemini-2.0-flash')
    print("✅ Gemini 2.0 Flash Model loaded successfully")
except Exception as e:
    model = genai.GenerativeModel('gemini-flash-latest')

# --- MongoDB Atlas Connection ---
MONGO_URI = "mongodb+srv://umer:Plantio123@cluster0.mmiqh2p.mongodb.net/plantio_db?retryWrites=true&w=majority"
try:
    client_db = MongoClient(MONGO_URI)
    db = client_db['plantio_db']
    users_collection = db['users']
    print("✅ MongoDB Atlas Connected!")
except Exception as e:
    print(f"❌ Connection error: {e}")

# --- Helper Functions ---
def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

def verify_password(password: str, hashed: bytes) -> bool:
    return bcrypt.checkpw(password.encode('utf-8'), hashed)

# --- Web Page HTML (Reset Password Form) ---
RESET_FORM_HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>Plantio - Reset Password</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background-color: #f5f5f5; }
        .card { background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); width: 100%; max-width: 400px; text-align: center; }
        h2 { color: #5B8E55; margin-bottom: 20px; }
        input { width: 100%; padding: 12px; margin: 10px 0; border: 1px solid #ddd; border-radius: 8px; box-sizing: border-box; font-size: 16px; }
        button { width: 100%; padding: 12px; background-color: #5B8E55; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; font-weight: bold; }
        button:hover { background-color: #4a7545; }
        .error { color: red; font-size: 14px; margin-bottom: 10px; }
        .success { color: #5B8E55; font-size: 18px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="card">
        <h2>Plantio</h2>
        <p>Enter your new password below</p>
        <form method="POST">
            <input type="password" name="password" placeholder="New Password" required minlength="6">
            <input type="password" name="confirm_password" placeholder="Confirm Password" required minlength="6">
            <button type="submit">Update Password</button>
        </form>
    </div>
</body>
</html>
"""

# --- ROUTES ---

@app.route('/chat', methods=['POST', 'OPTIONS'])
def chat():
    if request.method == 'OPTIONS': return jsonify({"status": "ok"}), 200
    try:
        data = request.get_json()
        user_message = data.get('message', '')
        if not user_message: return jsonify({"reply": "Please type a message."}), 400
        prompt = f"System: You are an expert gardening assistant. Keep answers short, friendly and helpful. User: {user_message}"
        response = model.generate_content(prompt)
        return jsonify({"reply": response.text}), 200
    except Exception as e:
        return jsonify({"reply": f"Server Error: {str(e)}"}), 500

@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        name, email, password = data['name'].strip(), data['email'].strip().lower(), data['password']
        if users_collection.find_one({"email": email}):
            return jsonify({"success": False, "message": "Email already registered"}), 400
        user_doc = {"name": name, "email": email, "password": hash_password(password), "created_at": datetime.utcnow()}
        users_collection.insert_one(user_doc)
        return jsonify({"success": True, "message": "User registered successfully"}), 201
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        email, password = data['email'].strip().lower(), data['password']
        user = users_collection.find_one({"email": email})
        if not user or not verify_password(password, user['password']):
            return jsonify({"success": False, "message": "Invalid email or password"}), 401
        return jsonify({"success": True, "message": "Login successful", "user": {"id": str(user['_id']), "name": user['name'], "email": user['email']}}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

# --- FORGOT PASSWORD (SEND EMAIL) ---
@app.route('/api/forgot-password', methods=['POST'])
def forgot_password():
    try:
        data = request.get_json()
        email = data['email'].strip().lower()
        user = users_collection.find_one({"email": email})
        
        if not user:
            return jsonify({"success": False, "message": "This email is not registered!"}), 404
        
        # Create Token (expires in 30 minutes)
        token = s.dumps(email, salt='password-reset-salt')
        # Link points to this Flask server's Web Route
        reset_link = f"http://192.168.18.77:5000/web/reset-password/{token}"
        
        msg = Message("Plantio - Password Reset Request", recipients=[email])
        msg.body = f"Hi {user['name']},\n\nTo reset your password, click the link below:\n{reset_link}\n\nIf you didn't request this, please ignore this email."
        msg.html = f"""<h3>Plantio Password Reset</h3>
                       <p>Hi {user['name']},</p>
                       <p>Please click the button below to reset your password:</p>
                       <a href="{reset_link}" style="background:#5B8E55; color:white; padding:10px 20px; text-decoration:none; border-radius:5px;">Reset Password</a>
                       <p>This link will expire in 30 minutes.</p>"""
        mail.send(msg)
        
        return jsonify({"success": True, "message": "Reset link sent! Please check your Gmail inbox (or spam)."}), 200
    except Exception as e:
        return jsonify({"success": False, "message": f"Email error: {str(e)}"}), 500

# --- WEB ROUTE: HTML PASSWORD RESET ---
@app.route('/web/reset-password/<token>', methods=['GET', 'POST'])
def web_reset_password(token):
    try:
        email = s.loads(token, salt='password-reset-salt', max_age=1800)
    except SignatureExpired:
        return "<h1>Link Expired!</h1><p>The reset link is older than 30 minutes. Please request a new one from the app.</p>"
    except:
        return "<h1>Invalid Link!</h1>"

    if request.method == 'POST':
        new_password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')

        if new_password != confirm_password:
            return RESET_FORM_HTML.replace("<p>Enter your new password below</p>", "<p class='error'>Passwords do not match!</p>")

        # Update Password in DB
        hashed_pw = hash_password(new_password)
        users_collection.update_one({"email": email}, {"$set": {"password": hashed_pw}})
        
        return "<div style='text-align:center; padding:50px;'><h1>Success! ✅</h1><p>Password updated successfully. You can now login in the app.</p></div>"

    return RESET_FORM_HTML

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)