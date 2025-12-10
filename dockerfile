# ============================
# 1. Image Python optimisée
# ============================
FROM python:3.10-slim

# ============================
# 2. Installation des dépendances système
# - faiss-cpu → dépendances BLAS
# - spaCy → dépendances linguistiques
# - torch → nécessite gcc
# ============================
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    g++ \
    git \
    wget \
    curl \
    libblas-dev \
    liblapack-dev \
    libatlas-base-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# ============================
# 3. Créer dossier app
# ============================
WORKDIR /app

# ============================
# 4. Copier requirements
# ============================
COPY requirements.txt .

# ============================
# 5. Installer les dépendances Python
# ============================
RUN pip install --no-cache-dir -r requirements.txt

# ============================
# 6. Copier tout le backend FastAPI
# ============================
COPY . .

# ============================
# 7. Exposer le port du backend
# ============================
EXPOSE 8000

# ============================
# 8. Commande pour lancer FastAPI + Uvicorn
# main.py → adapte si ton fichier principal a un autre nom
# ============================
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
