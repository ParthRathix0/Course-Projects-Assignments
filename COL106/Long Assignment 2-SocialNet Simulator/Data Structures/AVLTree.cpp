#include "AVLTree.hpp"

using namespace std;

// AVLNode Constructor
AVLNode::AVLNode(long long k, Post val) : key(k), data(val), left(nullptr), right(nullptr), height(1) {}

// AVLTree Constructor
AVLTree::AVLTree() : root(nullptr) {}

// Helper function to get the height of a node
int AVLTree::height(AVLNode* node) {
    if (node == nullptr)
        return 0;
    return node->height;
}

// Helper function to get the balance factor of a node
int AVLTree::getBalance(AVLNode* node) {
    if (node == nullptr)
        return 0;
    return height(node->left) - height(node->right);
}

// Right rotation
AVLNode* AVLTree::rightRotate(AVLNode* y) {
    AVLNode* x = y->left;
    AVLNode* T2 = x->right;
    x->right = y;
    y->left = T2;
    y->height = max(height(y->left), height(y->right)) + 1;
    x->height = max(height(x->left), height(x->right)) + 1;
    return x;
}

// Left rotation
AVLNode* AVLTree::leftRotate(AVLNode* x) {
    AVLNode* y = x->right;
    AVLNode* T2 = y->left;
    y->left = x;
    x->right = T2;
    x->height = max(height(x->left), height(x->right)) + 1;
    y->height = max(height(y->left), height(y->right)) + 1;
    return y;
}

// Recursive insert function
AVLNode* AVLTree::insert(AVLNode* node, long long key, Post data) {
    if (node == nullptr)
        return (new AVLNode(key, data));
    
    if (key < node->key)
        node->left = insert(node->left, key, data);
    else if (key > node->key)
        node->right = insert(node->right, key, data);
    else // key == node->key - duplicate, do not insert
        return node;
    
    node->height = 1 + max(height(node->left), height(node->right));
    int balance = getBalance(node);
    
    // Left Left Case
    if (balance > 1 && key < node->left->key)
        return rightRotate(node);
    
    // Right Right Case
    if (balance < -1 && key > node->right->key)
        return leftRotate(node);
    
    // Left Right Case
    if (balance > 1 && key > node->left->key) {
        node->left = leftRotate(node->left);
        return rightRotate(node);
    }
    
    // Right Left Case
    if (balance < -1 && key < node->right->key) {
        node->right = rightRotate(node->right);
        return leftRotate(node);
    }
    
    return node;
}

// Recursive helper for reverse in-order traversal
void AVLTree::reverseInOrder(AVLNode* node, vector<Post>& result, int& count, int n) {
    if (node == nullptr)
        return;
    
    // Check if we've reached the limit BEFORE processing
    if (n != -1 && count >= n)
        return;
    
    // Traverse right subtree first for descending order
    reverseInOrder(node->right, result, count, n);
    
    // Add current node only if we haven't reached the limit
    if (n == -1 || count < n) {
        result.push_back(node->data);
        count++;
    }
    
    // Then traverse left subtree
    reverseInOrder(node->left, result, count, n);
}

// Public insert method
void AVLTree::insert(Post data) {
    root = insert(root, data.timestamp, data);
}

// Public method to get posts in reverse chronological order
vector<Post> AVLTree::getRecentPosts(int n) {
    vector<Post> result;
    int count = 0;
    reverseInOrder(root, result, count, n);
    return result;
}
