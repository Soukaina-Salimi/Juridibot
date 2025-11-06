import os
import faiss
import pandas as pd
from pathlib import Path
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv
from openai import OpenAI

# ==============================
# 🔹 Configuration de base
# ==============================
load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise RuntimeError("❌ OPENAI_API_KEY non trouvée. Crée un fichier .env avec ta clé OpenAI.")
client = OpenAI(api_key=OPENAI_API_KEY)

BASE = Path(__file__).resolve().parents[1]
INDEX_FILE = BASE / "data/cleaned_chunks/faiss_index.bin"
META_FILE = BASE / "data/cleaned_chunks/chunks_meta.parquet"

EMBED_MODEL = "paraphrase-multilingual-MiniLM-L12-v2"
TOP_K = 5
DISTANCE_THRESHOLD = 7.5      # 🔸 seuil de distance FAISS : plus petit = plus strict
MAX_CONTEXT_CHARS = 2000      # 🔸 longueur max du contexte

# ==============================
# 🔹 Prompts
# ==============================
SYSTEM_PROMPT = (
    "Tu es **JuridiBot**, un assistant juridique marocain. "
    "Tu réponds UNIQUEMENT sur la base des documents fournis (Codes marocains, droit du travail, droit pénal, etc.). "
    "Si la question n’a aucun rapport avec ces textes, tu dois répondre : "
    "'Je ne peux pas répondre à cette question car elle ne figure pas dans ma base de connaissances juridiques.' "
    "Toujours citer les sources utilisées à la fin de ta réponse, au format : [source: Code du travail marocain]."
)

INSTRUCTION_PROMPT = (
    "Utilise exclusivement les extraits suivants pour formuler ta réponse. "
    "Ne crée ni n'invente d'informations extérieures au texte."
)

# ==============================
# 🔹 Chargement des données
# ==============================
print("Chargement de l’index FAISS et des métadonnées...")
index = faiss.read_index(str(INDEX_FILE))
df_meta = pd.read_parquet(META_FILE)
print(f"✅ Index chargé ({index.ntotal} vecteurs).")

embedder = SentenceTransformer(EMBED_MODEL)

# ==============================
# 🔹 Fonctions principales
# ==============================
def retrieve(query: str, top_k: int = TOP_K):
    """Recherche les passages similaires dans FAISS"""
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
    """Construit le texte du contexte à envoyer au modèle"""
    context_parts, total_len = [], 0
    for c in chunks:
        passage = f"[{c['source']}] {c['text']}"
        if total_len + len(passage) > MAX_CONTEXT_CHARS:
            break
        context_parts.append(passage)
        total_len += len(passage)
    return "\n\n---\n\n".join(context_parts)


def ask_openai(question, context, model="gpt-4o-mini", temperature=0.0):
    """Appelle le modèle OpenAI avec le contexte"""
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": INSTRUCTION_PROMPT + "\n\nContexte :\n" + context},
        {"role": "user", "content": "Question : " + question}
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


# ==============================
# 🔹 CLI principale
# ==============================
def main():
    print("\nBienvenue dans **JuridiBot CLI 🇲🇦**")
    print("Pose une question juridique ou tape 'quit' pour sortir.\n")

    while True:
        question = input("Question > ").strip()
        if question.lower() in ("quit", "exit"):
            print("👋 Fin du programme. À bientôt !")
            break
        if not question:
            continue

        # Étape 1 : Recherche
        chunks = retrieve(question, top_k=TOP_K)

        # Étape 2 : Filtrage selon la distance
        relevant_chunks = [c for c in chunks if c["distance"] < DISTANCE_THRESHOLD]
        if not relevant_chunks:
            print("\n🚫 Aucun passage pertinent trouvé.")
            print("=== 💬 Réponse JuridiBot ===")
            print("Je ne peux pas répondre à cette question car elle ne figure pas dans ma base de connaissances juridiques.")
            print("\n---------------------------------------------\n")
            continue

        # Étape 3 : Affichage des sources retenues
        print(f"\n🔍 {len(relevant_chunks)} passages pertinents trouvés :")
        for c in relevant_chunks:
            print(f"- {c['source']} (dist={c['distance']:.2f})")

        # Étape 4 : Construction du contexte
        context = build_context(relevant_chunks)

        # Étape 5 : Génération de la réponse
        print("\n🧠 Génération de la réponse...")
        answer = ask_openai(question, context)

        # Étape 6 : Affichage du résultat
        print("\n=== 💬 Réponse JuridiBot ===")
        print(answer)

        print("\n=== 📚 Sources utilisées ===")
        for c in relevant_chunks:
            print(f"- {c['source']} ({c['chunk_id']})")

        print("\n---------------------------------------------\n")


if __name__ == "__main__":
    main()