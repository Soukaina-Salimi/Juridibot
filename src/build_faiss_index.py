# src/build_faiss_index.py
import json
import faiss
import numpy as np
import pandas as pd
from tqdm import tqdm
from pathlib import Path
from sentence_transformers import SentenceTransformer


#  CONFIG

BASE = Path(__file__).resolve().parents[1]
CHUNKS_FILE = BASE / "data/cleaned_chunks/chunks_by_article.jsonl"
INDEX_OUT = BASE / "data/cleaned_chunks/faiss_index.bin"
META_OUT = BASE / "data/cleaned_chunks/chunks_meta.parquet"

EMBED_MODEL = "paraphrase-multilingual-MiniLM-L12-v2"
BATCH_SIZE = 32


#  LOAD CHUNKS

def load_chunks(jsonl_path):
    chunks = []
    with open(jsonl_path, "r", encoding="utf-8") as f:
        for line in f:
            chunks.append(json.loads(line))
    return chunks



#  EMBED USING SENTENCE TRANSFORMERS

def embed_chunks(chunks, embedder):
    texts = [c["text"] for c in chunks]
    embeddings = []

    print(f"Vectorisation ({len(texts)} chunks)...")

    for i in tqdm(range(0, len(texts), BATCH_SIZE)):
        batch = texts[i:i + BATCH_SIZE]
        vecs = embedder.encode(batch, convert_to_numpy=True)
        embeddings.append(vecs)

    return np.vstack(embeddings)



#  BUILD FAISS INDEX

def build_faiss_index(embeddings):
    dim = embeddings.shape[1]  # 768 dimensions
    index = faiss.IndexFlatL2(dim)
    index.add(embeddings)
    return index



#  MAIN

def main():
    print("🔵 Chargement des chunks…")
    chunks = load_chunks(CHUNKS_FILE)
    print(f"➡️ {len(chunks)} chunks chargés.\n")

    embedder = SentenceTransformer(EMBED_MODEL)

    # Vectorisation
    embeddings = embed_chunks(chunks, embedder)
    print("✅ Embeddings générés.")

    # Indexation
    index = build_faiss_index(embeddings)
    print(f"✅ Index FAISS construit ({index.ntotal} vecteurs).")

    # Sauvegarde
    faiss.write_index(index, str(INDEX_OUT))
    print(f"💾 Index enregistré → {INDEX_OUT}")

    df = pd.DataFrame(chunks)
    df["embedding_dim"] = embeddings.shape[1]
    df.to_parquet(META_OUT, index=False)
    print(f"💾 Métadonnées enregistrées → {META_OUT}")

    print("\n🎉 Vectorisation + Indexation FAISS terminée !")


if __name__ == "__main__":
    main()