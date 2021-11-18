from setuptools import setup

setup(
   name='x2542',
   version='1.0',
   description='Implements x2542',
   author='Derek Lam',
   author_email='derek@lam.io',
   packages=['x2542'],  #same as name
   install_requires=['astral','click','cycler','dataclasses','Flask','importlib-metadata','itsdangerous','Jinja2','kiwisolver','MarkupSafe','matplotlib','numpy','Pillow','pkg-resources','psycopg2','pyparsing','python-dateutil','pytz','six','typing-extensions','Werkzeug','zipp'], #external packages as dependencies
)
