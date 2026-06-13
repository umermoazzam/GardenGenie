# app.py
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
from dotenv import load_dotenv
from PIL import Image
import smtplib
import traceback

# ML Libraries
import torch
import torch.nn.functional as F
from transformers import MobileNetV2ForImageClassification
from torchvision import transforms

load_dotenv() 

from itsdangerous import URLSafeTimedSerializer

app = Flask(__name__)
CORS(app)

# ==========================================
# ✅ FIXED MAIL CONFIGURATION FOR CLOUD (HF)
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

if not app.config['MAIL_USERNAME'] or not app.config['MAIL_PASSWORD']:
    print("❌ MAIL_USERNAME or MAIL_PASSWORD is missing; SMTP may fail.")

mail = Mail(app)
s = URLSafeTimedSerializer(app.config['SECRET_KEY'])

# --- Groq Configuration ---
GROQ_API_KEY = os.getenv('GROQ_API_KEY')
GROQ_TEXT_MODEL = "llama-3.1-8b-instant"
GROQ_VISION_MODEL = "llama-3.2-11b-vision-preview" 

def call_groq_ai(prompt, image_base64=None):
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"}
    model = GROQ_VISION_MODEL if image_base64 else GROQ_TEXT_MODEL
    messages = []
    if image_base64:
        messages = [{"role": "user", "content": [{"type": "text", "text": prompt}, {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + image_base64}}]}]
    else:
        messages = [{"role": "system", "content": "Your name is Garden Genie. You are a friendly gardening assistant. Plain text only."}, {"role": "user", "content": prompt}]
    payload = {"model": model, "messages": messages, "temperature": 0.7}
    try:
        response = requests.post(url, json=payload, headers=headers)
        res_json = response.json()
        if 'choices' not in res_json: return f"AI Error: {res_json.get('error', {}).get('message', 'Unknown API Error')}"
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
    print("🚀 Disease model loaded successfully!")
except Exception as e:
    model = None

# --- MongoDB Atlas ---
try:
    client_db = MongoClient(os.getenv('MONGO_URI'))
    db = client_db['plantio_db']
    users_collection = db['users']
    products_collection = db['products'] 
    chat_history_collection = db['chat_history']
    print("✅ MongoDB Connected!")
except Exception as e:
    print(f"❌ DB Error: {e}")

