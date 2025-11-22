#include "SocialNet.hpp"

using namespace std;

SocialNet::SocialNet() {}

string SocialNet::toLower(const string& str) {
    string lower_str = str;
    transform(lower_str.begin(), lower_str.end(), lower_str.begin(), [](unsigned char c){ return std::tolower(c); });
    return lower_str;
}

void SocialNet::ADD_USER(const vector<string>& args) {
    if (args.size() != 1) {
        cout << "Error: Invalid syntax for ADD USER." << endl;
        return;
    }

    // Store both original case and lowercase versions
    string original_username = args[0];
    string lower_username = toLower(original_username);

    // Graph now stores both versions for better design
    if (networkGraph.addUser(lower_username, original_username) != -1) {
        User newUser;
        newUser.username = original_username;  // Store original for display
        
        int userId = networkGraph.getUserId(lower_username);
        if (static_cast<size_t>(userId) >= users.size()) {
            users.resize(userId + 1);
        }
        users[userId] = newUser;

        cout << "User " << original_username << " added." << endl;
    } 
    else {
        cout << "Error: User " << original_username << " already exists." << endl;
    }
}

void SocialNet::ADD_FRIEND(const vector<string>& args) {
    if (args.size() != 2) {
        cout << "Error: Invalid syntax for ADD FRIEND." << endl;
        return;
    }

    string user1 = toLower(args[0]);
    string user2 = toLower(args[1]);
    int id1 = networkGraph.getUserId(user1);
    int id2 = networkGraph.getUserId(user2);

    if (id1 == -1 || id2 == -1) {
        cout << "Error: One or both users do not exist." << endl;
        return;
    }

    if (id1 == id2) {
        cout << "Error: Cannot add yourself as a friend." << endl;
        return;
    }

    if (networkGraph.addFriend(id1, id2)) {
        cout << "Friendship added between " << args[0] << " and " << args[1] << "." << endl;
    } 
    else {
        cout << "Error: Friendship already exists." << endl;
    }
}

void SocialNet::LIST_FRIENDS(const vector<string>& args) {
    if (args.size() != 1) {
        cout << "Error: Invalid syntax for LIST FRIENDS." << endl;
        return;
    }

    string user = toLower(args[0]);
    int userId = networkGraph.getUserId(user);

    if (userId == -1) {
        cout << "Error: User " << args[0] << " does not exist." << endl;
        return;
    }

    const vector<int>& friends = networkGraph.getFriends(userId);
    
    if (friends.empty()) {
        cout << args[0] << " has no friends." << endl;
        return;
    }

    vector<string> friendNames;
    for (int friendId : friends) {
        string friendName = networkGraph.getUsername(friendId);
        if (!friendName.empty()) {
            friendNames.push_back(friendName);
        }
    }

    sort(friendNames.begin(), friendNames.end());

    cout << "Friends of " << args[0] << ":" << endl;
    for (const string& name : friendNames) {
        cout << name << endl;
    }
}

void SocialNet::SUGGEST_FRIENDS(const vector<string>& args) {
    if (args.size() != 2) {
        cout << "Error: Invalid syntax for SUGGEST FRIENDS." << endl;
        return;
    }

    string user = toLower(args[0]);
    int userId = networkGraph.getUserId(user);

    if (userId == -1) {
        cout << "Error: User " << args[0] << " does not exist." << endl;
        return;
    }

    // Handle number parsing with specific exception types
    int n = 0;
    try {
        n = stoi(args[1]);
    } catch (const invalid_argument&) {
        cout << "Error: Invalid number argument for SUGGEST FRIENDS." << endl;
        return;
    } catch (const out_of_range&) {
        cout << "Error: Number out of range for SUGGEST FRIENDS." << endl;
        return;
    }

    if (n <= 0) {
        cout << "Error: N must be a positive number." << endl;
        return;
    }

    // Map to store mutual friend counts
    unordered_map<int, int> mutuals;
    const vector<int>& myFriends = networkGraph.getFriends(userId);
    unordered_set<int> myFriendsSet(myFriends.begin(), myFriends.end());
    myFriendsSet.insert(userId);  // Don't suggest myself

    for (int friendId : myFriends) {
        const vector<int>& friendsOfFriend = networkGraph.getFriends(friendId);
        for (int fofId : friendsOfFriend) {
            if (myFriendsSet.find(fofId) == myFriendsSet.end()) {
                mutuals[fofId]++;
            }
        }
    }

    if (mutuals.empty()) {
        cout << "No friend suggestions for " << args[0] << "." << endl;
        return;
    }

    vector<pair<int, int>> suggestions(mutuals.begin(), mutuals.end());
    sort(suggestions.begin(), suggestions.end(), [](const pair<int, int>& a, const pair<int, int>& b) {
        if (a.second != b.second) {
            return a.second > b.second;  // Sort by mutual count (descending)
        }
        return a.first < b.first;  // Tie-break by user ID (ascending)
    });

    cout << "Friend suggestions for " << args[0] << ":" << endl;
    int count = 0;
    for (const auto& suggestion : suggestions) {
        if (count >= n) break;
        
        string name = networkGraph.getUsername(suggestion.first);
        if (!name.empty()) {
            cout << name << " (Mutual friends: " << suggestion.second << ")" << endl;
            count++;
        }
    }
}

