from transformers import MobileNetV2ForImageClassification

model_path = "disease_model"
model = MobileNetV2ForImageClassification.from_pretrained(model_path)

# Yeh command aapko dikha degi ki model ne kya labels seekhe hain
print("Model Labels/Categories:")
print(model.config.id2label)