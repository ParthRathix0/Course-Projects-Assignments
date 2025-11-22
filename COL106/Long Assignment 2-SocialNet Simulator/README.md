# SocialNet Simulator

## Overview

**SocialNet Simulator** is a command-line application that simulates a social network's backend services. The system manages users, friendships, and user-generated posts using custom implementations of **Graphs** and **AVL Trees**.

This project demonstrates practical applications of core data structures in solving real-world problems.

---

## System Architecture

### Core Data Structures (Custom Implementations)

The system utilizes two fundamental data structures, both implemented from scratch:

#### 1. **Graph** (`Data Structures/Graph.hpp` & `Graph.cpp`)
- **Purpose:** Represents the social network structure
- **Structure:** Adjacency list with unordered_map for O(1) username-to-ID lookups
- **Vertices:** Each user is a vertex in the undirected graph
- **Edges:** Bidirectional friendships between users
- **Key Methods:**
  - `addUser()`: Register a new user
  - `addFriend()`: Establish bidirectional friendship
  - `getFriends()`: Retrieve list of friends for a user
  - `userExists()`: Check if a user exists

#### 2. **AVL Tree** (`Data Structures/AVLTree.hpp` & `AVLTree.cpp`)
- **Purpose:** Store and manage posts for each user
- **Ordering:** Posts sorted by timestamp (key)
- **Balance:** Self-balancing to maintain O(log n) operations
- **Features:**
  - Automatic height balancing with rotations (left, right, left-right, right-left)
  - Supports insertion of new posts
  - Efficient retrieval of recent posts in reverse chronological order
- **Key Methods:**
  - `insert()`: Add a new timestamped post
  - `getRecentPosts()`: Retrieve N most recent posts

#### 3. **Queue** (`Data Structures/Queue.hpp`)
- **Purpose:** Breadth-First Search (BFS) for shortest path finding
- **Implementation:** Linked-list based queue for DEGREES_OF_SEPARATION command

### Additional Data Structures

- **Unordered HashMap:** C++ STL `unordered_map` for mapping usernames to graph vertex IDs (O(1) lookup)
- **Vector:** Dynamic arrays for storing users and adjacency lists

---

## File Structure

```
SOCIALNET-SIMU/
├── Data Structures/
│   ├── AVLTree.hpp          # AVL Tree header
│   ├── AVLTree.cpp          # AVL Tree implementation
│   ├── Graph.hpp            # Graph header
│   ├── Graph.cpp            # Graph implementation
│   └── Queue.hpp            # Queue implementation
│
├── SocialNet/
│   ├── SocialNet.hpp        # Main SocialNet system header
│   └── Socialnet.cpp        # Command handling and core logic
│
├── Main.cpp                 # Entry point
├── compile.sh               # Compilation script
├── README.md                # This file
└── LICENSE                  # License information
```

---

## Installation & Compilation

### Prerequisites

- **C++ Compiler:** g++ (version 11 or later recommended)
- **Build Tool:** bash (for running compilation script)
- **OS:** Linux/macOS (or Windows with WSL/MinGW)

### Steps to Compile

1. **Navigate to project directory:**
   ```bash
   cd SOCIALNET-SIMULATOR
   ```

2. **Make compilation script executable:**
   ```bash
   sh compile.sh
   ```

3. **Compile the project:**
   ```bash
   ./compile.sh
   ```

4. **Expected output:**
   - Generates executable: `socialnet`
   - No errors or warnings (clean compilation)

### Manual Compilation

If `compile.sh` doesn't work, compile manually:

```bash
g++ -std=c++17 -o socialnet \
    Data\ Structures/Graph.cpp \
    Data\ Structures/AVLTree.cpp \
    SocialNet/Socialnet.cpp \
    Main.cpp
```

---

## Running the Application

### Start the Simulator

```bash
./socialnet
```

The application enters interactive command mode and reads commands from standard input (stdin).

### Interactive Mode

- **Input Method:** Type commands and press Enter
- **Output Method:** Results displayed to standard output (stdout)
- **Exit:** Press `Ctrl+D` (EOF) or `Ctrl+C`

---

## Command Reference

### User Management Commands

#### 1. **ADD_USER**
**Create a new user in the social network**

```
ADD_USER <username>
```

- **Parameters:**
  - `<username>`: Name of the user to create (case-insensitive, stored as lowercase)
- **Output:** Success or error message
- **Example:**
  ```
  ADD_USER alice
  ADD_USER Bob
  ```
- **Error Cases:**
  - User already exists
  - Invalid syntax

---

#### 2. **ADD_FRIEND**
**Establish bidirectional friendship between two users**

```
ADD_FRIEND <username1> <username2>
```

- **Parameters:**
  - `<username1>`: First user (case-insensitive)
  - `<username2>`: Second user (case-insensitive)
- **Constraints:**
  - Both users must exist
  - Friendship is bidirectional
  - User cannot befriend themselves
  - Duplicate friendships not allowed
- **Output:** Success or error message
- **Example:**
  ```
  ADD_FRIEND alice bob
  ADD_FRIEND Alice BOB
  ```

---

#### 3. **LIST_FRIENDS**
**Display all friends of a user in alphabetical order**

```
LIST_FRIENDS <username>
```

- **Parameters:**
  - `<username>`: User whose friends to list (case-insensitive)
- **Output:** Friends listed alphabetically (one per line), or "No friends" if list is empty
- **Example:**
  ```
  LIST_FRIENDS alice
  ```
