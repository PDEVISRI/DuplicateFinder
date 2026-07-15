import java.io.*;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.security.*;
import java.util.*;

public class DuplicateFinder {


    // Generate SHA-256 hash for a file
    public static String calculateHash(String filePath) throws Exception {

        MessageDigest digest = MessageDigest.getInstance("SHA-256");

        FileInputStream fis = new FileInputStream(filePath);

        byte[] buffer = new byte[4096];

        int bytesRead;

        while ((bytesRead = fis.read(buffer)) != -1) {
            digest.update(buffer, 0, bytesRead);
        }

        fis.close();


        byte[] hashBytes = digest.digest();

        StringBuilder hashString = new StringBuilder();

        for (byte b : hashBytes) {
            hashString.append(String.format("%02x", b));
        }

        return hashString.toString();
    }



    // Find oldest file using creation date
    public static String findOriginalFile(ArrayList<String> files) throws IOException {


        String original = files.get(0);


        BasicFileAttributes firstFileAttributes =
                Files.readAttributes(
                        Paths.get(original),
                        BasicFileAttributes.class
                );


        long oldestTime =
                firstFileAttributes.creationTime().toMillis();



        for (String file : files) {


            BasicFileAttributes attributes =
                    Files.readAttributes(
                            Paths.get(file),
                            BasicFileAttributes.class
                    );


            long creationTime =
                    attributes.creationTime().toMillis();



            if (creationTime < oldestTime) {

                oldestTime = creationTime;
                original = file;

            }

        }


        return original;

    }




    public static void main(String[] args) throws Exception {


        Scanner scanner = new Scanner(System.in);


        System.out.print("Enter folder path: ");

        String folderPath = scanner.nextLine();




        // Step 1: Group files by size

        HashMap<Long, ArrayList<String>> sizeMap = new HashMap<>();


        Files.walk(Paths.get(folderPath))
                .filter(Files::isRegularFile)
                .forEach(path -> {
                    try {
                        long size = Files.size(path);
                        sizeMap
                        .computeIfAbsent(size, k -> new ArrayList<>())
                        .add(path.toString());
                    } catch(Exception e) {
                        System.out.println(e.getMessage());
                    }
                });
        // Step 2: Group files by hash
        HashMap<String, ArrayList<String>> hashMap = new HashMap<>();
        for(ArrayList<String> files : sizeMap.values()) {
            // Skip files with unique size
            if(files.size() < 2)
                continue;
            for(String file : files) {
                String hash = calculateHash(file);
                hashMap
                .computeIfAbsent(hash, k -> new ArrayList<>())
                .add(file);
            }
        }
        // Step 3: Display duplicate groups
        System.out.println("\nDuplicate Files Found");
        System.out.println("=====================");
        int group = 1;
        for(ArrayList<String> duplicateFiles : hashMap.values()) {
            if(duplicateFiles.size() < 2)
                continue;
            String originalFile =
                    findOriginalFile(duplicateFiles);
            System.out.println("\nDuplicate Group " + group);
            System.out.println("--------------------");
            System.out.println("Original File : "
                    + new File(originalFile).getName());
            System.out.println("Duplicate Files:");
            for(String file : duplicateFiles) {
                if(!file.equals(originalFile)) {
                    System.out.println("- "
                            + new File(file).getName());
                }
            }
            group++;
        }
        if(group == 1) {
            System.out.println("No duplicate files found.");
        }
        scanner.close();

    }
}