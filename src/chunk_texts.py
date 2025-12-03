# src/chunk_texts_by_article.py
import re
import json
from pathlib import Path
from tqdm import tqdm
from utils import ensure_dirs

def split_by_articles(text):
    """Découpe le texte selon les articles et titres légaux."""
    # Garder les titres pour le contexte
    pattern = r'(?=(Article\s+\d+))'
    parts = re.split(pattern, text)
    chunks = []

    # Fusionner titre + contenu de chaque article
    for i in range(1, len(parts), 2):
        title = parts[i].strip()
        content = parts[i+1].strip() if i + 1 < len(parts) else ""
        chunk = f"{title}\n{content}"
        chunks.append(chunk)
    return chunks

def main():
    raw_pdfs, raw_txt, cleaned_chunks = ensure_dirs()
    cleaned_txt_folder = cleaned_chunks.parent / "cleaned_txt"
    cleaned_files = sorted(cleaned_txt_folder.glob("*_clean.txt"))

    if not cleaned_files:
        print("⚠️ Aucun fichier trouvé dans", cleaned_txt_folder)
        return

    output_file = cleaned_chunks / "chunks_by_article.jsonl"
    with output_file.open("w", encoding="utf-8") as fout:
        for path in tqdm(cleaned_files, desc="Découpage par articles"):
            text = path.read_text(encoding="utf-8")
            chunks = split_by_articles(text)

            for idx, chunk in enumerate(chunks):
                record = {
                    "source": path.stem.replace("_clean", ""),
                    "chunk_id": f"{path.stem}_{idx}",
                    "text": chunk.strip()
                }
                fout.write(json.dumps(record, ensure_ascii=False) + "\n")

    print(f"✅ {len(chunks)} chunks enregistrés dans {output_file}")

if __name__ == "__main__":
    main()
