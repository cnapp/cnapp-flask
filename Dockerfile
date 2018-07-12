# Copyright (C) 2018 Nicolas Lamirault <nicolas.lamirault@gmail.com>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM python:3.6-slim

LABEL summary="Python Flask version of Cnapps" \
      description="Python Flask version of Cnapps" \
      name="nlamirault/cnapps-python-flask" \
      url="https://github.com/nlamirault/cnapps" \
      maintainer="Nicolas Lamirault <nicolas.lamirault@gmail.com>"

ARG http_proxy
ARG https_proxy

RUN apt-get update -o Acquire::ForceIPv4=true \
    && apt-get install -o Acquire::ForceIPv4=true -y python-dev gcc curl \
    && rm -rf /var/lib/apt/lists/*
RUN curl -o /get-pip.py https://bootstrap.pypa.io/get-pip.py \
    && python3 get-pip.py

ADD ./requirements.txt /srv/
WORKDIR /srv
RUN pip3 install -r requirements.txt \
    && pip3 install gunicorn==19.7.1

ADD . /srv

EXPOSE 9191

CMD ["gunicorn", "--log-level", "debug", "--log-file=-", "-w", "1", "-b", "0.0.0.0:9191", "run:app"]
