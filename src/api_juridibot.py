from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
import os
import faiss
import pandas as pd
from pathlib import Path
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv
from openai import OpenAI

# =====================================================
# 🔹 Chargement des variables d'environnement
# =====================================================
load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise RuntimeError("❌ OPENAI_API_KEY non trouvée. Crée un fichier .env avec ta clé OpenAI.")

client = OpenAI(api_key=OPENAI_API_KEY)

# =====================================================
# 🔹 Configuration du projet
# =====================================================
BASE = Path(__file__).resolve().parents[1]
INDEX_FILE = BASE / "data/cleaned_chunks/faiss_index.bin"
META_FILE = BASE / "data/cleaned_chunks/chunks_meta.parquet"

EMBED_MODEL = "paraphrase-multilingual-MiniLM-L12-v2"
TOP_K = 5
DISTANCE_THRESHOLD = 7.5
MAX_CONTEXT_CHARS = 2000

# =====================================================
# 🔹 Prompts d'instructions
# =====================================================
SYSTEM_PROMPT = (
    "Tu es **JuridiBot**, un assistant juridique marocain. "
    "Tu réponds uniquement sur la base des textes juridiques fournis "
    "(Code du travail, Code de la famille, droit pénal, etc.). "
    "Si la question n’a aucun rapport avec ces documents, tu dois répondre : "
    "'Je ne peux pas répondre à cette question car elle ne figure pas dans ma base de connaissances juridiques.' "
    "Toujours citer les sources utilisées entre crochets à la fin."
)

INSTRUCTION_PROMPT = (
    "Utilise exclusivement les extraits suivants pour formuler ta réponse. "
    "Ne crée ni n'invente d'informations extérieures à ces textes."
)

# =====================================================
# 🔹 Chargement du modèle et des données
# =====================================================
print("Chargement de l’index FAISS et des métadonnées...")
index = faiss.read_index(str(INDEX_FILE))
df_meta = pd.read_parquet(META_FILE)
print(f"✅ Index chargé ({index.ntotal} vecteurs).")

embedder = SentenceTransformer(EMBED_MODEL)

# =====================================================
# 🔹 Fonctions principales
# =====================================================
def retrieve(query: str, top_k: int = TOP_K):
    """Recherche des passages similaires"""
    q_vec = embedder.encode([query], convert_to_numpy=True)
    D, I = index.search(q_vec, top_k)
    results = []
    for idx, dist in zip(I[0], D[0]):
        row = df_meta.iloc[idx]
        results.append({
            "chunk_id": row["chunk_id"],
            "source": row.get("source", "Inconnue"),
            "text": row["text"],
            "distance": float(dist)
        })
    return results


def build_context(chunks):
    """Construit le contexte"""
    context_parts, total_len = [], 0
    for c in chunks:
        passage = f"[{c['source']}] {c['text']}"
        if total_len + len(passage) > MAX_CONTEXT_CHARS:
            break
        context_parts.append(passage)
        total_len += len(passage)
    return "\n\n---\n\n".join(context_parts)


def ask_openai(question, context, model="gpt-4o-mini", temperature=0.0):
    """Appel à OpenAI"""
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": INSTRUCTION_PROMPT + "\n\nContexte :\n" + context},
        {"role": "user", "content": "Question : " + question},
    ]
    try:
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=800
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"⚠️ Erreur OpenAI : {e}"

# =====================================================
# 🔹 Création de l’application FastAPI
# =====================================================
app = FastAPI(title="JuridiBot API", version="1.0", description="Assistant juridique marocain IA")

# 🔸 Autoriser les requêtes Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ou restreindre à ton IP locale
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================================================
# 🔹 Endpoint principal
# =====================================================
@app.get("/ask")
def ask(question: str = Query(..., description="Question juridique")):
    """Répond à une question en se basant uniquement sur les PDFs indexés"""
    print(f"❓ Question reçue : {question}")

    # Étape 1 : Récupération des passages
    chunks = retrieve(question, top_k=TOP_K)

    # Étape 2 : Filtrage par distance
    relevant_chunks = [c for c in chunks if c["distance"] < DISTANCE_THRESHOLD]
    if not relevant_chunks:
        return {
            "answer": "Je ne peux pas répondre à cette question car elle ne figure pas dans ma base de connaissances juridiques.",
            "context_found": False,
            "sources": [],
        }

    # Étape 3 : Construction du contexte
    context = build_context(relevant_chunks)

    # Étape 4 : Génération de réponse
    answer = ask_openai(question, context)

    # Étape 5 : Retourner la réponse
    return {
        "answer": answer,
        "context_found": True,
        "sources": list({c["source"] for c in relevant_chunks}),
        "count_chunks": len(relevant_chunks),
    }

# =====================================================
# 🔹 Lancer le serveur (pour test local)
# =====================================================
# Commande à exécuter :
# uvicorn src.api_juridibot:app --host 0.0.0.0 --port 8000 --reload