# --- Helper Functions ---
def hash_password(password: str) -> str: return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
def verify_password(password: str, hashed: bytes) -> bool: return bcrypt.checkpw(password.encode('utf-8'), hashed)
def validate_leaf_gate(image_bytes: bytes) -> bool:
    if not GROQ_API_KEY: return True
    prompt = "Is this a plant leaf or part of a plant? Answer with ONLY 'YES' or 'NO'."
    try:
        img_b64 = base64.b64encode(image_bytes).decode('utf-8')
        res = call_groq_ai(prompt, img_b64).strip().upper()
        return "YES" in res or "LEAF" in res
    except: return True

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
        input:focus { box-shadow: 0 0 0 2px #5B8E55; }
        button { width: 100%; padding: 15px; background: #5B8E55; color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; margin-top: 10px; }
        button:hover { background: #4a7545; }
    </style>
</head>
<body>
    <div class="card">
        <div class="logo-circle">🌿</div>
        <h2>Reset Password</h2>
        <form method="POST">
            <div class="input-group"><label>New Password</label><input type="password" name="password" id="p1" required></div>
            <div class="input-group"><label>Confirm Password</label><input type="password" id="p2" required oninput="check()"></div>
            <p id="msg" style="color:red; font-size:12px; display:none;">Passwords do not match</p>
            <button type="submit" id="btn">UPDATE PASSWORD</button>
        </form>
    </div>
    <script>
        function check() {
            var p1 = document.getElementById('p1').value;
            var p2 = document.getElementById('p2').value;
            var btn = document.getElementById('btn');
            if(p1 != p2) { btn.disabled = true; document.getElementById('msg').style.display='block'; }
            else { btn.disabled = false; document.getElementById('msg').style.display='none'; }
        }
    </script>
</body>
</html>
"""

# --- ROUTES ---

@app.route('/predict', methods=['POST'])
def predict():
    if model is None: return jsonify({"error": "Model not loaded"}), 500
    if 'file' not in request.files: return jsonify({"error": "No file"}), 400
    file_bytes = request.files['file'].read()
    if not validate_leaf_gate(file_bytes):
        return jsonify({"disease": "This image is not a plant leaf.", "confidence": 0.0, "status": "rejected"}), 200
    try:
        image = Image.open(io.BytesIO(file_bytes)).convert("RGB")
        img_tensor = data_transforms(image).unsqueeze(0)
        with torch.no_grad():
            outputs = model(img_tensor)
            probs = F.softmax(outputs.logits, dim=-1)
            idx = torch.argmax(probs, dim=-1).item()
            conf = probs[0][idx].item()
        labels = getattr(model.config, "id2label", {})
        label = labels.get(idx, labels.get(str(idx), "Unknown"))
        return jsonify({"disease": label, "confidence": round(conf * 100, 2), "status": "success"}), 200
    except Exception as e: return jsonify({"error": str(e)}), 500

@app.route('/chat', methods=['POST', 'OPTIONS'])
def chat():
    if request.method == 'OPTIONS': return jsonify({"status": "ok"}), 200
    try:
        data = request.get_json()
        msg = data.get('message', '')
        uid = data.get('userId', 'test_user')
        if not msg: return jsonify({"reply": "Message empty"}), 400
        reply = call_groq_ai(msg)
        clean_reply = reply.replace("**", "").replace("*", "").strip()
        chat_history_collection.insert_one({"user_id": uid, "user_message": msg, "ai_reply": clean_reply, "timestamp": datetime.utcnow()})
        return jsonify({"reply": clean_reply}), 200
    except Exception as e: return jsonify({"reply": f"AI Error: {str(e)}"}), 500

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
    chat_history_collection.delete_many({"user_id": user_id})
    return jsonify({"success": True}), 200

@app.route('/api/products', methods=['GET'])
def get_all_products():
    products = list(products_collection.find())
    for p in products: p['_id'] = str(p['_id'])
    return jsonify(products), 200

@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    email = data['email'].strip().lower()
    if users_collection.find_one({"email": email}): return jsonify({"success": False}), 400
    users_collection.insert_one({"name": data['name'], "email": email, "password": hash_password(data['password']), "created_at": datetime.utcnow()})
    return jsonify({"success": True}), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data['email'].strip().lower()
    user = users_collection.find_one({"email": email})
    if not user or not verify_password(data['password'], user['password']): return jsonify({"success": False}), 401
    return jsonify({"success": True, "user": {"id": str(user['_id']), "name": user['name'], "email": user['email']}}), 200

@app.route('/api/forgot-password', methods=['POST'])
def forgot_password():
    try:
        email = request.get_json().get('email').strip().lower()
        user = users_collection.find_one({"email": email})
        
        if not user:
            return jsonify({"success": False, "message": "Email not found"}), 404

        token = s.dumps(email, salt='password-reset-salt')
        link = f"{os.getenv('NGROK_URL')}/web/reset-password/{token}"
        timestamp = datetime.utcnow().strftime("%B %d, %Y")

        api_key = os.getenv('BREVO_API_KEY')
        url = "https://api.brevo.com/v3/smtp/email"
        headers = {"api-key": api_key, "content-type": "application/json"}

        # High-End Professional Template
        html_body = f"""
        <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 40px auto; border-radius: 16px; background: #ffffff; border: 1px solid #e1e4e8; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.05);">
            <div style="background: #5B8E55; padding: 30px; text-align: center;">
                <h2 style="color: #ffffff; margin: 0; font-size: 22px; font-weight: 600; letter-spacing: -0.5px;">Password Reset</h2>
            </div>
            
            <div style="padding: 40px;">
                <p style="color: #24292e; font-size: 16px; margin-bottom: 20px;">Hi there,</p>
                <p style="color: #586069; font-size: 15px; line-height: 1.6; margin-bottom: 30px;">
                    We received a request to reset your password for your <strong>Plantio</strong> account. If you didn't make this request, please ignore this email.
                </p>

                <div style="text-align: center; margin: 40px 0;">
                    <a href="{link}" style="background: #5B8E55; color: #ffffff; padding: 14px 30px; text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 15px; display: inline-block;">Reset Password</a>
                </div>
                
                <p style="color: #999; font-size: 13px; text-align: center;">This link will expire in 30 minutes.</p>
            </div>

            <div style="background: #fcfcfc; padding: 20px; text-align: center; border-top: 1px solid #e1e4e8; color: #a1a1a1; font-size: 11px;">
                <p style="margin: 0;">Plantio Security System • {timestamp}</p>
            </div>
        </div>
        """

        payload = {
            "sender": {"name": "Plantio Security", "email": "umermoazzam2@gmail.com"},
            "to": [{"email": email}],
            "subject": "Reset your Plantio password",
            "htmlContent": html_body
        }
        
        requests.post(url, json=payload, headers=headers)
        return jsonify({"success": True, "message": "Reset link sent"}), 200
        
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@app.route('/web/reset-password/<token>', methods=['GET', 'POST'])
def web_reset_password(token):
    try: email = s.loads(token, salt='password-reset-salt', max_age=1800)
    except: return "Link expired"
    if request.method == 'POST':
        users_collection.update_one({"email": email}, {"$set": {"password": hash_password(request.form.get('password'))}})
        return "Password Updated!"
    return RESET_FORM_HTML

# ==========================================================
# ✅ UPDATED: HIGH-END PROFESSIONAL UI/UX EMAIL (EXACT TEMPLATE)
# ==========================================================

@app.route('/api/contact-inquiry', methods=['POST', 'OPTIONS'])
def contact_inquiry():
    if request.method == 'OPTIONS': 
        return jsonify({"status": "ok"}), 200
    try:
        data = request.get_json() or {}
        receiver_email = data.get('email')
        member_name = data.get('name')
        customer_name = data.get('customer_name', 'A Visitor')
        customer_email = data.get('customer_email', 'Not provided')
        timestamp = datetime.utcnow().strftime("%B %d, %Y at %H:%M UTC")

        api_key = os.getenv('BREVO_API_KEY')
        url = "https://api.brevo.com/v3/smtp/email"
        headers = {"accept": "application/json", "api-key": api_key, "content-type": "application/json"}

        # Professional High-End Template
        html_body = f"""
        <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 40px auto; border-radius: 16px; background: #ffffff; border: 1px solid #e1e4e8; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.05);">
            <div style="background: #5B8E55; padding: 30px; text-align: center;">
                <h2 style="color: #ffffff; margin: 0; font-size: 22px; font-weight: 600; letter-spacing: -0.5px;">New Connection Request</h2>
            </div>
            
            <div style="padding: 40px;">
                <p style="color: #24292e; font-size: 16px; margin-bottom: 20px;">Hello <strong>{member_name}</strong>,</p>
                <p style="color: #586069; font-size: 15px; line-height: 1.6; margin-bottom: 30px;">
                    A visitor is interested in your Plantio profile. Here are the details of the request:
                </p>

                <div style="background: #f6f8fa; padding: 20px; border-radius: 8px; border: 1px solid #e1e4e8;">
                    <div style="margin-bottom: 15px;">
                        <span style="display: block; color: #586069; font-size: 12px; text-transform: uppercase; font-weight: bold;">Visitor Name</span>
                        <span style="color: #24292e; font-size: 15px; font-weight: 500;">{customer_name}</span>
                    </div>
                    <div>
                        <span style="display: block; color: #586069; font-size: 12px; text-transform: uppercase; font-weight: bold;">Email Address</span>
                        <span style="color: #24292e; font-size: 15px; font-weight: 500;">{customer_email}</span>
                    </div>
                </div>

                <div style="margin-top: 40px; text-align: center;">
                    <a href="mailto:{customer_email}" style="background: #5B8E55; color: #ffffff; padding: 14px 30px; text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 15px; display: inline-block;">Reply to {customer_name}</a>
                </div>
            </div>

            <div style="background: #fcfcfc; padding: 20px; text-align: center; border-top: 1px solid #e1e4e8; color: #a1a1a1; font-size: 11px;">
                <p style="margin: 0;">Plantio Connection System • {timestamp}</p>
            </div>
        </div>
        """

        payload = {
            "sender": {"name": "Plantio System", "email": "umermoazzam2@gmail.com"},
            "to": [{"email": receiver_email, "name": member_name}],
            "subject": f"🚨 New Connection Request | {customer_name} wants to connect!",
            "htmlContent": html_body
        }

        response = requests.post(url, json=payload, headers=headers)
        
        if response.status_code >= 200 and response.status_code < 300:
            return jsonify({"success": True}), 200
        else:
            return jsonify({"success": False, "message": "API Error"}), 500
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500
    
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=7860)