#!/bin/bash

echo "Compiling SocialNet Simulator..."

g++ -std=c++17 -o socialnet \
    Main.cpp \
    SocialNet/Socialnet.cpp \
    Data\ Structures/Graph.cpp \
    Data\ Structures/AVLTree.cpp

echo "Compilation finished successfully."
echo "To run the simulator, use the command: ./socialnet"