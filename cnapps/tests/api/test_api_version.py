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

import flask

from cnapps.tests import commons
from cnapps.tests import http
from cnapps import version


class ApiVersionUnitTestCase(commons.CnappsUnitTestCase):
    def test_get_version(self):
        response = http.get(self.app_client, "/version")
        self.check_content_type(response)
        self.assertEqual("200 OK", response.status)
        content = flask.json.loads(response.data)
        self.assertEqual(version.RELEASE, content["version"])
