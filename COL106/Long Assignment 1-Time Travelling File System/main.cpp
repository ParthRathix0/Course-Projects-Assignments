#include "File/FileSystem.hpp"
#include <iostream>
#include <string>
#include <sstream>
#include <vector>

using namespace std;

string remain_content(stringstream& ss) {
    string content;
    string temp;
    if (ss >> temp) {
        content += temp;
        while (ss >> temp) {
            content += " " + temp;
        }
    }
    return content;
}

int main() {
    FileSystem fs;
    string line;

    while (getline(cin, line)) {
        stringstream ss(line);
        string command;
        ss >> command;

        if (command == "CREATE") {
            string filename;
            if (ss >> filename) fs.CREATE(filename);
            else cerr << "Usage: CREATE <filename>" << endl;
        } else if (command == "READ") {
            string filename;
            if (ss >> filename) fs.READ(filename);
            else cerr << "Usage: READ <filename>" << endl;
        } else if (command == "INSERT") {
            string filename;
            if (ss >> filename) {
                string content = remain_content(ss);
                fs.INSERT(filename, content);
            } else {
                cerr << "Usage: INSERT <filename> <content>" << endl;
            }
        } else if (command == "UPDATE") {
            string filename;
            if (ss >> filename) {
                string content = remain_content(ss);
                fs.UPDATE(filename, content);
            } else {
                cerr << "Usage: UPDATE <filename> <content>" << endl;
            }
        } else if (command == "SNAPSHOT") {
            string filename;
            if (ss >> filename) {
                string message = remain_content(ss);
                fs.SNAPSHOT(filename, message);
            } else {
                cerr << "Usage: SNAPSHOT <filename> <message>" << endl;
            }
        } else if (command == "ROLLBACK") {
            string filename;
            if (ss >> filename) {
                int versionID;
                if (ss >> versionID) fs.ROLLBACK(filename, versionID);
                else fs.ROLLBACK(filename);
            } else {
                cerr << "Usage: ROLLBACK <filename>[versionID]" << endl;
            }
        } else if (command == "HISTORY") {
            string filename;
            if (ss >> filename) fs.HISTORY(filename);
            else cerr << "Usage: HISTORY <filename>" << endl;
        } else if (command == "RECENT_FILES") {
            int num;
            if (ss >> num) fs.RECENT_FILES(num);
            else fs.RECENT_FILES(-1);
        } else if (command == "BIGGEST_TREES") {
            int num;
            if (ss >> num) fs.BIGGEST_TREES(num);
            else fs.BIGGEST_TREES(-1);
        } else if (!command.empty()) {
            cerr << "Error: Unknown command '" << command << "'." << endl;
        }
    }

    return 0;
}
