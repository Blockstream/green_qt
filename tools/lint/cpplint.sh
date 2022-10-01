#!/bin/bash

cpplint --filter=-,+build/include_what_you_use,+build/deprecated --recursive src
