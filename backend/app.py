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
app.config['MAIL_PORT'] = 587             # 465 ko 587 kar dein
app.config['MAIL_USE_TLS'] = True         # False ko True kar dein
app.config['MAIL_USE_SSL'] = False        # True ko False kar dein
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
GROQ_VISION_MODEL = "llama-3.2-11b-vision-preview" # Optimized for vision

def call_groq_ai(prompt, image_base64=None):
    """Groq API Call Helper with Debugging"""
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json"
    }
    
    model = GROQ_VISION_MODEL if image_base64 else GROQ_TEXT_MODEL
      
    messages = []
    if image_base64:
        messages = [{
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + image_base64}}
            ]
        }]
    else:
        messages = [
            {"role": "system", "content": "Your name is Garden Genie. You are a friendly gardening assistant. Plain text only."},
            {"role": "user", "content": prompt}
        ]

    payload = {"model": model, "messages": messages, "temperature": 0.7}

    try:
        response = requests.post(url, json=payload, headers=headers)
        res_json = response.json()
        
        # --- DEBUGGING START ---
        if 'choices' not in res_json:
            print(f"❌ Groq API Error Response: {res_json}")
            error_msg = res_json.get('error', {}).get('message', 'Unknown API Error')
            return f"AI Error: {error_msg}"
        # --- DEBUGGING END ---
        
        return res_json['choices'][0]['message']['content']
    except Exception as e:
        return f"AI Error: {str(e)}"
    
# --- ML Model Loading (MobileNetV2) ---
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
    print(f"❌ Model Error: {e}")
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
def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

def verify_password(password: str, hashed: bytes) -> bool:
    return bcrypt.checkpw(password.encode('utf-8'), hashed)

