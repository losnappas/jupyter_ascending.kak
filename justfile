build:
    pip install -r requirements.txt

# https://github.com/imbue-ai/jupyter_ascending/blob/main/README.md
setup-nb:
    python -m jupyter nbextension    install jupyter_ascending --sys-prefix --py && \
      python -m jupyter nbextension     enable jupyter_ascending --sys-prefix --py && \
      python -m jupyter serverextension enable jupyter_ascending --sys-prefix --py

setup: build setup-nb
