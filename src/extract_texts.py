# src/extract_texts.py
from pathlib import Path
from PyPDF2 import PdfReader
from tqdm import tqdm
from utils import ensure_dirs

def extract_text_from_pdf(pdf_path: Path) -> str:
    text_parts = []
    try:
        reader = PdfReader(str(pdf_path))
        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:
                text_parts.append(page_text)
    except Exception as e:
        print(f"[ERREUR] lecture {pdf_path}: {e}")
    return "\n".join(text_parts)

def main():
    raw_pdfs, raw_txt, cleaned_txt, cleaned_chunks = ensure_dirs()
    pdf_files = sorted([p for p in raw_pdfs.glob("*.pdf")])
    if not pdf_files:
        print("⚠️ Aucun PDF trouvé dans", raw_pdfs)
        return

    for pdf_path in tqdm(pdf_files, desc="Extraction des textes depuis les PDF"):
        text = extract_text_from_pdf(pdf_path)
        out_file = raw_txt / (pdf_path.stem + ".txt")
        out_file.write_text(text, encoding="utf-8")
        print(f"✅ Texte extrait : {out_file}")

if __name__ == "__main__":
    main()
