#ifndef AVLTREE_HPP
#define AVLTREE_HPP

#include <vector>
#include <algorithm>
#include <iostream>

// Represents a single post made by a user
struct Post {
    long long timestamp;
    std::string content;
};

// Node structure for the AVL Tree
struct AVLNode {
    long long key; // Timestamp for ordering
    Post data; // The Post object
    AVLNode* left;
    AVLNode* right;
    int height;
    AVLNode(long long k, Post val);
};

// AVL Tree class
class AVLTree {
private:
    AVLNode* root;
    
    // Helper functions
    int height(AVLNode* node);
    int getBalance(AVLNode* node);
    AVLNode* rightRotate(AVLNode* y);
    AVLNode* leftRotate(AVLNode* x);
    AVLNode* insert(AVLNode* node, long long key, Post data);
    void reverseInOrder(AVLNode* node, std::vector<Post>& result, int& count, int n);
    
public:
    AVLTree();
    
    // Public insert method
    void insert(Post data);
    
    // Public method to get posts in reverse chronological order
    std::vector<Post> getRecentPosts(int n);
};

#endif // AVLTREE_HPP
