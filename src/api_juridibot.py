# ============================
#    JuridiBot - API RAG Maroc
# ============================

import os
import faiss
import pandas as pd
from pathlib import Path
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv
from openai import OpenAI
from pydantic import BaseModel
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


# ============================
# 🔹 Création API
# ============================

app = FastAPI()

# ============================
# 🔹 Configuration générale
# ============================

load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise RuntimeError("❌ OPENAI_API_KEY manquante dans .env")

client = OpenAI(api_key=OPENAI_API_KEY)

BASE = Path(__file__).resolve().parents[1]
INDEX_FILE = BASE / "data/cleaned_chunks/faiss_index.bin"
META_FILE = BASE / "data/cleaned_chunks/chunks_meta.parquet"

EMBED_MODEL = "paraphrase-multilingual-MiniLM-L12-v2"
TOP_K = 5
DISTANCE_THRESHOLD = 9.5
MAX_CONTEXT_CHARS = 7000

# ============================
# 🔹 Prompts
# ============================

SYSTEM_PROMPT = (
    "Tu es JuridiBot, un assistant juridique marocain. "
    "Tu réponds UNIQUEMENT à partir des extraits fournis. "
    "Si les textes ne contiennent pas la réponse : "
    "'Je ne peux pas répondre à cette question car elle ne figure pas dans ma base juridique.' "
    "Toujours citer les sources."
)

INSTRUCTION_PROMPT = (
    "N'utilise que les extraits suivants. "
    "Ne crée aucune information externe."
)

# ============================
# 🔹 Chargement FAISS
# ============================

print("📦 Chargement index FAISS...")
index = faiss.read_index(str(INDEX_FILE))
df_meta = pd.read_parquet(META_FILE)
embedder = SentenceTransformer(EMBED_MODEL)
print(f"✅ Index chargé ({index.ntotal} vecteurs).")


# ============================
# 🔹 Fonctions RAG
# ============================

def retrieve(query):
    q_vec = embedder.encode([query], convert_to_numpy=True)
    D, I = index.search(q_vec, TOP_K)

    results = []
    for idx, dist in zip(I[0], D[0]):
        row = df_meta.iloc[idx]
        results.append({
            "chunk_id": row["chunk_id"],
            "source": row["source"],
            "article": row.get("article", ""),  # 🔥 ajoute article avec fallback vide
            "text": row["text"],
            "distance": float(dist)
        })
    return results



def filter_relevant(chunks):
    filtered = [c for c in chunks if c["distance"] < DISTANCE_THRESHOLD]
    return filtered if filtered else chunks[:2]


def build_context(chunks):
    parts = []
    total = 0
    for c in chunks:
        block = f"[{c['source']}] {c['text']}"
        if total + len(block) > MAX_CONTEXT_CHARS:
            break
        parts.append(block)
        total += len(block)
    return "\n\n---\n\n".join(parts)


def ask_llm(question, context):
    msgs = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": INSTRUCTION_PROMPT + "\n\nContexte :\n" + context},
        {"role": "user", "content": "Question : " + question}
    ]

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=msgs,
            temperature=0.0,
            max_tokens=500
        )
        return response.choices[0].message.content.strip()

    except Exception as e:
        return f"⚠️ Erreur OpenAI : {e}"


# ============================
# 🔹 API INPUT MODEL
# ============================

class Query(BaseModel):
    question: str


# ============================
# 🔹 Endpoint API
# ============================

# Autoriser les requêtes Flutter / ngrok
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/ask")
def ask_api(question: str):
    # 1) Retrieve chunks
    chunks = retrieve(question)
    filtered = filter_relevant(chunks)

    if not filtered:
        return {
            "answer": "Je ne peux pas répondre à cette question car elle ne figure pas dans ma base juridique.",
            "context_found": False,
            "sources": [],
            "count_chunks": 0
        }

    # 2) Build context
    context = build_context(filtered)

    # 3) LLM answer
    answer = ask_llm(question, context)

    # 4) Extraire tous les articles uniques
    all_articles = []
    for c in filtered:
        if c["article"]:
            # transformer en liste si séparé par des virgules
            arts = [a.strip() for a in c["article"].split(",")]
            all_articles.extend(arts)
    all_articles = sorted(list(set(all_articles)))  # supprimer doublons

    # 5) Retour API
    return {
        "answer": answer,
        "context_found": True,
        "sources": [
            {
                "source": c["source"],
                "articles": [a.strip() for a in c["article"].split(",")] if c["article"] else []
            }
            for c in filtered
        ],
        "articles": all_articles,   # ✅ tous les articles de tous les chunks
        "count_chunks": len(filtered)
    }
