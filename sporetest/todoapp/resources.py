from flask_potion import ModelResource, fields
from models import Todo


class TodoResource(ModelResource):
    class Meta:
        model = Todo
        required_fields = ('title', 'done')
        # id_field_class = fields.String()
