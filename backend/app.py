from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_mail import Mail, Message
from pymongo import MongoClient
import bcrypt
from datetime import datetime
import os
import io
import requests
import base64
import json
from dotenv import load_dotenv
from PIL import Image
import smtplib
import traceback

# --- Firebase Admin SDK (For Live Products) ---
import firebase_admin
from firebase_admin import credentials, firestore

# --- ML Libraries ---
import torch
import torch.nn.functional as F
from transformers import MobileNetV2ForImageClassification
from torchvision import transforms

load_dotenv() 

from itsdangerous import URLSafeTimedSerializer

# ==========================================
# 🔥 FIREBASE INITIALIZATION
# ==========================================
try:
    if not firebase_admin._apps:
        # Ensure serviceAccountKey.json is in your backend folder
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
    db_firestore = firestore.client()
    print("🔥 Firebase Firestore Connected Successfully!")
except Exception as e:
    print(f"❌ Firebase Init Error: {e}")

app = Flask(__name__)
CORS(app)

# ==========================================
# ✅ MAIL CONFIGURATION (GMAIL & BREVO)
# ==========================================
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587           
app.config['MAIL_USE_TLS'] = True         
app.config['MAIL_USE_SSL'] = False        
app.config['MAIL_USERNAME'] = os.getenv('MAIL_USERNAME')
app.config['MAIL_PASSWORD'] = os.getenv('MAIL_PASSWORD')
app.config['MAIL_DEFAULT_SENDER'] = os.getenv('MAIL_USERNAME')
app.config['MAIL_ASCII_ATTACHMENTS'] = False
app.config['MAIL_DEBUG'] = True
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'a_very_secret_default_string')

mail = Mail(app)
s = URLSafeTimedSerializer(app.config['SECRET_KEY'])

# --- Global Disease Database Load ---
try:
    with open('disease_info.json', 'r') as f:
        DISEASE_DB = json.load(f)
    print("📚 disease_info.json loaded!")
except Exception as e:
    print(f"⚠️ Warning: Could not load disease_info.json: {e}")
    DISEASE_DB = {}

# --- Groq AI Configuration ---
GROQ_API_KEY = os.getenv('GROQ_API_KEY')
GROQ_TEXT_MODEL = "llama-3.1-8b-instant"
GROQ_VISION_MODEL = "llama-3.2-11b-vision-preview" 

def call_groq_ai(prompt, image_base64=None, system_context=None):
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"}
    model = GROQ_VISION_MODEL if image_base64 else GROQ_TEXT_MODEL
    
    # Strict System Instruction
    if not system_context:
        system_context = "Your name is Garden Genie. You are a friendly gardening assistant for the app Plantio. Plain text only."

    messages = [{"role": "system", "content": system_context}]
    if image_base64:
        messages.append({"role": "user", "content": [{"type": "text", "text": prompt}, {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + image_base64}}]})
    else:
        messages.append({"role": "user", "content": prompt})

    payload = {"model": model, "messages": messages, "temperature": 0.1} # Lower temp for accuracy
    try:
        response = requests.post(url, json=payload, headers=headers)
        res_json = response.json()
        return res_json['choices'][0]['message']['content']
    except Exception as e: return f"AI Error: {str(e)}"
    
# --- ML Model Loading ---
print("🔍 Loading Disease model...")
model_path = "disease_model"
data_transforms = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])
try:
    model = MobileNetV2ForImageClassification.from_pretrained(model_path)
    model.eval()
    print("🚀 Disease model loaded!")
except Exception as e:
    model = None

# --- MongoDB Atlas (For Auth & Logs) ---
try:
    client_db = MongoClient(os.getenv('MONGO_URI'))
    db = client_db['plantio_db']
    users_collection = db['users']
    chat_history_collection = db['chat_history']
    print("✅ MongoDB Connected!")
except Exception as e:
    print(f"❌ DB Error: {e}")

# --- Helper Functions ---
def hash_password(password: str) -> str: return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
def verify_password(password: str, hashed: bytes) -> bool: return bcrypt.checkpw(password.encode('utf-8'), hashed)

# --- ML Predict Logic ---
def validate_leaf_gate(image_bytes: bytes):
    if not GROQ_API_KEY: return True, "Plant"
    prompt = "Identify if there is any plant foliage in this image. Reply: YES | [Plant Name] or NO."
    try:
        img_b64 = base64.b64encode(image_bytes).decode('utf-8')
        res = call_groq_ai(prompt, img_b64).strip()
        if "YES" in res.upper():
            return True, (res.split("|")[-1].strip() if "|" in res else "Plant")
        return False, None
    except: return True, "Plant"

