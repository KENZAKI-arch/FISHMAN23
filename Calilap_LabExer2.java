import java.util.Scanner;

class Node {
    String songTitle;
    Node next;

    public Node(String songTitle) {
        this.songTitle = songTitle;
        this.next = null;
    }
}

public class Calilap_LabExer2 {
    private Node head;

    // 1. Add song at beginning
    public void addAtBeginning(String song) {
        Node newNode = new Node(song);
        newNode.next = head;
        head = newNode;
        System.out.println("Song added at beginning.");
    }

    // 2. Add song at end
    public void addAtEnd(String song) {
        Node newNode = new Node(song);
        if (head == null) {
            head = newNode;
        } else {
            Node temp = head;
            while (temp.next != null) {
                temp = temp.next;
            }
            temp.next = newNode;
        }
        System.out.println("Song added at end.");
    }

    // 3. Insert song after another song
    public void insertAfter(String newSong, String afterSong) {
        Node temp = head;
        while (temp != null && !temp.songTitle.equalsIgnoreCase(afterSong)) {
            temp = temp.next;
        }
        if (temp != null) {
            Node newNode = new Node(newSong);
            newNode.next = temp.next;
            temp.next = newNode;
            System.out.println("Song inserted.");
        } else {
            System.out.println("Song not found.");
        }
    }

    // 4. Search Song
    public void searchSong(String song) {
        Node temp = head;
        int pos = 1;
        while (temp != null) {
            if (temp.songTitle.equalsIgnoreCase(song)) {
                System.out.println("Song found at position " + pos);
                return;
            }
            temp = temp.next;
            pos++;
        }
        System.out.println("Song not found.");
    }

    // 5. Delete first song
    public void deleteFirst() {
        if (head == null) {
            System.out.println("Playlist is empty.");
        } else {
            head = head.next;
            System.out.println("First song deleted.");
        }
    }

    // 6. Delete last song
    public void deleteLast() {
        if (head == null) {
            System.out.println("Playlist is empty.");
        } else if (head.next == null) {
            head = null;
            System.out.println("Last song deleted.");
        } else {
            Node temp = head;
            while (temp.next.next != null) {
                temp = temp.next;
            }
            temp.next = null;
            System.out.println("Last song deleted.");
        }
    }

    // 7. Delete a selected song
    public void deleteSelected(String song) {
        if (head == null) {
            System.out.println("Playlist is empty.");
            return;
        }
        if (head.songTitle.equalsIgnoreCase(song)) {
            head = head.next;
            System.out.println("Song deleted.");
            return;
        }
        Node temp = head;
        while (temp.next != null && !temp.next.songTitle.equalsIgnoreCase(song)) {
            temp = temp.next;
        }
        if (temp.next != null) {
            temp.next = temp.next.next;
            System.out.println("Song deleted.");
        } else {
            System.out.println("Song not found.");
        }
    }

    // 8. Display playlist
    public void displayPlaylist() {
        if (head == null) {
            System.out.println("Playlist is empty.");
            return;
        }
        Node temp = head;
        System.out.println("\n--- Playlist ---");
        int count = 1;
        while (temp != null) {
            System.out.println(count + ". " + temp.songTitle);
            temp = temp.next;
            count++;
        }
        System.out.println("----------------\n");
    }

    public static void main(String[] args) {
        Calilap_LabExer2 playlist = new Calilap_LabExer2();
        Scanner scanner = new Scanner(System.in);
        int choice;

        do {
            System.out.println("======================================");
            System.out.println("       MUSIC PLAYLIST MANAGER         ");
            System.out.println("======================================");
            System.out.println("1. Add Song at Beginning");
            System.out.println("2. Add Song at End");
            System.out.println("3. Insert Song After Another Song");
            System.out.println("4. Search Song");
            System.out.println("5. Delete First Song");
            System.out.println("6. Delete Last Song");
            System.out.println("7. Delete Selected Song");
            System.out.println("8. Display Playlist");
            System.out.println("9. Exit");
            System.out.print("Enter your choice: ");
            
            while (!scanner.hasNextInt()) {
                System.out.println("Invalid input. Please enter a number.");
                scanner.next();
                System.out.print("Enter your choice: ");
            }
            choice = scanner.nextInt();
            scanner.nextLine(); // consume newline

            switch (choice) {
                case 1:
                    System.out.print("Enter song title: ");
                    playlist.addAtBeginning(scanner.nextLine());
                    break;
                case 2:
                    System.out.print("Enter song title: ");
                    playlist.addAtEnd(scanner.nextLine());
                    break;
                case 3:
                    System.out.print("Enter new song title: ");
                    String newSong = scanner.nextLine();
                    System.out.print("Enter song to insert after: ");
                    String afterSong = scanner.nextLine();
                    playlist.insertAfter(newSong, afterSong);
                    break;
                case 4:
                    System.out.print("Enter Song Title to Search: ");
                    playlist.searchSong(scanner.nextLine());
                    break;
                case 5:
                    playlist.deleteFirst();
                    break;
                case 6:
                    playlist.deleteLast();
                    break;
                case 7:
                    System.out.print("Enter song title to delete: ");
                    playlist.deleteSelected(scanner.nextLine());
                    break;
                case 8:
                    playlist.displayPlaylist();
                    break;
                case 9:
                    System.out.println("Exiting...");
                    break;
                default:
                    System.out.println("Invalid choice.");
            }
        } while (choice != 9);

        scanner.close();
    }
}
