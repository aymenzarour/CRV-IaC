# Utiliser une image Node.js stable et légère
FROM node:18-alpine

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers package.json et yarn.lock dans le conteneur
COPY app/package.json app/yarn.lock ./

# Installer les dépendances avec yarn
RUN yarn install --frozen-lockfile

# Copier tout le code source de `app/` vers `/app`
COPY app .

# Exposer le port 3000
EXPOSE 3000

# Définir les variables d'environnement
ENV REDIS_URL=redis://redis-main:6379
ENV REDIS_REPLICAS_URL=redis://redis-replicas:6379
ENV PORT=3000

# Commande de démarrage
CMD ["node", "main.js"]
