from setuptools import find_packages
from setuptools import setup

REQUIRED_PACKAGES = ['sh']

setup(
    name='wals_ml_engine',
    version='0.1',
    author='Pankaj Sharma',
    author_email='luvneries@gmail.com',
    url='https://github.com/luvneries',
    install_requires=REQUIRED_PACKAGES,
    packages=find_packages(),
    include_package_data=True,
    description='A trainer application package for WALS on ML Engine.'
)