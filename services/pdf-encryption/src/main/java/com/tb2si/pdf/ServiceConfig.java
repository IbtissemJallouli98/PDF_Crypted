package com.tb2si.pdf;

final class ServiceConfig {
    private final int port;
    private final int workerThreads;
    private final int maxPdfBytes;
    private final int maxRequestBytes;
    private final String apiToken;

    private ServiceConfig(int port, int workerThreads, int maxPdfBytes, int maxRequestBytes, String apiToken) {
        this.port = port;
        this.workerThreads = workerThreads;
        this.maxPdfBytes = maxPdfBytes;
        this.maxRequestBytes = maxRequestBytes;
        this.apiToken = apiToken;
    }

    static ServiceConfig fromEnvironment() {
        String token = required("PDF_ENCRYPTION_API_TOKEN");
        int maxPdfBytes = integer("MAX_PDF_BYTES", 4_500_000);
        return new ServiceConfig(
                integer("PORT", 8080),
                integer("WORKER_THREADS", 4),
                maxPdfBytes,
                Math.max(maxPdfBytes * 2, 1_000_000),
                token);
    }

    int port() { return port; }
    int workerThreads() { return workerThreads; }
    int maxPdfBytes() { return maxPdfBytes; }
    int maxRequestBytes() { return maxRequestBytes; }
    String apiToken() { return apiToken; }

    private static String required(String name) {
        String value = System.getenv(name);
        if (value == null || value.isBlank()) throw new IllegalStateException(name + " must be configured");
        return value;
    }

    private static int integer(String name, int fallback) {
        String value = System.getenv(name);
        if (value == null || value.isBlank()) return fallback;
        try {
            int parsed = Integer.parseInt(value);
            if (parsed <= 0) throw new IllegalArgumentException(name + " must be positive");
            return parsed;
        } catch (NumberFormatException e) {
            throw new IllegalStateException(name + " must be an integer");
        }
    }
}
