#ifndef QUEUE_HPP
#define QUEUE_HPP

template <typename T>
struct QueueNode {
    T data;
    QueueNode* next;
    QueueNode(T d) : data(d), next(nullptr) {}
};

template <typename T>
class Queue {
private:
    QueueNode<T>* head; // Front
    QueueNode<T>* tail; // Rear

public:
    Queue() : head(nullptr), tail(nullptr) {}
    
    ~Queue() {
        while (!empty()) {
            pop();
        }
    }
    
    bool empty() {
        return head == nullptr;
    }
    
    void push(T data) { // Enqueue
        QueueNode<T>* newNode = new QueueNode<T>(data);
        if (empty()) {
            head = tail = newNode;
        } else {
            tail->next = newNode;
            tail = newNode;
        }
    }
    
    void pop() { // Dequeue
        if (empty()) {
            return;
        }
        
        QueueNode<T>* temp = head;
        head = head->next;
        if (head == nullptr) {
            tail = nullptr;
        }
        
        delete temp;
    }
    
    T front() {
        if (empty()) {
            return T();
        }
        
        return head->data;
    }
};

#endif // QUEUE_HPP
