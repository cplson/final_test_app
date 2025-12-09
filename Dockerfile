# FROM mhart/alpine-node
# COPY . /app
# CMD node /app/index.js
# EXPOSE  3000

# Use official Node.js LTS image
FROM node:20

# Set working directory
WORKDIR /app

# Copy package files first (for caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy app source
COPY . /app

# Expose port 3000
EXPOSE 3000

# Start the app
CMD ["node", "index.js"]
