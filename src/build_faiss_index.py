# src/build_faiss_index.py
import json
from pathlib import Path
from tqdm import tqdm
import pandas as pd
import numpy as np
import faiss
from sentence_transformers import SentenceTransformer

# --- Config ---
CHUNKS_FILE = Path(__file__).resolve().parents[1] / "data/cleaned_chunks/chunks.jsonl"
INDEX_FILE = Path(__file__).resolve().parents[1] / "data/cleaned_chunks/faiss_index.bin"
META_FILE = Path(__file__).resolve().parents[1] / "data/cleaned_chunks/chunks_meta.parquet"
MODEL_NAME = "paraphrase-multilingual-MiniLM-L12-v2"
EMBED_DIM = 384  # Dimension du modèle MiniLM

# --- Charger chunks ---
chunks = []
sources = []
chunk_ids = []

with CHUNKS_FILE.open("r", encoding="utf-8") as f:
    for line in f:
        data = json.loads(line)
        chunks.append(data["text"])
        sources.append(data["source"])
        chunk_ids.append(data["chunk_id"])

print(f"✅ {len(chunks)} chunks chargés.")

# --- Embeddings ---
model = SentenceTransformer(MODEL_NAME)
embeddings = model.encode(chunks, show_progress_bar=True, convert_to_numpy=True, batch_size=32)

print("✅ Embeddings calculés.")

# --- Créer index FAISS ---
index = faiss.IndexFlatL2(EMBED_DIM)
index.add(embeddings)
print(f"✅ Index FAISS créé avec {index.ntotal} vecteurs.")

# --- Sauvegarder index FAISS et métadonnées ---
faiss.write_index(index, str(INDEX_FILE))
print(f"✅ Index sauvegardé : {INDEX_FILE}")

# Sauvegarder métadonnées (source + chunk_id)
df_meta = pd.DataFrame({
    "chunk_id": chunk_ids,
    "source": sources,
    "text": chunks
})
df_meta.to_parquet(META_FILE, engine="pyarrow", index=False)
print(f"✅ Métadonnées sauvegardées : {META_FILE}")
