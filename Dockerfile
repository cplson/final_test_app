FROM mhart/alpine-node
# COPY . /app
# RUN npm install
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . /app
# CMD node /app/index.js
EXPOSE  3000
CMD ["node", "index.js"]


# package files first (for caching)
# COPY /app/package*.json ./app

# Install dependencies
# RUN npm install

# Copy app source
# COPY . /app

# Expose port 3000
# EXPOSE 3000

# Start the app
# CMD ["node", "index.js"]
