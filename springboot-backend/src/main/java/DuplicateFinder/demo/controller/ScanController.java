package DuplicateFinder.demo.controller;

import DuplicateFinder.demo.model.DuplicateGroup;
import DuplicateFinder.demo.service.DuplicateService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class ScanController {

    @Autowired
    private DuplicateService duplicateService;

    @GetMapping("/scan")
    public List<DuplicateGroup> scanDirectory(@RequestParam("path") String path) {
        return duplicateService.findDuplicates(path);
    }
}