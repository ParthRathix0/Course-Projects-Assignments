#ifndef FILESYSTEM_HPP
#define FILESYSTEM_HPP

#include "File.hpp"
#include "../DataStructures/MaxHeap.hpp"
#include "../DataStructures/HashMap.hpp"
#include <string>

using namespace std;

class File;

struct ChangeT {
    bool operator()(const File* a, const File* b) const {
        return a->LastChangeT() < b->LastChangeT();
    }
};

struct VersionCount {
    bool operator()(const File* a, const File* b) const {
        return a->TotalVersions() < b->TotalVersions();
    }
};

class FileSystem {
private:
    HashMap<string, File*>* files;
    MaxHeap<File*, ChangeT>* recentFiles;
    MaxHeap<File*, VersionCount>* biggestTree;
    unsigned long long system_clock;

    void rebuildHeaps();

public:
    FileSystem();
    ~FileSystem();

    void CREATE(const string& filename);
    void READ(const string& filename);
    void INSERT(const string& filename, const string& content);
    void UPDATE(const string& filename, const string& content);
    void SNAPSHOT(const string& filename, const string& message);
    void ROLLBACK(const string& filename, int versionID = -1);
    void HISTORY(const string& filename);
    void RECENT_FILES(int num);
    void BIGGEST_TREES(int num);
};

#endif 
