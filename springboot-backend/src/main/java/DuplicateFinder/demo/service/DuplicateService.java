package DuplicateFinder.demo.service;

import DuplicateFinder.demo.model.DuplicateGroup;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.attribute.BasicFileAttributes;
import java.security.MessageDigest;
import java.util.*;

@Service
public class DuplicateService {

    public List<DuplicateGroup> findDuplicates(String folderPath) {
        File directory = new File(folderPath);
        if (!directory.exists() || !directory.isDirectory()) {
            return Collections.emptyList();
        }

        List<File> allFiles = new ArrayList<>();
        collectFiles(directory, allFiles);

        // Group files by size
        Map<Long, List<File>> sizeMap = new HashMap<>();
        for (File file : allFiles) {
            sizeMap.computeIfAbsent(file.length(), k -> new ArrayList<>()).add(file);
        }

        // Hash files of the same size and group duplicates
        Map<String, List<File>> hashMap = new HashMap<>();
        for (Map.Entry<Long, List<File>> entry : sizeMap.entrySet()) {
            if (entry.getValue().size() > 1) {
                for (File file : entry.getValue()) {
                    String hash = calculateHash(file);
                    if (hash != null) {
                        hashMap.computeIfAbsent(hash, k -> new ArrayList<>()).add(file);
                    }
                }
            }
        }

        List<DuplicateGroup> duplicateGroups = new ArrayList<>();

        for (Map.Entry<String, List<File>> entry : hashMap.entrySet()) {
            List<File> filesWithSameHash = entry.getValue();
            if (filesWithSameHash.size() > 1) {
                // Sort by creation time to determine original file
                filesWithSameHash.sort(Comparator.comparingLong(this::getCreationTime));

                File original = filesWithSameHash.get(0);
                List<String> duplicates = new ArrayList<>();
                for (int i = 1; i < filesWithSameHash.size(); i++) {
                    duplicates.add(filesWithSameHash.get(i).getAbsolutePath());
                }

                duplicateGroups.add(new DuplicateGroup(
                        original.getAbsolutePath(),
                        duplicates,
                        original.length()
                ));
            }
        }

        return duplicateGroups;
    }

    private void collectFiles(File dir, List<File> fileList) {
        File[] files = dir.listFiles();
        if (files != null) {
            for (File file : files) {
                if (file.isDirectory()) {
                    collectFiles(file, fileList);
                } else if (file.isFile()) {
                    fileList.add(file);
                }
            }
        }
    }

    private String calculateHash(File file) {
        try (InputStream is = new FileInputStream(file)) {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] buffer = new byte[8192];
            int bytesRead;
            while ((bytesRead = is.read(buffer)) != -1) {
                digest.update(buffer, 0, bytesRead);
            }
            byte[] hashBytes = digest.digest();
            StringBuilder sb = new StringBuilder();
            for (byte b : hashBytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            return null;
        }
    }

    private long getCreationTime(File file) {
        try {
            BasicFileAttributes attrs = Files.readAttributes(file.toPath(), BasicFileAttributes.class);
            return attrs.creationTime().toMillis();
        } catch (Exception e) {
            return file.lastModified();
        }
    }
}