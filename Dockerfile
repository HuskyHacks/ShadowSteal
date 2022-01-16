FROM nimlang/nim

# Update APT
RUN apt-get update
RUN apt-get upgrade -y
# Requires apt install nim to install nimble
RUN apt-get install -y mingw-w64 make
RUN nimble install zippy argparse winim -y

# Clone ShadowSteal
WORKDIR /opt
RUN git clone https://github.com/HuskyHacks/ShadowSteal.git
WORKDIR /opt/ShadowSteal
RUN make
