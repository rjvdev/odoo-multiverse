from odoo.tests.common import TransactionCase


class TestLabSelftest(TransactionCase):
    def test_create_and_compute(self):
        record = self.env["lab.selftest"].create({"name": "ping", "value": 21})
        self.assertEqual(record.name, "ping")
        self.assertEqual(record.double, 42)

    def test_recompute_on_write(self):
        record = self.env["lab.selftest"].create({"name": "pong", "value": 1})
        record.value = 5
        self.assertEqual(record.double, 10)
