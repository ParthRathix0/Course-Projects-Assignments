#ifndef HASHMAP_HPP
#define HASHMAP_HPP

#include <vector>
#include <string>

using namespace std;

template <typename K>
struct KeyHasher {
    size_t operator()(const K& key, int capacity) const {
        return static_cast<size_t>(key) % capacity;
    }
};

template <>
struct KeyHasher<string> {
    size_t operator()(const string& key, int capacity) const {
        size_t hash = 0;
        for (char c : key) {
            hash = hash * 31 + c;
        }
        return hash % capacity;
    }
};

template <typename K, typename V>
class HashMap {
private:
    struct HashNode {
        K key;
        V val; 
        HashNode* next;
        HashNode(K k, V v) : key(k), val(v), next(nullptr) {}
    };

    vector<HashNode*> buckets;
    int capacity;
    int num_elements; 
    KeyHasher<K> hasher;

    int hash(const K& key) const {
        return hasher(key, capacity);
    }

public:
    HashMap(int initial_capacity = 16) : capacity(initial_capacity), num_elements(0) {
        buckets.resize(capacity, nullptr);
    }

    ~HashMap() {
        for (int i = 0; i < capacity; ++i) {
            HashNode* entry = buckets[i];
            while (entry != nullptr) {
                HashNode* prev = entry;
                entry = entry->next;
                delete prev;
            }
        }
    }

    V* get(const K& key) const {
        int i = hash(key);
        HashNode* entry = buckets[i];
        while (entry != nullptr) {
            if (entry->key == key) {
                return &(entry->val);
            }
            entry = entry->next;
        }
        return nullptr;
    }
    
    void INSERT(const K& key, const V& val) {
        int i = hash(key);
        HashNode* head = buckets[i];
        HashNode* curr = head;
        while (curr != nullptr) {
            if (curr->key == key) {
                curr->val = val;
                return;
            }
            curr = curr->next;
        }
        HashNode* newNode = new HashNode(key, val);
        newNode->next = head;
        buckets[i] = newNode;
        num_elements++;
    }

    vector<V> allVal() const {
        vector<V> values;
        for (int i = 0; i < capacity; ++i) {
            HashNode* entry = buckets[i];
            while (entry != nullptr) {
                values.push_back(entry->val);
                entry = entry->next;
            }
        }
        return values;
    }
};

#endif
