FROM codewars/base-runner

# <https://github.com/docker-library/golang/blob/master/1.8/stretch/Dockerfile>
# gcc for cgo
RUN apt-get update && apt-get install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
		pkg-config \
	&& rm -rf /var/lib/apt/lists/*

ENV GOLANG_VERSION 1.8
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 53ab94104ee3923e228a2cb2116e5e462ad3ebaeea06ff04463479d7f12d27ca

RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
	&& echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
	&& tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

RUN go get github.com/onsi/ginkgo/ginkgo  # installs the ginkgo CLI
RUN go get github.com/onsi/gomega         # fetches the matcher library

RUN ln -s /home/codewarrior /workspace
WORKDIR /runner
ENV NPM_CONFIG_LOGLEVEL=warn
COPY package.json /runner/package.json
RUN npm install --only=prod

COPY lib /runner/lib

COPY docker/frameworks/codewars $GOPATH/src/codewars
RUN go install codewars/reporter

# TODO: separate test
RUN npm install --only=dev
COPY test /runner/test

USER codewarrior
ENV USER=codewarrior HOME=/home/codewarrior
# Use global mocha for now. local one exits after first test for some reason.
RUN NODE_ENV=test mocha -t 5000
ENTRYPOINT ["timeout", "17", "node"]
