#ifndef GRAPH_HPP
#define GRAPH_HPP

#include <vector>
#include <unordered_map>
#include <string>
#include <algorithm>

class Graph {
private:
    std::vector<std::vector<int>> adjList;  // Adjacency list
    std::unordered_map<std::string, int> username_to_id;  // Lowercase -> ID
    std::vector<std::string> id_to_username;  // ID -> Original cased username
    int next_id;

public:
    Graph();
    bool userExists(const std::string& username) const;
    int getUserId(const std::string& username) const;
    std::string getUsername(int id) const;
    
    // Modified to accept both lowercase and original versions
    int addUser(const std::string& lowercase_username, const std::string& original_username);
    
    bool addFriend(int userId1, int userId2);
    const std::vector<int>& getFriends(int userId) const;
    int getNumUsers() const;
};

#endif // GRAPH_HPP