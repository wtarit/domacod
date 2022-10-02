from fastapi import FastAPI, File, UploadFile, HTTPException, Response, status
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline
from google.cloud import vision
import os

tokenizer = AutoTokenizer.from_pretrained(
    pretrained_model_name_or_path="autonlp-4Subject-613017416"
)

model = AutoModelForSequenceClassification.from_pretrained(
    pretrained_model_name_or_path="autonlp-4Subject-613017416"
)

classifier = pipeline("sentiment-analysis", model=model, tokenizer=tokenizer)

app = FastAPI()
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "domacod-ef1a05fe4585.json"
client = vision.ImageAnnotatorClient()


@app.get("/")
def hello():
    return {"Hello": "World"}


@app.get("/predict_sub")
def predict_sub(text: str = ""):
    subject = classifier(text)
    return {"subject": subject[0]["label"]}


@app.post("/predict")
def predict(
    response: Response,
    file: UploadFile = File(...),
):
    text_result = ""
    extension = file.filename.split(".")[-1].lower() in ("jpg", "jpeg", "png")
    if not extension:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return HTTPException(
            status_code=400, detail={"error": "Image must be jpg or png format!"}
        )
    data = file.file.read()
    image = vision.Image(content=data)
    response = client.text_detection(image=image)
    texts = response.text_annotations
    for text in texts:
        if len(text.description) < 3:
            continue
        text_result += text.description.replace("\n", "")
    try:
        subject = classifier(text_result)
    except:
        return {"text": text_result, "subject": ""}
    subject = subject[0]
    if subject["score"] < 0.95:
        return {"text": text_result, "subject": ""}
    translation = {
        "เคมี": "Chemistry",
        "ชีวะ": "Biology",
        "ฟิสิกส์": "Physics",
        "คณิต": "Math",
    }
    translated_subject = translation[subject["label"]]
    return {"text": text_result, "subject": translated_subject}