void SocialNet::DEGREES_OF_SEPARATION(const vector<string>& args) {
    if (args.size() != 2) {
        cout << "Error: Invalid syntax for DEGREES OF SEPARATION." << endl;
        return;
    }

    string user1 = toLower(args[0]);
    string user2 = toLower(args[1]);
    int id1 = networkGraph.getUserId(user1);
    int id2 = networkGraph.getUserId(user2);

    if (id1 == -1 || id2 == -1) {
        cout << "Error: One or both users do not exist." << endl;
        return;
    }

    if (id1 == id2) {
        cout << "Degrees of separation: 0" << endl;
        return;
    }

    // BFS using pair to store both userId and distance
    Queue<pair<int, int>> q;
    q.push({id1, 0});
    vector<bool> visited(networkGraph.getNumUsers(), false);
    visited[id1] = true;

    while (!q.empty()) {
        pair<int, int> current = q.front();
        q.pop();
        int u = current.first;
        int dist = current.second;

        const vector<int>& friends = networkGraph.getFriends(u);
        for (int v : friends) {
            if (v == id2) {
                cout << "Degrees of separation: " << dist + 1 << endl;
                return;
            }
            if (!visited[v]) {
                visited[v] = true;
                q.push({v, dist + 1});
            }
        }
    }

    cout << "Degrees of separation: -1 (No path found)" << endl;
}

void SocialNet::ADD_POST(const string& username, const string& content) {
    string lower_username = toLower(username);
    int userId = networkGraph.getUserId(lower_username);

    if (userId == -1) {
        cout << "Error: User " << username << " does not exist." << endl;
        return;
    }

    auto now = std::chrono::high_resolution_clock::now();
    long long timestamp = now.time_since_epoch().count();

    // Posts are case-insensitive as per specification
    Post newPost = {timestamp, toLower(content)};

    if (static_cast<size_t>(userId) >= users.size() || users[userId].username.empty()) {
        cout << "Error: Internal data mismatch for user " << username << "." << endl;
        return;
    }

    users[userId].posts.insert(newPost);
    cout << "Post added by " << username << "." << endl;
}

void SocialNet::OUTPUT_POSTS(const vector<string>& args) {
    if (args.size() != 2) {
        cout << "Error: Invalid syntax for OUTPUT POSTS." << endl;
        return;
    }

    string user = toLower(args[0]);
    int userId = networkGraph.getUserId(user);

    if (userId == -1) {
        cout << "Error: User " << args[0] << " does not exist." << endl;
        return;
    }

    int n = 0;
    try {
        n = stoi(args[1]);
    } catch (const invalid_argument&) {
        cout << "Error: Invalid number argument for OUTPUT POSTS." << endl;
        return;
    } catch (const out_of_range&) {
        cout << "Error: Number out of range for OUTPUT POSTS." << endl;
        return;
    }

    if (static_cast<size_t>(userId) >= users.size() || users[userId].username.empty()) {
        cout << "Error: Internal data mismatch for user " << args[0] << "." << endl;
        return;
    }

    vector<Post> posts = users[userId].posts.getRecentPosts(n);

    if (posts.empty()) {
        cout << "No posts by " << args[0] << "." << endl;
        return;
    }

    cout << "Posts by " << args[0] << ":" << endl;
    for (const auto& post : posts) {
        cout << post.content << endl;
    }
}

void SocialNet::executeCommand(const string& commandLine) {
    try {
        stringstream ss(commandLine);
        string command;
        ss >> command;

        vector<string> args;
        string arg;

        if (command == "ADD_USER") {
            ss >> arg;
            args.push_back(arg);
            ADD_USER(args);
        }
        else if (command == "ADD_FRIEND") {
            ss >> arg;
            args.push_back(arg);
            ss >> arg;
            args.push_back(arg);
            ADD_FRIEND(args);
        }
        else if (command == "LIST_FRIENDS") {
            ss >> arg;
            args.push_back(arg);
            LIST_FRIENDS(args);
        }
        else if (command == "SUGGEST_FRIENDS") {
            ss >> arg;
            args.push_back(arg);
            ss >> arg;
            args.push_back(arg);
            SUGGEST_FRIENDS(args);
        }
        else if (command == "DEGREES_OF_SEPARATION") {
            ss >> arg;
            args.push_back(arg);
            ss >> arg;
            args.push_back(arg);
            DEGREES_OF_SEPARATION(args);
        }
        else if (command == "ADD_POST") {
            string username;
            ss >> username;
            size_t first_quote = commandLine.find('\"');
            size_t last_quote = commandLine.rfind('\"');
            
            if (first_quote != string::npos && last_quote != string::npos && first_quote < last_quote) {
                string content = commandLine.substr(first_quote + 1, last_quote - first_quote - 1);
                ADD_POST(username, content);
            } else {
                cout << "Error: Invalid syntax for ADD POST. Content must be in quotes." << endl;
            }
        }
        else if (command == "OUTPUT_POSTS") {
            ss >> arg;
            args.push_back(arg);
            ss >> arg;
            args.push_back(arg);
            OUTPUT_POSTS(args);
        }
        else {
            cout << "Error: Unknown command." << endl;
        }
    }
    catch (const exception& e) {
        // Catch any unexpected exceptions to prevent program termination
        cout << "Error: " << e.what() << endl;
    }
}
