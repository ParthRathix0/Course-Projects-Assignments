#include <iostream>
#include <string>
#include "SocialNet/SocialNet.hpp"

using namespace std;

int main() {
    SocialNet simulator;
    string line;

    while (getline(cin, line)) {
        if (line.empty()) {
            continue;
        }

        simulator.executeCommand(line);
    }

    return 0;
}
