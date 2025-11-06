# src/preprocess.py
import re
from pathlib import Path
from nltk.corpus import stopwords
from utils import ensure_dirs

def clean_text(text: str) -> str:
    text = text.replace("\r", "\n")
    text = re.sub(r'Page\s*\d+\s*(/|of)?\s*\d*', ' ', text)
    text = re.sub(r'http\S+|www\.\S+', ' ', text)
    text = re.sub(r'[^\x00-\x7F\u00C0-\u017F\n]', ' ', text)
    text = re.sub(r'\s+', ' ', text)
    text = text.strip()
    return text

def process_all():
    raw_pdfs, raw_txt, cleaned_txt, cleaned_chunks = ensure_dirs()
    txt_files = sorted(raw_txt.glob("*.txt"))
    if not txt_files:
        print("⚠️ Aucun fichier .txt trouvé dans", raw_txt)
        return

    for file in txt_files:
        raw = file.read_text(encoding="utf-8")
        cleaned = clean_text(raw)
        out_path = cleaned_txt / (file.stem + "_clean.txt")
        out_path.write_text(cleaned, encoding="utf-8")
        print(f"✅ Nettoyé : {out_path}")

if __name__ == "__main__":
    process_all()
