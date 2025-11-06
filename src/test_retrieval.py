# src/test_retrieval.py
import faiss
import pandas as pd
from sentence_transformers import SentenceTransformer
from pathlib import Path
import numpy as np

# --- Config ---
INDEX_FILE = Path(__file__).resolve().parents[1] / "data/cleaned_chunks/faiss_index.bin"
META_FILE = Path(__file__).resolve().parents[1] / "data/cleaned_chunks/chunks_meta.parquet"
MODEL_NAME = "paraphrase-multilingual-MiniLM-L12-v2"
TOP_K = 3

# --- Charger index et métadonnées ---
index = faiss.read_index(str(INDEX_FILE))
df_meta = pd.read_parquet(META_FILE)

model = SentenceTransformer(MODEL_NAME)

# --- Fonction recherche ---
def search(query, top_k=TOP_K):
    q_vec = model.encode([query], convert_to_numpy=True)
    D, I = index.search(q_vec, top_k)
    results = []
    for idx, dist in zip(I[0], D[0]):
        row = df_meta.iloc[idx]
        results.append({
            "source": row["source"],
            "chunk_id": row["chunk_id"],
            "text": row["text"],
            "distance": float(dist)
        })
    return results

# --- Exemple ---
query = "Durée normale du travail au Maroc"
results = search(query)
for r in results:
    print(f"[{r['source']} - {r['chunk_id']}] (dist={r['distance']:.2f})\n{r['text']}\n---")
