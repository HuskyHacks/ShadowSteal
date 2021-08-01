FROM ubuntu:latest

# Update APT
RUN apt-get update
RUN apt-get upgrade -y
# Requires apt install nim to install nimble
RUN apt-get install -y nim mingw-w64 make git tar curl xz-utils

# Then, install later version of nim needed for zippy
RUN mkdir -p /tmp/nim && \
	curl -sL "https://nim-lang.org/download/nim-1.4.8-linux_x64.tar.xz" | tar xJ --strip-components=1 -C /tmp/nim && \
	cd /tmp/nim && chmod +x install.sh && \
	./install.sh /usr/bin && \
	rm -rf /tmp/nim
	
# Nim dependencies
RUN nimble install zippy argparse winim -y

# Clone ShadowSteal
WORKDIR /opt
RUN git clone https://github.com/HuskyHacks/ShadowSteal.git
WORKDIR /opt/ShadowSteal
RUN make

