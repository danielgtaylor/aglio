# Pull base image
FROM node:0.12.7

# Install Aglio
RUN npm install -g aglio@latest


ENTRYPOINT ["aglio"]
