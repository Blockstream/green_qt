#!/bin/bash

cpplint --quiet \
  --filter=-,+build/include_what_you_use \
  --filter=-,+build/deprecated \
  --filter=-,+build/include_alpha \
	--recursive src
