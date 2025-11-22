#ifndef TREENODE_HPP
#define TREENODE_HPP

#include <string>
#include <vector>
#include <ctime> 

using namespace std;

class TreeNode {
public:
    int version_id;
    string content;
    string message;
    time_t created_timestamp;
    time_t snapshot_timestamp;
    TreeNode* parent;
    vector<TreeNode*> children;

    TreeNode(int id, string initial_content, time_t creation_time, TreeNode* p = nullptr)
        : version_id(id), content(initial_content), message(""),
          created_timestamp(creation_time), snapshot_timestamp(0),
          parent(p) {}

    ~TreeNode() {
        for (TreeNode* child : children) {
            delete child;
        }
    }
};

#endif 
