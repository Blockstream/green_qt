#!/bin/bash

cpplint --quiet \
  --filter=-,+build/c++14,+build/deprecated,+build/endif_comment,+build/forward_decl,+build/include_alpha,+build/include_what_you_use \
  --recursive src

cpplint --quiet \
  --filter=-,+whitespace/parens \
  --recursive src
