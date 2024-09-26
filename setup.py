import os
from setuptools import setup, find_packages


def get_version():
    with open(
        os.path.join(
            os.path.dirname(os.path.realpath(__file__)),
            "seqchk",
            "seqchk.VERSION",
        )
    ) as f:
        return f.readline().strip()
    

def get_description():
    with open("README.md", "r") as fh:
        long_description = fh.read()
    return long_description


def get_data_files():
    data_files = [(".", ["README.md"])]
    return data_files


CLASSIFIERS = [
    "Environment :: Console",
    "Environment :: MacOS X",
    "Intended Audience :: Science/Research",
    "License :: OSI Approved :: Other/Proprietary License",
    "Natural Language :: English",
    "Operating System :: POSIX :: Linux",
    "Operating System :: MacOS :: MacOS X",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Topic :: Scientific/Engineering :: Bio-Informatics",
]

setup(
    name="seqchk",
    packages=find_packages(),
    url="https://github.com/kdm9/seqchk",
    python_requires=">=3.9",
    description="Quickly QC, map, and check a new sequencing run",
    long_description=get_description(),
    long_description_content_type="text/markdown",
    version=get_version(),
    author="KD Murray",
    author_email="foss@kdmurray.id.au",
    data_files=get_data_files(),
    py_modules=["seqchk"],
    install_requires=[
        "snaketool-utils>=0.0.4",
        "snakemake>=8",
        "pyyaml>=6.0",
        "Click>=8.1.3",
    ],
    entry_points={
        "console_scripts": [
            "seqchk=seqchk.__main__:main"
        ]
    },
    include_package_data=True,
)
