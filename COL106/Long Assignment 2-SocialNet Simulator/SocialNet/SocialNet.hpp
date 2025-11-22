#ifndef SOCIALNET_HPP
#define SOCIALNET_HPP

#include <iostream>
#include <vector>
#include <string>
#include <algorithm>
#include <sstream>
#include <unordered_map>
#include <unordered_set>
#include <chrono>  

#include "../Data Structures/Graph.hpp"
#include "../Data Structures/AVLTree.hpp"
#include "../Data Structures/Queue.hpp"

// Represents a user in the social network
struct User {
    std::string username;
    AVLTree posts;
};

class SocialNet {
private:
    Graph networkGraph;
    std::vector<User> users;
    
    // Helper to normalize strings to lowercase
    std::string toLower(const std::string& str);

public:
    SocialNet();
    void executeCommand(const std::string& commandLine);

private:
    // Command execution methods
    void ADD_USER(const std::vector<std::string>& args);
    void ADD_FRIEND(const std::vector<std::string>& args);
    void LIST_FRIENDS(const std::vector<std::string>& args);
    void SUGGEST_FRIENDS(const std::vector<std::string>& args);
    void DEGREES_OF_SEPARATION(const std::vector<std::string>& args);
    void ADD_POST(const std::string& username, const std::string& content);
    void OUTPUT_POSTS(const std::vector<std::string>& args);
};

#endif // SOCIALNET_HPP
