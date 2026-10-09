import unittest
from unittest.mock import patch

from main import app, artifact


class ServerTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_serves_exact_build(self):
        expected = artifact.read_bytes()
        self.assertTrue(expected)
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, expected)
        self.assertEqual(response.content_type, "text/plain; charset=utf-8")

    def test_missing_build(self):
        with patch("main.artifact") as missing:
            missing.read_bytes.side_effect = FileNotFoundError
            response = self.client.get("/")
        self.assertEqual(response.status_code, 503)

    def test_source_route_removed(self):
        self.assertEqual(self.client.get("/src/main.lua").status_code, 404)


if __name__ == "__main__":
    unittest.main()
