#!/usr/bin/env bash
# Kill old SSH sessions
kill $(ps aux | grep '[:]localhost:8888 -N' | awk '{print $2}')
