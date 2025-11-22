#include "Graph.hpp"

using namespace std;

Graph::Graph() : next_id(0) {}

bool Graph::userExists(const string& username) const {
    return username_to_id.count(username) > 0;
}

int Graph::getUserId(const string& username) const {
    if (userExists(username)) {
        return username_to_id.at(username);
    }
    return -1;
}

string Graph::getUsername(int id) const {
    if (id >= 0 && static_cast<size_t>(id) < id_to_username.size()) {
        return id_to_username[id];
    }
    return "";
}

// Modified to accept both lowercase and original versions
int Graph::addUser(const string& lowercase_username, const string& original_username) {
    if (userExists(lowercase_username)) {
        return -1;  // User already exists
    }

    username_to_id[lowercase_username] = next_id;
    id_to_username.push_back(original_username);  // Store original casing
    adjList.emplace_back();
    return next_id++;
}

bool Graph::addFriend(int userId1, int userId2) {
    if (userId1 < 0 || userId1 >= getNumUsers() ||
        userId2 < 0 || userId2 >= getNumUsers()) {
        return false;
    }

    if (userId1 == userId2) {
        return false;  // Can't befriend yourself
    }

    // Check if already friends
    auto& friends1 = adjList[userId1];
    if (find(friends1.begin(), friends1.end(), userId2) != friends1.end()) {
        return false;
    }

    // Add bidirectional friendship
    adjList[userId1].push_back(userId2);
    adjList[userId2].push_back(userId1);
    return true;
}

const vector<int>& Graph::getFriends(int userId) const {
    return adjList[userId];
}

int Graph::getNumUsers() const {
    return next_id;
}