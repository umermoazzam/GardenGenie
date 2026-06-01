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

# ML Libraries
import torch
import torch.nn.functional as F
from transformers import MobileNetV2ForImageClassification
from torchvision import transforms

load_dotenv() 

from itsdangerous import URLSafeTimedSerializer

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

# Config
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = os.getenv('MAIL_USERNAME')
app.config['MAIL_PASSWORD'] = os.getenv('MAIL_PASSWORD')
app.config['MAIL_DEFAULT_SENDER'] = os.getenv('MAIL_USERNAME')

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
            print(f"❌ Groq API Error Response: {res_json}") # Ye aapke VS Code terminal mein dikhega
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
        
        # --- DEBUGGING: Terminal mein check karne ke liye ---
        print(f"DEBUG: Groq Vision Response -> '{res}'") 
        
        # If API error, return True to allow ML model to process the image
        if res.startswith("AI ERROR"):
            print(f"⚠️  Vision API failed, falling back to ML model")
            return True
        
        # If response contains YES or LEAF, it's a valid leaf
        if "YES" in res or "LEAF" in res:
            return True
        
        # Otherwise, it's not a leaf
        return False
    except Exception as e:
        print(f"❌ Gate Error: {e}")
        return True # Agar AI error de toh user ko block na karein, model ko chalne dein

RESET_FORM_HTML = """
<!DOCTYPE html>
<html>
<head><title>Reset Password</title></head>
<body><div style="text-align:center; padding:50px;"><h2>Reset Password</h2><form method="POST"><input type="password" name="password" placeholder="New Password" required><br><button type="submit">Update</button></form></div></body>
</html>
"""

# --- ROUTES ---

@app.route('/predict', methods=['POST'])
def predict():
    if model is None: return jsonify({"error": "Model not loaded"}), 500
    if 'file' not in request.files: return jsonify({"error": "No file"}), 400
    
    file_bytes = request.files['file'].read()
    
    # Leaf Check via Groq Vision
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
        
        # 🔥 Groq AI Call (No stars, plain text)
        reply = call_groq_ai(msg)
        clean_reply = reply.replace("**", "").replace("*", "").strip()

        chat_history_collection.insert_one({
            "user_id": uid, "user_message": msg, "ai_reply": clean_reply, "timestamp": datetime.utcnow()
        })
        return jsonify({"reply": clean_reply}), 200
    except Exception as e:
        return jsonify({"reply": f"AI Error: {str(e)}"}), 500

# Other routes stay exactly the same (History, Products, Auth)
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
    users_collection.insert_one({
        "name": data['name'], "email": email, 
        "password": hash_password(data['password']), "created_at": datetime.utcnow()
    })
    return jsonify({"success": True}), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    user = users_collection.find_one({"email": data['email'].strip().lower()})
    if not user or not verify_password(data['password'], user['password']): return jsonify({"success": False}), 401
    return jsonify({"success": True, "user": {"id": str(user['_id']), "name": user['name']}}), 200

@app.route('/api/forgot-password', methods=['POST'])
def forgot_password():
    email = request.get_json().get('email').strip().lower()
    user = users_collection.find_one({"email": email})
    if not user: return jsonify({"success": False}), 404
    token = s.dumps(email, salt='password-reset-salt')
    link = f"{os.getenv('NGROK_URL')}/web/reset-password/{token}"
    msg = Message("Reset Password", recipients=[email], body=f"Link: {link}")
    mail.send(msg)
    return jsonify({"success": True}), 200

@app.route('/web/reset-password/<token>', methods=['GET', 'POST'])
def web_reset_password(token):
    try: email = s.loads(token, salt='password-reset-salt', max_age=1800)
    except: return "Link expired"
    if request.method == 'POST':
        users_collection.update_one({"email": email}, {"$set": {"password": hash_password(request.form.get('password'))}})
        return "Updated! ✅"
    return RESET_FORM_HTML

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)