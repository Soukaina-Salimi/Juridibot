# src/chunk_texts.py
import json
from pathlib import Path
from tqdm import tqdm
from nltk.tokenize import sent_tokenize
from utils import ensure_dirs

def chunk_sentences(sentences, max_chars=900, overlap_sentences=2):
    """
    Découpe la liste de phrases en "chunks" d'environ max_chars,
    avec un chevauchement en nombre de phrases (overlap_sentences).
    Retourne une liste de chaînes (chunks).
    """
    chunks = []
    n = len(sentences)
    i = 0

    while i < n:
        # Construire un chunk en ajoutant des phrases tant que la longueur reste <= max_chars
        j = i
        current_chars = 0
        while j < n and current_chars + len(sentences[j]) + 1 <= max_chars:
            current_chars += len(sentences[j]) + 1  # +1 pour l'espace
            j += 1

        # Si aucune phrase n'a pu être ajoutée (phrase isolée trop longue),
        # on force l'ajout de cette phrase unique (pour éviter boucle infinie).
        if j == i:
            # couper la phrase trop longue en morceaux de taille max_chars
            long_sent = sentences[i]
            start = 0
            while start < len(long_sent):
                chunk_part = long_sent[start:start + max_chars].strip()
                if chunk_part:
                    chunks.append(chunk_part)
                start += max_chars
            i += 1
            continue

        chunk_text = " ".join(sentences[i:j]).strip()
        if chunk_text:
            chunks.append(chunk_text)

        # Calculer le prochain index en gardant un chevauchement de 'overlap_sentences' phrases
        # On veut reculer de overlap_sentences phrases par rapport à j, mais pas avant i+1
        step_back = overlap_sentences
        next_i = max(i + 1, j - step_back)
        i = next_i

    return chunks

def main():
    # ensure_dirs doit renvoyer (raw_pdfs, raw_txt, cleaned_chunks)
    raw_pdfs, raw_txt, cleaned_chunks = ensure_dirs()

    # Le dossier cleaned_txt est dans le parent de cleaned_chunks
    cleaned_txt_folder = cleaned_chunks.parent / "cleaned_txt"
    if not cleaned_txt_folder.exists():
        print(f"⚠️ Dossier introuvable : {cleaned_txt_folder}\nExécute d'abord preprocess.py")
        return

    cleaned_files = sorted(cleaned_txt_folder.glob("*_clean.txt"))
    if not cleaned_files:
        print("⚠️ Aucun fichier nettoyé trouvé dans", cleaned_txt_folder)
        return

    output_file = cleaned_chunks / "chunks.jsonl"
    with output_file.open("w", encoding="utf-8") as fout:
        for path in tqdm(cleaned_files, desc="Découpage en chunks"):
            text = path.read_text(encoding="utf-8")
            # Tokenize en phrases (français)
            sentences = sent_tokenize(text, language='french')
            if not sentences:
                continue

            # Obtenir les chunks (valeurs par défaut : max_chars=900, overlap_sentences=2)
            chunks = chunk_sentences(sentences, max_chars=900, overlap_sentences=2)
            for idx, chunk in enumerate(chunks):
                record = {
                    "source": path.stem.replace("_clean", ""),
                    "chunk_id": f"{path.stem}_{idx}",
                    "text": chunk
                }
                fout.write(json.dumps(record, ensure_ascii=False) + "\n")

    print(f"✅ Chunks enregistrés dans : {output_file}")

if __name__ == "__main__":
    main()
