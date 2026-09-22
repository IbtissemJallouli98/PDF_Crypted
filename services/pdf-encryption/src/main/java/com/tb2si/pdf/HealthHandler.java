package com.tb2si.pdf;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import java.io.IOException;
import java.util.Map;

final class HealthHandler implements HttpHandler {
    private final ObjectMapper mapper;
    HealthHandler(ObjectMapper mapper) { this.mapper = mapper; }

    @Override
    public void handle(HttpExchange exchange) throws IOException {
        try (exchange) {
            byte[] response = mapper.writeValueAsBytes(Map.of("status", "ok"));
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            exchange.getResponseBody().write(response);
        }
    }
}
