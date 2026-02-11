from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
from flask_mail import Mail, Message
from pymongo import MongoClient
from bson import ObjectId
import bcrypt
from datetime import datetime
import os
import google.generativeai as genai
from itsdangerous import URLSafeTimedSerializer, SignatureExpired 

app = Flask(__name__)

# --- CONFIGURATION ---
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)
app.config['SECRET_KEY'] = 'garden_genie_secret_key_123' 

# --- Flask-Mail Configuration ---
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'click.umer50@gmail.com' 
app.config['MAIL_PASSWORD'] = 'xhniqpqsunpoicdt' 
app.config['MAIL_DEFAULT_SENDER'] = 'click.umer50@gmail.com' 

mail = Mail(app)
s = URLSafeTimedSerializer(app.config['SECRET_KEY'])

# --- Google Gemini Configuration (AUTO-DETECT MODE) ---
GEMINI_API_KEY = "AIzaSyB2EgylaKPkGzfb_sff9w_0aVBIRlK_PT0"
genai.configure(api_key=GEMINI_API_KEY)

try:
    print("🔍 Checking for available models...")
    available_models = [m.name for m in genai.list_models() if 'generateContent' in m.supported_generation_methods]
    if 'models/gemini-1.5-flash' in available_models:
        model_id = 'models/gemini-1.5-flash'
    elif 'models/gemini-pro' in available_models:
        model_id = 'models/gemini-pro'
    else:
        model_id = available_models[0]
    
    model = genai.GenerativeModel(model_id)
    print(f"🚀 Successfully connected to: {model_id}")
except Exception as e:
    print(f"❌ Model detection failed: {e}")
    model = genai.GenerativeModel('gemini-pro')

# --- MongoDB Atlas Connection ---
MONGO_URI = "mongodb+srv://umer:Plantio123@cluster0.mmiqh2p.mongodb.net/plantio_db?retryWrites=true&w=majority"
try:
    client_db = MongoClient(MONGO_URI)
    db = client_db['plantio_db']
    users_collection = db['users']
    products_collection = db['products'] 
    # NEW: Collection for persistent chat history
    chat_history_collection = db['chat_history']
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
<head><title>Plantio - Reset Password</title></head>
<body><div style="text-align:center; padding:50px;"><h2>Plantio Reset</h2><form method="POST"><input type="password" name="password" placeholder="New Password" required><br><button type="submit">Update</button></form></div></body>
</html>
"""

# --- ROUTES ---

# 1. NEW: Fetch chat history for a user
@app.route('/api/chat-history/<user_id>', methods=['GET'])
def get_chat_history(user_id):
    try:
        # Fetching messages sorted by time
        history = list(chat_history_collection.find({"user_id": user_id}).sort("timestamp", 1))
        messages = []
        for doc in history:
            messages.append({"role": "user", "message": doc["user_message"], "time": doc["timestamp"].strftime("%H:%M")})
            messages.append({"role": "ai", "message": doc["ai_reply"], "time": doc["timestamp"].strftime("%H:%M")})
        return jsonify(messages), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@app.route('/chat', methods=['POST', 'OPTIONS'])
def chat():
    if request.method == 'OPTIONS': return jsonify({"status": "ok"}), 200
    try:
        data = request.get_json()
        user_message = data.get('message', '')
        user_id = data.get('userId', 'test_user') # Defaulting to test_user if not provided
        
        if not user_message: return jsonify({"reply": "Please type a message."}), 400
        
        prompt = (
            "System: Your name is 'Garden Genie'. You are an expert friendly gardening assistant for the Plantio app. "
            "If the user asks what your name is or who you are, always answer 'My name is Garden Genie!'. "
            "Write in plain simple text only. No stars, no markdown formatting. "
            f"User message: {user_message}"
        )
        
        response = model.generate_content(prompt)
        raw_reply = response.text if response.text else "I'm sorry, I didn't get that."
        clean_reply = raw_reply.replace("**", "").replace("*", "").replace("#", "").strip()

        # ✅ SAVE TO DATABASE for Persistence
        chat_history_collection.insert_one({
            "user_id": user_id,
            "user_message": user_message,
            "ai_reply": clean_reply,
            "timestamp": datetime.utcnow()
        })
        
        return jsonify({"reply": clean_reply}), 200
    except Exception as e:
        return jsonify({"reply": f"AI Error: {str(e)}"}), 500

@app.route('/api/products', methods=['GET'])
def get_all_products():
    try:
        products = list(products_collection.find())
        for p in products: p['_id'] = str(p['_id'])
        return jsonify(products), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

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

@app.route('/api/forgot-password', methods=['POST'])
def forgot_password():
    try:
        data = request.get_json()
        email = data['email'].strip().lower()
        user = users_collection.find_one({"email": email})
        if not user: return jsonify({"success": False, "message": "Not found"}), 404
        token = s.dumps(email, salt='password-reset-salt')
        reset_link = f"https://semipublic-monopoly-lorina.ngrok-free.dev/web/reset-password/{token}"
        msg = Message("Plantio Reset", recipients=[email])
        msg.body = f"Reset here: {reset_link}"
        mail.send(msg)
        return jsonify({"success": True, "message": "Link sent!"}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@app.route('/web/reset-password/<token>', methods=['GET', 'POST'])
def web_reset_password(token):
    try: email = s.loads(token, salt='password-reset-salt', max_age=1800)
    except: return "<h1>Link Expired!</h1>"
    if request.method == 'POST':
        new_pw = request.form.get('password')
        users_collection.update_one({"email": email}, {"$set": {"password": hash_password(new_pw)}})
        return "<h1>Success! ✅</h1>"
    return RESET_FORM_HTML

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)