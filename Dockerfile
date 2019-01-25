# Copyright (C) 2018-2019 Nicolas Lamirault <nicolas.lamirault@gmail.com>

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

# FROM python:3.6-slim
FROM python:3.6-alpine

LABEL summary="Python Flask version of Cnapps" \
      description="Python Flask version of Cnapps" \
      name="nlamirault/cnapps-python-flask" \
      url="https://github.com/nlamirault/cnapps" \
      maintainer="Nicolas Lamirault <nicolas.lamirault@gmail.com>"

ARG http_proxy
ARG https_proxy

# RUN apt-get update -o Acquire::ForceIPv4=true \
#     && apt-get install -o Acquire::ForceIPv4=true -y python-dev gcc curl \
#     && rm -rf /var/lib/apt/lists/*
RUN apk add --no-cache --virtual .build-deps \
    curl gcc python3-dev musl-dev linux-headers libffi-dev openssl-dev

RUN curl -o /get-pip.py https://bootstrap.pypa.io/get-pip.py \
    && python3 get-pip.py

RUN pip3 install gunicorn==19.9.0

RUN curl -sSL https://raw.githubusercontent.com/sdispater/poetry/master/get-poetry.py | python

WORKDIR /srv

COPY ./deps /srv/deps/

COPY pyproject.* /srv/
COPY poetry.lock /srv/

RUN /root/.poetry/bin/poetry config settings.virtualenvs.create false
RUN /root/.poetry/bin/poetry install -n --no-dev

RUN pip3 install gunicorn==19.9.0

ADD . /srv

RUN addgroup -S cnapps \
    && adduser -S cnapps -G cnapps
USER cnapps

EXPOSE 9191

CMD ["gunicorn", "--log-level", "debug", "--log-file=-", "-w", "1", "-b", "0.0.0.0:9191", "run:app"]