- **Output Example:**
  ```
  bob
  charlie
  diana
  ```

---

#### 4. **SUGGEST_FRIENDS**
**Recommend up to N potential friends based on mutual connections**

```
SUGGEST_FRIENDS <username> <N>
```

- **Parameters:**
  - `<username>`: User to generate suggestions for (case-insensitive)
  - `<N>`: Maximum number of suggestions (integer)
- **Algorithm:**
  - Find "friends of friends" not already connected to the user
  - Rank by number of mutual friends (descending)
  - Break ties alphabetically
  - Return top N suggestions
- **Output:** Suggested usernames or "No suggestions" if unavailable
- **Example:**
  ```
  SUGGEST_FRIENDS alice 3
  ```
- **Output Example:**
  ```
  diana (2 mutual friends)
  eve (1 mutual friend)
  ```

---

#### 5. **DEGREES_OF_SEPARATION**
**Find shortest friendship path between two users**

```
DEGREES_OF_SEPARATION <username1> <username2>
```

- **Parameters:**
  - `<username1>`: First user (case-insensitive)
  - `<username2>`: Second user (case-insensitive)
- **Algorithm:** Breadth-First Search (BFS) on the friendship graph
- **Output:** 
  - Integer: Length of shortest path (0 if same user, 1 if direct friends)
  - -1: If no path exists (unreachable users)
- **Example:**
  ```
  DEGREES_OF_SEPARATION alice bob
  ```
- **Output Example:**
  ```
  2
  ```

---

### Post Management Commands

#### 6. **ADD_POST**
**Create and publish a new post for a user**

```
ADD_POST <username> "<post_content>"
```

- **Parameters:**
  - `<username>`: User publishing the post (case-insensitive)
  - `<post_content>`: Post text enclosed in double quotes (case-insensitive)
- **Timestamp:** Automatically assigned using system clock
- **Storage:** Posts stored in user's AVL Tree, indexed by timestamp
- **Output:** Confirmation message or error
- **Example:**
  ```
  ADD_POST alice "Hello, this is my first post!"
  ADD_POST bob "What a great day!"
  ```
- **Note:** Post content is stored as-is (with quotes in command); quotes are not part of stored content

---

#### 7. **OUTPUT_POSTS**
**Display recent posts from a user**

```
OUTPUT_POSTS <username> <N>
```

- **Parameters:**
  - `<username>`: User whose posts to retrieve (case-insensitive)
  - `<N>`: Number of recent posts to display
    - Positive integer: Show N most recent posts
    - `-1`: Show all posts
- **Output Format:**
  - Posts in **reverse chronological order** (newest first)
  - One post per line
  - Shows: Timestamp and content
- **Output Example:**
  ```
  OUTPUT_POSTS alice 2
  ```
  **Output:**
  ```
  Hello, this is my first post!
  My day was great!
  ```

---

## Usage Example

### Complete Workflow

```bash
./socialnet
```

**Input:**
```
ADD_USER alice
ADD_USER bob
ADD_USER charlie
ADD_FRIEND alice bob
ADD_FRIEND bob charlie
LIST_FRIENDS alice
ADD_POST alice "My first post!"
ADD_POST alice "Second post here!"
OUTPUT_POSTS alice -1
SUGGEST_FRIENDS alice 2
DEGREES_OF_SEPARATION alice charlie
```

**Output:**
```
User alice added.
User bob added.
User charlie added.
Friendship added between alice and bob.
Friendship added between bob and charlie.
bob
Post added successfully.
Post added successfully.
Second post here!
My first post!
charlie (1 mutual friend)
2
```

---

## Implementation Details

### Case Sensitivity
- **Usernames:** Normalized to lowercase for storage and comparison
- **Commands:** Case-insensitive (parsed as uppercase internally)
- **Post Content:** Stored as-is but displayed with original case

### Time Complexity Analysis

| Operation | Complexity | Implementation |
|-----------|------------|-----------------|
| Add User | O(1) | Hash table insertion |
| Add Friend | O(log n) | Adjacency list update |
| List Friends | O(k log k) | k = # friends, sort operation |
| Suggest Friends | O(n + k log k) | n = total users, BFS + sort |
| Degrees of Separation | O(n + e) | BFS traversal (n vertices, e edges) |
| Add Post | O(log m) | m = # posts, AVL insertion |
| Output Posts | O(m) | In-order traversal of AVL tree |

### Space Complexity
- **Graph:** O(n + e) where n = users, e = edges
- **Posts:** O(m) where m = total posts across all users
- **Overall:** O(n + e + m)

---

## Important Notes

### Data Structure Requirements
- **Graph Implementation:** Custom adjacency list (no STL graph libraries)
- **AVL Tree Implementation:** Custom self-balancing BST (no STL tree containers)
- **Queue Implementation:** Custom linked-list based queue (for BFS)
- **HashMap Usage:** C++ STL `unordered_map` allowed for username mapping only

### Limitations & Assumptions
1. **Usernames:** Must be single words (no spaces)
2. **Post Content:** Enclosed in double quotes; no newlines within posts
3. **Integer Parameters:** Treated as decimal integers
4. **User Limit:** Limited only by available system memory
5. **Timestamps:** Generated using `clock()` function (may vary by system)

### Error Handling
- Invalid usernames (non-existent users)
- Duplicate operations (adding existing friends, duplicate users)
- Malformed commands (incorrect syntax)
- Out-of-range parameters

All errors produce descriptive console messages without program termination.

---

