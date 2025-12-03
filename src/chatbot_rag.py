# ============================
#    JuridiBot - RAG Maroc
# ============================

import os
import faiss
import pandas as pd
from pathlib import Path
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv
from openai import OpenAI

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
DISTANCE_THRESHOLD = 12    # 🔥 seuil optimal pour Loi Famille / Travail
MAX_CONTEXT_CHARS = 7000


# ============================
# 🔹 Prompts LLM
# ============================

SYSTEM_PROMPT = (
    "Tu es JuridiBot, un assistant juridique marocain. "
    "Tu réponds UNIQUEMENT à partir des extraits fournis. "
    "Si les textes ne contiennent pas la réponse : tu dois dire : "
    "'Je ne peux pas répondre à cette question car elle ne figure pas dans ma base juridique.' "
    "Toujours citer les sources à la fin."
)

INSTRUCTION_PROMPT = (
    "N'utilise que les extraits suivants. "
    "Ne crée aucune information externe."
)

# ============================
# 🔹 Chargement du modèle & index
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
    """Recherche les chunks les plus similaires."""
    q_vec = embedder.encode([query], convert_to_numpy=True)
    D, I = index.search(q_vec, TOP_K)

    results = []
    for idx, dist in zip(I[0], D[0]):
        row = df_meta.iloc[idx]
        results.append({
            "chunk_id": row["chunk_id"],
            "source": row["source"],
            "text": row["text"],
            "distance": float(dist)
        })
    return results


def filter_relevant(chunks):
    """Filtrage intelligent des passages pertinents."""
    filtered = [c for c in chunks if c["distance"] < DISTANCE_THRESHOLD]

    if not filtered:
        # fallback : prendre les 2 meilleurs
        return chunks[:2]

    return filtered


def build_context(chunks):
    context = ""
    for c in chunks:
        block = f"[{c['source']}] {c['text']}\n\n---\n\n"
        if len(context) + len(block) <= MAX_CONTEXT_CHARS:
            context += block
        else:
            # couper proprement
            available = MAX_CONTEXT_CHARS - len(context)
            context += block[:available]
            break
    return context.strip()



def ask_llm(question, context):
    """Appel OpenAI."""
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
# 🔹 Interface terminal (CLI)
# ============================

def main():
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("    🤖 JuridiBot – Maroc 🇲🇦")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

    while True:
        q = input("❓ Question > ").strip()

        if q.lower() in ["quit", "exit"]:
            print("👋 Au revoir !")
            break

        if not q:
            continue

        # 1) Retrouver les chunks
        chunks = retrieve(q)
        filtered = filter_relevant(chunks)

        print("\n📚 Passages retenus :")
        for c in filtered:
            print(f"- {c['source']} | dist={c['distance']:.2f}")

        # 2) Vérifier si aucun passage n'est pertinent
        if not filtered:
            print("\n=== 💬 Réponse JuridiBot ===")
            print("Je ne peux pas répondre à cette question car elle ne figure pas dans ma base juridique.\n")
            continue

        # 3) Construire contexte
        context = build_context(filtered)

        # 4) LLM
        answer = ask_llm(q, context)

        print("\n=== 💬 Réponse JuridiBot ===")
        print(answer)

        print("\n=== 📚 Sources utilisées ===")
        for c in filtered:
            print(f"- {c['source']} ({c['chunk_id']})")

        print("\n--------------------------------------------\n")


if __name__ == "__main__":
    main()