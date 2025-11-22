#include "FileSystem.hpp"
#include <iostream>
#include <vector>
#include <ctime>
#include <iomanip> 
#include <sstream> 

using namespace std;

FileSystem::FileSystem() {
    files = new HashMap<string, File*>();
    recentFiles = new MaxHeap<File*, ChangeT>();
    biggestTree = new MaxHeap<File*, VersionCount>();
}

FileSystem::~FileSystem() {
    vector<File*> all_files = files->allVal();
    for (File* file : all_files) {
        delete file;
    }
    delete files;
    delete recentFiles;
    delete biggestTree;
}

void FileSystem::rebuildHeaps() {
    recentFiles->clear();
    biggestTree->clear();
    vector<File*> all_files = files->allVal();
    for (File* file_ptr : all_files) {
        recentFiles->INSERT(file_ptr);
        biggestTree->INSERT(file_ptr);
    }
}

void FileSystem::CREATE(const string& filename) {
    if (files->get(filename) != nullptr) {
        cerr << "Error: File '" << filename << "' already exists." << endl;
        return;
    }
    File* new_file = new File(filename, time(0));
    files->INSERT(filename, new_file);
    rebuildHeaps();
    cout << "File '" << filename << "' created with snapshot version 0." << endl;
}

void FileSystem::READ(const string& filename) {
    File** file_ptr = files->get(filename);
    if (file_ptr == nullptr) {
        cerr << "Error: File '" << filename << "' not found." << endl;
        return;
    }
    cout << (*file_ptr)->READ() << endl;
}

void FileSystem::INSERT(const string& filename, const string& content) {
    File** file_ptr = files->get(filename);
    if (file_ptr == nullptr) {
        cerr << "Error: File '" << filename << "' not found." << endl;
        return;
    }
    (*file_ptr)->INSERT(content, time(0));
    rebuildHeaps();
}

void FileSystem::UPDATE(const string& filename, const string& content) {
    File** file_ptr = files->get(filename);
    if (file_ptr == nullptr) {
        cerr << "Error: File '" << filename << "' not found." << endl;
        return;
    }
    (*file_ptr)->UPDATE(content, time(0));
    rebuildHeaps();
}

void FileSystem::SNAPSHOT(const string& filename, const string& message) {
    File** file_ptr = files->get(filename);
    if (file_ptr == nullptr) {
        cerr << "Error: File '" << filename << "' not found." << endl;
        return;
    }
    (*file_ptr)->SNAPSHOT(message, time(0));
}

void FileSystem::ROLLBACK(const string& filename, int versionID) {
    File** file_ptr = files->get(filename);
    if (file_ptr == nullptr) {
        cerr << "Error: File '" << filename << "' not found." << endl;
        return;
    }
    if ((*file_ptr)->ROLLBACK(versionID)) {
        cout << "Active version for '" << filename << "' set to " << (*file_ptr)->ActiveVersionId() << "." << endl;
    } else {
        if (versionID == -1) {
            cerr << "Error: Cannot ROLLBACK from root version." << endl;
        } else {
            cerr << "Error: Version ID " << versionID << " not found for file '" << filename << "'." << endl;
        }
    }
}

void FileSystem::HISTORY(const string& filename) {
    File** file_ptr = files->get(filename);
    if (file_ptr == nullptr) {
        cerr << "Error: File '" << filename << "' not found." << endl;
        return;
    }
    (*file_ptr)->HISTORY();
}

void FileSystem::RECENT_FILES(int num) {
    MaxHeap<File*, ChangeT> temp_heap = *recentFiles;
    cout << "Most Recently Modified Files:" << endl;
    int count = 0;
    while (!temp_heap.isEmpty() && (num == -1 || count < num)) {
        File* file = temp_heap.extractMax();
        time_t mod_time = file->LastChangeT();
        tm* ptm = localtime(&mod_time);
        stringstream ss;
        ss << put_time(ptm, "%a %b %d %H:%M:%S %Y");
        cout << "  - " << file->getFilename() << " (Last modified: " << ss.str() << ")" << endl;
        count++;
    }
}

void FileSystem::BIGGEST_TREES(int num) {
    MaxHeap<File*, VersionCount> temp_heap = *biggestTree;
    cout << "Files with Most Versions:" << endl;
    int count = 0;
    while (!temp_heap.isEmpty() && (num == -1 || count < num)) {
        File* file = temp_heap.extractMax();
        cout << "  - " << file->getFilename() << " (" << file->TotalVersions() << " versions)" << endl;
        count++;
    }
}

