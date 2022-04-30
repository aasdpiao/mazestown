#!/bin/bash

if [ -f skynet.pid ]; then
    kill $(cat skynet.pid)
    rm skynet.pid
fi

if [ -f skynet.log ]; then
    rm skynet.log
fi

./skynet/skynet ./config/config

sleep 1

tail -f skynet.log