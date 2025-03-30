# docker run --rm --name toot -d -p 1972:1972 -p 52773:52773 -p 80:80 -p 443:443 -v "%CD%\external\durable":/durable toot
# docker -it toot /bin/bash
# docker exec -u root toot apachectl start
# Visit link: https://localhost/iris/csp/toot/TOOT.Web.Button.cls
# Management Portal link: http://127.0.0.1:52773/iris/csp/sys/UtilHome.csp

FROM containers.intersystems.com/intersystems/iris-community:2024.3
USER root

# ffmpeg: Used to convert WAV to MP3
# timidity: Used to convert MIDI to WAV
# midicsv: convert midi binary to acsii text
# sound_to_midi: convert WAV to MIDI binary
# Use the CPU version of torch for maximum compatability
# Prevent importing NVIDIA CUDA dependencies
# Pin the torch version for simpler build reusability of demo
# Also exludes specifying torchvision torchaudio
# Installs huggingface sentence transformers for encodings
# Use an uber RUN command to reduce the number of layers and make some reduction in final size
# Software Properties common needed before midiutil will take
# librosa may have gone in via pip
RUN apt-get update; \
  apt-get -y install ffmpeg; \
  apt-get -y install --no-install-recommends git-lfs timidity librosa midiutil; \
  apt-get -y install apache2; \
# pytorch CPU based
  pip3 install -q -q --exists-action i --break-system-packages torch~=2.6.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu; \
  pip install transformers --break-system-packages; \
  pip install -q -q --exists-action i --break-system-packages sentence-transformers ; \
  pip install -U --break-system-packages librosa midiutil; \
  yes | pip install --no-cache-dir -q -q --exists-action i --break-system-packages py_midicsv sound_to_midi

#enable HTTP proxy modules
RUN a2enmod proxy && \
  a2enmod proxy_http && \
  a2enmod ssl && \
  a2enmod proxy && \
  a2enmod proxy_http2 && \
  a2enmod proxy_html

# delete the last line of a file
# update SSL virtual site with proxy pass
# enable ssl site
RUN sed -i '$d' /etc/apache2/sites-available/default-ssl.conf && \
  echo ' \n\
LoadModule proxy_module modules/mod_proxy.so \n\
LoadModule proxy_http_module modules/mod_proxy_http.so \n\
  ProxyPreserveHost On \n\
  ProxyRequests Off \n\
  ProxyPass /iris http://localhost:52773/iris \n\
  ProxyPassReverse /iris http://localhost:52773/iris \n\
</VirtualHost> ' >> /etc/apache2/sites-available/default-ssl.conf && \
  a2ensite default-ssl

#CMD apachectl start
RUN echo '#!/bin/bash  \
  apachectl start' > /etc/profile.d/custom.sh

RUN  mkdir -p /opt/hub/toot; \
  chown -R irisowner:irisowner /opt/hub/toot
  
  # Copy Embedding model file to

COPY --chown=irisowner ./model/* /opt/hub/toot/

# Set the cache reference without the implict "hub" subfolder.
# This is appended by the transformer loading 
ENV HF_HOME=/opt/
# Switch to irisowner before download of model resource
USER irisowner

WORKDIR /home/irisowner/dev

ENV PATH="/usr/irissys/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/irisowner/bin"

RUN --mount=type=bind,src=.,dst=. \
    iris start IRIS && \
	iris session IRIS < iris.script && \
	iris session IRIS -U %SYS "##class(SYS.Container).QuiesceForBundling()" && \
    iris stop IRIS quietly
