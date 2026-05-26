# app.py
from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
from flask_mail import Mail, Message
from pymongo import MongoClient
from bson import ObjectId
import bcrypt
from datetime import datetime
import os
import io
import base64
from typing import Optional
from PIL import Image

# ML Libraries
import torch
import torch.nn.functional as F
from transformers import MobileNetV2ForImageClassification
from torchvision import transforms

# Gemini API
try:
    import google.generativeai as genai
except Exception:
    genai = None
try:
    from google.genai import Client as GenAIClient
except Exception:
    GenAIClient = None

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

# --- Google Gemini Configuration ---
GEMINI_API_KEY = "AIzaSyCi9woBgjLxmbeWVZ6hVMQLMvJ0t5RHtto"
model_gemini = None
use_genai_new = False

if GenAIClient is not None:
    try:
        model_gemini = GenAIClient(api_key=GEMINI_API_KEY)
        use_genai_new = True
        print("🔍 New google.genai client initialized.")
    except Exception as exc:
        print(f"❌ google.genai failed: {exc}")

if model_gemini is None:
    try:
        genai.configure(api_key=GEMINI_API_KEY)
        model_gemini = genai.GenerativeModel('gemini-1.5-flash')
        print("🔍 Legacy google.generativeai client initialized.")
    except Exception as exc:
        print(f"❌ Legacy Gemini failed: {exc}")

# --- Machine Learning Model Loading ---
print("🔍 Loading MobileNetV2 disease model...")
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
    print(f"❌ Error loading model: {e}")
    model = None

# --- MongoDB Atlas Connection ---
MONGO_URI = "mongodb+srv://umer:Plantio123@cluster0.mmiqh2p.mongodb.net/plantio_db?retryWrites=true&w=majority"
try:
    client_db = MongoClient(MONGO_URI)
    db = client_db['plantio_db']
    users_collection = db['users']
    products_collection = db['products'] 
    chat_history_collection = db['chat_history']
    print("✅ MongoDB Atlas Connected!")
except Exception as e:
    print(f"❌ Connection error: {e}")

# --- Helper Functions ---
def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

def verify_password(password: str, hashed: bytes) -> bool:
    return bcrypt.checkpw(password.encode('utf-8'), hashed)

def validate_leaf_gate(image_bytes: bytes) -> bool:
    """
    STAGE 1: Super Strict Vision Gate
    Returns True ONLY if it's 100% a plant leaf.
    """
    if model_gemini is None:
        return True 
    
    # Ultra-strict prompt for Gemini
    prompt = (
        "CRITICAL INSTRUCTION: Analyze this image. Is this a plant leaf? "
        "If it is a human, a face, a car, a room, a keyboard, or anything NOT a plant leaf, "
        "you MUST respond with ONLY the word 'REJECT'. "
        "If it IS a plant leaf, respond with ONLY the word 'LEAF'. "
        "Do not use punctuation or other words."
    )
    
    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        if use_genai_new:
            # For new GenAI Client
            response = model_gemini.responses.create(
                model="gemini-1.5-flash",
                contents=[prompt, image]
            )
            res_text = response.text.strip().upper()
        else:
            # For legacy client
            response = model_gemini.generate_content([prompt, image])
            res_text = response.text.strip().upper()
        
        print(f"DEBUG: Gemini Gate said -> {res_text}")
        return "LEAF" in res_text
    except Exception as e:
        print(f"Gate Error: {e}")
        return True # Bypass on error to not block user

RESET_FORM_HTML = """
<!DOCTYPE html>
<html>
<head><title>Plantio - Reset Password</title></head>
<body><div style="text-align:center; padding:50px;"><h2>Plantio Reset</h2><form method="POST"><input type="password" name="password" placeholder="New Password" required><br><button type="submit">Update</button></form></div></body>
</html>
"""

# --- ROUTES ---

