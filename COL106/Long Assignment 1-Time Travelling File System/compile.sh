#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "Compiling the Time-Travelling File System..."

g++ -std=c++17 -Wall main.cpp File/FileSystem.cpp File/File.cpp -o filesystem

echo "Compilation finished. Executable 'filesystem' created."
echo "You can run the program using ./filesystem"