def validate_leaf_gate(image_bytes: bytes) -> bool:
    if not GROQ_API_KEY: return True
    
    prompt = "Is this a plant leaf or part of a plant? Answer with ONLY 'YES' or 'NO'. If it is a person, object, or animal, say 'NO'."
    
    try:
        img_b64 = base64.b64encode(image_bytes).decode('utf-8')
        res = call_groq_ai(prompt, img_b64).strip().upper()
        
        print(f"DEBUG: Groq Vision Response -> '{res}'") 
        
        if res.startswith("AI ERROR"):
            print(f"⚠️  Vision API failed, falling back to ML model")
            return True
        
        if "YES" in res or "LEAF" in res:
            return True
        
        return False
    except Exception as e:
        print(f"❌ Gate Error: {e}")
        return True

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
        <p>Set a new password for your Plantio account.</p>
        <form method="POST">
            <div class="input-group">
                <label>New Password</label>
                <input type="password" name="password" id="p1" placeholder="••••••••" required>
            </div>
            <div class="input-group">
                <label>Confirm Password</label>
                <input type="password" id="p2" placeholder="••••••••" required oninput="check()">
            </div>
            <p id="msg" style="color:red; font-size:12px; margin-top:-10px; display:none;">Passwords do not match</p>
            <button type="submit" id="btn">UPDATE PASSWORD</button>
        </form>
    </div>
    <script>
        function check() {
            var p1 = document.getElementById('p1').value;
            var p2 = document.getElementById('p2').value;
            var btn = document.getElementById('btn');
            var msg = document.getElementById('msg');
            if(p1 != p2) { btn.disabled = true; msg.style.display='block'; btn.style.opacity='0.5'; }
            else { btn.disabled = false; msg.style.display='none'; btn.style.opacity='1'; }
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
    except Exception as e:
        return jsonify({"error": str(e)}), 500

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

        chat_history_collection.insert_one({
            "user_id": uid,
            "user_message": msg,
            "ai_reply": clean_reply,
            "timestamp": datetime.utcnow()
        })

        return jsonify({"reply": clean_reply}), 200
    except Exception as e:
        return jsonify({"reply": f"AI Error: {str(e)}"}), 500

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
    if users_collection.find_one({"email": email}):
        return jsonify({"success": False}), 400

    users_collection.insert_one({
        "name": data['name'],
        "email": email,
        "password": hash_password(data['password']),
        "created_at": datetime.utcnow()
    })
    return jsonify({"success": True}), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data['email'].strip().lower()
    user = users_collection.find_one({"email": email})

    if not user or not verify_password(data['password'], user['password']):
        return jsonify({"success": False}), 401

    return jsonify({
        "success": True,
        "user": {
            "id": str(user['_id']),
            "name": user['name'],
            "email": user['email']
        }
    }), 200

@app.route('/api/forgot-password', methods=['POST'])
def forgot_password():
    try:
        email = request.get_json().get('email').strip().lower()
        user = users_collection.find_one({"email": email})
        
        if not user:
            return jsonify({"success": False, "message": "Email not found"}), 404

        token = s.dumps(email, salt='password-reset-salt')
        # NGROK_URL ki jagah Hugging Face ka link bhi ho sakta hai
        link = f"{os.getenv('NGROK_URL')}/web/reset-password/{token}"

        api_key = os.getenv('BREVO_API_KEY')
        url = "https://api.brevo.com/v3/smtp/email"
        
        headers = {
            "api-key": api_key,
            "content-type": "application/json",
            "accept": "application/json"
        }

        payload = {
            "sender": {"name": "Plantio Support", "email": "umermoazzam2@gmail.com"},
            "to": [{"email": email}],
            "subject": "Reset Your Plantio Password",
            "htmlContent": f"""
            <div style="font-family: sans-serif; padding: 20px;">
                <h2>Password Reset Request</h2>
                <p>Click the button below to reset your password. This link is valid for 30 minutes.</p>
                <a href="{link}" style="background: #5B8E55; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; display: inline-block;">Reset Password</a>
                <p>If you didn't request this, please ignore this email.</p>
            </div>
            """
        }

        requests.post(url, json=payload, headers=headers)
        return jsonify({"success": True, "message": "Reset link sent to your email"}), 200

    except Exception as e:
        print(f"❌ Forgot Password Error: {str(e)}")
        return jsonify({"success": False, "message": str(e)}), 500

@app.route('/web/reset-password/<token>', methods=['GET', 'POST'])
def web_reset_password(token):
    try:
        email = s.loads(token, salt='password-reset-salt', max_age=1800)
    except:
        return "Link expired"

    if request.method == 'POST':
        users_collection.update_one(
            {"email": email},
            {"$set": {"password": hash_password(request.form.get('password'))}}
        )
        # --- SUCCESS HTML RESPONSE ---
        return '<div style="text-align:center; padding:50px; font-family:sans-serif;"><h2>✅ Password Updated!</h2><p>You can now login from the app.</p></div>'

    return RESET_FORM_HTML


# =========================
# ✅ PROFESSIONAL HTML CONTACT INQUIRY
# ==========================

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

        # --- BREVO API LOGIC ---
        api_key = os.getenv('BREVO_API_KEY')
        url = "https://api.brevo.com/v3/smtp/email"
        
        headers = {
            "accept": "application/json",
            "api-key": api_key,
            "content-type": "application/json"
        }

        payload = {
            "sender": {"name": "Plantio Support", "email": "umermoazzam2@gmail.com"},
            "to": [{"email": receiver_email, "name": member_name}],
            "subject": f"Plantio: {customer_name} wants to connect!",
            "htmlContent": f"""
                <div style="font-family: sans-serif; border: 1px solid #eee; padding: 20px; border-radius: 10px;">
                    <h2 style="color: #5B8E55;">New Connection Request</h2>
                    <p>Hi <b>{member_name}</b>,</p>
                    <p><b>{customer_name}</b> ({customer_email}) is interested in your profile on Plantio.</p>
                    <br>
                    <a href="mailto:{customer_email}" style="background: #5B8E55; color: white; padding: 10px 20px; text-decoration: none; border-radius: 50px;">Reply to Customer</a>
                </div>
            """
        }

        response = requests.post(url, json=payload, headers=headers)
        
        if response.status_code in [200, 201, 202]:
            print(f"✅ Email sent successfully to {receiver_email} via Brevo")
            return jsonify({"success": True, "message": "Inquiry sent!"}), 200
        else:
            print(f"❌ Brevo Error: {response.text}")
            return jsonify({"success": False, "message": "Email provider error"}), 500

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return jsonify({"success": False, "message": str(e)}), 500
    
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=7860)