@app.route('/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({"error": "Model not loaded"}), 500
    if 'file' not in request.files: 
        return jsonify({"error": "No file uploaded"}), 400
    
    file_storage = request.files['file']
    file_bytes = file_storage.read()
    
    # --- STAGE 1: THE STRICT GATE ---
    if not validate_leaf_gate(file_bytes):
        return jsonify({
            "disease": "This image is not a plant leaf. Please upload a clear photo of a leaf.",
            "confidence": 0.0,
            "status": "rejected"
        }), 200

    # --- STAGE 2: DISEASE DETECTION ---
    try:
        image = Image.open(io.BytesIO(file_bytes)).convert("RGB")
        img_tensor = data_transforms(image).unsqueeze(0)
        
        with torch.no_grad():
            outputs = model(img_tensor)
            probs = F.softmax(outputs.logits, dim=-1)
            predicted_class_idx = torch.argmax(probs, dim=-1).item()
            confidence = probs[0][predicted_class_idx].item()
        
        labels = getattr(model.config, "id2label", None) or {}
        predicted_label = labels.get(predicted_class_idx) or labels.get(str(predicted_class_idx)) or "Unknown"

        # --- FINAL STAGE: CONFIDENCE FILTER ---
        # If confidence is extremely low, it means the model is guessing on a non-leaf image 
        # that somehow passed the Gemini Gate.
        if confidence < 0.35:
            return jsonify({
                "disease": "Invalid image. Please capture a clear, close-up photo of the leaf.",
                "confidence": round(confidence * 100, 2),
                "status": "rejected"
            }), 200

        return jsonify({
            "disease": predicted_label,
            "confidence": round(confidence * 100, 2),
            "status": "success"
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/chat-history/<user_id>', methods=['GET'])
def get_chat_history(user_id):
    try:
        history = list(chat_history_collection.find({"user_id": user_id}).sort("timestamp", 1))
        messages = []
        for doc in history:
            messages.append({"role": "user", "message": doc["user_message"], "time": doc["timestamp"].strftime("%H:%M")})
            messages.append({"role": "ai", "message": doc["ai_reply"], "time": doc["timestamp"].strftime("%H:%M")})
        return jsonify(messages), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@app.route('/api/chat-history/<user_id>', methods=['DELETE'])
def clear_chat_history(user_id):
    try:
        chat_history_collection.delete_many({"user_id": user_id})
        return jsonify({"success": True, "message": "History cleared permanently"}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@app.route('/chat', methods=['POST', 'OPTIONS'])
def chat():
    if request.method == 'OPTIONS': return jsonify({"status": "ok"}), 200
    try:
        data = request.get_json()
        user_message = data.get('message', '')
        user_id = data.get('userId', 'test_user')
        
        if not user_message: return jsonify({"reply": "Please type a message."}), 400
        
        prompt = (
            "System: Your name is 'Garden Genie'. You are an expert friendly gardening assistant for the Plantio app. "
            "If the user asks what your name is or who you are, always answer 'My name is Garden Genie!'. "
            "Write in plain simple text only. No stars, no markdown formatting. "
            f"User message: {user_message}"
        )
        
        if use_genai_new:
            response = model_gemini.responses.create(model="gemini-1.5-flash", contents=prompt)
            raw_reply = response.text
        else:
            response = model_gemini.generate_content(prompt)
            raw_reply = response.text

        clean_reply = raw_reply.replace("**", "").replace("*", "").replace("#", "").strip()

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
        msg = Message("Plantio Password Reset", recipients=[email])
        msg.body = f"Click the link to reset your password: {reset_link}"
        mail.send(msg)
        return jsonify({"success": True, "message": "Reset link sent to your email!"}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@app.route('/web/reset-password/<token>', methods=['GET', 'POST'])
def web_reset_password(token):
    try: 
        email = s.loads(token, salt='password-reset-salt', max_age=1800)
    except: 
        return "<h1>Reset link has expired or is invalid!</h1>"
    
    if request.method == 'POST':
        new_pw = request.form.get('password')
        users_collection.update_one({"email": email}, {"$set": {"password": hash_password(new_pw)}})
        return "<h1>Password Updated Successfully! ✅</h1><p>You can now log in from the app.</p>"
    
    return RESET_FORM_HTML

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)