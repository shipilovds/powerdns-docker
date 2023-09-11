import os

UPLOAD_DIR = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'upload')

{% for key, value in environment('PDNS_ADMIN_') %}
{% if value == 'True' or value == 'False' %}
{{ key }} = {{ value | replace('[\'\"]', '') }}
{% else%}
{{ key }} = '{{ value | replace('[\'\"]', '') }}'
{% endif %}
{% endfor %}

### DATABASE CONFIG
SQLALCHEMY_DATABASE_URI = f"postgresql://{SQLA_DB_USER}:{SQLA_DB_PASSWORD}@{SQLA_DB_HOST}:{SQLA_DB_PORT}/{SQLA_DB_NAME}"
if SQLA_DB_URI_PARAMETER_LIST != '':
    SQLALCHEMY_DATABASE_URI = f"{SQLALCHEMY_DATABASE_URI}?{SQLA_DB_URI_PARAMETER_LIST}"
SQLALCHEMY_TRACK_MODIFICATIONS = True