@app.route('/predict', methods=['POST'])
def predict():
    if model is None: return jsonify({"error": "Model missing"}), 500
    file_bytes = request.files['file'].read()
    try:
        image = Image.open(io.BytesIO(file_bytes)).convert("RGB")
        img_tensor = data_transforms(image).unsqueeze(0)
        with torch.no_grad():
            outputs = model(img_tensor); probs = F.softmax(outputs.logits, dim=-1)
            idx = torch.argmax(probs, dim=-1).item(); conf = probs[0][idx].item()
        
        accuracy = round(conf * 100, 2)
        if conf >= 0.85: is_leaf, plant_identity = True, "Detected Plant"
        else: is_leaf, plant_identity = validate_leaf_gate(file_bytes)
        
        if not is_leaf: return jsonify({"status": "rejected", "disease": "Not a leaf.", "confidence": accuracy}), 200
        if conf < 0.70: return jsonify({"status": "low_confidence", "disease": "Unclear scan.", "confidence": accuracy}), 200

        labels = getattr(model.config, "id2label", {}); full_label = str(labels.get(idx, labels.get(str(idx), "Unknown")))
        extra_info = DISEASE_DB.get(full_label)
        if not extra_info:
            words = set(full_label.lower().replace("_", " ").split())
            for k, v in DISEASE_DB.items():
                if set(k.lower().replace("_", " ").split()).issubset(words): extra_info = v; break
        if not extra_info:
            extra_info = {"title": full_label.split("___")[-1].replace("_", " ").title(), "info": "Details coming soon.", "steps": ["Observe"], "products": ["Consult expert"]}

        return jsonify({"status": "success", "plant": plant_identity, "confidence": accuracy, "disease": extra_info.get('title'), "brief_info": extra_info.get('info'), "what_to_do": extra_info.get('steps'), "recommended_products": extra_info.get('products')}), 200
    except: return jsonify({"error": "Predict error"}), 500

# ==========================================
# 🛒 MERGED SMART CHAT (PRODUCT AWARE)
# ==========================================
@app.route('/chat', methods=['POST', 'OPTIONS'])
def chat():
    if request.method == 'OPTIONS': return jsonify({"status": "ok"}), 200
    try:
        data = request.get_json()
        msg = data.get('message', '')
        uid = data.get('userId')
        if not uid or uid == "null": return jsonify({"reply": "Unauthorized access."}), 401

        # 1. Fetch live products from Firebase Firestore
        product_list = []
        try:
            docs = db_firestore.collection('products').stream()
            for doc in docs:
                p = doc.to_dict()
                title = p.get('title', 'N/A')
                price = p.get('price', 'N/A')
                is_new = p.get('isNew', False)
                product_list.append(f"PRODUCT: {title} | PRICE: Rs. {price} | NEW_LAUNCH: {is_new}")
            product_context = "\n".join(product_list)
        except Exception:
            product_context = "No products found in store."

        # 2. Strict Smart System Prompt
        smart_system_context = f"""
        You are Garden Genie, the official assistant for Plantio.
        LIVE DATABASE PRODUCTS:
        {product_context}
        
        STRICT RULES:
        - ONLY use the product list above for inventory questions.
        - Always mention prices in PKR (Rs.) from the list.
        - If 'NEW_LAUNCH: True', say: 'Our admin has just launched this new product in Plantio!'
        - Be friendly. Plain text only.
        """

        reply = call_groq_ai(msg, system_context=smart_system_context)
        clean_reply = reply.replace("**", "").replace("*", "").strip()
        
        chat_history_collection.insert_one({"user_id": uid, "user_message": msg, "ai_reply": clean_reply, "timestamp": datetime.utcnow()})
        return jsonify({"reply": clean_reply}), 200
    except Exception as e: return jsonify({"reply": "Sorry, server side error."}), 500

