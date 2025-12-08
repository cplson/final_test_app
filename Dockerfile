FROM mhart/alpine-node
COPY . /app
CMD node /app/index.js
EXPOSE  3000
