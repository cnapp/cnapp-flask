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


import logging

from opencensus.trace import config_integration
from opencensus.trace.ext.flask import flask_middleware
from opencensus.trace.propagation import trace_context_http_header_format


LOGGER = logging.getLogger(__name__)


def setup(app, trace_integrations=None):
    """Setup tracing using Opencensus.

    Args:
        app ([flask.Flask]): the main application
        trace_integrations ([list]): Default ['httplib']. A list of services to
            enable (httplib, mysql, postgresql, sqlalchemy, requests)

    Returns:
        [flask_middleware.Middleware]: the middleware for tracing a Flask application
    """

    LOGGER.debug("Configure application Tracing")
    if trace_integrations is not None:
        config_integration.trace_integrations(trace_integrations)
    else:
        config_integration.trace_integrations(['httplib'])

    blacklist_paths = ['health']
    return flask_middleware.FlaskMiddleware(
        app,
        blacklist_paths=blacklist_paths,
        propagator = trace_context_http_header_format.TraceContextPropagator())
