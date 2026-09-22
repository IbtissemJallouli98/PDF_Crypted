package com.tb2si.pdf;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.Map;

final class EncryptHandler implements HttpHandler {
    private final ServiceConfig config;
    private final ObjectMapper mapper;
    private final PdfEncryptionService encryptionService;

    EncryptHandler(ServiceConfig config, ObjectMapper mapper, PdfEncryptionService encryptionService) {
        this.config = config;
        this.mapper = mapper;
        this.encryptionService = encryptionService;
    }

    @Override
    public void handle(HttpExchange exchange) throws IOException {
        try (exchange) {
            if (!"POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                send(exchange, 405, Map.of("error", "method_not_allowed"));
                return;
            }
            if (!authorized(exchange)) {
                send(exchange, 401, Map.of("error", "unauthorized"));
                return;
            }

            byte[] requestBytes = readLimited(exchange.getRequestBody(), config.maxRequestBytes());
            JsonNode request = mapper.readTree(requestBytes);
            String encodedPdf = text(request, "pdfBase64");
            String userPassword = text(request, "userPassword");
            String ownerPassword = text(request, "ownerPassword");
            byte[] sourcePdf = Base64.getDecoder().decode(encodedPdf);
            byte[] encryptedPdf = encryptionService.encrypt(sourcePdf, userPassword, ownerPassword);

            send(exchange, 200, Map.of("pdfBase64", Base64.getEncoder().encodeToString(encryptedPdf)));
        } catch (IllegalArgumentException | IOException e) {
            // Deliberately return a generic error; never include PDF, password, token, or stack trace.
            try { send(exchange, 400, Map.of("error", "invalid_request")); } catch (IOException ignored) { }
        } catch (Exception e) {
            try { send(exchange, 500, Map.of("error", "encryption_failed")); } catch (IOException ignored) { }
        }
    }

    private boolean authorized(HttpExchange exchange) {
        String value = exchange.getRequestHeaders().getFirst("Authorization");
        String expected = "Bearer " + config.apiToken();
        return value != null && MessageDigest.isEqual(value.getBytes(StandardCharsets.UTF_8), expected.getBytes(StandardCharsets.UTF_8));
    }

    private static String text(JsonNode node, String name) {
        JsonNode value = node == null ? null : node.get(name);
        if (value == null || !value.isTextual() || value.textValue().isBlank()) throw new IllegalArgumentException("missing field");
        return value.textValue();
    }

    private static byte[] readLimited(InputStream input, int maxBytes) throws IOException {
        byte[] bytes = input.readNBytes(maxBytes + 1);
        if (bytes.length > maxBytes) throw new IllegalArgumentException("request too large");
        return bytes;
    }

    private void send(HttpExchange exchange, int status, Object body) throws IOException {
        byte[] response = mapper.writeValueAsBytes(body);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.getResponseHeaders().set("Cache-Control", "no-store");
        exchange.sendResponseHeaders(status, response.length);
        exchange.getResponseBody().write(response);
    }
}
