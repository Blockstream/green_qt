#!/bin/bash

cpplint --quiet \
  --filter=-,+build/c++14,+build/deprecated,+build/endif_comment,+build/forward_decl,+build/include_alpha,+build/include_what_you_use \
  --exclude=src/glsdk \
  --exclude=src/lwk \
  --recursive src

cpplint --quiet \
  --filter=-,+whitespace/blank_line,+whitespace/parens \
  --exclude=src/glsdk \
  --exclude=src/lwk \
  --recursive src
