# Time-Travelling File System

This project is a simplified, in-memory version control system inspired by Git. It's designed to manage versioned files with support for branching and historical inspection, utilizing custom-built **Tree**, **HashMap**, and **MaxHeap** data structures.

---

## How to Compile and Run

To compile and run this project, you'll need a C++ compiler that supports the **C++17** standard, such as the GNU C++ Compiler (`g++`).

1.  **Compile the program:** Open your terminal in the project's root directory and run the compile script:

    ```sh
    sh compile.sh
    ```

    This will generate an executable file named `filesystem`.

2.  **Run the program:** Execute the compiled program to start the interactive file system shell:

    ```sh
    ./filesystem
    ```

You can now enter commands directly into the terminal.

---

## Features

* **File Management:** Create, read, and modify file content.
* **Versioning:** Save immutable snapshots of file versions.
* **Branching & History:** Create different development branches by rolling back to an older version and making new edits.
* **Time-Travel:** Navigate through a file's version history, view past content, and revert to any previous state.
* **System Analytics:** Track system-wide metrics, such as the most recently modified files and files with the most versions.

---

## Command Reference

The file system operates via a set of simple commands entered at the interactive prompt.

| Command                               | Description                                                                                                                              |
| :------------------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------- |
| `CREATE <filename>`                   | Creates a new file with an empty initial version (version 0).                                                                            |
| `READ <filename>`                     | Displays the content of the file's currently active version.                                                                             |
| `INSERT <filename> <content>`         | Appends `<content>` to the active version. Creates a new version if the current one is a snapshot.                                       |
| `UPDATE <filename> <content>`         | Replaces the active version's content with `<content>`. Creates a new version if the current one is a snapshot.                          |
| `SNAPSHOT <filename> <message>`       | Marks the active version as an immutable snapshot with the given `<message>`.                                                            |
| `ROLLBACK <filename> [versionID]`     | Sets the active version to the specified `versionID`. If no ID is provided, it rolls back to the parent of the current version.         |
| `HISTORY <filename>`                  | Lists all snapshotted versions on the path from the active version to the root, showing their ID, timestamp, and message.                |
| `RECENT_FILES [num]`                  | Lists the `num` most recently modified files. If `num` is omitted, it lists all files.                                                   |
| `BIGGEST_TREES [num]`                 | Lists the `num` files with the highest number of versions. If `num` is omitted, it lists all files.                                      |

**Note on Arguments:** For `INSERT`, `UPDATE`, and `SNAPSHOT` commands, multi-word content or messages that include spaces should be enclosed in double quotes (`"`), for example: `SNAPSHOT myfile.txt "This is the first stable version"`.

---

## Error Handling

The system provides user-friendly error messages for common issues, including:

* Attempting to create a file that already exists.
* Operating on a file that does not exist.
* Trying to roll back to a non-existent version ID.
* Attempting to roll back from the root version (which has no parent).
