#!/usr/bin/env bash

flox activate -- find . -name '*.md' -not -name 'SKILL.md' -exec mdformat --number {} +