# ==========================================
# RESET PASSWORD & AUTH ROUTES (ORIGINAL)
# ==========================================
RESET_FORM_HTML = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password | Plantio</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; background: #f9f9f9; margin: 0; display: flex; align-items: center; justify-content: center; height: 100vh; }
        .card { background: white; padding: 40px; border-radius: 20px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); width: 100%; max-width: 350px; text-align: center; }
        .logo-circle { width: 60px; height: 60px; border: 3px solid #5B8E55; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 20px; color: #5B8E55; font-size: 30px; }
        h2 { color: #1A1A1A; font-size: 24px; margin-bottom: 10px; }
        p { color: #666; font-size: 14px; margin-bottom: 30px; }
        .input-group { text-align: left; margin-bottom: 20px; }
        label { display: block; font-size: 12px; font-weight: 600; color: #1A1A1A; margin-bottom: 8px; text-transform: uppercase; }
        input { width: 100%; padding: 14px; background: #F5F5F5; border: none; border-radius: 8px; font-size: 15px; box-sizing: border-box; outline: none; }
        button { width: 100%; padding: 15px; background: #5B8E55; color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; }
    </style>
</head>
<body>
    <div class="card">
        <div class="logo-circle">🌿</div>
        <h2>Reset Password</h2>
        <form method="POST">
            <div class="input-group"><label>New Password</label><input type="password" name="password" required></div>
            <button type="submit">UPDATE PASSWORD</button>
        </form>
    </div>
</body>
</html>
"""

@app.route('/api/chat-history/<user_id>', methods=['GET'])
def get_chat_history(user_id):
    history = list(chat_history_collection.find({"user_id": user_id}).sort("timestamp", 1))
    messages = []
    for doc in history:
        messages.append({"role": "user", "message": doc["user_message"], "time": doc["timestamp"].strftime("%H:%M")})
        messages.append({"role": "ai", "message": doc["ai_reply"], "time": doc["timestamp"].strftime("%H:%M")})
    return jsonify(messages), 200

@app.route('/api/chat-history/<user_id>', methods=['DELETE'])
def clear_chat_history(user_id):
    chat_history_collection.delete_many({"user_id": user_id}); return jsonify({"success": True}), 200

@app.route('/api/products', methods=['GET'])
def get_all_products():
    try:
        docs = db_firestore.collection('products').stream()
        products = []
        for doc in docs:
            p = doc.to_dict(); p['id'] = doc.id; products.append(p)
        return jsonify(products), 200
    except: return jsonify([]), 500

@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json(); email = data['email'].strip().lower()
    if users_collection.find_one({"email": email}): return jsonify({"success": False}), 400
    users_collection.insert_one({"name": data['name'], "email": email, "password": hash_password(data['password']), "created_at": datetime.utcnow()})
    return jsonify({"success": True}), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json(); email = data['email'].strip().lower()
    user = users_collection.find_one({"email": email})
    if not user or not verify_password(data['password'], user['password']): return jsonify({"success": False}), 401
    return jsonify({"success": True, "user": {"id": str(user['_id']), "name": user['name'], "email": user['email']}}), 200

@app.route('/api/forgot-password', methods=['POST'])
def forgot_password():
    try:
        email = request.get_json().get('email').strip().lower()
        user = users_collection.find_one({"email": email})
        if not user: return jsonify({"success": False, "message": "Email not found"}), 404
        token = s.dumps(email, salt='password-reset-salt')
        link = f"{os.getenv('NGROK_URL')}/web/reset-password/{token}"
        
        api_key = os.getenv('BREVO_API_KEY')
        url = "https://api.brevo.com/v3/smtp/email"
        headers = {"api-key": api_key, "content-type": "application/json"}
        payload = {
            "sender": {"name": "Plantio Security", "email": "umermoazzam2@gmail.com"},
            "to": [{"email": email}],
            "subject": "Reset your Plantio password",
            "htmlContent": f"<p>Reset link: {link}</p>"
        }
        requests.post(url, json=payload, headers=headers)
        return jsonify({"success": True, "message": "Reset link sent"}), 200
    except Exception as e: return jsonify({"success": False, "message": str(e)}), 500

@app.route('/web/reset-password/<token>', methods=['GET', 'POST'])
def web_reset_password(token):
    try: email = s.loads(token, salt='password-reset-salt', max_age=1800)
    except: return "Link expired"
    if request.method == 'POST':
        users_collection.update_one({"email": email}, {"$set": {"password": hash_password(request.form.get('password'))}})
        return "Password Updated!"
    return RESET_FORM_HTML

@app.route('/api/contact-inquiry', methods=['POST', 'OPTIONS'])
def contact_inquiry():
    if request.method == 'OPTIONS': return jsonify({"status": "ok"}), 200
    try:
        data = request.get_json()
        api_key = os.getenv('BREVO_API_KEY')
        requests.post("https://api.brevo.com/v3/smtp/email", json={"sender": {"name": "Plantio System", "email": "umermoazzam2@gmail.com"}, "to": [{"email": data.get('email')}], "subject": "New Inquiry", "htmlContent": "Message Received."}, headers={"api-key": api_key, "content-type": "application/json"})
        return jsonify({"success": True}), 200
    except: return jsonify({"success": False}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=7860)