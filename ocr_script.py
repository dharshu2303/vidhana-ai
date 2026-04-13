import pytesseract
import cv2
import os

pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

input_folder = "images"
output_folder = "output_text"

if not os.path.exists(output_folder):
    os.makedirs(output_folder)

for filename in os.listdir(input_folder):

    if filename.endswith(".jpg") or filename.endswith(".png"):

        img_path = os.path.join(input_folder, filename)
        print("Reading:", img_path)

        img = cv2.imread(img_path)

        text = pytesseract.image_to_string(img)

        text_filename = filename.split(".")[0] + ".txt"

        with open(os.path.join(output_folder, text_filename), "w", encoding="utf-8") as f:
            f.write(text)

        print("Saved:", text_filename)

print("Done")