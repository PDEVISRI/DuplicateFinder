package DuplicateFinder.demo.model;

import java.util.List;

public class DuplicateGroup {
    private String originalPath;
    private List<String> duplicatePaths;
    private long fileSize;

    public DuplicateGroup() {
    }

    public DuplicateGroup(String originalPath, List<String> duplicatePaths, long fileSize) {
        this.originalPath = originalPath;
        this.duplicatePaths = duplicatePaths;
        this.fileSize = fileSize;
    }

    public String getOriginalPath() {
        return originalPath;
    }

    public void setOriginalPath(String originalPath) {
        this.originalPath = originalPath;
    }

    public List<String> getDuplicatePaths() {
        return duplicatePaths;
    }

    public void setDuplicatePaths(List<String> duplicatePaths) {
        this.duplicatePaths = duplicatePaths;
    }

    public long getFileSize() {
        return fileSize;
    }

    public void setFileSize(long fileSize) {
        this.fileSize = fileSize;
    }
}