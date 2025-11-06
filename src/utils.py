# src/utils.py
from pathlib import Path

def ensure_dirs():
    """
    Crée les dossiers nécessaires et renvoie :
    - raw_pdfs
    - raw_txt
    - cleaned_chunks
    """
    base = Path(__file__).resolve().parents[1]
    raw_pdfs = base / "data" / "raw_pdfs"
    raw_txt = base / "data" / "raw_txt"
    cleaned_chunks = base / "data" / "cleaned_chunks"

    for d in [raw_pdfs, raw_txt, cleaned_chunks]:
        d.mkdir(parents=True, exist_ok=True)

    return raw_pdfs, raw_txt, cleaned_chunks
