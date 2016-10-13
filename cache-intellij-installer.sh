#!/usr/bin/env bash

# Cache the IntelliJ IDEA Community Edition installation package:
# Note: This has to be executed once before building the Dockerfile
wget \
  --continue \
  --directory-prefix 'files/' \
  'http://download-cf.jetbrains.com/idea/ideaIC-2016.2.2.tar.gz' \
