# The WORKSHOP image: the code, prebuilt, on top of the tools image.
# Rebuilt whenever the workshop content changes — attendees who already
# have the base pull only these layers.
#
# Build:  ./container/build.sh          (from the repository root)
# Run:    ./container/run.sh

ARG BASE_IMAGE=shipping-workshop-base:latest
FROM ${BASE_IMAGE}

WORKDIR /workshop
COPY . /workshop

# Prewarm everything code-shaped: all five scenario builds (Maven repo,
# npm cache, Python venv, S04's local fixture repo). Scanner databases are
# already in the base (--skip-db); image pulls and the S01/S02 image builds
# happen at run time via the host socket (--skip-pull --skip-images).
RUN chmod +x scripts/*.sh scenarios/*/scripts/*.sh investigations/*/scripts/*.sh \
    && ./scripts/build-all.sh --skip-pull --skip-images --skip-db

COPY container/motd.txt /etc/workshop-motd
RUN echo 'cat /etc/workshop-motd' >> /root/.bashrc
CMD ["/bin/bash"]
