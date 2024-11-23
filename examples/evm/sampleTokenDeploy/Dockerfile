# use official upstream solc compiler from ethereum
ARG SOLC_VER=0.8.28
FROM ethereum/solc:${SOLC_VER}-alpine AS solc

FROM alpine:3.20.3

# copy upstream solc
COPY --from=solc /usr/local/bin/solc /usr/local/bin/solc

# copy app
WORKDIR /app
COPY . .

# install deps and link contracts
RUN apk add --no-cache nodejs-lts npm && \
    npm i -g npm && \
    npm install && \
    apk del npm

# set default container entrypoint
ENTRYPOINT [ "node" ]
CMD [ "/app/index.js" ]
