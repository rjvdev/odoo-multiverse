from odoo import api, fields, models


class LabSelftest(models.Model):
    _name = "lab.selftest"
    _description = "Lab Selftest"

    name = fields.Char(required=True)
    value = fields.Integer()
    double = fields.Integer(compute="_compute_double", store=True)

    @api.depends("value")
    def _compute_double(self):
        for record in self:
            record.double = record.value * 2
