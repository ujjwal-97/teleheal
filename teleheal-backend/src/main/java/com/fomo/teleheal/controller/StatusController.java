package com.fomo.teleheal.controller;

import org.slf4j.ILoggerFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class StatusController {

    private static final Logger log = LoggerFactory.getLogger(StatusController.class);
    @Value("${spring.application.name:teleheal-backend}")
    private String applicationName;

    @Value("${server.port:8080}")
    private String serverPort;

    @GetMapping("/status")
    @CrossOrigin(origins = "*")
    public ResponseEntity<Map<String, Object>> getStatus() {
        log.info("status check alert!");
        Map<String, Object> status = new HashMap<>();
        
        status.put("service", applicationName);
        status.put("status", "UP");
        status.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        status.put("port", serverPort);
        status.put("version", "0.0.1-SNAPSHOT");
        status.put("environment", System.getProperty("spring.profiles.active", "default"));
        
        // System information
        Map<String, Object> system = new HashMap<>();
        system.put("java_version", System.getProperty("java.version"));
        system.put("java_vendor", System.getProperty("java.vendor"));
        system.put("os_name", System.getProperty("os.name"));
        system.put("os_version", System.getProperty("os.version"));
        
        status.put("system", system);
        
        // Memory information
        Runtime runtime = Runtime.getRuntime();
        Map<String, Object> memory = new HashMap<>();
        memory.put("total_mb", runtime.totalMemory() / (1024 * 1024));
        memory.put("free_mb", runtime.freeMemory() / (1024 * 1024));
        memory.put("used_mb", (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024));
        memory.put("max_mb", runtime.maxMemory() / (1024 * 1024));
        
        status.put("memory", memory);
        
        return ResponseEntity.ok(status);
    }

    @GetMapping("/health")
    @CrossOrigin(origins = "*")
    public ResponseEntity<Map<String, String>> getHealth() {
        Map<String, String> health = new HashMap<>();
        health.put("status", "UP");
        health.put("service", applicationName);
        health.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        
        return ResponseEntity.ok(health);
    }
}
